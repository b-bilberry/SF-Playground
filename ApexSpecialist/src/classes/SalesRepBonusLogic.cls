public with sharing class SalesRepBonusLogic {
	public static final decimal MaxBonusAmountPerMonth = 1000;
	public static final decimal BonusAmount = 100;
	public static final decimal OpportunityAmount = 1000;
	public static final string OpportunityStage = 'Closed Won';


	public static void CalculateSalesRepBonuses(List<Opportunity> newOpportunitites) {
		Map<Id, Opportunity> opportunityData = new Map<Id, Opportunity>([
			SELECT Id, OwnerId, StageName, Amount, CloseDate, (SELECT Id FROM Bonuses__r)
			FROM Opportunity
			WHERE Id IN :newOpportunitites]);

		List<Opportunity> opportunityToProcess = new List<Opportunity>();
		Set<Id> salesRepIds = new Set<Id>();

		for (Opportunity entry : newOpportunitites) {
			if (entry.StageName != OpportunityStage) {
				continue;
			}
			if (entry.Amount < OpportunityAmount) {
				continue;
			}

			Opportunity existingOpportunity = opportunityData.get(entry.Id);
			if (existingOpportunity != null) {
				if (existingOpportunity.StageName == OpportunityStage || existingOpportunity.Bonuses__r != null) {
					continue;
				}
			}

			opportunityToProcess.add(entry);
			salesRepIds.add(entry.OwnerId);
		}

		if (opportunityToProcess.size() > 0) {
			ProcessOpportunities(opportunityToProcess, salesRepIds);
		}
	}

	private static void ProcessOpportunities(List<Opportunity> opportunities, Set<Id> salesRepIds) {
		Map<Id, Map<Date, decimal>> salesRepBonuses = CalculateSalesRepBonuses(new List<Id>(salesRepIds));

		List<Bonus__c> bonusRecToCreate = new List<Bonus__c>();

		for (Opportunity opportunity : opportunities) {
			Date currentBonusPeriod = GetSurrogateDate(opportunity.CloseDate);
			Map<Date, decimal> currentSalesBonuses = salesRepBonuses.get(opportunity.OwnerId);
			if (currentSalesBonuses == null) {
				currentSalesBonuses = new Map<Date, decimal>();
				currentSalesBonuses.put(currentBonusPeriod, BonusAmount);
				salesRepBonuses.put(opportunity.OwnerId, currentSalesBonuses);
			}

			decimal currentBonus = currentSalesBonuses.get(currentBonusPeriod);
			if (currentBonus == null) {
				currentSalesBonuses.put(currentBonusPeriod, BonusAmount);
			}

			if ((currentBonus + BonusAmount) < MaxBonusAmountPerMonth) {
				bonusRecToCreate.add(new Bonus__c(
					Sales_Rep__c = opportunity.OwnerId,
					Amount__c = BonusAmount,
					Opportunity__c = opportunity.Id));
			}

		}

		insert bonusRecToCreate;
	}


	private static Map<Id, Map<Date, decimal>> CalculateSalesRepBonuses(Id[] salesRepIds) {
		AggregateResult[] bonuses = [
			SELECT Sales_Rep__c, SUM(Amount__c) TotalBonusAmount,
				CALENDAR_YEAR(Opportunity__r.CloseDate) OpportunityCloseYear,
				CALENDAR_MONTH(Opportunity__r.CloseDate) OpportunityCloseMonth
			FROM Bonus__c
			WHERE Sales_Rep__c IN :salesRepIds
			GROUP BY Sales_Rep__c, CALENDAR_YEAR(Opportunity__r.CloseDate), CALENDAR_MONTH(Opportunity__r.CloseDate)];

		Map<Id, Map<Date, decimal>> result = new Map<Id, Map<Date, decimal>>();

		for (AggregateResult bonus : bonuses) {
			Map<Date, decimal> bonusPerSalesRep = result.get((Id)bonus.get('Sales_Rep__c'));
			if (bonusPerSalesRep == null) { 
				bonusPerSalesRep  = new Map<Date, decimal>();
				result.put((Id)bonus.get('Sales_Rep__c'), bonusPerSalesRep);
			}

			Date surrogateDate = GetSurrogateDate(
				(integer)bonus.get('OpportunityCloseYear'),
				(integer)bonus.get('OpportunityCloseMonth'));

			if (bonusPerSalesRep.containsKey(surrogateDate) == false) {
				bonusPerSalesRep.put(surrogateDate, (decimal)bonus.get('TotalBonusAmount'));
			}
		}

		return result;
	}

	private static Date GetSurrogateDate(integer year, integer month) {
		return Date.newInstance(year, month, 1);
	}

	private static Date GetSurrogateDate(Date baseDate) {
		return GetSurrogateDate(baseDate.year(), baseDate.month());
	}
}
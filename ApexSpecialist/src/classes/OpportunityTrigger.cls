public with sharing class OpportunityTrigger {
	public static final decimal MAX_BONUS_SUM_PER_MONTH = 1000;
	public static final decimal BONUS_AMOUNT = 100;
	public static final decimal OPPORTUNITY_AMOUNT = 10000;
	public static final string OPPORTUNITY_CLOSEWON_STAGE = 'Closed Won';


	public static void CalculateSalesRepBonuses(List<Opportunity> newOpportunitites,
		Map<Id, Opportunity> oldOpportunities) {

		List<Opportunity> validOpportunities = new List<Opportunity>(newOpportunitites.size());

		for (Opportunity entry : newOpportunitites) {
			if (entry.StageName != OPPORTUNITY_CLOSEWON_STAGE) {
				continue;
			}
			if (entry.Amount < OPPORTUNITY_AMOUNT) {
				continue;
			}
			if (oldOpportunities != null) {
				Opportunity existingOpportunity = oldOpportunities.get(entry.Id);
				if (existingOpportunity != null && existingOpportunity.StageName == OPPORTUNITY_CLOSEWON_STAGE) {
					continue;
				}
			}
			validOpportunities.add(entry);
		}

		if (validOpportunities.size() > 0) {
			List<Opportunity> opportuntiesWithoutBonuses = GetOpportunitiesWithoutBonuses(validOpportunities);
			if (opportuntiesWithoutBonuses.size() > 0) {
				CreateBonuses(opportuntiesWithoutBonuses);
			}
		}
	}

	private static List<Opportunity> GetOpportunitiesWithoutBonuses(Opportunity[] opportunities) {
		List<Opportunity> result = [
			SELECT OwnerId, CloseDate
			FROM Opportunity
			WHERE (Id IN :opportunities)
				AND (Id NOT IN (SELECT Opportunity__c FROM Bonus__c WHERE Opportunity__c IN :opportunities))];

		return result;
	}

	private static void CreateBonuses(List<Opportunity> opportunities) {
		Set<Id> salesRepIds = GetDistinctSalesRepIds(opportunities);
		Map<Id, Map<Date, decimal>> totalBonusPerMonthByUserId = CalculateSalesRepBonuses(salesRepIds);

		List<Bonus__c> bonusRecToCreate = new List<Bonus__c>();

		for (Opportunity opportunity : opportunities) {
			Date currentBonusPeriod = GetSurrogateDate(opportunity.CloseDate);
			Map<Date, decimal> currentSalesBonuses = totalBonusPerMonthByUserId.get(opportunity.OwnerId);
			if (currentSalesBonuses == null) {
				currentSalesBonuses = new Map<Date, decimal>();
				currentSalesBonuses.put(currentBonusPeriod, BONUS_AMOUNT);
				totalBonusPerMonthByUserId.put(opportunity.OwnerId, currentSalesBonuses);
			}

			decimal currentBonus = currentSalesBonuses.get(currentBonusPeriod);
			if (currentBonus == null) {
				currentBonus = 0;
			}

			if ((currentBonus + BONUS_AMOUNT) < MAX_BONUS_SUM_PER_MONTH) {
				currentSalesBonuses.put(currentBonusPeriod, currentBonus + BONUS_AMOUNT);

				bonusRecToCreate.add(new Bonus__c(
					Sales_Rep__c = opportunity.OwnerId,
					Amount__c = BONUS_AMOUNT,
					Opportunity__c = opportunity.Id));
			}

		}

		insert bonusRecToCreate;
	}

	private static Set<Id> GetDistinctSalesRepIds(Opportunity[] opportunities) {
		Set<Id> result = new Set<Id>();
		for (Opportunity entry : opportunities) {
			result.add(entry.OwnerId);
		}
		return result;
	}

	private static Map<Id, Map<Date, decimal>> CalculateSalesRepBonuses(Set<Id> salesRepIds) {
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
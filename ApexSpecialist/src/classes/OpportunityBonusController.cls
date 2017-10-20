public with sharing class OpportunityBonusController {
	public Id Filter_SalesRepId {get; set; }
	public Integer RecordCount {get; set;}

	public OpportunityBonusController() {
		RecordCount = 1;
	}

	public Bonus__c[] getBonuses() {
		Bonus__c[] result = getBonusesBySalesRep(Filter_SalesRepId);
		RecordCount = result.size();
		return result;
	}

	private Bonus__c[] getBonusesBySalesRep(Id salesRepId) {
		return [
			SELECT Sales_Rep__r.Name, Opportunity__r.Type, Opportunity__r.CloseDate,
				Opportunity__r.Amount, Opportunity__r.StageName, Amount__c
			FROM Bonus__c
			WHERE Sales_Rep__c = :salesRepId
			ORDER BY Opportunity__r.CloseDate DESC
		];
	}

	public SelectOption[] getSalesRepresentatives() {
		List<SelectOption> result = new List<SelectOption>();
		result.add(new SelectOption('', ''));
		//TO-DO: Cache this stuff
		for (User entry : [SELECT Name, (SELECT Id FROM Bonuses__r) Bonuses FROM User ORDER BY Name]) {
			result.add(new SelectOption(entry.Id, entry.Name + (entry.Bonuses__r.size() == 0 ? '' : ' - *')));
		}

		return result;
	}
}
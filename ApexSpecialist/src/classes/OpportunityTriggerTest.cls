@isTest
private class OpportunityTriggerTest {
	@isTest
	static void BonusShouldBeCreated() {
		Opportunity testOpportunity = new Opportunity();
		testOpportunity.OwnerId = GetSalesRepId();
		testOpportunity.Amount = OpportunityTriggerHelper.OPPORTUNITY_AMOUNT;
		testOpportunity.StageName = OpportunityTriggerHelper.OPPORTUNITY_CLOSEWON_STAGE;

		Test.startTest();
		insert testOpportunity;
		Test.stopTest();

		Bonus__c bonus = [SELECT Amount__c, Sales_Rep__c, Opportunity__c FROM Bonus__c];

		system.assert(bonus != null, 'Bonus record was not created');

		system.assertEquals(bonus.Amount__c, OpportunityTriggerHelper.BONUS_AMOUNT,
			'Bonus amount is not equal to specified in SalesRepBonusLogic');

		system.assertEquals(bonus.Sales_Rep__c, testOpportunity.OwnerId,
			'Owner of the bonus is not equal to the owner of opportunity');

		system.assertEquals(bonus.Opportunity__c, testOpportunity.Id,
			'Bonus was not assigned to correct opportunity');

	}

	private static Id GetSalesRepId() {
		Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
		User u = new User(ProfileId = p.Id);
		insert u;
		return u.Id;
	}
}
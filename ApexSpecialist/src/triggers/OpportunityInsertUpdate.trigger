trigger OpportunityInsertUpdate on Opportunity (after insert, after update) {
	SalesRepBonusLogic.CalculateSalesRepBonuses(Trigger.new);
}
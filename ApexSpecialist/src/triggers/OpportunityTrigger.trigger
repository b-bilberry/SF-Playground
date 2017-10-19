trigger OpportunityTrigger on Opportunity (after insert, after update) {
	if (Trigger.isInsert || Trigger.isUpdate) {
		OpportunityTriggerHelper.CalculateSalesRepBonuses(Trigger.new, Trigger.oldMap);
	}
}
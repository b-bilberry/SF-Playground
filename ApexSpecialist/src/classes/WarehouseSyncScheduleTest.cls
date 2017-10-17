@isTest
private class WarehouseSyncScheduleTest {
    private static final string CorrectCron = '0 0 8 * * ?';
        
        @isTest static void SchedulePositiveTest() {
            Test.startTest();
            
            string jobId = system.schedule('WarehouseScheduleTest', CorrectCron,
                new WarehouseSyncSchedule());
            
           
            
            Test.stopTest();
            
            
             CronTrigger ct = [SELECT Id FROM CronTrigger WHERE Id = :jobId];
            system.assert(ct != null, 'Failed to schedule task');
            /*
            Product2[] equipments = [SELECT Id FROM Product2];
            system.debug(equipments);
            system.assert(equipments.size() > 0, 'Equipments were not loaded with scheduled web service call');
*/
        }
}
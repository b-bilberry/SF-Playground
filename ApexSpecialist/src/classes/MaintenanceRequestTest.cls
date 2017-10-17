@isTest
private class MaintenanceRequestTest {
    private static final integer NewRequestsTotalCount = 300;
    
    @testSetup static void setup() {
        Product2 workPartEquipment1 = MaintenanceRequestTestDataFactory.CreateEquipment(5, true);
        Product2 workPartEquipment2 = MaintenanceRequestTestDataFactory.CreateEquipment(1, true);
        Product2 requestRelatedEquipment = MaintenanceRequestTestDataFactory.CreateEquipment(5, false);
        
        insert new Product2[] { workPartEquipment1, workPartEquipment2, requestRelatedEquipment };
            
        Vehicle__c vehicle = MaintenanceRequestTestDataFactory.CreateVehicle();
        insert vehicle;
        
        Case request = MaintenanceRequestTestDataFactory.CreateMaintenanceRequest(
            requestRelatedEquipment.Id, vehicle.Id, MRequestConsts.RequestStatusNew, MRequestConsts.RequestTypeRepair);
        insert request;
        
        Work_Part__c part1 = MaintenanceRequestTestDataFactory.CreateWorkPart(
            workPartEquipment1.Id, request.Id);
        Work_Part__c part2 = MaintenanceRequestTestDataFactory.CreateWorkPart(
            workPartEquipment2.Id, request.Id);
        insert new Work_Part__c[] { part1, part2};
    }
    
    @isTest static void RequestStatusUpdatePositive() {
        Case request = [SELECT Id,
                        (SELECT Equipment__r.Lifespan_Months__c FROM Work_Parts__r)
                        FROM CASE LIMIT 1];
        
        request.Status = 'Closed';
        Test.startTest();
        update request;
        Test.stopTest();
        
        Case futureRequest = [SELECT Id, Vehicle__r.Id, Equipment__r.Id, Date_Due__c
                              FROM CASE WHERE Status = 'New'];
        
        system.assert(futureRequest != null, 'Newly created request not found');
        
        system.assert(futureRequest.Vehicle__c != request.Vehicle__c,
            'Newly created request has not have correct relationship with Vehicle');
        
        system.assert(futureRequest.Equipment__c != request.Equipment__c,
			'Newly created request has not correct relationship with Equipment');
        
        Decimal minLifespanMonths = request.Work_Parts__r[0].Equipment__r.Lifespan_Months__c;
        for (Work_Part__c part : request.Work_Parts__r) {
            if (minLifespanMonths > part.Equipment__r.Lifespan_Months__c) {
                minLifespanMonths = part.Equipment__r.Lifespan_Months__c;
            }
        }
        
        system.assertEquals(Date.today().addMonths(minLifespanMonths.intValue()), futureRequest.Date_Due__c,
			'Newly created request has invalid due date!');
    }
    
    @isTest static void RequestStatusNegative() {
        Case request = [SELECT Id FROM CASE LIMIT 1];
        request.Subject = 'SHOULD NOT CHANGE ME';
        Test.startTest();
        update request;
        Test.stopTest();
        
        Case[] cases = [SELECT Id FROM CASE WHERE Status = 'New'];
        system.assert(cases.size() == 1, 'There is must be only one case!');
    }
    
    @isTest static void BulkInsertNewRequestsPositive() {
        Product2 requestRelatedEquipment = MaintenanceRequestTestDataFactory.CreateEquipment(5, false);
        insert requestRelatedEquipment;
            
        Vehicle__c vehicle = MaintenanceRequestTestDataFactory.CreateVehicle();
        insert vehicle;
        
        List<Case> requestsList = new List<Case>();
        for(Integer i = 0; i < NewRequestsTotalCount; ++i) {
            Case request = MaintenanceRequestTestDataFactory.CreateMaintenanceRequest(
            requestRelatedEquipment.Id, vehicle.Id,
                MRequestConsts.RequestStatusNew, MRequestConsts.RequestTypeRepair);
            requestsList.add(request);
        }
        
        Case requestToClose = [SELECT Id FROM Case LIMIT 1];
        requestToClose.Status = MRequestConsts.RequestStatusClosed;
        requestsList.add(requestToClose);
        
        Test.startTest();
        upsert requestsList;
        Test.stopTest();
        
        system.assertEquals((NewRequestsTotalCount + 1),
                            [SELECT COUNT() FROM CASE WHERE Status = :MRequestConsts.RequestStatusNew],
                           'The count of newly created requests must be ' + (NewRequestsTotalCount + 1));
    }
}
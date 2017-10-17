@isTest
private class WarehouseCalloutServiceTest {
    @isTest static void CallWebServicePositiveTest() {
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock(200, true));
        Test.startTest();
        WarehouseCalloutService.runWarehouseEquipmentSync();
        Test.stopTest();
        
        Product2[] equipments = [SELECT Id FROM Product2];
        system.assert(equipments.size() == 2,
                      'Equipments were not loaded via web service');
    }
    
    @isTest static void CallWebServiceNegativeTest() {
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock(500, true));
        Test.startTest();
        WarehouseCalloutService.runWarehouseEquipmentSync();
        Test.stopTest();
        
        Integer rowCount = [SELECT COUNT() FROM Product2];
        system.assert(0 == rowCount,
                      'Equipments were loaded to db, but web service ' +
                      'has returned 500 error code');
    }
    
    @isTest static void CallWebServiceWillReturnWrongJsonAnswer() {
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock(200, false));
        Test.startTest();
        WarehouseCalloutService.runWarehouseEquipmentSync();
        Test.stopTest();
        
        Integer rowCount = [SELECT COUNT() FROM Product2];
        system.assert(0 == rowCount,
                      'Equipments were loaded to db, but web service ' +
                      'has returned erroneous data');
    }
}
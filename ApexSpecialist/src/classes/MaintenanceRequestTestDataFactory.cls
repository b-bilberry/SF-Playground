public class MaintenanceRequestTestDataFactory {
    
    public static Case CreateMaintenanceRequest(ID equipmentId, ID vehicleId, string status, string type) {
        Case result = new Case();
        result.Status = status;
        result.Type = type;
        result.Vehicle__c = vehicleId;
        result.Equipment__c = equipmentId;
        system.debug('created test instance of MaintenanceRequest ' + result);
        return result;
    }
    
    public static Product2 CreateEquipment(integer lifespanMonths, boolean replacement) {
        Product2 result = new Product2();
        result.Name = 'Test Product';
        result.Replacement_Part__c = replacement;
        result.Lifespan_Months__c = lifespanMonths;
        system.debug('created test instance of Equipment ' + result);
        return result;
    }
    
    public static Vehicle__c CreateVehicle() {
        Vehicle__c result = new Vehicle__c();
        result.Name = 'Test vehicle';
        system.debug('created test instance of Vehicle ' + result);
        return result;
    }
    
    public static Work_Part__c CreateWorkPart(ID equipmentId, Id requestId) {
        Work_Part__c result = new Work_Part__c();
        result.Equipment__c = equipmentId;
        result.Maintenance_Request__c = requestId;
        system.debug('created test instance of WorkPart ' + result);
        return result;
    }
}
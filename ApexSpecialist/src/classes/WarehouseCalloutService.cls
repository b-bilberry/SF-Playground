public with sharing class WarehouseCalloutService {
    private static final string WAREHOUSE_URL = 'https://th-superbadge-apex.herokuapp.com/equipment';
    
    @future(callout=true)
    public static void runWarehouseEquipmentSync(){
        HttpResponse response = null;
        
        if (Test.isRunningTest() == false) {
        	response = GetEquipment();
        } else {
            response = (new WarehouseCalloutServiceMock(200, true)).respond(null);
        }
        Product2[] equipments = ParseHttpResponse(response);
        if (equipments != null) {
        	upsert equipments;
        }
    }
    
    private static HttpResponse GetEquipment() {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(WAREHOUSE_URL);
        request.setMethod('GET');
        Http http = new Http();
        return http.send(request);
    }
    
    private static Product2[] ParseHttpResponse(HttpResponse response) {
        if (response.getStatusCode() != 200) {
            system.debug('HTTP response failed with code ' + 
                        string.valueOf(response.getStatusCode()));
            return null;
        }
        
        List<Map<string,object>> sourceEquipments = new List<Map<string,object>>();
        
        try
        {
            List<object> raw = (List<object>)JSON.deserializeUntyped(response.getBody());
            for (object rawEntry : raw) {
                sourceEquipments.add((Map<string,object>)rawEntry);
            }
        }
        catch(Exception ex) 
        {
            system.debug('Could not parse HTTP response\n' + ex);
            return null;
        }
        
        List<Product2> result = new List<Product2>();
        for (Map<string,object> sourceEntry : sourceEquipments) {
            Product2 destEntry = new Product2();
            destEntry.Name = (string)sourceEntry.get('name');
            destEntry.Warehouse_SKU__c = (string)sourceEntry.get('sku');
            destEntry.Replacement_Part__c = true;
            destEntry.Cost__c = (decimal)sourceEntry.get('cost');
            destEntry.Current_Inventory__c = (integer)sourceEntry.get('quantity');
            destEntry.Lifespan_Months__c = (integer)sourceEntry.get('lifespan');
            destEntry.Maintenance_Cycle__c= (double)sourceEntry.get('maintenanceperiod');
            result.add(destEntry);
        }
        
        system.debug('ParseHttpResponse result is ' + result);
        return result;
    }

}
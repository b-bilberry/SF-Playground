public class WarehouseCalloutServiceMock implements HttpCalloutMock {
    private final string ResourceId = 'MaintenanceRequestWebServiceResponse';
    
    private integer httpStatusCode = 200;
    private boolean returnCorrectJson = false;
    
    public WarehouseCalloutServiceMock(integer httpStatusCode, boolean returnCorrectJson) {
        this.httpStatusCode = httpStatusCode;
        this.returnCorrectJson = returnCorrectJson;
    }
    
    public HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(this.httpStatusCode);
        response.setHeader('Content-Type', 'application/json');
        response.setBody(GetResponseBody());
        return response;
    }
    
    private string GetResponseBody() {
        string result = '{"Error" : true}';
        
        if(this.returnCorrectJson == true)  {
            StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = :ResourceId LIMIT 1];
            result = sr.Body.toString();
        }
        
		return result;
    }
}
public class MaintenanceRequestHelper {
    
    public static void updateWorkOrders(Case[] updatedRequests) {
        Case[] closedRequests =
            [SELECT Vehicle__c, Equipment__r.Id, Equipment__r.Lifespan_Months__c,
             (SELECT Equipment__r.Lifespan_Months__c FROM Work_Parts__r)
             FROM Case
             WHERE Id IN :updatedRequests];
        
        List<Case> requestsToCreate = new List<Case>();
        
        for (Case request : closedRequests) {
            Case futureRequest = new Case();
            Integer lifespan = FindShortestLifespan(request.Work_Parts__r);
            futureRequest.Date_Due__c = Date.today().addMonths(lifespan);
            futureRequest.Subject = 'Routine Maintenance at ' + string.valueOf(futureRequest.Date_Due__c);
            futureRequest.Date_Reported__c = Date.today();
            futureRequest.Vehicle__c = request.Vehicle__c;
            futureRequest.Equipment__c = request.Equipment__c;
            futureRequest.Type = MRequestConsts.RequestTypeRoutine;
            futureRequest.Status = MRequestConsts.RequestStatusNew;
            requestsToCreate.add(futureRequest);
        }
        system.debug('Requests to be created: ' + requestsToCreate);
        insert requestsToCreate;
    }
    
    private static Integer FindShortestLifespan(Work_Part__c[] parts) {
        if (parts.size() == 0) { return 0; }
        Decimal result = parts[0].Equipment__r.Lifespan_Months__c;
        for (Work_Part__c part : parts) {
            if (result > part.Equipment__r.Lifespan_Months__c) {
                result = part.Equipment__r.Lifespan_Months__c;
            }
        }
        return result.intValue();
    }
}
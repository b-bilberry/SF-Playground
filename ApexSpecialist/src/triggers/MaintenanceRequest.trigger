trigger MaintenanceRequest on Case (after insert, after update) {
    List<Case> requestsToBeClosed = new List<Case>();
    
    for(Case request : Trigger.new) {
        if (request.Type == MRequestConsts.RequestTypeRepair || request.Type == MRequestConsts.RequestTypeRoutine) {
            if (request.Status == MRequestConsts.RequestStatusClosed) {
                Case oldRequest = Trigger.oldMap.get(request.Id);
                if (oldRequest == null || oldRequest.Status != MRequestConsts.RequestStatusClosed) {
                    requestsToBeClosed.add(request);
                }
            }
        }
    }
    
    MaintenanceRequestHelper.updateWorkOrders(requestsToBeClosed);
}
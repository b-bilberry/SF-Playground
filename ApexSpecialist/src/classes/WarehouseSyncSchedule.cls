public class WarehouseSyncSchedule implements Schedulable {
  public void execute(SchedulableContext ctx) {
      WarehouseCalloutService.runWarehouseEquipmentSync();
  }
}
trigger quoteTrigger on Quote (before insert, after insert, before update, after update, before delete, after delete) 
{
   MigrationSettings__c settings = MigrationSettings__c.getInstance();
   if(settings !=null && settings.Id !=null && settings.PerformingMigration__c)
     return;

    if(Trigger.isBefore && Trigger.isUpdate)
    {
        QuoteHelper.setFees(  Trigger.oldMap, Trigger.newMap );
    }
    else if(Trigger.isAfter && Trigger.isUpdate)
    {
        QuoteHelper.setVolumeDiscount( Trigger.oldMap, Trigger.newMap );
    }
}
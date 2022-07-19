trigger quoteLineTrigger on QuoteLineItem (before insert, after insert, before update, after update, before delete, after delete) 
{
    MigrationSettings__c settings = MigrationSettings__c.getInstance();
    if(settings !=null && settings.Id !=null && settings.PerformingMigration__c)
       return;

    if(Trigger.isBefore)
    {
        if(Trigger.isInsert)
        {
            QuoteLineHelper.copyFieldValues( Trigger.New );
        }

        if(Trigger.isInsert||Trigger.isUpdate)
        {
            QuoteLineHelper.setVolumeDiscount( Trigger.Old, Trigger.New, 
                                       Trigger.oldMap, Trigger.newMap, 
                                       Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete);
        }
    } 
    else if(Trigger.isAfter) 
    {
      
        if(Trigger.isInsert||Trigger.isDelete)
        {
            //Set the Quote Fees if we have any QL that require them
            QuoteLineHelper.setQuoteFlags( Trigger.Old, Trigger.New, 
                                Trigger.oldMap, Trigger.newMap, 
                                Trigger.isInsert,Trigger.isUpdate, Trigger.isDelete);

        }
        
    }
}
trigger LogEventTrigger on Log_Event__e (after insert) {
	List<Exception_Logger__c> logList = new List<Exception_Logger__c>();
    for(Log_Event__e event: trigger.new)
    {
        logList.add(ExceptionLogger.createLogRecord(event));
    }
    if(logList.size() > 0)
        Database.insert(logList, false);
}
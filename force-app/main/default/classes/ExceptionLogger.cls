public class ExceptionLogger {
    public static void log(List<Exception> e)
    {
        //Get info about the current request
        Request reqInfo = Request.getCurrent();
        //Get the identifier for this request, which is universally unique
        //Same as requestId in splunk or REQUEST_ID in event monitoring
        String currentRequestId = reqInfo.getRequestId();
        //Enum representing how Apex is running. e.g. BULK_API vs LIGHTNING
        String currentType = String.valueOf(reqInfo.getQuiddity());
        
        System.debug('currentType:'+currentType);
        if(currentType != null && Logger.getInstance().logSettings.containsKey(currentType) && Logger.getInstance().logSettings.get(currentType))
        {
            publishExceptionLogEvent(e,currentType);
            if(Test.isRunningTest() == true)
            {insertLogRecord(e);}
        }else{
            insertLogRecord(e);
        }
    }
    
    private static void publishExceptionLogEvent(List<Exception> expList, String context)
    {
        List<Log_Event__e> logList = new List<Log_Event__e>();
        for(Exception e: expList)
        {
            Log_Event__e logEvent = new Log_Event__e();
            logEvent.Exception_Message__c = e.getMessage();
            logEvent.Stack_Trace__c = e.getStackTraceString();
            logEvent.Exception_Type__c = e.getTypeName();
            logEvent.Line_Number__c = e.getLineNumber();
            logEvent.Exception_Cause__c = String.valueOf(e.getCause());
            logList.add(logEvent);
        }
        EventBus.publish(logList);
            
    }
    
    public static Exception_Logger__c createLogRecord(Log_Event__e event)
    {
        Exception_Logger__c eLog = new Exception_Logger__c();
        eLog.Exception_Cause__c = event.Exception_Cause__c;
        eLog.Exception_Message__c = event.Exception_Message__c;
        eLog.Exception_Type__c = event.Exception_Type__c;
        eLog.Line_Number__c = event.Line_Number__c;
        eLog.Stack_Trace__c = event.Stack_Trace__c;
        return eLog;
    }
	
    public static void logError(String error,String errorMessage)
    {
        Exception_Logger__c log = new Exception_Logger__c ();
        log.Stack_Trace__c= error;
        log.Exception_Message__c = errorMessage;
        Database.insert(log);
    }
    /*
    public static void insertLogRecord(Exception e)
    {
        Exception_Logger__c log = new Exception_Logger__c ();
        log.Stack_Trace__c= e.getStackTraceString();
        log.Line_Number__c= e.getLineNumber();
        log.Exception_Type__c = e.getTypeName();
        log.Exception_Cause__c = String.valueOf(e.getCause());
        log.Exception_Message__c = e.getMessage();
        database.insert(log,false);
    }*/
    
    //Method to insert Log__c records
    public static void insertLogRecord(List<Exception> e)
    {
        List<Exception_Logger__c> logList = new List<Exception_Logger__c>();
        for(Exception ex:e)
        {
            Exception_Logger__c log = new Exception_Logger__c ();
            log.Stack_Trace__c= ex.getStackTraceString();
            log.Line_Number__c= ex.getLineNumber();
            log.Exception_Type__c = ex.getTypeName();
            log.Exception_Cause__c = String.valueOf(ex.getCause());
            log.Exception_Message__c = ex.getMessage();
            logList.add(log);
        }
        database.insert(logList,false);
    }
}
public class Logger {
	private static final Logger instance = new Logger();
    public Map<String, Boolean> logSettings{get; private set;}
    public List<Exception> exceptionList{get; private set;}
    private Logger(){
        logSettings = new Map<String, Boolean>();
        exceptionList = new List<Exception>();
        Map<String, Log_Setting__mdt> ls = Log_Setting__mdt.getAll();
        System.debug('? ls.size():'+ls.size());
        for(String setting: ls.keySet()){
            logSettings.put(setting,ls.get(setting).Generate_Platform_Event__c);
        }
    }
    
    public static Logger getInstance(){
        //eager load of the class
        return instance;
    }
}
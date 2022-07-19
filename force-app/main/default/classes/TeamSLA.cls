public class TeamSLA {
    
    private static final TeamSLA INSTANCE = new TeamSLA();
    public static Map<String, Integer> teamSlaList{get; private set;}
    public static Map<String, Decimal> teamSlaMilliSecList{get; private set;}
    public static Map<Integer, Decimal> dayAndMill{get; private set;}
    
    public TeamSLA(){
        //eager load of the class
        Map<String, Case_SLA_by_Team__mdt> ls = Case_SLA_by_Team__mdt.getAll();
        Set<Integer> days = new Set<Integer>();
        
        System.debug('? ls.size():'+ls.size());
        teamSlaList = new Map<string,Integer>();
        teamSlaMilliSecList = new Map<string,Decimal>();
        for(Case_SLA_by_Team__mdt setting: ls.values()){
            teamSlaList.put(setting.Name__c,Integer.valueOf(setting.SLA__c));
            days.add(Integer.valueOf(setting.SLA__c));
        }
        
        dayAndMill = new Map<Integer, Decimal>();
        
        BusinessHours bHours = [SELECT Id,MondayStartTime,MondayEndTime,TimeZoneSidKey FROM BusinessHours WHERE Name =: CaseAppLiterals.ORTHOFIBUSINESSHOURS];
        Time t = bHours.MondayStartTime;
        Time t1 = bHours.MondayEndTime;
        Decimal milliSec = getMillisecondsFromTime(t,t1);
        system.debug(getMillisecondsFromTime(t,t1));
        
        for(Integer d : days)
        {
            
            dayAndMill.put(d,  milliSec * d);
        }
        
        system.debug('dayMil' + dayAndMill);
        
        for(String team : teamSlaList.keySet())
        {
            teamSlaMilliSecList.put(team, dayAndMill.get(teamSlaList.get(team)));
        }
        system.debug('teamSlaMilliSecList' + teamSlaMilliSecList);
    }
    
    
    
    public static long getMillisecondsFromTime(Time t1, Time t2){
        if(t1!=null && t2!=null){
            return (t2.hour() - t1.hour())*60*60*1000 + (t2.minute() - t1.minute())*60*1000  + (t2.second()-t1.second())*1000 + (t2.millisecond() - t1.millisecond());
        }
        return null;
    }    
    public static TeamSLA getInstance(){       
        return INSTANCE;
    }
    
    public Map<String, Integer> getTeamSLA()
    {
        return teamSlaList;
    }
    
    public Map<String, Decimal> getTeamSLAInMilliSec()
    {
        return teamSlaMilliSecList;
    }
    
    public Map<Integer, Decimal> getdayMilliSecMap()
    {
        return dayAndMill;
    }
}
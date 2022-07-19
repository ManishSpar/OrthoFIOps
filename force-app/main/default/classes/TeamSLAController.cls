public class TeamSLAController {
         
    public class TeamSLAWrapper
    {        
         @AuraEnabled public Map<string, Integer> teamSlaMap;
         @AuraEnabled public Map<String, Decimal> teamSlaInMillSecMap;
         @AuraEnabled public BusinessHours bhours;
         @AuraEnabled public long oneDayBusinessHrsInMilli;
         @AuraEnabled public Decimal oneDayBusinessHrs;
    }
    
   /* private static Map<string, Integer> teamSlaMap;
    private static Map<String, Decimal> teamSlaInMillSecMap;
    private static BusinessHours bhours;
    private static long oneDayBusinessHrs;*/
    @AuraEnabled
    public static TeamSLAWrapper getTeamSLAFromMetadata()
    {       
        TeamSLAWrapper tsw = new TeamSLAWrapper();
        tsw.teamSlaInMillSecMap = TeamSLA.getInstance().getTeamSLAInMilliSec();
        tsw.teamSlaMap = TeamSLA.getInstance().getTeamSLA();
        tsw.bhours = [SELECT Id,MondayStartTime, MondayEndTime FROM BusinessHours WHERE  Name = :CaseAppLiterals.ORTHOFIBUSINESSHOURS AND IsActive= true];
        
          Time t = tsw.bhours.MondayStartTime;
            Time t1 = tsw.bhours.MondayEndTime;
        tsw.oneDayBusinessHrsInMilli = CaseService.getMillisecondsFromTime(t,t1); // 12.5*60*60*1000
        
        tsw.oneDayBusinessHrs = CaseService.getOneBusinessDayHours(t,t1); //12.5
        return tsw;
    }
    
    
    @AuraEnabled
    public static List<Map<string,string>> getSLA(String recId,string tsw)
    {
        system.debug(tsw);
        TeamSLAWrapper teamSlaWrapper = (TeamSLAWrapper)JSON.deserialize(tsw, TeamSLAWrapper.class);
        System.debug('$$ recId: ' + recId);
        return getTeamSla(recId,teamSlaWrapper);
    }
    
    private static List<Map<string,string>> getTeamSla(String recId,TeamSLAWrapper tsw)
    {
          List<Map<string,string>> outputlist = new List<Map<string,string>>();
            
         try{
            Map<string, Decimal> changeLogMap = new Map<string,Decimal>();
            List<Case_Owner_Change_Log__c> changeLOg = [SELECT ID,Current_Owner__r.Name ,Current_Owner__c,Current_Owner_Queue__c, Start_Time__c,End_Time__c, SLA_Time__c FROM Case_Owner_Change_Log__c WHERE IsRolledUp__c=false AND Case__c = :recId order by ID];
            for(Case_Owner_Change_Log__c clog : changeLog)
            {
                if(clog.End_Time__c == null && clog.Start_Time__c != null)
                {
                 
                    Decimal hours = BusinessHours.diff(String.valueOf(tsw.bhours.Id), clog.Start_Time__c, DateTime.Now());
                    clog.SLA_Time__c = hours;
                    system.debug(hours);
                }
                if(changeLogMap.containsKey(clog.Current_Owner_Queue__c))     
                {
                    system.debug(clog.Current_Owner_Queue__c + ' ' + clog.sla_time__c );
                    Decimal sla = changeLogMap.get(clog.Current_Owner_Queue__c);
                    sla = sla + clog.SLA_Time__c;
                     system.debug(clog.Current_Owner_Queue__c + ' ' + sla );
                    changeLogMap.put(clog.Current_Owner_Queue__c, sla);
                    
                }
                else
                {
                    system.debug(clog.Current_Owner_Queue__c);
                    changeLogMap.put(clog.Current_Owner_Queue__c, clog.Sla_Time__c);
                }
            }
             
             for(string aggr:changeLogMap.keySet()){ 
                    Map<string,string> output = new Map<string,string>();
                    output.put(CaseAppLiterals.CONSUMED_SLA,CaseService.getAge(changeLogMap.get(aggr), tsw.oneDayBusinessHrsInMilli, tsw.oneDayBusinessHrs));
                    output.put('ConsumedSLAinmillisec',String.valueOf(changeLogMap.get(aggr)));
                    output.put(CaseAppLiterals.TEAMNAME, aggr);
                    output.put(CaseAppLiterals.ASSIGNEDSLA,''); 
                   
                    outputlist.add(output);
                }
             
             system.debug(changeLogMap);
             
             
             //3 day
             //// 
             //12.30 
             //1 53hrs
             //23  // 12.30  11 // 1day 11hrs
            
            //Map<String, Decimal> teamSlaInMillSec = TeamSLA.getInstance().getTeamSLAInMilliSec();
            //Map<String, Integer> teamSla = TeamSLA.getInstance().getTeamSLA(); 
            ////to convert user SLA in millisec
             
             Map<Integer, Decimal> dayAndMill = TeamSLA.getInstance().getdayMilliSecMap();
             for(Map<string,string> results : outputlist)
            {
                String queue = (String)results.get(CaseAppLiterals.TEAMNAME);
                Integer sla  = tsw.teamSlaMap.get(queue) == null ? CaseAppLiterals.USERSLA : tsw.teamSlaMap.get(queue); // change 13/8
                System.debug('? sla'+ sla);
                 
                //Decimal slaInMilli = tsw.teamSlaInMillSecMap.get(queue) == null ? dayAndMill.get(CaseAppLiterals.USERSLA) : tsw.teamSlaInMillSecMap.get(queue);
                Decimal slaInMilli;
                if(tsw.teamSlaInMillSecMap.containsKey(queue))
                {
                    slaInMilli = tsw.teamSlaInMillSecMap.get(queue);
                }else{
                    slaInMilli = dayAndMill.get(CaseAppLiterals.USERSLA);
                }
                System.debug('? slaInMilli' + slaInMilli);
                if(sla != null)
                {
                    results.put(CaseAppLiterals.ASSIGNEDSLA,  sla + CaseAppLiterals.SPACE + CaseAppLiterals.DAYS);
                
                    //boolean slaMet = CaseService.checkSlaMet(results.get(CaseAppLiterals.CONSUMED_SLA),sla);
                    boolean slaMet = CaseService.checkSlaMetOrNot(results.get('ConsumedSLAinmillisec'),slaInMilli);
                    if(slaMet)
                    {
                         results.put(CaseAppLiterals.SLAMET, CaseAppLiterals.MET);
                    }
                    else
                    {
                        results.put(CaseAppLiterals.SLAMET, CaseAppLiterals.NOTMET);
                    }
                }
            }
            system.debug(outputList);
           
        }
        catch(Exception ex)
        {
            system.debug(ex);
            Logger.getInstance().exceptionList.add(ex);
              
        }
        finally
        {
            List<Exception> expList = Logger.getInstance().exceptionList;
            if(expList != null && expList.size() > 0)
            {
                ExceptionLogger.log(expList);
                Logger.getInstance().exceptionList.clear();
            }
        }
        return outputList;
    }
}
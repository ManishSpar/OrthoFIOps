public class CaseService {    
    
	public static void handleCaseOwnerChange(List<Case> cases, Set<ID> caseOwners)
    {
        for(case c:cases){
            system.debug('case number 00085737 '+ c.CaseNumber);
        }
        Map<ID,String> memberQueue = new Map<ID, String>();
        Map<ID,String> memberName = new Map<ID, String>();
        
        List<User> users = [SELECT ID, Name FROM User WHERE ID IN :caseOwners];
        for(User u : users)
        {
            memberName.put(u.ID, u.Name);
        }
        
		List<GroupMember> members = [Select Group.Name, UserOrGroupId from GroupMember where Group.Type = :CaseAppLiterals.QUEUE  and UserOrGroupId IN :  caseOwners];    
        for(GroupMember gm : members)
        {
            memberQueue.put(gm.UserOrGroupId, gm.Group.NAme);
        }
        system.debug('member' + memberQueue);
        List<Case_Owner_Change_Log__c> caseOwnerChangeLog = new List<Case_Owner_Change_Log__c>();
        Map<String, Decimal> teamSla = TeamSLA.getInstance().getTeamSLA();
        for(Case c  : caseS)
        {
            if(c.Status != CaseAppLiterals.CLOSED)
            {
                Case_Owner_Change_Log__c log = new Case_Owner_Change_Log__c();
                log.Case__c = c.ID;
                log.Start_Time__c = DateTime.now();
                log.Current_Owner__c = c.OwnerId;                
                log.Current_Owner_Queue__c = memberQueue.containsKey(c.OwnerId) ? memberQueue.get(c.OwnerId) : memberName.get(c.OwnerId);
                log.Defined_SLA_for_Current_Owner_Team__c = teamSla.get(log.Current_Owner_Queue__c);
                
                caseOwnerChangeLog.add(log);
            }
        }
        
        createCaseOwnerChanges(caseOwnerChangeLog);
    }
    
    public static void handleCaseUpdate(Map<ID, Case> oldMap, Map<Id,Case> newMap)
    {
       List<Case_Owner_Change_Log__c> caseOwnerChangeLogInsert = new List<Case_Owner_Change_Log__c>();
        List<Case_Owner_Change_Log__c> caseOwnerChangeLogUpdate = new List<Case_Owner_Change_Log__c>();
        Map<String, Integer> teamSla = TeamSLA.getInstance().getTeamSLA();
		Map<ID,String> memberQueue = new Map<ID, String>();
        Map<ID,String> queueIds = new Map<ID, String>();
        
        Set<ID> caseOwners = new Set<ID>();
          for(Case oldCase: oldMap.values())
        {
            system.debug('case number 00085737'+oldCase.CaseNumber);
             system.debug(oldCase.ownerid);
            caseOwners.add(oldCase.OwnerId);
        }
        
        // Get current case owner log
        List<Case_Owner_Change_Log__c>  existingLogs = [SELECT ID, Start_Time__c,End_Time__c, Case__c FROM Case_Owner_Change_Log__c WHERE Case__c IN : newMap.keySet()
                                                       and end_time__c = null];
		System.debug('exisiting log'+existingLogs);
        Map<ID, Case_Owner_Change_Log__c> existingChangeLog = new Map<ID, Case_Owner_Change_Log__c>();
        for(Case_Owner_Change_Log__c log : existingLogs)
        {
            existingChangeLog.put(log.Case__c, log);
        }
         for(Case newCase: newMap.values())
        {
            system.debug(newCase.ownerid);
            caseOwners.add(newCase.OwnerId);
        }
        System.debug('exisiting log'+existingChangeLog);
        System.debug('caseOwners'+caseOwners);
      
        
        List<GroupMember> members = [Select Group.Id,Group.Name, UserOrGroupId from GroupMember where Group.Type = :CaseAppLiterals.QUEUE  and (UserOrGroupId IN :  caseOwners OR Group.Id IN : caseOwners)];    
        
        List<Group> groupNames = [SELECT Id, Name FROM Group WHERE Type = : CaseAppLiterals.QUEUE];
        for(GroupMember gm : members)
        {
            memberQueue.put(gm.UserOrGroupId, gm.Group.Name);
            if(!queueIds.containsKey(gm.Group.Id))
            {
              queueIds.put(gm.Group.Id,gm.Group.Name);
        	}
        }
        
        for(Group gp : groupNames)
        {
            if(!queueIds.containsKey(gp.Id))
            {
               queueIds.put(gp.Id,gp.Name);
        	}
        }
        
       system.debug(queueIds);
        Map<ID,String> memberName = new Map<ID, String>();
        List<User> users = [SELECT ID, Name FROM User WHERE ID IN :caseOwners];
        for(User u : users)
        {
            memberName.put(u.ID, u.Name);
        }
        
        BusinessHours bh = [SELECT Id,MondayStarttime,MondayEndTime FROM BusinessHours WHERE  Name=:CaseAppLiterals.ORTHOFIBUSINESSHOURS];
            Time t = bh.MondayStartTime;
            Time t1 = bh.MondayEndTime;
        Long oneDayBusinessHrsInMilli = getMillisecondsFromTime(t,t1);
        Decimal oneDayBusinessHrs = getOneBusinessDayHours(t, t1);
        
        for(Case c: newMap.values())
        {
            
            Case oldCase = oldMap.get(c.id);
           // if(c.OwnerId != oldCase.OwnerId)
            //{
            
            
                if(existingChangeLog.containsKey(c.Id))
                {
                    //updat log for previous owner
                    Case_Owner_Change_Log__c oldLog = existingChangeLog.get(c.Id);
                    oldLog.End_Time__c = DateTime.Now();
                   
                    Decimal consumedSlaInMilliSec = BusinessHours.diff(String.valueOf(bh.Id), oldLog.Start_Time__c, oldLog.End_Time__c);
                    oldLog.SLA_Time__c = consumedSlaInMilliSec;
                    oldLog.Age__c = getAge(consumedSlaInMilliSec, oneDayBusinessHrsInMilli, oneDayBusinessHrs);
                    caseOwnerChangeLogUpdate.add(oldLog);
                }
            
                system.debug('new case owner' +c.OwnerId);
                system.debug('old case ownder'+oldcase.OwnerId);
                
            if(c.Status != 'Closed')
            { 
                // insert log for new owner
				Case_Owner_Change_Log__c log = new Case_Owner_Change_Log__c();
                log.Case__c = c.ID;
                log.Current_Owner__c = string.valueOf(c.ownerId).startsWith(CaseAppLiterals.USER_STARTCODE) ? c.OwnerId : null;
                log.Start_Time__c = DateTime.now();  
                
                // If owner id is of user, get queue name for user, if user does not belong to queue, enter user name as current owner queue
                log.Current_Owner_Queue__c = string.valueOf(c.ownerId).startsWith(CaseAppLiterals.USER_STARTCODE) ? (memberQueue.containsKey(c.OwnerId) ? memberQueue.get(c.OwnerId) : memberName.get(c.OwnerId) ): queueIds.get(c.OwnerId);
                log.Defined_SLA_for_Current_Owner_Team__c = teamSla.containsKey(log.Current_Owner_Queue__c) ? teamSla.get(log.Current_Owner_Queue__c) : CaseAppLiterals.USERSLA ; 
                log.Previous_Owner__c = string.valueOf(oldCase.ownerId).startsWith(CaseAppLiterals.USER_STARTCODE) ? oldCase.OwnerId : null;                
                System.debug('? log.Defined_SLA_for_Current_Owner_Team__c'+log.Defined_SLA_for_Current_Owner_Team__c);                
                // If owner id is of user, get queue name for user, if user does not belong to queue, enter user name as current owner queue
                log.Previous_Owner_Queue__c = string.valueOf(oldCase.ownerId).startsWith(CaseAppLiterals.USER_STARTCODE) ?  (memberQueue.containsKey(oldCase.OwnerId) ? memberQueue.get(oldCase.OwnerId) : memberName.get(oldCase.OwnerId) ) : queueIds.get(oldCase.OwnerId);
                caseOwnerChangeLogInsert.add(log);
                system.debug('--case number 00085737--'+caseOwnerChangeLogInsert);
            }
            //}
        }
        system.debug(caseOwnerChangeLogInsert);
         system.debug(caseOwnerChangeLogUpdate);
        
        if(caseOwnerChangeLogInsert!=null && caseOwnerChangeLogInsert.size() > 0)
        {
            Database.insert(caseOwnerChangeLogInsert);
        }
        
        if(caseOwnerChangeLogUpdate != null && caseOwnerChangeLogUpdate.size() > 0)
        {
            Database.update(caseOwnerChangeLogUpdate);
          //  CaseTriggerHandler.isFirstTime = false; 
        }
    }
    
    // Calculate Cumulative SLA
    public static void cumulativesla(Map<ID, Case> oldMap, Map<Id,Case> newMap){
         CaseTriggerHandler.isFirstRun = false;
        List<Case> closedCases = [Select id, Status from Case where Status =: CaseAppLiterals.CLOSED and id in: newMap.keyset()];
        Set<ID> closedCaseIds = new Set<ID>();
        for(Case c: closedCases){
            system.debug('Yess--- '+oldMap.get(c.id).Status);
            if(oldMap.get(c.id).Status != CaseAppLiterals.CLOSED){
                closedCaseIds.add(c.id);
            }
            
        }
        system.debug('Size---- '+closedCaseIds.size());
        
        List<Case_Owner_Change_Log__c>  existingLogs = [SELECT ID, Current_Owner_Queue__c, Start_Time__c,End_Time__c, SLA_Time__c, Case__c 
                                                        FROM Case_Owner_Change_Log__c WHERE Case__c IN : closedCaseIds];
        system.debug('?? Size of Case_Log--- '+existingLogs.size());
        if( existingLogs.size() > 0 || existingLogs!=null){
            Map<ID, List<Case_Owner_Change_Log__c>> mapCaseidtologs = new Map<ID, List<Case_Owner_Change_Log__c>>();
            for(Case_Owner_Change_Log__c log: existingLogs){
                if(mapCaseidtologs.containskey(log.Case__c)){
                    mapCaseidtologs.get(log.Case__c).add(log);
                }else{
                    List<Case_Owner_Change_Log__c> clogs = new List<Case_Owner_Change_Log__c>();
                    clogs.add(log);
                    mapCaseidtologs.put(log.Case__c, clogs);
                }
            }
            
            system.debug('??? Total Size-mapCaseidtologs'+mapCaseidtologs.values().size());
            
            //Cuml operation
            Map<ID, Map<String, Double>> mapCasetocumulQ =  new Map<ID, Map<String, Double>>();
            Map<String, Double> mapQSLA =  new Map<String, Double>();
            for(ID i:mapCaseidtologs.keyset()){
                for(Case_Owner_Change_Log__c log: mapCaseidtologs.get(i)){
                    if(mapQSLA.containskey(log.Current_Owner_Queue__c)){
                        Double d =  0;
                        d = log.SLA_Time__c +   mapQSLA.get(log.Current_Owner_Queue__c)  ;
                        mapQSLA.put(log.Current_Owner_Queue__c, d);
                    }else{
                        if(String.isNotBlank(log.Current_Owner_Queue__c)){
                            Double count = 0;
                            count = log.SLA_Time__c;
                            mapQSLA.put(log.Current_Owner_Queue__c, count);
                        }
                    }
                }
                mapCasetocumulQ.put(i, mapQSLA);
            }
            
            // ---- Team SLA from Metadata and Business Hours Standard Calculation ---
            Map<String, Decimal>  teamSlaMilliSecList = TeamSLA.getInstance().getTeamSLAInMilliSec();   
            Map<String, Integer> teamSla = TeamSLA.getInstance().getTeamSLA();
            
            BusinessHours bh = [SELECT Id,MondayStarttime,MondayEndTime FROM BusinessHours WHERE  Name=:CaseAppLiterals.ORTHOFIBUSINESSHOURS];
            Time t = bh.MondayStartTime;
            Time t1 = bh.MondayEndTime;
            Long oneDayBusinessHrsInMilli = CaseService.getMillisecondsFromTime(t,t1);
            Decimal oneDayBusinessHrs = CaseService.getOneBusinessDayHours(t, t1);
            //Millisec for User for 5 Day Defined SLA
            Decimal UserSLAinMls = CaseAppLiterals.USERSLA * oneDayBusinessHrsInMilli ;
            // !----- Team SLA from Metadata and Business Hours Standard Calculation ---
            
            // Insert Case-Log operation
            List<Case_Owner_Change_Log__c> logstoinsert = new List<Case_Owner_Change_Log__c>();
            for(ID i : mapCasetocumulQ.keyset() ){
                for( String s   :   mapCasetocumulQ.get(i) .keyset()  ){
                    Case_Owner_Change_Log__c log = new Case_Owner_Change_Log__c();
                    log.Case__c = i;
                    log.Start_Time__c = DateTime.now(); //change
                    log.End_Time__c = DateTime.now(); //change
                    log.SLA_Time__c = mapCasetocumulQ.get(i).get(s);
                    log.Age__c = CaseService.getAge(mapCasetocumulQ.get(i).get(s), oneDayBusinessHrsInMilli, oneDayBusinessHrs);
                    log.Defined_SLA_for_Current_Owner_Team__c = teamSla.containskey(s) ? teamSla.get(s) : CaseAppLiterals.USERSLA ;
                    log.Current_Owner_Queue__c = s;
                    log.IsRolledUp__c = true;
                    log.SlaMetNotMet__c = CaseService.checkSlaMetOrNot(String.valueOf( mapCasetocumulQ.get(i).get(s)), teamSlaMilliSecList.containskey(s) ? teamSlaMilliSecList.get(s) : UserSLAinMls) ? CaseAppLiterals.MET : CaseAppLiterals.NOTMET;
                    
                    logstoinsert.add(log);
                }
            }
            
            if(logstoinsert!=null && logstoinsert.size() > 0)
            {
                Database.insert(logstoinsert);
            }
        }
        
    }
    
   /* public static void handleCaseUpdate(Map<ID, sobject> oldMap, Map<Id,sobject> newMap)
    {
       List<Case_Owner_Change_Log__c> caseOwnerChangeLogInsert = new List<Case_Owner_Change_Log__c>();
        List<Case_Owner_Change_Log__c> caseOwnerChangeLogUpdate = new List<Case_Owner_Change_Log__c>();
        Map<String, Integer> teamSla = TeamSLA.getInstance().getTeamSLA();
		Map<ID,String> memberQueue = new Map<ID, String>();
        Map<ID,String> queueIds = new Map<ID, String>();
        
        Set<ID> caseOwners = new Set<ID>();
          for(Case oldCase: (List<Case>)oldMap.values())
        {
             system.debug(oldCase.ownerid);
            caseOwners.add(oldCase.OwnerId);
        }
        
        // Get current case owner log
        List<Case_Owner_Change_Log__c>  existingLogs = [SELECT ID, Start_Time__c,End_Time__c, Case__c FROM Case_Owner_Change_Log__c WHERE Case__c IN : newMap.keySet()
                                                       and end_time__c = null];
		System.debug('exisiting log'+existingLogs);
        Map<ID, Case_Owner_Change_Log__c> existingChangeLog = new Map<ID, Case_Owner_Change_Log__c>();
        for(Case_Owner_Change_Log__c log : existingLogs)
        {
            existingChangeLog.put(log.Case__c, log);
        }
         for(Case newCase: (List<Case>)newMap.values())
        {
            system.debug(newCase.ownerid);
            caseOwners.add(newCase.OwnerId);
        }
        System.debug('exisiting log'+existingChangeLog);
        System.debug('caseOwners'+caseOwners);
      
        
        List<GroupMember> members = [Select Group.Id,Group.Name, UserOrGroupId from GroupMember where Group.Type = :CaseAppLiterals.QUEUE  and (UserOrGroupId IN :  caseOwners OR Group.Id IN : caseOwners)];    
        
        List<Group> groupNames = [SELECT Id, Name FROM Group WHERE Type = : CaseAppLiterals.QUEUE];
        for(GroupMember gm : members)
        {
            memberQueue.put(gm.UserOrGroupId, gm.Group.Name);
            if(!queueIds.containsKey(gm.Group.Id))
            {
              queueIds.put(gm.Group.Id,gm.Group.Name);
        	}
        }
        
        for(Group gp : groupNames)
        {
            if(!queueIds.containsKey(gp.Id))
            {
               queueIds.put(gp.Id,gp.Name);
        	}
        }
        
       system.debug(queueIds);
        Map<ID,String> memberName = new Map<ID, String>();
        List<User> users = [SELECT ID, Name FROM User WHERE ID IN :caseOwners];
        for(User u : users)
        {
            memberName.put(u.ID, u.Name);
        }
        
        BusinessHours bh = [SELECT Id,MondayStarttime,MondayEndTime FROM BusinessHours WHERE Isdefault = true];
            Time t = bh.MondayStartTime;
            Time t1 = bh.MondayEndTime;
        Long oneDayBusinessHrsInMilli = getMillisecondsFromTime(t,t1);
        Decimal oneDayBusinessHrs = getOneBusinessDayHours(t, t1);
        
        for(Case c: (List<Case>)newMap.values())
        {
            Case oldCase = (Case)oldMap.get(c.id);
            if(c.OwnerId != oldCase.OwnerId)
            {
                system.debug('new case owner' +c.OwnerId);
                system.debug('old case ownder'+oldcase.OwnerId);
                
                // insert log for new owner
				Case_Owner_Change_Log__c log = new Case_Owner_Change_Log__c();
                log.Case__c = c.ID;
                log.Current_Owner__c = string.valueOf(c.ownerId).startsWith(CaseAppLiterals.USER_STARTCODE) ? c.OwnerId : null;
                log.Start_Time__c = DateTime.now();  
                
                // If owner id is of user, get queue name for user, if user does not belong to queue, enter user name as current owner queue
                log.Current_Owner_Queue__c = string.valueOf(c.ownerId).startsWith(CaseAppLiterals.USER_STARTCODE) ? (memberQueue.containsKey(c.OwnerId) ? memberQueue.get(c.OwnerId) : memberName.get(c.OwnerId) ): queueIds.get(c.OwnerId);
                log.Defined_SLA_for_Current_Owner_Team__c = teamSla.get(log.Current_Owner_Queue__c);
                log.Previous_Owner__c = string.valueOf(oldCase.ownerId).startsWith(CaseAppLiterals.USER_STARTCODE) ? oldCase.OwnerId : null;                
                                
                // If owner id is of user, get queue name for user, if user does not belong to queue, enter user name as current owner queue
                log.Previous_Owner_Queue__c = string.valueOf(oldCase.ownerId).startsWith(CaseAppLiterals.USER_STARTCODE) ?  (memberQueue.containsKey(oldCase.OwnerId) ? memberQueue.get(oldCase.OwnerId) : memberName.get(oldCase.OwnerId) ) : queueIds.get(oldCase.OwnerId);
                caseOwnerChangeLogInsert.add(log);
                
                if(existingChangeLog.containsKey(c.Id))
                {
                    //updat log for previous owner
                    Case_Owner_Change_Log__c oldLog = existingChangeLog.get(c.Id);
                    oldLog.End_Time__c = DateTime.Now();
                   
                    Decimal consumedSlaInMilliSec = BusinessHours.diff(String.valueOf(bh.Id), oldLog.Start_Time__c, oldLog.End_Time__c);
                    oldLog.SLA_Time__c = consumedSlaInMilliSec;
                    oldLog.Age__c = getAge(consumedSlaInMilliSec, oneDayBusinessHrsInMilli, oneDayBusinessHrs);
                    caseOwnerChangeLogUpdate.add(oldLog);
                }
            }
        }
        system.debug(caseOwnerChangeLogInsert);
         system.debug(caseOwnerChangeLogUpdate);
        
        if(caseOwnerChangeLogInsert!=null)
        {
            Database.insert(caseOwnerChangeLogInsert);
        }
        
        if(caseOwnerChangeLogUpdate != null)
        {
            Database.update(caseOwnerChangeLogUpdate);
        }
    }*/
    private static void createCaseOwnerChanges(List<Case_Owner_Change_Log__c> logs){
        system.debug('case case number 00085737'+logs);
        Database.insert(logs);
    }
    
    public static boolean checkSlaMetOrNot(string age, Decimal teamSla)
    {
        system.debug('age' + age);
         system.debug('teamSla' + teamSla);
        if(Decimal.valueOf(age) > teamSla)
        { 
            return false;
        }
        
        return true;
    }
    
    public static long getMillisecondsFromTime(Time t1, Time t2){
        if(t1!=null && t2!=null){
           return (t2.hour() - t1.hour())*60*60*1000 + (t2.minute() - t1.minute())*60*1000;
        }
        return null;
    } 
    
     public static Decimal getOneBusinessDayHours(Time t1, Time t2){
        if(t1!=null && t2!=null){
            Decimal timeAvailable = ((t2.hour() * 60 + t2.minute()) -
                     (t1.hour() * 60 + t1.minute()));
            
            timeAvailable = timeAvailable.divide(60,2);
            
            //Long abc = timeAvailable.divide(60,2);
            system.debug('KKKKKKKK'+timeAvailable + ' ' );
           return timeAvailable;
        }
        return null;
    } 
    
    public static string getAge(Decimal timeInMilliSeconds, Long oneDayBusinessHrsInMilli, Decimal oneDayBusinessHrs)
    {       
        system.debug(timeInMilliSeconds);
        // system.debug(timeInMilliSeconds.longValue());
             
         if(timeInMilliSeconds != null)
        {
            
            // 12.5
        //system.debug(math.floor(102600000/(1000*60*60*12.5)));
        //system.debug(Math.floor(Math.Mod(102600000, 45000000)/(60*60*1000)));
        //system.debug(math.floor(math.mod(math.Mod(102600000, 45000000),(60*60*1000))/(60*1000)));
         string output='';
            Decimal days =  (math.floor(timeInMilliSeconds/(1000*60*60*oneDayBusinessHrs)));
            
            if(days > 0 )
            {
                 output = Integer.valueof(days) + CaseAppLiterals.SPACE + CaseAppLiterals.DAY + CaseAppLiterals.SPACE;
            }
            
            Decimal hrs =  (Math.floor(Math.Mod(Integer.valueOf(timeInMilliSeconds), oneDayBusinessHrsInMilli)/(60*60*1000)));
             if(hrs > 0){
                 output = output + Integer.valueof(hrs) + CaseAppLiterals.SPACE + CaseAppLiterals.HOURS + CaseAppLiterals.SPACE;
            }
          
            Decimal min = (math.floor(math.mod(math.Mod(Integer.valueOf(timeInMilliSeconds), oneDayBusinessHrsInMilli),(60*60*1000))/(60*1000)));
            if(min> 0)
            {
                 output = output + Integer.valueof(min) + CaseAppLiterals.SPACE + CaseAppLiterals.MINUTES;
            } 
            system.debug(days + ' ' + hrs + ' ' + min);
            return output;
        }
        
        return '';
       /* if(timeInMilliSeconds != null)
        {
            Decimal seconds = timeInMilliSeconds/ 1000;
            Decimal minutes = seconds / 60;
            Decimal hours = minutes / 60;
            Decimal days = (hours / 12.5).longValue();
             system.debug(seconds);
             system.debug(hours);
             system.debug(minutes);
            system.debug(days);
                string output='';
                if(days > 0)
                {
                    output = days + CaseAppLiterals.SPACE + CaseAppLiterals.DAY + CaseAppLiterals.SPACE;
                }
                long hrs =Math.mod(hours,12);
                if(hrs > 0){
                    output = output + hrs + CaseAppLiterals.SPACE + CaseAppLiterals.HOURS + CaseAppLiterals.SPACE;
                }
                
                long min =  Math.mod(minutes, 60);
                if(min> 0)
                {
                    output = output + min + CaseAppLiterals.SPACE + CaseAppLiterals.MINUTES;
                }
                
                return output;                  
            }
            */
            //return output      										
    }
    
    public static boolean checkSlaMet(string age, integer teamSla)
    {      
          system.debug('teamSla' + teamSla);
        system.debug('age' + age);
        if(!age.contains('days'))
        {
            return true;
        }
        else
        {
            String dayValue = age.substringBefore(CaseAppLiterals.SPACE + CaseAppLiterals.DAYS);
          system.debug(dayValue);
            if(Integer.valueOf(dayValue)> teamSla)
            {
                return false;
            }
            else if(Integer.valueOf(dayValue)< teamSla)
            {
                return true;
            }
            else
            {
                if(age.contains(CaseAppLiterals.HOURS) || age.contains(CaseAppLiterals.MINUTES))
                {
                    return false;
                }
                return true;
            } 
        }
        //return true;
    }
}
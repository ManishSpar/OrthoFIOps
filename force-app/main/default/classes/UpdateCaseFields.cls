public class UpdateCaseFields implements Database.Batchable<sObject>{    

   public Database.QueryLocator start(Database.BatchableContext BC){
       string query='SELECT Followup_Date__c,Followup_Required__c,Id FROM Case WHERE Status = \'Pending\' AND Followup_Required__c = true AND Followup_Date__c = today';
       return Database.getQueryLocator(query);
   }

   public void execute(Database.BatchableContext BC, List<Case> scope){
              system.debug('---exe etod');
   for(case c :scope){
    c.By_Pass_Validation_Rule_through_Process__c=true;
   }
   update scope;
       // get the pending queueids
      List<Group> pendingIds =[SELECT Id FROM Group WHERE DeveloperName = 'Pending' AND Type = 'Queue' LIMIT 1];
       id queueId;
       if(pendingIds.size()==1){
             for(group g: pendingIds){
               queueId=g.id;
           }  
       }
   //    SELECT Id FROM Group WHERE Id :IN
       
       List<CaseHistory> lstCh=[SELECT Id,NewValue,OldValue FROM CaseHistory
                                WHERE Field IN ('Owner','ownerAssignment','ownerEscalated') and datatype ='EntityId' order by CreatedDate desc];
   List<string > ovl= new List<string>();
   
   for(CaseHistory chs:lstCh){
     string ovname =(string)chs.Oldvalue;  
     ovl.add(ovname);
   }
    List<Group> gs=[ SELECT Id FROM Group WHERE Id IN :ovl];
       map<string,string> onlyqueuesids= new Map<string,string>();
       for(Group g:gs){
           onlyqueuesids.put(g.id, g.id);           
       }
       for(case c :scope){
           for(CaseHistory ch:lstCh){  
                string oldvaluequeue =(string)ch.Oldvalue;
                string oldvalueswhichareTypequeue= onlyqueuesids.get(oldvaluequeue);
             //  system.debug(s);
               if(ch.NewValue!=queueId && ch.OldValue == oldvalueswhichareTypequeue ){
                  system.debug('--- newValues iss not pending and assing values is not userid'+ch.OldValue);        
                   c.Status='Follow up Required';                   
                   c.OwnerID = (Id)ch.NewValue;
               }               
           }           
       }
       system.debug('-before--'+scope);
       
       update scope;
       system.debug('-after--'+scope);
       
       for(case c :scope){
        c.By_Pass_Validation_Rule_through_Process__c=false;
       }
      update scope;
   }

   public void finish(Database.BatchableContext BC){
              system.debug('---finish etod');

   }
}
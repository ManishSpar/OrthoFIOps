public class CaseTriggerHandler extends TriggerHandler {
    /* Trigger Variables */
    List<Case> triggerNew;
    Map<Id,Case> triggerOldMap;
    Map<Id,Case> triggerNewMap;
    set<Id> caseIds = new Set<ID>();
    public static boolean isFirstRun = true;
    public CaseTriggerHandler() {
        triggerNew = (List<Case>) trigger.new;
        triggerOldMap = (Map<Id,Case>) trigger.oldMap;
        triggerNewMap = (Map<Id,Case>) trigger.NewMap;
        beforeInsertBeforeUpdate(triggerNew);
    }
    
    /* Constants */
    public static Id caseRecordID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Case Management').getRecordTypeId();
    public static Id caseSSRecordID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Self Service').getRecordTypeId();
    
    public static void beforeInsertBeforeUpdate(List<case> triggerNew){ 
        if(Trigger.isBefore || Trigger.isInsert){
            system.debug('-- update invoke');

            if(PreventDuplicateCase.runOnce()){
                PreventDuplicateCase.checkDuplicate(triggerNew);
            }
        }
    }
    /* Handle Trigger Events */
    public override void afterInsert(){
        try
        {
            List<Case> caseList = new List<Case>();
            Set<ID> caseOwners = new Set<ID>();
            for(Case newCase:triggerNew)
            {
                if(newCase.RecordTypeId == caseRecordID || newCase.RecordTypeId == caseSSRecordID)
                {
                    caseIds.add(newCase.Id);
                    caseOwners.add(newCase.OwnerId); 
                    caseList.add(newCase);
                }
            }
            
            entitlementAssignment(caseIds);
            runAssignmentRules(caseIds);
            
            if(caseList.size() > 0)
            {
                //add entry for current owner in case log
                 CaseService.handleCaseOwnerChange(caseList, caseOwners);
            }
        }catch(Exception ex){
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
    }
    
    public override void afterUpdate(){
        try
        {
            system.debug('after update');           
            set<Id> caseIdSet = new Set<ID>();
            Map<ID, Case> newCaseMap = new Map<ID, Case>();
            Map<ID, Case> oldCaseMap = new Map<ID, Case>();
            Group PatientIncomingQueue = [select Id from Group where Type = 'Queue' AND NAME = 'Patient Incoming Emails'];
            Group PracticeIncomingQueue = [select Id from Group where Type = 'Queue' AND NAME = 'Practice Incoming Emails'];            
            //System.debug('Incoming Email Queue ID>>>'+ IncomingQueue.Id);
            
            for(ID c: Trigger.newMap.keyset())
            {
               
                caseIds.add(c);
                Case oldCase = (Case)trigger.oldMap.get(c);
                Case newCase = (Case) trigger.NewMap.get(c);
                 if(newCase.RecordTypeId == caseRecordID || newCase.RecordTypeId == caseSSRecordID)
                {
                //if owner is changed or case is closed
                if((newCase.OwnerId != oldCase.OwnerId && oldCase.Status != 'Closed') ||  
                (newCase.Status == 'Closed' && triggerOldMap.get(newCase.id).Status != newCase.Status))
                {
                   newCaseMap.put(c, newCase);
                   oldcaseMap.put(c, oldCase);                    
                }
                    if(newCase.Origin == 'Email' && (newCase.OwnerId == PatientIncomingQueue.Id || newCase.OwnerId == PracticeIncomingQueue.Id) && newCase.SuppliedEmail != null && oldCase.Status == 'Draft' && 
                       (newCase.Status == 'New' || newCase.Status == 'In Progress')) {
                           System.debug('? case Id set creation for email2case');
                           caseIdSet.add(newCase.Id);
                    }
                }
            }//end of for
            if(caseIdSet.size() > 0)
            {
                System.debug('? case assignment rules for email2case');
                entitlementAssignment(caseIdSet);
                runAssignmentRules(caseIdSet);
            }
            
            if(newCaseMap.size() > 0)
            {
                CaseService.handleCaseUpdate(oldCaseMap, newCaseMap);
            }
            //call to update milestone status, add check for case status changed
            //add condition as (record type + case status old is not equals new + new status is equals to Inprogress or Closed)
            
            updateMilestoneStatus(triggerNew, triggerOldMap);
            
            //Calculate Cumulative SLA ffor Each Queue/user
            if(isFirstRun){
                CaseService.cumulativesla(triggerOldMap, triggerNewMap);
            }
        }catch(Exception ex){
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
        
    }
    
    //method to run assignment rules on case
    @future
    public static void runAssignmentRules(Set<ID> caseIds)
    {
        System.debug('? inside CaseTriggerHandler:runAssignmentRules');
        List<Id> caseIdList = new List<Id>(caseIds);
        AssignCaseBackToQueue.caseAssign(caseIdList);
        
    }
    
    //method to populate Entitlement on case
    @future
    public static void entitlementAssignment(Set<ID> caseIds)
    {
        List<Case> caseList = new List<Case>();
        
        for(Case newCase:[Select Id, Entitlement_ID__c, EntitlementId, Status, RecordTypeId  from case where Id in:caseIds ])
        {
            if(newCase.Entitlement_ID__c != null)
            {
                newCase.EntitlementId = newCase.Entitlement_ID__c;
                caseList.add(newCase);
            }
        }
        if(caseList.size() > 0){
            update caseList;
            //calling below method to mark Initial response milestone completed if status is In Progress while case creation
            updateMilestoneStatus(caseList, null);
        }
        
    }
    
    //method to update milestone status    
    public static void updateMilestoneStatus(List<Case> triggerNew, Map<Id,Case> triggerOldMap){
        System.debug('? inside CaseTriggerHandler:updateMilestoneStatus');
        Set<ID> caseIdSet = new Set<ID>();
        Map<Id,List<CaseMilestone>> caseMilestoneMap = new Map<Id,List<CaseMilestone>>();
        Map<String,Id> milestoneMap = new Map<String,Id>();
        List<CaseMilestone> updateMilestone = new List<CaseMilestone>();
        Boolean insertVar = false;              //variable to check if method is called afterInsert or afterUpdate 
        List<Case> caseList = new List<Case>();
        
        for(Case newCase:triggerNew)
        {
            if((newCase.Status == CaseAppLiterals.INPROGRESS || newCase.Status == CaseAppLiterals.CLOSED) && triggerOldMap == null && (newCase.RecordTypeId == caseRecordID || newCase.RecordTypeId == caseSSRecordID)){
                caseIdSet.add(newCase.Id);
                insertVar = true;
            }else if((newCase.Status == CaseAppLiterals.INPROGRESS || newCase.Status == CaseAppLiterals.CLOSED) && (newCase.Status != triggerOldMap.get(newCase.id).Status) && (newCase.RecordTypeId == caseRecordID || newCase.RecordTypeId == caseSSRecordID)){
                caseIdSet.add(newCase.Id);
            }
            
        }
        
        //retrieve milestone related to case
        if(!caseIdSet.isEmpty()){ 
            //prepare map of case 
            for(CaseMilestone caseMilestone:[SELECT Id, MilestoneTypeId, CaseId, CompletionDate, IsCompleted
                                             FROM CaseMilestone 
                                             WHERE CaseId  in: caseIdSet])
            {
                if(!caseMilestoneMap.containsKey(caseMilestone.CaseId))
                {
                    caseMilestoneMap.put(caseMilestone.CaseId, new List<CaseMilestone> {caseMilestone});
                }else{
                    caseMilestoneMap.get(caseMilestone.CaseId).add(caseMilestone);
                }
                
            }
            
            //get Milestone type in map
            for(MilestoneType milestone: [Select Id, Name from MilestoneType])
            {
                milestoneMap.put(milestone.Name, milestone.Id);
            }
            
            //check case status and update milestone accordingly
            for(Case newCase: triggerNew){
                System.debug('? inside case for loop');
                List<CaseMilestone> relatedMilestoneList = new  List<CaseMilestone>();
                relatedMilestoneList = caseMilestoneMap.get(newCase.Id);
                if(relatedMilestoneList.size() > 0){
                    for(CaseMilestone cm: relatedMilestoneList)
                    {
                        System.debug('? inside milestone for loop');
                        
                        if(newCase.Status == CaseAppLiterals.INPROGRESS && cm.MilestoneTypeId == milestoneMap.get('Initial Response'))
                        {
                            cm.CompletionDate = System.now();
                            updateMilestone.add(cm);
                            //below if-code part updates SLA respose fields for initial response milestone 
                            if(insertVar)
                            {
                                newCase.Initial_Response_SLA__c = CaseAppLiterals.MET;
                                newCase.Initial_Response_Time__c = System.now();
                                caseList.add(newCase);
                            }
                        }else if(newCase.Status == CaseAppLiterals.CLOSED && cm.MilestoneTypeId == milestoneMap.get('Resolution'))
                        {
                            cm.CompletionDate = System.now();
                            updateMilestone.add(cm);
                        }
                        
                    }//end loop for milestones on case
                }// end if loop for relatedmilestone empty check
            }// end loop for case
        }// end if for caseIds empty check
        if(caseList.size() > 0)
        {
            update caseList;
        }
        if(updateMilestone.size() > 0)
        {
            update updateMilestone;
        }
        
        
    }
}
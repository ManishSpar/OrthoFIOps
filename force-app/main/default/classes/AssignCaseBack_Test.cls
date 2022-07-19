@isTest
private class AssignCaseBack_Test {
    
    private static testMethod void doTest() {
        
        Test.startTest();
        Id accountRecordID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Logo').getRecordTypeId();
        Id caseRecordID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Case Management').getRecordTypeId();
        
        //create account
        Account ac = new Account();
        ac.RecordTypeId = accountRecordID;
        ac.Name = 'Test Business Account';
		user i = [select id from user where email in ('salesforce.admin@orthofi.com.invalid','salesforce.admin@orthofi.com') and IsActive =True limit 1];
		ac.OwnerId = i.id;
        ac.Status__c = 'Client';
        insert ac;      
        
         Insurance_Carrier__c ic = new Insurance_Carrier__c();
        ic.Name = 'IC';
        insert ic;
        //create case
        Case c = new Case(
            RecordTypeId = caseRecordID,
            Subject = 'Test case',
            Practice_Account__c = ac.Id,
            Status = 'In Progress',
            //Sub_Status__c='Pending Insurance Carrier',
            Type = 'Claims',
            Insurance_Carrier__c = ic.Id,
            Category__c = 'Insurance Claims - Request-Info/Action Needed from Subcriber/FRP');
        insert c;       
        
        List<Group> queueID = [SELECT Id from Group where name = 'Enrollment' LIMIT 1];
        ID previousOwner ;
        ID newOwner;
        list<ID> CaseId=new list<ID>();
        List<Case> caseList = [SELECT ID,OwnerId FROM CASe LIMIT 1];
        if(caseList.size() > 0)
        {
            //previousOwner = caselist[0].OwnerId;
            caseList[0].OwnerId = queueID[0].Id;
            previousOwner = queueID[0].Id;
            newOwner = queueID[0].Id;
            update caseList[0];
            for(Case cc : caseList)
            {
                CaseId.add(cc.Id);
            }
        }
        AssignCaseBackToQueue.CaseAssign(CaseId); 
        
        caseList = [SELECT ID,OwnerId FROM CASe LIMIT 1];
        if(caseList.size() > 0)
        {
            newOwner = caseList[0].Id;
        }
        Test.stopTest();
        system.assert(caseList[0].ownerid != null);
        system.assert(previousOwner != newOwner);
    }
}
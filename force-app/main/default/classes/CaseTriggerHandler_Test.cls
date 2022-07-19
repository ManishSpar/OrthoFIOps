@isTest
public class CaseTriggerHandler_Test {
    @testsetup
    public static void testdata(){
        Id accountRecordID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Logo').getRecordTypeId();
        Id caseRecordID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Case Management').getRecordTypeId();

        //get entitlement process
        Slaprocess sla = [Select Id, Name from slaProcess where Name = 'orthofisuccess entitlement 5 days process' limit 1];
        System.debug('? sla'+sla);
        
        //create account
        Account ac = new Account();
        ac.RecordTypeId = accountRecordID;
        ac.Name = 'Test Business Account';
        ac.Status__c = 'Client';
        insert ac;    
        
        
        //create entitlement
        Entitlement ec = new Entitlement();
        ec.AccountId = ac.Id;
        ec.Name = 'Test Entitlement';
        ec.SlaProcessId = sla.Id;
        insert ec;
       
        //create case
        Case c = new Case();
        c.RecordTypeId = caseRecordID;
        c.Subject = 'Test case';
        c.Practice_Account__c = ac.Id;
        c.Status = 'New';
        c.Description = 'Case created for testing';
        c.Entitlement_ID__c = ec.Id;
        c.EntitlementId = ec.Id;
        c.Type = 'Accounts Payable';
        c.Category__c = 'Orthofi Issued Refund-Inquiry';
        c.Action_Taken__c = 'Case created for testing';

        insert c;
        
    }
    /*
     Public static testmethod void caseDuplicatreCreation() {         
         Test.startTest();         
          Id accountRecordID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Logo').getRecordTypeId();
          Id accountPatientRecordID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patient').getRecordTypeId();
                //create account
        Account ac = new Account();
        ac.RecordTypeId = accountRecordID;
        ac.Name = 'Test Business Account';
        ac.Status__c = 'Client';
        insert ac;
        
         Account pac = new Account();
        pac.RecordTypeId = accountPatientRecordID;
        pac.LastName = 'Test user Account';
        pac.Status__c = 'Client';
        insert pac;
        
          List<case> lst = new List<case>();
          for(integer i=0;i<=1;i++){  
           Case casedup1 = new Case();
          //casedup1.RecordTypeId = caseRecordID;
             casedup1.Subject = 'Test case';
             casedup1.Practice_Account__c = ac.Id;
             casedup1.Patient_Account__c= pac.Id;
             casedup1.Status = 'New';
             casedup1.Description = 'Case created for testing';
            casedup1.Type = 'Accounts Payable';
            casedup1.Category__c = 'Orthofi Issued Refund-Inquiry';
            casedup1.Action_Taken__c = 'Case created for testing';
                 lst.add(casedup1);
        }
            insert lst;
         Set<id>  caseId= new Set<id>();
         for(case c: lst){
             caseId.add(c.id);
         }
       List<case> csl=[select Subject,Type,Category__c, Practice_Account__c,Patient_Account__c ,Status,Description from case where Id=:caseId];
            List<case> lstcase = new List<Case>();

         for(Case sc: csl){
               Case casedup1 = new Case();
        casedup1.Subject = sc.Subject;
        casedup1.Practice_Account__c = sc.Practice_Account__c;
        casedup1.Patient_Account__c= sc.Patient_Account__c;
        casedup1.Status = 'New';
        casedup1.Description = sc.Description;
        casedup1.Type = sc.Type;
        casedup1.Action_Taken__c = 'Case created for testing';
        casedup1.Category__c = sc.Category__c;
        casedup1.Allow_Duplicate_Case__c=false;
       
             lstcase.add(casedup1);       
         }
          insert lstcase;
             
        system.debug('---test class'+lst);
         system.debug('---casedup1'+lstcase);
        Test.stopTest();
     }
    
    */
    Public static testmethod void entitlementAssignmentTest() {
        Test.startTest();      
         //CaseTriggerHandler_Test.testdata();
        List<Case> caseList = [Select Id, Entitlement_ID__c, EntitlementId from case where subject = 'Test case'];
        System.debug('Case Entitlement'+ caseList[0].EntitlementId);
        System.assertEquals(caseList[0].EntitlementId, caseList[0].Entitlement_ID__c);
        //caseList[0].EntitlementId = '';
        /*
        caseList[0].Entitlement_ID__c = 'ABCD';
        update caseList;
        Set<Id> caseIds = new Set<ID>();
        caseIds.add(caseList[0].Id);
        CaseTriggerHandler.entitlementAssignment(caseIds);
        List<Exception_Logger__c> loggerList = new List<Exception_Logger__c>();
        loggerList = [Select Id from Exception_Logger__c];
        System.debug('loggerList'+loggerList);*/
        Test.stopTest();
        
    }
    
    //test for milestone status update
    Public static testmethod void updateMilestoneStatusTest() {
        Test.startTest();    
        //CaseTriggerHandler_Test.testdata();
        List<Case> caseList = [Select Id, Entitlement_ID__c, EntitlementId, Status, Initial_Response_Milestone_Success_Flag__c from case where subject = 'Test case'];
        System.debug('Case Entitlement'+ caseList[0].EntitlementId);
        caseList[0].status = 'In Progress';
        update caseList;
        System.assertEquals(caseList[0].Status , 'In Progress');
        Test.stopTest();
    }
}
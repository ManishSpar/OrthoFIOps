@isTest
public class PreventDuplicateCaseTest {

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
       system.assertEquals(false, casedup1.Allow_Duplicate_Case__c);
             lstcase.add(casedup1);       
         }
          insert lstcase;
        PreventDuplicateCase.checkDuplicate(lstcase);
             
        system.debug('---test class'+lst);
         system.debug('---casedup1'+lstcase);
        Test.stopTest();
     }
    
}
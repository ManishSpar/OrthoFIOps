@isTest
public class GetRelatedCaseOfAccount_Test {
    @isTest
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
        
        
        //create case
        Case c = new Case();
        c.RecordTypeId = caseRecordID;
        c.Subject = 'Test case';
        c.Practice_Account__c = ac.Id;
        c.Status = 'Open';
        c.Description = 'Case created for testing';
        
        c.Type = 'Accounts Payable';
        c.Category__c = 'Orthofi Issued Refund-Inquiry';
        c.Action_Taken__c = 'Case created for testing';

        insert c;
      
     	c = new Case();
        c.RecordTypeId = caseRecordID;
        c.Subject = 'Test case';
        c.Practice_Account__c = ac.Id;
        c.Status = 'Closed';
        c.Description = 'Case created for testing';
       
        c.Type = 'Accounts Payable';
        c.Category__c = 'Orthofi Issued Refund-Inquiry';
        c.Action_Taken__c = 'Case created for testing';

        insert c;
    List<Case> lstcases= LwcControllerGetRelatedCaseOfAccount.getContactsRelatedToAccount(ac.Id);
     system.assertEquals(lstcases.size(), 1);
     LwcControllerGetRelatedCaseOfAccount.getOpenCasesRelatedToAccount(ac.Id);
     system.assertEquals(lstcases.size(), 1);
         LwcControllerGetRelatedCaseOfAccount.getOpenCasesSearch(ac.Id,'test');
     system.assertEquals(lstcases.size(), 1);
         LwcControllerGetRelatedCaseOfAccount.getClosedCasesSearch(ac.Id,'test');
     system.assertEquals(lstcases.size(), 1);
     LwcControllerGetRelatedCaseOfAccount.getOpenCasesSearch(ac.Id,'');
     system.assertEquals(lstcases.size(), 1);
         LwcControllerGetRelatedCaseOfAccount.getClosedCasesSearch(ac.Id,'');
     system.assertEquals(lstcases.size(), 1);
         LwcControllerGetRelatedCaseOfAccount.countOfOpencase(ac.id);
     system.assertEquals(lstcases.size(), 1);
         LwcControllerGetRelatedCaseOfAccount.countOfClosedcase(ac.id);
     system.assertEquals(lstcases.size(), 1);
     LwcControllerGetRelatedCaseOfAccount.fetchCases(ac.Id,'test','Open','Status','asc');
     system.assertEquals(lstcases.size(), 1);
  
        
    }
}
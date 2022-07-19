@isTest
public class TeamSLAControllerTest {
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
		user i = [select id from user where email in ('salesforce.admin@orthofi.com.invalid','salesforce.admin@orthofi.com') and IsActive =True limit 1];
		ac.OwnerId = i.id;
        ac.Status__c = 'Client';
        insert ac;
        
        //create entitlement
        Entitlement ec = new Entitlement();
        ec.AccountId = ac.Id;
        ec.Name = 'Test Entitlement';
        ec.SlaProcessId = sla.Id;
        insert ec;
        
        Insurance_Carrier__c ic = new Insurance_Carrier__c();
        ic.Name = 'IC';
        insert ic;
        
        //create case
        Case c = new Case();
        c.RecordTypeId = caseRecordID;
        c.Subject = 'Test case';
        c.Practice_Account__c = ac.Id;
        c.Status = 'New';
        c.Description = 'Case created for testing';
        c.Entitlement_ID__c = ec.Id;
        c.EntitlementId = ec.Id;
        c.Type = 'Claims';
        c.Category__c = 'Insurance Claims - Request-Info/Action Needed from Subcriber/FRP';
        c.Insurance_Carrier__c = ic.Id;
        insert c;
        
        Group g =  [SELECT ID FROM GRoup WHERE Name = 'Enrollment' LIMIT 1];
        c.OwnerId = g.Id;
        update c;
    }
    
	public static testMethod void getTeamSLAFromMetadata()
    {
         Test.startTest();
         TeamSLAController.TeamSLAWrapper wrapper = TeamSLAController.getTeamSLAFromMetadata();
        
         System.assert(wrapper != null);
         Test.stopTest();
    }
    
    public static testMethod void getSLA()
    {
         Test.startTest();
         TeamSLAController.TeamSLAWrapper wrapper = TeamSLAController.getTeamSLAFromMetadata();
        
        Case c = [SELECT ID FROM CASE LIMIT 1];
         List<Map<string,string>> output = TeamSLAController.getSLA(c.Id, JSON.serialize(wrapper));
         System.assert(output != null);
        // System.assert(output.size() > 0);
         Test.stopTest();
    }
}
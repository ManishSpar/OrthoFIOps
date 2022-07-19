@isTest
public class PracticeAccountsOfTheLoggedInContactTest {
    static testMethod void validateSampleApex() {
        Id profileId = [Select Id From Profile Where Name ='System Administrator'].Id;
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'OrthoSuccess_Director' Limit 1];
         String orgId = UserInfo.getOrganizationId();  
        String dateString =String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');  
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));  
        String uniqueName = orgId + dateString + randomInt;  
        User tempUser = new User(  
            FirstName = 'Suit',  
            UserRoleId = userRole.Id,
            LastName = 'the original',  
            email = 'emailexm@sfdc.org',  
            Username = 'emailexm@sfdcorgId.org',  
            EmailEncodingKey = 'ISO-8859-1',  
            Alias = uniqueName.substring(18, 23),  
            TimeZoneSidKey = 'America/Los_Angeles',  
            LocaleSidKey = 'en_US',  
            LanguageLocaleKey = 'en_US',  
            ProfileId = profileId
        );   
          insert tempUser;
 System.runAs( tempUser ){
         Account acc = new Account();
     		acc.Name='Peter';
     		acc.PracticeLocationId__c=123321;
     
            insert acc;
     
     contact con = new contact();     
     con.AccountId=acc.id;
     con.LastName='test';
     insert con;
     Account personacc= new Account();
         personacc.Practice__c =acc.id;
         personacc.RecordTypeId=Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Patient').getRecordTypeId();
		 personacc.LastName='person account';
     
     insert personacc;
     
         Id democommunityuser = [Select Id From Profile Where Name ='Self Service Community Portal'].Id;
         User cmuser = new User(  
            FirstName = 'Suit',  
            LastName = 'thes original',  
            email = 'emaislexm@sfdc.org',  
            Username = 'emsailexm@sfdcorgId.org',  
            EmailEncodingKey = 'ISO-8859-1',  
            Alias = uniqueName.substring(18, 23),  
            TimeZoneSidKey = 'America/Los_Angeles',  
            LocaleSidKey = 'en_US',  
            LanguageLocaleKey = 'en_US',  
            contactid=con.id,
            ProfileId = democommunityuser
        );   
          insert cmuser;
        
        System.runAs( cmuser ){ 
                PracticeAccountsOfTheLoggedInContact.getAllRelatedPatientOfPracticeAccount();           
                PracticeAccountsOfTheLoggedInContact.getAllRelatedPatientAccountsCases('person account');

        }
 }
     
      
    }
    
    
}
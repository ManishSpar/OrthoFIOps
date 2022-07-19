@isTest
public class TestSendNotificationEmailToCase {
    @testSetup static void setup(){
        Account acc = new Account(Name='Shrunkhala');
        insert acc;
        Contact con = new Contact(FirstName='F', 
                                  Lastname='F', 
                                  Email='shrunkhala_fulzele@persistent.com', 
                                  Phone='9999999999');
        insert con;
        Case c = new Case(AccountId=[SELECT ID FROM Account where Name='Shrunkhala'].Id,
                          ContactId = [SELECT ID FROM Contact where Lastname='F'].Id,
                          Subject='Testing Email Template',
                          Type='Patient Care',
                          Category__c='PPA Issue',
                          Status='New',
                          Preferred_Method_of_Communication__c='Email',
                          Description='Testing Email Template',
                          Action_Taken__c = 'Case created for testing',
                          Origin='Phone'
                         );
        insert c;
		EmailMessage msgList= new EmailMessage(ParentId = [SELECT Id FROM Case where Subject='Testing Email Template'].Id);
		insert msgList;
    }
    @isTest private static void sendMailTest() {
        Id i = [SELECT Id FROM Case WHERE Contact.Email='shrunkhala_fulzele@persistent.com' LIMIT 1].Id; 
        List<id> mylist=new List<id>();
        mylist.add(i);
        	
        Test.startTest();
        SendNotificationEmailToCase.sendnotification(mylist);
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();
        System.assertEquals(1, invocations);
    }
}
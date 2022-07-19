@isTest
public class CreatePatientAccountCasesTest {
	@isTest
    static void testBulkCaseController() {
        Account acObj = new Account(Name='Sam');
        insert acObj;
        
        List<Account> lstAccounts = CreatePatientAccountCases.getPatientAccounts('Sam', 'Name', 'DESC', acObj.Id);
        
        CreatePatientAccountCases.createChildPatientCases(acObj.Id, '["'+acObj.Id+'"]', '{"Subject":"Test","Type":"Eligibility", "Category__c":"Eligibility - Escalation", "Action_Taken__c":"Test", "Description":"Test123","FCR__c":"true"}');
    }
}
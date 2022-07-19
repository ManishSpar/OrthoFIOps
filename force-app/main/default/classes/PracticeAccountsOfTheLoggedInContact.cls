public with sharing class PracticeAccountsOfTheLoggedInContact {
    

    @AuraEnabled
    public static List<Account> getAllRelatedPatientOfPracticeAccount(){
        User userContact =[SELECT ContactId FROM User WHERE id=:UserInfo.getUserId()];
        if(userContact!=null){
            set<id> accountid = new set<id>();
            for(contact con:[select Accountid,id from contact where id=:userContact.ContactId]){
                accountid.add(con.accountid);
            }
            List<Account> acc= [SELECT Practice__r.name,IsPersonAccount,id,Gender__pc,Name,OrthoFi_Patient_Record_URL__c,Patient_ID__c,PersonBirthdate,
            Phone,RecordType.name,PersonMailingAddress,PersonMailingCity,PersonMailingCountry,PersonMailingPostalCode,PersonMailingState,PersonMailingStreet FROM Account WHERE PersonContactId IN (SELECT ContactId FROM AccountContactRelation WHERE AccountId IN: accountid AND IsActive = true)];
            return acc;
        }else {
            return null;
        }
        
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Account> getAllRelatedPatientAccountsCases(String searchKey) {
        system.debug('search qeury invoke');
        User uObj = [SELECT Contact.AccountId FROM User WHERE Id =: UserInfo.getUserId()];

        Id practiceAccId = uObj.Contact.AccountId;
        String query = 'SELECT Practice__r.name,IsPersonAccount,id,Gender__pc,Name,OrthoFi_Patient_Record_URL__c,Patient_ID__c,PersonBirthdate,Phone,RecordType.name,PersonMailingAddress,PersonMailingCity,PersonMailingCountry,PersonMailingPostalCode,PersonMailingState,PersonMailingStreet FROM Account WHERE PersonContactId IN (SELECT ContactId FROM AccountContactRelation WHERE AccountId =:practiceAccId AND IsActive = true)';
        
        if ( String.isNotBlank(searchKey)) {
            String key = '%' + searchKey + '%';
            query += ' AND ( FirstName LIKE :key OR LastName LIKE :key OR Patient_ID__c LIKE :key)';
        }
       
        System.debug(query);
        return Database.query( query );
    }
}
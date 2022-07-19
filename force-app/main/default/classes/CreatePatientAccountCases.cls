public class CreatePatientAccountCases {
    @AuraEnabled(cacheable=true)
    public static List<Account> getPatientAccounts( String searchKey, String sortBy, String sortDirection, String PracticeId) {
       String query = 'SELECT Id, Name, Patient_ID__c, OrthoFi_Patient_Record_URL__c, PersonBirthdate, PersonMailingAddress FROM Account WHERE PersonContactId IN (select ContactId from AccountContactRelation where AccountId =: PracticeId and IsActive = true)';
       system.debug('query---'+query);
       if ( searchKey != null && searchKey != '' ) {
           String key = '%' + searchKey + '%';
           query += ' AND Name LIKE :key';
       }
       if ( sortBy != null && sortDirection != null ) {
           query += ' ORDER BY ' + sortBy + ' ' + sortDirection;
       }
       return Database.query( query );
    }

    @AuraEnabled
    public static Map<String,String> createChildPatientCases( String PracticeId, String AccountIds, String fieldsdataInput) {
        Map<String,String> response = new Map<String,String>();
        response.put('Message','Cases created for selected Patient Accounts.');
        response.put('Status','Success');
        try{
            Map<String,String> data = (Map<String,String>) JSON.deserialize(fieldsdataInput, Map<String,String>.class);
            List<String> accountIdsList = (List<String>) JSON.deserialize(AccountIds, List<String>.class);
            List<Case> newCases = new List<Case>();
            Id insuranceCarrierId = data.get('Insurance_Carrier__c') != null? Id.valueOf(data.get('Insurance_Carrier__c')): null;
            Id contactId = data.get('ContactId') != null? Id.valueOf(data.get('ContactId')): null;
            for(String accId: accountIdsList) {
                Case newCase = new Case(Subject= data.get('Subject'),
                                        Type=data.get('Type'),
                                        Category__c=data.get('Category__c'),
                                        Action_Taken__c=data.get('Action_Taken__c'),
                                        Origin='Phone',
                                        Description=data.get('Description'),
                                        Patient_Account__c = accId,
                                        AccountId = PracticeId,
                                        Status = data.get('Status'),
                                        Practice_Account__c = PracticeId,
                                        FCR__c= Boolean.valueOf(data.get('FCR__c')),
                                        Insurance_Carrier__c= insuranceCarrierId,
                                        ContactId= contactId
                                        );
                newCases.add(newCase);
            }
            insert newCases;
        } catch(Exception e) {
            response.put('Message',e.getMessage());
            response.put('Status','Error');
        }

        return response;
    }
}
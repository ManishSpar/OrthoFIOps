public without sharing class SearchController {

    @AuraEnabled(cacheable=true)
    public static List<FilterDataWrapper> search(String searchTerm, string myObject, String filter) {
        List<FilterDataWrapper> filterDataList = new List<FilterDataWrapper>();
        String myQuery = myObject == 'Account'? 'Select Id,Name, Patient_ID__c, PersonBirthdate, Practice__r.Name, PersonMailingStreet, PersonMailingCity, PersonMailingCountry, PersonMailingState, PersonMailingPostalCode': 'Select Id,Name';
        if(filter != null && filter != ''){
            if(myObject == 'Account') {
                if(searchTerm == null || searchTerm == '') {
                    myQuery += ' from '+myObject+' Where '+filter+' LIMIT  5';
                } else {
                    myQuery += ' from '+myObject+' Where Name Like  \'%' + searchTerm + '%\' AND '+filter+' LIMIT  5';
                }
            } else {
                myQuery += ' from '+myObject+' Where Name Like  \'%' + searchTerm + '%\' AND '+filter+' LIMIT  5';
            } 
        } else {
            if(searchTerm == null || searchTerm == ''){
                myQuery += ' from '+myObject+' Where LastViewedDate != NULL ORDER BY LastViewedDate DESC LIMIT  5';
            }
            else {
                myQuery += ' from '+myObject+' Where Name Like  \'%' + searchTerm + '%\' LIMIT  5';
            }
        }

        System.debug('Querystr>>'+myQuery);
        List<SObject> filterRecords = database.query(myQuery);

        for(SObject recordObj: filterRecords) {
            FilterDataWrapper dataWrapper = new FilterDataWrapper();
            dataWrapper.record = recordObj;
            if(myObject == 'Account') {
                Account acObj = (Account)recordObj;
                dataWrapper.guardianName = acObj.Practice__r.Name;
            }
            filterDataList.add(dataWrapper);
        }
        
        return filterDataList;
    }

    public class FilterDataWrapper {
        @AuraEnabled public sObject record;
        @AuraEnabled public String guardianName = '';
    }
}
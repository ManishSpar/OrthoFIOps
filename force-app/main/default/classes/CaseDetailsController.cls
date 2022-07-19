public without sharing class CaseDetailsController {
    @AuraEnabled
    public static Map<String,Map<String,String>> getPickListValuesForFilters(){
        Map<String,Map<String,String>> pickvaluesMap = new Map<String,Map<String,String>>{
            'Status' =>new Map<String,String>(),
            'SubStatus' =>new Map<String,String>(),
            'Type'=> new Map<String,String>()
        };
        Map<String,String> pickMap;
        for( Schema.PicklistEntry pickListVal : Case.Status.getDescribe().getPicklistValues()){
            pickMap = pickvaluesMap.get('Status');
            pickMap.put(pickListVal.getLabel(), pickListVal.getValue());
            pickvaluesMap.put('Status', pickMap);
        } 
        for( Schema.PicklistEntry pickListVal : Case.Sub_Status__c.getDescribe().getPicklistValues()){
            pickMap = pickvaluesMap.get('SubStatus');
            pickMap.put(pickListVal.getLabel(), pickListVal.getValue());
            pickvaluesMap.put('SubStatus', pickMap);
        } 
        for( Schema.PicklistEntry pickListVal : Case.Type.getDescribe().getPicklistValues()){
            pickMap = pickvaluesMap.get('Type');
            pickMap.put(pickListVal.getLabel(), pickListVal.getValue());
            pickvaluesMap.put('Type', pickMap);
        }  

        return pickvaluesMap;
    }

    @AuraEnabled(cacheable=true)
    public static List<Case> getClosedCases(String searchKey, String sortBy, String sortDirection, String substatus, String type, Integer pageSize, Integer pageNumber) {
       User uObj = [SELECT Contact.AccountId FROM User WHERE Id =: UserInfo.getUserId()];
       Integer offset = (pageNumber - 1) * pageSize;
       String query = 'SELECT Id,CaseNumber,Patient_Account__c,Patient_Account__r.Name,Subject,Status,Sub_Status__c,Type,Category__c,LastModifiedDate, LastModifiedBy.Name FROM Case WHERE Practice_Account__c =\''+uObj.Contact.AccountId+'\' AND Status = \'Closed\'';
        if ( String.isNotBlank(searchKey)) {
            String key = '%'+ searchKey +'%';
            List<String> termsList = searchKey.split(' ');
            String subquery = ' OR (';
            for(String term: termsList) {
                String whereTerm = '%'+term+'%';
                subquery += subquery==' OR ('?'(Patient_Account__r.FirstName LIKE :whereTerm OR Patient_Account__r.LastName LIKE :whereTerm)' : ' AND (Patient_Account__r.FirstName LIKE :whereTerm OR Patient_Account__r.LastName LIKE :whereTerm)';
            }
            subquery += ')';
            query += ' AND ( CaseNumber LIKE :key OR Patient_Account__r.Patient_ID__c LIKE :key '+subquery+')';
        }
        if ( String.isNotBlank(substatus)) {
            query += ' AND Sub_Status__c =: substatus';
        }
        if ( String.isNotBlank(type)) {
            query += ' AND Type =: type';
        }
        
        if ( String.isNotBlank(sortBy)) {
            query += ' ORDER BY ' + sortBy + ' ' + sortDirection;
        }
        query += ' LIMIT :pageSize OFFSET :offset';
       return Database.query( query );

    }

    @AuraEnabled(cacheable=true)
    public static List<Case> getAllOpenedCases(String searchKey, String sortBy, String sortDirection, String status, String substatus, String type, Integer pageSize, Integer pageNumber) {
        User uObj = [SELECT Contact.AccountId FROM User WHERE Id =: UserInfo.getUserId()];
        Integer offset = (pageNumber - 1) * pageSize;
        Set<String> statusSet = new Set<String>{'New', 'In Progress', 'Escalated', 'Pending', 'Follow Up Required'};
        String query = 'SELECT Id,CaseNumber,Patient_Account__c,Patient_Account__r.Name,Subject,Status,Sub_Status__c,Type,Category__c,LastModifiedDate, LastModifiedBy.Name FROM Case WHERE Practice_Account__c =\''+uObj.Contact.AccountId+'\' AND Status IN: statusSet';
        if ( String.isNotBlank(searchKey)) {
            String key = '%'+ searchKey +'%';
            List<String> termsList = searchKey.split(' ');
            String subquery = ' OR (';
            for(String term: termsList) {
                String whereTerm = '%'+term+'%';
                subquery += subquery==' OR ('?'(Patient_Account__r.FirstName LIKE :whereTerm OR Patient_Account__r.LastName LIKE :whereTerm)' : ' AND (Patient_Account__r.FirstName LIKE :whereTerm OR Patient_Account__r.LastName LIKE :whereTerm)';
            }
            subquery += ')';
            query += ' AND ( CaseNumber LIKE :key OR Patient_Account__r.Patient_ID__c LIKE :key '+subquery+')';
        }
        if ( String.isNotBlank(status)) {
            query += ' AND Status =: status';
        }
        if ( String.isNotBlank(substatus)) {
            query += ' AND Sub_Status__c =: substatus';
        }
        if ( String.isNotBlank(type)) {
            query += ' AND Type =: type';
        }
        
        if ( String.isNotBlank(sortBy)) {
            query += ' ORDER BY ' + sortBy + ' ' + sortDirection;
        }

        query += ' LIMIT :pageSize OFFSET :offset';
        return Database.query( query );
    }

    @AuraEnabled(cacheable=true)
    public static List<Case> getAllPendingCases(String searchKey, String sortBy, String sortDirection, String status, String substatus, String type, Integer pageSize, Integer pageNumber) {
        User uObj = [SELECT Contact.AccountId FROM User WHERE Id =: UserInfo.getUserId()];
        Integer offset = (pageNumber - 1) * pageSize;
     //   Set<String> statusSet = new Set<String>{'New', 'In Progress', 'Escalated', 'Pending', 'Follow Up Required'};
           Set<String> statusSet = new Set<String>{'Pending'};
        Set<String> substatusSet = new Set<String>{ 'Pending Practice Response'};
        String query = 'SELECT Id,CaseNumber,Patient_Account__c,Patient_Account__r.Name,Subject,Status,Sub_Status__c,Type,Category__c,LastModifiedDate, LastModifiedBy.Name FROM Case WHERE Practice_Account__c =\''+uObj.Contact.AccountId+'\' AND Status IN: statusSet AND Sub_Status__c IN: substatusSet';
        if ( String.isNotBlank(searchKey)) {
            String key = '%'+ searchKey +'%';
            List<String> termsList = searchKey.split(' ');
            String subquery = ' OR (';
            for(String term: termsList) {
                String whereTerm = '%'+term+'%';
                subquery += subquery==' OR ('?'(Patient_Account__r.FirstName LIKE :whereTerm OR Patient_Account__r.LastName LIKE :whereTerm)' : ' AND (Patient_Account__r.FirstName LIKE :whereTerm OR Patient_Account__r.LastName LIKE :whereTerm)';
            }
            subquery += ')';
            query += ' AND ( CaseNumber LIKE :key OR Patient_Account__r.Patient_ID__c LIKE :key '+subquery+')';
        }
        if ( String.isNotBlank(status)) {
            query += ' AND Status =: status';
        }
        if ( String.isNotBlank(substatus)) {
            query += ' AND Sub_Status__c =: substatus';
        }
        if ( String.isNotBlank(type)) {
            query += ' AND Type =: type';
        }
        if ( String.isNotBlank(sortBy)) {
            query += ' ORDER BY ' + sortBy + ' ' + sortDirection;
        }
        query += ' LIMIT :pageSize OFFSET :offset';
        return Database.query( query );
    }
}
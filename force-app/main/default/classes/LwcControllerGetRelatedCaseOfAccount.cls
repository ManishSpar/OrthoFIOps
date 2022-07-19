/*
Author :Basmah
email   :basmah.kaleem@sparsolutions.com
year of implementation:April 2022

purpose of the class
*/

public without sharing class LwcControllerGetRelatedCaseOfAccount {
    /*  
     /* @AuraEnabled(cacheable=true)
      public static List<Case> fetchCases(String accId, String searchKey, boolean isClosed,String sortBy, String sortDirection) {
         String strQuery = 'SELECT OwnerId,Type,Category__c, Sub_Status__c,Owner.Name,CaseNumber,Patient_Account__c,Contact.name,CreatedDate,Id,Patient_Account__r.name,Status,Subject '+
                          'FROM Case where Practice_Account__c = :accId';
          if (String.isNotBlank(searchKey)) {
              string key ='%'+searchKey+'%';
               strQuery = strQuery +' AND Patient_Account__r.name LIKE : key';
          }
          if(isClosed)
          {
              strQuery = strQuery +' AND Status =\'Closed\'';
          } 
          if ( String.isNotBlank(sortBy)) {
              strQuery =  strQuery +' ORDER BY ' + sortBy + ' ' + sortDirection;
          }       
          else {
              strQuery = strQuery +' AND Status !=\'Closed\'';
          }
            system.debug('@strQuery'+strQuery);
           //system.debug('@strQuery'+summary);
          List<Case> lstcas=Database.query(strQuery);
          return lstcas;
              
  }
  */
      @AuraEnabled(cacheable=true)
      public static List<Case> fetchCases(String accId, String searchKey, String status,String sortBy, String sortDirection) {
         String strQuery = 'SELECT OwnerId,Type,Category__c, Sub_Status__c,Owner.Name,CaseNumber,Patient_Account__c,Contact.name,CreatedDate,Id,Patient_Account__r.name,Status,Subject '+
                          'FROM Case where (Practice_Account__c = :accId OR AccountId = :accId)';
          if (String.isNotBlank(searchKey)) {
              string key ='%'+searchKey+'%';
               strQuery = strQuery +' AND Patient_Account__r.name LIKE : key';
          }
          if(status == 'Closed')
          {
              strQuery = strQuery +' AND Status =\'Closed\'';
          } 
          if(Status=='Open')
          {
              strQuery = strQuery +' AND Status !=\'Closed\'';
          }
          if(String.isNotBlank(Status)){
              strQuery = strQuery +' AND Status = :Status';
          }
          if ( String.isNotBlank(sortBy)) {
              strQuery =  strQuery +' ORDER BY ' + sortBy + ' ' + sortDirection;
          }       
                         
            system.debug('@strQuery'+strQuery);
           //system.debug('@strQuery'+summary);
          List<Case> lstcas=Database.query(strQuery);
          return lstcas;
      }    
  
  /*
  @AuraEnabled(cacheable=true)
  public static List<Case> filterListCase(string accId,String searchKey,String summary) {
     String strQuery = 'SELECT OwnerId,Type, Category__c,Sub_Status__c,Owner.Name,CaseNumber,Patient_Account__c,Contact.name,CreatedDate,Id,Patient_Account__r.name,Status,Subject '+
                      'FROM Case where Practice_Account__c = :accId';
      if (String.isNotBlank(summary)) {
          //string key ='%'+summary+'%';
          string key =summary;
           strQuery = strQuery +' AND Status =: Key';
      }else{
          if( String.isNotBlank(searchKey) &&  String.isNotBlank(summary)){
          string key ='%'+searchKey+'%';
          string statuss=summary;
           strQuery = strQuery +' AND Patient_Account__r.name LIKE : key  AND Status =: statuss';
          }
      }
      /*if(isClosed)
      {
          //strQuery = strQuery +' AND Status =\'Closed\'';
      }        
      else {
          strQuery = strQuery +' AND Status !=\'Closed\'';
      }
        system.debug('@strQuery'+strQuery);
        system.debug('@searchKey'+searchKey);
      List<Case> lstcas=Database.query(strQuery);
      return lstcas;
      //return lstcas;
          
  }
  
  */
      @AuraEnabled(cacheable=true)
      public static List<Case> getContactsRelatedToAccount(String accId) {
          system.debug('accId >> ' + accId);
          return [SELECT CaseNumber,OwnerId,Type,Category__c, Owner.Name,Patient_Account__c,Contact.name,CreatedDate,Id,Patient_Account__r.name,Status,Subject,contactId FROM Case where (Practice_Account__c = :accId OR AccountId = :accId) and Status='Closed' order by LastModifiedDate desc  limit 10];
  }
  
  @AuraEnabled(cacheable=true)
      public static List<Case> getOpenCasesRelatedToAccount(String accId) {
          system.debug('accId >> ' + accId);
          return [SELECT CaseNumber,OwnerId,Type,Category__c, Sub_Status__c,Owner.Name,Patient_Account__c,Contact.name,CreatedDate,Id,Patient_Account__r.name,Status,Subject ,contactId FROM Case where (Practice_Account__c = :accId OR AccountId = :accId) and Status !='Closed' order by LastModifiedDate desc  limit 10];
  }
  
  @AuraEnabled(cacheable=true)
      public static List<Case> getOpenCasesSearch(String accId, String PatientName) {
          if (String.isBlank(PatientName)) {
              return getOpenCasesRelatedToAccount(accId);
          }
          
              string key ='%'+PatientName+'%';
              List<Case> lstcas=[SELECT CaseNumber,OwnerId,Type,Category__c,Sub_Status__c, Owner.Name,Patient_Account__c,Contact.name,CreatedDate,Id,Patient_Account__r.name,Status,Subject FROM Case where (Practice_Account__c = :accId OR AccountId = :accId) and Patient_Account__r.name LIKE : key and Status !='Closed' ];
              return lstcas;
                  
  }
  
  
  @AuraEnabled(cacheable=true)
      public static List<Case> getClosedCasesSearch(String accId, String PatientName) {
          if (String.isBlank(PatientName)) {
              return getContactsRelatedToAccount(accId);
          }
          
              string key ='%'+PatientName+'%';
              List<Case> lstcas=[SELECT CaseNumber,OwnerId,Type, Category__c,Sub_Status__c,Owner.Name,Patient_Account__c,Contact.name,CreatedDate,Id,Patient_Account__r.name,Status,Subject FROM Case where (Practice_Account__c = :accId OR AccountId = :accId) and Patient_Account__r.name LIKE : key and Status ='Closed' ];
              return lstcas;
                  
  }
  
  @AuraEnabled(cacheable=true)
  public static Integer countOfOpencase(string accId){
     return [select count() from case where (Practice_Account__c = :accId OR AccountId = :accId) and Status !='Closed'];
  }
  
  @AuraEnabled(cacheable=true)
  public static Integer countOfClosedcase(string accId){
     return [select count() from case where (Practice_Account__c = :accId OR AccountId = :accId) and Status ='Closed'];
  }
  }
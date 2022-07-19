public with sharing class ViewAllCases {    

    
@AuraEnabled(cacheable=true)
public static List<Case> ViewAllOpenOrClosedCase(String accId,String searchKey, boolean Closed) {
    system.debug('accId >> ' + accId);
   
    List<case> ClosedCase= new List<case>();
    List<case>  OpenCase = new List<Case>();
    List<case> alllist=[SELECT CaseNumber,Contact.name,CreatedDate,Id,Patient_Account__r.name,Status,Subject FROM Case where Practice_Account__c = :accId order by LastModifiedDate desc  ];
system.debug('---'+alllist);
/*
    for(case c:alllist){
        if(c.Status!='Closed'){
            OpenCase.add(c);
        }else {
            ClosedCase.add(c) ;
        }

    }

if(Closed==true){
    return ClosedCase;
}else {
    return OpenCase;
}
*/

return alllist;
}
}
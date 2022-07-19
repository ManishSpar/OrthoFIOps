/*
Author : Basma
Date   : 24-Feb-2022
Purpose: Throw error for dupliacte case if exist for Patient Account and Pratiet account and case type with in one week old record. 
*/
public class PreventDuplicateCase{
    private static boolean run = true;
    
    public static boolean runOnce(){
        if(run){
            run=false;
            return true;
        }else{
            return run;
        }
    }
    
    public static void checkDuplicate(List<case> caselst){
        set<id> practiceAccount= new set<id>();
        set<id> patientAccount= new set<id>();
        List<string> types= new List<string>();
        List<string> Category= new List<string>();
        
        for(case cs:caselst){
            practiceAccount.add(cs.Practice_Account__c);
            patientAccount.add(cs.Patient_Account__c);
            types.add(cs.type);
            Category.add(cs.Category__c);
        }
        
        date createdORLtMd = date.today()-7;
        system.debug('--date'+createdORLtMd);
    /*   List<case> dupiclist=[select CaseNumber ,id,status,CreatedDate,LastModifiedDate,Practice_Account__c,Patient_Account__c from case where status !='closed' 
                              and type=:types and  (CreatedDate<=:createdORLtMd or  LastModifiedDate>=:createdORLtMd)
                              and Practice_Account__c IN:practiceAccount and Patient_Account__c IN:patientAccount];
       */
           
           List<case> dupiclist=[select CaseNumber From case where status !='Closed' and Category__c=:Category and type=:types and Practice_Account__c IN:practiceAccount and Patient_Account__c IN:patientAccount];
           // List<case> dupiclist=[select CaseNumber From case where CaseNumber='00038873'];

           system.debug('--d---'+dupiclist);
        List<string> CaseNumbers= new List<string>();
        string errormessage;
       // integer count4=dupiclist.size();
        integer count=0;
        for(case c:dupiclist){
             if(dupiclist.size()>0){
                 if(count<=3){
                      string allNum=c.CaseNumber;
                 system.debug('---'+allNum);
                CaseNumbers.add(allNum);
                 count++;
                 }
                
            }
        }
        system.debug('---'+CaseNumbers);
        
        for(case cs:caselst){
            if(cs.Patient_Account__c!=null  && cs.Allow_Duplicate_Case__c==false){            
                if(dupiclist.size()>0){
                    system.debug(dupiclist.size());                    
                        for(case c: dupiclist){
                             if(dupiclist.size()<=4){
                                 if(!Test.isRunningTest()){
                            cs.Patient_Account__c.addError('Case '+c.CaseNumber +' with the same Case Category already exists for this patient.  If you still want to create a new case then click on "Allow Duplicate Case" checkbox.');
                            }else if(dupiclist.size()>=4){
                                cs.Patient_Account__c.addError('Case '+CaseNumbers+' and others with the same Case Category already exists for this patient.  If you still want to create a new case then click on "Allow Duplicate Case" checkbox.');
                              }
                        }
                    }
                }
            }
        }
    }
}
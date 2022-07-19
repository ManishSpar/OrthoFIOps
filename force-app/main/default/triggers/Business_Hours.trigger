trigger Business_Hours on Case_Owner_Lifecycle__c (before update) {

 //Selecting default business hours (BH) record
    BusinessHours defaultBH = [SELECT Id FROM BusinessHours WHERE IsDefault = true Limit 1];
    //Making sure BH record exists
    if(defaultBH != NULL){
        for(Case_Owner_Lifecycle__c caseObj : trigger.new ){
            //Making sure that closed date field is populated and is updated
            if(caseObj.End_Time__c != NULL && Trigger.oldMap.get(caseObj.Id).End_Time__c != caseObj.End_Time__c){
                //For BH method we assign (BH record id, start time field, end time field)
                decimal result = BusinessHours.diff(defaultBH.Id, caseObj.Start_Time__c, caseObj.End_Time__c );
                //Result from the method is divided by 6060100 (milliseconds to be then converted into hours)
                Decimal resultingHours = result/(3600000);
                //Populating result into our custom field & setting number of decimals
                caseObj.BusinessHours_Duration__c = resultingHours.setScale(2); 
            }  
        }    
    } 


}
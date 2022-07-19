trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert) {
    List<User> currentUser = new List<User>();
    currentUser = [SELECT Id FROM User WHERE Profile.Name='Demo Customer Community User' AND Id=: Userinfo.getUserId()];
    
    if(currentUser.size() == 1) {
        Set<Id> caseIdSet = new Set<Id>();
        Map<String, Id> queueMap = new  Map<String, Id>();
        
        for(ContentDocumentLink att: Trigger.new){
            caseIdSet.add(att.LinkedEntityId);
        }
        
        if(caseIdSet.size() > 0) {
            List<Case> caseList = new List<Case>();
            Set<String> queueSet = new Set<String>();
            caseList = [select Id, OwnerId, Status, Sub_Status__c, (SELECT Queue_Name__c FROM Case_Owner_Lifecycles__r WHERE Queue_Name__c != null AND Queue_Name__c != 'Pending' ORDER By CreatedDate DESC LIMIT 1) from Case where Id IN: caseIdSet AND Status='Pending' and Sub_Status__c='Pending Practice Response' ];
            
            for(Case cObj: caseList) {
                if(cObj.Case_Owner_Lifecycles__r.size() > 0) {
                    queueSet.add(cObj.Case_Owner_Lifecycles__r[0].Queue_Name__c);
                }
            }
            
            if(queueSet.size() > 0) {
                for(Group queueObj: [SELECT Id,Name FROM Group WHERE Type='Queue' AND Name IN: queueSet]) {
                    queueMap.put(queueObj.Name, queueObj.id);
                }
            }
            
            for(Case cObj: caseList) {
                cObj.Status = 'Follow Up Required';
                cObj.Sub_Status__c = 'Practice Response Received';
                if(cObj.Case_Owner_Lifecycles__r.size() > 0 && queueMap.containsKey(cObj.Case_Owner_Lifecycles__r[0].Queue_Name__c)) {
                    cObj.OwnerId = queueMap.get(cObj.Case_Owner_Lifecycles__r[0].Queue_Name__c);
                }
            }
            update caseList;
        }
    }
}
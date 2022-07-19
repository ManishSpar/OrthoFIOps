trigger FeedItemTrigger on FeedItem (after insert) {
    System.debug(userinfo.getProfileId());
    System.debug(System.label.Experience_Cloud_Profile_ID);
    if(userinfo.getProfileId() == System.label.Experience_Cloud_Profile_ID){
        
        List<Case> closedCases = [SELECT Id FROM Case WHERE Id IN (SELECT ParentId FROM FeedItem where Id IN : Trigger.new) AND Status = 'Closed'];
        System.debug('Closed CASES -----'+closedCases);
        Set<Id> closedCasesIds = new Set<Id>();
        for(Case c : closedCases){
            closedCasesIds.add(c.Id);
        }
        for(FeedItem f:Trigger.new){
            if(closedCasesIds.contains(f.ParentId)){
                    f.addError(System.label.Post_Error_Message);
            }
        }
    }
}
trigger FeedCommentTrigger on FeedComment (after insert) {
    System.debug(userinfo.getProfileId());
    System.debug(System.label.Experience_Cloud_Profile_ID);
    if(userinfo.getProfileId() == System.label.Experience_Cloud_Profile_ID){
        List<Case> closedCases = [SELECT Id FROM Case WHERE Id IN (SELECT ParentId FROM FeedComment where Id IN : Trigger.new) AND Status = 'Closed'];
        System.debug('Closed CASES -----'+closedCases);
        Set<Id> closedCasesIds = new Set<Id>();
        for(Case c : closedCases){
            closedCasesIds.add(c.Id);
        }
        for(FeedComment fc:Trigger.new){
            if(closedCasesIds.contains(fc.ParentId)){
                    fc.addError(System.label.Post_Error_Message);
            }
        }
    }
}
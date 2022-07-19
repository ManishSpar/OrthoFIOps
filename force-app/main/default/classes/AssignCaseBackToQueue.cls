public class AssignCaseBackToQueue
{    
    @InvocableMethod
    public static void CaseAssign(List<Id> caseIds)
    {
        try
        {
            if(caseIds != null)
            {
                Database.DMLOptions dmo = new Database.DMLOptions();            
                
                dmo.assignmentRuleHeader.useDefaultRule= true;            
                
                List<Case> cases = [select id from case where case.id in :CaseIds];
                
                if(cases!=null && cases.size() > 0)
                {
                    for(Case c: cases)
                    {
                        c.setOptions(dmo);
                    }
                    system.debug(cases);
                    Database.update(cases, false);
                    
                }    
            }
            
        }catch(Exception ex){
            Logger.getInstance().exceptionList.add(ex);              
        }
        finally
        {
            List<Exception> expList = Logger.getInstance().exceptionList;
            if(expList != null && expList.size() > 0)
            {
                ExceptionLogger.log(expList);
                Logger.getInstance().exceptionList.clear();
            }
        }
    }
}
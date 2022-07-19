@isTest
public class Logger_Test {
    @testsetup
    public static void testdata()
    {
        try{
        Case c = new Case();
        c.Entitlement_ID__c = null;
        insert c;
        }
        Catch(Exception ex){
            Logger.getInstance().exceptionList.add(ex);
        }finally
        {
            List<Exception> expList = Logger.getInstance().exceptionList;
            if(expList != null && expList.size() > 0)
            {
                ExceptionLogger.log(expList);
                Logger.getInstance().exceptionList.clear();
            }
        }
    }
    
    Public static testmethod void Logger_Test()
    {
        Test.startTest();
        Logger_Test.testdata();
        Test.stopTest();
    }

}
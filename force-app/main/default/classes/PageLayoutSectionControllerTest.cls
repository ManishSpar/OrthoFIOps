@isTest
private class PageLayoutSectionControllerTest 
{
    static TestMethod void validateGetFieldsByFieldSetName()
    {
        //Unfortunately this is configuration dependent, but cant create Fieldsets programatically!
        //Test will fail if MgdActFees field set is missing from org
        List<String> fields = PageLayoutSectionController.getFieldsByFieldSetName('Quote', 'MgdActFees');      
        System.assert(fields.size()>0);

        List<String> fields2 = PageLayoutSectionController.getFieldsByFieldSetName('RandomObjectName', 'MgdActFees');      
        System.assert(fields2==null);

        List<String> fields3 = PageLayoutSectionController.getFieldsByFieldSetName('Quote', 'RandomFieldsetName');      
        System.assert(fields3==null);
    }

}
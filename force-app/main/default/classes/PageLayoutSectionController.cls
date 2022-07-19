public with sharing class PageLayoutSectionController {

    //Given an object and Field Set name, return the list fo field names
    @AuraEnabled(cacheable = true)
    public static List<String> getFieldsByFieldSetName(String objectApiName, String fieldSetName)
    {
        Schema.SObjectType describe = Schema.getGlobalDescribe().get(objectApiName);
        if(describe==null)
            return null;

        Schema.FieldSet fieldset = describe.getDescribe().FieldSets.getMap().get(fieldSetName);
        if(fieldset==null)
            return null;

        List<Schema.FieldSetMember> fieldSetMembers = fieldset.getFields();

        List<String> names = new List<String>();
        for(Schema.FieldSetMember fsm :fieldSetMembers )
        {
            names.add(fsm.sobjectfield.getDescribe().getName());
        }
        return names;

    }
}
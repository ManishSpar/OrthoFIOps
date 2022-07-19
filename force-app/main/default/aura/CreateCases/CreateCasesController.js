({
    createNewCase : function(component, event, helper) {
        component.set('v.isOpen', true);
        var flow = component.find("create_case");
        flow.startFlow("Create_Case_from_Community");
    },

    closeFlowModal : function(component, event, helper) {
        component.set("v.isOpen", false);
    },

    closeModalOnFinish : function(component, event, helper) {
        if(event.getParam('status') === "FINISHED") {
            component.set("v.isOpen", false);
        }
    }
})
trigger CaseTrigger on Case (after insert, after update,before insert) {
    //calling handler class for trigger logic
    new CaseTriggerHandler().run();
}
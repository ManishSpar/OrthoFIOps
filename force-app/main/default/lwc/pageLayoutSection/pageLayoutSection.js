import { LightningElement, api, wire } from 'lwc';
import getFieldsByFieldSetName from '@salesforce/apex/PageLayoutSectionController.getFieldsByFieldSetName';

export default class PageLayoutSection extends LightningElement
{
    @api recordId;              //the quote id, automatically populated
    @api objectApiName;         //Quote, automatically populated
    @api label;                 //the accordian label
    @api expanded   = false;    //the intial expanded/collapsed state
    @api columns    = 2;        //the number of columns
    @api readonly   = false;    //allow or prevent editing (obeys FLS regardless)
    @api density    ="auto";    //spacing & location of lables comfy/compact/auto
    @api fieldSetName   = null; //fields to be displayed

    @wire(getFieldsByFieldSetName, { objectApiName: '$objectApiName', fieldSetName: '$fieldSetName' })
        fields;                 //the field names

    get activeSection()
    {
        if(this.expanded) 
            return "accordianSection";
        return "";
    }

    get mode()
    {
        if(this.readonly)
            return "readonly";
        return "view";
    }

}
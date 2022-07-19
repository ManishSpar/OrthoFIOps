import searchFunction from '@salesforce/apex/SearchController.search';
import { api, LightningElement, track, wire } from 'lwc';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import NAME_FIELD from "@salesforce/schema/Account.Name";
const FIELDS = [NAME_FIELD];

export default class customLookUp extends LightningElement {
    @api objName;
    @api recordId;
    @api iconName;
    @api filter = '';
    @api fieldLabel;
    @api searchPlaceholder='Search';
    @api selectedName;
    @api selectedId;
    @track records;
    @track isValueSelected;
    @track blurTimeout;
    error;
    showRichResultsForAccount = false;
    searchTerm;
    @track boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    @track inputClass = '';

    @wire(getRecord, {
        recordId: '$recordId',
        fields:FIELDS
    })
    wiredAccountRecord({ error, data }) {
        if (data) {
            this.onSelect(null, this.recordId, data.fields.Name.value);
        } else {
            console.log('Error');
        }
    }

    connectedCallback() {
        if(this.objName == 'Account') {
            this.showRichResultsForAccount = true;
        }
    }

    @wire(searchFunction, {searchTerm : '$searchTerm', myObject : '$objName', filter : '$filter'})
    wiredRecords({ error, data }) {
        if (data) {
            this.error = undefined;
            this.records = data;
        } else if (error) {
            this.error = error;
            this.records = undefined;
        }
    }

    handleClick() {
        this.searchTerm = '';
        this.inputClass = 'slds-has-focus';
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open';
    }

    onBlur() {
        this.blurTimeout = setTimeout(() =>  {this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus'}, 300);
    }

    onSelect(event, patientd, patientName) {
        let selectedId = patientd != undefined ? patientd : event.currentTarget.dataset.id;
        this.selectedId = selectedId;
        let selectedName = patientName != undefined ? patientName : event.currentTarget.dataset.name;
        const valueSelectedEvent = new CustomEvent('lookupselected', {detail:  selectedId });
        this.dispatchEvent(valueSelectedEvent);
        this.isValueSelected = true;
        this.selectedName = selectedName;
        if(this.blurTimeout) {
            clearTimeout(this.blurTimeout);
        }
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    }

    handleRemovePill() {
        this.isValueSelected = false;
    }

    onChange(event) {
        this.searchTerm = event.target.value;
    }

}
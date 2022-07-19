import { LightningElement, wire, api, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPatientAccounts from '@salesforce/apex/CreatePatientAccountCases.getPatientAccounts';
import createPatientsCases from '@salesforce/apex/CreatePatientAccountCases.createChildPatientCases';

export default class CreatePatientAccountCases extends LightningElement {
    @api recordId;
    @track error;
    filterStr;
    @api sortedDirection = 'asc';
    @api sortedBy = 'Name';
    statusValue = 'New';
    @api searchKey = '';
    @track contactId;
    @track patientAccountIds = [];
    @track selection = [];
    casesSpinner = false;
    isCasePage = false;
    cardTitle = 'Patient Accounts';

    @track data; 
    @track columns =[{
        label: 'Name',
        fieldName: 'Name',
        type: 'text',
        sortable: true
    },
    {
        label: 'Mailing Address',
        fieldName: 'mailingaddress',
        type: 'text'
    },
    {
        label: 'Patient Id',
        fieldName: 'Patient_URL',
        type: 'url',
        sortable: true,
        typeAttributes: {
            label: {
                fieldName: 'Patient_ID__c'
            }
        }
    },
    {
        label: 'BirthDate',
        fieldName: 'PersonBirthdate',
        type: "date-local",
        typeAttributes:{
            month: "2-digit",
            day: "2-digit"
        },
        sortable: true
    }]; 

    renderedCallback() {
        this.filterStr = "AccountId = \'"+ this.recordId +"\' AND Contact_Title__c != 'Patient'";
    }

    @wire(getPatientAccounts, {searchKey: '$searchKey', sortBy: '$sortedBy', sortDirection: '$sortedDirection', PracticeId: '$recordId'})
    wiredAccounts({ error, data }) {
        if (data) { 
            var listViewData = [];
            for(let i=0; i< data.length; i++){
                var recordLink = data[i].OrthoFi_Patient_Record_URL__c.substring(data[i].OrthoFi_Patient_Record_URL__c.indexOf('>')+9,data[i].OrthoFi_Patient_Record_URL__c.indexOf('</a>'));
                var address = data[i].PersonMailingAddress != undefined ? data[i].PersonMailingAddress.street + ', ' + data[i].PersonMailingAddress.city + ', '+data[i].PersonMailingAddress.state + ', '+data[i].PersonMailingAddress.postalCode + ', '+data[i].PersonMailingAddress.country : "";
                listViewData.push({
                    "Id":data[i].Id,
                    "Name" : data[i].Name, 
                    "mailingaddress" : address,
                    "Patient_ID__c" : data[i].Patient_ID__c,
                    "Patient_URL" : recordLink, 
                    "PersonBirthdate" : data[i].PersonBirthdate});
            }
            this.data = listViewData;
            this.error = undefined;
            this.template.querySelector('[data-id="datarow"]').selectedRows = this.selection;
        } else if (error) {
            this.error = error;
            this.data = undefined;
        }
    }

    sortColumns( event ) {
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        return refreshApex(this.data);
    }
  
    handleAccountChange( event ) {
        this.searchKey = event.target.value;
        return refreshApex(this.data);
    }

    nextHandler() {
        var accountsSelected = this.patientAccountIds;
        if(this.patientAccountIds.length > 0) {
            this.isCasePage = true;
            this.cardTitle = 'New Patient Cases';
        } else {
            this.showToast('Error','Please select atleast one Patient Account.','info');
        }
    }

    previous() {
        this.isCasePage = false;
        this.cardTitle = 'Patient Accounts';
    }

    createCases(event) {
        this.casesSpinner = true;
        event.preventDefault();

        createPatientsCases({ PracticeId: this.recordId, AccountIds: JSON.stringify(this.patientAccountIds), fieldsdataInput: JSON.stringify(event.detail.fields)})
		.then(result => {
            if(result.Status == 'Success') {
                this.showToast(result.Status,result.Message,'success');
                this.dispatchEvent(new CloseActionScreenEvent());
            } else {
                this.showToast(result.Status,result.Message,'error');
                this.casesSpinner = false;
            }
		})
		.catch(error => {
			this.showToast('Error','Something went wrong while creating cases.','error');
            this.dispatchEvent(new CloseActionScreenEvent());
		})
        
    }

    getSelectedPatientAccounts(event) {
        const selectedRowsList = event.detail.selectedRows;

        this.patientAccountIds = [];
        for (let i = 0; i < selectedRowsList.length; i++) {
            this.patientAccountIds.push(selectedRowsList[i].Id);
        }

        let updatedItemsSet = new Set();
        let selectedItemsSet = new Set(this.selection);
        let loadedItemsSet = new Set();

        this.data.map((eventObj) => {
            loadedItemsSet.add(eventObj.Id);
        });

        if (selectedRowsList) {
            selectedRowsList.map((eventObj) => {
                updatedItemsSet.add(eventObj.Id);
            });

            updatedItemsSet.forEach((id) => {
                if (!selectedItemsSet.has(id)) {
                    selectedItemsSet.add(id);
                }
            });        
        }


        loadedItemsSet.forEach((id) => {
            if (selectedItemsSet.has(id) && !updatedItemsSet.has(id)) {
                selectedItemsSet.delete(id);
            }
        });

        this.selection = [...selectedItemsSet];
    }

    showToast(strTitle, strMessage, strType) {
        const event = new ShowToastEvent({
            title: strTitle,
            message: strMessage,
            variant: strType
        });
        this.dispatchEvent(event);
    }

    handleAccountSelection(event){
        this.contactId = event.detail;
    }

    changeStatus(event){
        if(event.detail.checked) {
            this.statusValue = 'Closed';
        } else {
            this.statusValue = 'New';
        }
    }
}
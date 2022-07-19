import { LightningElement, wire, api, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getClosedCases from '@salesforce/apex/CaseDetailsController.getClosedCases';

export default class ClosedCases extends LightningElement {
    @track error;
    @track data; 
    @api sortedDirection = 'asc';
    @api sortedBy = 'Status';
    @api searchKey = '';
    @api substatus = '';
    @api type = '';
    pageNumber = 1;
    pageSize = 5;
    dataSize = 0;
    disablePrev = true;
    disableNext = true;

    @track columns =[{
        label: 'Case Number',
        fieldName: 'CaseNumberUrl',
         type: 'url',
        typeAttributes: 
        {
            label: {fieldName: 'CaseNumber'},
            disabled: false,
            name: 'viewRecord'
        }
    },{
        label: 'Patient Name',
        fieldName: 'PatientName',
        type: 'text'
    },{
        label: 'Summary',
        fieldName: 'Subject',
        type: 'text'
    },{
        label: 'Status',
        fieldName: 'Status',
        type: "text",
        sortable: true
    },{
        label: 'Follow-up Sub Status',
        fieldName: 'Sub_Status__c',
        type: "text",
        sortable: true
    },{
        label: 'Type',
        fieldName: 'Type',
        type: "text",
        sortable: true
    },{
        label: 'Last Modified Date',
        fieldName: 'modifiedDate',
        type: "date"
    },{
        label: 'Last Modified By',
        fieldName: 'modifiedBy',
        type: "text"
    }]; 

    get fromRecords() {
        return ((this.pageNumber-1) * this.pageSize) +1;
    }

    get toRecords() {
        return (this.pageNumber-1) * this.pageSize + this.dataSize;
    }

    @wire(getClosedCases, {searchKey: '$searchKey', sortBy: '$sortedBy', sortDirection: '$sortedDirection', substatus: '$substatus', type: '$type', pageSize: '$pageSize', pageNumber: '$pageNumber'})
    wiredCases({ error, data }) {
        if (data) { 
            var listViewData = [];
            for(let i=0; i< data.length; i++){
                listViewData.push({
                    "Id":data[i].Id,
                    "CaseNumber" : data[i].CaseNumber,
                    "PatientName" : data[i].Patient_Account__c == undefined ? "" : data[i].Patient_Account__r.Name,
                    "Subject" : data[i].Subject, 
                    "Status" : data[i].Status,
                    "Sub_Status__c" : data[i].Sub_Status__c,
                    "Type" : data[i].Type,
                    "modifiedDate":data[i].LastModifiedDate,
                    "CaseNumberUrl":'/s/detail/' +data[i].Id,
                    "modifiedBy":data[i].LastModifiedBy.Name});
            }

            this.disableNext = listViewData.length < this.pageSize;
            this.disablePrev = this.pageNumber == 1;
            this.dataSize = listViewData.length;
            this.data = listViewData;
            this.error = undefined;
        } else if (error) {
            console.log('error'+ JSON.stringify(error));
            this.error = error;
            this.data = undefined;
        }
    }

    sortColumns( event ) {
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        return refreshApex(this.data);
    }

    handleNext(event) { 
        this.pageNumber = this.pageNumber+1;
    }
     
    handlePrev(event) {        
        this.pageNumber = this.pageNumber-1;
    }
}
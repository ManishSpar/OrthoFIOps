import { LightningElement, wire, api, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getAllOpenedCases from '@salesforce/apex/CaseDetailsController.getAllOpenedCases';
import getPickValues from '@salesforce/apex/CaseDetailsController.getPickListValuesForFilters';
import getAllPendingCases from '@salesforce/apex/CaseDetailsController.getAllPendingCases';
import {loadStyle} from 'lightning/platformResourceLoader'
import OrthoFiCSS from '@salesforce/resourceUrl/OrthoFi'

export default class AllOpenCases extends LightningElement {
    @track error;
    @track data; 
    @track pendingStatusData;
    @api sortedDirection = 'asc';
    @api sortedBy = 'Status';
    @api sortedDirectionPendingCases = 'asc';
    @api sortedByPendingCases = 'Status';
    @api searchKey = '';
    @track typeSelected;
    pageNumber = 1;
    subStatuspageNumber = 1;
    pageSize = 10;
    dataSize = 0;
    dataSizePendingCases = 0;
    disablePrev = true;
    disableNext = true;
    disablePrevPendingCases = true;
    disableNextPendingCases = true;
    isCssLoaded = false

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
        sortable: true,
        cellAttributes:{class : {fieldName:'cssClass'}}
    },{
        label: 'Type',
        fieldName: 'Type',
        type: "text",
        sortable: true
    },{
        label: 'Last Modified By',
        fieldName: 'LastModifiedByName',
        type: "text"
    },{
        label: 'Last Modified Date',
        fieldName: 'LastModifiedDate',
        type: "date-local",
        typeAttributes:{
            month: "2-digit",
            day: "2-digit"
        },
        sortable: true
    }];

    @track statusPicklist = [];
    @track subStatusPicklist = [];
    @track typePicklist = [];
    status = '';
    substatus = '';
    type = '';

    get fromRecords() {
        return ((this.pageNumber-1) * this.pageSize) +1;
    }

    get toRecords() {
        return (this.pageNumber-1) * this.pageSize + this.dataSize;
    }

    get fromRecordsPendingCase() {
        return ((this.subStatuspageNumber-1) * this.pageSize) +1;
    }

    get toRecordsPendingCase() {
        return (this.subStatuspageNumber-1) * this.pageSize + this.dataSizePendingCases;
    }

    connectedCallback() {
        getPickValues()
        .then(result => {
            let statusPickTemp = [{label: '-None-',value: ''}];
            let subStatusPickTemp = [{label: '-None-',value: ''}];
            let typePickTemp = [{label: '-None-',value: ''}];

            Object.entries(result.Status).forEach(([key, value]) => {
                statusPickTemp.push({label: `${key}`,value: `${value}`});
            });
            Object.entries(result.SubStatus).forEach(([key, value]) => {
                subStatusPickTemp.push({label: `${key}`,value: `${value}`});
            });
            Object.entries(result.Type).forEach(([key, value]) => {
                typePickTemp.push({label: `${key}`,value: `${value}`});
            });

            this.statusPicklist = statusPickTemp;
            this.subStatusPicklist = subStatusPickTemp;
            this.typePicklist = typePickTemp;
        })
        .catch(error => {
            this.error = error;
        });
    }

    renderedCallback(){ 
        if(this.isCssLoaded) return
        this.isCssLoaded = true
        loadStyle(this, OrthoFiCSS).then(()=>{
            console.log("Loaded Successfully")
        }).catch(error=>{ 
            console.error("Error in loading the OrthoFiCSS")
        })
    }

    @wire(getAllOpenedCases, {searchKey: '$searchKey', sortBy: '$sortedBy', sortDirection: '$sortedDirection', status: '$status', substatus: '$substatus', type: '$type', pageSize: '$pageSize', pageNumber: '$pageNumber'})
    wiredCases({ error, data }) {
        if (data) { 
            var listViewData = [];

            for(let i=0; i< data.length; i++){
                var cssSelectorClass = '';
                if(data[i].Sub_Status__c == 'Pending Practice Response') {
                    cssSelectorClass = 'highlighted-status';
                }

                listViewData.push({
                    "Id":data[i].Id,
                    "CaseNumber" : data[i].CaseNumber,
                    "PatientName" : data[i].Patient_Account__c == undefined ? "" : data[i].Patient_Account__r.Name,
                    "Subject" : data[i].Subject, 
                    "Status" : data[i].Status,
                    "Sub_Status__c" : data[i].Sub_Status__c,
                    "Type" : data[i].Type,
                    "LastModifiedDate" : data[i].LastModifiedDate,
                    "LastModifiedByName":data[i].LastModifiedBy.Name,
                    "CaseNumberUrl":'/s/detail/' +data[i].Id,
                    "cssClass": cssSelectorClass
                });
            } 

            this.disableNext = listViewData.length < this.pageSize;
            this.disablePrev = this.pageNumber == 1;
            this.dataSize = listViewData.length;
            this.data = listViewData;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.data = undefined;
        }
    }

    @wire(getAllPendingCases, {searchKey: '$searchKey', sortBy: '$sortedByPendingCases', sortDirection: '$sortedDirectionPendingCases', status: '$status', substatus: '$substatus', type: '$type', pageSize: '$pageSize', pageNumber: '$subStatuspageNumber'})
    wiredSubCase({ error, data }) {
        if (data) { 
            console.log('Sub status');
            var listViewData = [];

            for(let i=0; i< data.length; i++){
                var cssSelectorClass = '';
                if(data[i].Sub_Status__c == 'Pending Practice Response') {
                    cssSelectorClass = 'highlighted-status';
                }

                listViewData.push({
                    "Id":data[i].Id,
                    "CaseNumber" : data[i].CaseNumber,
                    "PatientName" : data[i].Patient_Account__c == undefined ? "" : data[i].Patient_Account__r.Name,
                    "Subject" : data[i].Subject, 
                    "Status" : data[i].Status,
                    "Sub_Status__c" : data[i].Sub_Status__c,
                    "Type" : data[i].Type,
                    "LastModifiedDate" : data[i].LastModifiedDate,
                    "LastModifiedByName":data[i].LastModifiedBy.Name,
                    "CaseNumberUrl":'/s/detail/' +data[i].Id,
                    "cssClass": cssSelectorClass
                });
            } 
            this.disableNextPendingCases = listViewData.length < this.pageSize;
            this.disablePrevPendingCases = this.subStatuspageNumber == 1;
            this.dataSizePendingCases = listViewData.length;
            this.pendingStatusData = listViewData;
            this.error = undefined;
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

    sortColumnsPendingCases( event ) {
        this.sortedByPendingCases = event.detail.fieldName;
        this.sortedDirectionPendingCases = event.detail.sortDirection;
        return refreshApex(this.pendingStatusData);
    }

    handleAccountChange( event ) {
        this.searchKey = event.target.value;
        return refreshApex(this.data);
    }

    filterChange(event) {
        var filterName = event.target.dataset.id;
        var value = event.detail.value;
        if(filterName == 'status') {
            this.status = value;
        } else if(filterName == 'substatus') {
            this.substatus = value;
        } else if(filterName == 'type'){
            this.type = value;
        }
        return refreshApex(this.data);
    }

    handleNext(event) { 
        this.pageNumber = this.pageNumber+1;
    }
     
    handlePrev(event) {        
        this.pageNumber = this.pageNumber-1;
    }

    SubStatushandlePrev(event){
        this.subStatuspageNumber = this.subStatuspageNumber-1;
    }
    SubStatushandleNext(event) { 
        this.subStatuspageNumber = this.subStatuspageNumber+1;
    }
    
}
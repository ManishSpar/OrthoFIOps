import { LightningElement,track,api,wire } from 'lwc';
import getViewAllCase from '@salesforce/apex/LwcControllerGetRelatedCaseOfAccount.fetchCases';
import { NavigationMixin } from 'lightning/navigation';// this will help to navigate next page
import getPickValues from '@salesforce/apex/CaseDetailsController.getPickListValuesForFilters';
import { refreshApex } from '@salesforce/apex'; // this will  help to refresh apex class

/**
 *This js file is used to show the open and closed case fro Account page. 
 this component is being reused twice. 
 */


export default class ViewAllOpenedCas extends NavigationMixin(LightningElement) {
@track statusValue='';
@api accountId;
//Added condition to fetch closed cases
@api 
get isClosed(){

}
set isClosed(value){
    if(value)
    this.statusValue ='Closed';
}
@track cases;
@track opencases;
@track searchKey='';
@track Summary='';

@track statusPicklists = [];
status = '';
@api sortedDirection = 'asc';
@api sortedBy = 'Status';
showFilter =false;  
connectedCallback() {
    getPickValues()
    .then(result => {
        let statusPickTemp = [{label: '--None--',value: ''}];       

        Object.entries(result.Status).forEach(([key, value]) => {
            statusPickTemp.push({label: `${key}`,value: `${value}`});
        });

        this.statusPicklists = statusPickTemp;
        
    })
    .catch(error => {
        this.error = error;
    });
}

//this method will help to invoke apex class and get record based on selection of status.

filterChange(event) {
    
    var filterName = event.target.dataset.id;
    var value = event.detail.value;
    console.log(' this.statusValue'+ value);
        this.statusValue = event.detail.value;
        console.log(' this.statusValue'+ this.statusValue);
    
    return refreshApex(this.wiredCaseResult);
}
// list of fields to display on component. 

@track columns = [
    { label: 'CaseNumber', fieldName: 'CaseNumberURL', type: 'url',
    typeAttributes: {
        label: {
            fieldName: 'CaseNumber'
        }
    }
    },
    { label: 'Contact Name', fieldName: 'ContactUrl', type: 'url',
    typeAttributes: {
        label: {
            fieldName: 'ContactId'
        }
    }
    },
    { label: 'Patient Name', fieldName: 'PatientNameUrl', type: 'url',
 typeAttributes: {
     label: {
         fieldName: 'Patient_Account__c'
     }
 }
 },
            { label: 'Summary', fieldName: 'Subject', type: 'text' , title: 'Subject'  },
    { label: 'Status', fieldName: 'Status', type: 'text', sortable: true },   
    { label: 'Type', fieldName: 'Type', type: 'text' },
                { label: 'Category', fieldName: 'Category__c', type: 'text', typeAttributes: { title: { fieldName: 'Subject' }} },
                { label: 'Followup Sub Status', fieldName: 'Sub_Status__c', type: 'text' },         
   { label: 'Date Opened', fieldName: 'CreatedDate', type: 'date' } ,
    { label: 'Owner', fieldName: 'OwnerUrl', type: 'url',
 typeAttributes: {
     label: {
         fieldName: 'OwnerName'
     }
 }
 }           

];

// sort status value 
sortColumns( event ) {
    this.sortedBy = event.detail.fieldName;
    this.sortedDirection = event.detail.sortDirection;
    return refreshApex(this.wiredCaseResult);
}

    formatCaseData(data){
        let records =JSON.parse( JSON.stringify(data));
        this.error = undefined;
        let conid        
       records.forEach(caseRec => {
        if(caseRec.OwnerId){
            caseRec.OwnerUrl = '/lightning/r/User/' +caseRec.OwnerId+'/view';
            caseRec.OwnerName = caseRec.Owner.Name;
        }
        if(caseRec.ContactId){
            conid=caseRec.ContactId;
            caseRec.ContactUrl = '/lightning/r/Contact/' +caseRec.ContactId+'/view';
            caseRec.ContactId = caseRec.Contact.Name;
        }
        if(caseRec.Patient_Account__c){
            caseRec.PatientNameUrl='/lightning/r/Account/' +caseRec.Patient_Account__c+'/view';
            caseRec.Patient_Account__c = caseRec.Patient_Account__r.Name;
        }
    });

        records.forEach(item => item['CaseNumberURL'] = '/lightning/r/Case/' +item['Id'] +'/view');
       // records.forEach(item => item['ContactUrl'] = '/lightning/r/Contact/' +conid+'/view');
       return records;    
        console.log( 'Open case '+this.opencases);
    
    }
    searchCase(event){        
        this.searchKey = event.target.value;        
    }
    /*searchSummary(event){
        this.summary = event.target.value;
    }*/
    



    @wire(getViewAllCase, {accId: '$accountId',searchKey: '$searchKey' , status:'$statusValue',sortBy: '$sortedBy', sortDirection: '$sortedDirection'}) 
    WireAllCaseRecords(result){
        this.wiredCaseResult = result;
        if(result.data){
            this.opencases = this.formatCaseData(result.data);
            this.error = undefined;
        }else{
            this.error = result.error;
            this.opencases = [];
        }
    }
// filterList check and unchecked  

    handleFilterClick(event){
        this.showFilter =!this.showFilter;
 
    }

    

//click on  new button open new case page
    createcase() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Case',
                actionName: 'new'
            }
        });
    }


}
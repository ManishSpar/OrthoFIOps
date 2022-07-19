import { LightningElement ,api,track,wire} from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getAllRelatedAccounts from '@salesforce/apex/PracticeAccountsOfTheLoggedInContact.getAllRelatedPatientOfPracticeAccount';
import getAllRelatedPatientAccountsCases from '@salesforce/apex/PracticeAccountsOfTheLoggedInContact.getAllRelatedPatientAccountsCases';

export default class PracticeAccountsOfTheLoggedInContact extends LightningElement {
    @track data;   
    @api searchKey = ''; 

    
    @track columns = [      
    { label: 'Patient Name', fieldName: 'patientNameUrl', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'Name'
            }
        }
    },
    { label: 'Patient ID', fieldName: 'PatientIDUrl', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'Patient_ID__c'
            }
        }
    },  
     { label: 'Birthdate', fieldName: 'PersonBirthdate', type: 'date' },
     { label: 'Phone', fieldName: 'Phone', type: 'text' } ,
     { label: 'Gender', fieldName: 'Gender__pc', type: 'text' }, 
     { label: 'Mailing Address', fieldName: 'PersonMailingAddress', type: 'text' }, 
     { label: 'OrthoFi Patient Record URL', fieldName: 'OrthoFiPatientRecordURL', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'OrthoFi_Patient_Record_URL__c'
            }
        }
    }
    ];

connectedCallback() {
    getAllRelatedAccounts()
        .then(result => {
            this.data =  this.formatCaseData(result);
        })
        .catch(error => {
            console.log('Error'+JSON.stringify(error));
        });
}

handleAccountChange( event ) {
    this.searchKey = event.target.value;
    console.log('log search key'+this.searchKey);     
    return refreshApex(this.getAllRelatedPatientAccountsCases);
}

@wire(getAllRelatedPatientAccountsCases, {searchKey: '$searchKey'})
    wiredPatientAccounts({  data,error }) {
        if(data){
        console.log('----hit search key'+data);           
        this.data =  this.formatCaseData(data);
        console.log('the data is after search is'+this.data);
    }
    else if (error) {
        this.error = error; 
        this.data = undefined;
    }
}
    
formatCaseData(data){
    let records =JSON.parse( JSON.stringify(data));
    this.error = undefined;
    records.forEach(item => item['patientNameUrl'] = '/s/detail/' +item['Id'] );
    records.forEach(item => item['PatientIDUrl'] = '/s/detail/' +item['Id'] );
    console.log(records);
    records.forEach(caseRec => {
        if(caseRec.OrthoFi_Patient_Record_URL__c){
            caseRec.OrthoFi_Patient_Record_URL__c =caseRec.OrthoFi_Patient_Record_URL__c.split('_blank">')[1].replace('</a>','');
            caseRec.OrthoFiPatientRecordURL=caseRec.OrthoFi_Patient_Record_URL__c ;
        }
        if(caseRec.PersonMailingAddress){
            var mailingAddress = [caseRec.PersonMailingCity,caseRec.PersonMailingCountry,caseRec.PersonMailingPostalCode,caseRec.PersonMailingState,caseRec.PersonMailingStreet];
            var filtered = mailingAddress.filter(function(x){
                return x != undefined;
            })
            caseRec.PersonMailingAddress =  filtered.join(", ");
        }
    });
    return records; 
}
}
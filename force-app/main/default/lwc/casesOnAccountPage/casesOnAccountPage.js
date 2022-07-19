import { LightningElement, track, wire, api  } from 'lwc';
import getCaseRelatedToAccount from '@salesforce/apex/LwcControllerGetRelatedCaseOfAccount.getContactsRelatedToAccount';
import getOpenCasesToAccount from '@salesforce/apex/LwcControllerGetRelatedCaseOfAccount.getOpenCasesRelatedToAccount';
import getOpenCaseCount from '@salesforce/apex/LwcControllerGetRelatedCaseOfAccount.countOfOpencase';
import getClosedCaseCount from  '@salesforce/apex/LwcControllerGetRelatedCaseOfAccount.countOfClosedcase';
import getSearchCases from '@salesforce/apex/LwcControllerGetRelatedCaseOfAccount.getOpenCasesSearch';
import getClosedSearchCases from '@salesforce/apex/LwcControllerGetRelatedCaseOfAccount.getClosedCasesSearch';
import { NavigationMixin } from 'lightning/navigation';

export default class CasesOnAccountPage extends NavigationMixin(LightningElement) {
    @api recordId;
    @track cases;
    @track openCaseCount;
    @track closeCaseCount;
    @track opencases;


    @track ClosedSearchKey = '';
    @track ClosedCasesSearched;
    @track ClosedCaseerror;


    @track searchKey = '';
    @track casesSearched;
    @track error;

    searchClosedCase(event){        
        this.ClosedSearchKey = event.target.value;        
    }

    @wire(getClosedSearchCases, {   accId: '$recordId',  PatientName:'$ClosedSearchKey'})
    wiredClosedCases({data, error}){
        if(data){
            this.cases = this.formatCaseData(data);
            this.ClosedCaseerror = undefined;
        }
        else if (error) {
            this.ClosedCaseerror = error;
            this.ClosedCasesSearched = undefined;
        }
    }

    handleNavigate() {
        console.log('navigation hit');
        var compDefinition = {
            componentDef: "c:viewAllOpenedCase",
            attributes: {
                accountId: this.recordId ,
                isClosed : false               
            }
        };
        // Base64 encode the compDefinition JS object
        var encodedCompDef = btoa(JSON.stringify(compDefinition));
        console.log(encodedCompDef);
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/one/one.app#' + encodedCompDef
            }
        });
    }

    
    handleNavigateCaseClosed() {
        console.log('navigation hit');
        var compDefinition = {
            componentDef: "c:viewAllOpenedCase",
            attributes: {
                accountId: this.recordId,
                isClosed : true                
            }
        };
        // Base64 encode the compDefinition JS object
        var encodedCompDef = btoa(JSON.stringify(compDefinition));
        console.log(encodedCompDef);
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/one/one.app#' + encodedCompDef
            }
        });
    }

    createcase() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Case',
                actionName: 'new'
            }
        });
    }



    searchOpenCase(event){        
        this.searchKey = event.target.value;        
    }
 
    @wire(getSearchCases, {   accId: '$recordId',  PatientName:'$searchKey'})
    wiredContacts({data, error}){
        if(data){
            this.opencases =  this.formatCaseData(data);
        }
        else if (error) {
            this.error = error;
            this.casesSearched = undefined;
        }
    }


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
                { label: 'Summary', fieldName: 'Subject', type: 'text' },
                { label: 'Type', fieldName: 'Type', type: 'text' },
                { label: 'Category', fieldName: 'Category__c', type: 'text' },
                { label: 'Followup Sub Status', fieldName: 'Sub_Status__c', type: 'text' },
        { label: 'Status', fieldName: 'Status', type: 'text' },            
     //   { label: 'Contact Name', fieldName: 'ContactId', type: 'text' },
       // { label: 'Patient Name', fieldName: 'Patient_Account__c', type: 'text' },
        { label: 'Date Opened', fieldName: 'CreatedDate', type: 'date' }  ,          
        { label: 'Owner', fieldName: 'OwnerUrl', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'OwnerName'
            }
        }
    }
    ];

   
    
    @wire(getCaseRelatedToAccount, {accId: '$recordId'}) 
    WireCaseRecords({error, data}){
        if(data){            
           let records =JSON.parse( JSON.stringify(data));
           this.error = undefined;

                    
            this.cases = this.formatCaseData(data);
            this.error = undefined;
        }else{
            this.error = error;
            this.cases = undefined;
        }
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
     
    @wire(getOpenCasesToAccount, {accId: '$recordId'}) 
    WireOpenCaseRecords({error, data}){
        if(data){
            this.opencases =  this.formatCaseData(data);
        }else{
            this.error = error;
            this.opencases = undefined;
        }
          
    }

    @wire(getClosedCaseCount, {accId: '$recordId'}) 
    WireCloseCaseCount({error, data}){
        if(data){
            this.closeCaseCount = data;
            this.error = undefined;
            console.log( 'Count of  close case '+this.closeCaseCount);
        }else{
            this.error = error;
            this.closeCaseCount = undefined;
        }
    }

    @wire(getOpenCaseCount, {accId: '$recordId'}) 
    WireOpenCaseCount({error, data}){
        if(data){
            this.openCaseCount = data;
            this.error = undefined;
            console.log('Count of  close case '+this.openCaseCount);
        }else{
            this.error = error;
            this.openCaseCount = undefined;
        }
    }

    handleSearch(event){
        this.searchKey= event.target.value;
        console.log(searchKey);
    }
}
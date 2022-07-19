import { LightningElement, api, track, wire } from 'lwc';
import getSlaDetails from '@salesforce/apex/TeamSLAController.getSLA';
import getSlaFromMetadata from '@salesforce/apex/TeamSLAController.getTeamSLAFromMetadata';

const columns = [
    { label: 'Team Name/User Name', fieldName: 'TeamName', type: 'text' },
    { label: 'Assigned SLA', fieldName: 'AssignedSLA', type: 'text' },
    { label: 'Consumed SLA', fieldName: 'ConsumedSLA', type: 'text' },
    { label: 'SLA Met?', fieldName: 'SLAMet', type: 'text' }
];

export default class TeamSLA extends LightningElement {
    @api recordId;
    recordsToDisplay = [];
    columns = columns;
    error;
    customMetadata;
    connectedCallback()
    {
        this.getTeamSlaFromMetadata();
       
    }

    getTeamSlaFromMetadata()
    {
        getSlaFromMetadata()
        .then((result) => {
            console.log('after metadata'+JSON.stringify(result));
            this.customMetadata = result;
           this.handleSla(result);
        })
        .catch((error) => {
            this.error = error;               
        });
    }
    
    refreshComponent()
    {
        this.handleSla(this.customMetadata);
    }
    handleSla(resultMetadata)
    {
        console.log(JSON.stringify(resultMetadata));
    getSlaDetails({ recId: this.recordId, tsw:JSON.stringify(resultMetadata) })
            .then((result) => {
                console.log(JSON.stringify(result));
                this.recordsToDisplay = result;
                this.error = undefined;
            })
            .catch((error) => {
                this.error = error;               
            });
        }
    // @wire(getSlaDetails, {recId: '$recordId'})
    // getSlaDetails(result){
    //     console.log(JSON.stringify(result));
    //     console.log('inside wire function' + result);
    //     if(result.data){
    //        console.log(JSON.stringify(result.data));
    //         this.recordsToDisplay = result.data;
           
    //         }
           
    //         else if(result.error){
    //         console.log('--- error --- ' + Json.stringify(result.error));
    //     }
    //     else{
    //           console.log('else');  
    //     }
    // }
}
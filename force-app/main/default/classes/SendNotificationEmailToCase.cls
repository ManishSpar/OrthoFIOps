public class SendNotificationEmailToCase {
     
    	@InvocableMethod
        public static void sendnotification(List<Id> caseid){ 
             system.debug('---In Process builder---');
            Case mycase =  [Select Id, Contact.Name, Subject, Status, description, contactemail from Case where Id =: caseid[0]]; 
            OrgWideEmailAddress owa = [select id, Address, DisplayName from OrgWideEmailAddress]; 
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            String[] to = new string[] {mycase.contactemail };
            String[] bcc = new String[] {owa.Address};
            List<EmailMessage> msgList=[Select Id,ThreadIdentifier,Subject,ParentId,Parent.CaseNumber,MessageIdentifier from EmailMessage where parentId=:caseid[0] order by createddate asc];
         
            system.debug(msgList.size());
            if(msgList.size()>0){     
                system.debug('to'+to);
                system.debug('bcc'+bcc);
                system.debug('id'+caseid[0]);
                system.debug('pppp'+mycase.contactemail);
                email.setToAddresses(to);
                email.setBccAddresses(bcc);
              //  email.setSubject(+msgList[0].subject+' - '+msgList[0].Parent.CaseNumber);
                email.setSubject('[OrthoFi has created a case for you!] - Case Number # '+msgList[0].Parent.CaseNumber);
                email.setOrgWideEmailAddressId(owa.Id); //From address
               String body = 'Dear '+mycase.Contact.Name+'!,';
                body += '<p>Thank you for contacting us.';
                body += ' A case has been created '+ msgList[0].Parent.CaseNumber+' and is being currently being worked on by the OrthoFi team.';
                body += ' We will contact you if we have any questions.</p>';
				body += '<p>Customer Name: '+mycase.Contact.Name+'</p>';
                body += '<p>Status: '+mycase.Status+'</p>';
                body += '<p>Subject: '+mycase.Subject+'</p>';
                body += '<p>Case Details: '+mycase.description+'</p>';
                body += '<p>Thank you,</p>';
                body += '<p>OrthoFi Support</p>';
                body += '<p><u>support@orthofi.com</u></p>';
                body += '<p>877-766-5220</p>';
                email.setHtmlBody(body);
                email.setReferences(msgList[0].ThreadIdentifier);
                email.setInReplyTo(msgList[0].MessageIdentifier);
                email.whatid=mycase.Id;
                try{
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                }catch(exception e){
                    system.debug(e);
                }
            }
            
        }
}
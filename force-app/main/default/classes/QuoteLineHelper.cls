public with sharing class QuoteLineHelper 
{
 
    //Called from Quote Line Trigger before insert to copy relevant data to Quote Line
    public static void copyFieldValues( List<QuoteLineItem> qlis )
    {
        Set<Id> quoteIds = new Set<Id>();
        for(QuoteLineItem qli:qlis)
        {
            quoteIds.add(qli.QuoteId);
        }
        
        Map<ID, Quote> quoteMap = new Map<ID, Quote>([SELECT Id, Discount_List__c FROM Quote WHERE Id IN :quoteIds ]);
        for(QuoteLineItem qli:qlis)
        {
            Quote q = quoteMap.get(qli.QuoteId);
            if(q==null)
                continue;
            qli.DiscountList__c=q.Discount_List__c;
        }
    }


    //Called from Quote Line Trigger before update & insert
    //Set Discounts on Quote Lines as defined in the Discount Lists 
    public static void setVolumeDiscount(List<QuoteLineItem> qlisOld, List<QuoteLineItem> qlisNew, 
                                  Map<Id,SObject> qliMapOld, Map<Id,SObject> qliMapNew, 
                                  Boolean isInsert, Boolean isUpdate, Boolean isDelete)
    {
        if(isDelete)
            return;

        //Gather discount lists and products so we can query for discount list items for our quote lines
        Set<Id> discountListIds  = new Set<Id>();
        Set<Id> productIds  = new Set<Id>();
        for(QuoteLineItem qli : qlisNew)
        {
            discountListIds.add(qli.DiscountList__c);
            productIds.add(qli.Product2Id);
        }

        List<DiscountListItem__c> dlis = [SELECT Id, Type__c, DiscountAmount__c, TierStartQty__C, TierEndQty__c, Name,FixedPrice__c,
                                                 Product__c, DiscountList__c, DiscountList__r.Name FROM DiscountListItem__c WHERE
                                                 DiscountList__c IN :discountListIds AND Product__c IN :productIds];

        //Loop through each quote line and apply discount if matches product & discount list
        for(QuoteLineItem qli : qlisNew)
        {
            QuoteLineItem qliOld = null;
            if(isUpdate)
                qliOld = (QuoteLineItem) qliMapOld.get(qli.Id);

            if(qli.DiscountListAmount__c>0 && qli.UnitPrice != qli.ListPriceWorkaround__c)
            {
                qli.UnitPrice = qli.ListPriceWorkaround__c;
            }

            if(qli.DiscountListAmount__c != 0)
            {
                qli.DiscountListAmount__c = 0; //reset
            }

            for(DiscountListItem__c dli : dlis)
            {
                if(dli.Product__c != qli.Product2Id || dli.DiscountList__c != qli.DiscountList__c)
                    continue;
                
                if( isInsert || 
                   (isUpdate && (qliOld.Quantity != qli.Quantity || qliOld.UnitPrice != qli.UnitPrice || qliOld.DiscountList__c != qli.DiscountList__c )))
                {        
                    if(dli.Type__c=='Tier' && qli.Quantity>=dli.TierStartQty__C && (qli.Quantity<dli.TierEndQty__c || dli.TierEndQty__c==null))
                    {
                        qli.DiscountListAmount__c = dli.DiscountAmount__c;
                        qli.UnitPrice = qli.ListPriceWorkaround__c - dli.DiscountAmount__c; 
                    }
                    else if(dli.Type__c=='FixedPrice')
                    {
                        qli.UnitPrice = dli.FixedPrice__c ; 
                        qli.DiscountListAmount__c = qli.ListPriceWorkaround__c - dli.FixedPrice__c;
                    }
                    else if(dli.Type__c=='Standard')
                    {
                        qli.UnitPrice = qli.ListPriceWorkaround__c - dli.DiscountAmount__c; 
                        qli.DiscountListAmount__c = dli.DiscountAmount__c;
                    }
                }
            }
        }
    }



    //Called by Quote Line trigger (after) to update information on the Quote if necessary
    public static void setQuoteFlags(List<QuoteLineItem> qlisOld, List<QuoteLineItem> qlisNew, 
                                    Map<Id,SObject> qliMapOld, Map<Id,SObject> qliMapNew, 
                                    Boolean isInsert, Boolean isUpdate, Boolean isDelete)
    {
        if(isUpdate)
            return;

        List<QuoteLineItem> qlis = isDelete ? qlisOld :qlisNew;

        Set<Id> quoteIds = new Set<Id>();
        for(QuoteLineItem qli : qlis)
        {
            if(qli.HasFees__c != '')
            {
                quoteIds.add(qli.QuoteId);
            }
        }
        
        //Determine if quote has any lines with breeze/mgdact fees
        List<QuoteLineItem> allQlis = [SELECT Id, HasFees__c, QuoteId FROM QuoteLineItem WHERE QuoteId IN :quoteIds AND 
                                        (HasFees__c!='')];

        Map<Id,boolean> hasBreeze = new Map<Id,boolean>();
        Map<Id,boolean> hasMgdAct = new Map<Id,boolean>();
        Map<Id,boolean> hasRhino = new Map<Id,boolean>();
        for(QuoteLineItem qli : allQlis)
        {
            if(qli.HasFees__c=='Breeze')
                hasBreeze.put(qli.QuoteId,true);
            else if(qli.HasFees__c=='MgdAct')
                hasMgdAct.put(qli.QuoteId,true);
            else if(qli.HasFees__c=='Rhinopay')
                hasRhino.put(qli.QuoteId,true);
        }
       
        List<Quote> quotesToUpdate = new List<Quote>();
        for(Id qid : quoteIds)
        {
            quotesToUpdate.add(  new Quote( Id=qid, 
                    HasBreezeFees__c = hasBreeze.containsKey(qid), 
                    HasMgdActFees__c = hasMgdAct.containsKey(qid),
                    HasRhinoFees__c =  hasRhino.containsKey(qid)));
        }

        if(quotesToUpdate.size()>0)
            update quotesToUpdate; //Will trigger recalc of Fees
        
    }

}
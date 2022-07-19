public with sharing class QuoteHelper 
{
 
    //Called from Quote trigger (before update) to set the appropriate Quote Fees based on Products in current Price Book 
    public static void setFees( Map<Id,Quote> qMapOld, Map<Id,Quote> qMapNew )
    {

        List<PriceBookEntry> pbes = null;
        for(Quote q : qMapNew.values())
        {
            Quote qOld = qMapOld.get(q.id);

            if(q.HasBreezeFees__c == qOld.HasBreezeFees__c &&
               q.HasMgdActFees__c == qOld.HasMgdActFees__c &&
               q.HasRhinoFees__c == qOld.HasRhinoFees__c)
               continue;

            boolean bChangedBreeze = (q.HasBreezeFees__c != qOld.HasBreezeFees__c ||  q.HasRhinoFees__c != qOld.HasRhinoFees__c);
            boolean bChangedMgdAct = (q.HasMgdActFees__c != qOld.HasMgdActFees__c);

            if(bChangedBreeze)
            {
                q.Merchant_Transaction_Fee__c=null;
                q.ACH_Transaction_Fee__c=null;

                q.CC_Breeze_AmexRate__c = null;
                q.CC_Breeze_DiscoverRate__c = null;
                q.CC_Breeze_MC_VisaRate__c = null;
            }

            if(bChangedMgdAct)
            {
                q.Transaction_Fee__c=null;
                q.Pay_As_You_Go_Fee__c=null;
                q.MgdAct_Merchant_Transaction_Fee__c=null;
                q.MgdAct_ACH_Transaction_Fee__c=null;

                q.CC_AmexRate__c = null;
                q.CC_DiscoverRate__c = null;
                q.CC_MC_VisaRate__c = null;
            }
           
       
            if(q.HasBreezeFees__c||q.HasMgdActFees__c||q.HasRhinoFees__c)
            {
                if(pbes==null)
                {
                    Set<Id> pbs = new Set<Id>();
                    for(Quote pbq : qMapNew.values())
                    {
                        pbs.add(pbq.PriceBook2Id);
                    }

                    //Gather all of the fees (product wih a transaction fee type)
                    pbes = [SELECT Id,Name,UnitPrice,Pricebook2Id,TransactionFeeType__c FROM PriceBookEntry 
                            WHERE PriceBook2Id IN :pbs AND TransactionFeeType__c != ''];
                }
            
                //Set the quote field based on fee type
                for(PriceBookEntry pbe : pbes)
                {    
                    //Just in case we have multiple quotes/PBs involved
                    if(pbe.Pricebook2Id != q.Pricebook2Id)
                        continue;
                    
                    if(bChangedBreeze)
                    {
                        if((q.HasBreezeFees__c||q.HasRhinoFees__c) && pbe.TransactionFeeType__c ==  'Breeze-MerchantTransactionFee' )
                            q.Merchant_Transaction_Fee__c=pbe.UnitPrice;
                        
                        if((q.HasBreezeFees__c||q.HasRhinoFees__c) && pbe.TransactionFeeType__c ==  'Breeze-ACHTransactionFee' )
                            q.ACH_Transaction_Fee__c=pbe.UnitPrice;
                    }
                      
                    if(bChangedMgdAct)
                    {
                        if(q.HasMgdActFees__c && pbe.TransactionFeeType__c ==  'MgdAct-TransactionFee' )
                            q.Transaction_Fee__c=pbe.UnitPrice;
                    
                        if(q.HasMgdActFees__c && pbe.TransactionFeeType__c ==  'MgdAct-PayAsYouGoFee' )
                            q.Pay_As_You_Go_Fee__c=pbe.UnitPrice;


                        if(q.HasMgdActFees__c && pbe.TransactionFeeType__c ==  'MgdAct-MerchantTransactionFee' )
                            q.MgdAct_Merchant_Transaction_Fee__c=pbe.UnitPrice;
                    
                        if(q.HasMgdActFees__c && pbe.TransactionFeeType__c ==  'MgdAct-ACHTransactionFee' )
                            q.MgdAct_ACH_Transaction_Fee__c=pbe.UnitPrice;
                    }
                }
                QuoteHelper.setCCFees(q, bChangedBreeze, bChangedMgdAct);
            }
        }
    }



    //Find & set Credit Card fees for the quote using custom metadata
    public static void setCCFees(Quote q, boolean bChangedBreeze, boolean bChangedMgdAct)
    {
       
        List<CCFeeRate__mdt> fees = [SELECT Id, Product__c, Amex_Rate__c, Discover_Rate__c, MC_Visa_Rate__c FROM CCFeeRate__mdt];
        for(CCFeeRate__mdt fee : fees)
        {
            if(bChangedMgdAct)
            {
                if(q.HasMgdActFees__c && fee.Product__c=='MgdAct')
                {
                    q.CC_AmexRate__c        = fee.Amex_Rate__c;
                    q.CC_DiscoverRate__c    = fee.Discover_Rate__c;
                    q.CC_MC_VisaRate__c     = fee.MC_Visa_Rate__c;
                }
            }

            if(bChangedBreeze)
            {
                if(q.HasBreezeFees__c && fee.Product__c=='Breeze')
                {
                    q.CC_Breeze_AmexRate__c     = fee.Amex_Rate__c;
                    q.CC_Breeze_DiscoverRate__c = fee.Discover_Rate__c;
                    q.CC_Breeze_MC_VisaRate__c  = fee.MC_Visa_Rate__c;
                }
                else if(q.HasRhinoFees__c && fee.Product__c=='Rhinopay')
                {
                    q.CC_Breeze_AmexRate__c     = fee.Amex_Rate__c;
                    q.CC_Breeze_DiscoverRate__c = fee.Discover_Rate__c;
                    q.CC_Breeze_MC_VisaRate__c  = fee.MC_Visa_Rate__c;
                }
            }

            //NOTE: Breeze/Rhino may interfere if on same quote
        }
    }



    //Called from Quote trigger (after update) to cover the scenario where Discount List is changed and
    //discounts must all potentially be adjusted
    public static void setVolumeDiscount( Map<Id,Quote> qMapOld, Map<Id,Quote> qMapNew )
    {
        //Gather the list of Quotes where the DL changed
        Map<Id,Id> dlChanged = new Map<Id,Id>();
        for(Quote qNew : qMapNew.values() )
        {
            Quote qOld = qMapOld.get(qNew.id);
            if(qOld.Discount_List__c != qNew.Discount_List__c)
            {
                dlChanged.put(qNew.Id, qNew.Discount_List__c);
            }
        }

        if(dlChanged.size()>0)
        {
            //Update the DiscountList on all quote lines
            List<QuoteLineItem> qlis = new List<QuoteLineItem>([SELECT Id, QuoteId, DiscountList__c FROM QuoteLineItem WHERE QuoteId IN :dlChanged.keySet()]);
            for(QuoteLineItem qli : qlis)
            {
                qli.DiscountList__c=dlChanged.get(qli.QuoteId);
            }
            update qlis;//Will trigger recalc of volume discounts
        }
    }



}
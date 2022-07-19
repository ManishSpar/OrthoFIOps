@isTest
private class QuoteHelperTest 
{
    
    static TestMethod void validateSetVolumeDiscount()
    {
        Opportunity o = new Opportunity(Name='TestOppo',StageName='Prospecting', CloseDate=  Date.parse('1/1/2022'), PriceBook2Id=Test.getStandardPricebookId());
        insert o;

        Product2 p = new Product2(Name='TestProduct');
        insert p;

        DiscountList__c dl = new DiscountList__c(Name='TestDL');
        insert dl;

        DiscountListItem__c dli1 = new DiscountListItem__c(DiscountList__c=dl.id,Product__c=p.id, Type__c='Tier',TierStartQty__C=50, TierEndQty__c=100, DiscountAmount__c=0.25);
        insert dli1;

        DiscountListItem__c dli2 = new DiscountListItem__c(DiscountList__c=dl.id,Product__c=p.id, Type__c='Tier',TierStartQty__C=100, DiscountAmount__c=0.5);
        insert dli2;
        
        Quote q = new Quote(Name='TestQuote', OpportunityId=o.id, Status='Draft');
        insert q;

        PriceBookEntry pbe = new PriceBookEntry(Product2Id=p.Id, PriceBook2Id=Test.getStandardPricebookId(),UnitPrice=2.00,IsActive=True);
        insert pbe;

        //First Tier, but no discount list
        QuoteLineItem qli = new QuoteLineItem(QuoteId=q.Id, Product2Id=p.Id, PricebookEntryId=pbe.id, Quantity=50, UnitPrice=2.00);
        insert qli;
        qli=[SELECT Id,UnitPrice,DiscountListAmount__c FROM QuoteLineItem WHERE Id = :qli.Id];
        System.assertEquals(2.00,qli.UnitPrice);
        System.assertEquals(0.00,qli.DiscountListAmount__c);

        //First Tier w/ discount list
        q.Discount_List__c=dl.id;
        update q;  
        qli=[SELECT Id,UnitPrice,DiscountListAmount__c FROM QuoteLineItem WHERE Id = :qli.Id];
        System.assertEquals(1.75,qli.UnitPrice);
        System.assertEquals(0.25,qli.DiscountListAmount__c);

        //No Discount, Qty too low
        qli.Quantity=1;
        update qli;
        qli=[SELECT Id,UnitPrice,DiscountListAmount__c FROM QuoteLineItem WHERE Id = :qli.Id];
        System.assertEquals(2.00,qli.UnitPrice);
        System.assertEquals(0.00,qli.DiscountListAmount__c);

        //Second tier
        qli.Quantity=999;
        update qli;
        qli=[SELECT Id,UnitPrice,DiscountListAmount__c FROM QuoteLineItem WHERE Id = :qli.Id];
        System.assertEquals(1.50,qli.UnitPrice);
        System.assertEquals(0.50,qli.DiscountListAmount__c);

        

        //Standard discount
        DiscountListItem__c dli3 = new DiscountListItem__c(DiscountList__c=dl.id,Product__c=p.id, Type__c='Standard', DiscountAmount__c=0.30);
        insert dli3;
        delete dli1;
        delete dli2;
                
        qli.Quantity=5;
        update qli;
        qli=[SELECT Id,UnitPrice,DiscountListAmount__c FROM QuoteLineItem WHERE Id = :qli.Id];
        System.assertEquals(1.70,qli.UnitPrice);
        System.assertEquals(0.30,qli.DiscountListAmount__c);


        //Fixed Price
        DiscountListItem__c dli4 = new DiscountListItem__c(DiscountList__c=dl.id,Product__c=p.id, Type__c='FixedPrice', FixedPrice__c=1.25);
        insert dli4;
        delete dli3;

        qli.Quantity=6;
        update qli;
        qli=[SELECT Id,UnitPrice,DiscountListAmount__c FROM QuoteLineItem WHERE Id = :qli.Id];
        System.assertEquals(1.25,qli.UnitPrice);
        System.assertEquals(0.75,qli.DiscountListAmount__c);


    }



    static TestMethod void validateSetFees()
    {
        Opportunity o = new Opportunity(Name='TestOppo',StageName='Prospecting', CloseDate=  Date.parse('1/1/2022'), PriceBook2Id=Test.getStandardPricebookId());
        insert o;

        Quote q = new Quote(Name='TestQuote', OpportunityId=o.id, Status='Draft');
        insert q;

        //Insert products that require fees...
        Product2 p1 = new Product2(Name='TestProductMgdAct', HasFees__c = 'MgdAct');
        insert p1;

        Product2 p2 = new Product2(Name='TestProductBreeze', HasFees__c = 'Breeze');
        insert p2;

        PriceBookEntry pbe1 = new PriceBookEntry(Product2Id=p1.Id, PriceBook2Id=Test.getStandardPricebookId(),UnitPrice=1.00,IsActive=True);
        insert pbe1;

        PriceBookEntry pbe2 = new PriceBookEntry(Product2Id=p2.Id, PriceBook2Id=Test.getStandardPricebookId(),UnitPrice=2.00,IsActive=True);
        insert pbe2;

        
        //Insert products that represent the fees...
        Product2 p3 = new Product2(Name='TestFee', TransactionFeeType__c='Breeze-MerchantTransactionFee');
        insert p3;
        Product2 p4 = new Product2(Name='TestFee', TransactionFeeType__c='Breeze-ACHTransactionFee');
        insert p4;
        Product2 p5 = new Product2(Name='TestFee', TransactionFeeType__c='MgdAct-TransactionFee');
        insert p5;
        Product2 p6 = new Product2(Name='TestFee',TransactionFeeType__c='MgdAct-PayAsYouGoFee');
        insert p6;
        Product2 p7 = new Product2(Name='TestFee', TransactionFeeType__c='MgdAct-MerchantTransactionFee');
        insert p7;
        Product2 p8 = new Product2(Name='TestFee',TransactionFeeType__c='MgdAct-ACHTransactionFee');
        insert p8;

        PriceBookEntry pbe3 = new PriceBookEntry(Product2Id=p3.Id, PriceBook2Id=Test.getStandardPricebookId(),UnitPrice=3.00,IsActive=True);
        insert pbe3;
        PriceBookEntry pbe4 = new PriceBookEntry(Product2Id=p4.Id, PriceBook2Id=Test.getStandardPricebookId(),UnitPrice=4.00,IsActive=True);
        insert pbe4;
        PriceBookEntry pbe5 = new PriceBookEntry(Product2Id=p5.Id, PriceBook2Id=Test.getStandardPricebookId(),UnitPrice=5.00,IsActive=True);
        insert pbe5;
        PriceBookEntry pbe6 = new PriceBookEntry(Product2Id=p6.Id, PriceBook2Id=Test.getStandardPricebookId(),UnitPrice=6.00,IsActive=True);
        insert pbe6;
        PriceBookEntry pbe7 = new PriceBookEntry(Product2Id=p7.Id, PriceBook2Id=Test.getStandardPricebookId(),UnitPrice=7.00,IsActive=True);
        insert pbe7;
        PriceBookEntry pbe8 = new PriceBookEntry(Product2Id=p8.Id, PriceBook2Id=Test.getStandardPricebookId(),UnitPrice=8.00,IsActive=True);
        insert pbe8;

        //Get custom metadata values
        Map<String, CCFeeRate__mdt> mapCC = new Map<String,CCFeeRate__mdt>();
        List<CCFeeRate__mdt> fees = [SELECT Id, Product__c, Amex_Rate__c, Discover_Rate__c, MC_Visa_Rate__c FROM CCFeeRate__mdt];
        System.assertEquals(3,fees.size());

        for(CCFeeRate__mdt f : fees)
        {
            mapCC.put(f.Product__c,f);
        }

        //MgdAct Fees
        QuoteLineItem qli = new QuoteLineItem(QuoteId=q.Id, Product2Id=p1.Id, PricebookEntryId=pbe1.id, Quantity=1, UnitPrice=1.25, Description='test');
        insert qli; 

 
        q = [SELECT Merchant_Transaction_Fee__c,ACH_Transaction_Fee__c,Transaction_Fee__c,Pay_As_You_Go_Fee__c,CC_AmexRate__c,CC_DiscoverRate__c,CC_MC_VisaRate__c,
        CC_Breeze_AmexRate__c,CC_Breeze_DiscoverRate__c,CC_Breeze_MC_VisaRate__c,MgdAct_Merchant_Transaction_Fee__c,MgdAct_ACH_Transaction_Fee__c FROM Quote WHERE ID = :q.id];
        System.assertEquals(null,q.Merchant_Transaction_Fee__c);
        System.assertEquals(null,q.ACH_Transaction_Fee__c);
        System.assertEquals(5.00,q.Transaction_Fee__c);
        System.assertEquals(6.00,q.Pay_As_You_Go_Fee__c);
        System.assertEquals(7.00,q.MgdAct_Merchant_Transaction_Fee__c);
        System.assertEquals(8.00,q.MgdAct_ACH_Transaction_Fee__c);
        System.assertEquals(mapCC.get('MgdAct').Amex_Rate__c,q.CC_AmexRate__c); 
        System.assertEquals(mapCC.get('MgdAct').Discover_Rate__c,q.CC_DiscoverRate__c);
        System.assertEquals(mapCC.get('MgdAct').MC_Visa_Rate__c,q.CC_MC_VisaRate__c);

        //Test removal
        delete qli;

        q = [SELECT Merchant_Transaction_Fee__c,ACH_Transaction_Fee__c,Transaction_Fee__c,Pay_As_You_Go_Fee__c,CC_AmexRate__c,CC_DiscoverRate__c,CC_MC_VisaRate__c,
        CC_Breeze_AmexRate__c,CC_Breeze_DiscoverRate__c,CC_Breeze_MC_VisaRate__c,MgdAct_Merchant_Transaction_Fee__c,MgdAct_ACH_Transaction_Fee__c FROM Quote WHERE ID = :q.id];
        System.assertEquals(null,q.Merchant_Transaction_Fee__c);
        System.assertEquals(null,q.ACH_Transaction_Fee__c);
        System.assertEquals(null,q.Transaction_Fee__c);
        System.assertEquals(null,q.Pay_As_You_Go_Fee__c);
        System.assertEquals(null,q.CC_AmexRate__c);
        System.assertEquals(null,q.CC_DiscoverRate__c);
        System.assertEquals(null,q.CC_MC_VisaRate__c);
        System.assertEquals(null,q.MgdAct_Merchant_Transaction_Fee__c);
        System.assertEquals(null,q.MgdAct_ACH_Transaction_Fee__c);

        //Breeze Fees
        qli = new QuoteLineItem(QuoteId=q.Id, Product2Id=p2.Id, PricebookEntryId=pbe2.id, Quantity=1, UnitPrice=1.25, Description='test');
        insert qli; 
        q = [SELECT Merchant_Transaction_Fee__c,ACH_Transaction_Fee__c,Transaction_Fee__c,Pay_As_You_Go_Fee__c,CC_AmexRate__c,CC_DiscoverRate__c,CC_MC_VisaRate__c,
        CC_Breeze_AmexRate__c,CC_Breeze_DiscoverRate__c,CC_Breeze_MC_VisaRate__c,MgdAct_Merchant_Transaction_Fee__c,MgdAct_ACH_Transaction_Fee__c FROM Quote WHERE ID = :q.id];
        System.assertEquals(3.00,q.Merchant_Transaction_Fee__c);
        System.assertEquals(4.00,q.ACH_Transaction_Fee__c);
        System.assertEquals(null,q.Transaction_Fee__c);
        System.assertEquals(null,q.Pay_As_You_Go_Fee__c);
        System.assertEquals(null,q.MgdAct_Merchant_Transaction_Fee__c);
        System.assertEquals(null,q.MgdAct_ACH_Transaction_Fee__c);
        System.assertEquals(mapCC.get('Breeze').Amex_Rate__c,q.CC_Breeze_AmexRate__c); 
        System.assertEquals(mapCC.get('Breeze').Discover_Rate__c,q.CC_Breeze_DiscoverRate__c);
        System.assertEquals(mapCC.get('Breeze').MC_Visa_Rate__c,q.CC_Breeze_MC_VisaRate__c);
        System.assertEquals(null,q.CC_AmexRate__c); 
        System.assertEquals(null,q.CC_DiscoverRate__c);
        System.assertEquals(null,q.CC_MC_VisaRate__c);

        //Rhinopay fees
        delete qli;
        
        Product2 p9 = new Product2(Name='TestProductRhino', HasFees__c = 'Rhinopay');
        insert p9;

        PriceBookEntry pbe9 = new PriceBookEntry(Product2Id=p9.Id, PriceBook2Id=Test.getStandardPricebookId(),UnitPrice=9.00,IsActive=True);
        insert pbe9;

        qli = new QuoteLineItem(QuoteId=q.Id, Product2Id=p9.Id, PricebookEntryId=pbe9.id, Quantity=1, UnitPrice=1.33, Description='test');
        insert qli; 

        q = [SELECT Merchant_Transaction_Fee__c,ACH_Transaction_Fee__c,Transaction_Fee__c,Pay_As_You_Go_Fee__c,CC_AmexRate__c,CC_DiscoverRate__c,CC_MC_VisaRate__c,
        CC_Breeze_AmexRate__c,CC_Breeze_DiscoverRate__c,CC_Breeze_MC_VisaRate__c,MgdAct_Merchant_Transaction_Fee__c,MgdAct_ACH_Transaction_Fee__c FROM Quote WHERE ID = :q.id];
        System.assertEquals(3.00,q.Merchant_Transaction_Fee__c);
        System.assertEquals(4.00,q.ACH_Transaction_Fee__c);
        System.assertEquals(null,q.Transaction_Fee__c);
        System.assertEquals(null,q.Pay_As_You_Go_Fee__c);
        System.assertEquals(null,q.MgdAct_Merchant_Transaction_Fee__c);
        System.assertEquals(null,q.MgdAct_ACH_Transaction_Fee__c);
        System.assertEquals(mapCC.get('Rhinopay').Amex_Rate__c,q.CC_Breeze_AmexRate__c); 
        System.assertEquals(mapCC.get('Rhinopay').Discover_Rate__c,q.CC_Breeze_DiscoverRate__c);
        System.assertEquals(mapCC.get('Rhinopay').MC_Visa_Rate__c,q.CC_Breeze_MC_VisaRate__c);
        System.assertEquals(null,q.CC_AmexRate__c); 
        System.assertEquals(null,q.CC_DiscoverRate__c);
        System.assertEquals(null,q.CC_MC_VisaRate__c);
    }



}
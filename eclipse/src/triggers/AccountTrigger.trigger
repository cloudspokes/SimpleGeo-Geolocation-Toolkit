trigger AccountTrigger on Account (after insert, after update) {
    GeocodeService.geocode(
        Trigger.new
        ,'BillingAddress__c'
        ,'Latitude__c'
        ,'Longitude__c'
        ,true //true means run @future
    );
}
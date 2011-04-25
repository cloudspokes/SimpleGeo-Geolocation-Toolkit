/* ============================================================
 * This code is part of Richard Vanhook's submission to the 
 * Cloudspokes Geolocation Toolkit challenge.
 *
 * This software is provided "AS IS," and you, its user, 
 * assume all risks when using it. 
 * ============================================================
 */
@IsTest
private class GeocodeServiceTest {

    private static testmethod void test_geocode_synchronous(){
        final GeoPoint expected = new GeoPoint(23.456789d, 12.345678d);
        al.HttpUtils.pushTest(buildBasicResponseWithCoordinates(''+expected.latitude,''+expected.longitude));

        Account acct1 = new Account(name = 'test 1',BillingCity = 'New York');
        GeocodeService.futureFlag = true;
        insert acct1;
        GeocodeService.futureFlag = false;
        acct1 = Database.query('select BillingAddress__c,Latitude__c,Longitude__c from account where id = \'' + acct1.id + '\'');
        
        System.assertEquals(null,acct1.get('Latitude__c'));
        System.assertEquals(null,acct1.get('Longitude__c'));

        GeocodeService.geocode(
             new List<SObject>{acct1}
            ,'BillingAddress__c'
            ,'Latitude__c'
            ,'Longitude__c'
            ,false
        );
        
        System.assertNotEquals(null,acct1.get('Latitude__c'));
        System.assertNotEquals(null,acct1.get('Longitude__c'));
    }

    private static testmethod void test_geocode_single_error(){
        final HttpResponse testResponse = new HttpResponse();
        testResponse.setBody('{"code":404,"message":"Address not found"}');
        testResponse.setStatusCode(404);
        al.HttpUtils.pushTest(testResponse);

        Account acct1 = new Account(name = 'test 1',BillingCity = 'New York');
        GeocodeService.futureFlag = true;
        insert acct1;
        GeocodeService.futureFlag = false;
        acct1 = Database.query('select BillingAddress__c,Latitude__c,Longitude__c from account where id = \'' + acct1.id + '\'');
        
        Boolean exceptionCaught = false;
        try{
	        GeocodeService.geocode(
	             new List<SObject>{acct1}
	            ,'BillingAddress__c'
	            ,'Latitude__c'
	            ,'Longitude__c'
	            ,false
	        );
        }catch(Exception e){
            exceptionCaught = true;
        }
        System.assert(exceptionCaught == true,'Exception not thrown');
    }
    
    private static testmethod void test_geocode_multiple_error(){
        final HttpResponse testResponse = new HttpResponse();
        testResponse.setBody('{"code":404,"message":"Address not found"}');
        testResponse.setStatusCode(404);
        al.HttpUtils.pushTest(testResponse);
        al.HttpUtils.pushTest(testResponse);

        Account acct1 = new Account(name = 'test 1',BillingCity = 'New York');
        GeocodeService.futureFlag = true;
        insert acct1;
        acct1 = Database.query('select BillingAddress__c,Latitude__c,Longitude__c from account where id = \'' + acct1.id + '\'');
        Account acct2 = new Account(name = 'test 2',BillingCity = 'New York');
        insert acct2;
        GeocodeService.futureFlag = false;
        acct2 = Database.query('select BillingAddress__c,Latitude__c,Longitude__c from account where id = \'' + acct1.id + '\'');
        
        Boolean exceptionCaught = false;
        try{
            GeocodeService.geocode(
                 new List<SObject>{acct1,acct2}
                ,'BillingAddress__c'
                ,'Latitude__c'
                ,'Longitude__c'
                ,false
            );
        }catch(Exception e){
            exceptionCaught = true;
        }
        System.assert(exceptionCaught == true,'Exception not thrown');
    }
    
    private static testmethod void test_geocode_asynchronous(){
        final GeoPoint expected = new GeoPoint(23.456789d, 12.345678d);
        al.HttpUtils.pushTest(buildBasicResponseWithCoordinates(''+expected.latitude,''+expected.longitude));

        Account acct1 = new Account(name = 'test 1',BillingCity = 'New York');
        GeocodeService.futureFlag = true;
        insert acct1;
        GeocodeService.futureFlag = false;
        acct1 = Database.query('select BillingAddress__c,Latitude__c,Longitude__c from account where id = \'' + acct1.id + '\'');
        
        System.assertEquals(null,acct1.get('Latitude__c'));
        System.assertEquals(null,acct1.get('Longitude__c'));

        Test.startTest();
        GeocodeService.geocode(
             new List<SObject>{acct1}
            ,'BillingAddress__c'
            ,'Latitude__c'
            ,'Longitude__c'
            ,true
        );
        Test.stopTest();
        
        acct1 = Database.query('select Latitude__c,Longitude__c from account where id = \'' + acct1.id + '\'');

        System.assertNotEquals(null,acct1.get('Latitude__c'));
        System.assertNotEquals(null,acct1.get('Longitude__c'));
    }

    private static testmethod void testLookup_WithOneResults(){
        final Account acct1 = new Account(name = 'test 1');
        acct1.put('latitude__c',40.9d);
        acct1.put('longitude__c',-90.9d);
        final Account acct2 = new Account(name = 'test 2');
        acct2.put('latitude__c',41.1d);
        acct2.put('longitude__c',-91.1d);
        GeocodeService.futureFlag = true;
        insert new List<Account>{acct1, acct2};

        final List<GeocodeService.SearchResult> results = GeocodeService.findNearbyRecords(
             new GeoPoint(41.0d, -91.0d)
            ,20
            ,null
            ,'latitude__c'
            ,'longitude__c'
            ,'Account'
            ,null
        );
        System.assertNotEquals(null,results);
        System.assert(results.size() >= 2);
    }

    private static testmethod void test_geocode_batch(){
        final GeoPoint expected = new GeoPoint(23.456789d, 12.345678d);
        al.HttpUtils.pushTest(buildBasicResponseWithCoordinates(''+expected.latitude,''+expected.longitude));

        Account acct1 = new Account(name = 'test 1',BillingCity = 'New York');
        GeocodeService.futureFlag = true;
        insert acct1;
        GeocodeService.futureFlag = false;
        acct1 = Database.query('select id,BillingAddress__c,Latitude__c,Longitude__c from account where id = \'' + acct1.id + '\'');
        
        System.assertEquals(null,acct1.get('Latitude__c'));
        System.assertEquals(null,acct1.get('Longitude__c'));

        Test.startTest();
        GeocodeService.geocodeEnMasse(
             'BillingAddress__c'
            ,'Latitude__c'
            ,'Longitude__c'
            ,'Account'
            ,new al.FieldCondition('id').equals(acct1.id)
            ,'test@test.com'
        );
        Test.stopTest();
        
        acct1 = Database.query('select Latitude__c,Longitude__c from account where id = \'' + acct1.id + '\'');

        System.assertNotEquals(null,acct1.get('Latitude__c'));
        System.assertNotEquals(null,acct1.get('Longitude__c'));
    }

    private static String buildBasicResponseWithCoordinates(String lat, String lng){
        return   '{"query":{"latitude":' 
         + lat 
         + ',"longitude":' 
         + lng 
         + ',"address":"San Francisco"}}';
    }
    
    private static void setupGlobalVariables(){
        final Map<String,String> theVariables = new Map<String,String>{
             GlobalVariable.KEY_SIMPLE_GEO_OAUTH_KEY    => 'abc'
            ,GlobalVariable.KEY_SIMPLE_GEO_SECRET_KEY   => 'def'
        };
        for(String key : theVariables.keySet()){
            GlobalVariableTestUtils.ensureExists(new GlobalVariable__c(name=key,Value__c=theVariables.get(key)));
        }
    }

}
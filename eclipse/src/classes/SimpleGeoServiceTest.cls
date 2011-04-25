/* ============================================================
 * This code is part of Richard Vanhook's submission to the 
 * Cloudspokes Geolocation Toolkit challenge.
 *
 * This software is provided "AS IS," and you, its user, 
 * assume all risks when using it. 
 * ============================================================
 */
@IsTest
private class SimpleGeoServiceTest {

    private static testmethod void test_ILLEGAL_ARGUMENT(){
    	setupGlobalVariables();
        Boolean exceptionCaught = false;
        try{
             SimpleGeoService.lookup(null);
        }catch(SimpleGeoServiceException e){
            exceptionCaught = true;
        }
        System.assert(exceptionCaught == true,'SimpleGeoServiceException not thrown');
    }

    private static testmethod void test_PARSE_ERROR_INVALID_RESPONSE(){
        setupGlobalVariables();
        al.HttpUtils.pushTest('abc 123');
        Boolean exceptionCaught = false;
        try{
             SimpleGeoService.lookup('x'); //query param just can't be blank
        }catch(SimpleGeoServiceException e){
            exceptionCaught = true;
        }
        System.assert(exceptionCaught == true,'SimpleGeoServiceException not thrown');
    }

    private static testmethod void test_PARSE_ERROR_NO_COORDINATES(){
        setupGlobalVariables();
        al.HttpUtils.pushTest(buildBasicResponseWithCoordinates('',''));
        Boolean exceptionCaught = false;
        try{
             SimpleGeoService.lookup('x'); //query param just can't be blank
        }catch(SimpleGeoServiceException e){
            exceptionCaught = true;
        }
        System.assert(exceptionCaught == true,'SimpleGeoServiceException not thrown');
    }

    private static testmethod void test_PARSE_ERROR_INAVLID_COORDINATES(){
        al.HttpUtils.pushTest(buildBasicResponseWithCoordinates('a','b'));
        Boolean exceptionCaught = false;
        try{
             SimpleGeoService.lookup('x'); //query param just can't be blank
        }catch(SimpleGeoServiceException e){
            exceptionCaught = true;
        }
        System.assert(exceptionCaught == true,'SimpleGeoServiceException not thrown');
    }

    private static testmethod void testLookup_WithNoResults(){
        final HttpResponse testResponse = new HttpResponse();
        testResponse.setBody('{"code":404,"message":"Address not found"}');
        testResponse.setStatusCode(404);
        al.HttpUtils.pushTest(testResponse);
        Boolean exceptionCaught = false;
        try{
             SimpleGeoService.lookup('x'); //query param just can't be blank
        }catch(SimpleGeoServiceException e){
            exceptionCaught = true;
        }
        System.assert(exceptionCaught == true,'SimpleGeoServiceException not thrown');
    }

    private static testmethod void testLookup_WithOneResults(){
        final GeoPoint expected = new GeoPoint(23.456789d, 12.345678d);
        al.HttpUtils.pushTest(buildBasicResponseWithCoordinates(''+expected.latitude,''+expected.longitude));
        final GeoPoint actual = SimpleGeoService.lookup('x'); //query param just can't be blank
        System.assertNotEquals(null, actual);
        System.assert(actual.equals(expected),'expected: ' + expected.toStr() + ', actual: ' + actual.toStr());
    }

/*
    private static testmethod void test_geocode_synchronous(){
        al.HttpUtils.pushTest(TEST_XML_RESPONSE_WITH_THREE_RESULTS);
        final Account acct = new Account(name = 'Test 123');
        insert acct;
        final Contact contact = new Contact(LastName = 'Smith', AccountId = acct.id);
        insert contact;
        final Asset asset = new Asset(ContactId=contact.id, AccountId=acct.id, Name='Asset 123', Price = 1, Quantity = 1);
        
        SimpleGeoService.geocode(new List<SObject>{asset}, 'name', 'price', 'quantity');
        
        final GeoPoint expected = EXPECTED_GEOPOINT_RESULT_FOR_TEST_XML_RESPONSE_WITH_THREE_RESULTS;
        System.assertEquals(expected.latitude,asset.Price);
        System.assertEquals(expected.longitude,asset.Quantity.doubleValue());
    }
    
    private static testmethod void test_geocode_single_error(){
        al.HttpUtils.pushTest('<xyz123><abc123></xyz123>');
        final Account acct = new Account(name = 'Test 123');
        insert acct;
        final Contact contact = new Contact(LastName = 'Smith', AccountId = acct.id);
        insert contact;
        final Asset asset = new Asset(ContactId=contact.id, AccountId=acct.id, Name='Asset 123', Price = 1, Quantity = 1);
        
        Boolean exceptionCaught = false;
        try{
            SimpleGeoService.geocode(new List<SObject>{asset}, 'name', 'price', 'quantity');
        }catch(SimpleGeoServiceException e){
            exceptionCaught = true;
        }
        System.assert(exceptionCaught == true,'SimpleGeoServiceException not thrown');
    }
    
    private static testmethod void test_geocode_multiple_error(){
        al.HttpUtils.pushTest('<xyz123><abc123></xyz123>');
        final Account acct = new Account(name = 'Test 123');
        insert acct;
        final Contact contact = new Contact(LastName = 'Smith', AccountId = acct.id);
        insert contact;
        final Asset asset1 = new Asset(ContactId=contact.id, AccountId=acct.id, Name='Asset 123', Price = 1, Quantity = 1);
        final Asset asset2 = new Asset(ContactId=contact.id, AccountId=acct.id, Name='Asset 123', Price = 1, Quantity = 1);
        
        Boolean exceptionCaught = false;
        try{
            SimpleGeoService.geocode(new List<SObject>{asset1,asset2}, 'name', 'price', 'quantity');
        }catch(SimpleGeoServiceException e){
            exceptionCaught = true;
        }
        System.assert(exceptionCaught == true,'SimpleGeoServiceException not thrown');
    }
    
    private static testmethod void test_geocode_asynchronous(){
        al.HttpUtils.pushTest(TEST_XML_RESPONSE_WITH_THREE_RESULTS);
        final Account acct = new Account(name = 'Test 123');
        insert acct;
        final Contact contact = new Contact(LastName = 'Smith', AccountId = acct.id);
        insert contact;
        Asset asset = new Asset(ContactId=contact.id, AccountId=acct.id, Name='Asset 123', Price = 1, Quantity = 1);
        insert asset;
        
        Test.startTest();
        SimpleGeoService.geocode(new List<SObject>{asset}, 'name', 'price', 'quantity', true);
        Test.stopTest();
        
        asset = [select Price,Quantity from Asset where id = :asset.id];
        
        final GeoPoint expected = EXPECTED_GEOPOINT_RESULT_FOR_TEST_XML_RESPONSE_WITH_THREE_RESULTS;
        System.assertEquals(expected.latitude,asset.Price);
        System.assertEquals(expected.longitude,asset.Quantity.doubleValue());
    }
*/    
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

    private static final String TEST_RESPONSE_200 = 
           '{"query":{"latitude":37.784827,"longitude":-122.727802,"address":"San Francisco"},' 
         + '"timestamp":1302894622.602,"features":[],"weather":{"wind_speed":"6.9 meters per s' 
         + 'econd","temperature":"68F","dewpoint":"35F","cloud_cover":"10%","wind_direction":"' 
         + '248 degrees","forecast":{"tonight":{"conditions":"Mostly cloudy","precipitation":"' 
         + '0%","temperature":{"max":"55F","min":"53F"}},"tomorrow":{"conditions":"Partly clou' 
         + 'dy","precipitation":"0%","temperature":{"max":"65F","min":"54F"}},"today":{"condit' 
         + 'ions":"Mostly cloudy","precipitation":"20%","temperature":{"max":"64F","min":"48F"' 
         + '}}},"conditions":"Clear"}}';
         
}
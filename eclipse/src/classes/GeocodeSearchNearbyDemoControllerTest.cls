/* ============================================================
 * This code is part of Richard Vanhook's submission to the 
 * Cloudspokes Geolocation Toolkit challenge.
 *
 * This software is provided "AS IS," and you, its user, 
 * assume all risks when using it. 
 * ============================================================
 */
@IsTest
private class GeocodeSearchNearbyDemoControllerTest {

    private static testmethod void testLookup_WithOneResults(){
		final Account acct1 = new Account(name = 'test 1');
		acct1.put('latitude__c',40.9d);
		acct1.put('longitude__c',-90.9d);
		final Account acct2 = new Account(name = 'test 2');
		acct2.put('latitude__c',41.1d);
		acct2.put('longitude__c',-91.1d);
		GeocodeService.futureFlag = true;
    	insert new List<Account>{acct1, acct2};

        final GeocodeSearchNearbyDemoController controller = new GeocodeSearchNearbyDemoController();
		System.assertEquals(null,controller.addressInput);
		System.assertEquals(100,controller.distance);
		System.assertEquals('km',controller.unit);
		System.assertEquals('Latitude__c',controller.latitudeFieldName);
		System.assertEquals('Longitude__c',controller.longitudeFieldName);
		System.assertEquals('Account',controller.objectName);
		System.assertEquals(null,controller.results);
		System.assertNotEquals(null,controller.paginator);
		System.assertEquals(false,controller.searchExecuted);
        
        final GeoPoint expected = new GeoPoint(41.0d, -91.0d);
        al.HttpUtils.pushTest(buildBasicResponseWithCoordinates(''+expected.latitude,''+expected.longitude));
        controller.addressInput = 'doesn\'t really matter what goes in here during unit test, just not blank';
        controller.distance = 20;

        System.assertEquals(null,controller.doSearchNearby());

        System.assertNotEquals(null,controller.results);
        System.assert(controller.results.size() >= 2);
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
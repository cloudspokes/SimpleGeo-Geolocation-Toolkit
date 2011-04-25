/* ============================================================
 * This code is part of Richard Vanhook's submission to the 
 * Cloudspokes Geolocation Toolkit challenge.
 *
 * This software is provided "AS IS," and you, its user, 
 * assume all risks when using it. 
 * ============================================================
 */
@IsTest
private class GlobalVariableTest {

    private static testmethod void testGlobalVariablesExist(){
        final Map<String,String> theVariables = new Map<String,String>{
             GlobalVariable.KEY_SIMPLE_GEO_OAUTH_KEY    => 'abc'
            ,GlobalVariable.KEY_SIMPLE_GEO_SECRET_KEY   => 'def'
        };
        for(String key : theVariables.keySet()){
            GlobalVariableTestUtils.ensureExists(new GlobalVariable__c(name=key,Value__c=theVariables.get(key)));
        }
        System.assertEquals('abc', GlobalVariable.getInstance().simpleGeoOAuthKey);
        System.assertEquals('def', GlobalVariable.getInstance().simpleGeoSecretKey);
    }

    private static testmethod void testGlobalVariablesDoNotExist(){
        final Map<String,String> theVariables = new Map<String,String>{
             GlobalVariable.KEY_SIMPLE_GEO_OAUTH_KEY    => null
            ,GlobalVariable.KEY_SIMPLE_GEO_SECRET_KEY   => null
        };
        for(String key : theVariables.keySet()){
            GlobalVariableTestUtils.ensureExists(new GlobalVariable__c(name=key,Value__c=theVariables.get(key)));
        }
        System.assertEquals(null, GlobalVariable.getInstance().simpleGeoOAuthKey);
        System.assertEquals(null, GlobalVariable.getInstance().simpleGeoSecretKey);
    }

}
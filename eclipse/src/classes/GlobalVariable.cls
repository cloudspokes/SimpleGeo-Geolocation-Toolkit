/* ============================================================
 * This code is part of Richard Vanhook's submission to the 
 * Cloudspokes Geolocation Toolkit challenge.
 *
 * This software is provided "AS IS," and you, its user, 
 * assume all risks when using it. 
 * ============================================================
 */
global class GlobalVariable {
    
    //==================================================
    // PROPERTIES
    //==================================================
    global static final String KEY_SIMPLE_GEO_OAUTH_KEY  = 'SimpleGeo.OAuthKey';
    global static final String KEY_SIMPLE_GEO_SECRET_KEY = 'SimpleGeo.SecretKey';

    global static GlobalVariable instance;

    global String simpleGeoOAuthKey  {get; private set;}
    global String simpleGeoSecretKey {get; private set;}

    //==================================================
    // CONSTRUCTOR  
    //==================================================
    private GlobalVariable(){
        simpleGeoOAuthKey  = retrieveString(KEY_SIMPLE_GEO_OAUTH_KEY);
        simpleGeoSecretKey = retrieveString(KEY_SIMPLE_GEO_SECRET_KEY);
    }

    global static GlobalVariable getInstance(){
        if(instance == null){
            instance = new GlobalVariable();
        }
        return instance;
    }

    //==================================================
    // HELPERS
    //==================================================
    private String retrieveString(String key){
        String returnValue = null;
        final Map<String,GlobalVariable__c> all = GlobalVariable__c.getAll();
        if(    key != null 
            && key.trim() != null 
            && key.trim().length() > 0 
            && all != null 
            && all.get(key) != null
        ){
            returnValue = all.get(key).value__c;
        }
        return returnValue;
    }
    
}
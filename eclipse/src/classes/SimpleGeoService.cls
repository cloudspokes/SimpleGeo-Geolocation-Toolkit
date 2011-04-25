/* ============================================================
 * This code is part of Richard Vanhook's submission to the 
 * Cloudspokes Geolocation Toolkit challenge.
 *
 * This software is provided "AS IS," and you, its user, 
 * assume all risks when using it. 
 * ============================================================
 */
global class SimpleGeoService implements IGeocodeServiceAdapter{
    
    //==================================================
    // PROPERTIES
    //==================================================
    private static SimpleGeoService instance;
    
    //==================================================
    // CONSTRUCTOR  
    //==================================================
    private SimpleGeoService(){}
    
    //==================================================
    // METHODS
    //==================================================
    global static SimpleGeoService getInstance(){
        if(instance == null){
            instance = new SimpleGeoService();
        }
        return instance;
    }

    global static GeoPoint lookup(String address){
    	address = al.StringUtils.remove(address, '\n');
        if(al.StringUtils.isBlank(address)) 
            throw new SimpleGeoServiceException('address parameter cannot be blank');
        if(al.StringUtils.isBlank(GlobalVariable.getInstance().simpleGeoOAuthKey)) 
            throw new SimpleGeoServiceException('Please create a GlobalVariable__c Custom Setting with name  ' + GlobalVariable.KEY_SIMPLE_GEO_OAUTH_KEY);
        if(al.StringUtils.isBlank(GlobalVariable.getInstance().simpleGeoSecretKey)) 
            throw new SimpleGeoServiceException('Please create a GlobalVariable__c Custom Setting with name ' + GlobalVariable.KEY_SIMPLE_GEO_SECRET_KEY);

        final HttpRequest request = new HttpRequest();
        request.setEndpoint('http://api.simplegeo.com/1.0/context/address.json?address="' + address + '"');
        request.setMethod('GET');
        sign(request,GlobalVariable.getInstance().simpleGeoOAuthKey,GlobalVariable.getInstance().simpleGeoSecretKey);
        debug(request);
        final HttpResponse response = al.HttpUtils.send(request); 
        debug(response);
        if(response == null || response.getStatusCode() != 200){
            String message = '';
            if(response != null){
                message = response.getStatus();
            }
            throw new SimpleGeoServiceException(message);
        }
        return findFirstPoint(response.getBody());
    }
    
    global static GeoPoint findFirstPoint(String reponse){
        GeoPoint returnValue = null;
        try{
            final String lat = al.StringUtils.substringBefore(al.StringUtils.substringAfter(reponse,'"latitude":'),',');
            final String lng = al.StringUtils.substringBefore(al.StringUtils.substringAfter(reponse,'"longitude":'),',');
            if(al.StringUtils.isBlank(lat) || al.StringUtils.isBlank(lng)){
                throw new SimpleGeoServiceException('Address not found');
            }
            returnValue = new GeoPoint(parseCoordinate(lat),parseCoordinate(lng));
        }catch(Exception e){
            throw new SimpleGeoServiceException('Failed to parse response: '+e.getMessage(),e);
        }
        return returnValue;
        
    }
    
    //==================================================
    // STATIC HELPER METHODS
    //==================================================
    private static Double parseCoordinate(String value){
        Double returnValue = null;
        if(al.StringUtils.isNotBlank(value)){
            try{
                returnValue = Double.valueOf(al.StringUtils.trim(value));
            }catch(System.TypeException e){
                throw new SimpleGeoServiceException('Invalid coordinate: ' + value,e); 
            }
        }
        return returnValue;
    }
    
    global static String sign(
         String data
        ,String secretKey
    ){
        return EncodingUtil.urlEncode(
            EncodingUtil.base64Encode(
                Crypto.generateMac(
                      'HmacSHA1'
                    , Blob.valueOf(data)
                    , Blob.valueOf(secretKey+'&')
                )
            ), 'UTF-8'
        );
    }

    global static void sign(
         HttpRequest request
        ,String      oauthKey
        ,String      secret 
    ){
        if(request == null) throw new al.IllegalArgumentException('request argument cannot be null');
        final Map<String,String> parameters = new Map<String,String>{
             'oauth_consumer_key'      => oauthKey
            ,'oauth_signature_method'  => 'HMAC-SHA1'
            ,'oauth_timestamp'         => String.valueOf(DateTime.now().getTime()/1000)
            ,'oauth_nonce'             => String.valueOf(Crypto.getRandomInteger())
        };
        final Map<String,String> parameters2 = parameters.clone();
        parameters2.putAll(getUrlParams(request.getEndpoint()));
        final String stringToSign = 
              request.getMethod().toUpperCase()
            + '&' + EncodingUtil.urlEncode(al.StringUtils.substringBefore(request.getEndpoint(), '?'), 'UTF-8')
            + '&' + EncodingUtil.urlEncode(joinMap(parameters2,'=','&'), 'UTF-8')
        ;
        parameters.put('oauth_signature',sign(stringToSign,secret));
        
        final Map<String,String> parametersWithValueQuoted = new Map<String,String>();
        for(String key : parameters.keySet()){
            parametersWithValueQuoted.put(key,'"'+parameters.get(key)+'"');
        }
        request.setHeader('Authorization','OAuth ' + joinMap(parametersWithValueQuoted,'=',','));      
    }
    

    global static Map<String,String> getUrlParams(String url) {
        final Map<String,String> returnValue = new Map<String,String>();
        url = al.StringUtils.substringAfter(url, '?');
        if(al.StringUtils.isNotBlank(url)){
            for(String s : url.split('&')) {
                List<String> kv = s.split('=');
                if(kv.size()>1) {
                    returnValue.put(
                        EncodingUtil.urlEncode(EncodingUtil.urlDecode(kv[0], 'UTF-8'), 'UTF-8').replace('+','')
                        ,EncodingUtil.urlEncode(EncodingUtil.urlDecode(kv[1], 'UTF-8'), 'UTF-8').replace('+','')
                    );
                }
            }
        }
        return returnValue;
    }
    
    global static void debug(HttpRequest request){
        System.debug(toStr(request));
    }
    
    global static String toStr(HttpRequest request){
        String returnValue = '';
        if(request != null){
            returnValue = '\n'
                + '\n###########################################################'
                + '\nHTTP REQUEST: ' 
                + '\n###########################################################'
                + '\nCompressed: ' + request.getCompressed()
                + '\nEndpoint: ' + request.getEndpoint()
                + '\nMethod: ' + request.getMethod()
                + '\nBody: '
                + '\n' + request.getBody()
                + '\n'
                + '\n';
        }
        return returnValue;
    }
    
    global static void debug(HttpResponse response){
        if(response != null){
            System.debug('\n'
                + '\n###########################################################'
                + '\nHTTP RESPONSE: ' 
                + '\n###########################################################'
                + '\nHeaders:    ' + retrieveHeaders(response)
                + '\nStatusCode: ' + response.getStatusCode()
                + '\nStatus:     ' + response.getStatus()
                + '\nBody: '
                + '\n' + response.getBody()
                + '\n'
                + '\n'
            );
        }
    }

    global static String retrieveHeaders(HttpResponse response){
        String returnValue = '';
        if(response != null && response.getHeaderKeys() != null && response.getHeaderKeys().size() > 0){
            final Map<String,String> headers = new Map<String,String>();
            for(String key : response.getHeaderKeys()){
                if(key != null){
                    headers.put(key,response.getHeader(key));
                }
            }
            returnValue = joinMap(headers,'=',',');
        }
        returnValue = '[' + returnValue + ']';
        return returnValue;
    }    

    global static List<String> joinMap(Map<String,String> theMap, String keyValueSeparator){
        List<String> returnValue = null;
        if(theMap != null){
            returnValue = new List<String>();
            if(theMap.size() > 0){
                final List<String> keys = new List<String>();
                keys.addAll(theMap.keySet());
                keys.sort();
                for(String key : keys){
                    returnValue.add(key + keyValueSeparator + theMap.get(key));
                }
            }
        }
        return returnValue;
    }

    global static String joinMap(Map<String,String> theMap, String keyValueSeparator, String recordSeparator){
        String returnValue = null;
        if(theMap != null){
            returnValue = '';
            if(theMap.size() > 0){
                returnValue = al.StringUtils.joinArray(joinMap(theMap,keyValueSeparator), recordSeparator);
            }
        }
        return returnValue;
    }

}
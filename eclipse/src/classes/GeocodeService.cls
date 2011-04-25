/* ============================================================
 * This code is part of Richard Vanhook's submission to the 
 * Cloudspokes Geolocation Toolkit challenge.
 *
 * This software is provided "AS IS," and you, its user, 
 * assume all risks when using it. 
 * ============================================================
 */
/*
So long as you have a single field on a custom object which represents
an address and two Double fields which capture latitude and longitude, 
then this class can geocode it for you.  A simple way of having a single
field to represent address, is to use a Formula field.  The following is
an example for Billing Address on Account:

F(ISBLANK(BillingStreet),'', BillingStreet) 
& 
IF(ISBLANK(BillingCity),'', ',' & BillingCity) 
& 
IF(ISBLANK(BillingState),'', ',' & BillingState) 
& 
IF(ISBLANK(BillingPostalCode),'', ',' & BillingPostalCode) 

NOTE:  BillingCountry was intentionally left off because Simple Geo isn't a fan.
If you want BillingCountry, specify:

& 
IF(ISBLANK(BillingCountry),'', ',' & BillingCountry)


Latitude and longitude fields should be type Number(3,15).  Once those
three fields are setup, the following anonymous apex will geocode records on 
that object:


System.debug(                           //after running this command, the batch apex job ID will be output to the log
    GeocodeService.geocodeEnMasse(
         'BillingAddress__c'            //address field name
        ,'Latitude__c'                  //the latitude field to update
        ,'Longitude__c'                 //the longitude field to update
        ,'Account'                      //the object name which contains the latitude and longitude fields
        ,null                           //criteria; null means attempt to geocode all records on the object
        ,'richard.vanhook@gmail.com'    //optional email to notify when complete
    )    
);

*/

global class GeocodeService implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts{

    //==================================================
    // STATIC PROPERTIES
    //==================================================

    //track future context; global so it can be manipulated in tests
    global static Boolean futureFlag = false;

    //used for sorting
    private static final al.PrimitiveComparator primitiveComparator = new al.PrimitiveComparator();

    //for batch mode
    global  String       addressFieldName   {get;private set;}
    global  String       latitudeFieldName  {get;private set;}
    global  String       longitudeFieldName {get;private set;}
    global  String       objectName         {get;private set;}
    global  al.Condition criteria           {get;private set;}
    global  String       sendReportToEmail  {get;private set;}
    private Datetime     jobStartTime;
    private Long         recordCount;

    //==================================================
    // CONSTRUCTOR  
    //==================================================
    private GeocodeService(
         String        addressFieldName   //a formula field that combines whatever is the source 
        ,String        latitudeFieldName  //the latitude field to update
        ,String        longitudeFieldName //the longitude field to update
        ,String        objectName         //the object name which contains the latitude and longitude fields
        ,al.Condition  criteria           //the where clause for that object
        ,String        sendReportToEmail  //optional email to notify when complete
    ){
        this.addressFieldName   = addressFieldName;
        this.latitudeFieldName  = latitudeFieldName;
        this.longitudeFieldName = longitudeFieldName;
        this.objectName         = objectName;
        this.criteria           = criteria;
        this.sendReportToEmail  = sendReportToEmail;
    }
    
    //==================================================
    // SERVICE METHODS
    //==================================================
    global static void geocode(  
         List<SObject>  records            //the records to geocode
        ,String         addressFieldName   //a formula field that combines whatever is the source 
        ,String         latitudeFieldName  //the latitude field to update
        ,String         longitudeFieldName //the longitude field to update
    ){
        geocode(records, addressFieldName, latitudeFieldName, longitudeFieldName, false);
    }

    global static void geocode(  
         List<SObject>  records             //the records to geocode
        ,String         addressFieldName    //a formula field that combines whatever is the source 
        ,String         latitudeFieldName   //the latitude field to update
        ,String         longitudeFieldName  //the longitude field to update
        ,Boolean        asynchronousFlag    //run @future
    ){
    	if(asynchronousFlag == true){
    		if(futureFlag == false){ //<-- will auto prevent race condition when triggers invoke this service
	            geocodeFuture(
	                 al.SetUtils.objectToString(al.SetUtils.listToSet(al.ArrayUtils.pluck(records,'id')))
	                ,addressFieldName
	                ,latitudeFieldName
	                ,longitudeFieldName
	            );
    		}
    	} else {
    		geocodePopulate(
                records
                ,addressFieldName
                ,latitudeFieldName
                ,longitudeFieldName
                ,false
            );
    	}
    }

    global static ID geocodeEnMasse(  
         String         addressFieldName   //a formula field that combines whatever is the source 
        ,String         latitudeFieldName  //the latitude field to update
        ,String         longitudeFieldName //the longitude field to update
        ,String         objectName         //the object name which contains the latitude and longitude fields
        ,al.Condition   criteria           //the where clause for that object
        ,String         sendReportToEmail  //optional email to notify when complete
    ){
    	return Database.executeBatch(
	        new GeocodeService(
                 addressFieldName                
                ,latitudeFieldName  
                ,longitudeFieldName
	            ,objectName
	            ,criteria
		        ,sendReportToEmail 
	        ),1 //unfortunately, only one web service callout can be done per batch
		);
    }
    
    global static GeoPoint lookup(String address){
        return getAdapter().lookup(address);
    }

    global static List<SearchResult> findNearbyRecords(
         GeoPoint       point
        ,Double         distanceInKilometers
        ,Set<String>    fields
        ,String         latitudeFieldName  //the latitude field to update
        ,String         longitudeFieldName //the longitude field to update
        ,String         objectName         //the object name which contains the latitude and longitude fields
        ,al.Condition   extraCriteria
    ){
    	//argument scrubbing
        if(point == null) throw new al.IllegalArgumentException('point argument cannot be null');
        if(distanceInKilometers == null || distanceInKilometers <= 0) throw new al.IllegalArgumentException('distanceInKilometers argument cannot be null and must be greater than zero');
        if(al.StringUtils.isBlank(latitudeFieldName)) throw new al.IllegalArgumentException('latitudeFieldName argument cannot be null');
        if(al.StringUtils.isBlank(longitudeFieldName)) throw new al.IllegalArgumentException('latitudeFieldName argument cannot be null');
        if(al.StringUtils.isBlank(objectName)) throw new al.IllegalArgumentException('objectName argument cannot be null');
        if(fields == null) fields = new Set<String>();
        fields = al.SetUtils.lowerCase(fields.clone());
        fields.add(latitudeFieldName);
        fields.add(longitudeFieldName);
        fields.add('name');

    	final GeoBounds bounds = getBounds(point, distanceInKilometers);
        final al.NestableCondition criteria = 
            new al.AndCondition()
            .add(new al.FieldCondition(latitudeFieldName ).notEquals           (null)) 
            .add(new al.FieldCondition(longitudeFieldName).notEquals           (null)) 
            .add(new al.FieldCondition(latitudeFieldName ).lessThanOrEqualTo   (bounds.northeast.latitude)) 
            .add(new al.FieldCondition(longitudeFieldName).lessThanOrEqualTo   (bounds.northeast.longitude)) 
            .add(new al.FieldCondition(latitudeFieldName ).greaterThanOrEqualTo(bounds.southwest.latitude)) 
            .add(new al.FieldCondition(longitudeFieldName).greaterThanOrEqualTo(bounds.southwest.longitude))
        ;
        if(extraCriteria != null) criteria.add(extraCriteria);
        final String soql = new al.SoqlBuilder()
            .selectx(fields)
            .fromx(objectName)
            .wherex(criteria)
            .toSoql(new al.SoqlOptions().wildcardStringsInLikeOperators());
        System.debug('### soql ' + soql);
        final List<SObject> records = Database.query(soql);
        final List<SearchResult> returnValue = new List<SearchResult>();
        if(records != null && records.size() > 0){
        	SearchResult result = null;
        	for(SObject record : records){
        		result = new SearchResult();
        		try{
	                result.point = new GeoPoint((Double)record.get(latitudeFieldName), (Double)record.get(longitudeFieldName));
        		}catch(Exception e){
				    continue;
				}
				result.distanceInKilometers = determineDistanceInKilometers(point,result.point);
                result.record               = record;
                result.id = record.id;
                if(record.get('name') != null) result.name = (String)record.get('name');
        		returnValue.add(result);
        	}
        	al.ArrayUtils.qsort(filterResultsOutsideDistance(returnValue,distanceInKilometers),new SearchResultComparator());
        }        
        return returnValue;
    }

    private static IGeocodeServiceAdapter getAdapter(){
    	//idea here: this should be the only line to change if you implement
    	//  another geocoding service such as Google Maps 
        return SimpleGeoService.getInstance();
    }

    //==================================================
    // BATCH JOB METHODS
    //==================================================
    global Database.QueryLocator start(Database.BatchableContext context){
        this.jobStartTime = Datetime.now();
        sendMessage(context,'Started.  \n\nParams:' 
           + '\naddressFieldName: ' + this.addressFieldName 
           + '\nlatitudeFieldName: ' + this.latitudeFieldName 
           + '\nlongitudeFieldName: ' + this.longitudeFieldName 
           + '\nobjectName: ' + this.objectName 
           + '\ncriteria: ' + this.criteria 
           + '\nsendReportToEmail: ' + this.sendReportToEmail 
           + '\n');
        this.recordCount = 0;
        final String soql = 
            new al.SoqlBuilder()
            .selectx(new Set<String>{this.addressFieldName,this.latitudeFieldName,this.longitudeFieldName})
            .fromx(this.objectName)
            .wherex(this.criteria)
            .toSoql();
        System.debug('### soql ' + soql);
        return Database.getQueryLocator(al.StringUtils.replace(soql,'\n',' '));
    }
    
    global void execute(Database.BatchableContext context, List<SObject> records){
    	if(records != null) recordCount += records.size();
        geocodePopulate(
             records
            ,this.addressFieldName
            ,this.latitudeFieldName
            ,this.longitudeFieldName
            ,true
        );
    }
    
    global void finish(Database.BatchableContext context){
    	String timeStr = '?';
    	if(this.jobStartTime != null) timeStr = ''+((Datetime.now().getTime() - this.jobStartTime.getTime())/1000);
        sendMessage(context,'Finished.  Job took ' 
            + timeStr 
            + ' second(s) to run.  ' 
            + this.recordCount 
            + ' ' 
            + this.objectName 
            + ' records met your criteria.');
    }

    //==================================================
    // MATH HELPER METHODS
    //==================================================
    global static final Double KM_IN_ONE_LATITUDE_DEGREE = 111.132;
    global static final Double MEAN_EARTH_RADIUS_KM = 6371;
    global static final Double PI = 3.1415926535897932384626433832795;
    
    global static GeoBounds getBounds(GeoPoint point, Double distanceInKilometers){
        Double distLatDeg = distanceInKilometers/KM_IN_ONE_LATITUDE_DEGREE;
        Double distLngDeg = distLatDeg/Math.cos((point.lat()*PI)/180);
        Double neLat = point.lat()+distLatDeg;
        Double neLng = point.lng()+distLngDeg;
        Double swLat = point.lat()-distLatDeg;
        Double swLng = point.lng()-distLngDeg;
        neLat = (neLat < -90 || neLat > 90) ? 90 : neLat;
        neLng = (neLng < -180 || neLng > 180) ? 180 : neLng;
        swLat = (swLat < -90 || swLat > 90) ? -90 : swLat;
        swLng = (swLng < -180 || swLng > 180) ? -180 : swLng;
        return new GeoBounds(new GeoPoint(neLat, neLng),new GeoPoint(swLat, swLng));
    }
    
    global static Double determineDistanceInKilometers(GeoPoint point1, GeoPoint point2){
        if(point1==null || point2==null){
            throw new al.IllegalArgumentException();
        }
        Double a = 
            Math.pow(Math.sin(((point2.lat() - point1.lat())*(PI/180))/2),2) + 
            Math.cos(point1.latRadians()) * 
            Math.cos(point2.latRadians()) * 
            Math.pow(Math.sin(((point2.lng() - point1.lng())*(PI/180))/2),2);
        return MEAN_EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
    } 

    global static final Double KILOMETERS_IN_ONE_MILE  = 1.609344;

    global static Double milesToKilometers(Double miles){
        if(miles == null) miles = 0;
        return miles * KILOMETERS_IN_ONE_MILE;
    }

    global static Double kilometersToMiles(Double kilometers){
        if(kilometers == null) kilometers = 0;
        return kilometers * (1/KILOMETERS_IN_ONE_MILE);
    }

    //==================================================
    // PRIVATE HELPER METHODS
    //==================================================
    @future (callout = true)
    private static void geocodeFuture(  
         Set<String> recordIds
        ,String addressFieldName 
        ,String latitudeFieldName
        ,String longitudeFieldName
    ){
        geocodePopulate(
             al.DatabaseUtils.query(recordIds, new Set<String>{addressFieldName, latitudeFieldName, longitudeFieldName})
            ,addressFieldName
            ,latitudeFieldName
            ,longitudeFieldName
            ,true
        );
    }

    private static void geocodePopulate(  
         List<SObject> records
        ,String addressFieldName 
        ,String latitudeFieldName
        ,String longitudeFieldName
        ,Boolean updateFlag
    ){
        futureFlag = true;
        if(records != null && records.size() > 0){
        	final List<Exception> exceptions = new List<Exception>();
	        final List<SObject> recordsToUpdate = new List<SObject>();
            GeoPoint thePoint = null;
            String address = null;
            for(SObject record : records){
                try{
	                if(!Test.isRunningTest() && Limits.getCallouts() >= Limits.getLimitCallouts()){
	                	try{
	                        throw new al.IllegalStateException('out of web service callouts');
		                }catch(al.IllegalStateException e){
		                    exceptions.add(e);
		                    break;
		                }
	                }
	                address = (String)record.get(addressFieldName);
	                if(al.StringUtils.isBlank(address)) continue;
                    thePoint = lookup(address);
                }catch(GeocodeServiceException e){
                    System.debug('geocode lookup failed for record: ' + record);
                    exceptions.add(e);
                    continue;
                }
                if(thePoint != null){
                    record.put(latitudeFieldName,thePoint.latitude);
                    record.put(longitudeFieldName,thePoint.longitude);
                    recordsToUpdate.add(record);
                }
            }
	        if(updateFlag == true && recordsToUpdate.size() > 0) update recordsToUpdate;
            if(exceptions.size() == 1){
            	throw exceptions.get(0);
            }
            if(exceptions.size() > 1){
            	final List<String> messages = new List<String>();
            	Integer i = 1;
            	for(Exception e : exceptions){
            		messages.add('\nException ' + i + ': ' + e.getMessage());
            		i++;
            	} 
            	throw new GeocodeServiceException(exceptions.size() + ' exception(s) occurred: ' + al.StringUtils.joinArray(messages));
            }
        }
    }

    private void sendMessage(Database.BatchableContext context, String message){
        if(this.sendReportToEmail != null){
            al.EmailUtils.sendTextEmail(
                 new List<String>{this.sendReportToEmail}
                ,'Message from GeocodeService Job ID:' 
                    + context.getJobId() 
                    + ')'
                ,message
                    + '\n\nUser: '
                    + UserInfo.getName()
                    + ' (' 
                    + UserInfo.getUserName() 
                    + ',' 
                    + UserInfo.getUserId()
                    + ')\nOrganization: ' 
                    + UserInfo.getOrganizationName() 
                    + ' (' 
                    + UserInfo.getOrganizationId()
                    + ')\nDate/time: '
                    + Datetime.now()
            );
        }
    }
    
    private static List<Object> filterResultsOutsideDistance( 
         List<SearchResult> results 
        ,Double             limitDistanceInKilometers
    ){
        if(results != null && results.size() > 0){
            List<Integer> indicesToRemove = new List<Integer>();
            for(Integer i = 0; i < results.size(); i++){
                if(results.get(i).distanceInKilometers > limitDistanceInKilometers){
                    indicesToRemove.add(i);
                }
            }
            for(Integer i = 0; i < indicesToRemove.size(); i++){
                results.remove(indicesToRemove.get(i)-i);
            }
        }
        return results;
    }
    
    global class SearchResult {
        global GeoPoint point                {get;set;}
        global Double   distanceInKilometers {get;set;}
        global SObject  record               {get;set;}
        global String   id                   {get;set;}
        global String   name                 {get;set;}
    }    

    global class SearchResultComparator implements al.ObjectComparator{
	    global Integer compare(Object object1, Object object2){
	        if(object1==null && object2 == null){
	            return 0;
	        } else if(object1==null || !(object1 instanceof SearchResult)){
	            return -1;
	        } else if(object2==null || !(object2 instanceof SearchResult)){
	            return 1;
	        }
	        return primitiveComparator.compare(((SearchResult) object1).distanceInKilometers,((SearchResult) object2).distanceInKilometers);
	    }
    }
}
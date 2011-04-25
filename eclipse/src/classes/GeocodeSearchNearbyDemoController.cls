/* ============================================================
 * This code is part of Richard Vanhook's submission to the 
 * Cloudspokes Geolocation Toolkit challenge.
 *
 * This software is provided "AS IS," and you, its user, 
 * assume all risks when using it. 
 * ============================================================
 */
global class GeocodeSearchNearbyDemoController implements al.ObjectPaginatorListener{

    //search fields
    global String  addressInput       {get;set;}
    global Integer distance           {get;set;}
    global String  unit               {get;set;}
    global String  latitudeFieldName  {get;set;}
    global String  longitudeFieldName {get;set;}
    global String  objectName         {get;set;}

    //result fields
    global List<GeocodeService.SearchResult> results        {get;private set;}
    global al.ObjectPaginator                paginator      {get;private set;}
    global Boolean                           searchExecuted {get;private set;}

    global GeocodeSearchNearbyDemoController(){
    	this.addressInput       = null;
        this.distance           = 100;
        this.unit               = 'km';
    	//defaulting for Cloudspokes challenge
        this.latitudeFieldName  = 'Latitude__c';
        this.longitudeFieldName = 'Longitude__c';
        this.objectName         = 'Account';
        this.results            = null;
        this.paginator          = new al.ObjectPaginator(this);
        this.searchExecuted     = false;        
    }
    
    global PageReference doSearchNearby(){
        searchExecuted = false;        
    	if(al.StringUtils.isBlank(addressInput)) return error('Please enter a search string!');
    	GeoPoint searchPoint = null;
    	try{
    		searchPoint = GeocodeService.lookup(addressInput);
    	}catch(Exception e){
    	    return error('Search failed: ' + e.getMessage());
    	}
        if(searchPoint == null) return error('\'' + addressInput + '\' not found');
        
        try{
        	Double searchDistance = Double.valueOf(distance);
        	if('mi'.equalsIgnoreCase(unit)) searchDistance = GeocodeService.milesToKilometers(searchDistance);
	        paginator.setRecords(
	            GeocodeService.findNearbyRecords(
	                 searchPoint
	                ,searchDistance
	                ,null
	                ,this.latitudeFieldName
	                ,this.longitudeFieldName
	                ,this.objectName
	                ,null
	            )
	        );        
        }catch(Exception e){
            return error('Search failed: ' + e.getMessage());
        }
        searchExecuted = true;        
        return null;
    }
    
    private PageReference error(String msg){
    	al.PageUtils.addError(msg);
    	return null;
    }

    global void handlePageChange(List<Object> records){
        if(results == null) results = new List<GeocodeService.SearchResult>();
        results.clear();
        if(records != null && records.size() > 0){
            for(Object record : records){
                if(record != null && record instanceof GeocodeService.SearchResult){
                    results.add((GeocodeService.SearchResult) record);
                }
            }
        }
    }
    
    global List<SelectOption> distanceOptions {get{
        return new List<SelectOption>{
             new SelectOption('5','5')
            ,new SelectOption('10','10')
            ,new SelectOption('20','20')
            ,new SelectOption('50','50')
            ,new SelectOption('100','100')
            ,new SelectOption('200','200')
            ,new SelectOption('400','400')
            ,new SelectOption('800','800')
        };
    }}
    
    global List<SelectOption> unitOptions {get{
        return new List<SelectOption>{
             new SelectOption('km','Kilometers')
            ,new SelectOption('mi','Miles')
        };
    }}
    
    
}
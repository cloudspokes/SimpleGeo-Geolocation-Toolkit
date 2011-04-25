/* ============================================================
 * This code is part of Richard Vanhook's submission to the 
 * Cloudspokes Geolocation Toolkit challenge.
 *
 * This software is provided "AS IS," and you, its user, 
 * assume all risks when using it. 
 * ============================================================
 */
global class GeoBounds {

    global static final GeoBounds MAX = new GeoBounds(
        new GeoPoint(-90,-180)
        ,new GeoPoint(90,180)
    ); 
    
	global GeoPoint northeast {get;set;}
	global GeoPoint southwest {get;set;}

	global GeoBounds(List<GeoPoint> points){
		initialize(points);
	}
	
	global GeoBounds(GeoPoint southwest, GeoPoint northeast){
		initialize(new GeoPoint[]{southwest,northeast});
	}
	
	private void initialize(List<GeoPoint> points){
		if(points != null && points.size()>0){
			Double minLat = 90; 
			Double maxLat = -90; 
			Double minLng = 180; 
			Double maxLng = -180;
			for(GeoPoint point : points){
				minLat = point.lat() < minLat ? point.lat() : minLat;
				maxLat = point.lat() > maxLat ? point.lat() : maxLat;
				minLng = point.lng() < minLng ? point.lng() : minLng;
				maxLng = point.lng() > maxLng ? point.lng() : maxLng;
			} 
			this.northeast = new GeoPoint(maxLat,maxLng);
			this.southwest = new GeoPoint(minLat,minLng);
		}
	}
	
	global Boolean contains(GeoPoint point){
		if(point == null || northeast == null || southwest == null){
			return false;
		}
		return 
				this.northeast.lat() > point.lat()
			&& 	this.southwest.lat() < point.lat()
			&& 	this.northeast.lng() > point.lng()
			&& 	this.southwest.lng() < point.lng()
		;
	}

	global String toStr(){
		return '<#GeoBounds(northeast=' + (northeast==null ? null : northeast.toStr()) 
			+ ',southwest=' + (southwest==null ? null : southwest.toStr()) + ')>';
	}
}
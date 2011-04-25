/* ============================================================
 * This code is part of Richard Vanhook's submission to the 
 * Cloudspokes Geolocation Toolkit challenge.
 *
 * This software is provided "AS IS," and you, its user, 
 * assume all risks when using it. 
 * ============================================================
 */
@IsTest
private class GeoPointTest {
	
    private static testmethod void testNormal(){
        GeoPoint p1 = new GeoPoint(1.23,4.56);
        
        System.assertEquals(p1.latitude,p1.lat());
        System.assertEquals(p1.longitude,p1.lng());

        System.assertEquals(p1.latitude*(GeoPoint.PI/180),p1.latRadians());
        System.assertEquals(p1.longitude*(GeoPoint.PI/180),p1.lngRadians());

        GeoPoint p2 = new GeoPoint(1.23,4.56);
        System.assert(p1.equals(p2));
        System.assert(p2.equals(p1));
        GeoPoint p3 = new GeoPoint(10,10);
        System.assert(p1.equals(null)==false);
        System.assert(p1.equals(p3)==false);
        System.assert(p3.equals(p1)==false);
        System.assertEquals('<#GeoPoint(latitude=1.23,longitude=4.56)>',p1.toStr());
    }

    private static testmethod void testInvalidArgs(){
        Boolean exceptionThrown = false;
        try{GeoPoint p1 = new GeoPoint(-91,0); }catch(al.IllegalArgumentException e){exceptionThrown = true;}
        System.assert(exceptionThrown);
        try{GeoPoint p1 = new GeoPoint(91,0); }catch(al.IllegalArgumentException e){exceptionThrown = true;}
        System.assert(exceptionThrown);
        try{GeoPoint p1 = new GeoPoint(0,-181); }catch(al.IllegalArgumentException e){exceptionThrown = true;}
        System.assert(exceptionThrown);
        try{GeoPoint p1 = new GeoPoint(0,181); }catch(al.IllegalArgumentException e){exceptionThrown = true;}
        System.assert(exceptionThrown);
    }
    
}
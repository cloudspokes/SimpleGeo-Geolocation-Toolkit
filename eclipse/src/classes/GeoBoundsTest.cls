/* ============================================================
 * This code is part of Richard Vanhook's submission to the 
 * Cloudspokes Geolocation Toolkit challenge.
 *
 * This software is provided "AS IS," and you, its user, 
 * assume all risks when using it. 
 * ============================================================
 */
@IsTest
private class GeoBoundsTest {
    
    private static testmethod void test1(){
        final GeoBounds bounds = new GeoBounds(new List<GeoPoint>{
             new GeoPoint(1,-1)
            ,new GeoPoint(-1,2)
            ,new GeoPoint(-2,1)
        });
        
        System.assertEquals(1,bounds.northeast.lat());
        System.assertEquals(2,bounds.northeast.lng());
        System.assertEquals(-2,bounds.southwest.lat());
        System.assertEquals(-1,bounds.southwest.lng());

        System.assertEquals(true,bounds.contains(new GeoPoint(0,1)));
        System.assertEquals(false,bounds.contains(new GeoPoint(3,3)));
    }

    private static testmethod void test2(){
        final GeoBounds bounds = new GeoBounds(
             new GeoPoint(1,-1)
            ,new GeoPoint(-1,2)
        );
        
        System.assertEquals(1,bounds.northeast.lat());
        System.assertEquals(2,bounds.northeast.lng());
        System.assertEquals(-1,bounds.southwest.lat());
        System.assertEquals(-1,bounds.southwest.lng());

        System.assertEquals(true,bounds.contains(new GeoPoint(0,1)));
        System.assertEquals(false,bounds.contains(new GeoPoint(3,3)));
    }
    
}
/* ============================================================
 * This code is part of Richard Vanhook's submission to the 
 * Cloudspokes Geolocation Toolkit challenge.
 *
 * This software is provided "AS IS," and you, its user, 
 * assume all risks when using it. 
 * ============================================================
 */
@IsTest
private class GlobalVariableTestUtilsTest {
    
    private static testmethod void testEnsureGlobalVariableExists_Null(){
        System.assertEquals(null,GlobalVariableTestUtils.ensureExists(null));
        System.assertNotEquals(null,GlobalVariableTestUtils.ensureExists(new GlobalVariable__c()));
    }

    private static testmethod void testEnsureGlobalVariableExists_Insert(){
        GlobalVariable__c record = new GlobalVariable__c(
            name     = 'test 123'
            ,Value__c = 'xyz'
        );
        record = GlobalVariableTestUtils.ensureExists(record);
        System.assertNotEquals(null,record);
        System.assertNotEquals(null,record.id);
        try{
            record = [    
               select id 
               from GlobalVariable__c 
               where name = :'test 123' 
               limit 1 
            ];
        }catch(QueryException e){}
        System.assertNotEquals(null,record);
    }

    private static testmethod void testEnsureGlobalVariableExists_UpdateOther(){
        GlobalVariable__c record = new GlobalVariable__c(
            name     = 'test 123'
            ,Value__c = 'xyz'
        );
        insert record;
        record = GlobalVariableTestUtils.ensureExists(record.clone(false));
        System.assertNotEquals(null,record);
        System.assertNotEquals(null,record.id);
        try{
            record = [    
               select id 
               from GlobalVariable__c 
               where name = :'test 123' 
               limit 1 
            ];
        }catch(QueryException e){}
        System.assertNotEquals(null,record);
    }

    private static testmethod void testEnsureGlobalVariableExists_UpdateItself(){
        GlobalVariable__c record = new GlobalVariable__c(
            name     = 'test 123'
            ,Value__c = 'xyz'
        );
        insert record;
        record = GlobalVariableTestUtils.ensureExists(record);
        System.assertNotEquals(null,record);
        System.assertNotEquals(null,record.id);
        try{
            record = [    
               select id 
               from GlobalVariable__c 
               where name = :'test 123' 
               limit 1 
            ];
        }catch(QueryException e){}
        System.assertNotEquals(null,record);
    }

}
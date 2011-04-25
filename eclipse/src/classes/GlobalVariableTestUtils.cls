/* ============================================================
 * This code is part of Richard Vanhook's submission to the 
 * Cloudspokes Geolocation Toolkit challenge.
 *
 * This software is provided "AS IS," and you, its user, 
 * assume all risks when using it. 
 * ============================================================
 */
global class GlobalVariableTestUtils {

    global static GlobalVariable__c ensureExists(GlobalVariable__c record){
        if(record != null && !isBlank(record.name)){
            GlobalVariable__c queried = null;
            try{
                queried = [   
                    select id 
                    from GlobalVariable__c 
                    where name = :record.name
                ];
            }catch(QueryException e){}
            if(queried != null && queried.id != record.id){
                delete queried;
            }
            if(record.id != null){
                update record;
            } else {
                insert record;
            }
        }
        return record;
    } 

    private static boolean isBlank(String str) {
        return str == null || str.trim() == null || str.trim().length() == 0;
    }


}
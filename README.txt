===========================
Setup:
===========================

Install apex-lang 1.17 managed package https://login.salesforce.com/?startURL=%2Fpackaging%2FinstallPackage.apexp%3Fp0%3D04t80000000jMfG

Deploy code to org

Obtain Simplegeo oath key and secret key

Go to Setup | App Setup | Develop | Custom Settings
Click Manage for Global Variables
Click New
For name, enter SimpleGeo.OAuthKey and in the Value field, enter your oauth key
Click Save
Click New
For name, enter SimpleGeo.SecretKey and in the Value field, enter your secret key
Click Save

Add a Remote Site to: http://api.simplegeo.com

Create some accounts with valid Billing Addresses in the United States (that's all Simplegeo supports)

Run following anonymously (to geocode accounts):

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

Once that's complete, go to VF page GeocodeSearchNearbyDemo and execute searches.

===========================
Notes:
===========================
Since the idea is to create a toolkit, my main goal
was to make my code reusable for any SObject (not
just Account) and also define an easy way for
other geocoding service to be plugged in.  The main 
class is GeocodeService and I suggest the following 
methods in that class as a starting place for review:

GeocodeService.geocode()
GeocodeService.geocodeEnMasse()
GeocodeService.findNearbyRecords()

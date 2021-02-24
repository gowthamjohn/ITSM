public with sharing class AccessCheck {
    
    public static boolean isAuthorizedToView(Schema.SObjectType someType, String query, List<String> listOfFields) {
        List<String> fieldNames;
        if (query != null) {
            fieldNames = query.split('SELECT ')[1].split(' FROM')[0].split(',');
        } else {
            fieldNames = listOfFields;
        }
        fieldNames = filterExistingFields(someType, fieldNames);
        
        Schema.DescribeSObjectResult objDesc = someType.getDescribe();
        if (!objDesc.isAccessible() || !objDesc.isQueryable()){
            throw new AccessControlException(someType.getDescribe().getLabel() + ' is not accessible');
        }
        Map<String, Schema.DescribeFieldResult> fMap = fieldMapFor(someType);
        
        for (String f : fieldNames) {
            f = f.trim();
            if (f.contains('.'))
                continue;
            Schema.DescribeFieldResult sObjectFld = fMap.get(f);
            
            if (sObjectFld == null) {
                throw new AccessControlException('Field not found - '+f);
            }
            
            if (!sObjectFld.isAccessible()){
                throw new AccessControlException('Field is not accessible - '+f);
            }
        }
        return true;
    }
    public static Boolean isAuthorizedToView(String sobjTypeName, List<String> fieldNames) {
        // check at object-level first
        Schema.SObjectType sobjType;
        
        if(sobjTypeName.endsWith('kav')){
            SObject objectRecord = (SObject)Type.forName(sobjTypeName).newInstance();
            sobjType = objectRecord.getSObjectType();
            
        } else{
            Schema.DescribeSobjectResult[] describeResults = Schema.describeSObjects(new List<String>{sobjTypeName});
            sobjType = describeResults[0].getSobjectType();
        }
        
        if(sobjType == null)
            return false;
        
        List<Schema.SObjectField> fields = new List<Schema.SObjectField>();
        Schema.DescribeSObjectResult gdObject = sobjType.getDescribe();
        if (!gdObject.isAccessible()){
            return false;
        }
        
        Map<String,Schema.SObjectField> sObjectFieldsMap = gdObject.fields.getMap();
        
        for (String fieldName: fieldNames)
        {
            Schema.SObjectField sObjectField = sObjectFieldsMap.get(fieldName);
            fields.add(sObjectField);
        }
        // check each field
        for (Schema.SObjectField f : fields) {
            if (!f.getDescribe().isAccessible()){
                return false;
            }
        }
        
        return true;
    }
    
    private static List<String> filterExistingFields(Schema.SObjectType objectType, List<String> fields) {
        Map<String, Schema.SObjectField> fieldsByFieldApiNames = objectType.getDescribe().fields.getMap();
        Set<String> existingFieldApiNames = new Set<String>();
        for (String fieldApiName : fieldsByFieldApiNames.keySet()) {
            existingFieldApiNames.add(fieldApiName.toLowerCase());
        }
        List<String> existingFields = new List<String>();
        for (String fieldApiName : fields) {
            if (existingFieldApiNames.contains(fieldApiName.toLowerCase())) {
                existingFields.add(fieldApiName);
            }
        }
        
        return existingFields;
    }
    
    private static Map<String, Schema.DescribeFieldResult> fieldMapFor(Schema.SObjectType objectType) {
        return CalendarHelper.getSchemaObjectFieldsMap(objectType.getDescribe());
    }
    
    public class AccessControlException extends Exception {
        
        private String eText;
        
        /**
* Constructor for AccessControlException.
* @param eText Error text
*/
        public AccessControlException(String eText, Boolean empty) {
            this.eText = eText;
        }
        
        /**
* Get the error text.
* You might not want to expose the details of the exception to the users.
* Note : to avoid XSS, make sure to escape text before presenting it to the user.
*/
        public String getText() {
            return this.eText;
        }
    }
}
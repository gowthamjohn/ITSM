public with sharing class RelatedListController {
    
    public static final String FIELDS_PARAM = 'fields';
    public static final String NUMBER_OF_RECORDS_PARAM = 'numberOfRecords';
    public static final String RECORD_ID_PARAM = 'recordId';
    public static final String SOBJECT_API_NAME_PARAM = 'sobjectApiName';
    public static final String SOBJECT_LABEL_PARAM = 'sobjectLabel';
    public static final String SOBJECT_LABEL_PLURAL_PARAM = 'sobjectLabelPlural';
    public static final String PARENT_RELATIONSHIP_API_NAME_PARAM = 'parentRelationshipApiName';
    public static final String RELATED_FIELD_API_NAME_PARAM = 'relatedFieldApiName';
    public static final String SORTED_DIRECTION_PARAM = 'sortedDirection';
    public static final String SORTED_BY_PARAM = 'sortedBy';
    public static final String RECORDS_PARAM = 'records';
    public static final String ICON_NAME_PARAM = 'iconName';
    public static final String recordType = 'recordTypeName';
    
    
    
    @AuraEnabled
    public static String initData(String jsonData){
        try{
            
            // Get datas for the configuration item relationships
            
            Map<String, Object> requestMap = (Map<String, Object>)JSON.deserializeUntyped(jsonData);  
            Map<String, Object> responseMap = new Map<String, Object>();
            responseMap.put(RECORDS_PARAM, getRecords(jsonData));
            
            String sobjectApiName = (String)requestMap.get(SOBJECT_API_NAME_PARAM);
            responseMap.put(ICON_NAME_PARAM, getIconName(sobjectApiName));
            
            String recordTypeName = (String)requestMap.get(recordType);
            responseMap.put(recordType, recordTypeName);
            
            
            String recordId = (String)requestMap.get(RECORD_ID_PARAM);
            String relatedFieldApiName = (String)requestMap.get(RELATED_FIELD_API_NAME_PARAM);
            responseMap.put(PARENT_RELATIONSHIP_API_NAME_PARAM, getParentRelationshipName(recordId, sobjectApiName, relatedFieldApiName));
            
            Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get(sobjectApiName);
            Schema.DescribeSObjectResult sobjectDescribe = sobjectType.getDescribe();
            responseMap.put(SOBJECT_LABEL_PARAM, sobjectDescribe.getLabel());
            responseMap.put(SOBJECT_LABEL_PLURAL_PARAM, sobjectDescribe.getLabelPlural());
            return JSON.serialize(responseMap);
            
		}catch(Exception e){
            throw new AurahandledException(e.getMessage());
        }
    }
    
    public static List<Sobject> getRecords(String jsonData){
		
        Map<String, Object> root = (Map<String, Object>)JSON.deserializeUntyped(jsonData); 
        String fields = (String)root.get(FIELDS_PARAM);
		Integer numberOfRecords = (Integer)root.get(NUMBER_OF_RECORDS_PARAM);
        String recordId = (String)root.get(RECORD_ID_PARAM);
		String relatedFieldApiName = (String)root.get(RELATED_FIELD_API_NAME_PARAM);
		String sobjectApiName = (String)root.get(SOBJECT_API_NAME_PARAM);        
		String orderBy = (String)root.get(SORTED_BY_PARAM) + ' ' + (String)root.get(SORTED_DIRECTION_PARAM);        
        String recordTypeFilterStr = (String)root.get('recordTypeFilter');
        Integer offSet = (Integer)root.get('offset');
        List<String> recordTypeFilters = new List<String>();
        String query = 'SELECT '+fields+' FROM '+sobjectApiName+' WHERE ';
        
        
        if(recordTypeFilterStr != null && recordTypeFilterStr != ''){
           recordTypeFilters =  (List<String>)System.JSON.deserialize(recordTypeFilterStr, List<String>.class);
        }
        
        if(recordTypeFilters.size() > 0){
            query += ' Recordtype.developerName In :recordTypeFilters AND ';
        }
        query += relatedFieldApiName+ '= :recordId '+' ORDER BY ' +orderBy+' LIMIT :numberOfRecords OFFSET :offSet';
        if(sobjectApiName == 'Case'){
            system.debug(' object is case');
            if(AccessCheck.isAuthorizedToView(Schema.Case.getSObjectType(), query,null)){
                return Database.query(String.escapeSingleQuotes(query));
            }
        }else if(sobjectApiName == 'citsm__CI_Change__c'){
            if(AccessCheck.isAuthorizedToView(Schema.citsm__CI_Change__c.getSObjectType(), query,null)){
                return Database.query(String.escapeSingleQuotes(query));
            }
        }else if(sobjectApiName == 'citsm__Configuration_Item_Attribute__c'){
            if(AccessCheck.isAuthorizedToView(Schema.citsm__Configuration_Item_Attribute__c.getSObjectType(), query,null)){
                return Database.query(String.escapeSingleQuotes(query));
            }
        }
        return null;

	}
        
    private static String getParentRelationshipName(Id recordId, String childSobjectApiName, String relatedFieldApiName){
        
        Schema.DescribeSObjectResult descrRes = recordId.getSObjectType().getDescribe();
        String name;
        for (Schema.ChildRelationship cr: descrRes.getChildRelationships()){ 
            if(cr.getChildSObject().getDescribe().getName() == childSobjectApiName&& cr.getField().getDescribe().getName() == relatedFieldApiName){
          	 	name = cr.getRelationshipName();
                break;
            }
        }
        return name;
    }

	@AuraEnabled
    public static Boolean deleteRecord(Id recordId){

        try{
           
            Sobject sobj = recordId.getSObjectType().newSObject(recordId);
            Database.DeleteResult result;
            if (recordId.getSObjectType().getDescribe().isDeletable()) {
                result = Database.delete(sobj, true);
            } else {
                throw new CustomException('You don\'t have permission to delete the record');
            }
            return result.isSuccess();
        }catch(Exception e){
            throw new AurahandledException(e.getMessage());
        }
	}       
    
    @AuraEnabled
    public static String getIconName(String sobjectApiName){
        
        String iconName;
        List<Schema.DescribeTabSetResult> tabSetDesc = Schema.DescribeTabs();
        List<Schema.DescribeTabResult> tabDesc = new List<Schema.DescribeTabResult>();
        List<Schema.DescribeIconResult> iconDesc = new List<Schema.DescribeIconResult>();

        for(Schema.DescribeTabSetResult tsr : tabSetDesc) { 
            tabDesc.addAll(tsr.getTabs()); 
        }

        for(Schema.DescribeTabResult tr : tabDesc) {
            if( sobjectApiName == tr.getSobjectName() ) {
                if( tr.isCustom() ) {
                    iconDesc.addAll(tr.getIcons());
                } else {
                    iconName = 'standard:' + sobjectApiName.toLowerCase();
                }
            }
        }
        for (Schema.DescribeIconResult ir : iconDesc) {
            if (ir.getContentType() == 'image/svg+xml'){
                iconName = 'custom:' + ir.getUrl().substringBetween('custom/','.svg').substringBefore('_');
                break;
            }
        }
        return iconName;
    }    
    
    public class CustomException extends Exception{}
}
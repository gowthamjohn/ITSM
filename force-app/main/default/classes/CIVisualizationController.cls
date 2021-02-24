public with sharing class CIVisualizationController {    
    
    @AuraEnabled
    public static String getRelatedInfoofCI(String conId){
        try{
            CIVisual ciVisualInfo = new CIVisual();
            List<CIVisualItem> childNodeList = new List<CIVisualItem>();
            List<Configuration_Item_Relationship__c> relationShipList = new  List<Configuration_Item_Relationship__c>();
            if(AccessCheck.isAuthorizedToView(Schema.Configuration_Item_Relationship__c.getSObjectType(), null,new List<String>{'citsm__Configuration_Item_Formula__c','citsm__Related_Configuration_Item__r.name','citsm__Related_Configuration_Item__c','Name','citsm__Relationship__c','citsm__Configuration_Item__c','citsm__Configuration_Item__r.name'} )) {
            	       relationShipList = [SELECT Id,citsm__Configuration_Item_Formula__c,citsm__Related_Configuration_Item__r.name,citsm__Related_Configuration_Item__c,Name,citsm__Relationship__c,citsm__Configuration_Item__c,Configuration_Item__r.name FROM citsm__Configuration_Item_Relationship__c WHERE citsm__Configuration_Item__c =:conId  LIMIT 50000];
            }
                            
            if(relationShipList.size() > 0){
                ciVisualInfo.name = relationShipList[0].citsm__Configuration_Item__r.Name;
                ciVisualInfo.id = relationShipList[0].citsm__Configuration_Item__c;
            }else{
                
                Configuration_Item__c config = new Configuration_Item__c();
                
                if(AccessCheck.isAuthorizedToView(Schema.Configuration_Item__c.getSObjectType(), null,new List<String>{'Name'})){
                    config = [SELECT Id,Name FROM Configuration_Item__c WHERE Id=:conId];
                    ciVisualInfo.name = config.Name;
                    ciVisualInfo.id = config.Id;
                }
            }

            for(Configuration_Item_Relationship__c item : relationShipList){
                
                CIVisualItem nodeInfo = new CIVisualItem();
                nodeInfo.name = item.Related_Configuration_Item__r.name;
                nodeInfo.relation = item.Relationship__c;
                nodeInfo.id = item.Related_Configuration_Item__c;
                nodeInfo.isClicked = false;
                childNodeList.add(nodeInfo);
            }
            
            ciVisualInfo.children = childNodeList;
            ciVisualInfo.isClicked = false;

            return JSON.serialize(ciVisualInfo);

        }catch(Exception e){
            throw new AurahandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String getRelatedTabsInfo(){
        
        try{
            
        List<TabInfo> configTabList =new List<TabInfo>();
		citsm__Cadalys_Service_Management_Setting__mdt[] cmdRecordsList;
            
		if(AccessCheck.isAuthorizedToView(Schema.citsm__Cadalys_Service_Management_Setting__mdt.getSObjectType(), null,new List<String>{'DeveloperName','MasterLabel','citsm__Value__c'})){
			 cmdRecordsList = [SELECT DeveloperName,MasterLabel,citsm__value__c FROM citsm__Cadalys_Service_Management_Setting__mdt  LIMIT 50000];
        }
        
		Set<String> changeStatusSet = new Set<String>();

		List<String> incidentRecordTypeSet = new List<String>();

		List<String> problemRecordTypeSet = new List<String>();

        for(citsm__Cadalys_Service_Management_Setting__mdt csmSetting : cmdRecordsList) {
            if(csmSetting.developerName == 'Incident_Record_Types'){
                
                if(csmSetting.citsm__value__c != null){
                    if(csmSetting.citsm__value__c.contains(';')){
                        List<String> recTypeValues = csmSetting.citsm__value__c.split(';');
                        incidentRecordTypeSet = recTypeValues;
                    }else{
                        incidentRecordTypeSet.add(csmSetting.citsm__value__c);
                    }
                }
            }
            
            if(csmSetting.developerName == 'Problem_Record_Types'){
                        
                if(csmSetting.citsm__value__c != null){
                    if(csmSetting.citsm__value__c.contains(';')){
                        List<String> recTypeValues = csmSetting.citsm__value__c.split(';');
                        problemRecordTypeSet = recTypeValues;
                    }else{
                        problemRecordTypeSet.add(csmSetting.citsm__value__c);
                    }
                }
            }
        }       
          
        // Directly hard code the object name, fieldset names 

		List<recordType> incidentRecordTypeList = new List<recordType>();
		if(incidentRecordTypeSet.size() > 0){
            
            if(AccessCheck.isAuthorizedToView(Schema.RecordType.getSObjectType(), null,new List<String>{'DeveloperName','Name','SobjectType'})){
				incidentRecordTypeList = [SELECT Id,Name,DeveloperName,SobjectType FROM RecordType WHERE developername IN:incidentRecordTypeSet AND SobjectType = 'Case'  LIMIT 50000 ];
        	}
            
		}    
        
        String incidentFields = getFieldSet('Case','citsm__Incident_Visualization');
        List<String> incidentFieldNames = new List<String>();
        incidentFieldNames = getFields(incidentFields);
        TabInfo config = new TabInfo();
        config.fieldSet = incidentFields;
        config.fields = String.join(incidentFieldNames,',');
        config.blockName = 'Incident';
        config.objectName = 'Case';
		config.recordTypeInfo = JSON.serialize(incidentRecordTypeList);
        config.recordTypeFilterStr = JSON.serialize(incidentRecordTypeSet);
        configTabList.add(config);
        List<recordType> problemRecordTypeList = new List<recordType>();
         
        if(problemRecordTypeSet.size() > 0){
             if(AccessCheck.isAuthorizedToView(Schema.RecordType.getSObjectType(), null,new List<String>{'DeveloperName','Name','SobjectType'})){
				problemRecordTypeList = [SELECT Id,Name,DeveloperName,SobjectType FROM RecordType WHERE developername IN:problemRecordTypeSet AND SobjectType = 'Case'  LIMIT 50000 ];
        	}
		}
            
            
        String problemFields = getFieldSet('Case','citsm__Problem_Visualization');
        List<String> problemFieldNames = new List<String>();
        problemFieldNames = getFields(problemFields);
        TabInfo configProblem = new TabInfo();
        configProblem.fieldSet = problemFields;
        configProblem.fields = String.join(problemFieldNames,',');
        configProblem.blockName = 'Problem';
        configProblem.objectName = 'Case';
		configProblem.recordTypeInfo = JSON.serialize(problemRecordTypeList);
        configProblem.recordTypeFilterStr = JSON.serialize(problemRecordTypeSet);
        configTabList.add(configProblem);
        
        String changeFields = getFieldSet('citsm__CI_Change__c','citsm__Visualization_Related_List');
        List<String> changeFieldNames = new List<String>();
        changeFieldNames = getFields(changeFields);
        TabInfo configChange = new TabInfo();
        configChange.fieldSet = changeFields;
        configChange.fields = String.join(changeFieldNames,',');
        configChange.blockName = 'Change';
        configChange.objectName = 'citsm__CI_Change__c';
        configTabList.add(configChange);
            
        String attributeFields = getFieldSet('citsm__Configuration_Item_Attribute__c','citsm__Attribute_Visualization');
        List<String> attributeFieldNames = new List<String>();
        attributeFieldNames = getFields(attributeFields);
        TabInfo configAttribute = new TabInfo();
        configAttribute.fieldSet = attributeFields;
        configAttribute.fields = String.join(attributeFieldNames,',');
        configAttribute.blockName = 'Attribute';
        configAttribute.objectName = 'citsm__Configuration_Item_Attribute__c';
        configTabList.add(configAttribute);
       
        return JSON.serialize(configTabList);
		}catch(Exception e){
            throw new AurahandledException(e.getMessage());
        }
    }
    
    public static List<String> getFields(String fields){
        List<fieldValues> fieldsList =  (List<fieldValues>)System.JSON.deserialize(fields, List<fieldValues>.class);
        Set<String> fieldNamesSet = new Set<String>();
        for (Integer c = 0, clang = fieldsList.size(); c < clang; c++) {
            if (!fieldNamesSet.contains(fieldsList[c].fieldName)) {
                fieldNamesSet.add(fieldsList[c].fieldName);
                if (fieldsList[c].type == 'REFERENCE') {
                    if (fieldsList[c].fieldName.indexOf('__c') == -1) {
                        fieldNamesSet.add(fieldsList[c].fieldName.substring(0, fieldsList[c].fieldName.indexOf('Id')) + '.Name');
                    } else {
                        fieldNamesSet.add(fieldsList[c].fieldName.substring(0, fieldsList[c].fieldName.indexOf('__c')) + '__r.Name');
                    }
                }
            } 
        }
        List<String> fieldNamesList = new List<String>();
        fieldNamesList.addAll(fieldNamesSet);
        return fieldNamesList;
    }
    
	public static String getFieldSet(String sObjectName, String fieldSetName) {
        String result = '';
        try{
            SObjectType objToken = Schema.getGlobalDescribe().get(sObjectName);
            Schema.DescribeSObjectResult describeResult = objToken.getDescribe();
            Map<String, Schema.FieldSet> FieldSetsMap = describeResult.fieldSets.getMap();
            if(FieldSetsMap.containsKey(fieldSetName))
                for(Schema.FieldSetMember f : FieldSetsMap.get(fieldSetName).getFields()) {
                    if(result != ''){
                        result += ',';
                    }
                    String jsonPart = '{';
                    jsonPart += '"label":"' + f.getLabel() + '",';
                    jsonPart += '"required":"' + (f.getDBRequired() || f.getRequired()) + '",';
                    if (String.valueof(f.getType()) == 'REFERENCE') {
                        String fieldName = String.valueOf(f.getFieldPath());
                            jsonPart += '"objName":"' + CIVisualizationController.getParentObjectName(sObjectName,fieldName) + '",';
                } 
                    jsonPart += '"type":"' + (f.getType()) + '",';
                    jsonPart += '"fieldName":"' + f.getFieldPath() + '"';
                    jsonPart += '}';
                    result += jsonPart; 
            }
        }
        catch(Exception e){
            result += e.getLineNumber() + ' : ' + e.getMessage();
        }
        return '['+result+']';
    }

    
    public static String getParentObjectName(String objectName , String fieldName){
        
        
        DescribeSObjectResult objResult = Schema.getGlobalDescribe().get(objectName).getDescribe();
        
        // Get the field dynamically
        DescribeFieldResult fieldResult = objResult.fields.getMap().get(fieldName).getDescribe();
                
        String parentObject;
        
        for(Schema.SObjectType reference : fieldResult.getReferenceTo()) {
             parentObject = String.valueOf(reference.getDescribe().getName());
        }
        return parentObject;
    }
    
    @AuraEnabled
    public static String getItemNotifierCount(String configItem){
        Integer incidentCnt = 0;
        Integer  problemCnt = 0;
        Integer  ChangeCount = 0;
        if(configItem != null && configItem !=''){
            
            List<Case> caseList = [SELECT Id,recordtype.developername FROM Case WHERE citsm__Configuration_Item__c =:configItem  LIMIT 50000 ];
            
            for(case rec : caseList){
                if(rec.recordtype.Developername =='Incident'){
                    incidentCnt = incidentCnt + 1;
                }else if(rec.recordtype.Developername =='Problem'){
                    problemCnt = problemCnt+1;
                }
            }
            ChangeCount = Database.countQuery('SELECT count() FROM citsm__CI_Change__c WHERE citsm__Configuration_Item__c=: configItem AND citsm__Planned_Start_Date_Time__c > TODAY LIMIT 50000');
        }
        string countStr = '<p style="margin-top:3px">Incident = '+String.valueof(incidentCnt)+' <br/> Problem = '+String.valueOf(problemCnt)+'<br/>Change = '+String.valueOf(ChangeCount)+'</p>';
		return countStr;
    }
    
    
    public class CIVisual{
        @AuraEnabled
        public list<CIVisualItem> children {get;set;}
        @AuraEnabled
        public string name {get;set;}
        @AuraEnabled
        public String id{get;set;}   
        @AuraEnabled
        public Boolean isClicked {get;set;}     
    }
    
    public class CIVisualItem{
        @AuraEnabled
        public  String name {get;set;}
        @AuraEnabled
        public  String relation {get;set;}
        @AuraEnabled
        public  Id id {get;set;}
        @AuraEnabled
        public Boolean isClicked {get;set;}
        
    }
    public class fieldValues{
        @AuraEnabled
        public String fieldName {get;set;}
        @AuraEnabled
        public String  typeAttributes{get;set;}
        @AuraEnabled
        public String required {get;set;}
        @AuraEnabled
        public String type {get;set;}
        @AuraEnabled
        public String label {get;set;}
    }
    
    public class TabInfo{
        @AuraEnabled
        public String fieldSet {get;set;}
         @AuraEnabled
        public String tableRows {get;set;}
        @AuraEnabled
        public String fields {get;set;}
        @AuraEnabled
        public String blockName {get;set;}
        @AuraEnabled
        public String objectName {get;set;}
        @AuraEnabled
        public String recordTypeInfo {get;set;}
        @AuraEnabled
        public String recordTypeFilterStr {get;set;}
    }
}
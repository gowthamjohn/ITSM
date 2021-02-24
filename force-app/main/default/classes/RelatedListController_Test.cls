@IsTest
public class RelatedListController_Test {
    @testSetup static void methodName() {
        
        Configuration_Item_Class__c itemClass = new Configuration_Item_Class__c();
        itemClass.Code__c = 'code';
        itemClass.Name = 'class';
        Insert itemClass;
        
        Configuration_Item__c config = new Configuration_Item__c();
        config.Name = 'Item1';
        config.Configuration_Item_Class__c = itemClass.Id;
        Insert config;
        
        Configuration_Item__c config1 = new Configuration_Item__c();
        config1.Name = 'Item';
        config1.Configuration_Item_Class__c = itemClass.Id;
        Insert config1;
        
        Configuration_Item_Relationship__c relation = new Configuration_Item_Relationship__c();
        relation.Related_Configuration_Item__c = config.Id;
        relation.Configuration_Item__c = config.Id;
        relation.Relationship__c = 'manages';
        Insert relation;
        
        Change__c change = new Change__c();
        change.Category__c = 'Operating System	';
        change.Status__c = 'Approved';
        change.Actual_End_Date_Time__c = System.now();
        Insert change;
        
        CI_Change__c ciChange = new CI_Change__c();
        ciChange.Configuration_Item__c = config.id;
        ciChange.Change__c =  change.Id;
        Insert ciChange;
        
    }
    
    public static testMethod void testMethod1(){
        Configuration_Item_Relationship__c item = [SELECT Id from Configuration_Item_Relationship__c limit 1];
        RelatedListController.getIconName('Account');
        RelatedListController.deleteRecord(item.Id);
    }
    public static testMethod void testMethod2(){
       
            List<String> recordTypeList = new List<String>{'Incident','Problem'};
            Configuration_Item__c item = [SELECT Id from Configuration_Item__c limit 1];
            recWrap recInfo = new recWrap();
            recInfo.fields = 'Id,owner.name,citsm__Configuration_Item__c';
            recInfo.recordId = item.Id;
            recInfo.recordTypeFilter = JSON.serialize(recordTypeList);
            recInfo.numberOfRecords = 3;
            recInfo.sobjectApiName = 'Case';
            recInfo.sortedBy = 'CaseNumber';
            recInfo.sortedDirection = 'ASC';
            recInfo.relatedFieldApiName = 'citsm__Configuration_Item__c';
            String responseStr = RelatedListController.initData(JSON.serialize(recInfo));
            Map<String,object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseStr);
            System.assertEquals(responseMap.get('sobjectLabel'), 'Case');
            
            recInfo.sobjectApiName = 'citsm__CI_Change__c';
            recInfo.sortedBy = 'LastModifiedDate';
            recInfo.recordTypeFilter = null;
            recInfo.fields = 'Id,citsm__Change__c,citsm__Configuration_Item__c';
            
            String responseStr1 = RelatedListController.initData(JSON.serialize(recInfo));
            Map<String,object> responseMap1 = (Map<String, Object>) JSON.deserializeUntyped(responseStr1);
            System.assertEquals(responseMap1.get('sobjectLabel'), 'CI Change');
        
    }
    
    public class recWrap{
        public string fields{get;set;}
        public string recordId{get;set;}
        public String recordTypeFilter {get;set;}
        public Integer numberOfRecords{get;set;}
        public string sobjectApiName{get;set;}
        public string sortedBy{get;set;}
        public string sortedDirection{get;set;}
        public string relatedFieldApiName{get;set;}
    }
    
}
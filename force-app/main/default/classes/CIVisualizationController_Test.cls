@IsTest
public class CIVisualizationController_Test {
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
        
        
        Configuration_Item_Class_Attribute__c classAttribute = new Configuration_Item_Class_Attribute__c();
        classAttribute.Configuration_Item_Class__c = itemClass.Id;
        classAttribute.Name = 'Name';
        classAttribute.Parameter_Type__c = 'Text';
        Insert classAttribute;
        
        Configuration_Item_Attribute__c attribute = new Configuration_Item_Attribute__c();
        attribute.Configuration_Item__c = config.Id;
        attribute.Configuration_Item_Class_Attribute__c = classAttribute.Id;
        attribute.Value__c = 'value';
        attribute.Value__c = 'name';
        Insert attribute;
        
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
        List<Configuration_Item__c> relation = [SELECT Id from Configuration_Item__c];
        String jasonStr = CIVisualizationController.getRelatedInfoofCI(relation[0].Id);
        String countStr = CIVisualizationController.getItemNotifierCount(relation[0].Id);
        CIVisualizationController.CIVisual treeWrapper = (CIVisualizationController.CIVisual)System.JSON.deserialize(jasonStr, CIVisualizationController.CIVisual.class);
        system.assertEquals(treeWrapper.name ,'Item1');
        CIVisualizationController.getRelatedInfoofCI(relation[1].Id);
    }
    
    public static testMethod void testMethod2(){
        
        String relatedStr = CIVisualizationController.getRelatedTabsInfo();
		List<CIVisualizationController.TabInfo> treeWrapper = (List<CIVisualizationController.TabInfo>)System.JSON.deserialize(relatedStr, List<CIVisualizationController.TabInfo>.class);
        system.assertEquals(treeWrapper.size(),4);
    }
    
    
}
/**
 *  @date 15 May 2015
 *  @author Tushar Kumawat
 *  @description Calendar DTO
 */

public with sharing class CalendarDTO {
    /**
     *  @purpose wrapper class for the Objects (Standard and Custom)
     */
    public class SObjectWrapper implements Comparable {
        public SObjectWrapper(Schema.DescribeSobjectResult sObjData) {
            this.strName = sObjData.getLabel();
            this.strApi = sObjData.getName();
            this.sObjType = sObjData.getSObjectType();
            
            if(sObjData.getName().contains('__c')) {
                this.strType = 'Custom';    
            }
            else {
                this.strType = 'Standard';
            }
        }
        
        public String strName {get; set;}
        public String strApi {get; set;}
        public String strType {get; set;}
        public transient SObjectType sObjType {get; set;}
        
        public Integer compareTo(Object compareTo) {
            SObjectWrapper compareToObj = (SObjectWrapper)compareTo;
            
            if(strName == compareToObj.strName) {
                return 0;
            }
            
            if(strName > compareToObj.strName) {
                return 1;
            }
            
            return -1;
        }
    }
    
    /**
     *  @purpose wrapper class for the Fields of selected SObject
     */
    public class SObjectFieldWrapper {
        public SObjectFieldWrapper() {}
        public SObjectFieldWrapper(Schema.describeFieldResult fieldData) {
            this.strName = fieldData.getLabel();
            this.strApi = fieldData.getName();
            this.strType = fieldData.getType().name();
            this.doShow = fieldData.isAccessible();//!fieldData.isCalculated() && fieldData.isCreateable();
            this.isCreatable = fieldData.isCreateable();
            this.isFilterable = fieldData.isFilterable();
            this.isUpdateable = fieldData.isUpdateable();
            List<Schema.PicklistEntry> values = fieldData.getPicklistValues();
            this.availableOptions = new List<CustomSelectOptions>();
            for (Schema.PicklistEntry entry : values) {
                this.availableOptions.add(new CustomSelectOptions(entry.getValue(), entry.getLabel()));
            }
            
            if(this.strType.toUpperCase() == 'REFERENCE') {
                this.strRelationship = fieldData.getRelationshipName() + '.Name';
            }
            
            if(this.strName.toUpperCase().endsWith(' ID')) {
                this.strName = this.strName.left(this.strName.length() - 3);
            }
            
            if(fieldData.isNillable()) {
                this.isRequired = false;
            }
            else {
                this.isRequired = true;
            }
        }
        @AuraEnabled
        public List<CustomSelectOptions> availableOptions {get; set;}
        @AuraEnabled
        public Boolean isUpdateable {get; set;}
        @AuraEnabled
        public Boolean isFilterable {get; set;}
        @AuraEnabled
        public Boolean isCreatable {get; set;}
        @AuraEnabled
        public String strName {get; set;}
        @AuraEnabled
        public String strApi {get; set;}
        @AuraEnabled
        public String strType {get; set;}
        @AuraEnabled
        public String strRelationship {get; set;}
        @AuraEnabled
        public Boolean isRequired {get; set;}
        @AuraEnabled
        public Boolean isSelected {get; set;}
        @AuraEnabled
        public Boolean doShow {get; set;}
    }

    public class CustomSelectOptions{
        @AuraEnabled public String label {get;set;}
        @AuraEnabled public String value {get;set;}

        public CustomSelectOptions() {
            this.label = '';
            this.value = '';
        }

        public CustomSelectOptions(String lab, String val) {
            this.label = lab;
            this.value = val;
        }
    }

    /**
     *  @purpose wrapper class for Calender and Series SObject
     */
    public class CalenderSettingWrapper {
        public Cadalys_Calendar__c lightningCalender {get; set;}
        public List<Series__c> listSeries {get; set;}
    }

    /**
     *  @purpose wrapper class for Calender objects
     */
    public class CalenderWrapper {
        public Long TimeZone {get; set;}
        public List<CalenderObjectWrapper> Objects {get; set;}
    }

    /**
     *  @purpose wrapper class for Calender series
     */
    public class CalenderSeriesWrapper {
        public String SeriesName {get; set;}
        public List<FieldValueWrapper> CreateFields {get; set;}
    }

    /**
     *  @purpose wrapper class for Calender objects
     */
    public class CalenderObjectWrapper {
        @AuraEnabled
        public String ObjectApi {get; set;}
        public String recordTypeList {get; set;}
        public String Type {get; set;}
        public String Color {get; set;}
        // public List<CalenderSeriesWrapper> Series {get; set;}
        public List<CalenderRecordWrapper> Records {get; set;}
        public String SeriesId {get; set;}
        public String SeriesName {get; set;}
        public List<FieldValueWrapper> CreateFields {get; set;}
        public Boolean isEditable {get; set;}
        public List<SearchWrapper> recordTypesList {get; set;}


        public CalenderObjectWrapper() {}
        public CalenderObjectWrapper(String SeriesId, String SeriesName, Boolean isEditable, String ObjectApi, String Color, String Type) {
            this.Records = new List<CalendarDTO.CalenderRecordWrapper>();
            this.CreateFields = new List<CalendarDTO.FieldValueWrapper>();
            this.SeriesId = SeriesId;
            this.SeriesName = SeriesName;
            this.isEditable = isEditable;
            this.ObjectApi = ObjectApi;
            this.Color = String.isNotBlank(Color) ? '#' + Color : null;
            this.Type = Type;
            this.recordTypesList = gerRecordTypesList(objectApi);
        }
        private List<SearchWrapper> gerRecordTypesList(String objectApiName) {
            List<SearchWrapper> recordTypesList = new List<SearchWrapper>();
            Map<Id,Schema.RecordTypeInfo> rtAccountByIdMap = Schema.describeSObjects(new String[]{objectApiName})[0].getRecordTypeInfosById();
            for(Id item : rtAccountByIdMap.keySet()) {
                RecordTypeInfo rt = rtAccountByIdMap.get(item);
                if(rt.isAvailable()) {
                    SearchWrapper sw = new SearchWrapper();
                    sw.Id = item;
                    sw.Name = rt.getName();
                    recordTypesList.add(sw);
                }
            }
            return recordTypesList;
        }
    }

    /**
     *  @purpose wrapper class for Calender records
     */
    public class CalenderRecordWrapper {
        public String Id {get; set;}
        public String Name {get; set;}
        public DateTime StartDate {get; set;}
        public DateTime EndDate {get; set;}
        public List<FieldValueWrapper> Fields {get; set;}
        
        public CalenderRecordWrapper(String EventId, String EventName, DateTime EventStart, DateTime EventEnd, List<FieldValueWrapper> Fields) {
            this.Id = EventId;
            this.Name = EventName;
            this.StartDate = EventStart;
            this.EndDate = EventEnd == null? EventStart : EventEnd;
            this.Fields = Fields;
        }
    }
    
    /**
     *  @purpose wrapper class for Series record
     */
    public class SeriesWrapper {
        @AuraEnabled
        public String strId {get; set;}
        @AuraEnabled
        public String strName {get; set;}
        //public String strAdvancedFilter {get; set;}
        @AuraEnabled
        public String strDescription {get; set;}
        @AuraEnabled
        public String strEntryEnd {get; set;}
        @AuraEnabled
        public String strEntryName {get; set;}
        @AuraEnabled
        public String strEntryStart {get; set;}
        @AuraEnabled
        public String strDetailFields {get; set;}
        @AuraEnabled
        public String strCreateFields {get; set;}
        @AuraEnabled
        public String strObjectName {get; set;}
        @AuraEnabled
        public Boolean isEditable {get; set;}
        @AuraEnabled
        public Boolean isFilterByOwner {get; set;}
        @AuraEnabled
        public Boolean isVisible {get; set;}
        @AuraEnabled
        public String color {get; set;}
        @AuraEnabled
        public String filterLogic {get;set;}

        public SeriesWrapper() {}
        public SeriesWrapper(Map<String, Object> series) {
            series = series != null ? series : new Map<String, Object>();
            strId = (String)series.get('strId');
            strName = (String)series.get('strName');
            strDescription = (String)series.get('strDescription');
            strEntryEnd = (String)series.get('strEntryEnd');
            strEntryName = (String)series.get('strEntryName');
            strEntryStart = (String)series.get('strEntryStart');
            strDetailFields = (String)series.get('strDetailFields');
            strCreateFields = (String)series.get('strCreateFields');
            strObjectName = (String)series.get('strObjectName');
            color = (String)series.get('color');
            filterLogic = (String)series.get('filterLogic');
            isEditable = (Boolean)series.get('isEditable');
            isFilterByOwner = (Boolean)series.get('isFilterByOwner');
            isVisible = (Boolean)series.get('isVisible');
        }
        public SeriesWrapper(Series__c series) {
            strId = series.Id;
            strName = series.Name;
           //strAdvancedFilter = series.Advanced_Filter_Rule__c;
            strDescription = series.Description__c;
            strEntryEnd = series.Item_End__c;
            strEntryName = series.Field_Displayed_on_Calendar_Entry__c;
            strEntryStart = series.Item_Start__c;
            strDetailFields = series.Fields_to_Display_on_Detail__c;
            strCreateFields = series.Fields_to_Display_on_Create_Edit__c;
            strObjectName = series.Object_Name__c;
            isEditable = series.IsEditable__c;
            isFilterByOwner = series.Filter_by_Owner__c;
            isVisible = series.IsVisible__c;
            color = series.Color__c;
            filterLogic = series.Filter_Logic__c;
        }
    }
    
    /**
     *  @purpose wrapper class calendar
     */
    public class CalendarInfoWrapper {
        public List<CalendarWrapper> Calendars {get; set;}
    }
    
    /**
     *  @purpose wrapper class calendar
     */
    public class CalendarWrapper {
        public String Name {get; set;}
        public String Id {get; set;}
        
        public CalendarWrapper(String Id, String Name) {
            this.Id = Id;
            this.Name = Name;
        }
    }
    
    /**
     *  @purpose wrapper class for Field Value
     */
    public class FieldValueWrapper {
        public String Field {get; set;}
        public String RelationObject {get; set;}
        public String FieldAPI {get; set;}
        public String Data {get; set;}
        public String TextData {get; set;}
        public String FieldType {get; set;}
        public Boolean Disable {get; set;}
        public String disableStatus {get; set;}
        public Boolean Required {get; set;}
        public List<String> PicklistValues {get; set;}
        
        public FieldValueWrapper(String Field, String FieldAPI, Object Data, String TextData, String FieldType, Boolean Disable, String RelationObject, Boolean Required, List<String> PicklistValues) {
            this.TextData = TextData;
            setAllFields(Field, FieldAPI, Data, FieldType, Disable, RelationObject, Required, PicklistValues);
        }

        public FieldValueWrapper(String Field, String FieldAPI, Object Data, String FieldType, Boolean Disable, String RelationObject, Boolean Required, List<String> PicklistValues) {
            setAllFields(Field, FieldAPI, Data, FieldType, Disable, RelationObject, Required, PicklistValues);
        }

        private void setAllFields(String Field, String FieldAPI, Object Data, String FieldType, Boolean Disable, String RelationObject, Boolean Required, List<String> PicklistValues) {
            this.Field = Field;
            this.FieldAPI = FieldAPI;
            this.Data = serrializeFieldValue(Data, FieldType);
            this.FieldType = FieldType;
            this.Disable = Disable;
            this.disableStatus = '';
            if (Disable){
                this.disableStatus = 'disabled';
            }
            this.Required = Required;
            this.PicklistValues = PicklistValues;
            this.RelationObject = RelationObject;
        }
    }
    private static String serrializeFieldValue(Object valueObj, String fieldType) {
        if(fieldType == 'DATETIME' || fieldType == 'DATE' || fieldType == 'TIME') {
            try {
                DateTime valueDt = DateTime.valueOf(valueObj);
                return valueDt.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
            }
            catch(Exception e) {
                return String.valueOf(valueObj);
            }
        }
        else {
            return String.valueOf(valueObj);
        }

    }
    /**
     *  @purpose wrapper class for Field Value
     */
    public class FieldValueWrapper1 {
        public String Field {get; set;}
        public String FieldAPI {get; set;}
        public String Data {get; set;}
        public String FieldType {get; set;}
        public Boolean Disable {get; set;}
        
        public FieldValueWrapper1(String Field, String FieldAPI, String Data, String FieldType, Boolean Disable) {
            this.Field = Field;
            this.FieldAPI = FieldAPI;
            this.Data = Data;
            this.FieldType = FieldType;
            this.Disable = Disable;
        }
    }
    
    /**
     *  @purpose wrapper class calendar
     */
    public class InputWrapper {
        public String ObjectApi {get; set;}
        public List<FieldValueWrapper1> CreateFields {get; set;}
    }
    
    /**
     *  @purpose wrapper class calendar
     */
    public class MessageWrapper {
        public String Message {get; set;}
        public Boolean IsSuccess {get; set;}
        public String Id {get; set;}
    }
    
    /**
     *  @purpose wrapper class calendar
     */
    public class SearchWrapper {
        public String Id {get; set;}
        public String Name {get; set;}

        public SearchWrapper() {}
        public SearchWrapper(sObject sObj) {
            this.Id = (String) sObj.get('Id');
            this.Name = (String) sObj.get('Name');
        }
    }
}
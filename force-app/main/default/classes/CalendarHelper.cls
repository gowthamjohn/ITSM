/**
 *  @date 15 May 2015
 *  @author Tushar Kumawat
 *  @description Calander Helper
 */

public with sharing class CalendarHelper {

    private final static Set<String> textTypeSet {get {
        return new Set<String>{
                'REFERENCE',
                'STRING',
                'EMAIL',
                'PICKLIST',
                'COMBOBOX',
                'ID',
                'PHONE',
                'URL'
        };}set;}

    public final static String orgPrefix {get {
        return getNamespacePrefix();
    } set;}
    
    /**
     *  @description insert series coming
     
    public static void upsertSeries(CalendarDTO.CalenderSettingWrapper calenderSetting) {
        try {
        }
        catch(Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
        }
    }
    */
    /**
     *  @description search calender settings for incoming ID
     
    public static CalendarDTO.CalenderSettingWrapper getCalender(Id idCalender) {
        CalendarDTO.CalenderSettingWrapper calenderSetting = new CalendarDTO.CalenderSettingWrapper();
        
        try {
        }
        catch(Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
        }
        
        return calenderSetting;
    }
    */
    /**
     *  @description get all Calenders
     */
    public static CalendarDTO.CalendarInfoWrapper getAllCalenders() {
        
        CalendarDTO.CalendarInfoWrapper calWrapper = new CalendarDTO.CalendarInfoWrapper();
        calWrapper.Calendars = new List<CalendarDTO.CalendarWrapper>();
        List<String> listFields = new List<String>{'Id', 'Name'};
        listFields.addAll(getApiNameWithOrgPrefixList(new List<String> {'Available_For_Use__c', 'Description__c'}));
        Map<String,Schema.DescribeFieldResult> mapSObjectFieldDesc = getSchemaObjectFieldsMap(Schema.SObjectType.Cadalys_Calendar__c);
        for(String strField : listFields) {
            if(mapSObjectFieldDesc.containsKey(strField)) {
                if(!mapSObjectFieldDesc.get(strField).isAccessible()) {
                   throw new System.NoAccessException();
           //        return null;
                }
            }
        }
        List<Cadalys_Calendar__c> listOfLightningCalendar;
        String query = 'SELECT Id, Name FROM ' + getApiNameWithOrgPrefix('Cadalys_Calendar__c') + ' WHERE ' + getApiNameWithOrgPrefix('Available_For_Use__c') + ' = TRUE';
        if (AccessCheck.isAuthorizedToView(Schema.Cadalys_Calendar__c.getSObjectType(), query, null)) {
            listOfLightningCalendar = Database.query(query);
        }
        for(Cadalys_Calendar__c calendar : listOfLightningCalendar) {
            calWrapper.Calendars.add(new CalendarDTO.CalendarWrapper(calendar.Id, calendar.Name));
        }

        return calWrapper;
    }
    private static Map<Id, Calendar_Series__c> getMapCalendarSeriesByCalendarId(Id idCalender) {
        Map<Id, Calendar_Series__c> mapCalendarSeries = new Map<Id, Calendar_Series__c>();
        List<Calendar_Series__c> listOfCalendarSeries;
        if (AccessCheck.isAuthorizedToView(Schema.Calendar_Series__c.getSObjectType(), null, getApiNameWithOrgPrefixList(new List<String>{'Series__c', 'Cadalys_Calendar__c'})) &&
            AccessCheck.isAuthorizedToView(Schema.Series__c.getSObjectType(), null, getApiNameWithOrgPrefixList(new List<String>{'Color__c'}))) {
                listOfCalendarSeries = [SELECT Series__c, Series__r.Color__c FROM Calendar_Series__c WHERE Cadalys_Calendar__c =: idCalender];
            }
        for(Calendar_Series__c calSeries : listOfCalendarSeries) {
            mapCalendarSeries.put(calSeries.Series__c, calSeries);
        }
        return mapCalendarSeries;
    }
    private static Map<String, Schema.DescribeSObjectResult> getObjectDescribe(List<Series__c> allListSeries) {
        Map<String, Schema.DescribeSObjectResult> descriptionObjectMap = new Map<String, Schema.DescribeSObjectResult>();
        Map<String, List<Series__c>> allObjectNameSeriesMap = new Map<String, List<Series__c>>();
        for(Series__c item : allListSeries) {
            if(!descriptionObjectMap.containsKey(item.Object_Name__c)) {
                SObjectType sType = Type.forName('Schema.' + item.Object_Name__c) != null ?
                        ((SObject)(Type.forName('Schema.' + item.Object_Name__c).newInstance())).getSObjectType() : null;
                if (sType != null) {
                    descriptionObjectMap.put(item.Object_Name__c, sType.getDescribe());
                }
            }
        }
        return descriptionObjectMap;
    }
    private static List<Series__c> getListSeriesBySetId(Set<Id> seriesIds) {
        List<Series__c> listSeries = new List<Series__c>();
        if (AccessCheck.isAuthorizedToView(Schema.Series__c.getSObjectType(), null, getApiNameWithOrgPrefixList(new List<String>{ 'Id', 'Name', 'Object_Name__c', 'Item_Start__c', 'Item_End__c', 'Fields_to_Display_on_Detail__c', 'Advanced_Filter_Rule__c', 'Filter_by_Owner__c', 'Fields_to_Display_on_Create_Edit__c'})) &&
                AccessCheck.isAuthorizedToView(Schema.Series_Filter_Criterion__c.getSObjectType(),  null, getApiNameWithOrgPrefixList(new List<String>{ 'Id', 'Field_Name__c', 'Index__c', 'Operator__c', 'Value__c'}))) {
            listSeries = [
                    SELECT
                            Id,
                            Name,
                            Object_Name__c,
                            Item_Start__c,
                            Item_End__c,
                            Fields_to_Display_on_Detail__c,
                            Advanced_Filter_Rule__c,
                            Filter_by_Owner__c,
                            Fields_to_Display_on_Create_Edit__c,
                            IsVisible__c,
                            IsEditable__c,
                            Filter_Logic__c,
                    (
                            SELECT
                                    Id,
                                    Field_Name__c,
                                    Index__c,
                                    Operator__c,
                                    Value__c
                            FROM        Filter_Criteria__r
                            ORDER BY    Index__c ASC
                    )
                    FROM    Series__c
                    WHERE   Id IN : seriesIds AND
                            IsVisible__c = true
            ];
        }
        return listSeries;
    }
    private static void setCreateFields(Set<String> setCreateFields, Map<String, Schema.DescribeFieldResult> mapSobjectFields, Series__c series, List<CalendarDTO.FieldValueWrapper> createFields) {
        Schema.DescribeFieldResult dfield;
        for(String strField : setCreateFields) {
            if(mapSobjectFields.containsKey(strField)) {
                List<String> listPicklistEntry = new List<String>();
                String relationObj;


                dfield = mapSobjectFields.get(strField);
                String label = dfield.getLabel();
                if(dfield.getType().name().equalsIgnoreCase('PICKLIST')) {
                    for(Schema.PicklistEntry picklistEntry : dfield.getPicklistValues()) {
                        if(picklistEntry.isActive()) {
                            listPicklistEntry.add(picklistEntry.getValue());
                        }
                    }
                }

                if(dfield.getType().name().equalsIgnoreCase('REFERENCE')) {
                    List<Schema.sObjectType> listsObjectType = dfield.getReferenceTo();
                    if(listsObjectType.size() > 0) {
                        relationObj = listsObjectType[0].getDescribe().getName();
                    }
                    label = label.contains(' ID') ? label.substringBefore(' ID') : label;
                }

                Boolean requiredField = !dfield.isNillable();
                if (strField == series.Item_End__c || strField == series.Item_Start__c){
                    requiredField = true;
                }
                if (dfield.isAccessible() && dfield.isCreateable()){
                    createFields.add(new CalendarDTO.FieldValueWrapper(label, strField, '', dfield.getType().name(), (dfield.isCreateable() && dfield.isUpdateable()), relationObj, requiredField, listPicklistEntry));
                }
            }
        }
    }
    private static String setDetailFields(Set<String> setDetailFields, String strQuery, Map<String, Schema.DescribeFieldResult> mapSobjectFields, Map<String,String> mapOfReferenceNames) {
        for(String strField : setDetailFields) {
            if(!strQuery.contains(' ' + strField + ',') && !strQuery.contains(' ' + strField + ' ')) {
                Schema.DescribeFieldResult dfield = mapSobjectFields.get(strField);
                if (mapSobjectFields.containsKey(strField) && dfield.isAccessible()) {
                    if (dfield.getType().name() == 'REFERENCE') {
                        String newFieldStr;
                        if (strField.endsWith('__c')) {
                            newFieldStr = strField.removeEndIgnoreCase('c') + 'r.Name';
                        } else {
                            newFieldStr = strField.removeEndIgnoreCase('id') + '.Name';
                        }
                        strQuery += ', ' + newFieldStr;
                        mapOfReferenceNames.put(strField,newFieldStr);
                    } else{
                        strQuery += ', ' + strField;
                    }
                } else {
                    setDetailFields.remove(strField);
                }
            }
        }
        return strQuery;
    }
    private static String removeDublicateFields(String strQuery) {
        Set<String> uniqFieldsSet = new Set<String> (strQuery.removeStartIgnoreCase('SELECT').trim().split(','));
        strQuery = 'SELECT ';
        for (String field : uniqFieldsSet) {
            strQuery += field + ',';
        }
        return strQuery.removeEnd(',') + ' ';
    }
    private static String getQueryObject(Series__c series, Map<String, Schema.DescribeFieldResult> mapSobjectFields, Set<String> setCreateFields, Set<String> setDetailFields, List<CalendarDTO.FieldValueWrapper> createFields, Date ipStartDate, Date ipEndDate,  Map<String,String> mapOfReferenceNames) {
        Schema.DescribeFieldResult dfield;
        String strWhereClause;
        String strFilterClause = '';
        String strQuery = 'SELECT Id';

        strQuery += !strQuery.contains(series.Item_Start__c) ? ', ' + series.Item_Start__c : '';
        strQuery += !strQuery.contains(series.Item_End__c) ? ', ' + series.Item_End__c : '';

        if(mapSobjectFields.get('Name') != null && !strQuery.contains('Name')) {
            setDetailFields.add('Name');
        }
        setCreateFields.addAll((Set<String>) JSON.deserialize(series.Fields_to_Display_on_Create_Edit__c, Set<String>.class));
        setDetailFields.addAll((Set<String>) JSON.deserialize(series.Fields_to_Display_on_Detail__c, Set<String>.class));

        setCreateFields(setCreateFields, mapSobjectFields, series, createFields);
        strQuery = setDetailFields(setDetailFields, strQuery, mapSobjectFields, mapOfReferenceNames);
        strQuery = removeDublicateFields(strQuery);

        strQuery += ' FROM ' + series.Object_Name__c;
        String strUserId = UserInfo.getUserId();

        // strWhereClause = ' WHERE ' + series.Item_Start__c + ' >= : ipStartDate';
        // strWhereClause += ' AND ' + series.Item_End__c + ' <= : ipEndDate';

        strWhereClause = ' WHERE ' + series.Item_Start__c + ' <= : ipEndDate';
        strWhereClause += ' AND ' + series.Item_End__c + ' >= : ipStartDate';

        strWhereClause += series.Filter_by_Owner__c ? ' AND OwnerId =: strUserId' : '';

        List<String> filterClauses = new List<String>();
        for(Series_Filter_Criterion__c filter : series.Filter_Criteria__r) {
            if (String.isNotBlank(filter.Operator__c) && SettingPageHelper.templatesBySpecialOperators.containsKey(filter.Operator__c)) {
                filterClauses.add(
                    String.format(
                        SettingPageHelper.templatesBySpecialOperators.get(filter.Operator__c),
                        new List<String>{
                                filter.Field_Name__c,
                                filter.Value__c
                        }
                    ).replaceAll(SettingPageHelper.singleQuoteCode, '\'')
                );
            } else if (filter.Operator__c == SettingPageHelper.IS_NULL_OPERATOR) {
                filterClauses.add(
                    String.format(
                        '({0} {1} NULL)',
                        new List<String>{
                                filter.Field_Name__c,
                                filter.Value__c == 'true' ? '=' : '!='
                        }
                    )
                );
            } else if (mapSobjectFields.containsKey(filter.Field_Name__c)) {
                Schema.DescribeFieldResult describeField = mapSobjectFields.get(filter.Field_Name__c);
                String sObjectFieldType = describeField.getType().name();

                String value = filter.Value__c;
                if (textTypeSet.contains(sObjectFieldType)) {
                    value = '\'' + value + '\'';
                } else if (sObjectFieldType == 'DATETIME' && String.isNotBlank(value)) {
                    value = value.replace(' ', 'T') + 'Z';
                } else if (sObjectFieldType == 'TIME' && String.isNotBlank(value)) {
                    value = String.valueOf(Time.newInstance(0, 0, Integer.valueOf(value), 0));
                } else if (sObjectFieldType == 'MULTIPICKLIST') {
                    value = String.isNotBlank(value) ?
                            String.join((List<String>)JSON.deserialize(value, List<String>.class), ';') :
                            '';
                    value = (new Set<String>{'=', '!='}).contains(filter.Operator__c) ?
                            '\'' + value + '\'' :
                            '(\'' + value + '\')';
                }
                filterClauses.add(
                    String.format(
                        '({0} {1} {2})',
                        new List<String>{
                                filter.Field_Name__c,
                                filter.Operator__c,
                                value
                        }
                    )
                );
            }
        }

        if (!filterClauses.isEmpty()) {
            List<String> filterClausesWithFirstNull = new List<String>{''};
            filterClausesWithFirstNull.addAll(filterClauses);
            strFilterClause = String.isNotBlank(series.Filter_Logic__c) ?
                    String.format(
                            '(' + series.Filter_Logic__c.replaceAll('(\\d+)', '{$1}') + ')',
                            filterClausesWithFirstNull
                    ) :
                    String.join(filterClauses, ' AND ');
        }

        if(!String.isBlank(strFilterClause)) {
            strWhereClause = strWhereClause + ' AND ' + strFilterClause;
        }
        strQuery += strWhereClause;
        System.debug('ipStartDate: ' + ipStartDate);
        System.debug('ipEndDate: ' + ipEndDate);
        System.debug(strQuery);
        return strQuery;
    }
    private static Map<String, Map<String, Schema.DescribeFieldResult>> getDescribeObjectsFieldMap(Map<String, Schema.DescribeSObjectResult> mapSObjectDesc) {
        Map<String, Map<String, Schema.DescribeFieldResult>> describeObjectsFieldMap = new Map<String, Map<String, Schema.DescribeFieldResult>>();
        for(String objectName : mapSObjectDesc.keySet()) {
            describeObjectsFieldMap.put(objectName, getSchemaObjectFieldsMap(mapSObjectDesc.get(objectName)));
        }
        return describeObjectsFieldMap;
    }
    /**
     *  @description get all Calender records
     */
    public static CalendarDTO.CalenderWrapper getAllCalenderRecords(Id idCalender, String strStartDate, String strEndDate) {
        Date ipStartDate = Date.parse(strStartDate);
        Date ipEndDate = Date.parse(strEndDate);
        CalendarDTO.CalenderWrapper calenderWrapper = new CalendarDTO.CalenderWrapper();
        calenderWrapper.Objects = new List<CalendarDTO.CalenderObjectWrapper>();
        calenderWrapper.TimeZone = UserInfo.getTimeZone().getOffset(System.now());
        Map<String, CalendarDTO.CalenderObjectWrapper> mapCalendarWrapper = new Map<String, CalendarDTO.CalenderObjectWrapper>();
        System.debug('getAllCalenderRecords');
        if(!String.isBlank(idCalender)) {
            String strId;
            String strName;
            DateTime startDate;
            DateTime endDate;
            Schema.describeFieldResult dfield;
            Map<Id, Calendar_Series__c> mapCalendarSeries = new Map<Id, Calendar_Series__c>();

            Set<String> setDetailFields;
            Set<String> setCreateFields;
            CalendarDTO.CalenderObjectWrapper calenderObjectWrapper;
            // CalendarDTO.CalenderSeriesWrapper calendarSeries;

            Map<String, Schema.DescribeSObjectResult> mapSObjectDesc = new Map<String, Schema.DescribeSObjectResult>();

            mapCalendarSeries = getMapCalendarSeriesByCalendarId(idCalender);
            List<Series__c> listSeries = getListSeriesBySetId(mapCalendarSeries.keySet());
            mapSObjectDesc = getObjectDescribe(listSeries);
            Map<String, Map<String, Schema.DescribeFieldResult>> mapSobjectsFields = getDescribeObjectsFieldMap(mapSObjectDesc);
            for(Series__c series : listSeries) {
                if(!mapSObjectDesc.containsKey(series.Object_Name__c) || !mapSObjectDesc.get(series.Object_Name__c).isAccessible()) {
                    continue;
                }
                /*
                if(!mapCalendarWrapper.containsKey(series.Object_Name__c)) {
                    calenderObjectWrapper = new CalendarDTO.CalenderObjectWrapper();
                    calenderObjectWrapper.Series = new List<CalendarDTO.CalenderSeriesWrapper>();
                    calenderObjectWrapper.Records = new List<CalendarDTO.CalenderRecordWrapper>();
                    calenderObjectWrapper.ObjectApi = series.Object_Name__c;
                }
                else {
                    calenderObjectWrapper = mapCalendarWrapper.get(series.Object_Name__c);
                }
                */
                calenderObjectWrapper = new CalendarDTO.CalenderObjectWrapper(
                        series.Id,
                        series.Name,
                        series.IsEditable__c,
                        series.Object_Name__c,
                        mapCalendarSeries.get(series.id).Series__r.Color__c,
                        mapSObjectDesc.get(series.Object_Name__c).getLabelPlural()
                );
                // calenderObjectWrapper.Series = new List<CalendarDTO.CalenderSeriesWrapper>();
                // calendarSeries = new CalendarDTO.CalenderSeriesWrapper();
                setCreateFields = new Set<String>();
                setDetailFields = new Set<String>();
                Map<String, Schema.DescribeFieldResult> mapSobjectFields = mapSobjectsFields.get(series.Object_Name__c);
                Map<String,String> mapOfReferenceNames = new Map<String,String>();
                String strQuery = getQueryObject(series, mapSobjectFields, setCreateFields, setDetailFields, calenderObjectWrapper.CreateFields, ipStartDate, ipEndDate, mapOfReferenceNames);
                String strUserId = UserInfo.getUserId();
                for(sObject currSObject : Database.query(strQuery)) {
                    strId = (String) currSObject.get('id');
                    List<CalendarDTO.FieldValueWrapper> Fields = new List<CalendarDTO.FieldValueWrapper>();

                    if(setDetailFields.size() > 0) {
                        for(String strField : setDetailFields) {
                            List<String> listPicklistEntry = new List<String>();
                            //strField = strField.removeStartIgnoreCase('');
                            if(mapSobjectFields.containsKey(strField) && !mapOfReferenceNames.containsKey(strField)) {
                                String strKey = series.Object_Name__c + '.' + strField;
                                dfield = mapSobjectFields.get(strField);
                                if(dfield.getType().name().equalsIgnoreCase('PICKLIST')) {
                                    for(Schema.PicklistEntry picklistEntry : dfield.getPicklistValues()) {
                                        if(picklistEntry.isActive()) {
                                            listPicklistEntry.add(picklistEntry.getValue());
                                        }
                                    }
                                }
                                Fields.add(new CalendarDTO.FieldValueWrapper(dfield.getLabel(), strField, currSObject.get(strField), dfield.getType().name(), !dfield.isUpdateable(), '', false, listPicklistEntry));
                            } else {
                                String infoField = mapOfReferenceNames.get(strField);
                                if(infoField.contains('.')) {
                                    List<String> listObjField = infoField.split('\\.');

                                    if(listObjField.size() > 1) {
                                        //if(currSObject.getSObject(listObjField[0]) != null) {
                                            String relationObj = '';
                                            dfield = mapSobjectFields.get(strField);
                                            List<Schema.sObjectType> listsObjectType = dfield.getReferenceTo();

                                            if(listsObjectType.size() > 0) {
                                                relationObj = listsObjectType[0].getDescribe().getName();
                                            }
                                            sObject currObj = currSObject.getSObject(listObjField[0]);
                                            String textData;
                                            if (currObj != null){
                                                textData = String.valueOf(currObj.get(listObjField[1]));
                                            }
                                            //currObj.get(listObjField[1])
                                            Fields.add(new CalendarDTO.FieldValueWrapper(dfield.getLabel(), strField, currSObject.get(strField), textData, 'REFERENCE', !dfield.isUpdateable(), relationObj, false, new List<String>()));
                                        //}
                                    }
                                }
                            }
                        }


                        try {
                            strName = (String) currSObject.get('name');
                        } catch(Exception e) {
                            if (series.Object_Name__c == 'Case' && strQuery.contains('Subject')) {
                                strName = (String) currSObject.get('Subject');
                            } else {
                                System.debug(LoggingLevel.ERROR, e.getMessage());
                            }
                        }

                        startDate = endDate = null;

                        if(!String.isBlank(series.Item_Start__c)) {
                            startDate = (DateTime) currSObject.get(series.Item_Start__c);
                        }

                        if(!String.isBlank(series.Item_End__c)) {
                            endDate = (DateTime) currSObject.get(series.Item_End__c);
                        }
                        System.debug(fields);
                        calenderObjectWrapper.Records.add(new CalendarDTO.CalenderRecordWrapper(strId, strName, startDate, endDate, Fields));
                    }
                }
                calenderWrapper.Objects.add(calenderObjectWrapper);
            }
        }

        // calenderWrapper.Objects.addAll(mapCalendarWrapper.values());
        return calenderWrapper;
    }

    // public static String updateRecord(String calendarRWStr){
    //     CalendarDTO.MessageWrapper messageWrapper = new CalendarDTO.MessageWrapper();
    //     //try {
    //         CalendarDTO.CalenderRecordWrapper calenderRW = (CalendarDTO.CalenderRecordWrapper) JSON.deserialize(calendarRWStr, CalendarDTO.CalenderRecordWrapper.class);
    //         Id recordId = calenderRW.Id;
    //         Schema.SObjectType sobjectType = recordId.getSObjectType();
    //         String sobjectName = sobjectType.getDescribe().getName();
                        
    //         Map<String, Schema.describeFieldResult> mapSFieldDesc = new Map<String, Schema.describeFieldResult>();
    //         Map<String, Schema.SObjectType> mapGlobalDescribe = Schema.getGlobalDescribe();
    //         Schema.SObjectType SObjectTypeObj;
    //         Schema.describeFieldResult dfield;
    //         Schema.DescribeSObjectResult describeSObjectResultObj;
    //         String strFieldName;

    //         SObjectTypeObj = mapGlobalDescribe.get(sobjectName);
    //         describeSObjectResultObj = SObjectTypeObj.getDescribe();
    //         if(describeSObjectResultObj.isUpdateable()) {
    //             Map<String, Schema.SObjectField> mapSobjectFields =  describeSObjectResultObj.fields.getMap();
    //             sObject updateObject = Schema.getGlobalDescribe().get(sobjectName).newSObject() ;
    //             for(CalendarDTO.FieldValueWrapper fieldValue : calenderRW.Fields) {
    //                 strFieldName = String.escapeSingleQuotes(fieldValue.FieldAPI);
    //                 if(!mapSFieldDesc.containsKey(strFieldName)) {
    //                     dfield = mapSobjectFields.get(strFieldName).getDescribe();
    //                     mapSFieldDesc.put(strFieldName, dfield);
    //                 } else {
    //                     dfield = mapSFieldDesc.get(strFieldName);
    //                 }
    //                 if(dfield.isUpdateable()){
    //                     updateObject.put(strFieldName, convertUtility(fieldValue.Data, fieldValue.FieldType));
    //                 }
    //             }
    //             updateObject.Id = recordId; 
    //             ESAPI.securityUtils().validatedUpdate(new List<sObject>{updateObject});
    //             messageWrapper.IsSuccess = true;
    //             messageWrapper.Message = 'Record Update Successfully!';
    //             messageWrapper.Id = updateObject.Id;
    //         } else {
    //             messageWrapper.IsSuccess = false;
    //             messageWrapper.Message = 'You do not have sufficient permissions to update this record!';
    //         }
    //     //} catch(Exception e) {
    //      //   messageWrapper.IsSuccess = false;
    //    //     messageWrapper.Message = e.getMessage();
    //     //}
    //     return JSON.serialize(messageWrapper);
    // }
    
    /**
     *  @description to save incoming record
     */
    public static String saveRecord(String strInputData) {
        CalendarDTO.MessageWrapper messageWrapper = new CalendarDTO.MessageWrapper();
        try {
            CalendarDTO.InputWrapper inputWrapper = (CalendarDTO.InputWrapper) JSON.deserialize(strInputData, CalendarDTO.InputWrapper.class);
            Map<String, Schema.describeFieldResult> mapSFieldDesc = new Map<String, Schema.describeFieldResult>();
            Map<String, Schema.SObjectType> mapGlobalDescribe = Schema.getGlobalDescribe();
            Schema.SObjectType SObjectTypeObj;
            Schema.describeFieldResult dfield;
            Schema.DescribeSObjectResult describeSObjectResultObj;
            String strObjectName = String.escapeSingleQuotes(inputWrapper.ObjectApi);
            String strFieldName;

            SObjectTypeObj = mapGlobalDescribe.get(strObjectName);
            describeSObjectResultObj = SObjectTypeObj.getDescribe();
            
            if(describeSObjectResultObj.isCreateable()) {
                Map<String, Schema.SObjectField> mapSobjectFields =  describeSObjectResultObj.fields.getMap();
                sObject createObject = Schema.getGlobalDescribe().get(strObjectName).newSObject() ;
                
                for(CalendarDTO.FieldValueWrapper1 fieldValue : inputWrapper.CreateFields) {
                    strFieldName = String.escapeSingleQuotes(fieldValue.FieldAPI);
                    
                    if(!mapSFieldDesc.containsKey(strFieldName)) {
                        dfield = mapSobjectFields.get(strFieldName).getDescribe();
                        
                        mapSFieldDesc.put(strFieldName, dfield);
                    } else {
                        dfield = mapSFieldDesc.get(strFieldName);
                    }
                    if(dfield.isCreateable()) {
                        createObject.put(strFieldName, convertUtility(fieldValue.Data, fieldValue.FieldType));
                    }
                }
                //insert createObject;
                ESAPI.securityUtils().validatedInsert(new List<sObject>{createObject});
                messageWrapper.IsSuccess = true;
                messageWrapper.Message = 'Record Created Successfully!';
                messageWrapper.Id = createObject.Id;
            }
            else {
                messageWrapper.IsSuccess = false;
                messageWrapper.Message = 'You do not have sufficient permissions to create this record!';
            }
        }
        catch(Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            messageWrapper.IsSuccess = false;
            messageWrapper.Message = e.getMessage();
        }
        
        return JSON.serialize(messageWrapper);
    }
    
    /**
     *  @description search records
     */
    public static Object convertUtility(Object strInputDataObj, String strType) {
        String strInputData = strInputDataObj.toString();
        Object retObject;
        try {
            if(strType.equalsIgnoreCase('Decimal') || strType.equalsIgnoreCase('DOUBLE') || strType.equalsIgnoreCase('CURRENCY')) {
                retObject = Decimal.valueOf(strInputData);
            } else if(strType.equalsIgnoreCase('Datetime')) {
                //retObject = Datetime.valueOf(strInputData);
                System.debug(strInputData);
                try {
                    retObject = (Datetime)JSON.deserialize('"' + strInputData + '"', Datetime.class);
                    System.debug(retObject);
                } catch (Exception e) {
                    retObject = getConvertDateTime(strInputData);
                    System.debug('catch ' + retObject);
                }
            } else if(strType.equalsIgnoreCase('Date')) {
                retObject = Date.valueOf(strInputData);
            } else if(strType.equalsIgnoreCase('Boolean')) {
                retObject = Boolean.valueOf(strInputData);
            } else if(strType.equalsIgnoreCase('Integer')) {
                retObject = Integer.valueOf(strInputData);
            } else {
                retObject = strInputData;
            }
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
        }
        return retObject;
    }
    /**
     *  convertor from string Sep 4, 2016 15:00 PM  to dateTime
     */
    public static DateTime getConvertDateTime(string strDT) {
        Map<String, Integer> MapMonthList = new Map<string,integer>{
            'January' => 1,
            'February'=> 2,
            'March' => 3,
            'April' => 4,
            'May' => 5,
            'June' => 6,
            'July' => 7,
            'August' => 8,
            'Sep' => 9,
            'October' => 10,
            'November' => 11,
            'December' => 12
        };
        String[] strDTDivided = strDT.split(' ');
        
        string month = String.ValueOf(MapMonthList.get(strDTDivided.get(0)));
        string day = strDTDivided.get(1).replace(',', '');
        string year = strDTDivided.get(2);
        
        string hour = strDTDivided.get(3).split(':').get(0);
        string minute = strDTDivided.get(3).split(':').get(1);
        string second = '00';
        
        if (strDTDivided.get(4) == 'PM' && Integer.valueOf(hour) < 12) {
            hour = String.ValueOf(Integer.ValueOf(hour) + 12);
        }
        String stringDate = year + '-' + month + '-' + day + ' ' + hour + ':' + minute + ':' + second;
        
        return datetime.valueOf(stringDate);
    
    }
    /**
     *  @description search records
     */
    public static String searchData(String strInputData, String strObject, String parentObject) {
        List<CalendarDTO.SearchWrapper> listSearchWrapper = new List<CalendarDTO.SearchWrapper>();
        String strInput = '';
        
        try {
            if(!String.isBlank(strInputData) && !strInputData.equalsIgnoreCase('null')) {
                strInput = strInputData;
            }
            String newStrInput = '%' + String.escapeSingleQuotes(strInput) + '%';
            String strQuery = 'SELECT Id, Name FROM '+ String.escapeSingleQuotes(strObject) +' WHERE Name LIKE :newStrInput';
            List<sObject> listOfsObjects;
            Schema.SObjectType someType = Schema.getGlobalDescribe().get(strObject);
            /*if (someType == null){
                someType = Schema.getGlobalDescribe().get(''+strObject);
            }*/
            if (AccessCheck.isAuthorizedToView(someType, strQuery, null)){
                listOfsObjects = Database.query(strQuery);
            }            
            for(sObject currObj : listOfsObjects) {
                listSearchWrapper.add(new CalendarDTO.SearchWrapper(currObj));
            }
        }
        catch(Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
        }
        
        return JSON.serialize(listSearchWrapper);
    }

    private static String getNamespacePrefix() {
        String strNamespace = '';
        if(CalendarHelper.class.getName().contains('.')) {
            strNamespace = CalendarHelper.class.getName().substringBefore('.');
            strNamespace = strNamespace  + '__';
        }
        return strNamespace ;
    }
    public static List<String> getApiNameWithOrgPrefixList(List<String> apiNameList) {
        for(Integer i=0, j=apiNameList.size(); i<j;i++) {
            apiNameList[i] = apiNameList[i].endsWithIgnoreCase('__c') ? orgPrefix + apiNameList[i] : apiNameList[i];
        }
        return apiNameList;
    }
    public static String getApiNameWithOrgPrefix(String apiName) {
        return apiName.endsWithIgnoreCase('__c') ? orgPrefix + apiName : apiName;
    }
    //workaround for app on dev org
    public static Map<String, Schema.DescribeFieldResult> getSchemaObjectFieldsMap(DescribeSObjectResult typeDescribe) {
        Map<String, Schema.SObjectField> mapSObjectFieldDesc = typeDescribe.fields.getMap();
        Map<String, Schema.DescribeFieldResult> returnSObjectFieldDescMap = new Map<String, Schema.DescribeFieldResult>();
        for(Schema.SObjectField item : mapSObjectFieldDesc.values()) {
            Schema.DescribeFieldResult fieldDescribe = item.getDescribe();
            system.debug('field '+fieldDescribe.getName());
            returnSObjectFieldDescMap.put(fieldDescribe.getName(), fieldDescribe);
        }
        return returnSObjectFieldDescMap;
    }
}
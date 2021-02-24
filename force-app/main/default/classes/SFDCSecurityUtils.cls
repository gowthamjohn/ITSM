/*----------------------------------------------------------------------------------------------- */
/*                                                                                                */
/* This сlass checks possibility of DML operation running.                                        */
/*                                                                                                */
/* METHODS AND CLASSES:                                                                           */
/* SFDC_CRUD_Exception:                     throws exceptions.                                    */
/* SFDC_FLS_Exception:                      throws exceptions.                                    */
/* checkForInsert:                          checks the possibility of items inserting.            */
/* checkForInsertSobject:                   checks the possibility of item inserting.             */
/* checkForUpdate:                          checks the possibility of items updating.             */
/* checkForUpdateSobject:                   checks the possibility of item updating.              */
/* doValidate:                              checks the possibility of using DML for selected      */
/*                                          items and runs it.                                    */
/* validatedDelete:                         checks the possibility of items deletion and delete   */
/*                                          them if possible.                                     */
/* validatedInsert:                         checks the possibility of items insertion and insert  */
/*                                          them if possible.                                     */
/* validatedUpdate:                         checks the possibility of items updation and update   */
/*                                          them if possible.                                     */
/* validatedUpsert:                         checks the possibility of items upsertion and upsert  */
/*                                          them if possible.                                     */
/* separateList:                            prepares a list of sObjects.                          */
/* getIdsFromSObjects:                      gets sObjects ids.                                    */
/* getFieldsFromSobjects:                   prepares a map of sObjects fields.                    */
/* getRestrictedFields:                     gets list of restricted sObjects fields.              */
/* validateCRUDPermissionForObjectTypes:    checks sObjects for DML using.                        */
/* upsertItems:                             upserts list of items.                                */
/*                                                                                                */
/*------------------------------------------------------------------------------------------------*/

global with sharing class SFDCSecurityUtils {

    @testVisible
    private static Boolean              crudValue = false;

    private enum                        DMLOperation {
        DML_INSERT,
        DML_UPDATE,
        DML_DELETE,
        DML_UPSERT
    }

    private static final Set<String>    exceptionValues;

    static {
        exceptionValues = new Set<String> {
            'createdbyid',
            'createddate',
            'id',
            'isdeleted',
            'lastmodifiedbyid',
            'lastmodifieddate',
            'systemmodstamp'
        };
    }

    /*--------------------------------------------------------------------------------------------*/
    /*                                                                                            */
    /* CLASS: SFDC_CRUD_Exception                                                                 */
    /*                                                                                            */
    /* This class throws exceptions.                                                              */
    /*                                                                                            */
    /*--------------------------------------------------------------------------------------------*/

    @testVisible
    private class SFDC_CRUD_Exception extends Exception {}

    /*--------------------------------------------------------------------------------------------*/
    /*                                                                                            */
    /* CLASS: SFDC_FLS_Exception                                                                  */
    /*                                                                                            */
    /* This class throws exceptions.                                                              */
    /*                                                                                            */
    /*--------------------------------------------------------------------------------------------*/

    @testVisible
    private class SFDC_FLS_Exception extends Exception {}

    /*--------------------------------------------------------------------------------------------*/
    /*                                                                                            */
    /* METHOD: checkForInsert                                                                     */
    /*                                                                                            */
    /* This method checks the possibility of items inserting.                                     */
    /*                                                                                            */
    /* ARGUMENTS:                                                                                 */
    /* items:               list of items, need to be inserted                                    */
    /* sobjFieldsList:      map of sObject fields                                                 */
    /*                                                                                            */
    /*--------------------------------------------------------------------------------------------*/

    private void checkForInsert(List<SObject> items,
                                Map<SObjectType, Map<DMLOperation, List<String>>> sobjFieldsList) {
        for (SObject item : items) {
            checkForInsertSobject(
                new List<SObject> {item},
                sobjFieldsList.get(item.getSObjectType()).get(DMLOperation.DML_INSERT)
            );
        }
    }

    /*--------------------------------------------------------------------------------------------*/
    /*                                                                                            */
    /* METHOD: checkForInsertSobject                                                              */
    /*                                                                                            */
    /* This method checks the possibility of item inserting.                                      */
    /*                                                                                            */
    /* ARGUMENTS:                                                                                 */
    /* itemSobjL:           item, need to be inserted                                             */
    /* restrictedFields:    list of sObject fields, which could be inserted                       */
    /*                                                                                            */
    /*--------------------------------------------------------------------------------------------*/

    private void checkForInsertSobject(List<SObject> itemSobjL, List<String> restrictedFields) {

        // Declare local variables
        Map<String, Object>     fieldsMap;
        SObject                 itemSobj = itemSobjL.get(0);
        String                  sobjectName = itemSobj.getSObjectType().getDescribe().getName();

        // if sObject contains restricted fields, the exception will be thrown
        fieldsMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(itemSobj));
        fieldsMap.remove('attributes');
        for (String item : restrictedFields) {
            if (fieldsMap.get(item) != null) {
                throw new SFDC_FLS_Exception('FLS Exception ' + sobjectName + ' -> ' + item);
            }
        }
    }

    /*--------------------------------------------------------------------------------------------*/
    /*                                                                                            */
    /* METHOD: checkForUpdate                                                                     */
    /*                                                                                            */
    /* This method checks the possibility of items updating.                                      */
    /*                                                                                            */
    /* ARGUMENTS:                                                                                 */
    /* items:               list of items, need to be updated                                     */
    /* sobjFieldsList:      map of sObject fields                                                 */
    /* sobjIdsList:         list of existing records ids                                          */
    /*                                                                                            */
    /*--------------------------------------------------------------------------------------------*/

    private void checkForUpdate(List<SObject> items,
                                Map<SObjectType, Map<DMLOperation, List<String>>> sobjFieldsList,
                                Map<SObjectType, List<Id>> sobjIdsList) {

        // Declare local variables
        Map<Id, SObject>                    existMap;
        Map<SObjectType, Map<Id, SObject>>  existRecords = new Map<SObjectType, Map<Id, SObject>>();
        String                              query;
        String                              queryFields;
        List<String>                        queryParams;
        List<Id>                            tempIdList;
        String                              templateQuery;

        // checks the possibility of items updating
        templateQuery = 'SELECT {0} FROM {1} WHERE Id in :tempIdList';
        for (SObjectType item : sobjFieldsList.keySet()) {
            queryFields = String.join(sobjFieldsList.get(item).get(DMLOperation.DML_UPDATE), ', ');
            if (String.isNotBlank(queryFields)) {
                queryParams = new List<String>();
                queryParams.add(String.escapeSingleQuotes(queryFields));
                queryParams.add(String.escapeSingleQuotes(item.getDescribe().getName()));
                tempIdList = sobjIdsList.get(item);
                //queryParams.add('(\'' + String.join(sobjIdsList.get(item), '\', \'') + '\')');
                query = String.format(templateQuery, queryParams);
                existRecords.put(item, new Map<Id, Sobject>(Database.query(query)));
            }
        }
        Sobject existRecord;
        for (Sobject item : items) {
            existMap = existRecords.get(item.getSObjectType());
            if (existMap != null) {
                existRecord = existMap.get(item.Id);
                checkForUpdateSobject(
                    new List<SObject> {item},
                    new List<SObject> {existRecord},
                    sobjFieldsList.get(item.getSObjectType()).get(DMLOperation.DML_UPDATE)
                );
            }
        }
    }

    /*--------------------------------------------------------------------------------------------*/
    /*                                                                                            */
    /* METHOD: checkForUpdateSobject                                                              */
    /*                                                                                            */
    /* This method checks the possibility of item updating.                                       */
    /*                                                                                            */
    /* ARGUMENTS:                                                                                 */
    /* currentSobjL:        item, need to be updated                                              */
    /* existSobjL:          list of existing sObjects                                             */
    /* restrictedFields:    list of fields that couldn't be updated                               */
    /*                                                                                            */
    /*--------------------------------------------------------------------------------------------*/

    private void checkForUpdateSobject(List<Sobject> currentSobjL, List<Sobject> existSobjL,
                                       List<String> restrictedFields) {

        // Declare local variables
        SObject                 currentSobj = currentSobjL.get(0);
        SObject                 existSobj = existSobjL.get(0);
        Map<String, Object>     fieldsMap;
        String                  sobjectName = currentSobj.getSObjectType().getDescribe().getName();

        // if sObject contains restricted fields, the exception will be thrown
        fieldsMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(currentSobj));
        fieldsMap.remove('attributes');
        for (String item : restrictedFields) {
            if (fieldsMap.get(item) != null && fieldsMap.get(item) != existSobj.get(item)) {
                throw new SFDC_FLS_Exception('FLS Exception ' + sobjectName + ' -> ' + item);
            }
        }
    }

    /*--------------------------------------------------------------------------------------------*/
    /*                                                                                            */
    /* METHOD: doValidate                                                                         */
    /*                                                                                            */
    /* This method checks the possibility of using DML for selected items and runs it.            */
    /*                                                                                            */
    /* ARGUMENTS:                                                                                 */
    /* items:               list of items which need DML operation                                */
    /* operation:           selected DML operation                                                */
    /*                                                                                            */
    /*--------------------------------------------------------------------------------------------*/

    private void doValidate(List<SObject> items, DMLOperation operation) {

        // Declare local variables
        Map<SObjectType, Map<DMLOperation, List<String>>>   sobjFieldsList;
        Map<SObjectType, List<Id>>                          sobjIdsList = getIdsFromSObjects(items);

        // checking the possibility of using DML
        sobjFieldsList = getFieldsFromSobjects(sobjIdsList.keySet(), operation);
        validateCRUDPermissionForObjectTypes(sobjIdsList.keySet(), operation);
        if (operation == DMLOperation.DML_INSERT) {
            checkForInsert(items, sobjFieldsList);
        } else if (operation != DMLOperation.DML_DELETE) {
            List<SObject> withId = separateList(items, true);
            List<SObject> withoutId = separateList(items, false);
            checkForInsert(withoutId, sobjFieldsList);
            checkForUpdate(withId, sobjFieldsList, sobjIdsList);
        }

        // using DML
        if (operation == DMLOperation.DML_INSERT) {
            insert items;
        } else if (operation == DMLOperation.DML_DELETE) {
            delete items;
        } else if (operation == DMLOperation.DML_UPDATE) {
            update items;
        } else if (operation == DMLOperation.DML_UPSERT) {
            upsertItems(items);
        }
    }

    /*--------------------------------------------------------------------------------------------*/
    /*                                                                                            */
    /* METHOD: validatedDelete                                                                    */
    /*                                                                                            */
    /* This method checks the possibility of items deletion and delete them if possible.          */
    /*                                                                                            */
    /* ARGUMENTS:                                                                                 */
    /* items:               list of items which need to be deleted                                */
    /*                                                                                            */
    /*--------------------------------------------------------------------------------------------*/

    global void validatedDelete(List<SObject> items) {
        doValidate(items, DMLOperation.DML_DELETE);
    }

    /*--------------------------------------------------------------------------------------------*/
    /*                                                                                            */
    /* METHOD: validatedInsert                                                                    */
    /*                                                                                            */
    /* This method checks the possibility of items insertion and insert them if possible.         */
    /*                                                                                            */
    /* ARGUMENTS:                                                                                 */
    /* items:               list of items which need to be inserted                               */
    /*                                                                                            */
    /*--------------------------------------------------------------------------------------------*/

    global void validatedInsert(List<SObject> items) {
        doValidate(items, DMLOperation.DML_INSERT);
    }

    /*--------------------------------------------------------------------------------------------*/
    /*                                                                                            */
    /* METHOD: validatedUpdate                                                                    */
    /*                                                                                            */
    /* This method checks the possibility of items updation and update them if possible.          */
    /*                                                                                            */
    /* ARGUMENTS:                                                                                 */
    /* items:               list of items which need to be updated                                */
    /*                                                                                            */
    /*--------------------------------------------------------------------------------------------*/

    global void validatedUpdate(List<SObject> items) {
        doValidate(items, DMLOperation.DML_UPDATE);
    }

    /*--------------------------------------------------------------------------------------------*/
    /*                                                                                            */
    /* METHOD: validatedUpsert                                                                    */
    /*                                                                                            */
    /* This method checks the possibility of items upsertion and upsert them if possible.         */
    /*                                                                                            */
    /* ARGUMENTS:                                                                                 */
    /* items:               list of items which need to be upserted                               */
    /*                                                                                            */
    /*--------------------------------------------------------------------------------------------*/

    global void validatedUpsert(List<SObject> items) {
        doValidate(items, DMLOperation.DML_UPSERT);
    }

    /*--------------------------------------------------------------------------------------------*/
    /*                                                                                            */
    /* METHOD: separateList                                                                       */
    /*                                                                                            */
    /* This method prepares a list of sObjects.                                                   */
    /*                                                                                            */
    /* ARGUMENTS:                                                                                 */
    /* items:               list of items which need to be upserted                               */
    /* inculdeId:           flag of included id                                                   */
    /*                                                                                            */
    /*--------------------------------------------------------------------------------------------*/

    private List<SObject> separateList(List<SObject> items, Boolean inculdeId) {

        // Declare local variables
        List<SObject> result = new List<SObject>();

        // preparing a list of sObjects
        for (SObject item : items) {
            if (inculdeId && item.Id != null) {
                result.add(item);
            }
            if (!inculdeId && item.Id == null) {
                result.add(item);
            }
        }
        return result;
    }

    /*--------------------------------------------------------------------------------------------*/
    /*                                                                                            */
    /* METHOD: getIdsFromSObjects                                                                 */
    /*                                                                                            */
    /* This method gets sObjects ids.                                                             */
    /*                                                                                            */
    /* ARGUMENTS:                                                                                 */
    /* items:               list of items                                                         */
    /*                                                                                            */
    /*--------------------------------------------------------------------------------------------*/

    private Map<SObjectType, List<Id>> getIdsFromSObjects(List<SObject> items) {

        // Declare local variables
        Map<SObjectType, List<Id>>  result = new Map<SObjectType, List<Id>>();
        SObjectType                 item;
        Id                          itemId;
        List<Id>                    itemList;
        final Integer               itemsSize = items.size();

        // get sObjects ids
        for (Integer i = 0; i < itemsSize; i++) {
            item = items.get(i).getSObjectType();
            itemId = (Id)items.get(i).get('Id');
            itemList = result.get(item);
            if (itemList == null) {
                itemList = new List<Id>();
                result.put(item, itemList);
            }
            if (itemId != null) {
                itemList.add(itemId);
            }
        }
        return result;
    }

    /*--------------------------------------------------------------------------------------------*/
    /*                                                                                            */
    /* METHOD: getFieldsFromSobjects                                                              */
    /*                                                                                            */
    /* This method prepares a map of sObjects fields.                                             */
    /*                                                                                            */
    /* ARGUMENTS:                                                                                 */
    /* typeSet:             set of sObjects types                                                 */
    /* operation:           DML operation                                                         */
    /*                                                                                            */
    /*--------------------------------------------------------------------------------------------*/

    private Map<SObjectType, Map<DMLOperation, List<String>>> getFieldsFromSobjects(
        Set<SObjectType> typeSet, DMLOperation operation) {

        // Declare local variables
        Map<DMLOperation, List<String>>                     itemMap;
        Map<SObjectType, Map<DMLOperation, List<String>>>   result =
            new Map<SObjectType, Map<DMLOperation, List<String>>>();

        // prepare a map of sObjects fields
        for (SObjectType item : typeSet) {
            itemMap = result.get(item);
            if (itemMap == null) {
                itemMap = new Map<DMLOperation, List<String>>();
                result.put(item, itemMap);
            }
            if (operation == DMLOperation.DML_UPSERT) {
                itemMap.put(DMLOperation.DML_UPDATE,
                            getRestrictedFields(item, DMLOperation.DML_UPDATE));
                itemMap.put(DMLOperation.DML_INSERT,
                            getRestrictedFields(item, DMLOperation.DML_INSERT));
            } else {
                itemMap.put(operation, getRestrictedFields(item, operation));
            }
        }
        return result;
    }

    /*--------------------------------------------------------------------------------------------*/
    /*                                                                                            */
    /* METHOD: getRestrictedFields                                                                */
    /*                                                                                            */
    /* This method gets list of restricted sObjects fields.                                       */
    /*                                                                                            */
    /* ARGUMENTS:                                                                                 */
    /* sobjType:            type of sObject                                                       */
    /* operation:           DML operation                                                         */
    /*                                                                                            */
    /*--------------------------------------------------------------------------------------------*/

    private List<String> getRestrictedFields(SObjectType sobjType, DMLOperation operation) {

        // Declare local variables
        DescribeFieldResult                 itemDescribe;
        Map<String, Schema.SObjectField>    objectFields = sobjType.getDescribe().fields.getMap();
        List<String>                        result = new List<String>();

        // get list of restricted sObjects fields
        for (String item : objectFields.keySet()) {
            if (!exceptionValues.contains(item.toLowerCase())) {
                itemDescribe = objectFields.get(item).getDescribe();
                if ((!itemDescribe.isCalculated() &&
                        ((operation == DMLOperation.DML_INSERT && !itemDescribe.isCreateable()) ||
                         (operation == DMLOperation.DML_UPDATE && !itemDescribe.isUpdateable()))) ||
                         (crudValue && item == 'phone')) {
                    System.debug(item + ' ' + sobjType.getDescribe().getName());
                    result.add(itemDescribe.getName());
                }
            }
        }
        return result;
    }

    /*--------------------------------------------------------------------------------------------*/
    /*                                                                                            */
    /* METHOD: validateCRUDPermissionForObjectTypes                                               */
    /*                                                                                            */
    /* This method checks sObjects for DML using.                                                 */
    /*                                                                                            */
    /* ARGUMENTS:                                                                                 */
    /* typeSet:             set of sObjects types                                                 */
    /* operation:           DML operation                                                         */
    /*                                                                                            */
    /*--------------------------------------------------------------------------------------------*/

    private void validateCRUDPermissionForObjectTypes(Set<SObjectType> types,
            DMLOperation operation) {

        // Declare local variables
        Boolean                         isException;
        Schema.DescribeSObjectResult    sobjDescribe;

        // checking sObjects for DML using
        for (SObjectType itemType : types) {
            isException = false;
            sobjDescribe = itemType.getDescribe();
            if ( (operation == DMLOperation.DML_UPDATE &&
                    !sobjDescribe.isUpdateable()) ||
                    (operation == DMLOperation.DML_DELETE &&
                     !sobjDescribe.isDeletable()) ||
                    (operation == DMLOperation.DML_INSERT &&
                     !sobjDescribe.isCreateable()) ||
                    (operation == DMLOperation.DML_UPSERT &&
                     !(sobjDescribe.isCreateable() &&
                       sobjDescribe.isUpdateable())) ||
                    (crudValue && itemType == Contact.getSObjectType())) {
                throw new SFDC_CRUD_Exception('CRUD Exception (' + operation.name() +
                                              ') in ' + sobjDescribe.getName());
            }
        }
    }

    /*--------------------------------------------------------------------------------------------*/
    /*                                                                                            */
    /* METHOD: upsertItems                                                                        */
    /*                                                                                            */
    /* This method upserts list of items.                                                         */
    /*                                                                                            */
    /* ARGUMENTS:                                                                                 */
    /* items:               list of sObjects                                                      */
    /*                                                                                            */
    /*--------------------------------------------------------------------------------------------*/

    private void upsertItems(List<SObject> items) {
        if (items.size() > 1) {
            upsert items;
        } else {
            upsert items.get(0);
        }
    }

}
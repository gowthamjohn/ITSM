import { LightningElement, api, track, wire } from "lwc";
import initialData from "@salesforce/apex/RelatedListController.initData";
import deleteRecord from "@salesforce/apex/RelatedListController.deleteRecord";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
export default class RelatedList extends LightningElement {
  @api name = "";
  @api sobjectApiName = "";
  @api relatedFieldApiName = "";
  @api sortedBy = "";
  @api columns = [];
  @api recordTypeInfoStr;
  @api fields = [];
  @api recordTypeFilter = "";
  @api recordId = "";
  @track viewAllBool = true;
  @track fieldsList;
  @track isMultipleRecType = false;
  @track isLoad = false;
  @track jsonDataRes = "";
  @track recordtypeId;
  @track isModalOpen = false;
  @track initData = {};
  @track isNew = false;
  @track recTypesName = [];
  @track numberOfRecordsForTitle = 0;
  @track records = [];
  @track tempRecordsList = [];
  @track choosedRecType;
  @track iconName;
  @track currentRow;
  @track sobjectLabel;
  @track isEmpty = false;
  @track sobjectLabelPlural;
  @track recordTypeInfo;
  @track parentRelationshipApiName;
  @track isEdit = false;
  @track offset = 0;
  @track customActions = [];
  @track columnsWithActions = [];
  @track isLoaded = true;

  connectedCallback() {
    this.initData = {
      fields: this.fields,
      relatedFieldApiName: this.relatedFieldApiName,
      numberOfRecords: 10,
      offset : this.offset,
      sortedDirection: "desc",
      sortedBy: this.sortedBy,
      sobjectApiName: this.sobjectApiName,
      recordId: this.recordId,
      recordTypeFilter: this.recordTypeFilter,
    };
    if (this.recordTypeInfoStr != null && this.recordTypeInfoStr != "") {
      this.recordTypeInfo = JSON.parse(this.recordTypeInfoStr);
    }
    // Get related records
    this.getRecords();
    this.initColumnsWithActions();
  }

  getRecords() {
    this.tempRecordsList = [];
    initialData({
      jsonData: JSON.stringify(this.initData),
    })
      .then((result) => {
        var jsonData = JSON.parse(result);
        this.tempRecordsList = this.tempRecordsList.concat(jsonData.records);
        var records = JSON.parse(JSON.stringify(this.tempRecordsList));
        // Setting the number of records count

        if (records.length == 0 || jsonData.records.length < this.initData.numberOfRecords) {
          this.viewAllBool = false;
          this.numberOfRecordsForTitle = records.length;
        } else {
          this.viewAllBool = true;
          this.numberOfRecordsForTitle = records.length;
        }

        // Set the parent record name in Link_Name property

        records.forEach((record) => {
          record.LinkName = "/" + record.Id;
          for (const col in record) {
            const curCol = record[col];
            if (typeof curCol === "object") {
              const newVal = curCol.Id ? "/" + curCol.Id : null;
              this.flattenStructure(record, col + "_", curCol);
              if (newVal !== null) {
                record[col + "_LinkName"] = newVal;
              }
            }
          }
        });
        this.records = records;
        if (records.length == 0) {
          this.isEmpty = true;
        } else {
          this.isEmpty = false;
        }
        this.iconName = jsonData.iconName;
        this.sobjectLabel = jsonData.sobjectLabel;
        this.sobjectLabelPlural = jsonData.sobjectLabelPlural;
        this.parentRelationshipApiName = jsonData.parentRelationshipApiName;
      })
      .catch((error) => {
        this.isEmpty = true;
        this.displayToast('Error',error,'error');
      });
  }
  flattenStructure(topObject, prefix, toBeFlattened) {
    for (const prop in toBeFlattened) {
      const curVal = toBeFlattened[prop];
      if (typeof curVal === "object") {
        this.flattenStructure(topObject, prefix + prop + "_", curVal);
      } else {
        topObject[prefix + prop] = curVal;
      }
    }
  }

  initColumnsWithActions() {
    // Initiate the DML operations

    var customActions = this.customActions;
    if (!customActions.length) {
      customActions = [
        { label: "Edit", name: "edit" },
        { label: "Delete", name: "delete" },
      ];
    }

    var columns = this.columns;
    var columnsWithActions = [];
    columnsWithActions.push(...columns);
    columnsWithActions.push({
      type: "action",
      typeAttributes: { rowActions: customActions },
    });
    this.columnsWithActions = columnsWithActions;
  }

  handleRowAction(event) {
    const action = event.detail.action.name;
    const row = event.detail.row;
    this.currentRow = row;
    switch (action) {
      case "edit":
        this.editRecord(row);
        break;
      case "delete":
        this.removeRecord(row);
        break;
    }
  }

  editRecord(row) {
    this.currentRow = row;
    this.isModalOpen = true;
    this.isEdit = true;
    this.isNew = false;
    this.isDelete = false;
  }
  removeRecord(row) {
    this.isModalOpen = true;
    this.isDelete = true;
    this.isEdit = false;
    this.isNew = false;
  }
  newRecordSuccess(event) {
    this.isLoaded = false;
    this.isNew = false;
    this.isModalOpen = false;
    this.displayToast('Record Created Successfully','','success');
    this.currentRow = null;
    this.getRecords();
    setTimeout(() => {
      this.isLoaded = true;
    }, 3000);
  }
  handleCreateRecord() {
    var recordTypes = this.recordTypeInfo;
    if (recordTypes && recordTypes.length > 0) {
      if (recordTypes.length == 1) {
        this.recordtypeId = recordTypes[0].Id;
        this.isNew = true;
      } else {
        var recNames = [];
        for (var i = 0; i < recordTypes.length; i++) {
          var obj = {};
          obj.label = recordTypes[i].Name;
          obj.value = recordTypes[i].Id;
          recNames.push(obj);
        }
        this.recTypesName = recNames;
        this.isMultipleRecType = true;
      }
    } else {
      this.isNew = true;
    }
    this.isModalOpen = true;
  }
  handleSubmit(event) {
    event.preventDefault(); // stop the form from submitting
    const fields = event.detail.fields;
    if (fields.citsm__Configuration_Item__c == null) {
      fields.citsm__Configuration_Item__c = this.recordId; // modify a field
      this.template.querySelector("lightning-record-form").submit(fields);
    } else {
      this.template.querySelector("lightning-record-form").submit(fields);
    }
  }
  handleRecType(event) {
    // Set the recordtype id for the new reccord , when it comes with multiple record types
    this.recordtypeId = event.detail.value;
  }

  createRecord() {
    if (this.recordtypeId != null) {
      this.isMultipleRecType = false;
      this.isNew = true;
    } else {
      this.displayToast('Please choose a recordtype to continue ',"",'error');
    }
  }

  closeModal() {
    this.isModalOpen = false;
    this.isDelete = false;
    this.isEdit = false;
    this.isNew = false;
    this.currentRow = null;
    this.isLoaded = true;
  }
  handleDelete() {
    this.isLoaded = false;
    deleteRecord({
      recordId: this.currentRow.Id,
    })
      .then((result) => {
        if (result) {
          this.displayToast('Record deleted','','success');
          this.currentRow = null;
          this.isModalOpen = false;
          this.isDelete = false;
          this.getRecords();
          setTimeout(() => {
            this.isLoaded = true;
          }, 3000);
        }
      })
      .catch((error) => {
        this.isLoaded = true;
        this.displayToast('Error',error,'error');
      });
  }

  recordSuccess(event) {
    this.isLoaded = false;
    this.isEdit = false;
    this.isModalOpen = false;
    this.displayToast('Success','Record Updated Succesfully','success');
    this.getRecords();
    setTimeout(() => {
      this.isLoaded = true;
      this.currentRow = null;
    }, 3000);
  }

  cancelOperation() {
    this.isModalOpen = false;
    this.isDelete = false;
    this.isEdit = false;
    this.isNew = false;
    this.currentRow = null;
    this.isLoaded = true;
  }

  handleGotoRelatedList() {
    this.isLoaded = false;
    this.initData.offset = this.offset + 10;
    this.offset = this.offset + 10;
    this.getRecords();
    setTimeout(() => {
      this.isLoaded = true;
    }, 5000);
  }

  errorOperation(event) {
    this.isLoaded = true;
    this.displayToast('Error',event.detail,'error');
  }


  displayToast(title , errorMsg , status){
    const evt = new ShowToastEvent({
      title: title,
      message: "" + this.filterErrors(errorMsg),
      variant: status,
    });
    this.dispatchEvent(evt);
  }

  // Seperate the error message from exception
  filterErrors(errors) {
    if (!Array.isArray(errors)) {
      errors = [errors];
    }

    return (
      errors
        // Remove null/undefined items
        .filter((error) => !!error)
        // Extract an error message
        .map((error) => {
          // UI API read errors
          if (Array.isArray(error.body)) {
            return error.body.map((e) => e.message);
          }
          // UI API DML, Apex and network errors
          else if (error.body && typeof error.body.message === "string") {
            return error.body.message;
          }
          // JS errors
          else if (typeof error.message === "string") {
            return error.message;
          }
          // Unknown error shape so try HTTP status text
          return error.statusText;
        })
        // Flatten
        .reduce((prev, curr) => prev.concat(curr), [])
        // Remove empty strings
        .filter((message) => !!message)
    );
  }
}
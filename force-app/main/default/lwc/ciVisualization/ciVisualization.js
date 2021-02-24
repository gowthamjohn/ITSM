import { LightningElement, api, wire, track } from "lwc";
import { loadScript } from "lightning/platformResourceLoader";
import d3js from "@salesforce/resourceUrl/D3V4";
import initRecords from "@salesforce/apex/CIVisualizationController.getRelatedInfoofCI";
import relatedRecs from "@salesforce/apex/CIVisualizationController.getRelatedTabsInfo";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { drawRadialTree } from "./ciVisualizationRadial";
import { drawTidyTree } from "./ciVisualizationTidy";
import getIncidentProblemCount from "@salesforce/apex/CIVisualizationController.getItemNotifierCount";

export default class CiVisualization extends LightningElement {
  @api recordId;
  @track isRadial = true;
  @track isTab = false;
  @track isLoaded = false;
  @track nodeName;
  @track recs = [];
  @track wholeRecords = [];
  @track selectedRecordId;
  @track selectedTab;
  @track objectName;
  @track fieldSetValues;
  @track fields;
  @track recordTypeFilter;
  @track nodeCount = 0;
  @track recordTypeInfo;
  @track scrolled = 0;
  @track goToButton = {};
  @track d3Track;

  connectedCallback() {
   window.addEventListener("scroll",this.onScroll.bind(this));
   window.addEventListener("resize",this.onPageZoom.bind(this));
    loadScript(this, d3js)
      .then(() => {
        this.getRecords(this.recordId);
      })
      .catch((error) => {
        this.isLoaded = true;
        this.displayToast("Error", error, "error");
      });
  }

  

  getRecords(recordId) {
    this.goToButton.bottom = true;
    this.goToButton.top = false;
    initRecords({
      conId: recordId,
    })
      .then((result) => {
        var data = JSON.parse(result);
        this.recs = data;
        this.isTab = false;
        var self = this;
        if (data.children.length > 21) {
          this.isRadial = false;
          this.tidyTree(null);
          setTimeout(() => {}, 3000);
        } else {
          this.isRadial = true;
          this.drawTree(null, self);
          setTimeout(() => {}, 3000);
        }
      })
      .catch((error) => {
        this.isLoaded = true;
        this.displayToast("Error", error, "error");
      });
  }

  changeView() {
    this.isLoaded = false;
    this.goToButton.bottom = false;
    this.goToButton.top = false;
    d3.select("svg").remove();
    if (this.template.querySelector(".tooltip")) {
      this.template.querySelector(".tooltip").remove();
    }
    if (this.isRadial) {
      this.isRadial = false;
      this.isTab = false;
      setTimeout(() => {
        this.tidyTree(null);
      }, 3000);
      setTimeout(() => {
        this.isLoaded = true;
      }, 3000);
    } else {
      this.isRadial = true;
      this.isTab = false;
      var self = this;
      setTimeout(() => {
        this.drawTree(null, self);
      }, 3000);
    }
    this.goToButton.bottom = true;
    this.goToButton.top = false;
  }

  drawTree(wholeRecs, self) {
    drawRadialTree(wholeRecs, self, d3);
  }

  tidyTree(wholeRecs) {
    drawTidyTree(wholeRecs, this, d3);
  }

  relatedList(recordId, param) {
    // Constructing array for data table format

    relatedRecs({
      itemId: recordId,
    })
      .then((result) => {
        var wholeRecs = JSON.parse(result);
        var list = JSON.parse(JSON.stringify(wholeRecs));
        for (var i = 0; i < list.length; i++) {
          var fieldSet = JSON.parse(list[i].fieldSet);
          for (var j = 0; j < fieldSet.length; j++) {
            fieldSet[j].type = fieldSet[j].type.toLowerCase();
            var typeAtt = {},
              lab = {};
            if (
              fieldSet[j].type == "reference" ||
              fieldSet[j].fieldName == "Name" ||
              fieldSet[j].fieldName == "CaseNumber"
            ) {
              fieldSet[j].type = "url";
              if (fieldSet[j].fieldName == "Name") {
                lab["fieldName"] = "Name";
                typeAtt["target"] = "_self";
                fieldSet[j].fieldName = "LinkName";
              } else if (fieldSet[j].fieldName == "CaseNumber") {
                lab["fieldName"] = "CaseNumber";
                typeAtt["target"] = "_self";
                fieldSet[j].fieldName = "LinkName";
              } else {
                if (fieldSet[j].objName.includes("__c")) {
                  lab["fieldName"] =
                    fieldSet[j].objName.replace("__c", "__r") + "_Name";
                  fieldSet[j].fieldName =
                    fieldSet[j].objName.replace("__c", "__r") + "_LinkName";
                } else {
                  lab["fieldName"] = fieldSet[j].objName + "_Name";
                  fieldSet[j].fieldName = fieldSet[j].objName + "_LinkName";
                }
                typeAtt["target"] = "_self";
              }

              typeAtt["label"] = lab;
              fieldSet[j].typeAttributes = typeAtt;
            }

            if (fieldSet[j].type == "datetime") {
              fieldSet[j].type = "date";
              fieldSet[j].typeAttribute = {
                day: "numeric",
                month: "short",
                year: "numeric",
                hour: "2-digit",
                minute: "2-digit",
                second: "2-digit",
                hour12: true,
              };
            }
            if (fieldSet[j].type != "reference") {
              if (fieldSet[j].fieldName.includes(".")) {
                fieldSet[j].fieldName = fieldSet[j].fieldName.replace(".", "_");
              }
            }
          }

          list[i].fieldSet = JSON.stringify(fieldSet);
        }
        param.wholeRecords = list;
        param.selectedRecordId = recordId;
        this.setFocus("Incident", param);
      })
      .catch((error) => {
        this.isLoaded = true;
        this.displayToast("Error", error, "error");
      });
  }

  tabSelect(event) {
    this.isLoaded = false;
    this.isTab = false;
    this.selectedTab = event.target.label;
    var selectedTab = this.selectedTab;
    this.setFocus(selectedTab, this);
  }

  // set focus in selected tab

  setFocus(blockName, param) {
    var wholeRecords = param.wholeRecords;
    this.wholeRecords = param.wholeRecords;
    this.selectedTab = blockName;
    for (var i = 0; i < wholeRecords.length; i++) {
      if (wholeRecords[i].blockName == blockName) {
        var fields = JSON.parse(wholeRecords[i].fieldSet);
        var recs = JSON.parse(wholeRecords[i].tableRows);
        var fieldsList = wholeRecords[i].fields;
        this.objectName = wholeRecords[i].objectName;
        this.recordTypeInfoStr = wholeRecords[i].recordTypeInfo;
        this.recordTypeFilter = wholeRecords[i].recordTypeFilterStr;
        this.fieldSetValues = fields;
        this.fields = fieldsList;
      }
    }
    this.isTab = true;
    this.selectedRecordId = param.selectedRecordId;

    setTimeout(() => {
      this.isLoaded = true;
    }, 3000);
  }

  //Updating colors for selected nodes

  treeUpdate(data, treeData) {
    // Updating node colors
    var self = this;
    var wholeRecs = treeData;
    var clickedNodeId = data.id;
    if (clickedNodeId && data.data.level) {
      wholeRecs.data.isClicked = false;
      for (var i = 0; i < wholeRecs.children.length; i++) {
        if (wholeRecs.children[i].id == data.parent.id) {
          wholeRecs.children[i].data.children[0].isClicked = true;
        } else {
          wholeRecs.children[i].data.children[0].isClicked = false;
        }
      }
    } else {
      for (var i = 0; i < wholeRecs.children.length; i++) {
        wholeRecs.children[i].data.children[0].isClicked = false;
      }
      wholeRecs.data.isClicked = true;
    }
    this.drawTree(wholeRecs, self);
  }

  tidyTreeUpdate(data, treeData) {
    var wholeRecs = treeData;
    var clickedNodeId = data.id;
    var isChildChecked = true;
    if (clickedNodeId) {
      wholeRecs.data.isClicked = false;
      for (var j = 0; j < wholeRecs.children.length; j++)
        for (var i = 0; i < wholeRecs.children[j].children.length; i++) {
          if (wholeRecs.children[j].children[i].id == data.id) {
            wholeRecs.children[j].children[i].data.isClicked = true;
            isChildChecked = false;
          } else {
            wholeRecs.children[j].children[i].data.isClicked = false;
          }
        }
    }
    if (isChildChecked) {
      for (var j = 0; j < wholeRecs.children.length; j++)
        for (var i = 0; i < wholeRecs.children[j].children.length; i++) {
          wholeRecs.children[j].children[i].data.isClicked = false;
        }
      wholeRecs.data.isClicked = true;
    }
    this.tidyTree(wholeRecs);
  }

  getPopOverInfo(itemId, callback) {
    getIncidentProblemCount({
      configItem: itemId,
    })
      .then((result) => {
        
        var info = {};
        info.svg = d3;
        info.result = result;
        callback(info);
      })
      .catch((error) => {
        this.isLoaded = true;
        this.displayToast("Error", error, "error");
      });
  }

  displayToast(title, errorMsg, status) {
    const evt = new ShowToastEvent({
      title: title,
      message: "" + this.filterErrors(errorMsg),
      variant: status,
    });
    this.dispatchEvent(evt);
  }
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

  onScroll() {
    this.scrolled = window.scrollY;
    if (this.scrolled > 200) {
      this.goToButton.bottom = false;
      this.goToButton.top = true;
    }else{
      this.goToButton.bottom = true;
      this.goToButton.top = false;
    }
}

onPageZoom(){
  d3.select("svg").remove();
  var self = this;
  var data = this.recs;
  this.isLoaded = false;
  if (data.children.length > 21) {
    this.isRadial = false;
    this.tidyTree(null);
    setTimeout(() => {}, 3000);
  } else {
    this.isRadial = true;
    this.drawTree(null, self);
    setTimeout(() => {}, 3000);
    }
}

goToTop() {
  window.scrollTo({ top: 0, behavior: 'smooth' });
}
goToBottom(){
  window.scrollTo({ top: 10000, behavior: 'smooth' });
}
}
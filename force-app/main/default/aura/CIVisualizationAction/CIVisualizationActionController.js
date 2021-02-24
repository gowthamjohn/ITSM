({
	doInit : function(component,event,helper) {
		
        var navigateEvent = $A.get("e.force:navigateToComponent");
        
        navigateEvent.setParams({
            componentDef  : "c:ciVisualization",
            componentAttributes: {
            recordId : component.get("v.recordId")
        	}
        });
      
        navigateEvent.fire();
	}
})
using Toybox.Application as App;
using Toybox.WatchUi;
using Toybox.System as Sys;
using Toybox.Time;
//using Toybox.FitContributor as Fit;

class BGTrackerView extends WatchUi.SimpleDataField {

	var counter = 0l;
	var changeInterval = 3; //swap info every 2s
	
    // Set the label of the data field here.
    function initialize() {
        SimpleDataField.initialize();
        label = "Glucose";
        
        //read last values from the Object Store
        var temp=App.getApp().getProperty(OSDATA);
        if(temp!=null) {bgdata=temp;}
    }

	function trendFromDirection(direction) {
		var dirSwitch = { "SingleUp" => "Up",
                          "DoubleUp" => "UP",
                          "FortyFiveUp" => "Up",
                          "FortyFiveDown" => "Down",
                          "SingleDown" => "Down",
                          "DoubleDown" => "DOWN",
                          "Flat" => "Flat",
                          "NONE" => "NONE" };

		if (dirSwitch.hasKey(direction)) { direction = dirSwitch[direction];}
		return direction;
	}

    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info) {
        var fullStr = "";
        var bgStr = "";
        var str="";
        
        
        if (!Sys.getDeviceSettings().phoneConnected) {return "!BT  ";}
        
        // BG 
       	if ((bgdata != null) && bgdata.hasKey("bg")) {
       		bgStr = bgdata["bg"];
       		fullStr = fullStr + bgdata["bg"].toString();
       	}
       	
       	//elapsed time
       	if ((bgdata != null) && bgdata.hasKey("mills") && (bgdata["mills"] != 0) ) {
    		var mills = bgdata["mills"];
    		var sampleTime = new Time.Moment(mills / 1000);
    		var elapsedMinutes = Math.floor(Time.now().subtract(sampleTime).value() / 60);
    		var elapsed = elapsedMinutes.format("%d") + "'";
       		fullStr = fullStr + " " + elapsed;	
       	}
       	
       	//trend
       	if ((bgdata != null) && bgdata.hasKey("direction")) {
       		fullStr = fullStr + " " + trendFromDirection(bgdata["direction"]);
       	
       	}
       	
       	if ((counter % (changeInterval*2)) < changeInterval) {str = bgStr;}
       	else {str=fullStr;}
         counter++;
         return str;	
    }

}
using Toybox.Application as App;
using Toybox.Background;
using Toybox.System as Sys;
using Toybox.Attention;
using Toybox.Time;
using Toybox.Time.Gregorian as Calendar;

// info about whats happening with the background process
var canDoBG=false;
// background data, shared directly with appview
var bgdata;
var lastReading = null;
var lowAlert = 0l;
// keys to the object store data
var OSDATA="osdata";


var inBackground=false;

(:background)
class BGTrackerApp extends App.AppBase {
	var myView;

	function getTime() {
		var now = Sys.getClockTime();
        var ts = now.hour+":"+now.min.format("%02d");
        return ts;
  	}

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {	
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    	if(!inBackground) {Background.deleteTemporalEvent();}
    }

    // Return the initial view of your application here
    function getInitialView() {
    	
    	var url = (App.getApp()).getProperty("Url");
    	lowAlert = (App.getApp()).getProperty("lowAlert");
    	
        var data = {};
    	data["str"] = "";
		data["bg"] = 0;
		data["direction"] = "";
		data["mills"] = 0;
		data["delta"] = 0;
		App.getApp().setProperty(OSDATA,data); 
    	
    	//debug
    	Sys.println("URL = "+(App.getApp()).getProperty("Url") + " " + getTime());
    	
    	if((Toybox.System has :ServiceDelegate) && (url != null) && !url.equals("")) {
    		canDoBG=true;
        	Background.registerForTemporalEvent(new Time.Duration(5 * 60));
    	}
    	else {
    		Sys.println("Invalid URL or background not availabe");
    	}
    	     	
        return [ new BGTrackerView() ];
        
    }

	// defines what shall be executed when the event occurrs
    function getServiceDelegate(){
    	inBackground=true;
        return [new BGTrackerBG()];
    }
	
	// pass data back to the main process when getServiceDelegate has exit
    function onBackgroundData(data) {
    	// check that data is valid here...
    	if ((data != null) && data.hasKey("mills") && (data["mills"] > 0)) {
    		
    		// check time sync
    	 	var now = Sys.getClockTime();
    		var ts = now.hour.format("%02d") + ":" + now.min.format("%02d");
    		Sys.println("Now: " + ts);
    		  		
    		// Sample Time
    		var sampleMoment = new Time.Moment(data["mills"] / 1000);
    		sampleMoment = sampleMoment.add(new Time.Duration(Sys.getClockTime().timeZoneOffset));	   		    		
    		var sampleTime = Calendar.utcInfo(sampleMoment, Time.FORMAT_SHORT);
    		var timeString = Lang.format("$1$:$2$", [sampleTime.hour, sampleTime.min.format("%02d")]);
     		Sys.println("SampleTime: " + timeString);
    		
    		// calculate offset
    		var sTime = new Time.Moment(data["mills"] / 1000);
    		var elapsedMinutes = Math.floor(Time.now().subtract(sTime).value() / 60);
    		Sys.println("TimeOffset: " + elapsedMinutes.format("%02d"));  			
    	
    		if (lastReading != null) {	
    			var TBR = Math.floor(Time.now().subtract(lastReading).value() / 60);
    			Sys.println("TBR: " + TBR.format("%02d"));
    		}
    		
    		lastReading = new Time.Moment(Time.now().value());
    		
    	}
        
        if ((Attention has :vibrate) && (Attention has :playTone)) {
    		var bg = 0l;
    		if (data["bg"].toNumber() < lowAlert) {
    			Attention.playTone(Attention.TONE_LOUD_BEEP);
    			var vibeData = [new Attention.VibeProfile(50, 5000)]; // On for 5 seconds
    			Attention.vibrate(vibeData);
    		}
    	}
    	
        bgdata=data;
        App.getApp().setProperty(OSDATA,bgdata);
        
    }

}
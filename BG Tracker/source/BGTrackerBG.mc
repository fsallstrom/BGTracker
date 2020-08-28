using Toybox.Background;
using Toybox.Communications;
using Toybox.System as Sys;

// The Service Delegate is the main entry point for background processes
// our onTemporalEvent() method will get run each time our periodic event
// is triggered by the system.

(:background)
class BGTrackerBG extends Toybox.System.ServiceDelegate {
	
	function initialize() {
		Sys.ServiceDelegate.initialize();
	}
	
	function getTime() {
		var now = Sys.getClockTime();
        var ts = now.hour+":"+now.min.format("%02d");
        return ts;
  	}
	
    function onReceive(responseCode, data) {
    	// callback function for the HTTP response
    	var bgdata = {};
    	
    	// do lots of stuff here...
    	bgdata["str"]=data;
        bgdata["elapsedMills"] = "elapsedMills";
        bgdata["bg"] = "bg";
        bgdata["direction"] = "direction";
        bgdata["delta"] = "delta";
    	
    	Background.exit(bgdata);
    }
    
    function onReceiveNS(responseCode, data) {
    	// callback function for the HTTP response from Nightscout
    	var bgdata = {};
    	
    	//debug
    	//Sys.println(data.toString());
    	
    	if (responseCode != 200 ) {return;}
    	
    	var bg = 0;
    	var direction = "";
    	var delta = ""; 
    	var mills = 0l;
    	
    	// set BG
    	if (data.hasKey("bgnow") && data["bgnow"].hasKey("sgvs") && data["bgnow"]["sgvs"][0].hasKey("scaled")) {
    		bg = data["bgnow"]["sgvs"][0]["scaled"];
    		//Sys.println("bg = "+bg.toString());
    	}
    	
    	// set elapsed time
    	if (data.hasKey("bgnow") && data["bgnow"].hasKey("mills")) {
    		mills = data["bgnow"]["mills"];
    		//Sys.println("ElapsedMills = "+ mills.toString());
    	}
    	
    	// set direction
    	if (data.hasKey("bgnow") && data["bgnow"].hasKey("sgvs") && data["bgnow"]["sgvs"][0].hasKey("direction")) {
    		direction = data["bgnow"]["sgvs"][0]["direction"];
    		//Sys.println("Direction = "+data["bgnow"]["sgvs"][0]["direction"]);
    	}
    	
    	// set delta
    	if (data.hasKey("delta") && data["delta"].hasKey("display")) {
    		delta = data["delta"]["display"].toString();
    		//Sys.println("delta = "+delta);
    	}	
		
		bgdata["str"] = bg.toString() + " " + direction + " " + delta;
		bgdata["bg"] = bg;
		bgdata["direction"] = direction;
		bgdata["mills"] = mills;
		bgdata["delta"] = delta;
	
		//Sys.println(bgdata.toString());
		
    	Background.exit(bgdata);
    }
    
    function onTemporalEvent() {
    	
    	var url = (Application.getApp()).getProperty("Url");
    	var server = (Application.getApp()).getProperty("Server");
    	if((url != null) && !url.equals("")) {
    		
    		if (server.equals("Nightscout")) {
    			url = url + "/api/v2/properties/bgnow,rawbg,delta";
    			Communications.makeWebRequest(url, {"format" => "json"}, {}, method(:onReceiveNS));
    		
    		}
     		
     		else if (server.equals("Spike")) {
     		     		
     			url = url + "/sgv.json?count=3";	           
    			var params = {};
    			var options = { :method => Communications.HTTP_REQUEST_METHOD_GET, 
    							:headers => { "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED},
    							:responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON 
    			};
    			Communications.makeWebRequest(url, params, options, method(:onReceive));
    		}
    		
    			
		}
	}
    

}

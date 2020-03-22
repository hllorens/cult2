// Check for media needs
if(typeof images === 'undefined'){var images = [];}
if(typeof sounds === 'undefined'){var sounds = [];}

var QueryString=get_query_string();
var debug=false;
var user_bypass=undefined;
if(QueryString.hasOwnProperty('debug') && QueryString.debug=='true') debug=true;
if(QueryString.hasOwnProperty('user') && QueryString.user!='') user_bypass=QueryString.user;

// responsive tunings
prevent_scrolling();

var is_app=is_cordova();
if(is_app){
    if (!window.cordova) alert("ERROR: Running cordova without including cordova.js!");
	document.addEventListener('deviceready', onDeviceReady, false);
}else{
    onDeviceReady();
}

function onDeviceReady() {
    console.log('userAgent: '+navigator.userAgent+' is_app: '+is_app);
	check_internet_access();
    console.log('end index.js');
}

// window.onload = function () does not work for apps
window.onload = function () { 
	if(debug) console.log("win.onload");
	//var splash=document.getElementById("splash_screen");
	//if(splash!=null && (ResourceLoader.lazy_audio==false || ResourceLoader.not_loaded['sounds'].length==0)){ splash.parentNode.removeChild(splash); }
}
import std.stdio;
import std.net.curl;
import std.json;
import std.process;
import std.file;
import std.datetime;
import core.stdc.stdlib;
import std.algorithm;
import std.array;
import std.getopt;
import std.conv;

string docFileName = "New Document From toDoc";
bool newFile = true;
bool overwrite = false;

int main(string[] args){
	
	try
	{
		auto helpInformation = getopt(args,
								  "fileName|f","The name of the Google Doc you want to write to.",&docFileName,
								  "newFile|n","Creates a new Google Doc.",&newFile,
								  "overwrite|o","Overwrites the Google Doc instead of appending.",&overwrite,
								  "clearTokens|c","Deletes all stored OAuth tokens",&removeConfigFile);
		if (helpInformation.helpWanted)
	{
		defaultGetoptPrinter("\ntoDoc options",
							 helpInformation.options);
		return 0;
	}
	
	}
	catch(std.conv.ConvException err){
		writeln("Invalid arguments use --help for options.");
		return 0;
	}
	
	string oAuthToken = loadConfigFile();
	string[] cmdInput = stdin.byLineCopy(KeepTerminator.yes).array();
	writeToDoc(docFileName, newFile, overwrite, cmdInput, oAuthToken);
	return 0;
}

// get Full Qualified File Name
char[] getFQFileName(){
	string homePathVer;	
    version (Windows){homePathVer = "APPDATA";}
	version(Posix){homePathVer = "HOME";}
	char[] homePath = cast(char[])environment[homePathVer];
    return homePath ~ "/.toDoc";

}

void removeConfigFile(){
	char[] filename = getFQFileName();
	if (exists(filename)!=0){
		remove(filename);
	}
	core.stdc.stdlib.exit(0);
}

string loadConfigFile(){
  string cId = "1052420377433-jk4m14g58idknqq4qc3b0k04ethvdvvb.apps.googleusercontent.com"; //TODO: Add Client ID
	string cSecret = "N8C-4ikhc2N3gljsyQ-lQWt4"; //TODO: Add Client Secret	
	string redirect_uri = "urn:ietf:wg:oauth:2.0:oob";	
	string authUrl = "https://accounts.google.com/o/oauth2/v2/auth";
	string scopes = "https://www.googleapis.com/auth/drive https://www.googleapis.com/auth/documents"; 
  char[]  filename  = getFQFileName();
  JSONValue oTokens;
	string oAuthToken;

	if (exists(filename)!=0) { //OAuth tokens exist
        char[] tokenFile = cast(char[])read(filename);  //Read the stored token info
		oTokens = parseJSON(tokenFile);
		auto expireTime =  SysTime.fromSimpleString(oTokens["expires_in"].str());
		auto now = Clock.currTime();

		if(expireTime < now){

			auto postData = "client_id="~cId~
				"&client_secret="~cSecret~
				"&refresh_token=" ~ oTokens["refresh_token"].str() ~ 
				"&grant_type=refresh_token";
	        oAuthToken = getOAToken(postData, filename, oTokens["refresh_token"].str());
		}else{
			oAuthToken = oTokens["access_token"].str();
		}
	} else { // no OAuth tokens. Lets get them.
		string url = authUrl ~ "?" ~ "scope=" ~ scopes ~ "&redirect_uri=" ~ redirect_uri ~ "&response_type=code&client_id=" ~ cId;
		writef("Please post this URL in your Browser.\n\n" ~ url ~ "\n\nEnter response code here:");
		string oCode = readln();
		auto postData = "code="~oCode~"&client_id="~cId~"&client_secret="~cSecret~"&redirect_uri=" ~ redirect_uri ~ "&grant_type=authorization_code";
	    oAuthToken = getOAToken(postData, filename, null);
	}
  return oAuthToken;
}

string getOAToken(string postData, char[] fileName, string refreshToken){ //pass the refresh token as this isnt returned. Leave null for intial request.
 	string oAuthToken;

	string requestUrl = "https://www.googleapis.com/oauth2/v4/token";
	//exchange code for token
	auto http = HTTP(requestUrl);
	version(Windows){         
		//http.handle.set(CurlOption.ssl_verifypeer, 0); // not the right answer but the below does not work
		//char[] caBundle = cast(char[])read(homePath~"/cacert.pem");
		//http.caInfo(caBundle);
	}

	http.setPostData(postData, "application/x-www-form-urlencoded");
	http.onReceive = (ubyte[] data)
	{	
		JSONValue res = parseJSON(cast(string)data);
		if("error" in res){
			writeln("Invalid Code\n");
			core.stdc.stdlib.exit(-1);  // the memories leak?
		}else{
			auto cTime = Clock.currTime();
			cTime += dur!"seconds"(res["expires_in"].integer);
			res["expires_in"] = cTime.toSimpleString();
			if(refreshToken != null){
				res.object["refresh_token"] = refreshToken;
			}
			std.file.write(fileName,res.toString());
			oAuthToken = res["access_token"].str();

		}
		return data.length;
	};
	http.perform(); 

	return oAuthToken;
}

void writeToDoc(string docName, bool newFile, bool overwrite, string[] data, string oAuthToken){
	writeln("Writing to doc...");

    string cApi_Id = "MHEZo1FLHLcDoMtMRqDWs40MLm9v2IJHf"; //TODO: Add Execution API Key here	
	string fetchUrl = "https://script.googleapis.com/v1/scripts/"~ cApi_Id ~":run";

	string[] params = [docName,to!string(newFile),to!string(overwrite),join(data)];
	JSONValue postData =  ["function":"toDoc", "devMode":"true"]; //TODO: Change devMode as desired
	postData.object["parameters"] = params;
	auto http = HTTP(fetchUrl);
	
	version(Windows){         
		//http.handle.set(CurlOption.ssl_verifypeer, 0); // not the right answer but the below does not work
		//char[] caBundle = cast(char[])read("./cacert.pem");
		//http.caInfo(caBundle);
	}
    
	http.setPostData(postData.toString(), "application/json");	
	http.addRequestHeader("Authorization", "Bearer "~oAuthToken);
	
	http.onReceive = (ubyte[] data)
	{	
      JSONValue res = parseJSON(cast(string)data);
      if("error" in res){
      	try{writeln(res["error"].object["details"].array[0].object["errorMessage"].str);}
      	catch(Exception e){writeln(cast(string)data);}
      }
      if("response" in res){
      	writeln("done");
      	writeln(res["response"].object["result"].str);
      }

	  return data.length;
	};
	http.perform();
}

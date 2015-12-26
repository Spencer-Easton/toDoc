# toDoc
#####Command line tool to write data to a Google Doc

This simple command line tool allows you to write directly from a console to a Google Doc.  The tool has two parts, the client application written in the D language and a small Google Apps Script.  


#####Setup
1) Create a new app script. Add the code from the src/GAS-Source directory.  
2) Publish it using the Execution API.  [Check out the docs for more info.](https://developers.google.com/apps-script/guides/rest/api)  
3) Open the scripts Dev console. Create a set of OAuth Credentials using the `Other` type.  
4) Add the clientId, Client Secret, and the Execution API Id (the scripts Project Key) to the toDoc.d. Look for the TODOs in the code.  
5) Compile the client `dmd toDoc.d`.  
6) The first time you run the client you will have to authenticate.   
  
#####Using toDoc  
toDoc options  
-f    --fileName The name of the Google Doc you want to write to. (Default: New Document From toDoc)  
-n     --newFile Creates a new Google Doc.  (Default: true)  
-o   --overwrite Overwrites the Google Doc instead of appending. (Default: false)  
-c --clearTokens Deletes all stored OAuth tokens  
-h        --help This help information.  
  
Examples  
You can either pipe the the data in:  
  
    cat file.txt | toDoc --fileName="file.txt"  
  
  
    syslog -C | toDoc --newFile=false --fileName="System Log"

  
or type it in  

    toDoc --fileName="New Doc"  
    This is some text  
    I am typing in at the console  
    This is what I want to be saved to my doc  
    ctl-d on Posix, ctl-z on Windows to write the file  
 


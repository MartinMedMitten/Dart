library create_user;
import 'ServerCommunicator.dart';
import 'dart:html';
import 'dart:async';
import 'dart:core';
import 'package:widget/effects.dart';

ServerCommunicator serverCommunicator;

Future initServerCommunicator(){
  serverCommunicator  = new ServerCommunicator(querySelector("#statusBar"));
  return serverCommunicator.connect();
}

InputElement usernameTextbox;
InputElement passwordTextbox;
InputElement emailTextbox;
InputElement securityTextbox;
InputElement createButton;
SpanElement errorMessage;
DivElement createUserDiv;

void main() {
  usernameTextbox = querySelector("#username");
  passwordTextbox = querySelector("#password");
  emailTextbox = querySelector("#email");
  securityTextbox = querySelector("#security");
  createButton = querySelector("#createbutton");
  errorMessage = querySelector("#errorMessage");
  createUserDiv = querySelector("#createUserDiv");
  
  createUserDiv.style.display = "block";
  initServerCommunicator().then((result) {
    if (result){
      createButton.onClick.listen((_) {
        var username = usernameTextbox.value;
        var password = passwordTextbox.value;
        var email = emailTextbox.value;
        String security = securityTextbox.value;
        var secRev = new String.fromCharCodes(security.codeUnits.reversed.toList());
        if (username.length < 3 || password.length < 3 || email.length < 5 || secRev != username){
          errorMessage.innerHtml = "Username/password must be more than 2 characters";
          ShowHide.show(errorMessage, effect: new FadeEffect(), duration: 400, effectTiming: EffectTiming.linear);  
          errorMessage.style.display = "inline block";
        }
        
        serverCommunicator.sendCreateUser(username, password, email).then((_){
          errorMessage.innerHtml = "Username create successfully";
          ShowHide.show(errorMessage, effect: new FadeEffect(), duration: 400, effectTiming: EffectTiming.linear);
        }).catchError((msg) {
          errorMessage.innerHtml = msg;
          ShowHide.show(errorMessage, effect: new FadeEffect(), duration: 400, effectTiming: EffectTiming.linear);
        });
      });
    }
  });

  
 
  
}

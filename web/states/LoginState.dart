part of othello_state;

class LoginState implements State{
  
  DivElement loginDiv;
  DivElement playAreaDiv;
  InputElement loginButton;
  InputElement usernameTextBox;
  InputElement passwordTextBox;
  StreamSubscription loginButtonSub;
  SpanElement wrongLogin;
  
  void Init(){
    loginDiv = querySelector("#loginDiv");
    playAreaDiv = querySelector("#playArea");
    loginButton = querySelector("#loginButton");
    usernameTextBox = querySelector("#username");
    passwordTextBox = querySelector("#password");
    wrongLogin = querySelector("#wrongLogin");
    
    loginButtonSub = loginButton.onClick.listen(TryLogin);
    
    ShowHide.hide(playAreaDiv, effect: new FadeEffect(), duration: 400, effectTiming: EffectTiming.linear).then((_) {
      ShowHide.show(loginDiv, effect: new FadeEffect(), duration: 400, effectTiming: EffectTiming.linear);  
    });
    
    
    usernameTextBox.value = "MartinMedMitten";
    passwordTextBox.value = "cpcpcp";
    
    
  }
  void Leave(){
    loginButtonSub.cancel();
    
  }
  
  void TryLogin(MouseEvent event) {
   
    serverCommunicator.TryLogin(usernameTextBox.value, passwordTextBox.value).then((result){
      if (result){
        ShowHide.hide(loginDiv, effect: new FadeEffect(), duration: 400, effectTiming: EffectTiming.linear).then((_) {
          Leave();
          state = new LobbyState(usernameTextBox.value);
          state.Init();
        });    
      }
      else{
        usernameTextBox.value = "";
        passwordTextBox.value = "";
        ShowHide.show(wrongLogin, effect: new FadeEffect(), duration: 400, effectTiming: EffectTiming.linear);
      }
    });
  }
}
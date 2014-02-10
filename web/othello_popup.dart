 library othello_popup;
 import 'dart:html';
 import 'dart:async';
 import 'package:widget/effects.dart'; 
 
 typedef void OnPopupCloseFunction();
 
 
 class OthelloPopup{
  DivElement popup;
  List<OnPopupCloseFunction> onPopupCloseFunction = new List<OnPopupCloseFunction>();
  StreamSubscription okButton;
  OthelloPopup(this.popup){
     okButton = querySelector("#popupOkButton").onClick.listen((e) => ClosePopup());
  }
  
  
  DisplayPopup(String msg, {int ms: 1200}) {
    ShowHide.show(popup, effect: new FadeEffect(), duration: 400, effectTiming: EffectTiming.linear);
    var future = new Future.delayed(new Duration(milliseconds: ms));
    future.asStream().listen((e) => ClosePopup());
    popup.children.first.innerHtml = msg;
  }
  
  ClosePopup()
  {
    ShowHide.hide(popup, effect: new FadeEffect(), duration: 400, effectTiming: EffectTiming.linear);
    okButton.cancel();
    
    for (var x in onPopupCloseFunction){
      x();
    }
    
    onPopupCloseFunction.clear();
  }
}
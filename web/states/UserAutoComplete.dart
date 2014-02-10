library user_auto_complete;
import 'dart:html';
import 'dart:async';
import 'package:widget/effects.dart'; 

typedef Future<String> ParseAutoComplete(String text);
typedef Future<List<String>> GetAutoComplete(String q, int limit);

typedef void OnSelected(String value);

class UserAutoCompleteControl{
  ParseAutoComplete parseFunction;
  GetAutoComplete autocompleteFunction;
  OnSelected onSelectedCallback;
  
  TextInputElement inputElement;
  InputElement  okButtonElement;
  InputElement  cancelButtonElement;
  DivElement div;
  DivElement userAutoCompleteDataDiv;
  
  
  UserAutoCompleteControl(this.parseFunction, this.autocompleteFunction, this.div, this.onSelectedCallback){
    inputElement = div.querySelector(".autocompleteInput");
    okButtonElement = div.querySelector(".okButton");
    cancelButtonElement = div.querySelector(".cancelButton");
    userAutoCompleteDataDiv = div.querySelector("#userAutoCompleteData");
    
    cancelButtonElement.onClick.listen((_) => Hide());
    inputElement.onKeyUp.listen(autoComplete);
    okButtonElement.onClick.listen((_) => parse());
  }
  
  autoComplete(KeyboardEvent e) {
    if (e.keyCode == 27){
      this.Hide();
      return;
    }
    
    if (inputElement.value.length == 0){
      userAutoCompleteDataDiv.children.clear();
      return;
    }
    
    autocompleteFunction(inputElement.value, 5).then((List<String> l) {
      userAutoCompleteDataDiv.children.clear();
      var ul = new UListElement();
      
      for (var user in l){
        LIElement ny = new LIElement();
        ny.text = user;
        ul.children.add(ny);
      }
      
      userAutoCompleteDataDiv.children.add(ul);
    });
  }
  
  parse() {
    parseFunction(inputElement.value).then((String parsed) {
      if (parsed != null){
        onSelectedCallback(parsed);
      }
    });
  }
    
  Future Show(){
    return ShowHide.show(div, effect: new FadeEffect(), duration: 400, effectTiming: EffectTiming.linear).then((_){
      inputElement.focus();
    });
  }
  
  Future Hide(){
    return ShowHide.hide(div, effect: new FadeEffect(), duration: 400, effectTiming: EffectTiming.linear);
  }
  
  
  
  
  
  
}
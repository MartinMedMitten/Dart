library completer_queue;
import 'dart:async';

class CompleterQueue{
  final List<Completer> _completers = new List<Completer>();
  
  popAndFinish(dynamic d){
    if (_completers.length == 0){
      throw "Error empty completerQ"; 
    }
    var completer = _completers[0];
    
    _completers.removeAt(0);
    
    completer.complete(d);
  }
  
  popAndFinishError(dynamic d){
    if (_completers.length == 0){
      throw "Error empty completerQ"; 
    }
    var completer = _completers[0];
    
    _completers.removeAt(0);
    
    completer.completeError(d);
  }
  
  //Alias for popAndFinish
  complete(dynamic d){
    popAndFinish(d);
  }
  completeError(dynamic d){
    popAndFinishError(d);
  }
  
  Future add(){
    return enque(new Completer());
  }
  
  Future enque(Completer c){
    _completers.add(c);
    return c.future;
  }
  
}
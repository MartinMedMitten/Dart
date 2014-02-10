library othello;

import 'states/OthelloState.dart';


void main() {
  
  initOthelloStates();
//  state = new PlayState(querySelector("#mainCanvas"));
  state = new LoginState();
  state.Init();
  //state.StartGame();
  
}








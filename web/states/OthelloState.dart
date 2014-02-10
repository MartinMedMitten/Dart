library othello_state;
import 'dart:html';
import 'dart:async';
import 'package:widget/effects.dart'; 
import '../PlayingBoard.dart';
import '../ServerCommunicator.dart';
import 'UserAutoComplete.dart';
import '../othello_popup.dart';
part 'LoginState.dart';
part 'LobbyState.dart';
part 'PlayState.dart';

State state;
ServerCommunicator serverCommunicator;

void initOthelloStates(){
  serverCommunicator  = new ServerCommunicator(querySelector("#statusBar"));
  serverCommunicator.connect();
  serverCommunicator.opponentMadeMove.listen((gameId) => updateGame(gameId));
  serverCommunicator.challengeStatusChanged.listen((_) => updateChallenges());
}

updateChallenges() {
  if(state is LobbyState){
    _refreshLobbyState(state);
  }
}

void updateGame(String gameId) {
  if (state is NetworkPlayState){
    NetworkPlayState s = state;
    if (s.gameId == gameId){
      s.Refresh();
    }
  }
  else if(state is LobbyState){
    _refreshLobbyState(state);
  }
}
_refreshLobbyState(LobbyState s){
  s.refresh();
}

abstract class State {
  void Init();
  void Leave();
}
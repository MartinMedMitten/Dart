library ServerCommunicator;
import 'dart:convert';
import 'dart:async';
import 'dart:html';
import 'utility/completerqueue.dart';

typedef void HandleGameListFunction(String gameId, String player1, String player2, int status, int winner, int nextPlayer, int turn);
typedef void HandleChallengeListFunction(String challenger, String opponent, int id);
typedef void HandleLoadGameFunction(List l);


class ServerCommunicator{
  static const Duration RECONNECT_DELAY = const Duration(milliseconds: 500);
  bool connectPending = false;
  WebSocket webSocket;
  DivElement statusbar;
  Completer loginCompleter;
  
  CompleterQueue autoCompleter;
  CompleterQueue parseCompleter;
  CompleterQueue createUserCompleter;
  HandleGameListFunction getFinishedGamesListener;
  HandleGameListFunction getGamesListener;
  HandleChallengeListFunction getChallengeListener;
  HandleLoadGameFunction loadGameListener;
  StreamController opponentMadeMoveController = new StreamController.broadcast();
  StreamController challengeStatusChangedController = new StreamController.broadcast();
  Stream get opponentMadeMove => opponentMadeMoveController.stream;
  Stream get challengeStatusChanged => challengeStatusChangedController.stream;
  
  ServerCommunicator(this.statusbar){
    autoCompleter = new CompleterQueue();
    parseCompleter = new CompleterQueue();
    createUserCompleter = new CompleterQueue();
  }
  
  Future<bool> connect() {
    Completer completer = new Completer();
    connectPending = false;
    webSocket = new WebSocket('ws://${Uri.base.host}:9223/ws');
    webSocket.onOpen.first.then((_) {
      onConnected();
      completer.complete(true);
      webSocket.onClose.first.then((_) {
        print("Connection disconnected to ${webSocket.url}");
        onDisconnected();
      });
    });
    webSocket.onError.first.then((Event e) {
      if (!completer.isCompleted){
        completer.complete(false);
      }
      print(e);
      print("Failed to connect to ${webSocket.url}. "
            "Please run bin/server.dart and try again.");
      onDisconnected();
    });
    return completer.future;
  }

  void onConnected() {
    setStatus('');
    
    webSocket.onMessage.listen((e) {
      onMessage(e.data);
    });
  }

  void onDisconnected() {
    if (connectPending) return;
    connectPending = true;
    setStatus('Disconnected - start \'bin/server.dart\' to continue');
    
    new Timer(RECONNECT_DELAY, connect);
  }
  
  setStatus(String s) {
    statusbar.innerHtml = s;
  }
  
  
  void onMessage(data) {
    var json = JSON.decode(data);
    var response = json['type'];
    setStatus(response);
    if (response == "opponent_made_move"){
      print(0/0);
    }
    switch (response) {
      case 'login':
        LoginHandler(json);
        break;
      case 'get_games':
        GetGamesHandler(json);
        break;
      case 'get_finished_games':
        GetFinishedGamesHandler(json);
        break;
      case 'get_games_challenge':
        GetChallengeHandler(json);
        break;
      case 'move':
        LoadGameHandler(json);
        break;
      case 'parse':
        ParseHandler(json);
        break;
      case 'autocomplete':
        AutocompleteHandler(json);
        break;
      case 'create_user_response':
        CreateUserResponseHandler(json);
        break;
      case 'opponent_made_move':
        opponentMadeMoveHandler(json);
        break;
      case 'game_status_change':
        gameStatusChangeHandler();
        break;
      default:
        print("Invalid response: '$response'");
    }
  }
  
 
  
  opponentMadeMoveHandler(dynamic json) {
    var gameId = json['gameid'];
    opponentMadeMoveController.add(gameId);
  }
  
  gameStatusChangeHandler(){
    challengeStatusChangedController.add(null);
  }
  
  CreateUserResponseHandler(dynamic json) {
    var success = json['success'];
    var message = json['message'];
    
    if (!success){ //METODO jag fattar inte riktigt varför detta inte fungerar...
      createUserCompleter.completeError(message);
    }
    
    createUserCompleter.complete(success);
  }
  
  ParseHandler(dynamic json) {
    var string = json['user'];
    parseCompleter.complete(string);
  }
  
  AutocompleteHandler(dynamic json) {
    var users = json['users'];
    autoCompleter.complete(users);
  }
  
  LoadGameHandler(json){
    if (loadGameListener == null) return;
    loadGameListener(json['moves']);
  }
  
  void GetChallengeHandler(json){
    var challenger = json['challenger'];
    var opponent = json['opponent'];
    int id = json['id'];
    
    getChallengeListener(challenger, opponent, id);
    
  }
  
  
  
  void GetGamesHandler(json){

    var gameid = json['gameid'];
    var winner = json['winner'];
    var status = json['status'];
    var nextplayer = json['nextplayer'];
    var player1 = json['player1'];
    var player2 = json['player2'];
    var turn = json['turn']; //metodo skicka med de
    getGamesListener(gameid,player1,player2,status,winner, nextplayer, turn);
  }
  
  GetFinishedGamesHandler(dynamic json) {
    var gameid = json['gameid'];
    var winner = json['winner'];
    var status = json['status'];
    var nextplayer = json['nextplayer'];
    var player1 = json['player1'];
    var player2 = json['player2'];
    var turn = json['turn']; //metodo skicka med de
    getFinishedGamesListener(gameid,player1,player2,status,winner, nextplayer, turn);
  }
  
  String _sessionId;
  String _username;
  
  
  
  void LoginHandler(json){
    if (json['success']){ 
      if (loginCompleter != null)
      {
        this._sessionId = json['session_id'];
        this._username = json['username'];
        loginCompleter.complete(true);
      }
    }
    else{
      loginCompleter.complete(false); //METODO lite mer text kanske... eller nåt.
    }
  }
  ClearAndAddGetGamesListener(HandleGameListFunction func) {
    getGamesListener = func;
  }
  ClearAndAddGetFinishedGamesListener(HandleGameListFunction func) {
    getFinishedGamesListener = func;
  }
  ClearAndAddChallengeListener(HandleChallengeListFunction func) {
    getChallengeListener = func;
  }
  ClearAndAddLoadGameListener(HandleLoadGameFunction func) {
    loadGameListener = func;
  }
  Future<bool> TryLogin(String username, String password){
    //METODO egentligen måste man få nån slags session guid tillbaks
    this._sessionId = null;
    this._username = null;
    var request = {
                   'request': 'login',
                   'username': username,
                   'password': password
                   };
    loginCompleter = new Completer();
    //METODO CLEANUP
    webSocket.send(JSON.encode(request));
    return loginCompleter.future;
  }
  

  //"games" , "challenges", "finished_games"
  Get(String type) {
    var request = {
                   'request': 'get_$type',
                   'username': _username,
                   'session_id' : _sessionId
    };
    webSocket.send(JSON.encode(request));
  }
  
  LoadGame(String gameId) {
    var request = {
                   'request': 'load_game',
                   'gameid' : gameId,
                   'username': _username,
                   'session_id' : _sessionId
                   };
    webSocket.send(JSON.encode(request));
  }
  
  SendMove(int xTile, int yTile, String gameId) {
    var request = {
                   'request': 'do_move',
                   'gameid' : gameId,
                   'x' : xTile,
                   'y' : yTile,
                   'username': _username,
                   'session_id' : _sessionId
                   };
    webSocket.send(JSON.encode(request));
  }
  
  SendChallenge(String opponent) {
    var request = {
                   'request' : 'challenge',
                   'opponent' : opponent,
                   'username' : _username,
                   'session_id' : _sessionId
    };
    webSocket.send(JSON.encode(request));
  }
  
  Future<List<String>> AutoCompleteUser(String q, int limit){
    var request = {
                   'request' : 'autocomplete_user',
                   'q' : q,
                   'limit' : limit,
                   'username' : _username,
                   'session_id' : _sessionId
    };
    
    webSocket.send(JSON.encode(request));
    
    return autoCompleter.add();
  }
  
  Future<String> ParseUser(String q){
    var request = {
                   'request' : 'parse_user',
                   'q' : q,
                   'username' : _username,
                   'session_id' : _sessionId
    };
    webSocket.send(JSON.encode(request));
    return parseCompleter.add();
  }
  
  
  SendChallengeStatusChange(int id, bool challengeAccepted) {
    var request = {
                   'request' : 'challenge_status',
                   'id': id,
                   'accept' : challengeAccepted,
                   'username' : _username,
                   'session_id' : _sessionId
    };
    webSocket.send(JSON.encode(request));
  }
  
  Future<bool> sendCreateUser(String username, String password, String email) {
    var request = {
                   'request' : 'register_user',
                   'username': username,
                   'password' : password,
                   'email' : email,
    };
    webSocket.send(JSON.encode(request));
    return createUserCompleter.add();
  }
}
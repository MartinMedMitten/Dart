part of othello_server;

Future HandleChallenge(dynamic json, WebSocket webSocket) {
  String challenger = json['username'];
  String opponent = json['opponent'];
  
  return repo.AddChallenge(challenger.toLowerCase(), opponent.toLowerCase());
}

Future DeclineChallenge(int challengeId){ 
  return repo.DeclineChallenge(challengeId);
}
Future AcceptChallenge(int challengeId){ 
  Completer completer = new Completer();

  repo.AcceptChallenge(challengeId).then((_) {
    repo.GetChallenge(challengeId).then((Challenge p) {
      if (p.Status == 2){
        CreateGame(p.Challenger.toLowerCase(), p.Opponent.toLowerCase()).then((z) {
          completer.complete();
        });  
      }
      else{
        completer.complete();
      }
    });
  });
  
  
  return completer.future;
}

HandleChallengeStatusUpdate(dynamic json, WebSocket webSocket) {
  int id = json['id'];
  bool accept = json['accept'];
  String username = json['username'];
  repo.GetChallenge(id).then((Challenge c) => _handleChallengeStatusUpdate(accept, id, username, webSocket, c.Challenger));
}

void _handleChallengeStatusUpdate(bool accept, int id, String username, WebSocket webSocket, String opponent) {
  if (accept){
    AcceptChallenge(id).then((_) {
      //GetGamesFromJsonAndReply(username, webSocket);
      relayGameStatusUpdate(opponent); //HÄR ÄR DET NÅGOT KONSTIGT!
      relayGameStatusUpdate(username); //HÄR ÄR DET NÅGOT KONSTIGT!
    });
  }
  else{
    DeclineChallenge(id).then((_) { 
      //GetGamesFromJsonAndReply(username, webSocket);
      relayGameStatusUpdate(opponent); //HÄR ÄR DET NÅGOT KONSTIGT
      relayGameStatusUpdate(username); //HÄR ÄR DET NÅGOT KONSTIGT
    
    });
  }
}

Future<Game> CreateGame(String user1, String user2){
  var completer = new Completer();
  var game = new Game(user1, user2);
  repo.AddGame(game).then((p) => completer.complete(game));
  return completer.future;
}

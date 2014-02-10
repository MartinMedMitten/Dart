part of othello_server;



void relayMove(String username, String gameId){
  if (userHandler.ContainsUser(username.toLowerCase())){
    WebSocket socket = userHandler.GetSocket(username.toLowerCase());

    var response =  {
                     'type' : 'opponent_made_move',
                     'gameid' : gameId
    };
    socket.add(JSON.encode(response));
  }
}
void relayGameStatusUpdate(String username){
  if (userHandler.ContainsUser(username.toLowerCase())){
    WebSocket socket = userHandler.GetSocket(username.toLowerCase());

    var response =  {
                     'type' : 'game_status_change'
    };
    socket.add(JSON.encode(response));
  }
}
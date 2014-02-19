part of othello_server;

class UserHandler{
  
  Map<String, WebSocket> webSocketMap = {};
  
  bool ContainsUser(String username) => webSocketMap.containsKey(username);
  WebSocket GetSocket(String username) => webSocketMap[username];
  
  void loginFromJsonAndReply(json, webSocket){
    String username = json['username'];
    username = username.toLowerCase();
    var password = json['password'];
    
    _login(username, password).then((Communication c) {
      var response = {
                      'type' : 'login',
                      'success' : !c.Error,
                      'text' : c.Message,
                      'session_id' : c.Session,
                      'username' : username
      };
    
      if (!c.Error){
        webSocketMap[username] = webSocket;     
      }
      
      webSocket.add(JSON.encode(response));  
      
    }).catchError((_) { 
      var response = {
                      'type' : 'login',
                      'success' : false,
                      'text' : "Unknown error"
      };    
      webSocket.add(JSON.encode(response));
    }) ;
  }
  
  handleRegisterUser(dynamic json, WebSocket webSocket) {
    var username = json['username'];
    var password = json['password'];
    var mail = json['email'];
    
    _registerUser(username, password, mail).then((communication) {
      var response =  {
                       'type' : 'create_user_response',
                       'success' : !communication.Error,
                       'message' : communication.Message
      };
      webSocket.add(JSON.encode(response));
    });
  }
  
  handleParseUser(dynamic json, WebSocket webSocket) {
    var q = json['q']; //METODO de måste kunna bli null här alltså....
    repo.UserAutocomplete(q, 1).then((p){
      
      var response =  {
                       'type' : 'parse',
                       'user' : p.length > 0 ? p[0] : null
      };
      webSocket.add(JSON.encode(response));
    });
  }

  handleAutcompleteUser(dynamic json, WebSocket webSocket) {
    String q = json['q'];
    var limit = json['limit'];

    repo.UserAutocomplete(q, limit).then((p){
      var response =  {
                       'type' : 'autocomplete',
                       'users' : p
      };
      webSocket.add(JSON.encode(response));
    });
  }
  
  
  Future<Communication> _login(String username, String password){
    var sessionId = uuid.v4();
    return repo.Login(username.toLowerCase(), password, sessionId).then((p) => p ? new Communication.withSession("ok", false, sessionId) : new Communication("not ok", true));
  }
  
  Future<Communication> _registerUser(String username, String password, String mail){
    var completer = new Completer();  
    
    repo.RegisterUser(username, password, mail).then((value){
      completer.complete(new Communication("User created ok!", false));
    }).catchError((err) { completer.complete(new Communication(err, true)); });
    
    return completer.future;
  }
  
}
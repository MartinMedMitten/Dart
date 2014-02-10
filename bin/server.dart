library othello_server;
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart' show Logger, Level, LogRecord;
import '../web/PlayingBoard.dart';
import 'DataRepository.dart';

import 'package:http_server/http_server.dart' as http_server;
import 'package:route/server.dart' show Router;
import 'package:uuid/uuid.dart';
part 'userhandler.dart';
part 'challengehandler.dart';
part 'relaydata.dart';

Uuid uuid = new Uuid();

final Logger log = new Logger('Othello');

Game game;
DataRepository repo = new DataRepository("127.0.0.1", 3306, "root", "cpcpcp", "othello");
var board = new PlayingBoard(8,8,null);
UserHandler userHandler = new UserHandler();

void handleWebSocket(WebSocket webSocket) {
  log.info('New web-socket connection');

  webSocket
    .map((string) => JSON.decode(string))
    .listen((json) {
       
      var request = json['request'];
      log.warning(request);
      
      if (request == 'login' || request == 'register_user') {
        HandleRequest(request, json, webSocket);
       
      }
      else {
        validate(json['session_id'],json['username']).then((valid){
          if (valid){
            HandleRequest(request, json, webSocket);
          }
        });
      }
      
      
    }, onError: (error) {
      log.warning('Bad WebSocket request');
    });
}

Future<bool> validate(String sessionId, String username) {
  return repo.validate(sessionId, username);
}

void HandleRequest(request, json, WebSocket webSocket) {
  switch (request) {
    case 'login':
      userHandler.LoginFromJsonAndReply(json,webSocket);
      break;
    case 'do_move':
      _doMoveFromJsonAndReply(json, webSocket);
      break;
    case 'get_games':
      GetGamesFromJsonAndReply(json['username'], webSocket);
      break;
    case 'get_challenges':
      GetChallengesFromJsonAndReply(json['username'], webSocket);
      break;
    case 'get_finished_games':
      GetFinishedGamesFromJsonAndReply(json['username'], webSocket);
      break;
    case 'load_game':
      LoadGameFromJsonAndReply(json, webSocket);
      break;
    case 'challenge_status':
      HandleChallengeStatusUpdate(json, webSocket);
      break;
    case 'challenge':
      HandleChallenge(json, webSocket).then((_) {
        relayGameStatusUpdate(json['opponent']);
        relayGameStatusUpdate(json['username']);
      });
      break;
    case 'autocomplete_user':
      userHandler.HandleAutcompleteUser(json, webSocket);
      break;
    case 'parse_user':
      userHandler.HandleParseUser(json, webSocket);
      break;
    case 'register_user':
      userHandler.HandleRegisterUser(json, webSocket);
      break;
    default:
      log.warning("Invalid request '$request'.");
  }
}



LoadGameFromJsonAndReply(json, webSocket){
  var gameId = json['gameid'];
  repo.GetGame(gameId).then((Game g) {
    repo.GetMoves(g).then((moves) {
      List items = new List(); 
      for (Move m in moves){
        items.add({
          'turn' : m.Turn,
          'x' : m.X,
          'y' : m.Y
          });
      }
      var response =  {
                       'type' : 'move',
                       'gameid' : gameId,
                       'moves' : items
                      };
      webSocket.add(JSON.encode(response));
      
    });
  });
}
GetFinishedGamesFromJsonAndReply(String username, WebSocket webSocket) {
  username = username.toLowerCase();
  const int FINISHED = 2; 
  repo.GetGames(username, FINISHED).then((List<Game> games) {
    _sendGames(games, webSocket, FINISHED);
  });
}

GetChallengesFromJsonAndReply(String username, WebSocket webSocket) {
  repo.GetChallenges(username, 0).then((List<Challenge> challenges) {
    _sendChallenges(challenges, username, webSocket);
  });
}
void GetGamesFromJsonAndReply(String username, webSocket){
  username = username.toLowerCase();
  const int ONGOING = 0;
  repo.GetGames(username, 0).then((List<Game> games) {
    _sendGames(games, webSocket, ONGOING);
  });
}

void _sendGames(List<Game> games, webSocket, int status) {
  String type = status == 0 ? "games" : "finished_games";
  
  for (var game in games){
    
    var response =  {
                     'type' : 'get_$type',
                     'gameid' : game.Id,
                     'nextplayer' : game.NextPlayer,
                     'status' : game.Status,
                     'winner' : game.Winner,
                     'player1' : game.Player1,
                     'player2' : game.Player2,
                     'turn' : game.Turn
    };
    
    
    webSocket.add(JSON.encode(response));
  }
}

void _sendChallenges(List<Challenge> challenges, String username, webSocket) {
  for (var challenge in challenges.where((e) => e.Opponent.toLowerCase() == username)){
    var response =  {
                     'type' : 'get_games_challenge',
                     'challenger' : challenge.Challenger,
                     'opponent' : challenge.Opponent,
                     'id' : challenge.Id
                    };
    
    webSocket.add(JSON.encode(response));
  }
}

void _doMoveFromJsonAndReply(json, webSocket){
  var gameid = json['gameid'];
  var x = json['x'];
  var y = json['y'];
  var username = json['username'];
  DoMove(gameid, x,y, username);
}

void startupWebserver() {
  // Set up logger.
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  var buildPath = Platform.script.resolve('../build').toFilePath();
  if (!new Directory(buildPath).existsSync()) {
    log.severe("The 'build/' directory was not found. Please run 'pub build'.");
    return;
  }

  int port = 9223;  // TODO use args from command line to set this

  HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, port).then((server) {
    log.info("Search server is running on "
             "'http://${server.address.address}:$port/'");
    var router = new Router(server);

    // The client will connect using a WebSocket. Upgrade requests to '/ws' and
    // forward them to 'handleWebSocket'.
    router.serve('/ws')
      .transform(new WebSocketTransformer())
      .listen(handleWebSocket);

    // Set up default handler. This will serve files from our 'build' directory.
    var virDir = new http_server.VirtualDirectory(buildPath);
    // Disable jail-root, as packages are local sym-links.
    virDir.jailRoot = false;
    virDir.allowDirectoryListing = true;
    virDir.directoryHandler = (dir, request) {
      // Redirect directory-requests to index.html files.
      var indexUri = new Uri.file(dir.path).resolve('index.html');
      virDir.serveFile(new File(indexUri.toFilePath()), request);
    };

    // Add an error page handler.
    virDir.errorPageHandler = (HttpRequest request) {
      log.warning("Resource not found ${request.uri.path}");
      request.response.statusCode = HttpStatus.NOT_FOUND;
      request.response.close();
    };

    // Serve everything not routed elsewhere through the virtual directory.
    virDir.serve(router.defaultStream);

    // Special handling of client.dart. Running 'pub build' generates
    // JavaScript files but does not copy the Dart files, which are
    // needed for the Dartium browser.
    router.serve("/othello.dart").listen((request) {
      Uri clientScript = Platform.script.resolve("../web/othello.dart");
      virDir.serveFile(new File(clientScript.toFilePath()), request);
    });
  });
}

void main(){
  startupWebserver();
}

Future<Game> LoadGameToPlayingBoard(String id){
  Completer completer = new Completer();
  board.RestartLevel(8,8);
  repo.GetGame(id).then((Game g) {
    game = g;
    
    repo.GetMoves(g).then((moves) {
      for (Move m in moves){
        
        board.SetPiece(m.X, m.Y);
      }
      completer.complete(g);
    });
  });
  
  return completer.future;
}

/*Future<List<Game>> GetGames(String username){
  return repo.GetGames(username);
}*/


void DoMove(String gameId, int x, int y, String username){
  String opponent;
  LoadGameToPlayingBoard(gameId).then((Game game) {
    opponent = game.otherPlayer(username);
    return MakeMoveOnBoard(x,y);
  }).then((_) {
    relayMove(opponent, gameId);
  }); 
}

Future MakeMoveOnBoard(int x, int y){
  var completer = new Completer();
  var turn = board.CurrentTurn;
  board.SetPiece(x, y);
  var status = board.IsGameOver() ? Game.FINISHED : Game.STARTED;
  var winner = status == Game.FINISHED ? board.winner : null;
  
  repo.DoMove(game, turn , x, y).then(
      (_)  => repo.UpdateGame(game.Id, board.CurrentPlayer, status, winner)).then(
      (_)  => completer.complete()); 

  return completer.future;
}
Future<List<Move>> MovesAfter(int turn, String gameId){
  //Den här returnerar då till klienten alla moves efter de man senast kände till
  //på så vis kan klienten rita upp dem. När man startar upp klienten så börjar den på 1 och hämtar alla där efter, men då ritar man inte upp mer än de sista draget, eller ja de drag
  var completer = new Completer();
  repo.GetMovesById(gameId).then((List<Move >moves){
    completer.complete(moves.where((m) => m.Turn > turn).toList());
  });
  
  return completer.future;
}









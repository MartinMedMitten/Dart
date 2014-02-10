library datarepository;
import 'package:sqljocky/sqljocky.dart';
import 'dart:async';
import 'dart:math';
import 'package:uuid/uuid.dart';
var uuid = new Uuid();

class Communication{
  String Message;
  bool Error;
  String Session;
  Communication(this.Message, this.Error);
  Communication.withSession(this.Message, this.Error, this.Session);
}

class Challenge{
  String Challenger;
  String Opponent;
  DateTime PointInTime;
  int Id;
  int Status;
  Challenge.fromDb(this.Id, this.Challenger, this.Opponent, this.PointInTime, this.Status);
}


class Game{
  static const int NOT_STARTED = 0; 
  static const int STARTED = 1; 
  static const int FINISHED = 2; 
  
  String Id;
  String Player1;
  String Player2;
  int Status;
  int NextPlayer;
  int Winner;
  int Turn;
  Game(this.Player1, this.Player2){
    Id = uuid.v4();
  }
  Game.fromDb(this.Id, this.Player1, this.Player2, this.Status, this.NextPlayer, this.Winner, this.Turn);
  
  otherPlayer(String username) {
    return username == Player1 ?  Player2 :  Player1;
  }
}

class Move{
  String GameId;
  int Turn;
  int X;
  int Y;
  Move(this.Turn, this.X, this.Y);
}


class DataRepository{
  
  ConnectionPool _pool;
  var rng = new Random();
  
  DataRepository(String server, int port, String user, String password, String database){
    _pool = new ConnectionPool(host: server, port: port, user: user, password: password, db: database, max: 5);
  }
  
  Future AddGame(Game game){
    var beginner = rng.nextInt(2) + 1;
    
    var player1 = (beginner == 1) ? game.Player1 : game.Player2;
    var player2 =  game.otherPlayer(player1); 
    
    return _pool.query("insert game select '${game.Id}','${player1}','${player2}', 0, $beginner, -1").then((p){
      true;
    }).catchError((zz) {print(zz);});
  }
  

  Future UpdateGame(String gameId, int nextPlayer, int status, int winner){
    //Metodo validering att båda spelarna finns. Status på gamet, det kan ju vara bara en utmaning
    if (winner == null)
      winner = -1;
    return _pool.query("update game set nextPlayer='$nextPlayer', status='$status', winner='$winner' where Id = '$gameId'").then((p){
      true;
    }).catchError((zz) {print(zz);});
  }
  
  
  Future AddChallenge(String challenger, String opponent){
    return _pool.query("insert challenge(challenger, opponent) select '${challenger}','${opponent}'");
  }
  
  Future DeclineChallenge(int id){
    return _pool.query("update challenge set status = 1 where id = $id");
  }
  
  Future AcceptChallenge(int id){
    return _pool.query("update challenge set status = 2 where id = $id");
  }
 

  Future<Challenge> GetChallenge(int id){
    var completer = new Completer();
    _pool.query("select id, challenger, opponent, point_in_time, status from challenge where id =$id").then((p) {
      p.listen((row) {
        completer.complete(new Challenge.fromDb(row[0], row[1], row[2], row[3], row[4]));
      });
    });
    return completer.future;
  }
  
  
  Future<List<Challenge>> GetChallenges(String playerId, int status){
    var completer = new Completer();
    _pool.query("select id, challenger, opponent, point_in_time, status from challenge where (challenger='$playerId' or opponent ='$playerId') and status = $status").then((p) {
        List<Challenge> challenges = new List<Challenge>();
        p.listen((row) {
          challenges.add(new Challenge.fromDb(row[0], row[1], row[2], row[3], row[4]));
        }).onDone(() => completer.complete(challenges));
    });
    
    return completer.future;
  }
  
  Future<Game> GetGame(String id){
    var completer = new Completer();
    
    _pool.query("select game.*, max(turn) as turn from game left join move on game.id = move.game_id where game.id = '$id' group by game_id").then((result)  {
      result.listen((row) {
        completer.complete(new Game.fromDb(row[0], row[1], row[2],row[3], row[4], row[5], row[6]));
      });
    });
    return completer.future;
  }
  
  Future<List<Game>> GetGames(String player, int status){
    var completer = new Completer();
    List<Game> games = new List<Game>();
    var sql = "select game.*, max(ifnull(turn,0)) as turn FROM game LEFT JOIN move on game.id = move.game_id " +
              " WHERE status=$status and (player1 = '$player' or player2 = '$player')" +
              " group by game_id";
    
    _pool.query(sql).then((result)  {
      result.listen((row) {
        games.add(new Game.fromDb(row[0], row[1], row[2],row[3], row[4], row[5], row[6]));
      }).onDone(() { 
          completer.complete(games); 
        });
      
    });
    return completer.future;
  }
  
  
  Future DoMove(Game game,int turn, int x, int y){
    return _pool.query("insert move select '${game.Id}','$turn','$x', '$y'").then((p){
      true;
    }).catchError((zz) {print(zz);});
  }
  
  Future<List<Move>> GetMoves(Game game){
    return GetMovesById(game.Id);
  }
  Future<List<Move>> GetMovesById(String Id){
    var completer = new Completer();
    List<Move> moves = new List<Move>();
    _pool.query("select turn,x,y from move where game_id = '$Id' order by turn").then((Results result)  {
      Future s = result.forEach((row) {
        moves.add(new Move(row[0], row[1], row[2]));
      });
      
      s.then((_) => completer.complete(moves));
      
    });
    return completer.future;
  }
  
  Future RegisterUser(String username, String password, String mail){
    return UserExists(username).then((userNameExists) {
      if (!userNameExists){
        EmailExists(mail).then((emailExists) {
          if (!emailExists){
            _pool.query("insert user select '$username','$password','$mail', null").then((res) {
                res.listen((row) {
              });
            });     
          }
          else{
            throw("Email already exists");
          }
        });
      }
      else{
        throw("Username already exists");
      }
    });
  }
  
  Future<bool> Login(String username, String password, String sessionId){
    return Exists("select 1 from user where username ='$username' and password='$password'")
        .then((p) {
          if (p){
            Completer completer = new Completer();
            
            _pool.query("update user set session_id='$sessionId' where username ='$username'").then(
                (_) {
                  completer.complete(p);
                });
            
            return completer.future;
          }
          else {
            return false;
          }
        });
  }
  
  Future<bool> validate(String sessionId, String username) {
    return Exists("select 1 from user where username ='$username' and session_id='$sessionId'");
  }
  
  Future<bool> UserExists(String userName){
    return Exists("select 1 from user where username = '$userName'");
  }
  Future<bool> EmailExists(String email){
    return Exists("select 1 from user where email = '$email'");
  }
  
  Future<bool> Exists(String query){
    Completer<bool> completer = new Completer<bool>();
    var sqlFuture = _pool.query(query);
    
     sqlFuture.then((result)  {
      result.length.then((res) {
         completer.complete( res > 0);
      });
    });
    
    return completer.future;
  }
  
  Future<List<String>> UserAutocomplete(String s, int limit){
    Completer<List<String>> completer = new Completer<List<String>>();
    List<String> users = new List<String>();
    
   _pool.query("select username from user where username like '$s%' order by username limit $limit").then((result)  {
     result.listen((row) {
       users.add(row[0]);
     }).onDone(() => completer.complete(users));
     
   }); 
   
   return completer.future;
  }
  
}
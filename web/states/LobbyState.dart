part of othello_state;

class LobbyState implements State{
  DivElement lobbyDiv;
  DivElement gameList;
  DivElement challengeList;
  DivElement finishedList;
  DivElement challengeAutoCompleteDiv;
  InputElement challengeButton;
  
  UserAutoCompleteControl userAutoCompleteControl;
  OthelloPopup _popup;
  
  String Username;
  LobbyState(this.Username);
  
  void Init(){
    
    lobbyDiv = querySelector("#lobbyDiv");
    gameList = querySelector("#gameList");
    challengeList = querySelector("#challengeList");
    finishedList = querySelector("#finishedList");
    challengeButton = querySelector("#challengeButton");
    challengeAutoCompleteDiv = querySelector("#challengeAutoComplete");
    var popupDiv = querySelector("#popup");
    
    _popup = new OthelloPopup(popupDiv);
    
    userAutoCompleteControl = new UserAutoCompleteControl(serverCommunicator.ParseUser, 
        serverCommunicator.AutoCompleteUser, 
        challengeAutoCompleteDiv, 
        onChallengeMade);
    
    challengeButton.onClick.listen((_) => displayChallengeDiv());
    
    InitGameList();
    ShowHide.show(lobbyDiv, effect: new FadeEffect(), duration: 400, effectTiming: EffectTiming.linear);  
  }
  
  displayChallengeDiv() {
    userAutoCompleteControl.Show();
  }
  
  InitGameList() {
    clearLists();
    
    serverCommunicator.ClearAndAddGetGamesListener(AddGameToGameList);
    serverCommunicator.ClearAndAddGetFinishedGamesListener(AddGameToFinishedGameList);
    serverCommunicator.ClearAndAddChallengeListener(AddChallengeToGameList);
    serverCommunicator.Get("games");
    serverCommunicator.Get("challenges");
    serverCommunicator.Get("finished_games");
  }

  void clearLists() {
    gameList.children.clear();
    challengeList.children.clear();
    finishedList.children.clear();
  }
  
  void AddChallengeToGameList(String challenger, String opponent, int id){
    var challenge = new DivElement();
    var iAmChallenger = challenger.toLowerCase() == Username.toLowerCase();
    var myOpponenent = (iAmChallenger) ? opponent : challenger;
    challenge.children.add(new ParagraphElement()..innerHtml = "CHALLENGE $myOpponenent");
    challenge.classes.add("challenge");

    
    if (!iAmChallenger){
      setUpAcceptButton(id, challenge);
    }
    
    setUpRefuseButton(id, challenge);
    
    challenge.style.display = "none";
    challengeList.children.add(challenge);
    ShowHide.show(challenge, effect: new FadeEffect(), duration: 400, effectTiming: EffectTiming.linear);
  }

  void setUpRefuseButton(int id, DivElement challenge) {
    var refuseButton = new ButtonElement();
    refuseButton.text = "REFUSE";
    refuseButton.onClick.listen((_) { 
      serverCommunicator.SendChallengeStatusChange(id, false);
      //clearLists();
    });
    
    challenge.children.add(refuseButton);
  }

  void setUpAcceptButton(int id, challenge) {
    var okButton = new ButtonElement();
    okButton.text = "ACCEPT";
    okButton.onClick.listen((_) { 
      serverCommunicator.SendChallengeStatusChange(id, true);
      //clearLists();
    });
    
    challenge.children.add(okButton);
  }
  
  void AddGameToGameList(gameid,player1,player2,status,winner, nextplayer, int turn){
    bool isPlayer1 = player1.toLowerCase() == Username.toLowerCase();
    var opponent = isPlayer1 ? player2 : player1;
    bool myturn = isPlayer1  ? nextplayer == 1 : nextplayer != 1;
    _addGameToGameList(opponent, gameid,turn, myturn, isPlayer1);
  }
  void AddGameToFinishedGameList(gameid,player1,player2,status,int winner, nextplayer, int turn){
    bool isPlayer1 = player1.toLowerCase() == Username.toLowerCase();
    var opponent = isPlayer1 ? player2 : player1;
    
    bool iWon = (winner == 1 && isPlayer1) || (winner == 2 && !isPlayer1);
    
    String result = iWon ? "Yeah you won!" : "$opponent won :(";
    
    bool myturn = isPlayer1  ? nextplayer == 1 : nextplayer != 1;
    finishedList.children.add(new DivElement()..innerHtml =result);
    //_addGameToGameList(opponent, gameid,turn, myturn, isPlayer1);
  }
  
  _addGameToGameList(String opponent, String id, int turn, bool myturn, bool player1){
    var newGame = new DivElement();
    newGame.children.add(new ParagraphElement()..innerHtml = opponent);
    newGame.children.add(new SpanElement()..innerHtml = 
        "Turn: ${turn.toString()} (${myturn ? 'your' : 'opponents'} turn)");
    newGame.children.add(new HiddenInputElement()..value = id);
    
    newGame.classes.add(myturn ? "myTurnGame" : "opponentTurnGame");
    newGame.style.display = "none";
    gameList.children.add(newGame);
    ShowHide.show(newGame, effect: new FadeEffect(), duration: 400, effectTiming: EffectTiming.linear);
    newGame.onClick.listen((_) => gameClick(id, player1 ? 1 : 2));
  }
  
  void Leave(){
  
  }
  
  
  void gameClick(String id, int player) {
    ShowHide.hide(lobbyDiv, effect: new FadeEffect(), duration: 400, effectTiming: EffectTiming.linear).then((_) {
      Leave();
      var backToLobbyButton = querySelector("#backToLobby");
      var refreshButton = querySelector("#refreshButton");
      state = new NetworkPlayState(querySelector("#mainCanvas"), id, Username, player, backToLobbyButton, refreshButton);
      state.Init();
    });
  }
  
  void onChallengeMade(String value) {
    serverCommunicator.SendChallenge(value);
    userAutoCompleteControl.Hide();
    _popup.DisplayPopup("$value has been challenged!");
    clearLists();
  }
  
  refresh() {
    clearLists();
    serverCommunicator.Get("games");
    serverCommunicator.Get("challenges");
    serverCommunicator.Get("finished_games");
  }
}
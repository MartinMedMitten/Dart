part of othello_state;



class NetworkPlayState extends PlayState{
  String gameId;
  String username;
  int player;
  Element lobbyButton;
  Element refreshButton;
  DivElement thisPlayerName;
  StreamSubscription lobbyButtonSubscription;
  StreamSubscription refreshButtonSubscription;
  bool _finishedLoading;
  
  
  
  
  NetworkPlayState(CanvasElement canvas, this.gameId, this.username, this.player, this.lobbyButton, this.refreshButton) :super(canvas) {
    Refresh();
    lobbyButtonSubscription = lobbyButton.onClick.listen((_) => _goToLobby());
    refreshButtonSubscription = refreshButton.onClick.listen((_) => Refresh());
    thisPlayerName = querySelector("#thisPlayerName");
    thisPlayerName.innerHtml = this.username;
  }
  
  _doMove(int xTile, int yTile) {
    board.SetPiece(xTile,yTile);
    serverCommunicator.SendMove(xTile, yTile, gameId);
  }
  
  Refresh(){
    _initFields();
    _finishedLoading = false;
    serverCommunicator.ClearAndAddLoadGameListener(loadGameHandler);
    serverCommunicator.LoadGame(gameId);
  }
  
  void Leave(){
    super.Leave();
    lobbyButtonSubscription.cancel();
  }
  
  void draw(Event e)
  {
    context.drawImage(backgroundImage, 0, 0);
    
    board.DoForAll(drawPiece);
    drawGrid();
    var color = board.CurrentPlayer == Piece.WHITE ? "white" : "black";
    whosTurn.innerHtml = (board.CurrentPlayer == player ? "YOUR TURN $color" : "OPPONENT $color");  
  }

  
  _afterGameOver() {
    _goToLobby();
  }

  void _goToLobby() {
    Leave();
    ShowHide.hide(playArea, effect: new FadeEffect(), duration: 400, effectTiming: EffectTiming.linear).
      then((_){
      state = new LobbyState(username);
      state.Init();
    });
    
  }
  
  _validMove(int xTile, int yTile, int currentPlayer) {
    if (!_finishedLoading){
      return false;
    }
    if (currentPlayer != player){
      //METODO spela ett ljud eller nåt..
      return false;
    }
    return board.ValidMove(xTile, yTile);
  }
  
  void loadGameHandler(List moves){
    for (var move in moves){
      board.SetPiece(move['x'], move['y']);
    }
    _finishedLoading = true;
  }
}


class PlayState implements State{
  final CanvasElement canvas;
  ImageElement backgroundImage;
  ImageElement whiteBrick;
  ImageElement blackBrick;
  SpanElement whiteCount;
  SpanElement blackCount;
  SpanElement whosTurn;
 

  CanvasRenderingContext2D context;

  var clientRect;
  int GameWidth;
  int GameHeight;
  final int X_TILE_COUNT = 8;
  final int Y_TILE_COUNT = 8;
  int TILE_WIDTH;
  int TILE_HEIGHT;
  static const int EXPECTED_WIDTH = 512;
  static const int EXPECTED_SPRITE_WIDTH = 64;
    
  PlayingBoard board;
  Element playArea;
  OthelloPopup popup;
  
  
  
  PlayState(this.canvas)
  {
    _initFields();
  }

  
  
  void _initFields() {
    context = canvas.context2D;
    clientRect  = context.canvas.getBoundingClientRect();
    canvas.width = 256;
    canvas.height = 256;
    GameWidth = canvas.width;
    GameHeight = canvas.height;
    TILE_WIDTH  = GameWidth~/X_TILE_COUNT;
    TILE_HEIGHT = GameHeight~/Y_TILE_COUNT;
    board = new PlayingBoard(X_TILE_COUNT, Y_TILE_COUNT, () => draw(null));
  }
  void Init(){
    whiteCount = querySelector("#whiteCount");
    blackCount = querySelector("#blackCount");
    whosTurn = querySelector("#whosTurn");
    var popupDiv = querySelector("#popup");
    
    popup = new OthelloPopup(popupDiv);
    
    
    whiteBrick = GetTexture("white");
    blackBrick = GetTexture("black");
    backgroundImage = GetTexture("background");
    backgroundImage.onLoad.listen(draw);

    context.canvas.onClick.listen(canvasClick);
    
    playArea = querySelector("#playArea");
    
    ShowHide.show(playArea, effect: new FadeEffect(), duration: 800, effectTiming: EffectTiming.linear);
  }

  void Leave(){
    
  }
  
  

  ImageElement GetTexture(String s)
  {
    return new ImageElement(src:"$s.png");
  }

  void draw(Event e)
  {
    context.drawImage(backgroundImage, 0, 0);
    
    board.DoForAll(drawPiece);
    drawGrid();
    whosTurn.innerHtml = board.CurrentPlayer == Piece.WHITE ? "WHITE" : "BLACK";
  }

  void drawGrid() {
    
    assert(X_TILE_COUNT == Y_TILE_COUNT);
    
    final double stepX = GameWidth/(X_TILE_COUNT);
    final double stepY = GameHeight/(Y_TILE_COUNT);
    
    for (int x = 1; x <= X_TILE_COUNT;x++)
    {
      drawLine(x*stepX, 0, x*stepX, GameHeight);
      drawLine(0 ,x*stepY, GameWidth ,  x*stepY);
    }
  }

  void drawLine(num x1, num y1, num x2, num y2)
  {
    context.moveTo(x1, y1);
    context.lineTo(x2, y2);
    context.stroke();
  }

  void canvasClick(MouseEvent event) {
    
    num x = event.client.x - clientRect.left;
    num y = event.client.y - clientRect.top;
    
    num xTile = x ~/ TILE_WIDTH;
    num yTile = y ~/ TILE_HEIGHT;
    
    var currentPlayer = board.CurrentPlayer;
    
    if (_validMove(xTile,yTile, currentPlayer))
    {
      _doMove(xTile, yTile);
      
      if (board.IsGameOver()){
        _decideAndDisplayWinner();
        return;
      }
      
      if (currentPlayer != board.CurrentPlayer){
        popup.DisplayPopup(board.CurrentPlayer == Piece.WHITE  ? "Whites turn" : "Blacks turn");
      }
      else {
        popup.DisplayPopup(board.CurrentPlayer == Piece.WHITE  ? "White again!" : "Black again!");
      }
    }
  }
  
  _validMove(int xTile, int yTile, int currentPlayer) {
    board.ValidMove(xTile, yTile);
  }
  
  _doMove(int xTile, int yTile) {
    board.SetPiece(xTile,yTile);

  }
  _afterGameOver() {
    _restart();
  }
  
  void _decideAndDisplayWinner() {
    var whitePieces = board.whitePieceCount;
    var blackPieces = board.blackPieceCount;
    
    popup.onPopupCloseFunction.add(() => _afterGameOver());
    
    if (whitePieces > blackPieces){
      popup.DisplayPopup("White won! $whitePieces to $blackPieces", ms: 2800);
    }
    else if (whitePieces == blackPieces){
      popup.DisplayPopup("It's a draw!", ms: 2800);
    }
    else{
      popup.DisplayPopup("Black won! $blackPieces to $whitePieces", ms: 2800);
    }
    return;
  }
  
 
  void _restart(){
    board.RestartLevel(X_TILE_COUNT, Y_TILE_COUNT);
    draw(null);
  }
  
  double get _scale => GameWidth/EXPECTED_WIDTH;
  
  void drawPiece(Piece msg) {
    
    var size = EXPECTED_SPRITE_WIDTH * _scale;
    
    if (msg.Type == Piece.WHITE) {
      context.drawImageScaled(whiteBrick, msg.Position.x*TILE_WIDTH, msg.Position.y* TILE_HEIGHT, size, size);
      
    }
    else if (msg.Type == Piece.BLACK) {
      context.drawImageScaled(blackBrick, msg.Position.x*TILE_WIDTH, msg.Position.y* TILE_HEIGHT, size, size);
    }
  }
}
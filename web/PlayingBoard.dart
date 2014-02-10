library PlayingBoard;
import 'array2d.dart';
import 'dart:math';

class Piece
{
  static const int EMPTY = 0; 
  static const int WHITE = 1; 
  static const int BLACK = 2;
  
  static const List<Point> Directions = const [const Point(-1,-1), const Point(0,-1), const Point(1,-1),
                                               const Point(-1, 0),                    const Point(1, 0),
                                               const Point(-1, 1), const Point(0, 1), const Point(1, 1)];
  
  int Type;
  Point Position;
  Piece(this.Type, this.Position);
  
}
typedef void RenderCallback();

class PlayingBoard
{
  array2d<Piece> board;
  
  int CurrentPlayer = Piece.WHITE;
  int CurrentTurn = 1;
/*  String Player1;
  String Player2; */
  RenderCallback _renderCallback;
  
  PlayingBoard(int width, int height, RenderCallback render)
  {
    _renderCallback = render;
    RestartLevel(width, height);
  }
  
  void RestartLevel(int width, int height){
    CurrentTurn = 1;
    board = new array2d(width, height);
    for (int x = 0; x < width; x++)
    {
      for (int y = 0; y < height; y++)
      {
        board.Set(x, y, new Piece(Piece.EMPTY, new Point(x,y)));
      }
    }
    
    board.Get(3, 3).Type = Piece.WHITE;
    board.Get(4, 4).Type = Piece.WHITE;
    board.Get(3, 4).Type = Piece.BLACK;
    board.Get(4, 3).Type = Piece.BLACK;
    CurrentPlayer = Piece.WHITE;
  }
  
  void SetPiece(int x, int y)
  {
    var player = CurrentPlayer;
    
    if (!ValidMove(x,y))
    {
      return;
    }
    
    if (CurrentPlayer == Piece.WHITE)
    {
      _setWhite(x,y);  
    }
    else
      _setBlack(x, y);
    CurrentTurn++;
    _changeBoard(x,y, player);
    _switchPlayer();
    _render();
  }
  
  void _render(){
    if (_renderCallback != null){
      _renderCallback();
    }
  }
  
  bool ValidMove(int x, int y, [int player])
  {
    if (!_emptyPosition(x, y)) return false;
   
    if (player == null) player = CurrentPlayer;
    
    for (Point dir in Piece.Directions){
      if (_checkDirection(player, new Point(x,y), dir).length > 0) { 
        return true;
      }
    }
    
    return false;
  }
  
  //METODO nu skall jag börja använda servern snart!!! Victoryconditions kollas aldrig
  //Sen behöver jag väl egentligen ha nån slags state manager. Eller helt enkelt att spelet inte börjas med en gång
  
  bool IsGameOver()
  {
    if (!board.Any((p) => p.Type != Piece.EMPTY))
    {
      return true;
    }
    if (!PlayerHasValidMove(Piece.BLACK) && !PlayerHasValidMove(Piece.WHITE))
    {
      return true;
    }
    return false;
  }
  
  int Leader(){
    if (whitePieceCount > blackPieceCount)
      return Piece.WHITE;
    return Piece.BLACK;
  }
  
  int get winner => whitePieceCount > blackPieceCount ? Piece.WHITE : Piece.BLACK;
  
  int get whitePieceCount => board.Count((p) => p.Type == Piece.WHITE); 
  int get blackPieceCount => board.Count((p) => p.Type == Piece.BLACK); 
  
  bool PlayerHasValidMove(int player)
  {
    var tmp = board.Any((p) => ValidMove(p.Position.x, p.Position.y, player));
    
    return tmp;
  }
  
  void _changeBoard(int x, int y, int player)
  {
    for (Point dir in Piece.Directions){
      _flipList(_checkDirection(player, new Point(x,y), dir));
    }
  }

  void _flipList(List<Piece> flippPieces) {
    for (var piece in flippPieces)
    {
      _switchWithoutPlayerChange(piece.Position.x, piece.Position.y);
    }
    flippPieces.clear();
  }
  
  List<Piece> _checkDirection(int player, Point start, Point direction)
  {
    List<Piece> output = new List<Piece>();
    var tmp = _checkDirectionRecursive(player, start, start, direction, output);
    return output; //METODO BUGG???? varför måste jag ha med output.
    
  }
  
  List<Piece> _checkDirectionRecursive(int player, Point start, Point current, Point direction, List<Piece> change)
  {
    Point p = current + direction;
    
    if (!board.Inside(p.x, p.y))
    {
      change.clear();
      return new List<Piece>();
    }
    
    var pos = board.Get(p.x, p.y);
    
    if (pos.Type == Piece.EMPTY)
    {
      change.clear();
      return new List<Piece>();
    }
    
    if (pos.Type == player)
      return change;
    
    change.add(pos);
    
    _checkDirectionRecursive(player, start, p, direction, change);
  }
  
  void _setWhite(int x, int y)
  {
    board.Set(x, y, new Piece(Piece.WHITE,new Point(x,y)));
   
  }
  void _setBlack(int x, int y)
  {
    board.Set(x, y, new Piece(Piece.BLACK,new Point(x,y)));
   
  }
  
  void _switchWithoutPlayerChange(int x, int y)
  {
    var oldPiece = board.Get(x, y);
    oldPiece.Type = _otherPlayer(oldPiece.Type);
  }
  
  int _otherPlayer(int player)
  {
    if (player == Piece.WHITE)
    {
      return Piece.BLACK;
    }
    else if(player == Piece.BLACK)
    {
      return Piece.WHITE;
    }
    
    return Piece.EMPTY;
    
  }
  
  void _switchPlayer()
  {
    var oldPlayer = CurrentPlayer;
    CurrentPlayer = _otherPlayer(CurrentPlayer);
    if (!PlayerHasValidMove(CurrentPlayer)){
      CurrentPlayer = oldPlayer;
    }
  }
  
  void DoForAll(DoForAllFunction<Piece> f)
  {
    board.DoForAll(f);
    
  }
  
  bool _emptyPosition(int x, int y)
  {
    return (board.Get(x, y).Type == Piece.EMPTY);    
  }
  
  
}
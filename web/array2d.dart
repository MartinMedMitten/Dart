library array2d;
typedef void DoForAllFunction<T>(T msg);
class array2d<T>
{
  
  
  
  int _width;
  int _height;
  List<T> _list; 
  
  array2d(this._width, this._height){
    _list = new List<T>(_width*_height);
  }
  
  T Get(int x, int y)
  {
    return _list[_getIndex(x,y)];
  }
  
  bool Set(int x, int y, T item)
  {
    if (x >= _width || y >= _height)
    {
      return false;
    }
   
    _list[_getIndex(x,y)] = item;
    return true;
  }
  
  int _getIndex(int x, int y)
  {
    return (_width * y)+x;
  }
  void Fill(T item)
  {
    for (int i = 0; i < _getIndex(_width-1,_height-1); i++)
    {
      _list[i] = item;
    }
  }
  
  int Count(bool test(T element)) => _list.where(test).length;
  
  bool Any(bool test(T element))
  => _list.any(test);
  
  void DoForAll(DoForAllFunction<T> f)
  {
    for (int i = 0; i < (_getIndex(_width-1,_height-1)+1); i++)
    {
      f(_list[i]);
    }
  }
  
  bool Inside(int x, int y)
  {
    return x >= 0 && x < _width && y >= 0 && y < _height;
  }
  
}




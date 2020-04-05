
class defn{
  final String _returns;
  const defn({String returns}) : _returns = returns;
}

class param{
  final String _path;
  const param(String path) : _path = path;
}

class block{
  final String _name;
  final String _path;
  const block(String path, {String name}) : _path = path, _name = name;
}

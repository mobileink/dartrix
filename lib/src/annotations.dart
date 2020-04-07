class defn {
  final String _returns;
  const defn({String returns}) : _returns = returns;
  @override
  String toString() {
    return _returns;
  }
}

class param {
  final String _path;
  const param(String path) : _path = path;
  @override
  String toString() {
    return _path;
  }
}

class block {
  final String _name;
  final String _path;
  const block(String path, {String name})
      : _path = path,
        _name = name;
  @override
  String toString() {
    return '${_name} ${_path}';
  }
}

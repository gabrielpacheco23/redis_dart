import 'resp_object.dart';
import 'resp_types.dart';

class RespToken {
  final RespType type;
  final dynamic content;

  RespToken({
    required this.type,
    required this.content,
  });
}

class RespParser {
  late String _source;
  var _current = 0;
  var _index = 0;

  void _reset(String source) {
    _source = source;
    _current = 0;
    _index = 0;
  }

  Iterable<RespToken> _tokenize() sync* {
    while (!isAtEnd) {
      _index = _current;
      var token = _scanToken();
      if (token != null) {
        yield token;
      }
    }
  }

  RespToken? _scanToken() {
    var char = _advance();
    switch (char) {
      case '*':
        var value = _peek();
        while (_peek() != '\r') {
          _advance();
        }
        return RespToken(
          type: RespType.array,
          content: int.tryParse(value) ?? -1,
        );
      case r'$':
        var isNull = false;
        while (_peek() != '\r') {
          if (_peek() == '-') {
            isNull = true;
            break;
          }
          _advance();
        }
        _advance(); // get out of '\r'
        _advance(); // get out of '\n'
        var _tempIndex = _current;
        while (_peek() != '\r') {
          _advance();
        }
        return RespToken(
          type: RespType.bulkString,
          content: isNull ? null : _source.substring(_tempIndex, _current),
        );
      case '+':
        while (_peek() != '\r') {
          _advance();
        }
        return RespToken(
          type: RespType.simpleString,
          content: _source.substring(_index + 1, _current),
        );
      case '-':
        while (_peek() != '\r') {
          _advance();
        }
        return RespToken(
          type: RespType.error,
          content: _source.substring(_index + 1, _current),
        );
      case ':':
        while (_peek() != '\r') {
          _advance();
        }
        return RespToken(
          type: RespType.integer,
          content: int.parse(_source.substring(_index + 1, _current)),
        );
      default:
        return null;
    }
  }

  RespObject parse(String source) {
    _reset(source);

    var tokens = _tokenize().toList();
    var firstToken = tokens[0];

    if (firstToken.type != RespType.array) {
      return RespObject.fromType(firstToken.type, firstToken.content);
    }

    if (firstToken.content == -1) {
      return RespArray(null);
    }

    var length = firstToken.content as int;
    var elements = <RespObject>[];
    var pointer = 1;
    for (var count = 0; count < length; count++) {
      if (tokens[pointer].type != RespType.array) {
        elements.add(RespObject.fromType(
            tokens[pointer + count].type, tokens[pointer + count].content));
      } else {
        var _elemts = <RespObject>[];
        var _len = tokens[pointer].content as int;
        var iter = 1;
        for (; iter <= _len; iter++) {
          _elemts.add(RespObject.fromType(
              tokens[iter + pointer].type, tokens[iter + pointer].content));
        }
        elements.add(RespArray(_elemts));
        pointer += iter;
      }
    }
    return RespArray(elements);
  }

  String _peek() => _source[_current];

  String _advance() {
    _current++;
    return _source[_current - 1];
  }

  bool get isAtEnd => _current >= _source.length;
}

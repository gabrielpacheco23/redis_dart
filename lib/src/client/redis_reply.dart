import '../resp/resp_object.dart';
import '../utils/resp_utils.dart';

class RedisReply {
  final dynamic _object;
  RedisReply(this._object);

  dynamic get value {
    if (_object is RespObject) {
      return _object.toObject();
    }
    return _object;
  }

  String serialize() {
    if (_object is Map) {
      return RespArray(mapToList(_object)).serialize();
    }
    return _object.serialize();
  }

  @override
  String toString() => value.toString();
}

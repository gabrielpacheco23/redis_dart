import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import '../resp/resp_object.dart';
import '../resp/resp_parser.dart';

final _parser = RespParser();
final respDecoder = StreamTransformer<Uint8List, RespObject>.fromHandlers(
  handleData: (event, sink) => sink.add(_parser.parse(utf8.decode(event))),
  handleError: (err, st, sink) => sink.addError(err),
  handleDone: (sink) => sink.close(),
);

List<RespBulkString> mapBulkStrings(List<String> strs) {
  return strs.map((e) => RespBulkString(e)).toList();
}

Map? listToMap(List? list) {
  if (list == null) {
    return null;
  }
  final keys = [];
  final values = [];
  for (var i = 0; i < list.length; i++) {
    if (i.isEven) {
      keys.add(list[i]);
    } else {
      values.add(list[i]);
    }
  }
  return {
    for (var i = 0; i < keys.length; i++) keys[i]: values[i],
  };
}

List<RespObject> mapToList(Map map) {
  final list = <RespBulkString>[];
  for (var key in map.keys) {
    list.add(RespBulkString(key));
    list.add(RespBulkString(map[key]));
  }
  return list;
}

import 'package:redis_client/src/resp/resp_types.dart';

abstract class RespObject {
  late String identifier;
  late final dynamic content;
  final String crlf = '\r\n';

  RespObject(this.content);

  String serialize() => '$identifier${content.toString()}$crlf';
  dynamic toObject() => content;

  @override
  String toString() => serialize();

  factory RespObject.fromType(RespType type, content) {
    switch (type) {
      case RespType.simpleString:
        return RespSimpleString(content);
      case RespType.error:
        return RespError(content);
      case RespType.integer:
        return RespInteger(content);
      case RespType.bulkString:
        return RespBulkString(content);
      case RespType.array:
        return RespArray(content);
      default:
        throw Error(); // unreachable
    }
  }
}

class RespSimpleString extends RespObject {
  @override
  final String identifier = '+';
  @override
  final String content;

  RespSimpleString(this.content) : super(content);
}

class RespError extends RespObject implements Exception {
  @override
  final String identifier = '-';
  @override
  final String content;

  RespError(this.content) : super(content);

  @override
  Exception toObject() => Exception(content);
}

class RespInteger extends RespObject {
  @override
  final String identifier = ':';
  @override
  final int? content;

  RespInteger(this.content) : super(content);

  @override
  int? toObject() => content;
}

class RespBulkString extends RespObject {
  @override
  final String identifier = r'$';
  @override
  final String? content;

  final int length;

  RespBulkString(this.content)
      : length = content?.length ?? -1,
        super(content);

  @override
  String serialize() {
    if (content == null) return '$identifier-1$crlf';
    return '$identifier$length$crlf$content$crlf';
  }
}

class RespArray extends RespObject {
  @override
  final String identifier = '*';
  @override
  final List<RespObject>? content;

  final int length;

  RespArray(this.content)
      : length = content?.length ?? -1,
        super(content);

  @override
  String serialize() {
    if (content == null) return '$identifier-1$crlf';
    final elements = content?.map((e) => e.serialize()).join();
    return '$identifier$length$crlf$elements';
  }

  @override
  List? toObject() => content?.map((e) => e.toObject()).toList();
}

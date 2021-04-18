import 'dart:io';
import 'package:async/async.dart';
import 'package:redis_dart/src/resp/resp_object.dart';

import 'redis_reply.dart';
import '../resp/resp_request.dart';
import '../utils/resp_utils.dart';

class RedisClient {
  late final String host;
  late final int port;
  late final Socket _socket;

  late final StreamQueue<RespObject> _queue;

  RedisClient._(this.host, this.port, this._socket) {
    _socket.setOption(SocketOption.tcpNoDelay, true);
    _queue = StreamQueue(_socket.transform(respDecoder));
  }

  /// Connects to a Redis server
  static Future<RedisClient> connect(String host, [int port = 6379]) async {
    try {
      final socket = await Socket.connect(host, port);
      return RedisClient._(host, port, socket);
    } on SocketException catch (err) {
      throw _error('Can\'t connect to server: ${err.message}');
    }
  }

  /// Sends a Redis command to the server
  Future<RedisReply> command(String cmd, [List? args]) async {
    _socket.write(RespRequest([cmd, ...args ?? []]).serialize());

    final event = await _queue.next;
    return RedisReply(event);
  }

  /// SET - Set a key with a value
  Future<RedisReply> set(String key, value) async {
    return command('SET', [key, '$value']);
  }

  /// SETRANGE - Set value at offset of a key
  Future<RedisReply> setRange(String key, int offset, value) async {
    return command('SETRANGE', [key, '$offset', '$value']);
  }

  /// SETNX - Set a key with a value only if the key does not exist
  Future<RedisReply> setNotExists(String key, value) async {
    return command('SETNX', [key, '$value']);
  }

  /// MSET - Set a list of keys with a list of values
  Future<RedisReply> multiSet({
    required List<String> keys,
    required List values,
  }) async {
    if (keys.length != values.length) {
      throw _error('The number of keys must be equal to the number of values.');
    }

    final queryList = <String>[];
    for (var i = 0; i < keys.length; i++) {
      queryList.add(keys[i]);
      queryList.add('${values[i]}');
    }
    return command('MSET', queryList);
  }

  /// GET - Get a value from a key
  Future<RedisReply> get(String key) async {
    return command('GET', [key]);
  }

  /// GETRANGE - Get a range of a value of a key
  Future<RedisReply> getRange(String key, int start, int end) async {
    return command('GETRANGE', [key, '$start', '$end']);
  }

  /// MGET - Get a list of values from a list of keys
  Future<RedisReply> multiGet(List<String> keys) async {
    // final query = keys.join(' ');
    return command('MGET', keys);
  }

  /// DEL - Delete a key-value pair
  Future<RedisReply> delete(String key) async {
    return command('DEL', [key]);
  }

  /// FLUSHDB - Delete all the keys from the current database
  Future<RedisReply> deleteAllKeys() async {
    return command('FLUSHDB');
  }

  /// FLUSHALL - Delete all the keys from all databases
  Future<RedisReply> deleteAllDBs() async {
    return command('FLUSHALL');
  }

  /// EXISTS - Check if a key or list of keys exists
  Future<RedisReply> exists(String key, [List<String>? keys]) async {
    var query = '';
    if (keys != null) {
      query = keys.join(' ');
    }
    _socket.write(RespRequest(['EXISTS', key, query]));

    final event = await _queue.next;
    return RedisReply(event.content == 1 ? true : false);
  }

  /// KEYS - Get keys with pattern
  Future<RedisReply> keys(String pattern) async {
    return command('KEYS', [pattern]);
  }

  /// (KEYS *) - Get all keys
  Future<RedisReply> allKeys() async {
    return keys('*');
  }

  /// INCR - Increment a key
  Future<RedisReply> increment(String key) async {
    return command('INCR', [key]);
  }

  /// INCRBY - Increment a key with the amount
  Future<RedisReply> incrementBy(String key, int amount) async {
    return command('INCRBY', [key, '$amount']);
  }

  /// DECR - Decrements the key
  Future<RedisReply> decrement(String key) async {
    return command('DECR', [key]);
  }

  /// DECRBY - Decrements an integer by amout
  Future<RedisReply> decrementBy(String key, int amount) async {
    return command('DECRBY', [key, '$amount']);
  }

  /// APPEND - Appends a value to a key
  Future<RedisReply> append(String key, value) async {
    return command('APPEND', [key, '$value']);
  }

  /// STRLEN -  Gets the length of the value stored in the key
  Future<RedisReply> strlen(String key) async {
    return command('STRLEN', [key]);
  }

  /// EXPIRE - Expires a key with the timeout.
  Future<RedisReply> expire(String key, Duration timeout) async {
    return command('EXPIRE', [key, '${timeout.inSeconds}']);
  }

  /// EXPIREAT - Expires a key with a DateTime
  /// (e.g. await client.expireAt('num', DateTime(2021, 4, 18))
  Future<RedisReply> expireAt(String key, DateTime dateTime) async {
    return command(
        'EXPIREAT', [key, '${dateTime.millisecondsSinceEpoch ~/ 1000}']);
  }

  /// HSET - Sets a Redis Hash (with a Dart Map)
  Future<RedisReply> setMap(String key, Map<String, dynamic> value) async {
    final queryList = <String>[];
    final fields = value.keys.toList();
    for (var i = 0; i < value.keys.length; i++) {
      queryList.add(fields[i]);
      queryList.add('${value[fields[i]]}');
    }
    return command('HSET', [key, ...queryList]);
  }

  /// HGETALL - Gets all the fields from a Hash (returning a Dart Map)
  Future<RedisReply> getMap(String key) async {
    _socket.write(RespRequest(['HGETALL', key]));

    final event = await _queue.next;
    var map = listToMap(event.toObject());
    return RedisReply(map);
  }

  /// HGET - Gets a Hash field
  Future<RedisReply> getField(String key, String field) async {
    return command('HGET', [key, '$field']);
  }

  /// HEXISTS - Checks if a Hash field exists
  Future<RedisReply> existsField(String key, String field) async {
    _socket.write(RespRequest(['HEXISTS', key, field]));

    final event = await _queue.next;
    print(event.content);
    return RedisReply(event.content == 1 ? true : false);
  }

  /// HDEL - Deletes a field from a Hash
  Future<RedisReply> deleteField(String key, String field,
      [List<String>? fields]) async {
    final _fields = fields?.map((f) => '$f').toList();
    return command('HDEL', [key, field, ..._fields ?? []]);
  }

  /// HINCRBY or HINCRBYFLOAT - Increments a field from a Hash (int or float)
  Future<RedisReply> incrementFieldBy(
      String key, String field, num value) async {
    if (value is int) return command('HINCRBY', [key, field, '$value']);
    return command('HINCRBYFLOAT', [key, field, '$value']);
  }

  /// HKEYS - Gets the keys of a Hash
  Future<RedisReply> mapKeys(String key) {
    return command('HKEYS', [key]);
  }

  /// HLEN - Gets the length of a Hash
  Future<RedisReply> mapLength(String key) {
    return command('HLEN', [key]);
  }

  /// HVALS - Gets the values of a Hash
  Future<RedisReply> mapValues(String key) async {
    return command('HVALS', [key]);
  }

  /// LPUSH - Pushes a element or a list of them to the head (first)
  Future<RedisReply> pushFirst(String key, element, [List? elements]) async {
    if (element is List) {
      throw _error(
          'You have to pass a single element before the list of the rest.\n');
    }
    final _elmts = elements?.map((e) => '$e').toList();
    return command('LPUSH', [key, '$element', ..._elmts ?? []]);
  }

  /// RPUSH - Pushes a element or a list of them to the tail (last)
  Future<RedisReply> pushLast(String key, element, [List? elements]) async {
    if (element is List) {
      throw _error(
          'You have to pass a single element before the list of the rest.\n');
    }
    final _elmts = elements?.map((e) => '$e').toList();
    return command('RPUSH', [key, '$element', ..._elmts ?? []]);
  }

  /// LPOP - Pops the first element of a list (head)
  Future<RedisReply> popFirst(String key, [int? count]) async {
    if (count != null) return command('LPOP', [key, '$count']);
    return command('LPOP', [key]);
  }

  /// RPOP - Pops the last element of a list (tail)
  Future<RedisReply> popLast(String key, [int? count]) async {
    if (count != null) return command('RPOP', [key, '$count']);
    return command('RPOP', [key]);
  }

  /// LINDEX - Gets the element of a list at the index
  Future<RedisReply> elementAt(String key, int index) async {
    return command('LINDEX', [key, '$index']);
  }

  /// LINSERT BEFORE - Inserts in the list before a specified key
  Future<RedisReply> insertBefore(String key, before, value) async {
    return command('LINSERT', [key, 'BEFORE', '$before', '$value']);
  }

  /// LINSERT AFTER - Inserts in the list after a specified key
  Future<RedisReply> insertAfter(String key, after, value) async {
    return command('LINSERT', [key, 'AFTER', '$after', '$value']);
  }

  /// LLEN - Gets the list length
  Future<RedisReply> listLength(String key) async {
    return command('LLEN', [key]);
  }

  /// LRANGE - Gets a list in a range
  Future<RedisReply> listRange(String key, int start, int stop) async {
    return command('LRANGE', [key, '$start', '$stop']);
  }

  /// SADD - Adds a member or more to a Set
  Future<RedisReply> addSet(String key, member, [List? members]) async {
    final _members = members?.map((e) => '$e').toList();
    return command('SADD', [key, '$member', ..._members ?? []]);
  }

  /// SMEMBERS - Gets the members of a Set
  Future<RedisReply> members(String key) async {
    return command('SMEMBERS', [key]);
  }

  /// SISMEMBER - Checks if a member exists in a Set
  Future<RedisReply> isMember(String key, member) async {
    return command('SISMEMBER', [key, '$member']);
  }

  /// SPOP - Pops a random member from a Set
  Future<RedisReply> popSet(String key, [int? count]) async {
    if (count != null) return command('SPOP $key $count');
    return command('SPOP $key');
  }

  /// SREM - Removes a member of a Set
  Future<RedisReply> removeMember(String key, member, [List? members]) async {
    final _members = members?.map((e) => '$e').toList();
    return command('SREM', [key, '$member', ..._members ?? []]);
  }

  /// TTL - Gets the Time To Live (ttl) of a key with expiry
  Future<RedisReply> timeToLive(String key) async {
    return command('TTL $key');
  }

  /// Closes the connection
  Future<void> close() async {
    await _queue.cancel();
    await _socket.close();
  }

  static Error _error(String msg) {
    return _RedisConnectionError(msg);
  }
}

class _RedisConnectionError extends Error {
  _RedisConnectionError(this.msg);
  final String msg;

  @override
  String toString() => msg;
}

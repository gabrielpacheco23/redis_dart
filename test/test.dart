import 'package:test/test.dart';
import 'package:redis_dart/redis_dart.dart';

void main() {
  test('Connection test', () async {
    final client = await RedisClient.connect('localhost');
    var res = await client.get('key');

    expect(res.value, equals(null));
    await client.deleteAllKeys();
  });

  test('Set test', () async {
    final client = await RedisClient.connect('localhost');
    var res = await client.set('key', 'value');

    expect(res.value, equals('OK'));
    await client.deleteAllKeys();
  });

  test('Get test', () async {
    final client = await RedisClient.connect('localhost');
    await client.set('key', 'value');
    var res = await client.get('key');

    expect(res.value, equals('value'));
    await client.deleteAllKeys();
  });

  test('List test', () async {
    final client = await RedisClient.connect('localhost');
    await client.pushLast('a', 0);
    var res = await client.popFirst('a');

    expect(res.value, equals('0'));
    await client.deleteAllKeys();
  });

  test('Hash test', () async {
    final client = await RedisClient.connect('localhost');
    await client.setMap('map', {'two': 2});
    var res = await client.getMap('map');

    expect(int.parse(res.value['two']), equals(2));
    await client.deleteAllKeys();
  });
}

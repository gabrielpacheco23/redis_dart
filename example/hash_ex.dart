import 'package:redis_client/redis_client.dart';

void main() async {
  final client = await RedisClient.connect('localhost');

  // HSET
  await client.setMap('info', {
    'name': 'John Doe',
    'email': 'john@doe.com',
    'age': 34,
  });

  // HGETALL
  var info = await client.getMap('info');
  print(info);

  // HGET
  var name = await client.getField('info', 'name');
  print(name);

  // HKEYS
  var keys = await client.mapKeys('info');
  // HVALS
  var values = await client.mapValues('info');

  print(await client.existsField('info', 'not-a-field'));

  await client.close();
}

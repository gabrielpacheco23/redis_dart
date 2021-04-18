import 'package:redis_dart/redis_dart.dart';

void main() async {
  final client = await RedisClient.connect('localhost');

  print(await client.set('w', 123));
  print(await client.exists('w'));

  print(await client.setMap('map', {'a': 'b'}));
  print(await client.existsField('map', 'a'));

  await client.close();
}

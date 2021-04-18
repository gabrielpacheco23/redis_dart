import 'package:redis_client/redis_client.dart';

void main() async {
  final client = await RedisClient.connect('localhost');

  await client.multiSet(
    keys: ['a', 'b', 'c'],
    values: [1, 2, 3],
  );

  print(await client.multiGet(['a', 'b', 'c']));

  await client.close();
}

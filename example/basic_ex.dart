import 'package:redisclient/redisclient.dart';

void main() async {
  final client = await RedisClient.connect('localhost');

  await client.set('name', 'Gabriel');

  var res = await client.get('name');
  print(res);

  await client.close();
}

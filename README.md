# redis_dart
A simple and minimalist Redis client for Dart

See it in pub: https://pub.dev/packages/redis_dart \
and GitHub: https://github.com/gabrielpacheco23/redis_dart

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/Q5Q04C63Q)

# Usage 

```dart
import 'package:redis_dart/redis_dart.dart';

void main() async {
  final client = await RedisClient.connect('localhost');

  await client.set('name', 'Gabriel');

  var res = await client.get('name');
  print(res);

  await client.close();
}
```

# Easy to use
This library was meant to be clear and easy to understand, so the methods names are associated to what the function does, like
```dart
void main() async {
  final client = await RedisClient.connect('localhost');

  // this is a HSET command
  await client.setMap('info', {
    'name': 'John Doe',
    'email': 'john@doe.com',
    'age': 34,
  });

  // this one is a HGETALL
  var info = await client.getMap('info');
  print(info);

  await client.close();
}
```
which returns a ```Map``` and then prints

```
  {name: John Doe, email: john@doe.com, age: 34}
```

That way, inserting a Redis Hash is as simple as passing a Dart ```Map```. 

# API
For full API documentation take a look at https://pub.dev/documentation/redis_dart/latest/


Also, check out the ```examples``` directory.

# Contribute!
This library still does not covers the full features of Redis, so things like Pub/Sub, Transactions and some commands are not implemented yet, but if you want you can raise a PR to help the library to grow up!

# // TODO:
- Implement all Redis commands
- Implement Transactions
- Implement Pub/Sub
- Maybe some other things

# Support my work :)
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/Q5Q04C63Q)

# License
MIT License

Copyright © 2021 Gabriel Pacheco

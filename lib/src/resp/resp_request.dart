import 'resp_object.dart';
import '../utils/resp_utils.dart';

class RespRequest {
  RespRequest(this.command);
  final List<String> command;

  String serialize() => RespArray(mapBulkStrings(command)).serialize();

  @override
  String toString() => serialize();
}

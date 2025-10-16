
import '../model/message_payload.dart';
import 'media_message_content.dart';
import 'message.dart';
import 'message_content.dart';

// ignore: non_constant_identifier_names
MessageContent FileMessageContentCreator() {
  return FileMessageContent();
}

const fileContentMeta = MessageContentMeta(MESSAGE_CONTENT_TYPE_FILE,
    MessageFlag.PERSIST_AND_COUNT, FileMessageContentCreator);


class FileMessageContent extends MediaMessageContent {
  late String name;
  late int size;

  @override
  MessageContentMeta get meta => fileContentMeta;

  @override
  void decode(MessagePayload payload) {
    super.decode(payload);
    if(payload.searchableContent != null) {
      name = payload.searchableContent!;
    } else {
      name = "";
    }
    if(payload.content != null) {
      size = int.parse(payload.content!);
    } else {
      size = 0;
    }
  }

  @override
  MessagePayload encode() {
    MessagePayload payload = super.encode();
    payload.searchableContent = name;
    payload.content = size.toString();
    return payload;
  }

  @override
  Future<String> digest(Message message) async {
    if(name.isNotEmpty) {
      return '[文件]:$name';
    }
    return '[文件]';
  }

  @override
  MediaType get mediaType => MediaType.Media_Type_FILE;
}
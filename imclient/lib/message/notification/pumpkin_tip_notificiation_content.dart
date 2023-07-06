// ignore: non_constant_identifier_names
import 'dart:convert';

import '../../model/message_payload.dart';
import '../message.dart';
import '../message_content.dart';

MessageContent pumpkinTipNotificationContentCreator() {
  return PumpkinTipNotificationContent();
}

const pumpkinTipNotificationContentMeta = MessageContentMeta(
    MESSAGE_CONTENT_PUMPKIN_TIP,
    MessageFlag.PERSIST_AND_COUNT,
    pumpkinTipNotificationContentCreator);

class PumpkinTipNotificationContent extends MessageContent {
  static int SECRET_MESSAGE_MODE = 1;
  static int CLAIMED_GIFT = 2;

  String? tip;
  int? type;

  @override
  Future<void> decode(MessagePayload payload) async {
    super.decode(payload);

    if (payload.content != null) {
      var map = json.decode(payload.content!);
      tip = map['tip'];
      type = int.tryParse("${map['type']}");
    } else {
      tip = '';
      type = 0;
    }
  }

  @override
  MessageContentMeta get meta => pumpkinTipNotificationContentMeta;

  @override
  MessagePayload encode() {
    MessagePayload payload = super.encode();
    payload.content = json.encode({
      'tip': tip,
      'type': type,
    });
    return payload;
  }

  @override
  Future<String> digest(Message message) async {
    return tip ?? "";
  }
}

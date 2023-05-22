import 'dart:convert';
import '../model/message_payload.dart';
import 'message.dart';
import 'message_content.dart';

// ignore: non_constant_identifier_names
MessageContent GiftMessageContentCreator() {
  return GiftMessageContent();
}

const giftMessageContentMeta = MessageContentMeta(MESSAGE_CONTENT_Gift,
    MessageFlag.PERSIST_AND_COUNT, GiftMessageContentCreator);

class GiftMessageContent extends MessageContent {
  late String giftName;
  late String giftVoucher;
  late String giftStatus;
  late String giftId;
  late String title;

  @override
  Future<void> decode(MessagePayload payload) async {
    super.decode(payload);
    if (payload.searchableContent != null) {
      title = payload.searchableContent!;
    } else {
      title = "";
    }
    if (payload.content != null) {
      var map = json.decode(payload.content!);
      giftName = map['gift_name'];
      giftVoucher = map['gift_voucher'];
      giftStatus = map['gift_status'];
      giftId = map['gift_id'];
    } else {
      giftName = "";
      giftVoucher = "";
      giftStatus = "";
      giftId = "";
    }
  }

  @override
  MessageContentMeta get meta => giftMessageContentMeta;

  @override
  MessagePayload encode() {
    MessagePayload payload = super.encode();
    payload.searchableContent = title;
    payload.content = json.encode({
      'gift_name': giftName,
      'gift_voucher': giftVoucher,
      'gift_status': giftStatus,
      'gift_id': giftId,
    });
    return payload;
  }

  @override
  Future<String> digest(Message message) async {
    if (title.isNotEmpty) {
      return '[礼物]:$title';
    }

    return '[礼物]';
  }
}

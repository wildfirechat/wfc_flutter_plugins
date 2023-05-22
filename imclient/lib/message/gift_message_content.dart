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
  late num giftCount;
  late num giftPrice;
  late num giftVoucher;
  late int giftStatus;
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
      giftName = map['gift_name'] ?? '';
      giftCount = num.tryParse(map['gift_count']) ?? 0;
      giftPrice = num.tryParse(map['gift_price']) ?? 0;
      giftVoucher = num.tryParse(map['gift_voucher']) ?? 0;
      giftStatus = int.tryParse(map['gift_status']) ?? 0;
      giftId = map['gift_id'] ?? '';
    } else {
      giftName = "";
      giftCount = 0;
      giftPrice = 0;
      giftVoucher = 0;
      giftStatus = 0;
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
      'gift_count': giftCount,
      'gift_price': giftPrice,
      'gift_status': giftStatus,
      'gift_voucher': giftVoucher,
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

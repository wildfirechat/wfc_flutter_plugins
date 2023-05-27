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
  late String id;
  late String giftId;
  late num giftNum;
  late String fromUserId;
  late String toUserId;
  late num voucher;
  late num status;
  late int expiryTime;
  late String notes;
  late int createTime;
  late int updateTime;
  late String title;
  late dynamic giftData;

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
      id = map['id'] ?? '';
      giftId = map['gift_id'] ?? '';
      giftNum = num.tryParse('${map['gift_num'] ?? ""}') ?? 0;
      fromUserId = map['from_user_id'] ?? '';
      toUserId = map['to_user_id'] ?? '';
      voucher = num.tryParse('${map['voucher'] ?? ""}') ?? 0;
      status = num.tryParse('${map['status'] ?? ""}') ?? 0;
      expiryTime = int.tryParse('${map['expiry_time'] ?? ""}') ?? 0;
      notes = map['notes'] ?? '';
      createTime = int.tryParse('${map['create_time'] ?? ""}') ?? 0;
      updateTime = int.tryParse('${map['update_time'] ?? ""}') ?? 0;
      giftData = map['gift_data'] ?? '';
    } else {
      id = "";
      giftId = "";
      giftNum = 0;
      fromUserId = "";
      toUserId = "";
      voucher = 0;
      status = 0;
      expiryTime = 0;
      notes = "";
      giftId = "";
      createTime = 0;
      updateTime = 0;
      giftData = {};
    }
  }

  @override
  MessageContentMeta get meta => giftMessageContentMeta;

  @override
  MessagePayload encode() {
    MessagePayload payload = super.encode();
    payload.searchableContent = title;
    payload.content = json.encode({
      'id': id,
      'gift_id': giftId,
      'gift_num': giftNum,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'voucher': voucher,
      'status': status,
      'expiry_time': expiryTime,
      'notes': notes,
      'create_time': createTime,
      'update_time': updateTime,
      'gift_data': giftData,
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

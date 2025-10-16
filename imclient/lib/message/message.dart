
import '../model/conversation.dart';
import 'message_content.dart';

enum MessageStatus {
  ///消息发送中
  Message_Status_Sending,

  ///消息已发送
  Message_Status_Sent,

  ///消息发送失败
  Message_Status_Send_Failure,

  ///消息@当前用户
  Message_Status_Mentioned,

  ///消息@全体用户
  Message_Status_AllMentioned,

  ///消息未读
  Message_Status_Unread,

  ///消息已读
  Message_Status_Readed,

  ///消息已播放
  Message_Status_Played
}

enum MessageDirection { MessageDirection_Send, MessageDirection_Receive }

class Message {
  Message({this.messageId = 0, this.messageUid = 0});
  int messageId;
  int? messageUid;
  late Conversation conversation;
  late String fromUser;
  List<String>? toUsers;
  late MessageContent content;
  late MessageDirection direction;
  late MessageStatus status;
  late int serverTime;
  String? localExtra;

  @override
  String toString() {
    return 'Message{messageId: $messageId, messageUid: $messageUid, conversation: $conversation, fromUser: $fromUser, toUsers: $toUsers, content: $content, direction: $direction, status: $status, serverTime: $serverTime}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          messageId == other.messageId &&
          messageUid == other.messageUid &&
          status == other.status &&
          serverTime == other.serverTime;

  @override
  int get hashCode =>
      messageId.hashCode ^
      messageUid.hashCode ^
      status.hashCode ^
      serverTime.hashCode;
}

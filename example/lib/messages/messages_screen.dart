import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:imclient/message/call_start_message_content.dart';
import 'package:imclient/message/notification/tip_notificiation_content.dart';
import 'package:logger/logger.dart' show Level, Logger;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image/image.dart' as img;
import 'package:imclient/imclient.dart';
import 'package:imclient/message/card_message_content.dart';
import 'package:imclient/message/file_message_content.dart';
import 'package:imclient/message/image_message_content.dart';
import 'package:imclient/message/message.dart';
import 'package:imclient/message/message_content.dart';
import 'package:imclient/message/sound_message_content.dart';
import 'package:imclient/message/text_message_content.dart';
import 'package:imclient/message/typing_message_content.dart';
import 'package:imclient/message/video_message_content.dart';
import 'package:imclient/model/conversation.dart';
import 'package:imclient/model/user_info.dart';
import 'package:provider/provider.dart';
import 'package:rtckit/group_video_call.dart';
import 'package:rtckit/rtckit.dart';
import 'package:rtckit/single_voice_call.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wfc_example/messages/cell_builder/voice_cell_builder.dart';
import 'package:wfc_example/messages/conversation_settings.dart';
import 'package:wfc_example/messages/input_bar/message_input_bar.dart';
import 'package:wfc_example/messages/conversation_appbar_title.dart';
import 'package:wfc_example/messages/picture_overview.dart';
import 'package:wfc_example/messages/video_player_view.dart';
import 'package:wfc_example/viewmodel/conversation_view_model.dart';

import '../contact/contact_select_page.dart';
import '../user_info_widget.dart';
import 'message_cell.dart';
import '../ui_model/ui_message.dart';

class MessagesScreen extends StatefulWidget {
  final Conversation conversation;

  const MessagesScreen(this.conversation, {Key? key}) : super(key: key);

  @override
  State createState() => _State();
}

class _State extends State<MessagesScreen> {
  List<UIMessage> models = <UIMessage>[];
  final EventBus _eventBus = Imclient.IMEventBus;

  late ConversationViewModel conversationViewModel;

  String title = "消息";

  final GlobalKey<MessageInputBarState> _inputBarGlobalKey = GlobalKey();
  final GlobalKey<PictureOverviewState> _pictureOverviewKey = GlobalKey();

  Timer? _typingTimer;
  final Map<String, int> _typingUserTime = {};
  int _sendTypingTime = 0;

  late MessageInputBar _inputBar;

  int _playingMessageId = 0;
  final FlutterSoundPlayer _soundPlayer = FlutterSoundPlayer(logLevel: Level.error);

  @override
  void initState() {
    super.initState();
    _inputBar = MessageInputBar(
      widget.conversation,
      sendButtonTapedCallback: (text) => _onSendButtonTyped(text),
      textChangedCallback: (text) => _onInputBarTextChanged(text),
      pickerImageCallback: (imagePath) => _onPickImage(imagePath),
      pickerFileCallback: (filePath, name, size) => _onPickFile(filePath, name, size),
      pressCallBtnCallback: () => _onPressCallBtn(),
      pressCardBtnCallback: () => _onPressCardBtn(),
      cameraCaptureImageCallback: _cameraCaptureImage,
      cameraCaptureVideoCallback: _cameraCaptureVideo,
      soundRecordedCallback: (soundPath, duration) => _onSoundRecorded(soundPath, duration),
      key: _inputBarGlobalKey,
    );

    conversationViewModel = Provider.of<ConversationViewModel>(context, listen: false);
    conversationViewModel.setConversation(widget.conversation, (err) {
      Fluttertoast.showToast(msg: "网络错误！加入聊天室失败!");
      Navigator.pop(context);
    });

    Imclient.clearConversationUnreadStatus(widget.conversation);

    Imclient.getConversationInfo(widget.conversation).then((conversationInfo) {
      _inputBarGlobalKey.currentState!.setDrat(conversationInfo.draft ?? "");
    });
  }

  void _onSendButtonTyped(String text) {
    TextMessageContent txt = TextMessageContent(text);
    _sendMessage(txt);
    _sendTypingTime = 0;
  }

  void _onInputBarTextChanged(String text) {
    if (DateTime.now().second - _sendTypingTime > 12 && text.isNotEmpty) {
      _sendTyping();
    }
  }

  void _onPickImage(String imagePath) {
    ImageMessageContent imgCont = ImageMessageContent();
    imgCont.localPath = imagePath;
    _sendMessage(imgCont);
  }

  void _onPickFile(String filePath, String name, int size) {
    FileMessageContent fileCnt = FileMessageContent();
    fileCnt.name = name;
    fileCnt.size = size;
    fileCnt.localPath = filePath;
    _sendMessage(fileCnt);
  }

  void _onPressCallBtn() {
    if (widget.conversation.conversationType != ConversationType.Single && widget.conversation.conversationType != ConversationType.Group) {
      return;
    }

    Rtckit.currentCallSession().then((currentSession) {
      if (currentSession == null || currentSession.state == kWFAVEngineStateIdle) {
        if (widget.conversation.conversationType == ConversationType.Single) {
          final double centerX = MediaQuery.of(context).size.width / 2;
          final double centerY = MediaQuery.of(context).size.height / 2;

          // 计算菜单位置
          const double menuWidth = 150.0; // 菜单的宽度
          const double menuHeight = 100.0; // 菜单的高度
          final double left = centerX - (menuWidth / 2) - 36;
          final double top = centerY - (menuHeight / 2) - 24;

          showMenu(
            context: context,
            position: RelativeRect.fromLTRB(left, top, left + menuWidth, top + menuHeight),
            items: <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'voice',
                child: SizedBox(
                  width: menuWidth,
                  child: Text('音频通话'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'video',
                child: SizedBox(
                  width: menuWidth,
                  child: Text('视频通话'),
                ),
              ),
            ],
          ).then((value) {
            if (value == null) {
              return;
            }

            bool isAudioOnly = value == 'voice';
            SingleVideoCallView callView = SingleVideoCallView(userId: widget.conversation.target, audioOnly: isAudioOnly);
            Navigator.push(context, MaterialPageRoute(builder: (context) => callView));
          });
        } else if (widget.conversation.conversationType == ConversationType.Group) {
          Imclient.getGroupMembers(widget.conversation.target).then((groupMembers) {
            List<String> members = [];
            for (var gm in groupMembers) {
              members.add(gm.memberId);
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ContactSelectPage(
                        (context, members) async {
                          if (members.isEmpty) {
                            Fluttertoast.showToast(msg: "请选择一位或者多位成员发起通话");
                          } else {
                            GroupVideoCallView callView = GroupVideoCallView(groupId: widget.conversation.target, participants: members);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => callView),
                            );
                          }
                        },
                        maxSelected: Rtckit.maxAudioCallCount,
                        candidates: members,
                        disabledCheckedUsers: [Imclient.currentUserId],
                      )),
            );
          });
        }
      } else {
        Fluttertoast.showToast(msg: "正在通话中，无法再次发起！");
      }
    });
  }

  void _onPressCardBtn() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ContactSelectPage(
                (context, members) async {
                  if (members.isNotEmpty) {
                    UserInfo? userInfo = await Imclient.getUserInfo(members.first);
                    CardMessageContent cardCnt = CardMessageContent();
                    cardCnt.type = CardType.CardType_User;
                    cardCnt.targetId = members.first;
                    if (userInfo != null) {
                      cardCnt.name = userInfo.name;
                      cardCnt.displayName = userInfo.displayName;
                      cardCnt.portrait = userInfo.portrait;
                    }
                    _sendMessage(cardCnt);
                  }
                  Navigator.pop(context);
                },
                maxSelected: 1,
              )),
    );
  }

  void _cameraCaptureImage(String imagePath) {
    ImageMessageContent imgContent = ImageMessageContent();
    imgContent.localPath = imagePath;
    _sendMessage(imgContent);
  }

  void _cameraCaptureVideo(String videoPath, img.Image? thumbnail, int duration) {
    VideoMessageContent videoContent = VideoMessageContent();
    videoContent.duration = duration;
    videoContent.localPath = videoPath;
    videoContent.thumbnail = thumbnail;
    _sendMessage(videoContent);
  }

  void _onSoundRecorded(String soundPath, int duration) {
    SoundMessageContent soundMessageContent = SoundMessageContent();
    soundMessageContent.localPath = soundPath;
    soundMessageContent.duration = duration;
    _sendMessage(soundMessageContent);
  }

  void _sendMessage(MessageContent messageContent) {
    Imclient.sendMediaMessage(widget.conversation, messageContent, successCallback: (int messageUid, int timestamp) {}, errorCallback: (int errorCode) {},
        progressCallback: (int uploaded, int total) {
      debugPrint("progressCallback:$uploaded,$total");
    }, uploadedCallback: (String remoteUrl) {
      debugPrint("uploadedCallback:$remoteUrl");
    });
  }

  @override
  void dispose() {
    super.dispose();
    _stopTypingTimer();
    if (_soundPlayer.isPlaying) {
      _soundPlayer.stopPlayer();
    }
    if (widget.conversation.conversationType == ConversationType.Chatroom) {
      Imclient.quitChatroom(widget.conversation.target, () {
        Imclient.getUserInfo(Imclient.currentUserId).then((userInfo) {
          if (userInfo != null) {
            TipNotificationContent tip = TipNotificationContent();
            tip.tip = '${userInfo.displayName} 离开了聊天室';
            _sendMessage(tip);
          }
        });
      }, (errorCode) {});
    }
  }

  void _startTypingTimer() {
    _typingTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      bool isUserTyping = _updateTypingStatus();
      if (!isUserTyping && _typingUserTime.isNotEmpty) {
        _typingUserTime.clear();
        _stopTypingTimer();
      }
    });
  }

  String _getTypingDot(int time) {
    int dotCount = time ~/ 1000 % 4;
    String ret = '';
    for (int i = 0; i < dotCount; i++) {
      ret = '$ret.';
    }
    return ret;
  }

  bool _updateTypingStatus() {
    if (!mounted) {
      return false;
    }

    int now = DateTime.now().millisecondsSinceEpoch;
    if (widget.conversation.conversationType == ConversationType.Single) {
      int? time = _typingUserTime[widget.conversation.target];
      if (time != null && now - time < 6000) {
        // titleGlobalKey.currentState!.updateTitle('对方正在输入${_getTypingDot(now)}');
        return true;
      }
    } else {
      int typingUserCount = 0;
      String? lastTypingUser;
      for (String userId in _typingUserTime.keys) {
        int time = _typingUserTime[userId]!;
        if (now - time < 6000) {
          typingUserCount++;
          lastTypingUser = userId;
        }
      }
      if (typingUserCount > 1) {
        // titleGlobalKey.currentState!.updateTitle('$typingUserCount人正在输入${_getTypingDot(now)}');
        return true;
      } else if (typingUserCount == 1) {
        Imclient.getUserInfo(lastTypingUser!, groupId: widget.conversation.target).then((value) {
          if (value != null) {
            // titleGlobalKey.currentState!.updateTitle('${value.displayName!} 正在输入${_getTypingDot(now)}');
          }
        });
        return true;
      }
    }

    // titleGlobalKey.currentState!.updateTitle(title);
    return false;
  }

  void _stopTypingTimer() {
    if (_typingTimer != null) {
      _typingTimer!.cancel();
      _typingTimer = null;
    }
  }

  void _appendMessage(List<Message> messages, {bool front = false}) {
    debugPrint('received ${messages.length} messages');
    setState(() {
      bool haveNewMsg = false;
      for (var element in messages) {
        if (element.conversation != widget.conversation) {
          continue;
        }
        if (element.messageId == 0) {
          continue;
        }

        if (element.content is TypingMessageContent) {
          if (element.conversation == widget.conversation) {
            TypingMessageContent typing = element.content as TypingMessageContent;
            if (element.conversation.conversationType == ConversationType.Single || element.conversation.conversationType == ConversationType.Group) {
              _typingUserTime[element.fromUser] = element.serverTime;
              _startTypingTimer();
            }
          }

          continue;
        }

        if (element.messageId == 0) {
          continue;
        }

        if (element.status == MessageStatus.Message_Status_AllMentioned ||
            element.status == MessageStatus.Message_Status_Mentioned ||
            element.status == MessageStatus.Message_Status_Unread) {
          haveNewMsg = true;
          _typingUserTime.remove(element.fromUser);
          _updateTypingStatus();
        }

        bool duplicated = false;
        for (var m in models) {
          if (m.message.messageId == element.messageId) {
            m.message = element;
            duplicated = true;
            break;
          }
        }
        if (duplicated) {
          continue;
        }

        UIMessage model = UIMessage(element, showTimeLabel: false);
        if (front) {
          models.insert(0, model);
        } else {
          models.add(model);
        }
      }

      for (int i = 0; i < models.length; ++i) {
        UIMessage model = models[i];
        if (i < models.length - 1) {
          UIMessage nextModel = models[i + 1];
          if (model.message.serverTime - nextModel.message.serverTime > 60 * 1000) {
            model.showTimeLabel = true;
          } else {
            model.showTimeLabel = false;
          }
        } else {
          model.showTimeLabel = true;
        }
      }

      if (haveNewMsg) {
        Imclient.clearConversationUnreadStatus(widget.conversation);
      }
    });
  }

  bool notificationFunction(Notification notification) {
    switch (notification.runtimeType) {
      case ScrollEndNotification:
        var noti = notification as ScrollEndNotification;
        if (noti.metrics.pixels >= noti.metrics.maxScrollExtent) {
          conversationViewModel.loadHistoryMessage();
        }
        break;
    }
    return true;
  }

  void onTapedCell(UIMessage model) {
    if (model.message.content is ImageMessageContent) {
      Imclient.getMessages(widget.conversation, model.message.messageId, 10, contentTypes: [MESSAGE_CONTENT_TYPE_IMAGE]).then((value1) {
        Imclient.getMessages(widget.conversation, model.message.messageId, -10, contentTypes: [MESSAGE_CONTENT_TYPE_IMAGE]).then((value2) {
          List<Message> list = [];
          list.addAll(value2);
          list.add(model.message);
          list.addAll(value1);
          int index = 0;
          for (int i = 0; i < list.length; i++) {
            if (list[i].messageId == model.message.messageId) {
              index = i;
              break;
            }
          }
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PictureOverview(
                      list,
                      defaultIndex: index,
                      pageToEnd: (fromIndex, tail) {
                        if (tail) {
                          Imclient.getMessages(widget.conversation, fromIndex, 10, contentTypes: [MESSAGE_CONTENT_TYPE_IMAGE]).then((value) {
                            if (value.isNotEmpty) {
                              _pictureOverviewKey.currentState!.onLoadMore(value, false);
                            }
                          });
                        } else {
                          Imclient.getMessages(widget.conversation, fromIndex, -10, contentTypes: [MESSAGE_CONTENT_TYPE_IMAGE]).then((value) {
                            if (value.isNotEmpty) {
                              _pictureOverviewKey.currentState!.onLoadMore(value, true);
                            }
                          });
                        }
                      },
                      key: _pictureOverviewKey,
                    )),
          );
        });
      });
    } else if (model.message.content is VideoMessageContent) {
      VideoMessageContent videoContent = model.message.content as VideoMessageContent;
      Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPlayerView(videoContent.remoteUrl!)));
    } else if (model.message.content is FileMessageContent) {
      FileMessageContent fileContent = model.message.content as FileMessageContent;
      canLaunchUrl(Uri.parse(fileContent.remoteUrl!)).then((value) {
        if (value) {
          launchUrl(Uri.parse(fileContent.remoteUrl!));
        } else {
          Fluttertoast.showToast(msg: '无法打开');
        }
      });
    } else if (model.message.content is SoundMessageContent) {
      if (_playingMessageId == model.message.messageId) {
        stopPlayVoiceMessage(model);
      } else {
        if (_playingMessageId > 0) {
          for (var value in models) {
            if (value.message.messageId == _playingMessageId) {
              stopPlayVoiceMessage(model);
              break;
            }
          }
        }

        startPlayVoiceMessage(model);
      }
    } else if (model.message.content is CallStartMessageContent) {
      CallStartMessageContent callContent = model.message.content as CallStartMessageContent;
      if (model.message.conversation.conversationType == ConversationType.Single) {
        SingleVideoCallView callView = SingleVideoCallView(userId: widget.conversation.target, audioOnly: callContent.audioOnly);
        Navigator.push(context, MaterialPageRoute(builder: (context) => callView));
      } else if (model.message.conversation.conversationType == ConversationType.Group) {
        _onPressCallBtn();
      }
    }
  }

  void stopPlayVoiceMessage(UIMessage model) {
    if (_soundPlayer.isPlaying) {
      _soundPlayer.stopPlayer();
    }
    _eventBus.fire(VoicePlayStatusChangedEvent(model.message.messageId, false));
    _playingMessageId = 0;
  }

  void startPlayVoiceMessage(UIMessage model) {
    SoundMessageContent soundContent = model.message.content as SoundMessageContent;
    if (model.message.direction == MessageDirection.MessageDirection_Receive && model.message.status == MessageStatus.Message_Status_Readed) {
      Imclient.updateMessageStatus(model.message.messageId, MessageStatus.Message_Status_Played);
      model.message.status = MessageStatus.Message_Status_Played;
    }
    _soundPlayer.openPlayer();
    _soundPlayer.startPlayer(
        fromURI: soundContent.remoteUrl!,
        whenFinished: () {
          stopPlayVoiceMessage(model);
        });
    _eventBus.fire(VoicePlayStatusChangedEvent(model.message.messageId, true));
    _playingMessageId = model.message.messageId;
  }

  void onDoubleTapedCell(UIMessage model) {
    debugPrint("on double taped cell");
  }

  void onLongPressedCell(UIMessage model, Offset postion) {
    _showPopupMenu(model, postion);
  }

  void onPortraitTaped(UIMessage model) {
    debugPrint("on taped portrait");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserInfoWidget(model.message.fromUser)),
    );
  }

  void onPortraitLongTaped(UIMessage model) {
    debugPrint("on long taped portrait");
  }

  void onResendTaped(UIMessage model) {
    debugPrint("on taped resend");
    Imclient.sendSavedMessage(model.message.messageId, successCallback: (l, ll) {}, errorCallback: (errorCode) {});
  }

  void onReadedTaped(UIMessage model) {
    debugPrint("on taped readed");
  }

  void _showPopupMenu(UIMessage model, Offset position) {
    List<PopupMenuItem> items = [
      const PopupMenuItem(
        value: 'delete',
        child: Text('删除'),
      )
    ];

    if (model.message.content is TextMessageContent) {
      items.add(const PopupMenuItem(value: 'copy', child: Text('复制')));
    }

    items.add(const PopupMenuItem(
      value: 'forward',
      child: Text('转发'),
    ));

    if (model.message.direction == MessageDirection.MessageDirection_Send &&
        model.message.status == MessageStatus.Message_Status_Sent &&
        DateTime.now().millisecondsSinceEpoch - model.message.serverTime < 120 * 1000) {
      items.add(const PopupMenuItem(
        value: 'recall',
        child: Text('撤回'),
      ));
    }

    items.addAll([
      const PopupMenuItem(
        value: 'multi_select',
        child: Text('多选'),
      ),
      const PopupMenuItem(
        value: 'quote',
        child: Text('引用'),
      ),
      const PopupMenuItem(
        value: 'favorite',
        child: Text('收藏'),
      )
    ]);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: items,
    ).then((selected) {
      if (selected != null) {
        switch (selected) {
          case "delete":
            _deleteMessage(model.message.messageId);
            break;
          case "copy":
            break;
          case "forward":
            break;
          case "recall":
            _recallMessage(model.message.messageId, model.message.messageUid!);
            break;
          case "multi_select":
            break;
          case "quote":
            break;
          case "favorite":
            break;
        }
      }
    });
  }

  void _recallMessage(int messageId, int messageUid) {
    Imclient.recallMessage(messageUid, () {}, (errorCode) {});
  }

  void _deleteMessage(int messageId) {
    Imclient.deleteMessage(messageId).then((value) {
      setState(() {
        for (var model in models) {
          if (model.message.messageId == messageId) {
            models.remove(model);
            break;
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> actions = [];
    if (widget.conversation.conversationType != ConversationType.Chatroom) {
      actions = [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ConversationSettingPage(widget.conversation)),
            );
          },
          icon: const Icon(Icons.more_horiz_rounded),
        )
      ];
    }
    var conversationViewModel = Provider.of<ConversationViewModel>(context);
    var conversationMessageList = conversationViewModel.conversationMessageList;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 232, 232, 232),
      appBar: AppBar(
        title: const ConversationAppbarTitle(),
        actions: actions,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
              child: GestureDetector(
                child: NotificationListener(
                  onNotification: notificationFunction,
                  child: ListView.builder(
                    reverse: true,
                    itemBuilder: (BuildContext context, int index) => MessageCell(
                      conversationMessageList[index],
                      (model) => onTapedCell(model),
                      (model) => onDoubleTapedCell(model),
                      (model, offset) => onLongPressedCell(model, offset),
                      (model) => onPortraitTaped(model),
                      (model) => onPortraitLongTaped(model),
                      (model) => onResendTaped(model),
                      (model) => onReadedTaped(model),
                    ),
                    itemCount: conversationMessageList.length,
                  ),
                ),
                onTap: () {
                  _inputBarGlobalKey.currentState!.resetStatus();
                },
              ),
            ),
            _getInputBar(),
          ],
        ),
      ),
    );
  }

  void _sendTyping() {
    _sendTypingTime = DateTime.now().second;
    TypingMessageContent typingMessageContent = TypingMessageContent();
    typingMessageContent.type = TypingType.Typing_TEXT;
    Imclient.sendMessage(widget.conversation, typingMessageContent, successCallback: (messageUid, timestamp) {}, errorCallback: (errorCode) {});
  }

  Widget _getInputBar() {
    return _inputBar;
  }

  @override
  void deactivate() {
    String draft = _inputBarGlobalKey.currentState!.getDraft();
    Imclient.setConversationDraft(widget.conversation, draft);
    super.deactivate();
  }
}

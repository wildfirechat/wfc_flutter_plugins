import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:imclient/model/conversation.dart';
import 'package:wfc_example/messages/input_bar/emoji_board.dart';
import 'package:wfc_example/messages/input_bar/plugin_board.dart';

enum ChatInputBarStatus {
  keyboardStatus,
  pluginStatus,
  emojiStatus,
  recordStatus,
  muteStatus,
  pttStatus
}

typedef OnSendButtonTapedCallback = void Function(String text);
typedef OnTextChangedCallback = void Function(String text);

class MessageInputBar extends StatefulWidget {
  MessageInputBar(this._conversation, {required this.sendButtonTapedCallback, required this.textChangedCallback, required this.pickerImageCallback, required this.pickerFileCallback, required this.pressCallBtnCallback, ChatInputBarStatus chatInputBarStatus = ChatInputBarStatus.keyboardStatus, Key? key}) : _chatInputBarStatus = chatInputBarStatus, super(key: key);
  Conversation _conversation;
  ChatInputBarStatus _chatInputBarStatus;
  final OnSendButtonTapedCallback sendButtonTapedCallback;
  final OnTextChangedCallback textChangedCallback;
  final OnPickerImageCallback pickerImageCallback;
  final OnPickerFileCallback pickerFileCallback;
  final OnPressCallBtnCallback pressCallBtnCallback;

  @override
  State<StatefulWidget> createState() => MessageInputBarState();
}

class MessageInputBarState extends State<MessageInputBar> {
  final TextEditingController _textEditingController = TextEditingController();
  final List<String> emojis = ['😊','😨','😍','😳','😎','😭','😌','😵','😴','😢','😅','😡','😜','😀','😲','😟','😤','😞','😫','😣','😈','😉','😯','😕','😰','😋','😝','😓','😃','😂','😘','😒','😏','😶','😱','😖','😩','😔','😑','😚','😪','😇','🙊','👊','👎','☝','✌','😬','😷','🙈','👌','👏','✊','💪','😆','☺','🙉','👍','🙏','✋','☀','☕','⛄','📚','🎁','🎉','🍦','☁','❄','⚡','💰','🎂','🎓','🍖','☔','⛅','✏','💩','🎄','🍷','🎤','🏀','🀄','💣','📢','🌏','🍫','🎲','🏂','💡','💤','🚫','🌻','🍻','🎵','🏡','💢','📞','🚿','🍚','👪','👼','💊','🔫','🌹','🐶','💄','👫','👽','💋','🌙','🍉','🐷','💔','👻','👿','💍','🌲','🐴','👑','🔥','⭐','⚽','🕖','⏰','😁','🚀','⏳','🏡'];

  late CupertinoTextField _textField;
  late OutlinedButton _recordButton;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    _textField = CupertinoTextField(
      maxLines: 3,
      minLines: 1,
      controller: _textEditingController,
      focusNode: _focusNode,
      onSubmitted: (text){
        _onSendButton();
      }, onChanged: (text) {
        setState(() {

        });
        widget.textChangedCallback(text);
      },
    );
    _focusNode.requestFocus();
    _focusNode.addListener(() {
      if(_focusNode.hasFocus) {
       if(widget._chatInputBarStatus != ChatInputBarStatus.keyboardStatus) {
         setState(() {
           widget._chatInputBarStatus = ChatInputBarStatus.keyboardStatus;
         });
       }
      } else {

      }
    });

    _recordButton = OutlinedButton(onPressed: (){

    }, child: const Text("按下说话"));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(width: 1, color: Color(0xFFDDDDDD)),
              left: BorderSide(width: 1, color: Color(0xFFDDDDDD)),
              right: BorderSide(width: 1, color: Color(0xFFDDDDDD)),
              bottom: BorderSide(width: 1, color: Color(0xFFDDDDDD)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              widget._chatInputBarStatus == ChatInputBarStatus.recordStatus ? IconButton(icon: const Icon(Icons.keyboard_alt_rounded), onPressed: _onKeyboardButton) :  IconButton(icon: const Icon(Icons.record_voice_over_rounded), onPressed: _onVoiceButton),
              Expanded(
                child: widget._chatInputBarStatus == ChatInputBarStatus.recordStatus?_recordButton:Padding(padding: EdgeInsets.fromLTRB(0, 5, 0, 5), child: _textField,),
              ),
              IconButton(icon: const Icon(Icons.emoji_emotions), onPressed: _onEmojButton),
              _textEditingController.value.text.isNotEmpty && widget._chatInputBarStatus != ChatInputBarStatus.recordStatus && widget._chatInputBarStatus != ChatInputBarStatus.pluginStatus?
              IconButton(icon: const Icon(Icons.send), onPressed: _onSendButton) :
              IconButton(icon: const Icon(Icons.add_circle_outline_rounded), onPressed: _onPluginButton),
            ],
          ),
        ),
        widget._chatInputBarStatus == ChatInputBarStatus.emojiStatus? EmojiBoard(emojis, pickerEmojiCallback: _onPickEmoji, delEmojiCallback: _onDelEmoji,):Container(),
        widget._chatInputBarStatus == ChatInputBarStatus.pluginStatus? PluginBoard(widget.pickerImageCallback, widget.pickerFileCallback, widget.pressCallBtnCallback):Container(),
      ],
    );
  }

  void resetStatus() {
    if(widget._chatInputBarStatus == ChatInputBarStatus.pluginStatus || widget._chatInputBarStatus == ChatInputBarStatus.emojiStatus) {
      setState(() {
        widget._chatInputBarStatus = ChatInputBarStatus.keyboardStatus;
      });
    }
    _focusNode.unfocus();
  }

  void _onPluginButton() {
    setState(() {
      if(widget._chatInputBarStatus == ChatInputBarStatus.pluginStatus) {
        if(!_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
        widget._chatInputBarStatus = ChatInputBarStatus.keyboardStatus;
      } else {
        if(_focusNode.hasFocus) {
          _focusNode.unfocus();
        }
        widget._chatInputBarStatus = ChatInputBarStatus.pluginStatus;
      }
    });
  }

  void _onSendButton() {
    if(_textEditingController.value.text.isNotEmpty) {
      widget.sendButtonTapedCallback(_textEditingController.value.text);
      _textEditingController.clear();
    }
  }

  void _onEmojButton() {
    setState(() {
      if(widget._chatInputBarStatus == ChatInputBarStatus.emojiStatus) {
        if(!_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
        widget._chatInputBarStatus = ChatInputBarStatus.keyboardStatus;
      } else {
        if(_focusNode.hasFocus) {
          _focusNode.unfocus();
        }
        widget._chatInputBarStatus = ChatInputBarStatus.emojiStatus;
      }
    });
  }

  void _onVoiceButton() {
    setState(() {
      widget._chatInputBarStatus = ChatInputBarStatus.recordStatus;
    });
  }

  void _onKeyboardButton() {
    setState(() {
      if(!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
      widget._chatInputBarStatus = ChatInputBarStatus.keyboardStatus;
    });
  }

  void _insertText(String myText) {
    final text = _textEditingController.text;
    final textSelection = _textEditingController.selection;
    final newText = text.replaceRange(
      textSelection.start,
      textSelection.end,
      myText,
    );
    final myTextLength = myText.length;

    setState(() {
      _textEditingController.text = newText;
      _textEditingController.selection = textSelection.copyWith(
        baseOffset: textSelection.start + myTextLength,
        extentOffset: textSelection.start + myTextLength,
      );
    });
  }

  void _backspace() {
    final text = _textEditingController.text;
    final textSelection = _textEditingController.selection;
    final selectionLength = textSelection.end - textSelection.start;

    // There is a selection.
    if (selectionLength > 0) {
      final newText = text.replaceRange(
        textSelection.start,
        textSelection.end,
        '',
      );
      setState(() {
        _textEditingController.text = newText;
        _textEditingController.selection = textSelection.copyWith(
          baseOffset: textSelection.start,
          extentOffset: textSelection.start,
        );
      });
      return;
    }

    // The cursor is at the beginning.
    if (textSelection.start == 0) {
      return;
    }

    // Delete the previous character
    int charSize = 1;
    if(textSelection.start > 1) {
      String sub = text.substring(textSelection.start-2, textSelection.start);
      if(emojis.contains(sub)) {
        charSize = 2;
      }
    }

    int newStart = textSelection.start - charSize;
    int newEnd = textSelection.start;
    final newText = text.replaceRange(
      newStart,
      newEnd,
      '',
    );
    setState(() {
      _textEditingController.text = newText;
      _textEditingController.selection = textSelection.copyWith(
        baseOffset: newStart,
        extentOffset: newStart,
      );
    });
  }

  void _onPickEmoji(String emoji) {
    _insertText(emoji);
  }

  void _onDelEmoji() {
    _backspace();
  }
}
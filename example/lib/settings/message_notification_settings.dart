import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:imclient/imclient.dart';
import 'package:wfc_example/constants.dart';

import '../general_settings.dart';

class MessageNotificationSettings extends StatelessWidget {
  final List modelList = [
    ['接收新消息通知', 'new_msg_notification'],
    ['接收语音或视频来电通知', 'voip_notification'],
    ['通知显示消息详情', 'new_msg_detail'],
    ['免打扰', 'no_disturb'],
    ['同步草稿', 'sync_draft'],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("消息设置"),),
      body: SafeArea(
        child: ListView.builder(
          itemCount: modelList.length,
          itemBuilder: (BuildContext context, int index) {
            return _buildRow(context, index);
          },
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, int index) {
    String title = modelList[index][0];
    String key = modelList[index][1];
    return MessageNotificationSettingItem(title, key);
  }
}

class MessageNotificationSettingItem extends StatefulWidget {
  final String settingName;
  final String settingKey;

  const MessageNotificationSettingItem(this.settingName, this.settingKey, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => MessageNotificationSettingItemState();
}

class MessageNotificationSettingItemState extends State<MessageNotificationSettingItem> {
  bool isEnabled = false;
  int scope = 0;
  bool revertValue = false;
  int startTime = 0;
  int endTime = 0;


  @override
  void initState() {
    switch(widget.settingKey) {
      case 'new_msg_notification':
        scope = kUserSettingGlobalSilent;
        revertValue = true;
        break;
      case 'voip_notification':
        scope = kUserSettingVoipSilent;
        revertValue = true;
        break;
      case 'new_msg_detail':
        scope = kUserSettingHiddenNotificationDetail;
        revertValue = true;
        break;
      case 'no_disturb':
        scope = kUserSettingNoDisturbing;
        break;
      case 'sync_draft':
        scope = kUserSettingDisableSyncDraft;
        revertValue = true;
        break;
      default:
        return;
    }

    loadData();
  }

  void loadData() {
    Imclient.getUserSetting(scope, "").then((value)  {
      setState(() {
        isEnabled = !(value == null || value.isEmpty || value == '0');
        if(revertValue) {
          isEnabled = !isEnabled;
        }

        if(widget.settingKey == 'no_disturb') {
          startTime = 0;
          endTime = 0;
          if(isEnabled) {
            List<String> values = value.split("|");
            if(values.length == 2) {
              startTime = int.parse(values[0]);
              endTime = int.parse(values[1]);
            }
          }
        }
      });
    });
  }

  String _formatTimeDuration(int startTime, int endTime) {
    //弹出界面限制开始时间和结束时间，假设选择时间是晚上9点到第二天7天
    //东八区的时差是8个小时
    startTime = startTime + 8*60;
    endTime = endTime + 8*60;

    int startHour = startTime~/60;
    int startMin = startTime%60;
    int endHour = endTime~/60;
    int endMin = endTime%60;

    return '${startHour.toString().padLeft(2)}:${startMin.toString().padLeft(2)} - ${endHour.toString().padLeft(2)}:${endMin.toString().padLeft(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Padding(padding: EdgeInsets.all(8)),
            Text(widget.settingName),
            Expanded(child: Container()),
            (widget.settingKey == 'no_disturb' && startTime != endTime) ? Text(_formatTimeDuration(startTime, endTime)):Container(),
            Switch(value: isEnabled, onChanged: (enable) {
              setState(() {
                isEnabled = enable;
              });
              if(revertValue) {
                enable = !enable;
              }

              if(widget.settingKey == 'no_disturb') {
               if(isEnabled) {
                 //弹出界面限制开始时间和结束时间，假设选择时间是晚上9点到第二天7天
                 //东八区的时差是8个小时
                 startTime = 21*60 - 8*60;
                 endTime = 7*60 - 8*60;
                 Imclient.setUserSetting(scope, "", '$startTime|$endTime', () {
                   Fluttertoast.showToast(msg: "设置成功");
                 }, (errorCode) {
                   Fluttertoast.showToast(msg: "网络错误");
                 });
               } else {
                 startTime = 0;
                 endTime = 0;
                 Imclient.setUserSetting(scope, "", "", () {
                   Fluttertoast.showToast(msg: "设置成功");
                 }, (errorCode) {
                   Fluttertoast.showToast(msg: "网络错误");
                   loadData();
                 });
               }
              } else {
                Imclient.setUserSetting(scope, "", enable ? "1" : "0", () {
                  Fluttertoast.showToast(msg: "设置成功");
                }, (errorCode) {
                  Fluttertoast.showToast(msg: "网络错误");
                  loadData();
                });
              }
            })
          ],
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 0.0),
          height: 1,
          color: const Color(0xffebebeb),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DiscoveryTab extends StatelessWidget {
  DiscoveryTab({Key? key}) : super(key: key);

  List modelList = [
    ['assets/images/discover_chatroom.png', '聊天室', 'chatroom'],
    ['assets/images/discover_robot.png', '机器人', 'robot'],
    ['assets/images/discover_channel.png', '频道', 'channel'],
    ['assets/images/discover_devdocs.png', '开发文档', 'devdocs'],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: ListView.builder(
        itemCount: modelList.length,
        itemBuilder: (BuildContext context, int index) { return _buildRow(context, index);},)
      ),
    );
  }

  Widget _buildRow(BuildContext context, int index) {
    Image image = Image.asset(modelList[index][0], width: 20.0, height: 20.0);
    String title = modelList[index][1];
    return GestureDetector(child: Column(children: [
      Container(margin: const EdgeInsets.fromLTRB(10, 10, 5, 10), height: 36, child: Row(children: [image, Expanded(child: Container(margin: EdgeInsets.only(left: 15), child: Text(title),))],),),
      Container(
        margin: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 0.0),
        height: 0.5,
        color: const Color(0xdbdbdbdb),
      ),
    ],),
    onTap: () {
      Fluttertoast.showToast(msg: "方法没有实现");
      print("on tap item $index");
    },);
  }

}
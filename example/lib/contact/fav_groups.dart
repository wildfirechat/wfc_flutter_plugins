import 'package:flutter/material.dart';
import 'package:imclient/imclient.dart';

class FavGroupsPage extends StatefulWidget {
  const FavGroupsPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => FavGroupsPageState();
}

class FavGroupsPageState extends State<FavGroupsPage> {
  List<String> favGroupIds = [];

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Fav group count: ${favGroupIds.length}'),);
  }

  @override
  void initState() {
    super.initState();
    Imclient.getFavGroups().then((groupIds) {
      if(groupIds != null) {
        setState(() {
          favGroupIds = groupIds;
        });
      }
    });
  }
}
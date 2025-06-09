import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:imclient/imclient.dart';
import 'package:imclient/model/group_info.dart';
import 'package:imclient/model/group_member.dart';
import 'package:imclient/model/user_info.dart';
import 'package:wfc_example/repo/group_repo.dart';
import 'package:wfc_example/repo/user_repo.dart';

class GroupViewModel extends ChangeNotifier {
  late StreamSubscription<GroupInfoUpdatedEvent> _groupInfoUpdatedSubscription;
  late StreamSubscription<GroupMembersUpdatedEvent> _groupMembersUpdatedSubscription;

  GroupViewModel() {
    _groupInfoUpdatedSubscription = Imclient.IMEventBus.on<GroupInfoUpdatedEvent>().listen((event) {
      GroupRepo.updateGroupInfos(event.groupInfos);
      notifyListeners();
    });
    _groupMembersUpdatedSubscription = Imclient.IMEventBus.on<GroupMembersUpdatedEvent>().listen((event) {
      _loadAndNotifyGroupMemberUserInfos(event.groupId, event.members);
    });
  }

  GroupInfo? getGroupInfo(String groupId) {
    var groupInfo = GroupRepo.getGroupInfo(groupId);
    if (groupInfo == null) {
      Imclient.getGroupInfo(groupId).then((info) {
        if (info != null && info.updateDt > 0) {
          GroupRepo.putGroupInfo(info);
          notifyListeners();
        }
      });
    }
    return groupInfo;
  }

  List<UserInfo>? getGroupMemberUserInfos(String groupId) {
    var memberUserInfos = UserRepo.getGroupMemberUserInfos(groupId);
    Imclient.getGroupMembers(groupId).then((members) {
      if (memberUserInfos == null || members.length != memberUserInfos.length) {
        _loadAndNotifyGroupMemberUserInfos(groupId, members);
      }
    });
    return memberUserInfos;
  }

  _loadAndNotifyGroupMemberUserInfos(String groupId, List<GroupMember> members) {
    if (members.isNotEmpty) {
      var memberIds = members.map((e) => e.memberId).toList();
      Imclient.getUserInfos(memberIds, groupId: groupId).then((userInfos) {
        UserRepo.putGroupMemberUserInfos(groupId, userInfos);
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _groupInfoUpdatedSubscription.cancel();
    _groupMembersUpdatedSubscription.cancel();
  }
}

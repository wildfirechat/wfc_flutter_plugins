import 'package:flutter/material.dart';
import 'package:imclient/imclient.dart';
import 'package:imclient/model/conversation.dart';
import 'package:imclient/model/group_info.dart';
import 'package:imclient/model/user_info.dart';
import 'package:provider/provider.dart';
import 'package:wfc_example/messages/conversation_member_action_item.dart';
import 'package:wfc_example/messages/conversation_member_item.dart';
import 'package:wfc_example/viewmodel/group_view_model.dart';

class GroupConversationMembersView extends StatelessWidget {
  final Conversation conversation;

  final void Function() onAddActionTap;
  final void Function() onRemoveActionTap;
  final void Function(UserInfo userInfo) onGroupMemberTap;
  final void Function()? onShowMoreGroupMemberTap;

  const GroupConversationMembersView(this.conversation,
      {required this.onGroupMemberTap, required this.onAddActionTap, required this.onRemoveActionTap, this.onShowMoreGroupMemberTap, super.key});

  @override
  Widget build(BuildContext context) {
    GroupViewModel groupViewModel = Provider.of<GroupViewModel>(context);

    List<UserInfo>? groupMemberUserInfos;
    GroupInfo? groupInfo;
    groupMemberUserInfos = groupViewModel.groupMemberUserInfos;
    groupInfo = groupViewModel.groupInfo;
    if ((groupInfo == null) && conversation.conversationType == ConversationType.Group) {
      return Container();
    }

    List<UserInfo> showGroupMemberUserInfos;

    int columnCount = 5;
    int showLines = 4;
    bool hasMore = false;

    bool showAddAction = false;
    bool showRemoveAction = false;

    late int memberCount;
    showGroupMemberUserInfos = groupMemberUserInfos;
    memberCount = groupMemberUserInfos.length;
    int moreItemCount = 0;
    if (groupInfo!.type != GroupType.Organization) {
      if (groupInfo.owner == Imclient.currentUserId) {
        moreItemCount = 2;
        showAddAction = true;
        showRemoveAction = true;
      } else {
        moreItemCount = 1;
        showAddAction = true;
      }
    }

    memberCount += moreItemCount;

    if (memberCount > columnCount * showLines) {
      showGroupMemberUserInfos = groupMemberUserInfos.sublist(0, columnCount * showLines - moreItemCount);
      memberCount = columnCount * showLines;
      hasMore = true;
    }

    double screenWidth = MediaQuery.of(context).size.width;

    int lines = (memberCount - 1) ~/ columnCount + 1;
    double gridHeight = (screenWidth / 5) * lines;

    return Column(
      children: [
        SizedBox(
          height: gridHeight,
          child: GridView.builder(
              itemCount: memberCount,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
              itemBuilder: (context, index) {
                if (index < showGroupMemberUserInfos.length) {
                  return GestureDetector(
                    onTap: () {
                      onGroupMemberTap(showGroupMemberUserInfos[index]);
                    },
                    child: ConversationMemberItem(showGroupMemberUserInfos[index]),
                  );
                } else {
                  if (showRemoveAction && index == memberCount - 1) {
                    return GestureDetector(
                      onTap: () {
                        onRemoveActionTap();
                      },
                      child: const ConversationMemberActionItem(false),
                    );
                  } else if (showAddAction) {
                    return GestureDetector(
                      onTap: () {
                        onAddActionTap();
                      },
                      child: const ConversationMemberActionItem(true),
                    );
                  } else {
                    return Container();
                  }
                }
              }),
        ),
        hasMore
            ? Center(
                child: TextButton(
                  onPressed: () {
                    onShowMoreGroupMemberTap?.call();
                  },
                  child: const Text("查看更多群成员 >"),
                ),
              )
            : const Padding(padding: EdgeInsets.only(top: 15)),
      ],
    );
  }
}

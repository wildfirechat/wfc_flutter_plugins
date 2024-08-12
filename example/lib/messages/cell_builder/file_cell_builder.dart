
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:imclient/message/file_message_content.dart';
import 'package:wfc_example/messages/cell_builder/portrait_cell_builder.dart';
import 'package:wfc_example/utilities.dart';

import '../message_cell.dart';
import '../message_model.dart';

class FileCellBuilder extends PortraitCellBuilder {
  late FileMessageContent fileMessageContent;

  FileCellBuilder(MessageState state, MessageModel model) : super(state, model) {
    fileMessageContent = model.message.content as FileMessageContent;
  }

  @override
  Widget getContentAres(BuildContext context) {
    String imagePaht = 'assets/images/file_type/${Utilities.fileType(fileMessageContent.name)}.png';
    Image image = Image.asset(imagePaht, width: 32.0, height: 32.0);
    Text nameText = Text(fileMessageContent.name, maxLines: 2, overflow: TextOverflow.ellipsis,);
    SizedBox padding = const SizedBox(width: 3, height: 3,);
    Text sizeText = Text(Utilities.formatSize(fileMessageContent.size), style: const TextStyle(fontSize: 12),);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        padding,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(constraints: BoxConstraints(maxWidth:PlatformDispatcher.instance.views.first.physicalSize.width/PlatformDispatcher.instance.views.first.devicePixelRatio/3), child: nameText,),
            padding,
            sizeText,
          ],
        ),
        SizedBox(width: 32, height: 32, child: image,),
        padding,
      ],
    );
  }
}

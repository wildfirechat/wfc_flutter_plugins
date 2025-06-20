import 'package:flutter/cupertino.dart';

import '../message_cell.dart';
import '../../ui_model/ui_message.dart';
import 'message_cell_builder.dart';

class UnknownCellBuilder extends MessageCellBuilder {
  UnknownCellBuilder(super.context, super.model);

  @override
  Widget buildContent(BuildContext context) {
    return const Text(
      '该消息暂未实现，请升级版本!',
      textAlign: TextAlign.center,
    );
  }
}

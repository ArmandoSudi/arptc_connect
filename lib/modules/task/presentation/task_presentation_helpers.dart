import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/task/domain/task.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String taskStatusLabel(S l10n, TaskStatus status) {
  switch (status) {
    case TaskStatus.newTask:
      return l10n.taskStatusNew;
    case TaskStatus.doing:
      return l10n.taskStatusDoing;
    case TaskStatus.done:
      return l10n.taskStatusDone;
    case TaskStatus.archived:
      return l10n.taskStatusArchived;
  }
}

String taskTypeLabel(S l10n, TaskType type) {
  switch (type) {
    case TaskType.task:
      return l10n.taskTypeTask;
    case TaskType.mail:
      return l10n.taskTypeMail;
  }
}

String formatTaskDate(BuildContext context, DateTime date) {
  return DateFormat.yMMMd(Localizations.localeOf(context).toString())
      .add_Hm()
      .format(date);
}

bool isTaskAttachmentImage(TaskAttachment attachment) {
  if (attachment.contentType.startsWith('image/')) return true;
  final lowerName = attachment.fileName.toLowerCase();
  return lowerName.endsWith('.png') ||
      lowerName.endsWith('.jpg') ||
      lowerName.endsWith('.jpeg') ||
      lowerName.endsWith('.webp');
}

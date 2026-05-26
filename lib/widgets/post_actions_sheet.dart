import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/room_post.dart';
import '../services/moderation_service.dart';
import '../theme.dart';

/// Show a bottom sheet with moderation actions for a [RoomPost].
/// The viewer's own posts get fewer actions (no "block self").
Future<void> showPostActionsSheet({
  required BuildContext context,
  required RoomPost post,
  required String currentUserId,
}) async {
  final isOwn = post.senderId == currentUserId;
  final moderation = ModerationService();
  final l = AppLocalizations.of(context);

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: MomentoTheme.deepPlum.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            if (!isOwn) ...[
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.red),
                title: Text(l.postActionsReportTitle),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final reason = await _askReason(context, l.postActionsReportPrompt);
                  if (reason == null) return;
                  await moderation.reportPost(
                    reporterId: currentUserId,
                    reportedUserId: post.senderId,
                    roomId: post.roomId,
                    postId: post.id,
                    reason: reason,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.postActionsReportSubmitted)),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: Text(l.postActionsBlockUser(post.senderName)),
                subtitle: Text(l.postActionsBlockDescription),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final ok = await _confirmBlock(context, post.senderName);
                  if (ok != true) return;
                  await moderation.blockUser(
                    currentUserId: currentUserId,
                    targetUserId: post.senderId,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.postActionsUserBlocked(post.senderName))),
                    );
                  }
                },
              ),
            ] else ...[
              ListTile(
                leading: Icon(
                  Icons.info_outline,
                  color: MomentoTheme.deepPlum.withValues(alpha: 0.6),
                ),
                title: Text(l.postActionsOwnPost),
                subtitle: Text(l.postActionsNoActions),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

Future<String?> _askReason(BuildContext context, String prompt) async {
  final controller = TextEditingController();
  final l = AppLocalizations.of(context);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(prompt),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 200,
        decoration: InputDecoration(
          hintText: l.postActionsReportPlaceholder,
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: Text(l.commonSubmit),
        ),
      ],
    ),
  );
}

Future<bool?> _confirmBlock(BuildContext context, String name) async {
  final l = AppLocalizations.of(context);
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.postActionsBlockTitle(name)),
      content: Text(l.postActionsBlockBody(name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(l.postActionsBlock),
        ),
      ],
    ),
  );
}

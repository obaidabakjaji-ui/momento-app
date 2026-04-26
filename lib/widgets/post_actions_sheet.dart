import 'package:flutter/material.dart';
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
                title: const Text('Report this post'),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final reason = await _askReason(context, 'Why are you reporting this post?');
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
                      const SnackBar(content: Text('Report submitted. Thanks.')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: Text('Block ${post.senderName}'),
                subtitle: const Text("You won't see their posts in any room"),
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
                      SnackBar(content: Text('${post.senderName} blocked.')),
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
                title: const Text('This is your own post'),
                subtitle: const Text('No moderation actions available'),
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
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(prompt),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 200,
        decoration: const InputDecoration(
          hintText: 'Optional — describe what is wrong',
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('Submit'),
        ),
      ],
    ),
  );
}

Future<bool?> _confirmBlock(BuildContext context, String name) async {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Block $name?'),
      content: Text(
        "You won't see $name's posts in any room. They won't be notified.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Block'),
        ),
      ],
    ),
  );
}

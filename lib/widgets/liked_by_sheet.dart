import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/firestore_service.dart';
import '../theme.dart';

/// Bottom sheet showing the list of users who liked a post.
Future<void> showLikedBySheet({
  required BuildContext context,
  required List<String> userIds,
}) async {
  if (userIds.isEmpty) return;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _LikedBySheet(userIds: userIds),
  );
}

class _LikedBySheet extends StatelessWidget {
  final List<String> userIds;
  const _LikedBySheet({required this.userIds});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.favorite,
                      size: 18, color: MomentoTheme.coral),
                  const SizedBox(width: 8),
                  Text(
                    'Liked by ${userIds.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MomentoTheme.deepPlum,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<AppUser>>(
                future: FirestoreService().getUsers(userIds),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final users = snap.data!;
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: users.length,
                    itemBuilder: (_, i) {
                      final u = users[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: MomentoTheme.softPink,
                          backgroundImage: u.photoUrl != null
                              ? NetworkImage(u.photoUrl!)
                              : null,
                          child: u.photoUrl == null
                              ? Text(
                                  u.displayName.isNotEmpty
                                      ? u.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: MomentoTheme.coral,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          u.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: MomentoTheme.deepPlum,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

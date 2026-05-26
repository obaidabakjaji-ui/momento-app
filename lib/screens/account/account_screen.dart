import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/room_service.dart';
import '../../services/moderation_service.dart';
import '../../services/locale_service.dart';
import '../../models/app_user.dart';
import '../../models/room.dart';
import '../../theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../legal_urls.dart';
import '../auth/auth_screen.dart';
import 'edit_profile_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _auth = AuthService();
  final _firestore = FirestoreService();
  final _rooms = RoomService();
  final _moderation = ModerationService();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final uid = _auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text(l.accountTitle)),
      body: StreamBuilder<AppUser?>(
        stream: _firestore.watchUser(uid),
        builder: (context, userSnap) {
          final user = userSnap.data;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildProfileCard(user),
              if (user.currentStreak > 0) ...[
                const SizedBox(height: 12),
                _buildStreakCard(user),
              ],
              const SizedBox(height: 24),
              _sectionTitle(l.accountActiveRooms),
              const SizedBox(height: 4),
              Text(
                l.accountActiveRoomsDescription,
                style: TextStyle(
                  fontSize: 12,
                  color: MomentoTheme.deepPlum.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              _buildRoomList(user, user.activeRoomIds, emptyText: l.accountNoActiveRooms),
              const SizedBox(height: 24),
              _sectionTitle(l.accountFavoriteRooms),
              const SizedBox(height: 4),
              Text(
                l.accountFavoriteRoomsDescription,
                style: TextStyle(
                  fontSize: 12,
                  color: MomentoTheme.deepPlum.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              _buildRoomList(user, user.favoriteRoomIds,
                  emptyText: l.accountNoFavorites),
              const SizedBox(height: 24),
              _sectionTitle(l.accountBlockedUsers),
              const SizedBox(height: 8),
              _buildBlockedList(user),
              const SizedBox(height: 32),
              _sectionTitle(l.accountLanguage),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l.accountLanguage),
                  subtitle: Text(
                    LocaleService.displayName(LocaleService.instance.locale, l),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLanguagePicker(context),
                ),
              ),
              const SizedBox(height: 24),
              _sectionTitle(l.accountLegal),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(l.accountTermsOfService),
                      trailing: const Icon(Icons.open_in_new, size: 16),
                      onTap: () => launchUrl(Uri.parse(kTermsOfServiceUrl)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: Text(l.accountPrivacyPolicy),
                      trailing: const Icon(Icons.open_in_new, size: 16),
                      onTap: () => launchUrl(Uri.parse(kPrivacyPolicyUrl)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await _auth.signOut();
                  if (!mounted) return;
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (_) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: Text(l.accountSignOut),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _confirmDeleteAccount,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.withValues(alpha: 0.7),
                ),
                child: Text(l.accountDeleteMy),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.accountDeleteTitle),
        content: Text(l.accountDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _auth.deleteAccount();
      if (!mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        messenger.showSnackBar(SnackBar(
          content: Text(l.accountReauthRequired),
        ));
      } else {
        messenger.showSnackBar(SnackBar(content: Text(l.accountFailedWithMessage(e.message ?? ''))));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.commonFailedWithError(e.toString()))));
    }
  }

  Future<void> _showLanguagePicker(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final current = LocaleService.instance.locale;
    final picked = await showModalBottomSheet<Locale?>(
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
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    l.accountLanguage,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: MomentoTheme.deepPlum,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text(l.accountLanguageSystem),
                trailing: current == null
                    ? const Icon(Icons.check, color: MomentoTheme.coral)
                    : null,
                onTap: () => Navigator.pop(sheetCtx, null),
              ),
              ...LocaleService.selectableLocales.map((loc) {
                final selected = current?.languageCode == loc.languageCode;
                return ListTile(
                  title: Text(LocaleService.displayName(loc, l)),
                  trailing: selected
                      ? const Icon(Icons.check, color: MomentoTheme.coral)
                      : null,
                  onTap: () => Navigator.pop(sheetCtx, loc),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    // null from cancel vs explicit pop. Both null-locale and a Locale are valid choices.
    if (picked == null && current == null) return;
    await LocaleService.instance.setLocale(picked);
  }

  Widget _buildProfileCard(AppUser user) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: MomentoTheme.coral,
            backgroundImage:
                user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child: user.photoUrl == null
                ? Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: MomentoTheme.deepPlum,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    color: MomentoTheme.deepPlum.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.accountRoomsCount(user.roomIds.length),
                  style: TextStyle(
                    color: MomentoTheme.deepPlum.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l.accountEditProfile,
            color: MomentoTheme.coral,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditProfileScreen(user: user),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(AppUser user) {
    final l = AppLocalizations.of(context);
    final best = user.longestStreak;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [MomentoTheme.coral, MomentoTheme.warmOrange],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department,
              color: Colors.white, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.accountStreakDays(user.currentStreak),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  best > user.currentStreak
                      ? l.accountStreakBest(best)
                      : l.accountStreakKeepGoing,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: MomentoTheme.deepPlum,
      ),
    );
  }

  Widget _buildBlockedList(AppUser user) {
    final l = AppLocalizations.of(context);
    if (user.blockedUserIds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          l.accountNoBlocked,
          style: TextStyle(
            color: MomentoTheme.deepPlum.withValues(alpha: 0.5),
          ),
        ),
      );
    }
    return FutureBuilder<List<AppUser>>(
      future: _firestore.getUsers(user.blockedUserIds),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: snap.data!.map((blocked) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: MomentoTheme.softPink,
                    backgroundImage: blocked.photoUrl != null
                        ? NetworkImage(blocked.photoUrl!)
                        : null,
                    child: blocked.photoUrl == null
                        ? Text(
                            blocked.displayName.isNotEmpty
                                ? blocked.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: MomentoTheme.coral,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      blocked.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: MomentoTheme.deepPlum,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _moderation.unblockUser(
                      currentUserId: user.uid,
                      targetUserId: blocked.uid,
                    ),
                    child: Text(l.accountUnblock),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRoomList(
    AppUser user,
    List<String> roomIds, {
    required String emptyText,
  }) {
    if (roomIds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          emptyText,
          style: TextStyle(
            color: MomentoTheme.deepPlum.withValues(alpha: 0.5),
          ),
        ),
      );
    }
    return FutureBuilder<List<Room>>(
      future: _rooms.getRooms(roomIds),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: snap.data!
              .map((room) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: MomentoTheme.softPink,
                          backgroundImage: room.photoUrl != null
                              ? NetworkImage(room.photoUrl!)
                              : null,
                          child: room.photoUrl == null
                              ? Text(
                                  room.name.isNotEmpty
                                      ? room.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: MomentoTheme.coral,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            room.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: MomentoTheme.deepPlum,
                            ),
                          ),
                        ),
                        Text(
                          room.code,
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 2,
                            color: MomentoTheme.deepPlum.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

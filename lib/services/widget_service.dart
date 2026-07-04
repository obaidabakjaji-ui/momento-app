import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/app_user.dart';
import 'room_service.dart';

const _appGroupId = 'group.com.momento.momento';
const _androidWidgetName = 'MomentoWidgetReceiver';
const _iOSWidgetName = 'MomentoWidget';
const _channel = MethodChannel('com.momento.momento/appgroup');

/// Lightweight DTO passed to [WidgetService.updateWidgetWithPosts].
///
/// [postId] / [roomId] are pushed to the widget alongside the displayable
/// fields so the native receiver can address the underlying Firestore doc
/// for tap actions (open the post in-app, double-tap to like).
class WidgetPost {
  final String imageUrl;
  final String senderName;
  final String roomName;
  final bool isFavoriteRoom;
  final String? caption;
  final int likeCount;
  final String postId;
  final String roomId;

  /// Unix milliseconds. Used natively to render "2h ago".
  final int createdAtMs;

  const WidgetPost({
    required this.imageUrl,
    required this.senderName,
    required this.roomName,
    required this.postId,
    required this.roomId,
    this.isFavoriteRoom = false,
    this.caption,
    this.likeCount = 0,
    required this.createdAtMs,
  });
}

class WidgetService {
  // De-dup state shared across instances. The launcher visibly flickers
  // every time we touch the widget — even if the receiver dedups on its
  // side. Catching identical pushes here is cheaper and silent.
  static String _lastSignature = '';
  static DateTime _lastRefreshAt = DateTime.fromMillisecondsSinceEpoch(0);
  static bool _refreshInFlight = false;
  static const _refreshThrottle = Duration(seconds: 5);

  Future<void> initialize() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  /// Pull the user's freshest visible posts straight from Firestore and
  /// push them to the widget. Used at three call sites:
  ///   1. After the user posts a new huddle (so the widget reflects the
  ///      new photo without waiting for the feed StreamBuilder to redraw).
  ///   2. When the app comes to foreground (covers "I came back to the
  ///      app and the widget was still showing yesterday's photos").
  ///   3. The Workmanager background job (so the widget keeps cycling new
  ///      content even when the app hasn't been opened in hours).
  ///
  /// Serialised + throttled: if one refresh is mid-flight, additional calls
  /// short-circuit instead of stacking up. After a successful run, further
  /// non-forced calls within [_refreshThrottle] are skipped — the app-resume
  /// and BG-task paths fire often and don't need sub-5s freshness.
  ///
  /// [force] bypasses the throttle for explicit user actions (posting a
  /// photo): the user just created content and expects the widget to reflect
  /// it immediately, even if a passive refresh ran a second ago. The
  /// in-flight guard is always respected so two refreshes never race.
  Future<void> refreshForUser(String uid, {bool force = false}) async {
    if (_refreshInFlight) return;
    if (!force &&
        DateTime.now().difference(_lastRefreshAt) < _refreshThrottle) {
      return;
    }
    _refreshInFlight = true;
    try {
      await _doRefreshForUser(uid);
      _lastRefreshAt = DateTime.now();
    } catch (e, st) {
      debugPrint('WidgetService.refreshForUser failed: $e\n$st');
    } finally {
      _refreshInFlight = false;
    }
  }

  Future<void> _doRefreshForUser(String uid) async {
    try {
      debugPrint('WidgetService.refresh: START uid=$uid');
      await initialize();
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!userDoc.exists) {
        debugPrint('WidgetService.refresh: no user doc, clearing');
        await clearWidget();
        return;
      }
      final user = AppUser.fromFirestore(userDoc);
      final sourceRoomIds =
          user.activeRoomIds.isNotEmpty ? user.activeRoomIds : user.roomIds;
      debugPrint('WidgetService.refresh: sourceRoomIds=$sourceRoomIds '
          '(active=${user.activeRoomIds.length}, all=${user.roomIds.length})');
      if (sourceRoomIds.isEmpty) {
        debugPrint('WidgetService.refresh: no source rooms, clearing');
        await clearWidget();
        return;
      }

      final roomService = RoomService();
      final rooms = await roomService.getRooms(sourceRoomIds);
      final roomMap = {for (final r in rooms) r.id: r};

      final all = <_PostWithRoom>[];
      for (final roomId in sourceRoomIds) {
        final posts = await roomService.getRoomPostsOnce(roomId);
        debugPrint('WidgetService.refresh: room=$roomId fetched ${posts.length} posts');
        for (final p in posts) {
          final ageMin =
              DateTime.now().difference(p.createdAt).inMinutes;
          debugPrint('  post=${p.id} sender=${p.senderName} ageMin=$ageMin');
          all.add(_PostWithRoom(
            postId: p.id,
            imageUrl: p.imageUrl,
            senderName: p.senderName,
            roomId: roomId,
            caption: p.caption,
            likeCount: p.likeCount,
            createdAt: p.createdAt,
            senderId: p.senderId,
          ));
        }
      }

      final blocked = user.blockedUserIds.toSet();
      final favorites = user.favoriteRoomIds.toSet();
      final visible =
          all.where((p) => !blocked.contains(p.senderId)).toList();
      visible.sort((a, b) {
        final af = favorites.contains(a.roomId) ? 0 : 1;
        final bf = favorites.contains(b.roomId) ? 0 : 1;
        if (af != bf) return af - bf;
        return b.createdAt.compareTo(a.createdAt);
      });

      final widgetPosts = visible.take(20).map((p) => WidgetPost(
            imageUrl: p.imageUrl,
            senderName: p.senderName,
            roomName: roomMap[p.roomId]?.name ?? '',
            isFavoriteRoom: favorites.contains(p.roomId),
            caption: p.caption,
            likeCount: p.likeCount,
            postId: p.postId,
            roomId: p.roomId,
            createdAtMs: p.createdAt.millisecondsSinceEpoch,
            // _PostWithRoom doesn't expose sender id since we already
            // filtered blocked above.
          )).toList();

      debugPrint('WidgetService.refresh: pushing ${widgetPosts.length} widget posts');
      await updateWidgetWithPosts(widgetPosts);
      debugPrint('WidgetService.refresh: END');
    } catch (e, st) {
      // The widget refresh runs as fire-and-forget from several call sites
      // (camera send, foreground resume, BG job). A failure here must not
      // tank the calling flow — log so debugging is possible, then bail.
      debugPrint('WidgetService.refreshForUser failed: $e\n$st');
    }
  }

  Future<String> _getImageDirectory() async {
    if (Platform.isIOS) {
      try {
        final path = await _channel.invokeMethod<String>('getAppGroupDirectory');
        if (path != null) return path;
      } catch (_) {}
    }
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  /// One photo to render in the widget rotation.
  /// [roomName] is shown as a subtitle so the user knows which room it came from.
  /// [isFavoriteRoom] lets the native widget render a star/highlight.
  /// Items should be passed in display order (favorites already bubbled to front).
  Future<void> updateWidgetWithPosts(List<WidgetPost> posts) async {
    if (posts.isEmpty) {
      if (_lastSignature.isEmpty) return;
      _lastSignature = '';
      await clearWidget();
      return;
    }

    // Cheap content fingerprint — identical posts in the same order should
    // never re-broadcast to the receiver. imageUrl is unique per upload and
    // createdAtMs per post, so the signature changes the moment anything
    // visible changes (new post, deletion, re-sort).
    final signature =
        posts.map((p) => '${p.imageUrl}|${p.createdAtMs}').join(';');
    if (signature == _lastSignature) {
      debugPrint('WidgetService: signature unchanged, skipping push');
      return;
    }

    final dirPath = await _getImageDirectory();
    final paths = <String>[];
    final senders = <String>[];
    final rooms = <String>[];
    final favs = <bool>[];
    final captions = <String>[];
    final likes = <int>[];
    final createdAts = <int>[];
    final postIds = <String>[];
    final roomIds = <String>[];

    for (var i = 0; i < posts.length; i++) {
      final p = posts[i];
      final localPath =
          await _downloadImage(p.imageUrl, '$dirPath/widget_momento_$i.jpg');
      if (localPath != null) {
        paths.add(localPath);
        senders.add(p.senderName);
        rooms.add(p.roomName);
        favs.add(p.isFavoriteRoom);
        captions.add(p.caption ?? '');
        likes.add(p.likeCount);
        createdAts.add(p.createdAtMs);
        postIds.add(p.postId);
        roomIds.add(p.roomId);
      }
    }

    if (paths.isEmpty) {
      // Every download failed (e.g. cold Storage token right after a fresh
      // install). Reset the cached signature so the very next refresh
      // retries instead of treating this empty result as "done".
      _lastSignature = '';
      await clearWidget();
      return;
    }

    await HomeWidget.saveWidgetData('momento_image_paths', jsonEncode(paths));
    await HomeWidget.saveWidgetData('momento_senders', jsonEncode(senders));
    await HomeWidget.saveWidgetData('momento_rooms', jsonEncode(rooms));
    await HomeWidget.saveWidgetData('momento_favorites', jsonEncode(favs));
    await HomeWidget.saveWidgetData('momento_captions', jsonEncode(captions));
    await HomeWidget.saveWidgetData('momento_likes', jsonEncode(likes));
    await HomeWidget.saveWidgetData(
        'momento_created_ats', jsonEncode(createdAts));
    await HomeWidget.saveWidgetData('momento_post_ids', jsonEncode(postIds));
    await HomeWidget.saveWidgetData('momento_room_ids', jsonEncode(roomIds));
    await HomeWidget.saveWidgetData('momento_count', paths.length.toString());
    // Single-item fields kept for native widgets that haven't been updated yet
    await HomeWidget.saveWidgetData('momento_image_path', paths.first);
    await HomeWidget.saveWidgetData('momento_sender', senders.first);
    await HomeWidget.saveWidgetData(
      'momento_timestamp',
      DateTime.now().millisecondsSinceEpoch.toString(),
    );

    // Only cache the signature if EVERY intended post actually downloaded.
    // If some failed, paths.length < posts.length — caching the full
    // signature here would make the next identical refresh dedup-skip and
    // the missing photos would never appear until the post list changed
    // (the "doesn't show until the 3rd photo" bug). Leaving the signature
    // stale forces the next refresh to retry the failed downloads.
    final allSucceeded = paths.length == posts.length;
    _lastSignature = allSucceeded ? signature : '';
    if (!allSucceeded) {
      debugPrint('WidgetService: ${posts.length - paths.length} of '
          '${posts.length} downloads failed — will retry next refresh');
    }
    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
      iOSName: _iOSWidgetName,
    );
  }

  Future<void> clearWidget() async {
    _lastSignature = '';
    await HomeWidget.saveWidgetData('momento_image_paths', '[]');
    await HomeWidget.saveWidgetData('momento_senders', '[]');
    await HomeWidget.saveWidgetData('momento_rooms', '[]');
    await HomeWidget.saveWidgetData('momento_favorites', '[]');
    await HomeWidget.saveWidgetData('momento_captions', '[]');
    await HomeWidget.saveWidgetData('momento_likes', '[]');
    await HomeWidget.saveWidgetData('momento_created_ats', '[]');
    await HomeWidget.saveWidgetData('momento_post_ids', '[]');
    await HomeWidget.saveWidgetData('momento_room_ids', '[]');
    await HomeWidget.saveWidgetData('momento_count', '0');
    await HomeWidget.saveWidgetData('momento_image_path', '');
    await HomeWidget.saveWidgetData('momento_sender', '');
    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
      iOSName: _iOSWidgetName,
    );
  }

  Future<String?> _downloadImage(String url, String savePath) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        debugPrint(
            'WidgetService: download HTTP ${response.statusCode} for $url');
        return null;
      }
      final file = File(savePath);
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } catch (e) {
      debugPrint('WidgetService: download failed for $url: $e');
      return null;
    }
  }
}

/// Internal flattening helper for [WidgetService.refreshForUser] — we
/// iterate per-room and collect posts into one list before sorting.
class _PostWithRoom {
  final String postId;
  final String imageUrl;
  final String senderName;
  final String senderId;
  final String roomId;
  final String? caption;
  final int likeCount;
  final DateTime createdAt;

  const _PostWithRoom({
    required this.postId,
    required this.imageUrl,
    required this.senderName,
    required this.senderId,
    required this.roomId,
    required this.caption,
    required this.likeCount,
    required this.createdAt,
  });
}

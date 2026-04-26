import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

const _appGroupId = 'group.com.momento.momento';
const _androidWidgetName = 'MomentoWidgetReceiver';
const _iOSWidgetName = 'MomentoWidget';
const _channel = MethodChannel('com.momento.momento/appgroup');

/// Lightweight DTO passed to [WidgetService.updateWidgetWithPosts].
///
/// For video posts, [imageUrl] should be the poster frame and [isVideo]
/// should be true so the native widget can overlay a play indicator.
class WidgetPost {
  final String imageUrl;
  final String senderName;
  final String roomName;
  final bool isFavoriteRoom;
  final String? caption;
  final int likeCount;
  final bool isVideo;

  /// Unix milliseconds. Used natively to render "2h ago".
  final int createdAtMs;

  const WidgetPost({
    required this.imageUrl,
    required this.senderName,
    required this.roomName,
    this.isFavoriteRoom = false,
    this.caption,
    this.likeCount = 0,
    this.isVideo = false,
    required this.createdAtMs,
  });
}

class WidgetService {
  Future<void> initialize() async {
    await HomeWidget.setAppGroupId(_appGroupId);
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
      await clearWidget();
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
    final isVideos = <bool>[];

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
        isVideos.add(p.isVideo);
      }
    }

    if (paths.isEmpty) {
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
    await HomeWidget.saveWidgetData('momento_is_videos', jsonEncode(isVideos));
    await HomeWidget.saveWidgetData('momento_count', paths.length.toString());
    // Single-item fields kept for native widgets that haven't been updated yet
    await HomeWidget.saveWidgetData('momento_image_path', paths.first);
    await HomeWidget.saveWidgetData('momento_sender', senders.first);
    await HomeWidget.saveWidgetData(
      'momento_timestamp',
      DateTime.now().millisecondsSinceEpoch.toString(),
    );

    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
      iOSName: _iOSWidgetName,
    );
  }

  Future<void> clearWidget() async {
    await HomeWidget.saveWidgetData('momento_image_paths', '[]');
    await HomeWidget.saveWidgetData('momento_senders', '[]');
    await HomeWidget.saveWidgetData('momento_rooms', '[]');
    await HomeWidget.saveWidgetData('momento_favorites', '[]');
    await HomeWidget.saveWidgetData('momento_captions', '[]');
    await HomeWidget.saveWidgetData('momento_likes', '[]');
    await HomeWidget.saveWidgetData('momento_created_ats', '[]');
    await HomeWidget.saveWidgetData('momento_is_videos', '[]');
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
      if (response.statusCode != 200) return null;
      final file = File(savePath);
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }
}

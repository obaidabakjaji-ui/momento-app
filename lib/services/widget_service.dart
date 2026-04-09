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

  /// Update widget with multiple momentos for rotation
  Future<void> updateWidgetWithMomentos(
    List<Map<String, String>> momentos, // [{imageUrl, senderName}]
  ) async {
    if (momentos.isEmpty) {
      await clearWidget();
      return;
    }

    final dirPath = await _getImageDirectory();
    final paths = <String>[];
    final names = <String>[];

    for (var i = 0; i < momentos.length; i++) {
      final url = momentos[i]['imageUrl']!;
      final name = momentos[i]['senderName']!;
      final localPath = await _downloadImage(url, '$dirPath/widget_momento_$i.jpg');
      if (localPath != null) {
        paths.add(localPath);
        names.add(name);
      }
    }

    if (paths.isEmpty) {
      await clearWidget();
      return;
    }

    // Store as JSON arrays for the native widget to parse
    await HomeWidget.saveWidgetData('momento_image_paths', jsonEncode(paths));
    await HomeWidget.saveWidgetData('momento_senders', jsonEncode(names));
    await HomeWidget.saveWidgetData('momento_count', paths.length.toString());
    // Keep single image for backward compat
    await HomeWidget.saveWidgetData('momento_image_path', paths.first);
    await HomeWidget.saveWidgetData('momento_sender', names.first);
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

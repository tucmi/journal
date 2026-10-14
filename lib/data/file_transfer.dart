import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Moves export files in and out of the app: the share sheet out, a file
/// picker in. Kept behind an interface so the UI can be tested without
/// platform channels.
abstract class FileTransfer {
  /// Offers [contents] to the system share sheet as a file called [fileName].
  Future<void> share({required String fileName, required String contents});

  /// Lets the user pick a JSON file and returns its text, or null if they
  /// cancelled.
  Future<String?> pickJson();
}

class PlatformFileTransfer implements FileTransfer {
  const PlatformFileTransfer();

  @override
  Future<void> share({
    required String fileName,
    required String contents,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(contents, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: fileName,
      ),
    );
  }

  @override
  Future<String?> pickJson() async {
    // FileType.any: Android pickers often do not tag .json as a JSON type.
    final picked = await FilePicker.pickFile();
    final path = picked?.path;
    if (path == null) return null;
    return File(path).readAsString();
  }
}

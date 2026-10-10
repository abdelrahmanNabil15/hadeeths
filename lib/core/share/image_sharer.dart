import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Hands images to the system share sheet.
abstract interface class ImageSharer {
  /// Shares [pngs] (in order) with [text] alongside them.
  Future<void> sharePngs(List<Uint8List> pngs, {required String text});
}

/// Writes the images to the app's temporary folder and opens the system share sheet. Nothing is
/// uploaded by the app; the user chooses where the images go.
class SystemImageSharer implements ImageSharer {
  const SystemImageSharer();

  @override
  Future<void> sharePngs(List<Uint8List> pngs, {required String text}) async {
    final folder = Directory(
      '${(await getTemporaryDirectory()).path}${Platform.pathSeparator}share_cards',
    );
    if (await folder.exists()) await folder.delete(recursive: true);
    await folder.create(recursive: true);
    final files = <XFile>[];
    for (var i = 0; i < pngs.length; i++) {
      final file = File(
        '${folder.path}${Platform.pathSeparator}hadith_${i + 1}.png',
      );
      await file.writeAsBytes(pngs[i], flush: true);
      files.add(XFile(file.path, mimeType: 'image/png'));
    }
    await SharePlus.instance.share(ShareParams(files: files, text: text));
  }
}

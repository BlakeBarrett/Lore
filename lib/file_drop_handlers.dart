import 'package:Lore/artifact.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';

/// Desktop drag-and-drop wrapper. Pure view: the dropped file is reshaped
/// into a [PlatformFile] and handed to the controller's `select` pipeline
/// — hashing via [Artifact.fromFile], saving, remark loading, and the
/// `isCalculating` try/finally all live there, so every failure path
/// resets the busy flag. (Previously this widget did its own
/// `Artifact.fromFile` I/O and left `isCalculating == true` forever when
/// hashing threw.)
class DesktopFileDropHandler extends StatelessWidget {
  const DesktopFileDropHandler(
      {super.key,
      required this.onDrop,
      required this.onCalculating,
      required this.child});

  /// Receives the dropped file reshaped as a [PlatformFile]; the controller
  /// resolves it (path -> `Artifact.fromFile`) and manages the busy flag.
  final void Function(List<PlatformFile> values) onDrop;
  final void Function(bool artifactsCalculating) onCalculating;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    return DropTarget(
        child: child,
        onDragDone: (final details) async {
          final files = details.files;
          if (files.isEmpty) return;
          final dropped = files.first;
          try {
            onDrop([
              PlatformFile(
                name: dropped.name,
                size: await dropped.length(),
                path: dropped.path,
              )
            ]);
          } catch (e) {
            // e.g. the file vanished between drag and drop: nothing was
            // handed to the controller, so nothing is left busy.
            debugPrint('Dropped file could not be read: $e');
          }
        });
  }
}

/// Web drag-and-drop wrapper. Same contract as [DesktopFileDropHandler]:
/// text/MD5/URI drops pass through as Strings; a JS `File` handle is
/// reshaped into a name+bytes [Future] record whose read errors surface
/// inside `select`'s try/finally — so a failed md5 lookup, an unreadable
/// file, or an unknown junk value all reset `isCalculating` exactly once
/// and set the controller's error, instead of being swallowed by a
/// debugPrint or hanging the LinearProgressIndicator. No repo, hashing, or
/// MD5 logic lives here anymore; [onCalculating] stays part of the widget
/// contract but the controller's pipeline owns the flag.
class WebFileDropHandler extends StatelessWidget {
  const WebFileDropHandler(
      {super.key,
      required this.onDrop,
      required this.onCalculating,
      required this.child});

  /// Receives the drop payload: a String for text/MD5/URI drops, or a
  /// `Future<({String name, Uint8List bytes})>` for file drops (resolved
  /// by the controller's `artifactFromInput`). The controller manages the
  /// busy flag.
  final void Function(dynamic value) onDrop;
  final void Function(bool artifactsCalculating) onCalculating;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    // Only the web build ever runs the dropzone callback; on native
    // flutter_dropzone renders an empty widget, and the analyzer's
    // dead_code lint correctly flags the guarded branch there.
    // ignore: dead_code
    if (kIsWeb) {
      late DropzoneViewController controller;
      return Stack(children: [
        DropzoneView(
            cursor: CursorType.Default,
            operation: DragOperation.all,
            onCreated: (final ctrl) => controller = ctrl,
            onDropString: (final value) => onDrop(value),
            onDropFile: (final value) =>
                onDrop(_readDroppedFile(controller, value))),
        child,
      ]);
    }
    return child;
  }
}

Future<({String name, Uint8List bytes})> _readDroppedFile(
    final DropzoneViewController controller,
    final DropzoneFileInterface value) async {
  final fileUrl = await controller.createFileUrl(value);
  try {
    final name = await controller.getFilename(value);
    final bytes = await controller.getFileData(value);
    return (name: name, bytes: bytes);
  } finally {
    await controller.releaseFileUrl(fileUrl);
  }
}

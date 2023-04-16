// ignore_for_file: library_private_types_in_public_api

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class MyApplication extends StatefulWidget {
  const MyApplication({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyApplicationState createState() => _MyApplicationState();
}

class _MyApplicationState extends State<MyApplication> {
  File? _droppedFile;

  void _handleFileDrop(final List<PlatformFile> files) {
    setState(() {
      _droppedFile = File(files[0].path!);
    });
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _droppedFile != null
                ? Text('Dropped file: ${_droppedFile!.path}')
                : Text('Drop a file here'),
          ],
        ),
      ),
    );
  }
}

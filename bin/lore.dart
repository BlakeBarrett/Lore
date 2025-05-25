#!/usr/bin/env dart
import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:Lore/lore_console.dart';

void main(List<String> arguments) async {
  if (arguments.isNotEmpty && !arguments.first.startsWith('-')) {
    // If the first argument is a file or hash, treat as 'print remarks' command
    LoreConsole(['print-remarks', ...arguments]);
    return;
  }

  final parser = ArgParser()
    ..addOption('remark-add', abbr: 'r', help: 'Add a remark to a file or hash')
    ..addOption('md5', help: 'Specify an md5 hash instead of a file');

  final argResults = parser.parse(arguments);
  final remark = argResults['remark-add'] as String?;
  final md5 = argResults['md5'] as String?;
  final rest = argResults.rest;

  if (rest.isEmpty && md5 == null) {
    print('Usage: lore <file> [--remark-add="remark"] [--md5=<hash>]');
    exit(1);
  }

  if (remark != null) {
    // Add remark to file or hash
    final target = md5 ?? rest.first;
    LoreConsole(['add-remark', target, remark]);
  } else {
    // Print remarks for file or hash
    final target = md5 ?? rest.first;
    LoreConsole(['print-remarks', target]);
  }
}

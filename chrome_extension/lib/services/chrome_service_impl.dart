import 'package:chrome_extension/chrome_extension.dart';
import 'package:flutter/foundation.dart';
import 'dart:js' as js;
import 'dart:js_util' as js_util;

import 'chrome_service.dart';

/// Implementation of [ChromeService] that uses the actual Chrome extension APIs
class ChromeServiceImpl implements ChromeService {
  @override
  Future<String?> getCurrentUrl() async {
    try {
      final tabs = await chrome.tabs.query({
        'active': true,
        'currentWindow': true,
      });
      
      if (tabs.isNotEmpty) {
        return tabs.first.url;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current tab: $e');
      return null;
    }
  }

  @override
  String getRedirectUrl() {
    return chrome.identity.getRedirectURL();
  }

  @override
  Future<String?> launchWebAuthFlow({required String url, required bool interactive}) async {
    try {
      final dynamic result = await js_util.promiseToFuture<dynamic>(
        js.context.callMethod('eval', [
          '''
          new Promise((resolve, reject) => {
            chrome.identity.launchWebAuthFlow({
              url: '$url',
              interactive: $interactive
            }, function(responseUrl) {
              if (chrome.runtime.lastError) {
                reject(chrome.runtime.lastError.message);
              } else {
                resolve(responseUrl);
              }
            });
          })
          '''
        ])
      );
      
      return result as String?;
    } catch (e) {
      debugPrint('Error launching auth flow: $e');
      return null;
    }
  }

  @override
  Future<void> storeValue({required String key, required String value}) async {
    try {
      await js_util.promiseToFuture<void>(
        js.context.callMethod('eval', [
          '''
          new Promise((resolve) => {
            chrome.storage.local.set({$key: '$value'}, function() {
              resolve();
            });
          })
          '''
        ])
      );
    } catch (e) {
      debugPrint('Error storing value: $e');
      throw Exception('Failed to store value: $e');
    }
  }

  @override
  Future<String?> getValue({required String key}) async {
    try {
      final result = await js_util.promiseToFuture<dynamic>(
        js.context.callMethod('eval', [
          '''
          new Promise((resolve) => {
            chrome.storage.local.get(['$key'], function(result) {
              if (result && result.$key) {
                resolve(result.$key);
              } else {
                resolve(null);
              }
            });
          })
          '''
        ])
      );
      
      return result as String?;
    } catch (e) {
      debugPrint('Error getting value: $e');
      return null;
    }
  }

  @override
  Future<void> removeValue({required String key}) async {
    try {
      await js_util.promiseToFuture<void>(
        js.context.callMethod('eval', [
          '''
          new Promise((resolve) => {
            chrome.storage.local.remove(['$key'], function() {
              resolve();
            });
          })
          '''
        ])
      );
    } catch (e) {
      debugPrint('Error removing value: $e');
      throw Exception('Failed to remove value: $e');
    }
  }
}
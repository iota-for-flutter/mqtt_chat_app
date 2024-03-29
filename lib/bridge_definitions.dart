// AUTO GENERATED FILE, DO NOT EDIT.
// Generated by `flutter_rust_bridge`@ 1.82.6.
// ignore_for_file: non_constant_identifier_names, unused_element, duplicate_ignore, directives_ordering, curly_braces_in_flow_control_structures, unnecessary_lambdas, slash_for_doc_comments, prefer_const_literals_to_create_immutables, implicit_dynamic_list_literal, duplicate_import, unused_import, unnecessary_import, prefer_single_quotes, prefer_const_constructors, use_super_parameters, always_use_package_imports, annotate_overrides, invalid_use_of_protected_member, constant_identifier_names, invalid_use_of_internal_member, prefer_is_empty, unnecessary_const

import 'dart:convert';
import 'dart:async';
import 'package:meta/meta.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:uuid/uuid.dart';

abstract class Rust {
  Stream<LogEntry> createLogStream({dynamic hint});

  FlutterRustBridgeTaskConstMeta get kCreateLogStreamConstMeta;

  Future<void> rustSetUp({dynamic hint});

  FlutterRustBridgeTaskConstMeta get kRustSetUpConstMeta;

  Future<String> publishMessage(
      {required String tag,
      required String userId,
      required String user,
      required String message,
      dynamic hint});

  FlutterRustBridgeTaskConstMeta get kPublishMessageConstMeta;

  Future<String> setupMqtt({required String nodeUrl, dynamic hint});

  FlutterRustBridgeTaskConstMeta get kSetupMqttConstMeta;

  Future<String> subscribeForTag({required String tag, dynamic hint});

  FlutterRustBridgeTaskConstMeta get kSubscribeForTagConstMeta;

  Future<String> unsubscribe({dynamic hint});

  FlutterRustBridgeTaskConstMeta get kUnsubscribeConstMeta;

  Future<String> greet({dynamic hint});

  FlutterRustBridgeTaskConstMeta get kGreetConstMeta;

  Future<Platform> platform({dynamic hint});

  FlutterRustBridgeTaskConstMeta get kPlatformConstMeta;

  Future<bool> rustReleaseMode({dynamic hint});

  FlutterRustBridgeTaskConstMeta get kRustReleaseModeConstMeta;
}

class LogEntry {
  final int timeMillis;
  final int level;
  final String tag;
  final String userId;
  final String user;
  final String msg;

  const LogEntry({
    required this.timeMillis,
    required this.level,
    required this.tag,
    required this.userId,
    required this.user,
    required this.msg,
  });
}

enum Platform {
  Unknown,
  Android,
  Ios,
  Windows,
  Unix,
  MacIntel,
  MacApple,
  Wasm,
}

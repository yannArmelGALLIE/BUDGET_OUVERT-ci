// lib/utils/debug_console.dart
// Logs structurés en console (mode debug uniquement).

import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Désactive tous les appels [debugLogData] sans retirer le code.
bool kDebugLogEnabled = true;

/// Affiche une valeur dans la console (Flutter / `flutter run`, Xcode, Logcat).
/// Utile pour inspecter réponses RPC, JSON, listes, etc.
/// N’agit pas en build **release** (`kDebugMode` est false).
void debugLogData(String label, Object? data) {
  if (!kDebugMode || !kDebugLogEnabled) return;

  try {
    final tree = _toDebugTree(data);
    final encoded =
        const JsonEncoder.withIndent('  ').convert(tree);
    debugPrint('┌── $label ──\n$encoded\n└──────────');
  } catch (_) {
    debugPrint('┌── $label ──\n$data\n└──────────');
  }
}

/// Variante courte pour un message texte.
void debugLogMessage(String tag, [String? detail]) {
  if (!kDebugMode || !kDebugLogEnabled) return;
  debugPrint(detail == null ? '[$tag]' : '[$tag] $detail');
}

dynamic _toDebugTree(dynamic v) {
  if (v == null) return null;
  if (v is BigInt) return v.toString();
  if (v is int || v is double || v is String || v is bool) return v;
  if (v is List) return v.map(_toDebugTree).toList();
  if (v is Map) {
    return v.map((k, e) => MapEntry('$k', _toDebugTree(e)));
  }
  // EthereumAddress, autres objets
  return v.toString();
}

/// Utilisable depuis les services pour convertir un tuple Solidity avant log.
dynamic debugTreeForLog(dynamic v) => _toDebugTree(v);

// lib/services/audio_service.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service audio singleton pour la lecture des fichiers audio multilingues.
/// Gère play/pause/stop et expose l'état via ValueNotifier.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();

  // ── État exposé ───────────────────────────────────────────────────────
  final ValueNotifier<PlayerState> stateNotifier =
      ValueNotifier(PlayerState.stopped);
  final ValueNotifier<Duration> positionNotifier =
      ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> durationNotifier =
      ValueNotifier(Duration.zero);
  final ValueNotifier<String?> currentUrlNotifier =
      ValueNotifier(null);

  bool get isPlaying => stateNotifier.value == PlayerState.playing;
  String? get currentUrl => currentUrlNotifier.value;

  void init() {
    _player.onPlayerStateChanged.listen((state) {
      stateNotifier.value = state;
    });
    _player.onPositionChanged.listen((pos) {
      positionNotifier.value = pos;
    });
    _player.onDurationChanged.listen((dur) {
      durationNotifier.value = dur;
    });
    _player.onPlayerComplete.listen((_) {
      positionNotifier.value = Duration.zero;
      currentUrlNotifier.value = null;
    });
  }

  /// Joue un fichier audio (asset ou URL réseau).
  /// Si c'est le même fichier et qu'il joue → pause.
  /// Si c'est le même fichier et qu'il est en pause → reprend.
  Future<void> playOrPause(String url, {bool isAsset = true}) async {
    if (currentUrlNotifier.value == url) {
      if (isPlaying) {
        await _player.pause();
      } else {
        await _player.resume();
      }
      return;
    }

    // Nouveau fichier
    currentUrlNotifier.value = url;
    positionNotifier.value = Duration.zero;

    if (isAsset) {
      await _player.play(AssetSource(url));
    } else {
      await _player.play(UrlSource(url));
    }
  }

  Future<void> stop() async {
    await _player.stop();
    currentUrlNotifier.value = null;
    positionNotifier.value = Duration.zero;
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void dispose() {
    _player.dispose();
    stateNotifier.dispose();
    positionNotifier.dispose();
    durationNotifier.dispose();
    currentUrlNotifier.dispose();
  }
}

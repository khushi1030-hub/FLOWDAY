import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Service managing audio playback for the alarm experience.
///
/// Guarantees that only one audio source is active at any time.
class AlarmAudioService {
  AlarmAudioService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  bool _isPlaying = false;
  bool _isMuted = false;

  bool get isPlaying => _isPlaying;
  bool get isMuted => _isMuted;

  /// Starts playing the alarm tone.
  Future<void> playAlarmTone({String soundName = 'Soft Chime'}) async {
    try {
      _isPlaying = true;
      if (_isMuted) return;

      final assetPath = _resolveAssetPath(soundName);
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(1.0);
      await _player.setAsset(assetPath);
      await _player.play();
    } catch (e) {
      debugPrint('AlarmAudioService.playAlarmTone caught: $e');
    }
  }

  String _resolveAssetPath(String soundName) {
    final lower = soundName.toLowerCase();
    if (lower.contains('crystal')) return 'assets/audio/crystal_bell.wav';
    if (lower.contains('morning')) return 'assets/audio/morning_breeze.wav';
    if (lower.contains('lofi') || lower.contains('lo-fi')) {
      return 'assets/audio/lofi_piano.wav';
    }
    return 'assets/audio/soft_chime.wav';
  }

  /// Toggles mute state.
  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _player.setVolume(0.0);
    } else {
      _player.setVolume(1.0);
    }
  }

  /// Stops audio playback and resets player state.
  Future<void> stop() async {
    _isPlaying = false;
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('AlarmAudioService.stop caught: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}

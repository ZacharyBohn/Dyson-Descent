import 'package:audioplayers/audioplayers.dart';

/// Singleton that owns the background music player.
///
/// Call [startMusic] once (e.g. when the player presses START).
/// Call [toggleMute] to silence / un-silence without stopping playback.
class AudioManager {
  AudioManager._();
  static final AudioManager instance = AudioManager._();

  final AudioPlayer _player = AudioPlayer();
  bool _started = false;
  bool _isMuted = false;

  bool get isMuted => _isMuted;

  /// Begin looping background music. Safe to call multiple times – only
  /// starts playback on the first call.
  Future<void> startMusic() async {
    if (_started) return;
    _started = true;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('music/Town Center Echoes.mp3'));
  }

  /// Toggle mute state. Adjusts volume without pausing the loop.
  void toggleMute() {
    _isMuted = !_isMuted;
    _player.setVolume(_isMuted ? 0.0 : 1.0);
  }
}

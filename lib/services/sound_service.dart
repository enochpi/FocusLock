import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'settings_service.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _sfxPlayer   = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  // Track what SHOULD be playing so we can restore correctly
  _MusicTrack _currentTrack = _MusicTrack.none;
  bool _isInitialized = false;

  bool get isPlaying => _currentTrack != _MusicTrack.none;
  bool get _soundsOn  => SettingsService().soundsEnabled;

  // ── Init ──────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // ✅ Loop music automatically
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);

    // ✅ When focus music finishes (shouldn't happen with loop,
    // but just in case), fall back to background music
    _musicPlayer.onPlayerComplete.listen((_) {
      if (_currentTrack == _MusicTrack.focus) {
        debugPrint('🎵 Focus music ended unexpectedly — switching to background');
        _currentTrack = _MusicTrack.none;
        playBackgroundMusic();
      }
    });

    // ✅ SFX player: always release after playing so it doesn't loop
    await _sfxPlayer.setReleaseMode(ReleaseMode.release);

    debugPrint('✅ SoundService initialized');
  }

  // ── MUSIC ─────────────────────────────────────────────────────────────

  Future<void> playBackgroundMusic() async {
    if (!_soundsOn) return;

    // ✅ Don't restart if already playing background music
    if (_currentTrack == _MusicTrack.background) return;

    _currentTrack = _MusicTrack.background;

    try {
      await _musicPlayer.stop();
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.play(AssetSource('sounds/background_music.mp3'));
      debugPrint('🎵 Background music started');
    } catch (e) {
      debugPrint('❌ Background music error: $e');
      _currentTrack = _MusicTrack.none;
    }
  }

  Future<void> playFocusMusic() async {
    if (!_soundsOn) return;

    // ✅ Don't restart if already playing focus music
    if (_currentTrack == _MusicTrack.focus) return;

    _currentTrack = _MusicTrack.focus;

    try {
      await _musicPlayer.stop();
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.play(AssetSource('sounds/focus_music.mp3'));
      debugPrint('🎵 Focus music started');
    } catch (e) {
      debugPrint('❌ Focus music error: $e');
      _currentTrack = _MusicTrack.none;
    }
  }

  Future<void> stopMusic() async {
    _currentTrack = _MusicTrack.none;
    await _musicPlayer.stop();
    debugPrint('🎵 Music stopped');
  }

  // ✅ Pause — remembers what was playing so resumeMusic restores it
  Future<void> pauseMusic() async {
    if (_currentTrack == _MusicTrack.none) return;
    try {
      await _musicPlayer.pause();
      debugPrint('🎵 Music paused (track: $_currentTrack)');
    } catch (e) {
      debugPrint('❌ Pause error: $e');
    }
  }

  // ✅ Resume — only resumes if there was something playing
  // and sounds are still enabled
  Future<void> resumeMusic() async {
    if (!_soundsOn) return;
    if (_currentTrack == _MusicTrack.none) return;

    try {
      await _musicPlayer.resume();
      debugPrint('🎵 Music resumed (track: $_currentTrack)');
    } catch (e) {
      // ✅ If resume fails (player was released), restart the track
      debugPrint('⚠️ Resume failed — restarting track: $_currentTrack');
      final track = _currentTrack;
      _currentTrack = _MusicTrack.none;
      if (track == _MusicTrack.background) {
        await playBackgroundMusic();
      } else if (track == _MusicTrack.focus) {
        await playFocusMusic();
      }
    }
  }

  // ✅ Called when focus session ends — always switches to background
  // regardless of what was playing before
  Future<void> switchToBackgroundMusic() async {
    _currentTrack = _MusicTrack.none; // force restart even if track is same
    await playBackgroundMusic();
  }

  // ── SOUND EFFECTS ─────────────────────────────────────────────────────
  // ✅ Each SFX stops the previous SFX before playing
  // but NEVER touches the music player

  Future<void> playSessionComplete() async {
    if (!_soundsOn) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('sounds/session_complete.wav'));
    } catch (e) { debugPrint('❌ SFX error: $e'); }
  }

  Future<void> playDailyReward() async {
    if (!_soundsOn) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('sounds/daily_reward.wav'));
    } catch (e) { debugPrint('❌ SFX error: $e'); }
  }

  Future<void> playPurchase() async {
    if (!_soundsOn) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('sounds/purchase.wav'));
    } catch (e) { debugPrint('❌ SFX error: $e'); }
  }

  Future<void> playCoinConvert() async {
    if (!_soundsOn) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('sounds/coin_convert.wav'));
      // ✅ Resume music after coin convert SFX finishes
      _sfxPlayer.onPlayerComplete.listen((_) => resumeMusic());
    } catch (e) { debugPrint('❌ SFX error: $e'); }
  }

  Future<void> playAchievement() async {
    if (!_soundsOn) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('sounds/achievement.wav'));
    } catch (e) { debugPrint('❌ SFX error: $e'); }
  }

  // ── SETTINGS CHANGED ──────────────────────────────────────────────────
  Future<void> onSettingChanged(bool enabled) async {
    if (!enabled) {
      // ✅ Sounds turned off — stop everything cleanly
      await _sfxPlayer.stop();
      await _musicPlayer.stop();
      _currentTrack = _MusicTrack.none;
      debugPrint('🔇 Sounds disabled — all audio stopped');
    } else {
      // ✅ Sounds turned back on — restart background music
      await playBackgroundMusic();
      debugPrint('🔊 Sounds enabled — background music started');
    }
  }

  // ── APP LIFECYCLE ─────────────────────────────────────────────────────

  // ✅ Call this when app goes to background (screen off / home button)
  Future<void> onAppBackground() async {
    await pauseMusic();
    await _sfxPlayer.stop();
  }

  // ✅ Call this when app comes back to foreground
  Future<void> onAppForeground() async {
    await resumeMusic();
  }

  Future<void> dispose() async {
    await _sfxPlayer.dispose();
    await _musicPlayer.dispose();
  }
}

// ── Track state enum ──────────────────────────────────────────────────
enum _MusicTrack {
  none,
  background,
  focus,
}
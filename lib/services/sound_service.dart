import 'package:audioplayers/audioplayers.dart';
import 'settings_service.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  // Separate players so sounds don't cancel each other
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  bool _isFocusMusicPlaying = false;
  bool _isBackgroundMusicPlaying = false;
  bool get isPlaying => _isFocusMusicPlaying || _isBackgroundMusicPlaying;
  Future<void> init() async {
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setAudioContext(AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
    ));
  }
  // ── Check setting before playing anything ─────────────────────────────
  bool get _soundsOn => SettingsService().soundsEnabled;

  // ── Sound Effects ─────────────────────────────────────────────────────

  Future<void> playSessionComplete() async {
    if (!_soundsOn) return;
    await _sfxPlayer.stop();
    await _sfxPlayer.play(AssetSource('sounds/session_complete.wav'));
  }

  Future<void> playDailyReward() async {
    if (!_soundsOn) return;
    await _sfxPlayer.stop();
    await _sfxPlayer.play(AssetSource('sounds/daily_reward.wav'));
  }

  Future<void> playPurchase() async {
    if (!_soundsOn) return;
    await _sfxPlayer.stop();
    await _sfxPlayer.play(AssetSource('sounds/purchase.wav'));
  }

  Future<void> playCoinConvert() async {
    if (!_soundsOn) return;
    await _sfxPlayer.stop();
    await _sfxPlayer.play(AssetSource('sounds/coin_convert.wav'));
    _sfxPlayer.onPlayerComplete.listen((_) {
      resumeMusic();
    });
  }

  Future<void> playAchievement() async {
    if (!_soundsOn) return;
    await _sfxPlayer.stop();
    await _sfxPlayer.play(AssetSource('sounds/achievement.wav'));
  }

  // ── Music ─────────────────────────────────────────────────────────────

  Future<void> playBackgroundMusic() async {
    if (!_soundsOn || _isBackgroundMusicPlaying) return;
    _isBackgroundMusicPlaying = true;
    _isFocusMusicPlaying = false;
    await _musicPlayer.stop();
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.play(AssetSource('sounds/background_music.mp3'));
  }

  Future<void> playFocusMusic() async {
    if (!_soundsOn || _isFocusMusicPlaying) return;
    _isFocusMusicPlaying = true;
    _isBackgroundMusicPlaying = false;
    await _musicPlayer.stop();
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.play(AssetSource('sounds/focus_music.mp3'));
  }

  Future<void> stopMusic() async {
    _isFocusMusicPlaying = false;
    _isBackgroundMusicPlaying = false;
    await _musicPlayer.stop();
  }

  Future<void> pauseMusic() async {
    await _musicPlayer.pause();
  }

  Future<void> resumeMusic() async {
    if (!_soundsOn) return;
    await _musicPlayer.resume();
  }

  // ── Called when sounds setting is toggled ─────────────────────────────
  Future<void> onSettingChanged(bool enabled) async {
    if (!enabled) {
      await _sfxPlayer.stop();
      await _musicPlayer.stop();
      _isFocusMusicPlaying = false;
      _isBackgroundMusicPlaying = false;
    }
  }

  Future<void> dispose() async {
    await _sfxPlayer.dispose();
    await _musicPlayer.dispose();
  }
}
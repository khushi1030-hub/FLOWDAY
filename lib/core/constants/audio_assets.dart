/// Central registry for bundled audio asset paths.
/// Replacing these files with final audio tracks requires no code changes.
class AudioAssets {
  AudioAssets._();

  static const String softChime = 'assets/audio/soft_chime.mp3';
  static const String morningBreeze = 'assets/audio/morning_breeze.mp3';
  static const String crystalBell = 'assets/audio/crystal_bell.mp3';
  static const String lofiPiano = 'assets/audio/lofi_piano.mp3';

  static const String rainAmbient = 'assets/audio/rain_ambient.mp3';
  static const String lofiAmbient = 'assets/audio/lofi_ambient.mp3';

  static const List<String> notificationSounds = [
    softChime,
    morningBreeze,
    crystalBell,
    lofiPiano,
  ];

  static const List<String> ambientSounds = [
    rainAmbient,
    lofiAmbient,
  ];
}

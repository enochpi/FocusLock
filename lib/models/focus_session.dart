class FocusSession {
  int durationMinutes;
  int elapsedSeconds = 0;
  bool isActive = false;
  DateTime? startTime;

  FocusSession({required this.durationMinutes});

  void start() {
    isActive = true;
    startTime = DateTime.now();
  }

  void pause() {
    isActive = false;
  }

  void stop() {
    isActive = false;
    elapsedSeconds = 0;
  }

  void tick() {
    if (isActive) {
      elapsedSeconds++;
    }
  }

  int get remainingSeconds => (durationMinutes * 60) - elapsedSeconds;
  bool get isComplete => remainingSeconds <= 0;
  int get focusMinutes => elapsedSeconds ~/ 60;

  String get formattedTime {
    int minutes = remainingSeconds ~/ 60;
    int seconds = remainingSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }
}
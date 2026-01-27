class Character {
  String name;
  int totalFocusMinutes = 0;
  int money = 0;
  int focusPoints = 0;
  String currentStage = "cave";

  // Customization
  String skinTone = "light";
  String hairStyle = "short";
  String hairColor = "brown";

  Character({this.name = "Alex"});

  void addFocusMinutes(int minutes) {
    totalFocusMinutes += minutes;
    focusPoints += minutes;
  }

  void spendMoney(int amount) {
    if (money >= amount) {
      money -= amount;
    }
  }

  void earnMoney(int amount) {
    money += amount;
  }

  bool canAfford(int cost) {
    return money >= cost;
  }

  // Milestones
  bool get canGoToCollege => totalFocusMinutes >= 600; // 20 sessions × 30 min
  bool get hasJob => totalFocusMinutes >= 1500; // 50 sessions
  bool get hasFamily => totalFocusMinutes >= 3000; // 100 sessions

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'name': name,
    'totalFocusMinutes': totalFocusMinutes,
    'money': money,
    'focusPoints': focusPoints,
    'currentStage': currentStage,
    'skinTone': skinTone,
    'hairStyle': hairStyle,
    'hairColor': hairColor,
  };

  // Create from JSON
  Character.fromJson(Map<String, dynamic> json)
      : name = json['name'] ?? 'Alex',
        totalFocusMinutes = json['totalFocusMinutes'] ?? 0,
        money = json['money'] ?? 0,
        focusPoints = json['focusPoints'] ?? 0,
        currentStage = json['currentStage'] ?? 'cave',
        skinTone = json['skinTone'] ?? 'light',
        hairStyle = json['hairStyle'] ?? 'short',
        hairColor = json['hairColor'] ?? 'brown';
}
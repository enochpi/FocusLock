class Crop {
  String type;
  int growthProgress = 0;
  int growthRequired;
  int sellPrice;
  bool isReady = false;
  DateTime plantedAt;

  Crop({
    required this.type,
    required this.growthRequired,
    required this.sellPrice,
  }) : plantedAt = DateTime.now();

  void grow(int minutes) {
    growthProgress += minutes;
    if (growthProgress >= growthRequired) {
      isReady = true;
    }
  }

  double get growthPercentage =>
      (growthProgress / growthRequired).clamp(0.0, 1.0);

  int get minutesRemaining =>
      (growthRequired - growthProgress).clamp(0, growthRequired);
}

class CropType {
  String name;
  String emoji;
  int cost;
  int growthTime;
  int sellPrice;

  CropType({
    required this.name,
    required this.emoji,
    required this.cost,
    required this.growthTime,
    required this.sellPrice,
  });

  int get profit => sellPrice - cost;

  static List<CropType> availableCrops = [
    CropType(
      name: "Wheat",
      emoji: "🌾",
      cost: 10,
      growthTime: 30,
      sellPrice: 20,
    ),
    CropType(
      name: "Carrot",
      emoji: "🥕",
      cost: 15,
      growthTime: 45,
      sellPrice: 35,
    ),
    CropType(
      name: "Tomato",
      emoji: "🍅",
      cost: 25,
      growthTime: 60,
      sellPrice: 60,
    ),
    CropType(
      name: "Corn",
      emoji: "🌽",
      cost: 40,
      growthTime: 90,
      sellPrice: 100,
    ),
  ];
}

class Farm {
  List<Crop> crops = [];
  int maxPlots = 5;

  bool canPlant(CropType type, int playerMoney) {
    return crops.length < maxPlots && playerMoney >= type.cost;
  }

  void plant(CropType type) {
    if (crops.length < maxPlots) {
      crops.add(Crop(
        type: type.name,
        growthRequired: type.growthTime,
        sellPrice: type.sellPrice,
      ));
    }
  }

  void growAll(int minutes) {
    for (var crop in crops) {
      if (!crop.isReady) {
        crop.grow(minutes);
      }
    }
  }

  int harvest(int index) {
    if (index < crops.length && crops[index].isReady) {
      int money = crops[index].sellPrice;
      crops.removeAt(index);
      return money;
    }
    return 0;
  }

  int harvestAll() {
    int totalMoney = 0;
    List<Crop> readyCrops = crops.where((c) => c.isReady).toList();

    for (var crop in readyCrops) {
      totalMoney += crop.sellPrice;
      crops.remove(crop);
    }

    return totalMoney;
  }

  int get readyCount => crops.where((c) => c.isReady).length;
  int get growingCount => crops.where((c) => !c.isReady).length;
}
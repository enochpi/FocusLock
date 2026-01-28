class DecorationItem {
  String id;
  String name;
  String emoji;
  int cost;
  bool isOwned;
  String category; // 'bed', 'light', 'floor', 'decoration'
  String? imagePath;

  DecorationItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.cost,
    required this.category,
    this.isOwned = false,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'cost': cost,
    'category': category,
    'isOwned': isOwned,
    'imagePath': imagePath,
  };

  factory DecorationItem.fromJson(Map<String, dynamic> json) => DecorationItem(
    id: json['id'],
    name: json['name'],
    emoji: json['emoji'],
    cost: json['cost'],
    category: json['category'],
    isOwned: json['isOwned'] ?? false,
    imagePath: json['imagePath'],
  );
}

class PlacementSpot {
  String id;
  String category;
  double x; // Position in cave
  double y;
  String? equippedItemId; // What's currently placed here

  PlacementSpot({
    required this.id,
    required this.category,
    required this.x,
    required this.y,
    this.equippedItemId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'x': x,
    'y': y,
    'equippedItemId': equippedItemId,
  };

  factory PlacementSpot.fromJson(Map<String, dynamic> json) => PlacementSpot(
    id: json['id'],
    category: json['category'],
    x: json['x'],
    y: json['y'],
    equippedItemId: json['equippedItemId'],
  );
}

class CaveDecorations {
  List<DecorationItem> availableItems = [];
  List<PlacementSpot> spots = [];

  CaveDecorations() {
    _initializeItems();
    _initializeSpots();
  }

  void _initializeItems() {
    availableItems = [
      // LIGHTS
      DecorationItem(
        id: 'torch',
        name: 'Torch',
        emoji: '🔦',
        cost: 30,
        category: 'light',
        isOwned: true, // Start with basic torch
      ),
      DecorationItem(
        id: 'campfire',
        name: 'Campfire',
        emoji: '🔥',
        cost: 50,
        category: 'light',
      ),
      DecorationItem(
        id: 'lantern',
        name: 'Lantern',
        emoji: '🏮',
        cost: 100,
        category: 'light',
      ),
      DecorationItem(
        id: 'chandelier',
        name: 'Chandelier',
        emoji: '💡',
        cost: 200,
        category: 'light',
      ),
      DecorationItem(
        id: 'crystal_light',
        name: 'Crystal Light',
        emoji: '💎',
        cost: 300,
        category: 'light',
      ),

      // BEDS
      DecorationItem(
        id: 'sleeping_bag',
        name: 'Sleeping Bag',
        emoji: '🎒',
        cost: 0,
        category: 'bed',
        isOwned: true, // Start with this
      ),
      DecorationItem(
        id: 'straw_bed',
        name: 'Straw Bed',
        emoji: '🛏️',
        cost: 80,
        category: 'bed',
      ),
      DecorationItem(
        id: 'wooden_bed',
        name: 'Wooden Bed',
        emoji: '🛏️',
        cost: 150,
        category: 'bed',
      ),
      DecorationItem(
        id: 'comfy_bed',
        name: 'Comfy Bed',
        emoji: '🛌',
        cost: 300,
        category: 'bed',
      ),
      DecorationItem(
        id: 'luxury_bed',
        name: 'Luxury Bed',
        emoji: '🛌',
        cost: 500,
        category: 'bed',
      ),

      // FLOOR
      DecorationItem(
        id: 'dirt_floor',
        name: 'Dirt Floor',
        emoji: '🟫',
        cost: 0,
        category: 'floor',
        isOwned: true,
      ),
      DecorationItem(
        id: 'wood_floor',
        name: 'Wood Floor',
        emoji: '🪵',
        cost: 120,
        category: 'floor',
      ),
      DecorationItem(
        id: 'stone_floor',
        name: 'Stone Floor',
        emoji: '⬜',
        cost: 150,
        category: 'floor',
      ),
      DecorationItem(
        id: 'carpet',
        name: 'Carpet',
        emoji: '🟥',
        cost: 200,
        category: 'floor',
      ),

      // DECORATIONS
      DecorationItem(
        id: 'no_decoration',
        name: 'Empty',
        emoji: '⬜',
        cost: 0,
        category: 'decoration',
        isOwned: true,
      ),
      DecorationItem(
        id: 'shelf',
        name: 'Shelf',
        emoji: '📚',
        cost: 70,
        category: 'decoration',
      ),
      DecorationItem(
        id: 'table',
        name: 'Table',
        emoji: '🪑',
        cost: 90,
        category: 'decoration',
      ),
      DecorationItem(
        id: 'painting',
        name: 'Painting',
        emoji: '🖼️',
        cost: 120,
        category: 'decoration',
      ),
      DecorationItem(
        id: 'chest',
        name: 'Chest',
        emoji: '📦',
        cost: 100,
        category: 'decoration',
      ),
      DecorationItem(
        id: 'plant',
        name: 'Plant',
        emoji: '🪴',
        cost: 60,
        category: 'decoration',
      ),
    ];
  }

  void _initializeSpots() {
    spots = [
      // Light spot (top center)
      PlacementSpot(
        id: 'light_main',
        category: 'light',
        x: 150,
        y: 80,
        equippedItemId: 'torch', // Start with torch
      ),

      // Bed spot (bottom right)
      PlacementSpot(
        id: 'bed_main',
        category: 'bed',
        x: 220,
        y: 450,
        equippedItemId: 'sleeping_bag', // Start with sleeping bag
      ),

      // Floor (background, always equipped)
      PlacementSpot(
        id: 'floor_main',
        category: 'floor',
        x: 0,
        y: 0,
        equippedItemId: 'dirt_floor',
      ),

      // Decoration spots
      PlacementSpot(
        id: 'decoration_1',
        category: 'decoration',
        x: 50,
        y: 300,
      ),
      PlacementSpot(
        id: 'decoration_2',
        category: 'decoration',
        x: 280,
        y: 250,
      ),
      PlacementSpot(
        id: 'decoration_3',
        category: 'decoration',
        x: 150,
        y: 350,
      ),
    ];
  }

  // Get items by category
  List<DecorationItem> getItemsByCategory(String category) {
    return availableItems.where((item) => item.category == category).toList();
  }

  // Get owned items by category
  List<DecorationItem> getOwnedItemsByCategory(String category) {
    return availableItems
        .where((item) => item.category == category && item.isOwned)
        .toList();
  }

  // Purchase item
  bool purchaseItem(String itemId, int playerMoney) {
    DecorationItem? item = availableItems.firstWhere((i) => i.id == itemId);
    if (!item.isOwned && playerMoney >= item.cost) {
      item.isOwned = true;
      return true;
    }
    return false;
  }

  // Equip item to spot
  void equipItem(String spotId, String itemId) {
    PlacementSpot? spot = spots.firstWhere((s) => s.id == spotId);
    spot.equippedItemId = itemId;
  }

  // Unequip item from spot
  void unequipSpot(String spotId) {
    PlacementSpot? spot = spots.firstWhere((s) => s.id == spotId);
    spot.equippedItemId = null;
  }

  // Get equipped item for a spot
  DecorationItem? getEquippedItem(String spotId) {
    PlacementSpot? spot = spots.firstWhere((s) => s.id == spotId);
    if (spot.equippedItemId != null) {
      return availableItems.firstWhere((item) => item.id == spot.equippedItemId);
    }
    return null;
  }

  // Get lighting level for brightness
  int get lightingLevel {
    PlacementSpot? lightSpot = spots.firstWhere((s) => s.category == 'light');
    if (lightSpot.equippedItemId == null) return 0;

    switch (lightSpot.equippedItemId) {
      case 'torch': return 1;
      case 'campfire': return 1;
      case 'lantern': return 2;
      case 'chandelier': return 3;
      case 'crystal_light': return 4;
      default: return 0;
    }
  }

  Map<String, dynamic> toJson() => {
    'availableItems': availableItems.map((i) => i.toJson()).toList(),
    'spots': spots.map((s) => s.toJson()).toList(),
  };

  factory CaveDecorations.fromJson(Map<String, dynamic> json) {
    CaveDecorations decorations = CaveDecorations();

    if (json['availableItems'] != null) {
      decorations.availableItems = (json['availableItems'] as List)
          .map((i) => DecorationItem.fromJson(i))
          .toList();
    }

    if (json['spots'] != null) {
      decorations.spots = (json['spots'] as List)
          .map((s) => PlacementSpot.fromJson(s))
          .toList();
    }

    return decorations;
  }
}
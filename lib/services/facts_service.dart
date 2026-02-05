import 'dart:math';

class FactsService {
  static final FactsService _instance = FactsService._internal();
  factory FactsService() => _instance;
  FactsService._internal();

  final Random _random = Random();
  int? _lastFactIndex;

  // 100 Cool Facts Database
  final List<String> _facts = [
    // Science Facts
    "Honey never spoils. Archaeologists have found 3,000-year-old honey in Egyptian tombs that's still edible!",
    "A day on Venus is longer than a year on Venus. It takes 243 Earth days to rotate once, but only 225 days to orbit the Sun.",
    "Bananas are berries, but strawberries aren't. Botanically, berries come from one flower with one ovary.",
    "Your brain uses 20% of your body's energy while being only 2% of your body weight.",
    "Octopuses have three hearts and blue blood. Two hearts pump blood to the gills, one pumps to the body.",

    // Space Facts
    "One million Earths could fit inside the Sun. The Sun contains 99.86% of the mass in our solar system.",
    "There are more stars in the universe than grains of sand on all Earth's beaches - about 10^24 stars!",
    "A teaspoon of neutron star material would weigh 6 billion tons on Earth.",
    "Saturn's rings are only about 30 feet thick despite being 175,000 miles wide.",
    "The footprints on the Moon will stay there for millions of years - there's no wind to blow them away!",

    // Animal Facts
    "Octopuses can taste with their arms. Each sucker has chemoreceptors to identify food.",
    "Cows have best friends and get stressed when separated from them.",
    "A group of flamingos is called a 'flamboyance' - perfectly named!",
    "Dolphins have names for each other and call out to specific individuals.",
    "Sea otters hold hands while sleeping so they don't drift apart.",

    // Human Body Facts
    "Your stomach lining replaces itself every 3-4 days to prevent it from digesting itself.",
    "You have a unique tongue print, just like fingerprints.",
    "Your brain can survive 4-6 minutes without oxygen before permanent damage occurs.",
    "Humans glow in the dark, but the light is 1,000 times weaker than our eyes can detect.",
    "Your nose can remember 50,000 different scents.",

    // History Facts
    "Cleopatra lived closer to the Moon landing than to the building of the Great Pyramid.",
    "Oxford University is older than the Aztec Empire. Oxford started in 1096, Aztecs in 1428.",
    "The last woolly mammoth died in 2000 BC - 1,000 years after the pyramids were built!",
    "Nintendo was founded in 1889 as a playing card company.",
    "The Great Wall of China is NOT visible from space with the naked eye.",

    // Nature Facts
    "Trees can communicate through an underground fungal network called the 'Wood Wide Web'.",
    "A single bolt of lightning contains enough energy to toast 100,000 slices of bread.",
    "Bamboo can grow up to 35 inches in a single day - you can literally watch it grow!",
    "The world's oldest tree is 5,000+ years old - older than the pyramids!",
    "A cloud can weigh more than a million pounds despite floating in the air.",

    // Technology Facts
    "The first computer bug was an actual bug - a moth found in a computer in 1947.",
    "Your smartphone has more computing power than all of NASA in 1969 for the Moon landing.",
    "The first email was sent in 1971, and the @ symbol was chosen because it didn't appear in names.",
    "Nintendo's Game Boy had less computing power than a modern calculator.",
    "The first YouTube video was uploaded on April 23, 2005, titled 'Me at the zoo'.",

    // Food Facts
    "Apples float in water because they're 25% air.",
    "Pineapples take 2 years to grow. Each plant only produces one pineapple at a time.",
    "Chocolate was once used as currency by the Aztecs. 100 cacao beans = 1 turkey.",
    "Carrots were originally purple, not orange. Orange carrots were bred in the 1600s.",
    "Crackers can explode in your stomach if you swallow them whole - the air pressure builds up!",

    // Ocean Facts
    "The ocean produces 70% of Earth's oxygen, mostly from phytoplankton, not trees.",
    "The deepest part of the ocean is 36,000 feet - Mount Everest would fit with room to spare.",
    "There are more artifacts in the ocean than in all the world's museums combined.",
    "A blue whale's heart is the size of a small car and can be heard from 2 miles away.",
    "The ocean contains 20 million tons of gold, but it's dissolved and nearly impossible to extract.",

    // Random Mind-Blowing Facts
    "You can't hum while holding your nose closed. Try it!",
    "A shrimp's heart is in its head.",
    "If you shuffle a deck of cards, the order has probably never existed before in history.",
    "Your skeleton is wet inside your body right now. Think about that.",
    "Time moves slower at higher altitudes due to gravity. Mountain climbers age faster!",

    // Math & Numbers
    "Zero is the only number that can't be written in Roman numerals.",
    "The number 4 is the only number in English that has the same number of letters as its value.",
    "Pi has been calculated to over 50 trillion digits, but 39 digits is enough to calculate the universe's circumference.",
    "A googol is 10^100. A googolplex is 10^googol - you can't write it out, there's not enough space in the universe!",
    "If you write out all numbers (one, two, three...), 'A' doesn't appear until one thousand.",

    // Language Facts
    "The shortest complete sentence in English is 'I am' or 'Go'.",
    "'Dreamt' is the only English word that ends in 'mt'.",
    "The word 'set' has 464 definitions in the Oxford English Dictionary - the most of any word.",
    "'Uncopyrightable' is the longest English word with no repeated letters.",
    "The dot over the letters 'i' and 'j' is called a 'tittle'.",

    // Weather Facts
    "Lightning strikes Earth 100 times per second - that's 8.6 million times per day!",
    "Raindrops aren't tear-shaped - they're actually round like hamburger buns.",
    "It can rain diamonds on Jupiter and Saturn due to extreme pressure.",
    "The hottest temperature ever recorded on Earth was 134°F in Death Valley, California.",
    "Antarctica is technically a desert - it gets less precipitation than the Sahara!",

    // Music Facts
    "The longest concert ever played is still ongoing - it started in 2001 and will end in 2640!",
    "Beethoven wrote his 9th Symphony while completely deaf, feeling vibrations through the floor.",
    "The world's oldest instrument is a 40,000-year-old flute made from bird bone.",
    "Your heartbeat changes to match the music you're listening to.",
    "Finland has the most heavy metal bands per capita - 53.5 per 100,000 people!",

    // Psychology Facts
    "Your brain is more active while sleeping than watching TV.",
    "Smiling, even if forced, can trick your brain into feeling happier.",
    "You make decisions 7 seconds before you're consciously aware of them.",
    "Humans are the only animals that enjoy spicy food - it's literally pain your brain interprets as pleasure!",
    "You can remember things better if you associate them with strong smells.",

    // Geography Facts
    "Russia has 11 time zones, but China has only 1 (despite being almost as wide).",
    "Africa is the only continent in all four hemispheres (North, South, East, West).",
    "Canada has more lakes than the rest of the world combined - over 3 million!",
    "Vatican City is the smallest country (0.17 sq mi) but has the highest crime rate per capita!",
    "Mount Everest grows about 4mm every year due to tectonic plate movement.",

    // Plant Facts
    "Strawberries are the only fruit with seeds on the outside - about 200 seeds per berry.",
    "Some bamboo species can grow through concrete during their growth spurts.",
    "The corpse flower blooms once every 7-10 years and smells like rotting flesh.",
    "Trees can drown if their roots are underwater for too long.",
    "Apples, peaches, and raspberries are all members of the rose family.",

    // Biology Facts
    "Your body has more bacterial cells than human cells - you're 90% bacteria by cell count!",
    "Humans share 60% of their DNA with bananas.",
    "Your bones are 4 times stronger than concrete, weight for weight.",
    "Red blood cells are so small that 5 million of them fit in one drop of blood.",
    "Your eyes can distinguish about 10 million different colors.",

    // Time Facts
    "A day on Earth is getting 1.7 milliseconds longer every century due to the Moon's pull.",
    "The youngest person in the world is always younger than you were when you started reading this fact.",
    "If Earth's history was compressed into 1 day, humans appeared at 11:58 PM.",
    "You are always looking at the past - it takes time for light to reach your eyes!",
    "Time zones were invented by railroad companies in 1883 to coordinate train schedules.",

    // Bonus Weird Facts
    "A group of pugs is called a 'grumble'. Perfect!",
    "Sloths can hold their breath longer than dolphins - up to 40 minutes!",
    "Wombat poop is cube-shaped to prevent it from rolling away (they use it to mark territory).",
    "Penguins propose to their mates with a pebble - if accepted, they mate for life.",
    "The shortest war in history lasted 38 minutes (Anglo-Zanzibar War, 1896).",
  ];

  /// Get a random fact (won't repeat last fact)
  String getRandomFact() {
    int index;

    // Ensure we don't get the same fact twice in a row
    do {
      index = _random.nextInt(_facts.length);
    } while (index == _lastFactIndex && _facts.length > 1);

    _lastFactIndex = index;
    return _facts[index];
  }

  /// Get total number of facts
  int get totalFacts => _facts.length;

  /// Get a specific fact by index (for testing)
  String getFactByIndex(int index) {
    if (index < 0 || index >= _facts.length) {
      return getRandomFact();
    }
    return _facts[index];
  }
}
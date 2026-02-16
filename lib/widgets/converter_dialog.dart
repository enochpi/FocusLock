import 'package:flutter/material.dart';
import '../services/currency_service.dart';
import '../utils/number_formatter.dart';

class ConverterDialog extends StatefulWidget {
  const ConverterDialog({Key? key}) : super(key: key);

  @override
  State<ConverterDialog> createState() => _ConverterDialogState();
}

class _ConverterDialogState extends State<ConverterDialog> {
  final CurrencyService currency = CurrencyService();
  late int peasToConvert;

  @override
  void initState() {
    super.initState();
    peasToConvert = currency.PEAS_PER_COIN; // Start at minimum (1 coin worth)
  }

  @override
  Widget build(BuildContext context) {
    int maxCoins = currency.getMaxConvertibleCoins();
    int coinsFromConversion = peasToConvert ~/ currency.PEAS_PER_COIN;
    int rate = currency.PEAS_PER_COIN;
    String emoji = currency.cropEmoji;
    String name = currency.cropName;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF2d2d2d),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              '$emoji Convert $name',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$rate ${name.toLowerCase()} = 1 🪙',
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Current amounts
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a1a),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "You have:",
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "${NumberFormatter.format(currency.peas)} $emoji",
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Can convert:",
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "${NumberFormatter.format(maxCoins)} 🪙",
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Slider to choose amount
            if (maxCoins > 0) ...[
              Text(
                "Convert: ${NumberFormatter.format(peasToConvert)} $emoji → ${NumberFormatter.format(coinsFromConversion)} 🪙",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Slider(
                value: peasToConvert.toDouble(),
                min: rate.toDouble(),
                max: (maxCoins * rate).toDouble(),
                divisions: maxCoins > 0 ? maxCoins : 1,
                activeColor: const Color(0xFF4CAF50),
                inactiveColor: const Color(0xFF4CAF50).withOpacity(0.3),
                onChanged: (value) {
                  setState(() {
                    peasToConvert = (value ~/ rate) * rate;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Convert button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    bool success = await currency.convertPeasToCoins(peasToConvert);
                    if (success) {
                      Navigator.pop(context, true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Convert",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Not enough crop message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF4CAF50),
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Need at least $rate $emoji",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Complete focus sessions to earn more ${name.toLowerCase()}!",
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Close button
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                "Close",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to show converter dialog
Future<bool?> showConverterDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => const ConverterDialog(),
  );
}
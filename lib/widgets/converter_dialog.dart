import 'package:flutter/material.dart';
import '../services/currency_service.dart';

class ConverterDialog extends StatefulWidget {
  const ConverterDialog({Key? key}) : super(key: key);

  @override
  State<ConverterDialog> createState() => _ConverterDialogState();
}

class _ConverterDialogState extends State<ConverterDialog> {
  final CurrencyService currency = CurrencyService();
  int peasToConvert = 100;

  @override
  Widget build(BuildContext context) {
    int maxCoins = currency.getMaxConvertibleCoins();
    int coinsFromConversion = peasToConvert ~/ CurrencyService.PEAS_PER_COIN;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFF2d2d2d),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              "Convert Peas to Coins",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "100 🌱 Peas = 1 🪙 Coin",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 24),

            // Current amounts
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF1a1a1a),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "You have:",
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "${currency.peas} 🌱",
                        style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Can convert:",
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "$maxCoins 🪙",
                        style: TextStyle(
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
            SizedBox(height: 24),

            // Slider to choose amount
            if (maxCoins > 0) ...[
              Text(
                "Convert: $peasToConvert 🌱 → $coinsFromConversion 🪙",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Slider(
                value: peasToConvert.toDouble(),
                min: 100,
                max: (maxCoins * 100).toDouble(),
                divisions: maxCoins,
                activeColor: Color(0xFF4CAF50),
                inactiveColor: Color(0xFF4CAF50).withOpacity(0.3),
                onChanged: (value) {
                  setState(() {
                    peasToConvert = (value ~/ 100) * 100;
                  });
                },
              ),
              SizedBox(height: 24),

              // Convert button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    bool success = await currency.convertPeasToCoins(peasToConvert);
                    if (success) {
                      Navigator.pop(context, true); // Return true to refresh UI
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Converted $peasToConvert 🌱 to $coinsFromConversion 🪙!"),
                          backgroundColor: Color(0xFF4CAF50),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4CAF50),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
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
              // Not enough peas message
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(0xFF4CAF50).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF4CAF50),
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Need at least 100 🌱",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Complete focus sessions to earn more peas!",
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],

            // Close button
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
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
    builder: (context) => ConverterDialog(),
  );
}
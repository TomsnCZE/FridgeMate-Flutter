import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// test na vykresleni vsech 5 nutriscore obrazku

class NutriscoreTestScreen extends StatelessWidget {
  const NutriscoreTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutriscore Test'),
        backgroundColor: const Color(0xFFEC9B05),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Nutriscore Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            for (var grade in ['a', 'b', 'c', 'd', 'e'])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    Text(
                      'Nutriscore $grade'.toUpperCase(),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    SvgPicture.asset(
                      'assets/nutriscore/nutriscore-$grade.svg',
                      width: 75,
                      height: 75,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}



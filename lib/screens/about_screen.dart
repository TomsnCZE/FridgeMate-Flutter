import 'package:flutter/material.dart';
//import 'dart:io';
import 'package:google_fonts/google_fonts.dart';


class AboutScreen extends StatelessWidget {
  const AboutScreen ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:const Color.fromARGB(255, 236, 155, 5),
        title: const Text('O aplikaci'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BobSN',
              style: GoogleFonts.rubik(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Verze aplikace: 1.0.0',
              style: GoogleFonts.rubik(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Fridge Mate je aplikace pro správu domácího inventáře potravin. '
              'Umožňuje skenování čárových kódů produktů, sledování jejich trvanlivosti a správu zásob.',
              style: GoogleFonts.rubik(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Vyvinuto s láskou v roce 2025.',
              style: GoogleFonts.rubik(
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme.dart';

class PaletteTestScreen extends StatelessWidget {
  const PaletteTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Palette Test')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _swatch('primary', AppColors.primary, AppColors.white),
          _swatch('primaryDark', AppColors.primaryDark, AppColors.white),
          _swatch('primaryLight', AppColors.primaryLight, AppColors.text),
          _swatch('primaryMid', AppColors.primaryMid, AppColors.text),
          _swatch('white', AppColors.white, AppColors.text, border: true),
          _swatch('text', AppColors.text, AppColors.white),
          _swatch('textMuted', AppColors.textMuted, AppColors.white),
          _swatch('textSubtle', AppColors.textSubtle, AppColors.white),
          _swatch('border', AppColors.border, AppColors.text),
          _swatch('divider', AppColors.divider, AppColors.text),
          _swatch('error', AppColors.error, AppColors.white),
          _swatch('warning', AppColors.warning, AppColors.white),
        ],
      ),
    );
  }

  Widget _swatch(String name, Color bg, Color fg, {bool border = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: border ? Border.all(color: AppColors.border) : null,
      ),
      child: Row(
        children: [
          Text(
            name,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            '#${bg.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
            style: TextStyle(
              color: fg.withValues(alpha: 0.7),
              fontSize: 12,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

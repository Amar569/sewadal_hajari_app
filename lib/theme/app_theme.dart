import 'package:flutter/material.dart';

class AppTheme {
  static const Color headerBlue = Color(0xFF1A3C6E); 
  static const Color gridLine = Color(0xFFBBBBBB);
  static const Color presentGreen = Color(0xFF2E7D32);
  static const Color absentRed = Color(0xFFC62828);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: headerBlue,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: headerBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 1,
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: MaterialStateProperty.all(headerBlue.withOpacity(0.08)),
        dataRowMinHeight: 40,
        dataRowMaxHeight: 52,
      ),
    );
  }
}

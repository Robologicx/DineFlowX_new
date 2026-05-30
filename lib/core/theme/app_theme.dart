import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

class AppTheme {
  // Common border style for input fields

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Color(0xFF3CBFF0),
      brightness: Brightness.light,
    ),

    // colorScheme: ColorScheme(
    //   brightness: Brightness.light,
    //   primary: Color(0xFF3CBFF0), // Sky Blue - main brand
    //   onPrimary: Colors.white,
    //   secondary: Color(0xFF5AC8FA), // Aqua accents
    //   onSecondary: Colors.white,
    //   // background: Color(0xFFF5F9FF), // Very light bluish background
    //   // onBackground: Color(0xFF0B1B34), // Navy text
    //   surface: Color(
    //     0xFFE6F4FB,
    //   ), // Soft blue surface for cards ✅ not pure white
    //   onSurface: Color(0xFF0B1B34),
    //   error: Colors.red,
    //   onError: Colors.white,
    // ),
    cardTheme: CardThemeData(
      color: Color.fromARGB(255, 211, 236, 249), // Matches surface
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: TextTheme(
      bodyLarge: GoogleFonts.poppins(fontSize: 14, color: Color(0xFF0B1B34)),
      bodyMedium: GoogleFonts.poppins(fontSize: 12, color: Color(0xFF0B1B34)),
      titleLarge: GoogleFonts.poppins(
        color: Color(0xFF3CBFF0),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: GoogleFonts.poppins(
        color: Color(0xFF3CBFF0),
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF3CBFF0),
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFFE6F4FB), // light bluish fill
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Color(0xFF3CBFF0),
          width: 1.2,
        ), // Sky Blue
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFF0B1B34), width: 2), // Navy
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.redAccent, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      labelStyle: TextStyle(color: Color(0xFF0B1B34)), // Navy text
      hintStyle: TextStyle(color: Colors.grey.shade600),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF3CBFF0), // light bluish fill
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Color(0xFF3CBFF0),
          width: 1.2,
        ), // Sky Blue
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFF0B1B34), width: 2), // Navy
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.redAccent, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      labelStyle: TextStyle(color: Color(0xFF0B1B34)), // Navy text
      hintStyle: TextStyle(color: Colors.grey.shade600),
    ),
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Color(0xFF0B1B34),
      brightness: Brightness.dark,
    ),
    // colorScheme: ColorScheme(
    //   brightness: Brightness.dark,
    //   primary: Color(0xFF3CBFF0), // Sky Blue brand
    //   onPrimary: Colors.white,
    //   secondary: Color(0xFF5AC8FA),
    //   onSecondary: Colors.black,
    //   // background: Color(0xFF0B1B34), // Deep navy background
    //   // onBackground: Colors.white,
    //   surface: Color(0xFF243B55), // Visible lighter navy for cards ✅
    //   onSurface: Colors.white,
    //   error: Colors.redAccent,
    //   onError: Colors.black,
    // ),
    cardTheme: CardThemeData(
      margin: EdgeInsets.all(10),
      color: Color(0xff011c42), // Clearly visible on dark bg
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    textTheme: TextTheme(
      bodyLarge: GoogleFonts.poppins(fontSize: 14, color: Color(0xFF5AC8FA)),
      bodyMedium: GoogleFonts.poppins(fontSize: 12, color: Color(0xFF5AC8FA)),
      titleLarge: GoogleFonts.poppins(
        color: Color(0xFF5AC8FA),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: GoogleFonts.poppins(
        color: Color(0xFF5AC8FA),
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF5AC8FA),
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  );

  // static ThemeData lightTheme = ThemeData.light(useMaterial3: true).copyWith(
  //   // Backgrounds
  //   scaffoldBackgroundColor: AppColors.backgroundColor,

  //   // AppBar
  //   appBarTheme: AppBarTheme(
  //     backgroundColor: AppColors.transparentColor,
  //     elevation: 0,
  //     centerTitle: true,
  //     titleTextStyle: GoogleFonts.poppins(
  //       fontSize: 20,
  //       fontWeight: FontWeight.bold,
  //       color: AppColors.whiteColor,
  //     ),
  //     iconTheme: IconThemeData(color: AppColors.whiteColor),
  //   ),

  //   // Input Fields
  //   inputDecorationTheme: InputDecorationTheme(
  //     filled: true,
  //     fillColor: AppColors.darkGrey,
  //     hintStyle: GoogleFonts.poppins(
  //       fontSize: 16,
  //       fontWeight: FontWeight.w500,
  //       color: AppColors.whiteColor,
  //     ),
  //     border: _border(),
  //     focusedBorder: _border(AppColors.primaryColor),
  //     disabledBorder: _border(AppColors.lightGrey),
  //     enabledBorder: _border(AppColors.hintTextColor),
  //   ),

  //   // Text
  //   textTheme: TextTheme(
  //     titleLarge: GoogleFonts.poppins(
  //       fontSize: 18,
  //       fontWeight: FontWeight.bold,
  //       color: AppColors.whiteColor,
  //     ),
  //     titleMedium: GoogleFonts.poppins(
  //       fontSize: 16,
  //       fontWeight: FontWeight.bold,
  //       color: AppColors.appTextColor,
  //     ),
  //     bodyMedium: GoogleFonts.poppins(
  //       fontSize: 14,
  //       fontWeight: FontWeight.w500,
  //       color: AppColors.appTextColor,
  //     ),
  //     bodySmall: GoogleFonts.poppins(
  //       fontSize: 12,
  //       fontWeight: FontWeight.w400,
  //       color: AppColors.primaryColor,
  //     ),
  //   ),

  //   // Tabs
  //   tabBarTheme: TabBarThemeData(
  //     labelColor: AppColors.whiteColor,
  //     unselectedLabelColor: AppColors.hintTextColor,
  //     dividerColor: AppColors.transparentColor,
  //     indicatorColor: AppColors.whiteColor,
  //   ),

  //   // Buttons
  //   elevatedButtonTheme: ElevatedButtonThemeData(
  //     style: ElevatedButton.styleFrom(
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
  //       fixedSize: const Size(314, 70),
  //       backgroundColor: AppColors.primaryColor, // CTA Orange
  //       foregroundColor: AppColors.whiteColor,
  //       textStyle: GoogleFonts.poppins(
  //         fontSize: 16,
  //         fontWeight: FontWeight.bold,
  //       ),
  //     ),
  //   ),
  //   // Icons
  //   iconTheme: const IconThemeData(color: AppColors.darkGrey),

  //   // Bottom Navigation
  //   bottomNavigationBarTheme: BottomNavigationBarThemeData(
  //     backgroundColor: AppColors.primaryColor,
  //     selectedIconTheme: IconThemeData(color: AppColors.whiteColor),
  //     unselectedIconTheme: IconThemeData(color: AppColors.whiteColor),
  //     selectedLabelStyle: GoogleFonts.poppins(
  //       fontSize: 12,
  //       fontWeight: FontWeight.bold,
  //     ),
  //     unselectedLabelStyle: GoogleFonts.poppins(
  //       fontSize: 12,
  //       fontWeight: FontWeight.w500,
  //       color: AppColors.whiteColor,
  //     ),
  //   ),
  // );
}

import 'package:arptc_connect/modules/service/screens/main_service_screen.dart';
import 'package:flutter/material.dart';

class Constants {
  static List<String> itemCategories = [
    'Bureau',
    'Nettoyage',
    'Automobile',
  ];

  static List<String> productUnits =[
    'Pièce', 'Boite',
  ];

  static final Map<String, Service> modules = {
    "COURRIER" : Service("Courrier", "courriers", Icons.mail, color: Colors.blue),
    "SOCIAL" : Service("Social", "social", Icons.family_restroom, color: Colors.amber),
    "INVENTORY" : Service("Inventaire", "inventory", Icons.inventory_rounded, color: Colors.red),
    "TICKETING" : Service("Support IT", "ticketing", Icons.airplane_ticket_outlined, color: Colors.deepPurple),
    "PARC_INFORMATIQUE" : Service("Parc Informatique", "ticketing", Icons.devices, color: Colors.greenAccent),
    "TASK" : Service("Activités", "tasks", Icons.task_alt_outlined, color: Colors.pink),
    "MEETING" : Service("Salles de réunion", "meeting-hall", Icons.meeting_room, color: Colors.teal),
  };

}

/// Material Design 3 Color Scheme for Construction Theme
class AppColors {
  // Primary Colors (Construction Orange)
  static const Color primary = Color(0xFFFF6B35);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFFFDAD1);
  static const Color onPrimaryContainer = Color(0xFF3A0A00);

  // Secondary Colors (Steel Blue)
  static const Color secondary = Color(0xFF004E89);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFCFE5FF);
  static const Color onSecondaryContainer = Color(0xFF001D35);

  // Tertiary (Safety Yellow)
  static Color tertiary = Colors.amber.shade700;
  static const Color onTertiary = Color(0xFF000000);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);

  // Background
  static const Color background = Color(0xFFFFFBFF);
  static const Color onBackground = Color(0xFF201B16);

  // Surface
  static const Color surface = Color(0xFFFFFBFF);
  static const Color onSurface = Color(0xFF201B16);

  // Status Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF0288D1);
}

/// Text Styles
class AppTextStyles {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
}
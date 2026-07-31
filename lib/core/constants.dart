import 'package:arptc_connect/modules/service/domain/service.dart';
import 'package:flutter/material.dart';

class Constants {
  static List<String> itemCategories = [
    'Bureau',
    'Nettoyage',
    'Automobile',
  ];

  static List<String> productUnits = [
    'Pièce',
    'Boite',
  ];

  static final Map<String, Service> modules = {
    "COURRIER":
        const Service("Courrier", "courriers", Icons.mail, color: Colors.blue),
    "SOCIAL": const Service("Social", "social", Icons.family_restroom,
        color: Colors.amber),
    "INVENTORY": const Service(
        "Inventaire", "inventory", Icons.inventory_rounded,
        color: Colors.red),
    "TICKETING": const Service(
        "Support IT", "ticketing", Icons.airplane_ticket_outlined,
        color: Colors.deepPurple),
    "PARC_INFORMATIQUE": const Service(
        "Parc Informatique", "ticketing", Icons.devices,
        color: Colors.greenAccent),
    "TASK": const Service("Activités", "tasks", Icons.task_alt_outlined,
        color: Colors.pink),
    "MEETING": const Service(
        "Salles de réunion", "meeting-hall", Icons.meeting_room,
        color: Colors.teal),
  };
}

/// Backward-compatible aliases for the Corporate Blue design system.
class AppColors {
  static const Color primary = Color(0xFF155EEF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFDDE7FF);
  static const Color onPrimaryContainer = Color(0xFF102A56);

  static const Color secondary = Color(0xFF00A6A6);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFCCFBEF);
  static const Color onSecondaryContainer = Color(0xFF134E48);

  static const Color tertiary = Color(0xFFF79009);
  static const Color onTertiary = Color(0xFF3B2400);

  static const Color error = Color(0xFFD92D20);
  static const Color onError = Color(0xFFFFFFFF);

  static const Color background = Color(0xFFF6F8FC);
  static const Color onBackground = Color(0xFF101828);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF101828);
  static const Color success = Color(0xFF12B76A);
  static const Color warning = Color(0xFFF79009);
  static const Color info = Color(0xFF1570EF);
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

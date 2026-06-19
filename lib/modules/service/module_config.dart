import 'package:flutter/material.dart';

enum AppModule {
  tasks,
  courriers,
  social,
  news,
  inventory,
  ticketing,
  meetinghall,
  usermanagement
  // assets,
  // pos,
  // production,
  // contacts,
}

extension AppModuleX on AppModule {
  String get routeSegment {
    switch (this) {
      case AppModule.tasks:
        return 'tasks';
      case AppModule.courriers:
        return 'courriers';
      case AppModule.social:
        return 'social';
      case AppModule.news:
        return 'news';
      case AppModule.inventory:
        return 'inventory';
      case AppModule.ticketing:
        return 'incidents';
      case AppModule.meetinghall:
        return 'meetinghall';
      case AppModule.usermanagement:
        return 'usermanagement';
    }
  }

  String get permissionKey {
    switch (this) {
      case AppModule.tasks:
        return 'tasks';
      case AppModule.courriers:
        return 'courriers';
      case AppModule.social:
        return 'social';
      case AppModule.news:
        return 'news';
      case AppModule.inventory:
        return 'inventory';
      case AppModule.ticketing:
        return 'ticketing';
      case AppModule.meetinghall:
        return 'meetinghall';
      case AppModule.usermanagement:
        return 'usermanagement';
    }
  }
}

class ModuleInfo {
  final AppModule module;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const ModuleInfo({
    required this.module,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

/// Configuration for all app modules
class ModulesConfig {
  static const List<ModuleInfo> allModules = [
    ModuleInfo(
      module: AppModule.tasks,
      name: 'Tâches',
      description: 'Gestion des activités',
      icon: Icons.task_alt,
      color: Color(0xFFFF5722), // Deep Orange
    ),
    ModuleInfo(
      module: AppModule.courriers,
      name: 'Mails Management',
      description: 'Mail management',
      icon: Icons.mail_outline_rounded,
      color: Color(0xFF2196F3), // Blue
    ),
    ModuleInfo(
      module: AppModule.social,
      name: 'Social',
      description: 'Social and HR management',
      icon: Icons.local_shipping_outlined,
      color: Color(0xFF4CAF50), // Green
    ),
    ModuleInfo(
      module: AppModule.news,
      name: 'Actualités',
      description: 'Gestion des communiqués et de l\'information interne',
      icon: Icons.campaign_outlined,
      color: Color(0xFF3F51B5), // Indigo
    ),
    ModuleInfo(
      module: AppModule.inventory,
      name: 'Inventory',
      description: 'Inventory & Store operations',
      icon: Icons.inventory_2_outlined,
      color: Color(0xFF9C27B0), // Purple
    ),
    ModuleInfo(
      module: AppModule.ticketing,
      name: 'Support',
      description: 'Gestion des incidents IT',
      icon: Icons.support_agent_rounded,
      color: Color(0xFFFF9800), // Orange
    ),
    ModuleInfo(
      module: AppModule.meetinghall,
      name: 'Meeting Hall',
      description: 'Meeting room booking & management',
      icon: Icons.meeting_room_outlined,
      color: Color(0xFF00BCD4), // Cyan
    ),
    ModuleInfo(
      module: AppModule.usermanagement,
      name: 'Utilisateurs',
      description: 'Gestions des utilisateurs',
      icon: Icons.supervised_user_circle_outlined,
      color: Color(0xFF8BC34A), // Light Green
    ),
    // ModuleInfo(
    //   module: AppModule.production,
    //   name: 'Production',
    //   description: 'Work monitoring & quality control',
    //   icon: Icons.factory_outlined,
    //   color: Color(0xFF607D8B), // Blue Grey
    // ),
    // ModuleInfo(
    //   module: AppModule.contacts,
    //   name: 'Contacts',
    //   description: 'Vendors, suppliers & contractors',
    //   icon: Icons.contacts_outlined,
    //   color: Color(0xFF795548), // Brown
    // ),
  ];
}

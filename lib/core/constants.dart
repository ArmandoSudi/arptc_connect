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
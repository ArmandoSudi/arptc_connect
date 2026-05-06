import 'package:flutter/material.dart';

class Service {
  const Service(
    this.name,
    this.path,
    this.iconData, {
    this.color,
  });

  final String name;
  final String path;
  final IconData iconData;
  final Color? color;
}

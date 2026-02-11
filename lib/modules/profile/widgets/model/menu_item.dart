import 'package:flutter/material.dart';

class MenuItem {
  final String title;
  final String value;
  final IconData? icon;

  MenuItem({
    required this.title,
    required this.value,
    this.icon,
  });
}
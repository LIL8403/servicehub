import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> shadowNone = [];

  static const List<BoxShadow> shadowLow = [
    BoxShadow(
      color: Color.fromRGBO(15, 23, 42, 0.05),
      offset: Offset(0, 1),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color.fromRGBO(15, 23, 42, 0.08),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> shadowHigh = [
    BoxShadow(
      color: Color.fromRGBO(15, 23, 42, 0.14),
      offset: Offset(0, 10),
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];
}

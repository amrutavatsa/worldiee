import 'package:flutter/material.dart';

abstract final class WorldCompanionMotion {
  static const fast = Duration(milliseconds: 150);
  static const standard = Duration(milliseconds: 250);
  static const emphasized = Duration(milliseconds: 350);

  static const standardCurve = Curves.easeOutCubic;
  static const emphasizedCurve = Curves.easeInOutCubic;
}
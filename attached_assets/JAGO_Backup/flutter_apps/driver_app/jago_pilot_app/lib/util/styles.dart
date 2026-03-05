import 'package:flutter/material.dart';
import 'package:get/get.dart';

const sfProLight = TextStyle(
  fontFamily: 'SFProText',
  fontWeight: FontWeight.w300,
);

const textRegular = TextStyle(
  fontFamily: 'SFProText',
  fontWeight: FontWeight.w400,
);

const textMedium = TextStyle(
  fontFamily: 'SFProText',
  fontWeight: FontWeight.w500,
);

const textSemiBold = TextStyle(
  fontFamily: 'SFProText',
  fontWeight: FontWeight.w600,
);

const textBold = TextStyle(
  fontFamily: 'SFProText',
  fontWeight: FontWeight.w700,
);

const textHeavy = TextStyle(
  fontFamily: 'SFProText',
  fontWeight: FontWeight.w900,
);

const textRobotoRegular = TextStyle(
  fontFamily: 'Roboto',
  fontWeight: FontWeight.w400,
);

const textRobotoMedium = TextStyle(
  fontFamily: 'Roboto',
  fontWeight: FontWeight.w500,
);

const textRobotoBold = TextStyle(
  fontFamily: 'Roboto',
  fontWeight: FontWeight.w700,
);

const textRobotoBlack = TextStyle(
  fontFamily: 'Roboto',
  fontWeight: FontWeight.w900,
);

List<BoxShadow>? searchBoxShadow = Get.isDarkMode ? null : [
  BoxShadow(
    offset: const Offset(0, 2),
    color: const Color(0xFF2563EB).withValues(alpha: 0.08),
    blurRadius: 12,
    spreadRadius: 0,
  ),
];

List<BoxShadow>? cardShadow = Get.isDarkMode ? null : [
  BoxShadow(
    offset: const Offset(0, 1),
    blurRadius: 3,
    spreadRadius: 0,
    color: Colors.black.withValues(alpha: 0.04),
  ),
  BoxShadow(
    offset: const Offset(0, 4),
    blurRadius: 8,
    spreadRadius: -2,
    color: Colors.black.withValues(alpha: 0.06),
  ),
];

List<BoxShadow>? cardShadowMedium = Get.isDarkMode ? null : [
  BoxShadow(
    offset: const Offset(0, 2),
    blurRadius: 8,
    spreadRadius: -1,
    color: Colors.black.withValues(alpha: 0.06),
  ),
  BoxShadow(
    offset: const Offset(0, 6),
    blurRadius: 16,
    spreadRadius: -4,
    color: const Color(0xFF2563EB).withValues(alpha: 0.08),
  ),
];

List<BoxShadow>? cardShadowLarge = Get.isDarkMode ? null : [
  BoxShadow(
    offset: const Offset(0, 4),
    blurRadius: 12,
    spreadRadius: -2,
    color: Colors.black.withValues(alpha: 0.08),
  ),
  BoxShadow(
    offset: const Offset(0, 8),
    blurRadius: 24,
    spreadRadius: -6,
    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
  ),
];

List<BoxShadow>? shadow = Get.isDarkMode ? null : [
  BoxShadow(
    offset: const Offset(0, 1),
    color: const Color(0xFF0F172A).withValues(alpha: 0.05),
    blurRadius: 6,
    spreadRadius: 0,
  ),
];

const LinearGradient primaryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
);

const LinearGradient darkGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
);

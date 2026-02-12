import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:black_ai/config/app_colors.dart';

class CustomText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final double? letterSpacing;
  final double? height;
  final int? maxLines;
  final TextOverflow? overflow;

  const CustomText(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.letterSpacing,
    this.height,
    this.maxLines,
    this.overflow,
  });

  factory CustomText.header(
    String text, {
    Color? color,
    double? fontSize = 24,
    FontWeight? fontWeight = FontWeight.bold,
    TextAlign? textAlign,
  }) {
    return CustomText(
      text,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppColors.white,
      textAlign: textAlign,
    );
  }

  factory CustomText.body(
    String text, {
    Color? color,
    double? fontSize = 16,
    TextAlign? textAlign,
  }) {
    return CustomText(
      text,
      fontSize: fontSize,
      color: color ?? AppColors.white70,
      textAlign: textAlign,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      ),
    );
  }
}

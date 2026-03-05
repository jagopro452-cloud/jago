import 'package:flutter/material.dart';
import 'package:jago_pilot_app/util/dimensions.dart';
import 'package:jago_pilot_app/util/styles.dart';

class ButtonWidget extends StatelessWidget {
  final Function()? onPressed;
  final String buttonText;
  final bool transparent;
  final EdgeInsets margin;
  final double height;
  final double width;
  final double? fontSize;
  final double radius;
  final IconData? icon;
  final bool showBorder;
  final double borderWidth;
  final Color? borderColor;
  final Color? textColor;
  final Color? backgroundColor;
  const ButtonWidget({
    super.key, this.onPressed, required this.buttonText, this.transparent = false, this.margin = EdgeInsets.zero,
    this.width = Dimensions.webMaxWidth, this.height = 52, this.fontSize, this.radius = 14, this.icon, this.showBorder = false, this.borderWidth = 1.5,
    this.borderColor, this.textColor, this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null;

    return Center(child: SizedBox(width: width, child: Padding(
      padding: margin,
      child: Container(
        decoration: !transparent && !isDisabled ? BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ) : null,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: isDisabled
                ? Theme.of(context).disabledColor
                : Colors.transparent,
            minimumSize: Size(width, height),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
              side: showBorder
                  ? BorderSide(color: borderColor ?? Theme.of(context).primaryColor, width: borderWidth)
                  : const BorderSide(color: Colors.transparent),
            ),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            icon != null ?
            Padding(
              padding: const EdgeInsets.only(right: Dimensions.paddingSizeExtraSmall),
              child: Icon(icon, color: transparent ? Theme.of(context).primaryColor : Colors.white, size: 20),
            ) :
            const SizedBox(),

            Flexible(
              child: Text(
                buttonText, textAlign: TextAlign.center,
                style: textSemiBold.copyWith(
                  color: textColor ?? (transparent ? Theme.of(context).primaryColor : Colors.white),
                  fontSize: fontSize ?? Dimensions.fontSizeDefault,
                  overflow: TextOverflow.ellipsis,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ]),
        ),
      ),
    )));
  }
}

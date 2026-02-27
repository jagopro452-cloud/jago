import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jago_user_app/common_widgets/app_bar_widget.dart';
import 'package:jago_user_app/util/dimensions.dart';

class BodyWidget extends StatefulWidget {
  final Widget body;
  final AppBarWidget appBar;
  final double topMargin;
  const BodyWidget({super.key, required this.body, required this.appBar, this.topMargin = 10});

  @override
  State<BodyWidget> createState() => _BodyWidgetState();
}

class _BodyWidgetState extends State<BodyWidget> {
  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;

    return  Column(children: [
      widget.appBar,

      Expanded(child: Container(
        margin: EdgeInsets.only(top: widget.topMargin),
        width: Dimensions.webMaxWidth,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(28), topLeft: Radius.circular(28),
          ),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(topRight: Radius.circular(28), topLeft: Radius.circular(28)),
            child: widget.body,
        ),
      )),

    ]);
  }
}

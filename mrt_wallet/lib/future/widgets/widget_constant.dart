import 'package:flutter/material.dart';
import 'package:mrt_wallet/app/constant/custom_colors.dart';
import 'package:mrt_wallet/models/app/material.dart';

class WidgetConstant {
  static const Widget height8 = SizedBox(height: 8);
  static const Widget width8 = SizedBox(width: 8);
  static const Widget height20 = SizedBox(height: 20);
  static const Widget height15 = SizedBox(height: 15);
  static const ScrollPhysics noScrollPhysics = NeverScrollableScrollPhysics();
  static const EdgeInsets padding5 = EdgeInsets.all(5);
  static const EdgeInsets padding10 = EdgeInsets.all(10);
  static const EdgeInsets paddingHorizontal10 =
      EdgeInsets.symmetric(horizontal: 10);
  static const EdgeInsets paddingHorizontal20 =
      EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets padding20 = EdgeInsets.all(20);
  static const EdgeInsets paddingOnlyTop20 = EdgeInsets.only(top: 20);
  static const EdgeInsets paddingVertical20 =
      EdgeInsets.symmetric(vertical: 20);
  static const EdgeInsets paddingVertical10 =
      EdgeInsets.symmetric(vertical: 10);
  static const EdgeInsets paddingVertical8 = EdgeInsets.symmetric(vertical: 8);
  static final BorderRadius border8 = BorderRadius.circular(8);
  static final BorderRadius border25 = BorderRadius.circular(25);
  static final BorderRadius border4 = BorderRadius.circular(4);
  static const BorderRadius borderBottom8 = BorderRadius.only(
      bottomRight: Radius.circular(8), bottomLeft: Radius.circular(8));
  static const SizedBox sizedBox = SizedBox();
  static const BoxShadow circleShadow =
      BoxShadow(blurRadius: 0.3, spreadRadius: 0.1);
  static const Divider divider = Divider();
  static const Icon checkCircle = Icon(
    Icons.check_circle,
    color: CustomColors.green,
    size: 40,
  );
  static const Icon checkCircleLarge = Icon(
    Icons.check_circle,
    color: CustomColors.green,
    size: 80,
  );
  static final Icon errorIcon = Icon(
    Icons.error,
    color: AppMaterialController.appTheme.colorScheme.error,
    size: 40,
  );
  static final Icon errorIconLarge = Icon(
    Icons.error,
    color: AppMaterialController.appTheme.colorScheme.error,
    size: 80,
  );
}

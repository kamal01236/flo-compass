import 'package:flutter/material.dart';

/// Whether UI animations should run (respects OS reduced-motion / disableAnimations).
bool shouldAnimate(BuildContext context) {
  return !MediaQuery.disableAnimationsOf(context);
}

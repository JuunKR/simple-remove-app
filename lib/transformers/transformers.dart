import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'transformer_page_view.dart';
import 'package:vector_math/vector_math_64.dart';

final transformers = [
  AccordionTransformer(),
  ThreeDTransformer(),
  ZoomInPageTransformer(),
  ZoomOutPageTransformer(),
  DepthPageTransformer(),
  ScaleAndFadeTransformer(),
];

class AccordionTransformer extends PageTransformer {
  @override
  Widget transform(Widget child, TransformInfo info) {
    double position = info.position;
    return Transform.scale(
      scale: position < 0.0 ? 1 + position : 1 - position,
      alignment: position < 0.0 ? Alignment.topRight : Alignment.bottomLeft,
      child: child,
    );
  }
}

class ThreeDTransformer extends PageTransformer {
  @override
  Widget transform(Widget child, TransformInfo info) {
    double position = info.position;
    double height = info.height;
    double width = info.width;
    double pivotX = (position < 0 && position >= -1) ? width : 0.0;

    return Transform(
      transform:
          Matrix4.identity()..rotate(Vector3(0.0, 2.0, 0.0), position * 1.5),
      origin: Offset(pivotX, height / 2),
      child: child,
    );
  }
}

class ZoomInPageTransformer extends PageTransformer {
  static const double zoomMax = 0.5;

  @override
  Widget transform(Widget child, TransformInfo info) {
    double position = info.position;
    double width = info.width;

    if (position > 0 && position <= 1) {
      return Transform.translate(
        offset: Offset(-width * position, 0.0),
        child: Transform.scale(scale: 1 - position, child: child),
      );
    }
    return child;
  }
}

class ZoomOutPageTransformer extends PageTransformer {
  static const double minScale = 0.85;
  static const double minAlpha = 0.5;

  @override
  Widget transform(Widget child, TransformInfo info) {
    double position = info.position;
    double pageWidth = info.width;
    double pageHeight = info.height;

    if (position.abs() <= 1) {
      double scaleFactor = math.max(minScale, 1 - position.abs());
      double vertMargin = pageHeight * (1 - scaleFactor) / 2;
      double horzMargin = pageWidth * (1 - scaleFactor) / 2;
      double dx =
          position < 0
              ? (horzMargin - vertMargin / 2)
              : (-horzMargin + vertMargin / 2);
      double opacity =
          minAlpha + (scaleFactor - minScale) / (1 - minScale) * (1 - minAlpha);

      return Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(dx, 0.0),
          child: Transform.scale(scale: scaleFactor, child: child),
        ),
      );
    }
    return child;
  }
}

class DepthPageTransformer extends PageTransformer {
  DepthPageTransformer() : super(reverse: true);

  @override
  Widget transform(Widget child, TransformInfo info) {
    double position = info.position;
    Axis scrollDirection = info.scrollDirection;

    if (position <= 0) {
      return Opacity(
        opacity: 1.0,
        child: Transform.translate(
          offset: Offset(0.0, 0.0),
          child: Transform.scale(scale: 1.0, child: child),
        ),
      );
    } else if (position <= 1) {
      const double minScale = 0.75;
      double scaleFactor = minScale + (1 - minScale) * (1 - position);

      return Opacity(
        opacity: 1.0 - position,
        child: Transform.translate(
          offset:
              (scrollDirection == Axis.vertical)
                  ? Offset(0.0, -position * info.height)
                  : Offset(-position * info.width, 0.0),
          child: Transform.scale(scale: scaleFactor, child: child),
        ),
      );
    }
    return child;
  }
}

class ScaleAndFadeTransformer extends PageTransformer {
  final double scale;
  final double fade;

  ScaleAndFadeTransformer({this.fade = 0.3, this.scale = 0.8});

  @override
  Widget transform(Widget item, TransformInfo info) {
    double position = info.position;
    double scaleFactor = (1 - position.abs()) * (1 - scale);
    double fadeFactor = (1 - position.abs()) * (1 - fade);
    double opacity = fade + fadeFactor;
    double scaleValue = scale + scaleFactor;

    return Opacity(
      opacity: opacity,
      child: Transform.scale(scale: scaleValue, child: item),
    );
  }
}

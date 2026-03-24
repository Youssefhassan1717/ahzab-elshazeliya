import 'package:flutter/material.dart';

/// Ultra-smooth iOS-style scrolling physics.
/// Uses BouncingScrollSimulation for buttery momentum and natural bounce.
class SmoothScrollPhysics extends ScrollPhysics {
  const SmoothScrollPhysics({super.parent});

  @override
  SmoothScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SmoothScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 0.3,
        stiffness: 100.0,
        damping: 16.0,
      );

  @override
  double get dragStartDistanceMotionThreshold => 3.5;

  @override
  double get minFlingVelocity => 50.0;

  @override
  double get maxFlingVelocity => 8000.0;

  @override
  double carriedMomentum(double existingVelocity) {
    // Higher momentum carry = longer, smoother glide
    return existingVelocity.sign *
        (existingVelocity.abs() * 0.5).clamp(0.0, 800.0);
  }

  @override
  double frictionFactor(double overscrollFraction) {
    // Gentle rubber-band resistance when overscrolling
    return 0.52 * (1.0 - overscrollFraction * overscrollFraction).clamp(0.0, 1.0);
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final tolerance = toleranceFor(position);

    if (velocity.abs() < tolerance.velocity && !position.outOfRange) {
      return null;
    }

    // Always use BouncingScrollSimulation for smooth iOS-style momentum + bounce
    return BouncingScrollSimulation(
      spring: spring,
      position: position.pixels,
      velocity: velocity,
      leadingExtent: position.minScrollExtent,
      trailingExtent: position.maxScrollExtent,
      tolerance: tolerance,
    );
  }
}

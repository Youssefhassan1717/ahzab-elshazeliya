import 'package:flutter/material.dart';

/// Smooth scrolling physics with custom deceleration for a natural feel.
/// Uses iOS-style momentum with tuned friction for Arabic content reading.
class SmoothScrollPhysics extends ScrollPhysics {
  const SmoothScrollPhysics({super.parent});

  @override
  SmoothScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SmoothScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 0.5,
        stiffness: 90.0,
        damping: 14.0,
      );

  @override
  double get dragStartDistanceMotionThreshold => 3.5;

  @override
  double carriedMomentum(double existingVelocity) {
    return existingVelocity.sign *
        (existingVelocity.abs() * 0.4).clamp(0.0, 600.0);
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final tolerance = toleranceFor(position);

    if (position.outOfRange) {
      return BouncingScrollSimulation(
        spring: spring,
        position: position.pixels,
        velocity: velocity,
        leadingExtent: position.minScrollExtent,
        trailingExtent: position.maxScrollExtent,
        tolerance: tolerance,
      );
    }

    if (velocity.abs() < tolerance.velocity) return null;

    return ClampingScrollSimulation(
      position: position.pixels,
      velocity: velocity,
      friction: 0.015,
      tolerance: tolerance,
    );
  }
}

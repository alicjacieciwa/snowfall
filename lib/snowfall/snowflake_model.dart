import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:simple_animations/simple_animations.dart';
import 'package:snowfall/snowfall/utils/point.dart';

enum AniProps { X, Y }

class AnimationProgress {
  final Duration duration;
  final Duration startTime;

  /// Creates an [AnimationProgress].
  AnimationProgress({required this.duration, required this.startTime});

  /// Queries the current progress value based on the specified [startTime] and
  /// [duration] as a value between `0.0` and `1.0`. It will automatically
  /// clamp values this interval to fit in.
  double progress(Duration time) => math.max(
      0.0,
      math.min(
          (time - startTime).inMilliseconds / duration.inMilliseconds, 1.0));
}

class SnowflakeModel {
  static Map<int, Path> cachedFlakes = {};

  Animatable? tween;
  double size = 0.0;
  double scale = 1.0;
  AnimationProgress? animationProgress;
  math.Random random;
  Path? _path;

  SnowflakeModel(this.random, this.scale) {
    restart();
  }

  void restart({Duration time = Duration.zero}) {
    _path = null;
    final startPosition = Offset(-0.2 + 1.4 * random.nextDouble(), -0.2);
    final endPosition = Offset(-0.2 + 1.4 * random.nextDouble(), 1.2);
    final duration = Duration(seconds: 15, milliseconds: random.nextInt(10000));
    tween = MultiTween<AniProps>()
      ..add(AniProps.X, Tween(begin: startPosition.dx, end: endPosition.dx),
          duration, Curves.easeInOutSine)
      ..add(AniProps.Y, Tween(begin: startPosition.dy, end: endPosition.dy),
          duration, Curves.easeInOutSine);

    /* tween = MultiTrackTween([
      Track("x").add(
          duration, Tween(begin: startPosition.dx, end: endPosition.dx),
          curve: Curves.easeInOutSine),
      Track("y").add(
          duration, Tween(begin: startPosition.dy, end: endPosition.dy),
          curve: Curves.easeIn),
    ]); */
    animationProgress = AnimationProgress(duration: duration, startTime: time);
    size = 20 + random.nextDouble() * 100;
    drawPath();
  }

  void drawPath() {
    if (_path != null) {
      return;
    }
    double sideLength = 100;

    int iterationsTotal = 1;
    // we calculate the total number of iterations
    // based on the snowflake's size
    if (size > 40) {
    iterationsTotal += (size) ~/ 25;
    }
    _path = Path();
    if (cachedFlakes[iterationsTotal] == null) {
      double down = (sideLength / 2) * math.tan(math.pi / 6);
      double up = (sideLength / 2) * math.tan(math.pi / 3) - down;
      Point p1 = Point(-sideLength / 2, down);
      Point p2 = Point(sideLength / 2, down);
      Point p3 = Point(0, -up);
      Point p4 = Point(0, 0);
      Point p5 = Point(0, 0);
      double rot = random.nextDouble() * 6.28319;
      List<Point> lines = <Point>[p1, p2, p3];
      List<Point> tmpLines = <Point>[];

      for (int iterations = 0; iterations < iterationsTotal; iterations++) {
        sideLength /= 3;
        for (int loop = 0; loop < lines.length; loop++) {
          p1 = lines[loop];
          if (loop == lines.length - 1) {
            p2 = lines[0];
          } else {
            p2 = lines[loop + 1];
          }
          rot = math.atan2(p2.y - p1.y, p2.x - p1.x);
          p3 = p1 + Point.polar(sideLength, rot);
          rot += math.pi / 3;
          p4 = p3 + Point.polar(sideLength, rot);
          rot -= 2 * math.pi / 3;
          p5 = p4 + Point.polar(sideLength, rot);
          tmpLines.add(p1);
          tmpLines.add(p3);
          tmpLines.add(p4);
          tmpLines.add(p5);
        }
        lines = tmpLines;
        tmpLines = <Point>[];
      }
      lines.add(p2);
      _path!.moveTo(lines[0].x, lines[0].y);
      for (int a = 0; a < lines.length; a++) {
        _path!.lineTo(lines[a].x, lines[a].y);
      }
      _path!.lineTo(lines[0].x, lines[0].y);
      cachedFlakes[iterationsTotal] = _path!;
    } else {
      _path = cachedFlakes[iterationsTotal];
    }
    Matrix4 m = Matrix4.identity();
    // the rotation must be in radians
    // and to get a random angle we use the 360 equivalent
    // in radians that is 6.28319
    m.setRotationZ(random.nextDouble() * 6.28319);
    num scaleTo = size / sideLength;
    m.scale(scaleTo * scale);
    List<double> list = m.storage.toList();
    _path = _path!.transform(Float64List.fromList(list));
  }

  Path? get path {
    if (_path != null) {
      return _path;
    }
    drawPath();
    return _path;
  }

  void maintainRestart(Duration time) {
    if (animationProgress!.progress(time) == 1.0) {
      restart(time: time);
    }
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../a11y/motion_policy.dart';

class StreamingText extends StatefulWidget {
  const StreamingText({
    super.key,
    required this.text,
    this.enabled = true,
    this.lowBandwidth = false,
    this.stepDelay = const Duration(milliseconds: 20),
    this.style,
  });

  final String text;
  final bool enabled;
  final bool lowBandwidth;
  final Duration stepDelay;
  final TextStyle? style;

  @override
  State<StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<StreamingText> {
  Timer? _timer;
  int _length = 0;

  @override
  void initState() {
    super.initState();
  }

  bool _dependenciesReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dependenciesReady) {
      _dependenciesReady = true;
      _start();
    }
  }

  @override
  void didUpdateWidget(covariant StreamingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.enabled != widget.enabled ||
        oldWidget.lowBandwidth != widget.lowBandwidth) {
      _start();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    final instant =
        !widget.enabled || widget.lowBandwidth || !shouldAnimate(context);
    if (instant) {
      setState(() => _length = widget.text.length);
      return;
    }
    setState(() => _length = 0);
    _timer = Timer.periodic(widget.stepDelay, (timer) {
      if (!mounted) return;
      if (_length >= widget.text.length) {
        timer.cancel();
        return;
      }
      setState(() => _length += 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final end = _length.clamp(0, widget.text.length);
    return Text(widget.text.substring(0, end), style: widget.style);
  }
}

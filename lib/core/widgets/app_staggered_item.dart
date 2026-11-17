import 'dart:async';

import 'package:flutter/material.dart';

class AppStaggeredItem extends StatelessWidget {
  const AppStaggeredItem({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (index >= 8 || MediaQuery.of(context).disableAnimations) return child;
    return _AnimatedStaggeredItem(index: index, child: child);
  }
}

class _AnimatedStaggeredItem extends StatefulWidget {
  const _AnimatedStaggeredItem({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_AnimatedStaggeredItem> createState() => _AnimatedStaggeredItemState();
}

class _AnimatedStaggeredItemState extends State<_AnimatedStaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Timer _startTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _startTimer = Timer(Duration(milliseconds: widget.index * 7), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _startTimer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
        child: RepaintBoundary(child: widget.child),
      ),
    );
  }
}

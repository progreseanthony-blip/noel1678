import 'package:flutter/material.dart';
import 'package:noel_core/noel_core.dart';

class ScrollIndicator extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final ScrollController? controller;

  const ScrollIndicator({
    super.key,
    required this.child,
    this.padding,
    this.controller,
  });

  @override
  State<ScrollIndicator> createState() => _ScrollIndicatorState();
}

class _ScrollIndicatorState extends State<ScrollIndicator> {
  late ScrollController _controller;
  bool _hasScrollableContent = false;
  bool _isAtBottom = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ScrollController();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    final maxScroll = _controller.position.maxScrollExtent;
    final currentScroll = _controller.position.pixels;
    final atBottom = currentScroll >= maxScroll - 16;
    if (atBottom != _isAtBottom) {
      setState(() => _isAtBottom = atBottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return NotificationListener<ScrollMetricsNotification>(
          onNotification: (notification) {
            if (notification.metrics.maxScrollExtent > 0 !=
                _hasScrollableContent) {
              final hasScroll =
                  notification.metrics.maxScrollExtent > 0;
              _isAtBottom =
                  notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 16;
              Future.microtask(() {
                if (mounted) setState(() => _hasScrollableContent = hasScroll);
              });
            }
            return false;
          },
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: _controller,
                padding: widget.padding,
                child: widget.child,
              ),
              if (_hasScrollableContent && !_isAtBottom)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white,
                          ],
                        ),
                      ),
                      alignment: Alignment.bottomCenter,
                      child: const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: AppTheme.slate400,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

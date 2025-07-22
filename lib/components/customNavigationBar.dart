import 'package:flutter/material.dart';

class NavigationItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class CustomNavigationBar extends StatefulWidget {
  final List<NavigationItem> items;
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const CustomNavigationBar({
    super.key,
    required this.items,
    this.currentIndex = 0,
    this.onTap,
  });

  @override
  State<CustomNavigationBar> createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Responsive sizing
    final navBarHeight = screenHeight * 0.08 + 20; // 8% of screen height + padding
    final iconSize = screenWidth * 0.06; // 6% of screen width
    final specialIconSize = screenWidth * 0.08; // 8% for middle icon
    final fontSize = screenWidth * 0.032; // 3.2% of screen width
    final margin = screenWidth * 0.04; // 4% margin
    final borderRadius = screenWidth * 0.06; // 6% border radius

    final middleIndex = (widget.items.length / 2).floor();

    return Container(
      margin: EdgeInsets.fromLTRB(margin, 0, margin, bottomPadding + 8),
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.transparent,
        child: Container(
          height: navBarHeight,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1a1a1a),
                Color(0xFF2d2d2d),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.08),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: widget.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == widget.currentIndex;
              final isMiddleIcon = index == middleIndex;

              return Expanded(
                child: GestureDetector(
                  onTapDown: (_) => _animationController.forward(),
                  onTapUp: (_) => _animationController.reverse(),
                  onTapCancel: () => _animationController.reverse(),
                  onTap: () {
                    widget.onTap?.call(index);
                    item.onTap();
                  },
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: index == widget.currentIndex ? _scaleAnimation.value : 1.0,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Special styling for middle icon
                              if (isMiddleIcon)
                                Container(
                                  width: specialIconSize + 16,
                                  height: specialIconSize + 16,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isSelected
                                          ? [
                                        const Color(0xFF6366f1),
                                        const Color(0xFF8b5cf6),
                                      ]
                                          : [
                                        const Color(0xFF374151),
                                        const Color(0xFF4b5563),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? Colors.purple.withOpacity(0.4)
                                            : Colors.black.withOpacity(0.2),
                                        blurRadius: isSelected ? 15 : 8,
                                        spreadRadius: isSelected ? 3 : 1,
                                        offset: const Offset(0, 4),
                                      ),
                                      if (isSelected)
                                        BoxShadow(
                                          color: Colors.purple.withOpacity(0.2),
                                          blurRadius: 25,
                                          spreadRadius: 5,
                                        ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      item.icon,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[300],
                                      size: specialIconSize,
                                    ),
                                  ),
                                )
                              else
                              // Regular icons
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: EdgeInsets.all(screenWidth * 0.02),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.blue.withOpacity(0.2)
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                    boxShadow: isSelected
                                        ? [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.3),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      )
                                    ]
                                        : null,
                                  ),
                                  child: Icon(
                                    item.icon,
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.grey[400],
                                    size: iconSize,
                                  ),
                                ),
                              SizedBox(height: screenHeight * 0.006),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  color: isSelected
                                      ? (isMiddleIcon ? Colors.purple[300] : Colors.blue)
                                      : Colors.grey[400],
                                  fontSize: fontSize,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                                child: Text(
                                  item.label,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnimatedBalance extends StatelessWidget {
  final double balance;
  final bool isVisible;
  final String currency;

  const AnimatedBalance({
    super.key,
    required this.balance,
    required this.isVisible,
    this.currency = 'FCFA',
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: currency);
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Text(
        isVisible
            ? currencyFormat.format(balance)
            : '****',
        key: ValueKey<bool>(isVisible),
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
} 
import 'package:flutter/material.dart';

/// Vertically centers [child] when the keyboard is closed; scrolls when it opens.
class CenteredAuthForm extends StatelessWidget {
  const CenteredAuthForm({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewInsets = MediaQuery.viewInsetsOf(context);
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + viewInsets.bottom),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Align(
              alignment: Alignment.center,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

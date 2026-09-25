import 'package:flutter/material.dart';

class HangoutAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions; // <-- Added this to hold your Settings button

  const HangoutAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions, // <-- Added here
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: showBackButton,
      iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
      actions: actions, // <-- Plugs the buttons into the real AppBar
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF2B1B10), // dark terracotta-black blend
              Colors.black,
            ],
          ),
        ),
      ),
      title: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'serif',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 4,
          color: Color(0xFFD4AF37),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: const Color(0xFFD4AF37).withOpacity(0.35),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1.0);
}
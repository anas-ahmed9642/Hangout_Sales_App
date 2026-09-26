import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/marble_background_painter.dart';
import '../../../core/constants/app_routes.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authProvider.notifier).signOut();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to sign out. Please try again.'),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6EC),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                const Color(0xFF2B1B10), // dark terracotta-black blend
                Colors.black,
              ],
            ),
          ),
        ),
        title: const Text(
          'SETTINGS',
          style: TextStyle(
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
            color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: CastleWallPainter())),
          ListView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
            children: [
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    border: Border.all(color: AppTheme.primaryColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.25),
                        blurRadius: 26,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: AppTheme.primaryColor,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Center(
                child: Text(
                  'Hangout Pizza Classic',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Administrator',
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 2,
                    color: Colors.black.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              const _OrnamentalDivider(),
              const SizedBox(height: 32),
              const _SectionLabel('ACCOUNT'),
              const SizedBox(height: 14),
              _SettingsTile(
                icon: Icons.shield_outlined,
                title: 'Account & Security',
                subtitle: 'Manage administrator access',
                onTap: () {},
              ),
              const SizedBox(height: 30),
              const _SectionLabel('CATALOG'),
              const SizedBox(height: 14),
              _SettingsTile(
                icon: Icons.inventory_2_outlined,
                title: 'Manage Catalog',
                subtitle: 'Add, edit, activate, or deactivate expense items',
                onTap: () => context.push(AppRoutes.manageCatalog),
              ),
              const SizedBox(height: 30),
              const _SectionLabel('SESSION'),
              const SizedBox(height: 14),
              _SettingsTile(
                icon: Icons.logout_rounded,
                title: 'Sign out',
                subtitle: 'End the current administrator session',
                onTap: () => _signOut(context, ref),
                destructive: true,
              ),
              const SizedBox(height: 48),
              const _OrnamentalDivider(),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(
                      'HANGOUT SALES MANAGER',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 11,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Built for the business.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrnamentalDivider extends StatelessWidget {
  const _OrnamentalDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppTheme.primaryColor.withValues(alpha: 0.4),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(width: 7, height: 7, color: AppTheme.primaryColor),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppTheme.primaryColor.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.2,
        color: Colors.black.withValues(alpha: 0.4),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = destructive ? const Color(0xFF7A1F1F) : Colors.black;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: destructive
                  ? const Color(0xFF7A1F1F).withValues(alpha: 0.35)
                  : AppTheme.primaryColor.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: destructive
                        ? const Color(0xFF7A1F1F).withValues(alpha: 0.4)
                        : AppTheme.primaryColor.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: accent,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.black.withValues(alpha: 0.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

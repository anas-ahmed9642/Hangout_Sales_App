import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hangout_sales_app/shared/widgets/hangout_app_bar.dart';

import '../../../core/constants/app_routes.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3E8),
      // Make sure to import 'hangout_app_bar.dart' at the top of your file!
      appBar: HangoutAppBar(
        title: 'Hangout Pizza Classic',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFFD4AF37)),
            tooltip: 'Settings',
            onPressed: () => context.go(AppRoutes.settings),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _DashboardHeader(),

              const SizedBox(height: 24),

              const _SectionLabel(
                title: "TODAY'S OVERVIEW",
              ),

              const SizedBox(height: 12),

              const _OverviewGrid(),

              const SizedBox(height: 28),

              const _SectionLabel(
                title: 'QUICK ACTIONS',
              ),

              const SizedBox(height: 12),

              const _QuickActions(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.55),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TODAY\'S OVERVIEW',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.4,
              color: Colors.black.withOpacity(0.55),
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Thursday, 14 August',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFD4AF37),
                ),
              ),

              const SizedBox(width: 8),

              Text(
                'Business day • 5:00 PM – 5:00 AM',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.52),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Divider(
            height: 1,
            color: Color(0xFFE7DDC8),
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live overview',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.black.withOpacity(0.42),
                ),
              ),

              IconButton(
                onPressed: () {
                  // Refresh functionality will be connected later.
                },
                tooltip: 'Refresh',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.4,
        color: Colors.black.withOpacity(0.55),
      ),
    );
  }
}
class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.25,
      children: const [
        _OverviewCard(
          label: 'SALES',
          value: 'No sales yet today',
          icon: Icons.payments_outlined,
        ),
        _OverviewCard(
          label: 'EXPENSES',
          value: 'No expenses yet',
          icon: Icons.receipt_long_outlined,
        ),
        _OverviewCard(
          label: 'ORDERS',
          value: 'No orders yet',
          icon: Icons.shopping_bag_outlined,
        ),
        _OverviewCard(
          label: 'PROFIT',
          value: '—',
          subtitle: 'Waiting for sales',
          icon: Icons.trending_up_rounded,
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;

  const _OverviewCard({
    required this.label,
    required this.value,
    this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final gold = const Color(0xFFD4AF37);

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gold.withOpacity(0.42),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
              Icon(
                icon,
                size: 20,
                color: gold,
              ),
            ],
          ),

          const Spacer(),

          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),

         const SizedBox(height: 5),
Text(
  subtitle ?? '',
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(
    fontSize: 10,
    color: subtitle != null
        ? Colors.black.withOpacity(0.45)
        : Colors.transparent,
  ),
),
        ],
      ),
    );
  }
}
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _QuickActionTile(
          icon: Icons.add_circle_outline_rounded,
          title: 'New Order',
          subtitle: 'Record a new customer order',
          onTap: () => context.go(AppRoutes.orders),
        ),

        const SizedBox(height: 10),

        _QuickActionTile(
          icon: Icons.receipt_long_outlined,
          title: 'Add Expense',
          subtitle: 'Record a shop expense',
          onTap: () => context.go(AppRoutes.expenses),
        ),
      ],
    );
  }
}
class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 17,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: gold.withOpacity(0.38),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: gold.withOpacity(0.10),
                  border: Border.all(
                    color: gold.withOpacity(0.35),
                  ),
                ),
                child: Icon(
                  icon,
                  color: gold,
                  size: 21,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black.withOpacity(0.48),
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.black.withOpacity(0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
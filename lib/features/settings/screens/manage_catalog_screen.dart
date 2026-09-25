import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../expenses/models/catalog_item.dart';
import '../../expenses/models/expense_category.dart';
import '../../expenses/providers/catalog_provider.dart';
import '../../expenses/providers/catalog_repository_provider.dart';
import '../../../shared/widgets/hangout_app_bar.dart';

// ---------------------------------------------------------------------------
// Neoclassical design tokens (presentation only)
// ---------------------------------------------------------------------------

/// Flip this to switch prototypes (hot restart after changing):
///   false -> "Stone & Gilt": warm ashlar wall, matches the Settings screen.
///   true  -> "Nocturne": black ashlar wall with gilt, lit-at-night version.
const bool _blackBackground = false;

/// Every colour is a role, so both prototypes share the same widgets.
class _Palette {
  // Wall (ashlar blocks drawn behind the content).
  static const bg = _blackBackground ? Color(0xFF0B0A08) : Color(0xFFF7EFDF);
  static const stoneA =
      _blackBackground ? Color(0xFF12100D) : Color(0xFFFAF3E5);
  static const stoneB =
      _blackBackground ? Color(0xFF0E0C0A) : Color(0xFFF3E9D5);
  static const joint =
      _blackBackground ? Color(0xFF1C1813) : Color(0xFFE8DBBF);

  // Plates (cards, fields, dialog).
  static const surface =
      _blackBackground ? Color(0xFF17140F) : Color(0xFFF4F2EE);
  static const recess =
      _blackBackground ? Color(0xFF100E0B) : Color(0xFFE6E1D6);

  // Text.
  static const text =
      _blackBackground ? Color(0xFFF3E9D2) : Color(0xFF0A0A0A);
  static const textMuted =
      _blackBackground ? Color(0xFFB3A788) : Color(0xFF5E5A52);

  // Gilding.
  static const gold =
      _blackBackground ? Color(0xFFD4AF37) : Color(0xFFB8922B);
  static const goldText =
      _blackBackground ? Color(0xFFE3BD45) : Color(0xFF8A6A12);
  static const goldSoft =
      _blackBackground ? Color(0xFF5C4A1C) : Color(0xFFE0CB86);

  // Buttons: black-with-gold on stone, gold-with-black on night.
  static const button =
      _blackBackground ? Color(0xFFD4AF37) : Color(0xFF0A0A0A);
  static const onButton =
      _blackBackground ? Color(0xFF0A0A0A) : Color(0xFFE3BD45);

  // Cameo medallions (same idea as the Settings avatar).
  static const cameoFill =
      _blackBackground ? Color(0xFF000000) : Color(0xFF0A0A0A);
  static const cameoInk = Color(0xFFE3BD45);
  static const cameoFillInactive =
      _blackBackground ? Color(0xFF201C16) : Color(0xFFE6E1D6);
  static const cameoInkInactive =
      _blackBackground ? Color(0xFF8F846A) : Color(0xFF77716A);

  // Feedback.
  static const danger = Color(0xFF7F1D1D);
  static const snackBg =
      _blackBackground ? Color(0xFF1F1B14) : Color(0xFF0A0A0A);
  static const snackText = Color(0xFFF6EEDC);
}

/// Rectilinear, near-square frames: neoclassical architecture avoids the
/// soft, pill-shaped corners of default Material.
const _frame = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(2)),
  side: BorderSide(color: _Palette.gold),
);

const _frameSoft = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(2)),
  side: BorderSide(color: _Palette.goldSoft),
);

/// Applies to the body, dialog, popup menus and snack bars of this screen.
/// The app bar is deliberately kept outside it (see [ManageCatalogScreen]).
ThemeData _neoclassicalTheme(ThemeData base) {
  final scheme = base.colorScheme.copyWith(
    brightness: _blackBackground ? Brightness.dark : Brightness.light,
    primary: _Palette.button,
    onPrimary: _Palette.onButton,
    primaryContainer: _Palette.cameoFill,
    onPrimaryContainer: _Palette.cameoInk,
    secondary: _Palette.gold,
    surface: _Palette.surface,
    onSurface: _Palette.text,
    onSurfaceVariant: _Palette.textMuted,
    surfaceContainerHighest: _Palette.recess,
    outline: _Palette.gold,
    outlineVariant: _Palette.goldSoft,
    error: _Palette.danger,
    onError: _Palette.snackText,
    errorContainer: _Palette.danger,
    onErrorContainer: _Palette.snackText,
  );

  const buttonText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
  );

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: _Palette.bg,
    textTheme: base.textTheme.apply(
      bodyColor: _Palette.text,
      displayColor: _Palette.text,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _Palette.button,
        foregroundColor: _Palette.onButton,
        elevation: 0,
        shape: _frame,
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 14,
        ),
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _Palette.goldText,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
        textStyle: buttonText,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: _Palette.snackBg,
      contentTextStyle: TextStyle(
        fontSize: 14.5,
        color: _Palette.snackText,
      ),
      shape: _frame,
      actionTextColor: _Palette.cameoInk,
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: _Palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shape: _frameSoft,
      textStyle: TextStyle(
        fontSize: 15,
        color: _Palette.text,
      ),
    ),
  );
}

InputDecoration _fieldDecoration(
  String label, {
  Widget? prefixIcon,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(2),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    labelText: label,
    prefixIcon: prefixIcon,
    filled: true,
    fillColor: _Palette.surface,
    labelStyle: const TextStyle(color: _Palette.textMuted),
    floatingLabelStyle: const TextStyle(
      color: _Palette.goldText,
      fontWeight: FontWeight.w600,
    ),
    errorStyle: const TextStyle(color: Color(0xFFC0463F)),
    border: border(_Palette.goldSoft),
    enabledBorder: border(_Palette.goldSoft),
    disabledBorder: border(_Palette.recess),
    focusedBorder: border(_Palette.gold, 1.6),
    errorBorder: border(_Palette.danger),
    focusedErrorBorder: border(_Palette.danger, 1.6),
  );
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ManageCatalogScreen extends ConsumerWidget {
  const ManageCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory =
        ref.watch(selectedCatalogCategoryProvider);

    final catalogAsync = ref.watch(catalogItemsProvider);

    // Captured before the local theme is applied, so the app bar can keep
    // the app's own look and stay identical to the Settings screen.
    final baseTheme = Theme.of(context);
    const catalogAppBar = HangoutAppBar(
      title: 'Manage Catalog',
    );

    // The local theme also reaches the dialog, popup menus and snack bars
    // opened from this screen, because they capture the theme of `context`.
    return Theme(
      data: _neoclassicalTheme(baseTheme),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: _Palette.bg,
            appBar: PreferredSize(
              preferredSize: catalogAppBar.preferredSize,
              child: Theme(
                data: baseTheme,
                child: catalogAppBar,
              ),
            ),
            body: Stack(
              children: [
                const Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _AshlarPainter(),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Column(
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 18, 16, 8),
                        child: DropdownButtonFormField<ExpenseCategory>(
                          value: selectedCategory,
                          dropdownColor: _Palette.surface,
                          borderRadius: BorderRadius.circular(2),
                          iconEnabledColor: _Palette.gold,
                          decoration: _fieldDecoration(
                            'Catalog category',
                            prefixIcon: const Icon(
                              Icons.category_outlined,
                              color: _Palette.gold,
                            ),
                          ),
                          items: _catalogCategories.map((category) {
                            return DropdownMenuItem<ExpenseCategory>(
                              value: category,
                              child: Text(_categoryLabel(category)),
                            );
                          }).toList(),
                          onChanged: (category) {
                            if (category == null) {
                              return;
                            }

                            ref
                                .read(
                                  selectedCatalogCategoryProvider
                                      .notifier,
                                )
                                .state = category;
                          },
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 10, 16, 2),
                        child: _MeanderBand(height: 14),
                      ),
                      Expanded(
                        child: catalogAsync.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(
                              color: _Palette.gold,
                              strokeWidth: 2.5,
                            ),
                          ),
                          error: (error, stackTrace) => _CatalogError(
                            onRetry: () {
                              ref.invalidate(catalogItemsProvider);
                            },
                          ),
                          data: (items) {
                            if (items.isEmpty) {
                              return _CatalogEmpty(
                                category: selectedCategory,
                                onAdd: () => _showCatalogEditor(
                                  context,
                                  ref,
                                ),
                              );
                            }

                            return RefreshIndicator(
                              color: _Palette.gold,
                              backgroundColor: _Palette.surface,
                              onRefresh: () async {
                                ref.invalidate(catalogItemsProvider);
                                await ref
                                    .read(catalogItemsProvider.future);
                              },
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  96,
                                ),
                                itemCount: items.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final item = items[index];

                                  return _CatalogItemCard(
                                    item: item,
                                    onEdit: () => _showCatalogEditor(
                                      context,
                                      ref,
                                      item: item,
                                    ),
                                    onToggleActive: () async {
                                      await _toggleActive(
                                        context,
                                        ref,
                                        item,
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showCatalogEditor(
                context,
                ref,
              ),
              backgroundColor: _Palette.button,
              foregroundColor: _Palette.onButton,
              elevation: 3,
              shape: _frame,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Item',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    CatalogItem item,
  ) async {
    try {
      await ref
          .read(catalogRepositoryProvider)
          .setCatalogItemActive(
            item.id,
            !item.active,
          );

      ref.invalidate(catalogItemsProvider);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              item.active
                  ? '${item.name} deactivated.'
                  : '${item.name} activated.',
            ),
          ),
        );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor:
                Theme.of(context).colorScheme.errorContainer,
            content: Text(
              'Unable to update catalog item: $error',
            ),
          ),
        );
    }
  }

  Future<void> _showCatalogEditor(
    BuildContext context,
    WidgetRef ref, {
    CatalogItem? item,
  }) async {
    final result = await showDialog<_CatalogFormResult>(
      context: context,
      builder: (dialogContext) {
        return _CatalogEditorDialog(
          category: ref.read(selectedCatalogCategoryProvider),
          item: item,
        );
      },
    );

    if (result == null) {
      return;
    }

    try {
      final repository = ref.read(catalogRepositoryProvider);

      if (item == null) {
        await repository.createCatalogItem(
          category: result.category,
          name: result.name,
          brand: result.brand,
          size: result.size,
        );
      } else {
        await repository.updateCatalogItem(
          item.id,
          name: result.name,
          brand: result.brand,
          size: result.size,
        );
      }

      ref.invalidate(catalogItemsProvider);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              item == null
                  ? 'Catalog item added.'
                  : 'Catalog item updated.',
            ),
          ),
        );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor:
                Theme.of(context).colorScheme.errorContainer,
            content: Text(
              'Unable to save catalog item: $error',
            ),
          ),
        );
    }
  }
}

const _catalogCategories = [
  ExpenseCategory.marketBills,
  ExpenseCategory.chicken,
  ExpenseCategory.vegetables,
  ExpenseCategory.beveragesAndDrinks,
  ExpenseCategory.packaging,
];

String _categoryLabel(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.marketBills:
      return 'Market Bills';
    case ExpenseCategory.chicken:
      return 'Chicken';
    case ExpenseCategory.vegetables:
      return 'Vegetables';
    case ExpenseCategory.beveragesAndDrinks:
      return 'Beverages and Drinks';
    case ExpenseCategory.packaging:
      return 'Packaging';
    default:
      throw StateError(
        '${category.name} is not a catalog category.',
      );
  }
}

// ---------------------------------------------------------------------------
// Ornament: ashlar wall, Greek-key band and cameo medallion
// ---------------------------------------------------------------------------

/// Running-bond ashlar blocks, echoing the stone wall on the Settings screen.
/// Each row is seeded independently so the pattern stays put when the window
/// is resized.
class _AshlarPainter extends CustomPainter {
  const _AshlarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const blockHeight = 46.0;

    final fillA = Paint()..color = _Palette.stoneA;
    final fillB = Paint()..color = _Palette.stoneB;
    final joint = Paint()
      ..color = _Palette.joint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    var row = 0;

    for (double y = 0; y < size.height; y += blockHeight) {
      final random = math.Random(row * 7919 + 3);
      var x = -(random.nextDouble() * 80);

      while (x < size.width) {
        final width = 90 + random.nextDouble() * 60;
        final rect = Rect.fromLTWH(x, y, width, blockHeight);

        canvas.drawRect(
          rect,
          random.nextBool() ? fillA : fillB,
        );
        canvas.drawRect(rect, joint);

        x += width;
      }

      row++;
    }
  }

  @override
  bool shouldRepaint(_AshlarPainter oldDelegate) => false;
}

/// A running Greek-key (meander) band, drawn in gilt.
class _MeanderBand extends StatelessWidget {
  final double height;

  const _MeanderBand({this.height = 12});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: const CustomPaint(
          painter: _MeanderPainter(color: _Palette.gold),
        ),
      ),
    );
  }
}

class _MeanderPainter extends CustomPainter {
  final Color color;

  const _MeanderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.height * 0.1;
    final u = (size.height - stroke) / 4;
    final cell = u * 5;

    if (u <= 0 || size.width < cell) {
      return;
    }

    final count = (size.width / cell).floor();
    final startX = (size.width - count * cell) / 2;
    final top = stroke / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.miter
      ..strokeCap = StrokeCap.butt;

    final path = Path();

    for (var i = 0; i < count; i++) {
      final x = startX + i * cell;

      // Baseline running into the next key.
      path.moveTo(x, top + 4 * u);
      path.lineTo(x + cell, top + 4 * u);

      // The key: an inward-turning square spiral.
      path.moveTo(x, top + 4 * u);
      path.lineTo(x, top);
      path.lineTo(x + 3 * u, top);
      path.lineTo(x + 3 * u, top + 3 * u);
      path.lineTo(x + 1 * u, top + 3 * u);
      path.lineTo(x + 1 * u, top + 1 * u);
      path.lineTo(x + 2 * u, top + 1 * u);
      path.lineTo(x + 2 * u, top + 2 * u);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_MeanderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// A cameo: a disc inside a double gilt ring, like the Settings avatar.
class _Cameo extends StatelessWidget {
  final Widget child;
  final double size;
  final Color fill;
  final Color ring;

  const _Cameo({
    required this.child,
    this.size = 46,
    this.fill = _Palette.cameoFill,
    this.ring = _Palette.gold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 1.2),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Item card
// ---------------------------------------------------------------------------

class _CatalogItemCard extends StatelessWidget {
  final CatalogItem item;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  const _CatalogItemCard({
    required this.item,
    required this.onEdit,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final initial = item.name.isEmpty
        ? ''
        : String.fromCharCode(item.name.runes.first)
            .toUpperCase();

    // Double frame, like a mounted plate: an outer border and a fine inner
    // fillet. Inactive items recede with softer gilding.
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      color: item.active ? _Palette.surface : _Palette.recess,
      shape: item.active ? _frame : _frameSoft,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: _Palette.goldSoft,
              width: 0.75,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
            leading: _Cameo(
              fill: item.active
                  ? _Palette.cameoFill
                  : _Palette.cameoFillInactive,
              ring: item.active
                  ? _Palette.gold
                  : _Palette.goldSoft,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: item.active
                      ? _Palette.cameoInk
                      : _Palette.cameoInkInactive,
                ),
              ),
            ),
            title: Text(
              item.name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: item.active
                    ? _Palette.text
                    : _Palette.textMuted,
              ),
            ),
            subtitle: item.brand != null || item.size != null
                ? Text(
                    [
                      if (item.brand != null) item.brand!,
                      if (item.size != null) item.size!,
                    ].join(' • '),
                    style: const TextStyle(
                      color: _Palette.textMuted,
                    ),
                  )
                : Text(
                    item.active ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      color: _Palette.textMuted,
                    ),
                  ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: _Palette.gold,
              ),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                    break;
                  case 'toggle':
                    onToggleActive();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    iconColor: _Palette.gold,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit'),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'toggle',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    iconColor: _Palette.gold,
                    leading: Icon(
                      item.active
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    title: Text(
                      item.active ? 'Deactivate' : 'Activate',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty and error states
// ---------------------------------------------------------------------------

class _CatalogEmpty extends StatelessWidget {
  final ExpenseCategory category;
  final VoidCallback onAdd;

  const _CatalogEmpty({
    required this.category,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Cameo(
              size: 92,
              child: Icon(
                Icons.account_balance_outlined,
                size: 42,
                color: _Palette.cameoInk,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No ${_categoryLabel(category)} items yet.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add an item here before it can be selected '
              'during expense entry.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _Palette.textMuted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            const SizedBox(
              width: 150,
              child: _MeanderBand(height: 12),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Catalog Item'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  final VoidCallback onRetry;

  const _CatalogError({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Cameo(
              size: 84,
              fill: _Palette.danger,
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: _Palette.snackText,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load the catalog.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 150,
              child: _MeanderBand(height: 12),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Editor dialog
// ---------------------------------------------------------------------------

class _CatalogEditorDialog extends StatefulWidget {
  final ExpenseCategory category;
  final CatalogItem? item;

  const _CatalogEditorDialog({
    required this.category,
    this.item,
  });

  @override
  State<_CatalogEditorDialog> createState() =>
      _CatalogEditorDialogState();
}

class _CatalogEditorDialogState
    extends State<_CatalogEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _sizeController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.item?.name ?? '',
    );

    _brandController = TextEditingController(
      text: widget.item?.brand ?? '',
    );

    _sizeController = TextEditingController(
      text: widget.item?.size ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  bool get _isBeverage =>
      widget.category == ExpenseCategory.beveragesAndDrinks;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _Palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: _frame,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      actionsAlignment: MainAxisAlignment.center,
      title: Text(
        widget.item == null
            ? 'Add Catalog Item'
            : 'Edit Catalog Item',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: _Palette.text,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _MeanderBand(height: 14),
              const SizedBox(height: 20),
              DropdownButtonFormField<ExpenseCategory>(
                value: widget.category,
                dropdownColor: _Palette.surface,
                borderRadius: BorderRadius.circular(2),
                iconEnabledColor: _Palette.gold,
                iconDisabledColor: _Palette.goldSoft,
                decoration: _fieldDecoration('Category'),
                items: [
                  DropdownMenuItem(
                    value: widget.category,
                    child: Text(
                      _categoryLabel(widget.category),
                    ),
                  ),
                ],
                onChanged: null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameController,
                cursorColor: _Palette.gold,
                decoration: _fieldDecoration('Display name'),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Enter an item name.';
                  }

                  return null;
                },
              ),
              if (_isBeverage) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _brandController,
                  cursorColor: _Palette.gold,
                  decoration: _fieldDecoration('Brand'),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Enter a beverage brand.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _sizeController,
                  cursorColor: _Palette.gold,
                  decoration: _fieldDecoration('Size'),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Enter a beverage size.';
                    }

                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }

            Navigator.of(context).pop(
              _CatalogFormResult(
                category: widget.category,
                name: _nameController.text.trim(),
                brand: _isBeverage
                    ? _brandController.text.trim()
                    : null,
                size: _isBeverage
                    ? _sizeController.text.trim()
                    : null,
              ),
            );
          },
          child: Text(
            widget.item == null ? 'Add' : 'Save',
          ),
        ),
      ],
    );
  }
}

class _CatalogFormResult {
  final ExpenseCategory category;
  final String name;
  final String? brand;
  final String? size;

  const _CatalogFormResult({
    required this.category,
    required this.name,
    this.brand,
    this.size,
  });
}
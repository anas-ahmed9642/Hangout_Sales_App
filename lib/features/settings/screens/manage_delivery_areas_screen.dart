import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hangout_sales_app/features/orders/models/menu_data.dart';

import '../../delivery_areas/models/delivery_area.dart';
import '../../delivery_areas/providers/delivery_areas_provider.dart';
import '../../delivery_areas/providers/delivery_area_repository_provider.dart';
import '../../../shared/widgets/hangout_app_bar.dart';

// ---------------------------------------------------------------------------
// Neoclassical design tokens (presentation only) - mirrors
// manage_catalog_screen.dart so the two manage screens look like siblings.
// ---------------------------------------------------------------------------

const bool _blackBackground = false;

class _Palette {
  static const bg = _blackBackground ? Color(0xFF0B0A08) : Color(0xFFF7EFDF);
  static const stoneA =
      _blackBackground ? Color(0xFF12100D) : Color(0xFFFAF3E5);
  static const stoneB =
      _blackBackground ? Color(0xFF0E0C0A) : Color(0xFFF3E9D5);
  static const joint =
      _blackBackground ? Color(0xFF1C1813) : Color(0xFFE8DBBF);

  static const surface =
      _blackBackground ? Color(0xFF17140F) : Color(0xFFF4F2EE);
  static const recess =
      _blackBackground ? Color(0xFF100E0B) : Color(0xFFE6E1D6);

  static const text =
      _blackBackground ? Color(0xFFF3E9D2) : Color(0xFF0A0A0A);
  static const textMuted =
      _blackBackground ? Color(0xFFB3A788) : Color(0xFF5E5A52);

  static const gold =
      _blackBackground ? Color(0xFFD4AF37) : Color(0xFFB8922B);
  static const goldText =
      _blackBackground ? Color(0xFFE3BD45) : Color(0xFF8A6A12);
  static const goldSoft =
      _blackBackground ? Color(0xFF5C4A1C) : Color(0xFFE0CB86);

  static const button =
      _blackBackground ? Color(0xFFD4AF37) : Color(0xFF0A0A0A);
  static const onButton =
      _blackBackground ? Color(0xFF0A0A0A) : Color(0xFFE3BD45);

  static const cameoFill =
      _blackBackground ? Color(0xFF000000) : Color(0xFF0A0A0A);
  static const cameoInk = Color(0xFFE3BD45);
  static const cameoFillInactive =
      _blackBackground ? Color(0xFF201C16) : Color(0xFFE6E1D6);
  static const cameoInkInactive =
      _blackBackground ? Color(0xFF8F846A) : Color(0xFF77716A);

  static const danger = Color(0xFF7F1D1D);
  static const snackBg =
      _blackBackground ? Color(0xFF1F1B14) : Color(0xFF0A0A0A);
  static const snackText = Color(0xFFF6EEDC);
}

const _frame = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(2)),
  side: BorderSide(color: _Palette.gold),
);

const _frameSoft = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(2)),
  side: BorderSide(color: _Palette.goldSoft),
);

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

String _chargeLabel(double charge) =>
    'Rs. ${charge.toStringAsFixed(0)}';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ManageDeliveryAreasScreen extends ConsumerWidget {
  const ManageDeliveryAreasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areasAsync = ref.watch(deliveryAreasProvider);

    final baseTheme = Theme.of(context);
    const areasAppBar = HangoutAppBar(
      title: 'Manage Delivery Areas',
    );

    return Theme(
      data: _neoclassicalTheme(baseTheme),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: _Palette.bg,
            appBar: PreferredSize(
              preferredSize: areasAppBar.preferredSize,
              child: Theme(
                data: baseTheme,
                child: areasAppBar,
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
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 18, 16, 2),
                        child: _MeanderBand(height: 14),
                      ),
                      Expanded(
                        child: areasAsync.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(
                              color: _Palette.gold,
                              strokeWidth: 2.5,
                            ),
                          ),
                          error: (error, stackTrace) => _AreasError(
                            onRetry: () {
                              ref.invalidate(deliveryAreasProvider);
                            },
                          ),
                          data: (areas) {
                            if (areas.isEmpty) {
                              return _AreasEmpty(
                                onAdd: () => _showAreaEditor(
                                  context,
                                  ref,
                                ),
                              );
                            }

                            return RefreshIndicator(
                              color: _Palette.gold,
                              backgroundColor: _Palette.surface,
                              onRefresh: () async {
                                ref.invalidate(deliveryAreasProvider);
                                await ref.read(
                                  deliveryAreasProvider.future,
                                );
                              },
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  96,
                                ),
                                itemCount: areas.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final area = areas[index];

                                  return _AreaCard(
                                    area: area,
                                    onEdit: () => _showAreaEditor(
                                      context,
                                      ref,
                                      area: area,
                                    ),
                                    onToggleActive: () async {
                                      await _toggleActive(
                                        context,
                                        ref,
                                        area,
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
              onPressed: () => _showAreaEditor(
                context,
                ref,
              ),
              backgroundColor: _Palette.button,
              foregroundColor: _Palette.onButton,
              elevation: 3,
              shape: _frame,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Area',
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
    DeliveryArea area,
  ) async {
    try {
      await ref
          .read(deliveryAreaRepositoryProvider)
          .setAreaActive(
            area.id,
            !area.active,
          );

      ref.invalidate(deliveryAreasProvider);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              area.active
                  ? '${area.name} deactivated.'
                  : '${area.name} activated.',
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
              'Unable to update delivery area: $error',
            ),
          ),
        );
    }
  }

  Future<void> _showAreaEditor(
    BuildContext context,
    WidgetRef ref, {
    DeliveryArea? area,
  }) async {
    final result = await showDialog<_AreaFormResult>(
      context: context,
      builder: (dialogContext) {
        return _AreaEditorDialog(
          area: area,
        );
      },
    );

    if (result == null) {
      return;
    }

    try {
      final repository = ref.read(deliveryAreaRepositoryProvider);

      if (area == null) {
        await repository.createArea(
          name: result.name,
          defaultCharge: result.defaultCharge,
        );
      } else {
        await repository.updateArea(
          area.id,
          name: result.name,
          defaultCharge: result.defaultCharge,
        );
      }

      ref.invalidate(deliveryAreasProvider);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              area == null
                  ? 'Delivery area added.'
                  : 'Delivery area updated.',
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
              'Unable to save delivery area: $error',
            ),
          ),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Ornament: ashlar wall, Greek-key band and cameo medallion
// ---------------------------------------------------------------------------

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

      path.moveTo(x, top + 4 * u);
      path.lineTo(x + cell, top + 4 * u);

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
// Area card
// ---------------------------------------------------------------------------

class _AreaCard extends StatelessWidget {
  final DeliveryArea area;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  const _AreaCard({
    required this.area,
    required this.onEdit,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final initial = area.name.isEmpty
        ? ''
        : String.fromCharCode(area.name.runes.first).toUpperCase();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      color: area.active ? _Palette.surface : _Palette.recess,
      shape: area.active ? _frame : _frameSoft,
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
              fill: area.active
                  ? _Palette.cameoFill
                  : _Palette.cameoFillInactive,
              ring: area.active
                  ? _Palette.gold
                  : _Palette.goldSoft,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: area.active
                      ? _Palette.cameoInk
                      : _Palette.cameoInkInactive,
                ),
              ),
            ),
            title: Text(
              area.name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: area.active
                    ? _Palette.text
                    : _Palette.textMuted,
              ),
            ),
            subtitle: Text(
              area.active
                  ? _chargeLabel(area.defaultCharge)
                  : '${_chargeLabel(area.defaultCharge)} - Inactive',
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
                      area.active
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    title: Text(
                      area.active ? 'Deactivate' : 'Activate',
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

class _AreasEmpty extends StatelessWidget {
  final VoidCallback onAdd;

  const _AreasEmpty({
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
                Icons.local_shipping_outlined,
                size: 42,
                color: _Palette.cameoInk,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No delivery areas yet.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a sector here before it can be selected '
              'during order entry.',
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
              label: const Text('Add Delivery Area'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreasError extends StatelessWidget {
  final VoidCallback onRetry;

  const _AreasError({
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
              'Unable to load delivery areas.',
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

class _AreaEditorDialog extends StatefulWidget {
  final DeliveryArea? area;

  const _AreaEditorDialog({
    this.area,
  });

  @override
  State<_AreaEditorDialog> createState() => _AreaEditorDialogState();
}

class _AreaEditorDialogState extends State<_AreaEditorDialog> {
  late final TextEditingController _nameController;
  late double? _selectedCharge;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.area?.name ?? '',
    );
    _selectedCharge = widget.area?.defaultCharge;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

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
        widget.area == null ? 'Add Delivery Area' : 'Edit Delivery Area',
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
              TextFormField(
                controller: _nameController,
                cursorColor: _Palette.gold,
                decoration: _fieldDecoration(
                  'Area name',
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: _Palette.gold,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter an area name.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<double>(
                initialValue: _selectedCharge,
                dropdownColor: _Palette.surface,
                borderRadius: BorderRadius.circular(2),
                iconEnabledColor: _Palette.gold,
                decoration: _fieldDecoration(
                  'Default delivery charge',
                  prefixIcon: const Icon(
                    Icons.payments_outlined,
                    color: _Palette.gold,
                  ),
                ),
                items: MenuData.deliveryCharges.map((charge) {
                  return DropdownMenuItem<double>(
                    value: charge,
                    child: Text(_chargeLabel(charge)),
                  );
                }).toList(),
                onChanged: (charge) {
                  setState(() {
                    _selectedCharge = charge;
                  });
                },
                validator: (charge) {
                  if (charge == null) {
                    return 'Select a delivery charge.';
                  }

                  if (!MenuData.deliveryCharges.contains(charge)) {
                    return 'Invalid delivery charge.';
                  }

                  return null;
                },
              ),
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
              _AreaFormResult(
                name: _nameController.text.trim(),
                defaultCharge: _selectedCharge!,
              ),
            );
          },
          child: Text(
            widget.area == null ? 'Add' : 'Save',
          ),
        ),
      ],
    );
  }
}

class _AreaFormResult {
  final String name;
  final double defaultCharge;

  const _AreaFormResult({
    required this.name,
    required this.defaultCharge,
  });
}
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

import '../models/receipt_data.dart';

class ReceiptBuilder {
  const ReceiptBuilder();

  Future<List<int>> build(ReceiptData data) async {
    final profile = await CapabilityProfile.load();

    final generator = Generator(
      PaperSize.mm58,
      profile,
    );

    final bytes = <int>[];

   bytes.addAll(generator.reset());

    try {
      // Load the PNG asset from the app bundle
      final byteData = await rootBundle.load('assets/hangout_receipt_logo.png');
      final imageBytes = byteData.buffer.asUint8List();
      
      // Decode the PNG into an image map
      final decodedImage = img.decodeImage(imageBytes);

      if (decodedImage != null) {
        // Enforce the 384px width limit for 58mm printers
        final resizedImage = img.copyResize(decodedImage, width: 384);
        
        // Convert to ESC/POS raster format
        bytes.addAll(
          generator.imageRaster(
            resizedImage,
            align: PosAlign.center,
          ),
        );
        
        bytes.addAll(generator.feed(1));
      } else {
        _fallbackHeader(bytes, generator, data.storeName);
      }
    } catch (_) {
      // If the asset fails to load for any reason, print the text name instead
      _fallbackHeader(bytes, generator, data.storeName);
    }

    bytes.addAll(
      generator.text(
        'Order ${data.orderNumber}',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
        ),
      ),
    );

    bytes.addAll(
      generator.text(
        DateFormat('dd MMM yyyy - hh:mm a')
            .format(data.createdAt),
        styles: const PosStyles(
          align: PosAlign.center,
        ),
        linesAfter: 1,
      ),
    );

    bytes.addAll(
      generator.hr(),
    );

    bytes.addAll(
      generator.text(
        'CUSTOMER',
        styles: const PosStyles(
          bold: true,
        ),
      ),
    );

    bytes.addAll(
      generator.text(
        data.customerName,
      ),
    );

    if (data.customerPhone?.trim().isNotEmpty == true) {
      bytes.addAll(
        generator.text(
          'Phone: ${data.customerPhone!.trim()}',
        ),
      );
    }

    if (data.customerAddress?.trim().isNotEmpty == true) {
      bytes.addAll(
        generator.text(
          'Address: ${data.customerAddress!.trim()}',
        ),
      );
    }

    if (data.deliveryNotes?.trim().isNotEmpty == true) {
      bytes.addAll(
        generator.text(
          'NOTE: ${data.deliveryNotes!.trim()}',
        ),
      );
    }

    bytes.addAll(
      generator.hr(),
    );

    bytes.addAll(
      generator.text(
        'ITEMS',
        styles: const PosStyles(
          bold: true,
        ),
      ),
    );

    for (final item in data.items) {
      bytes.addAll(
        generator.row(
          [
            PosColumn(
              text: '${item.quantity}x ${item.title}',
              width: 8,
              styles: const PosStyles(
                bold: true,
              ),
            ),
            PosColumn(
              text: _money(item.amount),
              width: 4,
              styles: const PosStyles(
                align: PosAlign.right,
              ),
            ),
          ],
        ),
      );

           if (item.detail != null &&
          item.detail!.trim().isNotEmpty) {
        for (final line in item.detail!.split('\n')) {
          if (line.trim().isEmpty) continue;

          bytes.addAll(
            generator.text(
              line,
              styles: const PosStyles(
                fontType: PosFontType.fontB,
              ),
            ),
          );
        }
      }
    }

    if (data.additionalItems.isNotEmpty) {
      bytes.addAll(
        generator.hr(),
      );

      bytes.addAll(
        generator.text(
          'ADDITIONAL ITEMS',
          styles: const PosStyles(
            bold: true,
          ),
        ),
      );

      for (final item in data.additionalItems) {
        bytes.addAll(
          generator.text(
            '${item.quantity}x ${item.title}',
          ),
        );
      }
    }

    bytes.addAll(
      generator.hr(),
    );

    bytes.addAll(
      _summaryRow(
        generator,
        'Pizza subtotal',
        data.pizzaSubtotal,
      ),
    );

    if (data.additionalDrinksTotal > 0) {
      bytes.addAll(
        _summaryRow(
          generator,
          'Additional drinks',
          data.additionalDrinksTotal,
        ),
      );
    }

    if (data.additionalDipSauceTotal > 0) {
      bytes.addAll(
        _summaryRow(
          generator,
          'Dip sauce',
          data.additionalDipSauceTotal,
        ),
      );
    }

    bytes.addAll(
      _summaryRow(
        generator,
        'Delivery',
        data.deliveryCharge,
      ),
    );

    bytes.addAll(
      generator.hr(),
    );

    bytes.addAll(
      generator.row(
        [
          PosColumn(
            text: 'TOTAL',
            width: 7,
            styles: const PosStyles(
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size2,
            ),
          ),
          PosColumn(
            text: _money(data.total),
            width: 5,
            styles: const PosStyles(
              align: PosAlign.right,
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size2,
            ),
          ),
        ],
      ),
    );

    bytes.addAll(
      generator.text(
        'Payment: ${data.paymentStatus}',
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      ),
    );

    bytes.addAll(
      generator.text(
        'Status: ${data.fulfillmentStatus}',
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      ),
    );

    bytes.addAll(
      generator.feed(2),
    );

    bytes.addAll(
      generator.text(
        'Thank you for ordering!',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
        ),
      ),
    );

    bytes.addAll(
      generator.feed(2),
    );

    bytes.addAll(
      generator.cut(),
    );

    return bytes;
  }

  List<int> _summaryRow(
    Generator generator,
    String label,
    double amount,
  ) {
    return generator.row(
      [
        PosColumn(
          text: label,
          width: 8,
        ),
        PosColumn(
          text: _money(amount),
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
          ),
        ),
      ],
    );
  }

  String _money(double value) {
    return 'Rs. ${value.toStringAsFixed(0)}';
  }
  
  void _fallbackHeader(
    List<int> bytes,
    Generator generator,
    String storeName,
  ) {
    bytes.addAll(
      generator.text(
        storeName,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
        linesAfter: 1,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';

class BarcodeGenerator extends StatelessWidget {
  final String data;
  final double width;
  final double height;
  final bool showText;

  const BarcodeGenerator({
    super.key,
    required this.data,
    this.width = 200,
    this.height = 80,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: BarcodeWidget(
        barcode: Barcode.code128(), // Code 128 is versatile for alphanumeric
        data: data,
        width: width,
        height: height,
        drawText: showText,
        style: const TextStyle(fontSize: 12, color: Colors.black),
      ),
    );
  }
}

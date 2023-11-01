import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeOverlay extends StatelessWidget {
  const QrCodeOverlay({super.key, required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.7,
      child: QrImageView(
        data: data.contains('http://') ? data : 'http://$data',
        backgroundColor: material.Colors.white38,
        version: QrVersions.auto,
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
      ),
    );
  }
}

Future<String?> getWebUrl() async {
  final data = await NetworkInterface.list();
  final addresses = data.expand((element) => element.addresses).where((element) => element.type == InternetAddressType.IPv4).toList();
  final ip = addresses.first.address;
  if (addresses.isEmpty) {
    return null;
  }
  return ip;
}

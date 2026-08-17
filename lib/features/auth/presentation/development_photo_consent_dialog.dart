import 'package:flutter/material.dart';

Future<bool?> requestDevelopmentPhotoConsent(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Cloud photo backup'),
      content: const SingleChildScrollView(
        child: Text(
          'Development privacy notice (draft v1)\n\n'
          'Chami synchronizes scan metadata, batches, orders, and account '
          'settings so your account can work across devices. If you allow '
          'photo backup, Chami also stores the compressed, metadata-stripped '
          'JPEG retained in History. Photos are private to your account.\n\n'
          'You can withdraw photo consent later. Withdrawal removes uploaded '
          'photos while keeping local copies and metadata synchronization. '
          'Account tools provide deletion. This wording is '
          'for development and still requires authorized review before thesis '
          'release.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Metadata only'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Allow photo backup'),
        ),
      ],
    ),
  );
}

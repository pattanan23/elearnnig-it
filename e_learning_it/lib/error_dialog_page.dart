import 'package:flutter/material.dart';

class ErrorDialogPage extends StatelessWidget {
  final String message;

  const ErrorDialogPage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.all(24),
      title: const Text(
        'ไม่สามารถเข้าสู่ระบบได้',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      actions: <Widget>[
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow, // สีเหลืองตามรูปภาพ
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              elevation: 2,
            ),
            child: const Text('ตกลง', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }
}

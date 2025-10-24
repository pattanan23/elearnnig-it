import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 1. Import หน้าจอที่เราจะเทส
import 'package:e_learning_it/login/reset_password_request.dart';

// 2. Import หน้าจอที่เกี่ยวข้อง (เผื่อต้องใช้)
// (จากโค้ดของคุณ หน้านี้จะไปที่ ResetPasswordVerifyScreen
// และอาจจะแสดง ErrorDialogPage)
import 'package:e_learning_it/login/reset_password_verify.dart';
import 'package:e_learning_it/error_dialog_page.dart';

void main() {
  // Helper Function (ตัวช่วย) เพื่อสร้างหน้า ResetPasswordRequestScreen
  Future<void> pumpResetScreen(WidgetTester tester) async {
    // เราต้องหุ้มด้วย MaterialApp เพื่อให้ Widget (เช่น Navigator, AppBar) ทำงานได้
    await tester.pumpWidget(MaterialApp(
      home: const ResetPasswordRequestScreen(),
      // (กำหนด routes จำลอง เผื่อเทสการ
      // Navigator.push ไปยัง ResetPasswordVerifyScreen)
      routes: {
        '/verify': (context) => const ResetPasswordVerifyScreen(identifier: 'test'),
      },
    ));
    await tester.pumpAndSettle(); // รอ UI นิ่ง
  }

  // --- เริ่มการเทส ---

  group('ResetPasswordRequestScreen Widget Tests', () {
    
    // Test Case 1: ตรวจสอบว่า UI เริ่มต้นแสดงครบ
    testWidgets('Initial UI elements are displayed correctly', (WidgetTester tester) async {
      // 1. สร้างหน้า
      await pumpResetScreen(tester);

      // 2. ตรวจสอบ AppBar (จากโค้ดของคุณ)
      expect(find.text('ร้องขอรีเซ็ตรหัสผ่าน'), findsOneWidget);

      // 3. ตรวจสอบข้อความใน Body
      expect(find.text('กรุณากรอก Email หรือรหัสนิสิต'), findsOneWidget);

      // 4. ตรวจสอบช่องกรอก (จาก labelText)
      expect(find.widgetWithText(TextFormField, 'Email หรือ รหัสนิสิต'), findsOneWidget);

      // 5. ตรวจสอบปุ่ม (ต้องไม่มี Loading)
      expect(find.widgetWithText(ElevatedButton, 'ส่งรหัส OTP'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    // Test Case 2: ตรวจสอบการพิมพ์ข้อความในช่องกรอก
    testWidgets('Can enter text into text field', (WidgetTester tester) async {
      await pumpResetScreen(tester);

      // 1. พิมพ์ในช่องกรอก
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email หรือ รหัสนิสิต'),
        'test@example.com'
      );
      await tester.pump(); // อัปเดต UI

      // 2. ตรวจสอบว่าข้อความอยู่บนจอ
      expect(find.text('test@example.com'), findsOneWidget);
    });

    // Test Case 3: ตรวจสอบ Validation (เมื่อไม่กรอกอะไรเลย)
    testWidgets('Shows validation error when field is empty', (WidgetTester tester) async {
      await pumpResetScreen(tester);

      // 1. กดปุ่ม "ส่งรหัส OTP" (โดยที่ยังไม่กรอกอะไร)
      await tester.tap(find.text('ส่งรหัส OTP'));
      await tester.pump(); // รอ validator ทำงาน

      // 2. ตรวจสอบว่ามีข้อความ Error ของ validator แสดงขึ้นมา
      // 💡 (แก้ไข) เราคาดหวัง 1 อัน (findsOneWidget)
      // เพราะ errorText จะ "แทนที่" labelText, ไม่ได้ "เพิ่ม" เข้ามา
      expect(find.text('กรุณากรอก Email หรือ รหัสนิสิต'), findsOneWidget); 
    });

    

  });
}


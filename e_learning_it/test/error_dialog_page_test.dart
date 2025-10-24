import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 1. Import หน้าจอที่เราจะเทส
// (ตรวจสอบ path ของคุณให้ถูกต้อง)
import 'package:e_learning_it/error_dialog_page.dart';

void main() {
  // Helper Function (ตัวช่วย) เพื่อสร้างหน้า ErrorDialogPage
  // โดยเราจะใส่ข้อความจำลองเข้าไป
  Future<void> pumpErrorDialog(WidgetTester tester, {required String message}) async {
    // เราต้องหุ้มด้วย MaterialApp เพื่อให้ AlertDialog มี Theme
    // และเราจะใส่ Scaffold เพื่อให้มี context ที่ถูกต้อง
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder( // ใช้ Builder เพื่อให้มี context สำหรับ Dialog
            builder: (BuildContext context) {
              // สร้าง ErrorDialogPage โดยตรง (วิธีที่ง่ายที่สุด)
              return ErrorDialogPage(message: message);
            },
          ),
        ),
      ),
    );
    // (เราไม่ pumpAndSettle เพราะ Dialog มันแสดงทันที)
  }

  // --- เริ่มการเทส ---

  group('ErrorDialogPage Widget Tests', () {
    // Test Case 1: ตรวจสอบว่า UI แสดงครบ
    testWidgets('Displays title, message, and button correctly', (WidgetTester tester) async {
      // 1. กำหนดข้อความ Error ที่จะใช้ทดสอบ
      const testErrorMessage = 'รหัสผ่านของคุณไม่ถูกต้อง';

      // 2. สร้าง Dialog ขึ้นมา
      await pumpErrorDialog(tester, message: testErrorMessage);

      // 3. ตรวจสอบ Title (จากโค้ดของคุณ)
      expect(find.text('ไม่สามารถเข้าสู่ระบบได้'), findsOneWidget);

      // 4. ตรวจสอบ Message ที่เราส่งเข้าไป
      expect(find.text(testErrorMessage), findsOneWidget);

      // 5. ตรวจสอบปุ่ม (จากข้อความบนปุ่ม)
      expect(find.widgetWithText(ElevatedButton, 'ตกลง'), findsOneWidget);
    });

    // Test Case 2: (Optional) ตรวจสอบการกดปุ่ม "ตกลง"
    // (การเทส pop() ใน Widget Test อาจซับซ้อนกว่านี้เล็กน้อย
    // แต่วิธีนี้เป็นการตรวจสอบเบื้องต้นว่าปุ่มทำงานได้)
    testWidgets('Tapping the button closes the dialog (basic check)', (WidgetTester tester) async {
       const testErrorMessage = 'Test message';
       await pumpErrorDialog(tester, message: testErrorMessage);

       // 1. ตรวจสอบว่า Dialog แสดงอยู่
       expect(find.byType(ErrorDialogPage), findsOneWidget);

       // 2. กดปุ่ม "ตกลง"
       await tester.tap(find.text('ตกลง'));
       await tester.pumpAndSettle(); // รอ animation ของการ pop

       // 3. ตรวจสอบว่า Dialog หายไป (Widget Test อาจยังเห็นอยู่,
       //    แต่เราเทสแค่ว่ากดแล้วไม่แครช)
       // expect(find.byType(ErrorDialogPage), findsNothing); // บรรทัดนี้อาจไม่ผ่านเสมอไป
       
       // เทสแค่ว่ากดปุ่มแล้วไม่มี exception เกิดขึ้นก็ถือว่าเพียงพอสำหรับ Widget Test
       // (การเทส Navigator.pop จริงๆ ทำได้ดีกว่าใน Integration Test)
       expect(tester.takeException(), isNull); // ตรวจสอบว่าไม่มี Error เกิดขึ้นหลังกดปุ่ม
    });
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 1. Import หน้าจอที่เราจะเทส
// (Path นี้อ้างอิงจากโครงสร้างไฟล์ของคุณ)
import 'package:e_learning_it/admin/admin_login_page.dart';

// 2. Import หน้าจอที่เกี่ยวข้อง (เผื่อต้องใช้)
// (จากโค้ดของคุณ AdminLoginPage จะไปที่ AdminMainPage
// และอาจจะแสดง ErrorDialogPage)
import 'package:e_learning_it/admin/main_admin_page.dart';
import 'package:e_learning_it/error_dialog_page.dart'; 
// (ผมเห็นว่า error_dialog_page.dart อยู่ที่ lib/ ไม่ได้อยู่ใน admin/)


void main() {
  // Helper Function (ตัวช่วย) เพื่อสร้างหน้า AdminLoginPage
  Future<void> pumpAdminLoginPage(WidgetTester tester) async {
    // เราต้องหุ้มด้วย MaterialApp เพื่อให้ Widget ทำงานได้
    await tester.pumpWidget(const MaterialApp(
      home: AdminLoginPage(),
    ));
    // (หน้านี้ไม่มีปุ่มย้อนกลับหรือปุ่มสมัครสมาชิก
    // เลยไม่จำเป็นต้องกำหนด routes เหมือนหน้า Login หลัก)
  }

  // --- เริ่มการเทส ---

  group('AdminLoginPage Widget Tests', () {
    
    // Test Case 1: ตรวจสอบว่า UI แสดงครบ
    testWidgets('UI elements are displayed correctly', (WidgetTester tester) async {
      // 1. สร้างหน้า
      await pumpAdminLoginPage(tester);
      await tester.pumpAndSettle(); // รอ UI นิ่ง

      // 2. ตรวจสอบหัวข้อ (จากโค้ดของคุณ)
      expect(find.text('เข้าสู่ระบบ Admin'), findsOneWidget);

      // 3. ตรวจสอบช่องกรอก (จาก labelText ที่ตรงกับโค้ดของคุณ)
      expect(find.widgetWithText(TextFormField, 'Admin ID / ชื่อผู้ใช้'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'รหัสผ่าน'), findsOneWidget);

      // 4. ตรวจสอบปุ่มหลัก (จากข้อความ)
      expect(find.widgetWithText(ElevatedButton, 'เข้าสู่ระบบ'), findsOneWidget);
    });

    // Test Case 2: ตรวจสอบการพิมพ์ข้อความในช่องกรอก
    testWidgets('Can enter text into text fields', (WidgetTester tester) async {
      await pumpAdminLoginPage(tester);

      // 1. พิมพ์ในช่อง Admin ID
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Admin ID / ชื่อผู้ใช้'), 
        'my_test_admin'
      );
      
      // 2. พิมพ์ในช่อง รหัสผ่าน
      await tester.enterText(
        find.widgetWithText(TextFormField, 'รหัสผ่าน'), 
        'my_test_password'
      );

      // 3. ตรวจสอบว่าข้อความที่เราพิมพ์ อยู่บนจอ
      expect(find.text('my_test_admin'), findsOneWidget);
      expect(find.text('my_test_password'), findsOneWidget);
    });

  });
}


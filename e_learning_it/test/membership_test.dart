import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 1. Import หน้าจอที่เราจะเทส
import 'package:e_learning_it/login/membership.dart';

// 2. Import หน้าจอที่เกี่ยวข้อง (เช่น ErrorDialogPage)
// (จากโค้ดของคุณ `error_dialog_page.dart` อยู่ที่ lib/)
import 'package:e_learning_it/error_dialog_page.dart';
// (หน้านี้มีการ import 'screen_size.dart' ด้วย แต่เราไม่จำเป็นต้อง import
// ในเทส ตราบใดที่ `MemberScreen` import มันถูกต้อง)

void main() {
  // Helper Function (ตัวช่วย) เพื่อสร้างหน้า MemberScreen
  Future<void> pumpMembershipScreen(WidgetTester tester) async {
    // เราต้องหุ้มด้วย MaterialApp เพื่อให้ Widget ทำงานได้
    await tester.pumpWidget(const MaterialApp(
      home: MemberScreen(),
    ));
    await tester.pumpAndSettle(); // รอ UI นิ่ง
  }

  // Helper Function (ตัวช่วย) เพื่อเลือก Role
  Future<void> selectRole(WidgetTester tester, String role) async {
    // 1. กดที่ Dropdown
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle(); // รอเมนูเปิด

    // 2. กดเลือก Role (ใช้ .last เพราะ .first อาจจะเป็นอันที่แสดงอยู่)
    await tester.tap(find.text(role).last);
    await tester.pumpAndSettle(); // รอ UI อัปเดต
  }

  // --- เริ่มการเทส ---

  group('MemberScreen Widget Tests', () {
    // Test Case 1: ตรวจสอบ UI เริ่มต้น (ยังไม่เลือกสถานภาพ)
    testWidgets('Initial UI elements are displayed correctly',
        (WidgetTester tester) async {
      await pumpMembershipScreen(tester);

      // 1. ตรวจสอบ Dropdown
      expect(find.text('กรุณาเลือกสถานภาพ'), findsOneWidget);

      // 2. ตรวจสอบช่องกรอก (จาก labelText ที่ตรงกับโค้ดของคุณ)
      // (รหัสนิสิตควจะขึ้นว่า 'ไม่ต้องกรอก' และ disabled)
      expect(find.widgetWithText(TextFormField, 'ไม่ต้องกรอก'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'ชื่อ'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'นามสกุล'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'อีเมล'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'รหัสผ่าน'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'ยืนยันรหัสผ่าน'), findsOneWidget);

      // 3. ตรวจสอบปุ่ม
      expect(find.widgetWithText(ElevatedButton, 'สมัครสมาชิก'), findsOneWidget);
    });

    // Test Case 2: เทสเมื่อเลือก "นิสิต"
    testWidgets('Selecting "นิสิต" enables Student ID field',
        (WidgetTester tester) async {
      await pumpMembershipScreen(tester);

      // 1. เลือก "นิสิต"
      await selectRole(tester, 'นิสิต');

      // 2. ตรวจสอบว่าช่อง "รหัสนิสิต" เปลี่ยนไป
      expect(find.widgetWithText(TextFormField, 'ไม่ต้องกรอก'), findsNothing);
      expect(find.widgetWithText(TextFormField, 'รหัสนิสิต '), findsOneWidget);

      // 3. ตรวจสอบว่าช่องนี้ "enabled" (โดยการลองพิมพ์)
      await tester.enterText(
          find.widgetWithText(TextFormField, 'รหัสนิสิต '), '1234567890');
      expect(find.text('1234567890'), findsOneWidget);
    });

    // Test Case 3: เทสเมื่อเลือก "อาจารย์"
    testWidgets('Selecting "อาจารย์" changes Email hint text',
        (WidgetTester tester) async {
      await pumpMembershipScreen(tester);

      // 1. เลือก "อาจารย์"
      await selectRole(tester, 'อาจารย์');

      // 2. ตรวจสอบว่าช่อง "รหัสนิสิต" ยังคง disabled
      expect(find.widgetWithText(TextFormField, 'ไม่ต้องกรอก'), findsOneWidget);

      // 3. ตรวจสอบ "hintText" ของอีเมล
      expect(find.text('เมล ku.th เท่านั้น'), findsOneWidget);
    });

    // Test Case 4: เทสเมื่อเลือก "บุคคลภายนอก"
    testWidgets('Selecting "บุคคลภายนอก" changes Email hint text',
        (WidgetTester tester) async {
      await pumpMembershipScreen(tester);

      // 1. เลือก "บุคคลภายนอก"
      await selectRole(tester, 'บุคคลภายนอก');

      // 2. ตรวจสอบว่าช่อง "รหัสนิสิต" ยังคง disabled
      expect(find.widgetWithText(TextFormField, 'ไม่ต้องกรอก'), findsOneWidget);

      // 3. ตรวจสอบ "hintText" ของอีเมล
      expect(find.text('เมล gmail.com เท่านั้น'), findsOneWidget);
    });
  });
}

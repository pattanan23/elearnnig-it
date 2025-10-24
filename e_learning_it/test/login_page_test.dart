import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 1. Import หน้าจอที่เราจะเทส
// (ต้องแน่ใจว่า path ไปยัง login_page.dart ถูกต้อง)
import 'package:e_learning_it/login_page.dart';

// 2. Import หน้าจอปลายทางที่ปุ่มจะกดไป
// (ต้อง import ให้ครบทุกหน้าที่เกี่ยวข้อง)
// (จากโค้ด LoginScreen ของคุณ ผมเห็นว่าคุณ import 3 ไฟล์นี้)
import 'package:e_learning_it/admin/admin_login_page.dart';
import 'package:e_learning_it/login/membership.dart';
import 'package:e_learning_it/login/reset_password_request.dart';
// (โค้ดของคุณมีการ import 'error_dialog_page.dart' และหน้าอื่นๆ ด้วย
// แต่สำหรับเทส UI และ Navigation นี้ เรายังไม่จำเป็นต้องใช้ครับ)

void main() {
  // สร้าง Helper Function (ตัวช่วย)
  // เพื่อลดการเขียนโค้ดซ้ำซ้อนในการสร้าง LoginScreen
  Future<void> pumpLoginScreen(WidgetTester tester) async {
    // เราต้องหุ้มด้วย MaterialApp เพื่อให้ Widget (เช่น Navigator) ทำงานได้
    await tester.pumpWidget(const MaterialApp(
      home: LoginScreen(),
    ));
  }

  // --- เริ่มการเทส ---

  group('LoginScreen Widget Tests', () {
    // Test Case 1: ตรวจสอบว่า UI แสดงครบ
    testWidgets('UI elements are displayed correctly', (WidgetTester tester) async {
      // 1. สร้างหน้า Login
      await pumpLoginScreen(tester);

      // 2. ตรวจสอบช่องกรอก (จาก labelText ที่ตรงกับโค้ดของคุณ)
      expect(find.widgetWithText(TextFormField, 'Email / รหัสนิสิต'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'รหัสผ่าน'), findsOneWidget);

      // 3. ตรวจสอบปุ่มหลัก (จากข้อความ)
      expect(find.widgetWithText(ElevatedButton, 'เข้าสู่ระบบ'), findsOneWidget);

      // 4. ตรวจสอบปุ่มรอง (TextButton)
      expect(find.text('สมัครสมาชิก'), findsOneWidget);
      expect(find.text('ลืมรหัสผ่าน?'), findsOneWidget);
      expect(find.text('ระบบผู้ดูแล'), findsOneWidget);
    });

    // Test Case 2: เทสการกดปุ่ม "ระบบผู้ดูแล"
    testWidgets('Tapping "ระบบผู้ดูแล" navigates to AdminLoginPage',
        (WidgetTester tester) async {
      await pumpLoginScreen(tester);

      // 1. ตรวจสอบว่ายังไม่อยู่หน้า Admin
      expect(find.byType(AdminLoginPage), findsNothing);

      // 2. กดปุ่ม (ใช้ ensureVisible เผื่อหน้าจอเล็กแล้วต้องเลื่อน)
      await tester.ensureVisible(find.text('ระบบผู้ดูแล'));
      await tester.tap(find.text('ระบบผู้ดูแล'));
      await tester.pumpAndSettle(); // รอหน้าเปลี่ยน

      // 3. ตรวจสอบว่าไปหน้า AdminLoginPage แล้ว
      expect(find.byType(AdminLoginPage), findsOneWidget);
    });

    // Test Case 3: เทสการกดปุ่ม "สมัครสมาชิก"
    testWidgets('Tapping "สมัครสมาชิก" navigates to MemberScreen',
        (WidgetTester tester) async {
      await pumpLoginScreen(tester);
      await tester.ensureVisible(find.text('สมัครสมาชิก'));
      await tester.tap(find.text('สมัครสมาชิก'));
      await tester.pumpAndSettle();
      expect(find.byType(MemberScreen), findsOneWidget);
    });

    // Test Case 4: เทสการกดปุ่ม "ลืมรหัสผ่าน?"
    testWidgets('Tapping "ลืมรหัสผ่าน?" navigates to ResetPasswordRequestScreen',
        (WidgetTester tester) async {
      await pumpLoginScreen(tester);
      await tester.ensureVisible(find.text('ลืมรหัสผ่าน?'));
      await tester.tap(find.text('ลืมรหัสผ่าน?'));
      await tester.pumpAndSettle();
      expect(find.byType(ResetPasswordRequestScreen), findsOneWidget);
    });

    // (เราจะไม่เทสการกดปุ่ม "เข้าสู่ระบบ" ในนี้
    // เพราะมันต้องต่อ API จริง ซึ่งจะใช้ใน Integration Test หรือการ Mock )
  });
}

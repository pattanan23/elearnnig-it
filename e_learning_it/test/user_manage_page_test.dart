import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 1. Import หน้าจอที่เราจะเทส
// (ตรวจสอบ path ของคุณให้ถูกต้อง)
import 'package:e_learning_it/admin/user_manage_page.dart';

// 2. Import Widget ที่หน้านี้ใช้ (เช่น Navbar, Drawer) ถ้าจำเป็น
// import 'package:e_learning_it/admin/navbar_admin.dart';
// import 'package:e_learning_it/admin/drawer_admin.dart';

void main() {
  // Helper Function สร้างหน้า UserManagementPage
  Future<void> pumpUserManagementPage(WidgetTester tester) async {
    // ใช้ MaterialApp เพื่อให้มี Navigator และ Theme
    // (เราต้องใส่ค่า userName, userId จำลองให้)
    await tester.pumpWidget(const MaterialApp(
      home: UserManagementPage(
        userName: 'Admin Tester',
        userId: 'admin999',
        // (เราไม่ได้ส่ง client เข้าไป เพราะเราไม่ได้แก้ Constructor)
      ),
    ));
    // (เราจะไม่ pumpAndSettle ทันที เพื่อเทส Loading State)
  }

  // --- เริ่มการเทส ---
  group('UserManagementPage Widget Tests (Limited - No API Mocking)', () {
    testWidgets('Shows loading indicator and initial UI elements',
        (WidgetTester tester) async {
      // 1. สร้างหน้า
      await pumpUserManagementPage(tester);

      // 2. ตรวจสอบว่าเห็น Loading Indicator ก่อนที่ API (จริง) จะทำงานเสร็จ
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 3. ตรวจสอบ UI พื้นฐานที่ควรแสดงทันที
      // (Header)
      expect(find.text('จัดการผู้ใช้'), findsOneWidget);
      // (Role Tabs - ตรวจสอบว่ามีครบ)
      expect(find.text('นิสิต'), findsOneWidget); // Tab แรก
      expect(find.text('อาจารย์'), findsOneWidget);
      expect(find.text('บุคคลภายนอก'), findsOneWidget); // ⭐️ ตรวจสอบว่ามี Tab นี้ด้วย

      // (เราจะไม่ pumpAndSettle เพื่อรอ API จริง เพราะอาจจะเฟลหรือไม่เสถียร)
      // (เราจะไม่ตรวจสอบ DataTable ในนี้)
    });

    // Test Case 2: เทสการกด Tab "อาจารย์"
    testWidgets('Tapping "อาจารย์" tab works (UI interaction only)',
        (WidgetTester tester) async {
      await pumpUserManagementPage(tester);
      await tester.pumpAndSettle(); // รอ Loading หายไป (API จริงอาจจะเฟล)

      // 1. ตรวจสอบว่า Tab "นิสิต" มีอยู่
      expect(find.text('นิสิต'), findsOneWidget);

      // 2. ทำให้แน่ใจว่าปุ่ม "อาจารย์" มองเห็นได้ (เลื่อนจอถ้าจำเป็น)
      await tester.ensureVisible(find.text('อาจารย์'));

      // 3. ลองกด Tab "อาจารย์" (เทสแค่ว่ากดได้ ไม่พัง)
      await tester.tap(find.text('อาจารย์'));
      await tester.pumpAndSettle(); // รอ UI อัปเดต

      // 4. ตรวจสอบว่าปุ่ม "อาจารย์" ยังอยู่บนจอ (ไม่ได้หายไปไหน)
      expect(find.text('อาจารย์'), findsOneWidget);

      // (เราจะไม่ตรวจสอบ Style หรือข้อมูลใน DataTable ที่เปลี่ยนไป)
    });

    // ⭐️ --- START NEW TEST CASE --- ⭐️
    // Test Case 3: เทสการกด Tab "บุคคลภายนอก"
    testWidgets('Tapping "บุคคลภายนอก" tab works (UI interaction only)',
        (WidgetTester tester) async {
      await pumpUserManagementPage(tester);
      await tester.pumpAndSettle(); // รอ Loading หายไป (API จริงอาจจะเฟล)

      // 1. ตรวจสอบว่า Tab "นิสิต" มีอยู่
      expect(find.text('นิสิต'), findsOneWidget);

      // 2. ทำให้แน่ใจว่าปุ่ม "บุคคลภายนอก" มองเห็นได้ (เลื่อนจอถ้าจำเป็น)
      await tester.ensureVisible(find.text('บุคคลภายนอก'));

      // 3. ลองกด Tab "บุคคลภายนอก" (เทสแค่ว่ากดได้ ไม่พัง)
      await tester.tap(find.text('บุคคลภายนอก'));
      await tester.pumpAndSettle(); // รอ UI อัปเดต

      // 4. ตรวจสอบว่าปุ่ม "บุคคลภายนอก" ยังอยู่บนจอ (ไม่ได้หายไปไหน)
      expect(find.text('บุคคลภายนอก'), findsOneWidget);

      // (เราจะไม่ตรวจสอบ Style หรือข้อมูลใน DataTable ที่เปลี่ยนไป)
    });
    // ⭐️ --- END NEW TEST CASE --- ⭐️

  });
}


import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 1. Import โค้ดที่เราจะเทส
import 'package:e_learning_it/student_outsiders/course/course_search_widget.dart';

// 2. Import "Course Model" (เพื่อให้ไฟล์เทสนี้รู้จัก Class 'Course')
import 'package:e_learning_it/student_outsiders/course/course_detail_page.dart';



// 3.1 ฟังก์ชันจำลอง (Mock) สำหรับ "รายวิชาทั้งหมด"
Future<List<Course>> mockInitialCourses() async {
  // (ใช้ Constructor ของ Course ที่ถูกต้องตามที่คุณส่งมา)
   return [
      Course(
        courseId: '101',
        userId: 'u1',
        courseCode: 'PY101',
        courseName: 'Python Basics',
        shortDescription: 'Learn Python',
        description: 'Full Python course',
        objective: 'To learn Python',
        professorName: 'Prof. Test',
        imageUrl: 'http://example.com/img.png',
        lessons: [], 
        courseCredit: '3'
      ),
      Course(
        courseId: '102',
        userId: 'u2',
        courseCode: 'JV101',
        courseName: 'Java Basics',
        shortDescription: 'Learn Java',
        description: 'Full Java course',
        objective: 'To learn Java',
        professorName: 'Prof. Java',
        imageUrl: 'http://example.com/img2.png',
        lessons: [],
        courseCredit: '3'
      )
   ];
}

// 3.2 ฟังก์ชันจำลอง (Mock) สำหรับ "buildCourseSection"
Widget mockBuildCourseSection(
  BuildContext context, {
  required String title,
  required Future<List<Course>> futureCourses,
  required String userName,
  required String userId,
}) {
  // เราแค่แสดง Title เพื่อให้เทส "find" มันเจอ
  return Text(title); 
}


void main() {
  group('CourseSearchWidget Test (Easy Test)', () {

    // ⭐️ เราจะเทสแค่ Case นี้ Case เดียวครับ ⭐️
    testWidgets('Initial UI shows TextField and default title', (WidgetTester tester) async {
      // 1. สร้าง Widget (โดยไม่ส่ง searchFunction เข้าไป)
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CourseSearchWidget(
            userName: 'Test User',
            userId: '123',
            initialFutureCourses: mockInitialCourses(), // ⭐️ ฉีด
            buildCourseSection: mockBuildCourseSection, // ⭐️ ฉีด
          ),
        ),
      ));
      await tester.pumpAndSettle(); // รอ Future ของ mockInitialCourses ทำงาน

      // 2. ตรวจสอบช่องค้นหา
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('ค้นหารายวิชา (เช่น S001, Python Programming)'), findsOneWidget);

      // 3. ตรวจสอบ Title เริ่มต้น (จาก mockBuildCourseSection)
      expect(find.text('รายวิชา'), findsOneWidget);
    });

  });
}


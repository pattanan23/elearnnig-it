class Course {
  final String courseCode;
  final String courseName;
  final String shortDescription;
  final String professorName;
  final String imageUrl;

  Course({
    required this.courseCode,
    required this.courseName,
    required this.shortDescription,
    required this.professorName,
    required this.imageUrl,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      // แปลงค่าจาก int เป็น String
      courseCode: json['course_code']?.toString() ?? '',
      courseName: json['course_name'] ?? '',
      shortDescription: json['short_description'] ?? '',
      professorName: json['professor_name'] ?? 'ไม่ระบุ',
      imageUrl: json['image_url'] ?? 'https://placehold.co/600x400.png',
    );
  }
}
// Your existing imports...
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:e_learning_it/professor/drawer_processor.dart';
import 'package:e_learning_it/professor/navbar_professor.dart';
import 'package:e_learning_it/error_dialog_page.dart';
import 'package:e_learning_it/professor/main_professor_page.dart';

// New data model for video lessons
class Lesson {
  final TextEditingController videoNameController;
  final TextEditingController videoDescriptionController;
  PlatformFile? videoPlatformFile;
  PlatformFile? pdfPlatformFile;
  bool isUploading;
  double uploadProgress;
  bool isUploaded;

  Lesson({
    required this.videoNameController,
    required this.videoDescriptionController,
    this.videoPlatformFile,
    this.pdfPlatformFile,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.isUploaded = false,
  });
}

class UploadCoursePage extends StatefulWidget {
  final String userName;
  final String userId;

  const UploadCoursePage(
      {super.key, required this.userName, required this.userId});

  @override
  State<UploadCoursePage> createState() => _UploadCoursePageState();
}

class _UploadCoursePageState extends State<UploadCoursePage> {
  final _formKey = GlobalKey<FormState>();

  final _courseCodeController = TextEditingController();
  final _courseNameController = TextEditingController();
  final _shortDescriptionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _objectiveController = TextEditingController();
  PlatformFile? _selectedImagePlatformFile;
  String? _courseId;

  // Use the new data model for better structure
  final List<Lesson> _videoLessons = [];

  bool _isSubmittingCourse = false;

  @override
  void dispose() {
    _courseCodeController.dispose();
    _courseNameController.dispose();
    _shortDescriptionController.dispose();
    _descriptionController.dispose();
    _descriptionController.dispose();
    _objectiveController.dispose();
    for (var lesson in _videoLessons) {
      lesson.videoNameController.dispose();
      lesson.videoDescriptionController.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedImagePlatformFile = result.files.first;
      });
    }
  }

  Future<void> _pickFileForLesson(Lesson lesson, String type) async {
    FilePickerResult? result;
    if (type == 'video') {
      result = await FilePicker.platform.pickFiles(type: FileType.video);
    } else if (type == 'pdf') {
      result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    }
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        if (type == 'video') {
          lesson.videoPlatformFile = result?.files.first;
        } else {
          lesson.pdfPlatformFile = result?.files.first;
        }
      });
    }
  }

  void _addVideoLesson() {
    setState(() {
      _videoLessons.add(
        Lesson(
          videoNameController: TextEditingController(),
          videoDescriptionController: TextEditingController(),
        ),
      );
    });
  }

  void _removeVideoLesson(int index) {
    setState(() {
      final lesson = _videoLessons[index];
      lesson.videoNameController.dispose();
      lesson.videoDescriptionController.dispose();
      _videoLessons.removeAt(index);
    });
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
        context: context,
        builder: (context) => ErrorDialogPage(message: message));
  }

  void _showSuccessDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('ตกลง'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitCourseDetails() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImagePlatformFile == null) {
        _showErrorDialog('กรุณาเลือกไฟล์รูปภาพรายวิชา');
        return;
      }

      if (!mounted) return;

      setState(() {
        _isSubmittingCourse = true;
      });

      final userId = widget.userId;

      var uri = Uri.parse('http://localhost:3006/api/courses');
      var request = http.MultipartRequest('POST', uri);

      request.fields['user_id'] = userId;
      request.fields['course_code'] = _courseCodeController.text;
      request.fields['course_name'] = _courseNameController.text;
      request.fields['short_description'] = _shortDescriptionController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['objective'] = _objectiveController.text;

      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
            'name_image', _selectedImagePlatformFile!.bytes!,
            filename: _selectedImagePlatformFile!.name));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
            'name_image', _selectedImagePlatformFile!.path!,
            filename: _selectedImagePlatformFile!.name));
      }

      try {
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (!mounted) return;

        if (response.statusCode == 201) {
          final responseData = json.decode(response.body);
          setState(() {
            _courseId = responseData['course_id'].toString();
          });
          _showSuccessDialog('บันทึกสำเร็จ',
              'บันทึกข้อมูลรายวิชาสำเร็จแล้ว! กรุณาอัปโหลดวิดีโอในส่วนถัดไป');
        } else {
          final responseData = json.decode(response.body);
          final errorMessage = responseData['message'] ?? 'ไม่ทราบข้อผิดพลาด';
          _showErrorDialog(errorMessage);
        }
      } catch (e) {
        if (!mounted) return;
        _showErrorDialog('เกิดข้อผิดพลาดในการส่งข้อมูล: $e');
      } finally {
        if (!mounted) return;
        setState(() {
          _isSubmittingCourse = false;
        });
      }
    }
  }

  Future<void> _uploadVideoLesson(int index) async {
    if (_courseId == null) {
      _showErrorDialog('กรุณาบันทึกข้อมูลรายวิชาก่อน');
      return;
    }

    final lesson = _videoLessons[index];

    if (lesson.videoPlatformFile == null) {
      _showErrorDialog('กรุณาเลือกไฟล์วิดีโอสำหรับวิดีโอตอนที่ ${index + 1}');
      return;
    }

    // Check if the widget is mounted before calling setState
    if (!mounted) return;

    setState(() {
      lesson.isUploading = true;
      lesson.uploadProgress = 0.0;
    });

    var uri = Uri.parse('http://localhost:3006/api/upload-video');
    var request = http.MultipartRequest('POST', uri);

    request.fields['course_id'] = _courseId!;
    request.fields['video_name'] = lesson.videoNameController.text;
    request.fields['short_description'] =
        lesson.videoDescriptionController.text;

    if (kIsWeb) {
      request.files.add(http.MultipartFile.fromBytes(
          'video', lesson.videoPlatformFile!.bytes!,
          filename: lesson.videoPlatformFile!.name));
      if (lesson.pdfPlatformFile != null) {
        request.files.add(http.MultipartFile.fromBytes(
            'pdf', lesson.pdfPlatformFile!.bytes!,
            filename: lesson.pdfPlatformFile!.name));
      }
    } else {
      request.files.add(await http.MultipartFile.fromPath(
          'video', lesson.videoPlatformFile!.path!,
          filename: lesson.videoPlatformFile!.name));
      if (lesson.pdfPlatformFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'pdf', lesson.pdfPlatformFile!.path!,
            filename: lesson.pdfPlatformFile!.name));
      }
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 201) {
        _showSuccessDialog(
            'อัปโหลดสำเร็จ', 'อัปโหลดวิดีโอตอนที่ ${index + 1} สำเร็จแล้ว!');
        setState(() {
          lesson.isUploaded = true;
          lesson.uploadProgress = 1.0; // Mark as 100% complete
        });
      } else {
        final responseData = json.decode(response.body);
        final errorMessage = responseData['message'] ?? 'ไม่ทราบข้อผิดพลาด';
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('เกิดข้อผิดพลาดในการอัปโหลด: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        lesson.isUploading = false;
      });
    }
  }

  void _onFinishUpload() {
    if (_courseId == null) {
      _showErrorDialog('กรุณาบันทึกข้อมูลรายวิชาก่อน');
      return;
    }

    final allLessonsUploaded =
        _videoLessons.every((lesson) => lesson.isUploaded == true);

    if (_videoLessons.isEmpty) {
      _showErrorDialog('กรุณาเพิ่มและอัปโหลดวิดีโออย่างน้อย 1 ตอน');
      return;
    }

    if (allLessonsUploaded) {
      // Show success dialog first
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('อัปโหลดสำเร็จทั้งหมด'),
            content: const Text(
                'รายวิชาของคุณถูกสร้างและอัปโหลดวิดีโอสำเร็จเรียบร้อยแล้ว'),
            actions: <Widget>[
              TextButton(
                child: const Text('ตกลง'),
                onPressed: () {
                  // Navigate to MainProfessorPage after user clicks 'OK'
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MainProfessorPage(
                          userName: widget.userName, userId: widget.userId),
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
    } else {
      _showErrorDialog(
          'ยังมีวิดีโอที่ยังไม่ได้อัปโหลด กรุณาอัปโหลดให้ครบทุกตอน');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double horizontalPadding = screenWidth > 600 ? 100.0 : 20.0;
    final double verticalPadding = 24.0;

    return Scaffold(
      appBar:
          NavbarProcessorPage(userName: widget.userName, userId: widget.userId),
      drawer:
          DrawerProcessorPage(userName: widget.userName, userId: widget.userId),
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding, vertical: verticalPadding),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.upload_file, size: 48, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'อัปโหลดรายวิชาใหม่',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSectionCard(
                  title: '1. เนื้อหารายวิชา',
                  children: [
                    _buildTextField(
                        controller: _courseCodeController,
                        label: 'รหัสวิชา',
                        validator: (value) =>
                            value!.isEmpty ? 'กรุณาใส่รหัสวิชา' : null,
                        maxLength: 8),
                    const SizedBox(height: 16),
                    _buildTextField(
                        controller: _courseNameController,
                        label: 'หัวข้อเรื่อง',
                        validator: (value) =>
                            value!.isEmpty ? 'กรุณาใส่หัวข้อเรื่อง' : null),
                    const SizedBox(height: 16),
                    _buildTextField(
                        controller: _shortDescriptionController,
                        label: 'รายละเอียด (สั้นๆ)',
                        validator: (value) =>
                            value!.isEmpty ? 'กรุณาใส่รายละเอียด' : null),
                    const SizedBox(height: 16),
                    _buildTextField(
                        controller: _descriptionController,
                        label: 'คำอธิบายรายวิชา',
                        validator: (value) =>
                            value!.isEmpty ? 'กรุณาใส่คำอธิบายรายวิชา' : null),
                    const SizedBox(height: 16),
                    _buildObjectiveTextField(),
                    const SizedBox(height: 24),
                    _buildFilePicker(
                        label: 'อัปโหลดรูปภาพ',
                        onPressed: _pickImage,
                        fileName: _selectedImagePlatformFile?.name),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed:
                          _isSubmittingCourse ? null : _submitCourseDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                      ),
                      child: _isSubmittingCourse
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                  strokeWidth: 2))
                          : const Text('บันทึกรายละเอียดรายวิชา',
                              style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: '2. วิดีโอรายวิชา',
                  children: [
                    ..._videoLessons.asMap().entries.map((entry) {
                      final index = entry.key;
                      final lesson = entry.value;
                      return _buildVideoLessonCard(lesson, index);
                    }).toList(),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _addVideoLesson,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('เพิ่มวิดีโออีก',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _onFinishUpload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                      ),
                      child: const Text(
                        'เสร็จสิ้น',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // New helper widget to build a section with a white background, shadow, and rounded corners
  Widget _buildSectionCard(
      {required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(title),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // Helper widgets...
  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      int maxLines = 1,
      String? Function(String?)? validator,
      int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          keyboardType:
              maxLines == 1 ? TextInputType.text : TextInputType.multiline,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.grey, width: 1.0)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.grey, width: 1.0)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.green, width: 2.0)),
            counterText: "",
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildObjectiveTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('วัตถุประสงค์',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _objectiveController,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.grey, width: 1.0)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.grey, width: 1.0)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.green, width: 2.0)),
            hintText:
                'เช่น เรียนรู้พื้นฐานการเขียนโปรแกรม  สามารถสร้างแอปพลิเคชันง่ายๆ ',
          ),
          validator: (value) => value!.isEmpty ? 'กรุณาใส่วัตถุประสงค์' : null,
        ),
      ],
    );
  }

  Widget _buildFilePicker(
      {required String label,
      required VoidCallback onPressed,
      String? fileName}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    fileName ?? 'ไม่มีไฟล์ที่เลือก',
                    style: TextStyle(
                        color: fileName != null ? Colors.black : Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.upload, color: Colors.white),
                label: const Text('อัปโหลด',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8.0),
                        bottomRight: Radius.circular(8.0)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoLessonCard(Lesson lesson, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('วิดีโอตอนที่ ${index + 1}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeVideoLesson(index),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Disable text fields while uploading
            AbsorbPointer(
              absorbing: lesson.isUploading,
              child: _buildTextField(
                  controller: lesson.videoNameController,
                  label: 'ชื่อคลิป',
                  validator: (value) =>
                      value!.isEmpty ? 'กรุณาใส่ชื่อคลิป' : null),
            ),
            const SizedBox(height: 16),
            AbsorbPointer(
              absorbing: lesson.isUploading,
              child: _buildTextField(
                  controller: lesson.videoDescriptionController,
                  label: 'รายละเอียดสั้นๆ',
                  maxLines: 2,
                  validator: (value) =>
                      value!.isEmpty ? 'กรุณาใส่รายละเอียด' : null),
            ),
            const SizedBox(height: 16),
            AbsorbPointer(
              absorbing: lesson.isUploading,
              child: _buildFilePicker(
                  label: 'ไฟล์การเรียนการสอน (PDF)',
                  onPressed: () => _pickFileForLesson(lesson, 'pdf'),
                  fileName: lesson.pdfPlatformFile?.name),
            ),
            const SizedBox(height: 16),
            AbsorbPointer(
              absorbing: lesson.isUploading,
              child: _buildFilePicker(
                  label: 'ไฟล์วิดีโอ',
                  onPressed: () => _pickFileForLesson(lesson, 'video'),
                  fileName: lesson.videoPlatformFile?.name),
            ),
            const SizedBox(height: 16),
            if (lesson.isUploading)
              LinearProgressIndicator(value: lesson.uploadProgress),
            if (!lesson.isUploaded)
              ElevatedButton.icon(
                onPressed:
                    lesson.isUploading ? null : () => _uploadVideoLesson(index),
                icon: lesson.isUploading
                    ? const CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white)
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(
                  lesson.isUploading ? 'กำลังอัปโหลด...' : 'บันทึกวิดีโอตอนนี้',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            if (lesson.isUploaded)
              const Text('✅ อัปโหลดสำเร็จ',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
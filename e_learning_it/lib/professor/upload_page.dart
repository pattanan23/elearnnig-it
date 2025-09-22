import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:e_learning_it/professor/drawer_processor.dart';
import 'package:e_learning_it/professor/navbar_professor.dart';
import 'package:e_learning_it/error_dialog_page.dart';

class UploadCoursePage extends StatefulWidget {
  final String userName;
  final String userId;

  const UploadCoursePage({super.key, required this.userName, required this.userId});

  @override
  State<UploadCoursePage> createState() => _UploadCoursePageState();
}

class _UploadCoursePageState extends State<UploadCoursePage> {
  final _formKey = GlobalKey<FormState>();

  // Part 1: Course Details
  final _courseCodeController = TextEditingController();
  final _courseNameController = TextEditingController();
  final _shortDescriptionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _objectiveController = TextEditingController();
  PlatformFile? _selectedImagePlatformFile;

  // Part 2: Video Lessons
  final List<Map<String, dynamic>> _videoLessons = [];

  bool _isSubmitting = false;
  double _submitProgress = 0.0;

  @override
  void dispose() {
    _courseCodeController.dispose();
    _courseNameController.dispose();
    _courseNameController.dispose();
    _shortDescriptionController.dispose();
    _descriptionController.dispose();
    _objectiveController.dispose();
    for (var lesson in _videoLessons) {
      (lesson['videoNameController'] as TextEditingController).dispose();
      (lesson['videoDescriptionController'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  // สำหรับ _pickImage()
Future<void> _pickImage() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.image,
  );

  // การตรวจสอบที่ถูกต้องและปลอดภัย
  if (result != null && result.files.isNotEmpty) {
    setState(() {
      _selectedImagePlatformFile = result.files.first; // ใช้ .first แทน .single
    });
  }
}

// สำหรับ _pickFileForLesson()
Future<void> _pickFileForLesson(Map<String, dynamic> lesson, String type) async {
  FilePickerResult? result;
  if (type == 'video') {
    result = await FilePicker.platform.pickFiles(type: FileType.video);
  } else if (type == 'pdf') {
    result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
  }

  // การตรวจสอบที่ถูกต้องและปลอดภัย
  if (result != null && result.files.isNotEmpty) {
    setState(() {
      if (type == 'video') {
        lesson['videoPlatformFile'] = result!.files.first;
      } else {
        lesson['pdfPlatformFile'] = result!.files.first;
      }
    });
  }
}

  void _addVideoLesson() {
    setState(() {
      _videoLessons.add({
        'videoNameController': TextEditingController(),
        'videoDescriptionController': TextEditingController(),
        'videoPlatformFile': null,
        'pdfPlatformFile': null,
      });
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return ErrorDialogPage(message: message);
      },
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImagePlatformFile == null) {
        _showErrorDialog('กรุณาเลือกไฟล์รูปภาพหลักสูตร');
        return;
      }
      
      if (_videoLessons.isEmpty) {
        _showErrorDialog('กรุณาเพิ่มวิดีโออย่างน้อย 1 ตอน');
        return;
      }

      setState(() {
        _isSubmitting = true;
        _submitProgress = 0.0;
      });

      final userId = widget.userId;

      var uri = Uri.parse('http://localhost:3006/api/courses');
      var request = http.MultipartRequest('POST', uri);

      // Part 1: Course Details
      request.fields['course_code'] = _courseCodeController.text;
      request.fields['course_name'] = _courseNameController.text;
      request.fields['short_description'] = _shortDescriptionController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['objective'] = _objectiveController.text;
      request.fields['user_id'] = userId;

      // Correctly handle image file based on platform
      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'name_image',
          _selectedImagePlatformFile!.bytes!,
          filename: _selectedImagePlatformFile!.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'name_image',
          _selectedImagePlatformFile!.path!,
          filename: _selectedImagePlatformFile!.name,
        ));
      }

      // Part 2: Video Lessons
      for (int i = 0; i < _videoLessons.length; i++) {
        final lesson = _videoLessons[i];
        final videoFile = lesson['videoPlatformFile'] as PlatformFile?;
        final pdfFile = lesson['pdfPlatformFile'] as PlatformFile?;

        request.fields['video_name_$i'] = (lesson['videoNameController'] as TextEditingController).text;
        request.fields['video_description_$i'] = (lesson['videoDescriptionController'] as TextEditingController).text;

        // Correctly handle video file based on platform
        if (videoFile != null) {
          if (kIsWeb) {
            request.files.add(http.MultipartFile.fromBytes(
              'name_vdo_$i',
              videoFile.bytes!,
              filename: videoFile.name,
            ));
          } else {
            request.files.add(await http.MultipartFile.fromPath(
              'name_vdo_$i',
              videoFile.path!,
              filename: videoFile.name,
            ));
          }
        }

        // Correctly handle PDF file based on platform
        if (pdfFile != null) {
          if (kIsWeb) {
            request.files.add(http.MultipartFile.fromBytes(
              'name_file_$i',
              pdfFile.bytes!,
              filename: pdfFile.name,
            ));
          } else {
            request.files.add(await http.MultipartFile.fromPath(
              'name_file_$i',
              pdfFile.path!,
              filename: pdfFile.name,
            ));
          }
        }
      }

      try {
        final http.StreamedResponse response = await request.send();
        
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          setState(() {
            _submitProgress += 0.05;
            if (_submitProgress >= 1.0) {
              _submitProgress = 1.0;
              timer.cancel();
            }
          });
        });

        final responseBody = await response.stream.bytesToString();
        
        if (response.statusCode == 201) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('สำเร็จ'),
                content: const Text('ส่งข้อมูลและอัปโหลดไฟล์สำเร็จ!'),
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
          ).then((_) {
            _courseCodeController.clear();
            _courseNameController.clear();
            _shortDescriptionController.clear();
            _descriptionController.clear();
            _objectiveController.clear();
            setState(() {
              _selectedImagePlatformFile = null;
              _videoLessons.clear();
            });
            // Navigating to a new instance of the page to reset the form completely
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UploadCoursePage(
                  userName: widget.userName,
                  userId: widget.userId,
                ),
              ),
            );
          });
        } else {
          final responseData = json.decode(responseBody);
          final errorMessage = responseData['message'] ?? 'ไม่ทราบข้อผิดพลาด';
          _showErrorDialog(errorMessage);
        }
      } catch (e) {
        _showErrorDialog('เกิดข้อผิดพลาดในการส่งข้อมูล: $e');
      } finally {
        setState(() {
          _isSubmitting = false;
          _submitProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NavbarProcessorPage(userName: widget.userName, userId: widget.userId),
      drawer: DrawerProcessorPage(userName: widget.userName, userId: widget.userId),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(32.0),
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.upload_file, size: 48, color: Colors.black54),
                      const SizedBox(height: 8),
                      const Text(
                        'อัปโหลดหลักสูตร',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // --- Part 1: Course Details ---
                _buildSectionTitle('1. เนื้อหาหลักสูตร'),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _courseCodeController,
                  label: 'รหัสวิชา',
                  validator: (value) => value!.isEmpty ? 'กรุณาใส่รหัสวิชา' : null,
                  maxLength: 8,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _courseNameController,
                  label: 'หัวข้อเรื่อง',
                  validator: (value) => value!.isEmpty ? 'กรุณาใส่หัวข้อเรื่อง' : null,
                ),
                const SizedBox(height: 16),
                _buildSingleLineTextField(
                  controller: _shortDescriptionController,
                  label: 'รายละเอียด (สั้นๆ)',
                  validator: (value) => value!.isEmpty ? 'กรุณาใส่รายละเอียด' : null,
                ),
                const SizedBox(height: 16),
                _buildSingleLineTextField(
                  controller: _descriptionController,
                  label: 'คำอธิบายหลักสูตร',
                  validator: (value) => value!.isEmpty ? 'กรุณาใส่คำอธิบายหลักสูตร' : null,
                ),
                const SizedBox(height: 16),
                _buildObjectiveTextField(),
                const SizedBox(height: 24),
                _buildFilePicker(
                  label: 'อัปโหลดรูปภาพ',
                  onPressed: _pickImage,
                  fileName: _selectedImagePlatformFile?.name,
                ),

                const SizedBox(height: 32),
                const Divider(color: Colors.grey),
                const SizedBox(height: 32),

                // --- Part 2: Video Lessons ---
                _buildSectionTitle('2. วิดีโอหลักสูตร'),
                const SizedBox(height: 16),
                ..._videoLessons.asMap().entries.map((entry) {
                  final index = entry.key;
                  final lesson = entry.value;
                  return _buildVideoLessonCard(lesson, index);
                }).toList(),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _addVideoLesson,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('เพิ่มวิดีโออีก', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 32),

                // --- Final Submit Button ---
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'ยืนยันการเพิ่มหลักสูตร',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          keyboardType: maxLines == 1 ? TextInputType.text : TextInputType.multiline,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.grey, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.grey, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.green, width: 2.0),
            ),
            counterText: "",
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildSingleLineTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 1,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.grey, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.grey, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.green, width: 2.0),
            ),
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
        const Text('วัตถุประสงค์ (ใส่เป็นข้อๆ)', style: TextStyle(fontWeight: FontWeight.bold)),
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
              borderSide: const BorderSide(color: Colors.grey, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.grey, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.green, width: 2.0),
            ),
            hintText: 'เช่น เรียนรู้พื้นฐานการเขียนโปรแกรม  - สามารถสร้างแอปพลิเคชันง่ายๆ ได้',
          ),
          validator: (value) => value!.isEmpty ? 'กรุณาใส่วัตถุประสงค์' : null,
        ),
      ],
    );
  }

  Widget _buildFilePicker({
    required String label,
    required VoidCallback onPressed,
    String? fileName,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
                    style: TextStyle(color: fileName != null ? Colors.black : Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : onPressed,
                icon: const Icon(Icons.upload, color: Colors.white),
                label: const Text('อัปโหลด', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8.0),
                      bottomRight: Radius.circular(8.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoLessonCard(Map<String, dynamic> lesson, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'วิดีโอตอนที่ ${index + 1}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: lesson['videoNameController'],
              label: 'ชื่อคลิป',
              validator: (value) => value!.isEmpty ? 'กรุณาใส่ชื่อคลิป' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: lesson['videoDescriptionController'],
              label: 'รายละเอียดสั้นๆ',
              maxLines: 2,
              validator: (value) => value!.isEmpty ? 'กรุณาใส่รายละเอียด' : null,
            ),
            const SizedBox(height: 16),
            _buildFilePicker(
              label: 'ไฟล์การเรียนการสอน (PDF)',
              onPressed: () => _pickFileForLesson(lesson, 'pdf'),
              fileName: (lesson['pdfPlatformFile'] as PlatformFile?)?.name,
            ),
            const SizedBox(height: 16),
            _buildFilePicker(
              label: 'ไฟล์วิดีโอ',
              onPressed: () => _pickFileForLesson(lesson, 'video'),
              fileName: (lesson['videoPlatformFile'] as PlatformFile?)?.name,
            ),
          ],
        ),
      ),
    );
  }
}
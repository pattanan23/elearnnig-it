import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:async';
import 'dart:convert'; // เพิ่ม import นี้
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:e_learning_it/professor/drawer_processor.dart';
import 'package:e_learning_it/professor/navbar_professor.dart';
import 'package:e_learning_it/error_dialog_page.dart';

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
  PlatformFile? _selectedVideoPlatformFile;
  PlatformFile? _selectedPdfPlatformFile;

  bool _isSubmitting = false;
  double _submitProgress = 0.0;

  @override
  void dispose() {
    _courseCodeController.dispose();
    _courseNameController.dispose();
    _shortDescriptionController.dispose();
    _descriptionController.dispose();
    _objectiveController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedImagePlatformFile = result.files.single;
      });
    }
  }

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedVideoPlatformFile = result.files.single;
      });
    }
  }

  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedPdfPlatformFile = result.files.single;
      });
    }
  }

  // ฟังก์ชันสำหรับแสดง ErrorDialog
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
      if (_selectedImagePlatformFile == null &&
          _selectedVideoPlatformFile == null &&
          _selectedPdfPlatformFile == null) {
        _showErrorDialog(
            'กรุณาเลือกไฟล์รูปภาพ วิดีโอ หรือ PDF อย่างน้อย 1 ไฟล์');
        return;
      }

      setState(() {
        _isSubmitting = true;
        _submitProgress = 0.0;
      });

      final userId = widget.userId;

      var uri = Uri.parse('http://localhost:3006/api/courses');
      var request = http.MultipartRequest('POST', uri);

      request.fields['course_code'] = _courseCodeController.text;
      request.fields['course_name'] = _courseNameController.text;
      request.fields['short_description'] = _shortDescriptionController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['objective'] = _objectiveController.text;
      request.fields['user_id'] = userId;

      if (_selectedImagePlatformFile != null) {
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
      }

      if (_selectedVideoPlatformFile != null) {
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
            'name_vdo',
            _selectedVideoPlatformFile!.bytes!,
            filename: _selectedVideoPlatformFile!.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'name_vdo',
            _selectedVideoPlatformFile!.path!,
            filename: _selectedVideoPlatformFile!.name,
          ));
        }
      }

      if (_selectedPdfPlatformFile != null) {
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
            'name_file',
            _selectedPdfPlatformFile!.bytes!,
            filename: _selectedPdfPlatformFile!.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'name_file',
            _selectedPdfPlatformFile!.path!,
            filename: _selectedPdfPlatformFile!.name,
          ));
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
        
        // แก้ไขส่วนนี้
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
              _selectedVideoPlatformFile = null;
              _selectedPdfPlatformFile = null;
            });

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

  // ... (โค้ดส่วนอื่น ๆ ที่คุณมีอยู่)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          NavbarProcessorPage(userName: widget.userName, userId: widget.userId),
      drawer:
          DrawerProcessorPage(userName: widget.userName, userId: widget.userId),
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
                      const Icon(Icons.upload_file,
                          size: 48, color: Colors.black54),
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
                _buildTextField(
                  controller: _courseCodeController,
                  label: 'รหัสวิชา',
                  validator: (value) =>
                      value!.isEmpty ? 'กรุณาใส่รหัสวิชา' : null,
                  maxLength: 8,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _courseNameController,
                  label: 'หัวข้อเรื่อง',
                  validator: (value) =>
                      value!.isEmpty ? 'กรุณาใส่หัวข้อเรื่อง' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _shortDescriptionController,
                  label: 'รายละเอียด (สั้นๆ)',
                  maxLines: 3,
                  validator: (value) =>
                      value!.isEmpty ? 'กรุณาใส่รายละเอียด' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'คำอธิบายหลักสูตร',
                  maxLines: 3,
                  validator: (value) =>
                      value!.isEmpty ? 'กรุณาใส่คำอธิบายหลักสูตร' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _objectiveController,
                  label: 'วัตถุประสงค์',
                  maxLines: 3,
                  validator: (value) =>
                      value!.isEmpty ? 'กรุณาใส่วัตถุประสงค์' : null,
                ),
                const SizedBox(height: 24),
                _buildFilePicker(
                  label: 'อัปโหลดรูปภาพ',
                  onPressed: _pickImage,
                  fileName: _selectedImagePlatformFile?.name,
                ),
                const SizedBox(height: 16),
                _buildFilePicker(
                  label: 'อัปโหลดไฟล์การเรียนการสอน (PDF)',
                  onPressed: _pickPdf,
                  fileName: _selectedPdfPlatformFile?.name,
                ),
                const SizedBox(height: 16),
                _buildFilePicker(
                  label: 'อัปโหลดวิดีโอการสอน',
                  onPressed: _pickVideo,
                  fileName: _selectedVideoPlatformFile?.name,
                ),
                const SizedBox(height: 32),
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'ยืนยันข้อมูล',
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

  // ... (โค้ด widget อื่น ๆ ที่เหมือนเดิม)

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
                    style: TextStyle(
                        color: fileName != null ? Colors.black : Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : onPressed,
                icon: const Icon(Icons.upload, color: Colors.white),
                label: const Text('อัปโหลด',
                    style: TextStyle(color: Colors.white)),
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
}
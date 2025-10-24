import 'package:flutter/material.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // กำหนดสีและรูปแบบพื้นหลังของ Footer
    // ใช้สีเทาอ่อนตามรูปภาพที่ผู้ใช้ส่งมา
    const Color footerBackgroundColor = Color.fromRGBO(214, 214, 214, 1.0); 
    const Color footerDetailColor = Color.fromRGBO(96, 96, 96, 1.0); 

    return LayoutBuilder(
      builder: (context, constraints) {
        // ตรวจสอบความกว้างของหน้าจอเพื่อกำหนดรูปแบบการแสดงผล
        final isLargeScreen = constraints.maxWidth > 800;
        final double sectionSpacing = isLargeScreen ? 100.0 : 30.0;
        
        // กำหนด Padding ภายใน (Inner Padding) ให้กับ Footer
        final double paddingValue = isLargeScreen ? 60.0 : 20.0;

        return Container(
          width: double.infinity, // ทำให้ Container ขยายเต็มความกว้าง
          color: footerBackgroundColor,
          padding: EdgeInsets.symmetric(horizontal: paddingValue, vertical: 40.0),
          child: isLargeScreen
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ส่วนที่ 1: ช่องทางการติดต่อ
                    Expanded(child: _buildContactSection()),
                    SizedBox(width: sectionSpacing),
                    // ส่วนที่ 2: สถานที่ติดต่อ
                    Expanded(child: _buildLocationSection()),
                    SizedBox(width: sectionSpacing),
                    // ส่วนที่ 3: สถานที่ติดต่อเพิ่มเติม
                    Expanded(child: _buildAdditionalContactSection()),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // แสดงในรูปแบบ Column เมื่อหน้าจอเล็ก
                    _buildContactSection(),
                    const SizedBox(height: 40),
                    _buildLocationSection(),
                    const SizedBox(height: 40),
                    _buildAdditionalContactSection(),
                  ],
                ),
        );
      },
    );
  }

  // Helper Widget สำหรับส่วน "ช่องทางการติดต่อ"
  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle('ช่องทางการติดต่อ'),
        const SizedBox(height: 16),
        _buildContactItem(
          icon: Icons.facebook,
          text: 'สาขาวิชาเทคโนโลยีสารสนเทศ มหาวิทยาลัยเกษตรศาสตร์',
        ),
        _buildContactItem(
          icon: Icons.language,
          text: 'https://it.flas.kps.ku.ac.th/',
        ),
        _buildContactItem(
          icon: Icons.email,
          text: 'itkukps@gmail.com',
        ),
      ],
    );
  }

  // Helper Widget สำหรับส่วน "สถานที่ติดต่อ"
  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle('สถานที่ติดต่อ'),
        const SizedBox(height: 16),
        _buildTextDetail(
          'ภาควิชาภาษาตะวันออกและเทคโนโลยีสารสนเทศดิจิทัล ' +
          'สาขาวิชาเทคโนโลยีสารสนเทศและการสื่อสาร ' +
          'หลักสูตรวิทยาศาสตรบัณฑิต สาขาวิชาเทคโนโลยีสารสนเทศ',
        ),
        _buildTextDetail(
          'เลขที่ 1 หมู่ 6 ต.กำแพงแสน อ.กำแพงแสน จ.นครปฐม 73140',
        ),
        const SizedBox(height: 12),
        _buildTextDetail('โทรศัพท์ : 034-352360'),
      ],
    );
  }

  // Helper Widget สำหรับส่วน "สถานที่ติดต่อเพิ่มเติม"
  Widget _buildAdditionalContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle('สถานที่ติดต่อเพิ่มเติม'),
        const SizedBox(height: 16),
        _buildTextDetail('กองบริหารวิชาการและนิสิต'),
        _buildTextDetail('โทรศัพท์ : 0 3434 1545-7 Fax 0 3435 1395'),
        _buildTextDetail('line id : @vvp8070s'),
        _buildTextDetail('แจ้งเหตุฉุกเฉิน โทร 0 3435 1151 ภายใน 3191'),
      ],
    );
  }

  // Helper Widget สำหรับหัวข้อ
  Widget _buildTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  // Helper Widget สำหรับรายละเอียดข้อความ
  Widget _buildTextDetail(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Color.fromRGBO(96, 96, 96, 1.0),
          height: 1.5,
        ),
      ),
    );
  }

  // Helper Widget สำหรับรายการติดต่อที่มีไอคอน
  Widget _buildContactItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.black54, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color.fromRGBO(96, 96, 96, 1.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

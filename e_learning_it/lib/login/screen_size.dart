import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget registrationForm;

  const ResponsiveLayout({
    Key? key,
    required this.registrationForm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    const double mobileBreakpoint = 600;

    if (screenWidth >= mobileBreakpoint) {
      return _buildDesktopTabletLayout();
    } else {
      return _buildMobileLayout();
    }
  }
  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/logo3.png',
          height: 150,
          width: 150,
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: registrationForm,
        ),
      ],
    );
  }

  Widget _buildDesktopTabletLayout() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(right: 50.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
               mainAxisAlignment: MainAxisAlignment.center,
              children: [
                
                Center(
                  child: Image.asset(
                    'assets/images/logo3.png',
                    height: 200,
                    width: 200,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 450,
          child: registrationForm,
        ),
      ],
    );
  }
}

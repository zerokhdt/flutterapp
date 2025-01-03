import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test_application/Predict.dart';
import 'display_info_page.dart';
import 'pks.dart';
import 'MapPage.dart'; // Import HelpScreen

class PageScreen extends StatefulWidget {
  final String userId;

  PageScreen({required this.userId});

  @override
  _PageScreenState createState() => _PageScreenState();
}

class _PageScreenState extends State<PageScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<String> _imagePaths = [
    'assets/back1.jpg',
    'assets/back2.jpg',
    'assets/back3.jpg',
    'assets/back4.png',
    'assets/back5.jpg',
  ];

  final List<ButtonData> _buttons = [
    ButtonData(
      label: 'Thu thập thông tin',
      iconPath: 'assets/collect.png',
      action: (context, userId) => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => PksListPage(userId: userId)),
      ),
    ),
    ButtonData(
      label: 'Kết quả khảo sát',
      iconPath: 'assets/display.png',
      action: (context, userId) => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => DisplayInfoPage(userId: userId)),
      ),
    ),
    ButtonData(
      label: 'Bản đồ dịch bệnh',
      iconPath: 'assets/map.png',
      action: (context, userId) => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => MapScreen()),
      ),
    ),
    ButtonData(
      label: 'Dự đoán bệnh',
      iconPath: 'assets/hientrang.png',
      action: (context, userId) => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => PredictPage(userId: userId)),
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
      if (_currentPage < _imagePaths.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);

    List<String> weekdaysInVietnamese = [
      'Chủ Nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'
    ];
    String weekday = weekdaysInVietnamese[now.weekday % 7];

    return Scaffold(
      appBar: AppBar(
        title: Text('Trang chủ'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 250,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _imagePaths.length,
                    itemBuilder: (context, index) {
                      return Image.asset(
                        _imagePaths[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$weekday',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Ngày: $formattedDate',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                alignment: WrapAlignment.start,
                spacing: 10,
                runSpacing: 10,
                children: _buttons.map((button) {
                  return InkWell(
                    onTap: () => button.action(context, widget.userId),
                    borderRadius: BorderRadius.circular(16.0),
                    child: Container(
                      width: MediaQuery.of(context).size.width / 3 - 20,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(2, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 80,
                            child: Image.asset(
                              button.iconPath,
                              fit: BoxFit.contain,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            button.label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ButtonData {
  final String label;
  final String iconPath;
  final Function(BuildContext, String) action;

  ButtonData({
    required this.label,
    required this.iconPath,
    required this.action,
  });
}

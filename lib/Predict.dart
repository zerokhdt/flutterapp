import 'package:flutter/material.dart';
import 'package:test_application/Situation.dart';
import 'package:test_application/resultlist.dart';
import 'display_info_page.dart';
import 'pks.dart';

class PredictPage extends StatefulWidget {
  final String userId;

  PredictPage({required this.userId});

  @override
  _PredictPageState createState() => _PredictPageState();
}

class _PredictPageState extends State<PredictPage> {

  @override
  Widget build(BuildContext context) {
    final List<ButtonData> _buttons = [
      ButtonData(
        label: 'Tình trạng trang trại',
        iconPath: 'assets/collect.png',
        action: (context, userId) => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => SituationPage(userId: userId)),
        ),
      ),
      ButtonData(
        label: 'Kết quả dự đoán',
        iconPath: 'assets/display.png',
        action: (context, userId) => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => ResultListPage(userId: userId)),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Trang dự đoán'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
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
                width: MediaQuery.of(context).size.width / 2 - 24,
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

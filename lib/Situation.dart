import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SituationPage extends StatefulWidget {
  final String userId;

  SituationPage({required this.userId});
  @override
  _SituationPageState createState() => _SituationPageState();
}

class _SituationPageState extends State<SituationPage> {
  List<dynamic> _questions = [];  // Danh sách các câu hỏi từ API
  Map<String, List<String>> _groupedAnswers = {}; // Lưu các lựa chọn cho mỗi câu hỏi
  Map<String, String?> _selectedAnswers = {}; // Lưu câu trả lời đã chọn cho mỗi câu hỏi

  // Tải các câu hỏi từ API
  Future<void> _loadQuestions() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.5:3000/api/situation'));

      if (response.statusCode == 200) {
        setState(() {
          _questions = json.decode(response.body);

          // Nhóm các câu hỏi theo 'IndexST'
          _groupedAnswers = {};
          for (var question in _questions) {
            String indexST = question['IndexST'].toString();
            if (!_groupedAnswers.containsKey(indexST)) {
              _groupedAnswers[indexST] = [];
            }
            _groupedAnswers[indexST]!.add(question['PurportST'].toString());
          }

          // Lưu câu trả lời ban đầu (mặc định chưa chọn gì)
          _selectedAnswers = {};
          _groupedAnswers.forEach((key, values) {
            _selectedAnswers[key] = null; // Mặc định chưa có câu trả lời
          });
        });
      } else {
        throw Exception('Không tải được câu hỏi');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi tải câu hỏi: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  // Cập nhật câu trả lời đã chọn cho câu hỏi
  void _onAnswerChanged(String question, String? value) {
    setState(() {
      _selectedAnswers[question] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tình trạng đàn heo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Hiển thị danh sách các câu hỏi và lựa chọn của chúng
            Expanded(
              child: ListView.builder(
                itemCount: _groupedAnswers.length,
                itemBuilder: (context, index) {
                  String question = _groupedAnswers.keys.elementAt(index);
                  List<String> options = _groupedAnswers[question]!;
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 10.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: BorderSide(color: Colors.blueAccent, width: 1),
                    ),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question,  // Tên câu hỏi từ 'IndexST'
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          Text('Chọn một trong các lựa chọn dưới đây:'),
                          // Xây dựng các lựa chọn radio button dựa trên 'PurportST'
                          _buildOptions(question, options),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Xây dựng các lựa chọn radio button dựa trên 'PurportST'
  Widget _buildOptions(String question, List<String> options) {
    return Column(
      children: options.map((option) {
        return RadioListTile<String>(
          title: Text(option.trim()),  // Hiển thị mỗi lựa chọn
          value: option.trim(),
          groupValue: _selectedAnswers[question],
          onChanged: (value) => _onAnswerChanged(question, value),
        );
      }).toList(),
    );
  }
}

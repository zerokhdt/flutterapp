import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReviewAnswersPage extends StatefulWidget {
  final String pksId;
  final String userId;
  final String Dates;

  ReviewAnswersPage({required this.pksId, required this.userId,required this.Dates});

  @override
  _ReviewAnswersPageState createState() => _ReviewAnswersPageState();
}

class _ReviewAnswersPageState extends State<ReviewAnswersPage> {
  List<dynamic> _questionsAndAnswers = [];

  Future<void> _loadQuestionsAndAnswers() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/reviewanswers/${widget.userId}/${widget.pksId}/${widget.Dates}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _questionsAndAnswers = json.decode(response.body);
        });
      } else {
        throw Exception('Không tải được câu hỏi và câu trả lời');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadQuestionsAndAnswers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kết quả khảo sát'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _questionsAndAnswers.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: _questionsAndAnswers.length,
          itemBuilder: (context, index) {
            final question = _questionsAndAnswers[index];
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
                      _getQuestionText(question['PurportQT']),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Câu trả lời: ${question['PurportAS']}',
                      style: TextStyle(fontSize: 16, color: Colors.green),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getQuestionText(String questionContent) {
    List<String> parts = questionContent.split('&');
    return parts[0].trim();
  }
}

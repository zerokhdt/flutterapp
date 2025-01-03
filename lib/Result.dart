import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ResultsPage extends StatefulWidget {
  final String userId;
  final int timereply;  // Use Timereply instead of Dates

  ResultsPage({required this.userId, required this.timereply});

  @override
  _ResultsPageState createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  List<dynamic> _questionsAndAnswers = [];

  Future<void> _loadQuestionsAndAnswers() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.2:3000/api/results/${widget.userId}/${widget.timereply}'),
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
        child: Column(
          children: [
            SizedBox(height: 20),
            Expanded(
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
                            _getQuestionText(question['PurportTCT']),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Câu trả lời: ${question['PurportCT']}',
                            style: TextStyle(fontSize: 16, color: Colors.green),
                          ),
                          SizedBox(height: 10), // Add space between the two texts
                          Text(
                            'Điểm: ${question['Factor']}', // Display the Factor value
                            style: TextStyle(fontSize: 16, color: Colors.blue),
                          ),
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

  String _getQuestionText(String questionContent) {
    List<String> parts = questionContent.split('&');
    return parts[0].trim();
  }
}

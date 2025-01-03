import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReviewAnswersPage extends StatefulWidget {
  final String pksId;
  final String userId;
  final String Dates;

  ReviewAnswersPage({required this.pksId, required this.userId, required this.Dates});

  @override
  _ReviewAnswersPageState createState() => _ReviewAnswersPageState();
}

class _ReviewAnswersPageState extends State<ReviewAnswersPage> {
  List<dynamic> _questionsAndAnswers = [];
  String surveyName = 'Tên phiếu khảo sát'; // Placeholder for the survey name

  Future<void> _loadQuestionsAndAnswers() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.2:3000/api/reviewanswers/${widget.userId}/${widget.pksId}/${widget.Dates}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _questionsAndAnswers = json.decode(response.body);
          surveyName = _questionsAndAnswers.isNotEmpty ? _questionsAndAnswers[0]['Name'] : surveyName;
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

  Future<void> deleteAnswers() async {
    try {
      final response = await http.delete(
        Uri.parse('http://192.168.1.2:3000/api/deleteanswers/${widget.userId}/${widget.Dates}'),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa câu trả lời thành công')),
        );
        Navigator.pop(context,true);
      } else {
        throw Exception('Xóa câu trả lời bị lỗi');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa câu trả lời: $e')),
      );
    }
  }

  Future<void> setPriority() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.2:3000/api/setpriority/${widget.userId}/${widget.pksId}/${widget.Dates}'),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã đặt ưu tiên cho phiếu trả lời này')),
        );
      } else {
        throw Exception('Đặt ưu tiên bị lỗi');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi đặt ưu tiên: $e')),
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
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  surveyName,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: deleteAnswers,
                      icon: Icon(Icons.delete, color: Colors.red),
                      label: Text('Xóa câu trả lời'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: setPriority,
                      icon: Icon(Icons.star, color: Colors.white),
                      label: Text('Đặt ưu tiên'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 40), // Increase this value for more spacing between title/buttons and answers
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

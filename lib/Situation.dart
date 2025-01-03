import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class SituationPage extends StatefulWidget {
  final String userId;

  SituationPage({required this.userId});

  @override
  _SituationPageState createState() => _SituationPageState();
}

class _SituationPageState extends State<SituationPage> {
  List<dynamic> _questions = [];
  Map<String, List<Map<String, dynamic>>> _groupedAnswers = {}; // Lưu các lựa chọn cùng với Factor
  Map<String, Map<String, dynamic>?> _selectedAnswers = {}; // Lưu câu trả lời đã chọn cùng với Factor

  // Tải các câu hỏi từ API
  Future<void> _loadQuestions() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.2:3000/api/situation'));

      if (response.statusCode == 200) {
        setState(() {
          _questions = json.decode(response.body);

          // Nhóm các câu hỏi theo 'PurportTCT'
          _groupedAnswers = {};
          for (var question in _questions) {
            String PurportTCT = question['PurportTCT'].toString();
            if (!_groupedAnswers.containsKey(PurportTCT)) {
              _groupedAnswers[PurportTCT] = [];
            }
            _groupedAnswers[PurportTCT]!.add({
              'CriteriaID': question['CriteriaID'].toString(),
              'text': question['PurportCT'].toString(),
              'factor': question['Factor'] ?? 0, // Lấy giá trị Factor
            });
          }

          // Khởi tạo câu trả lời ban đầu
          _selectedAnswers = {};
          _groupedAnswers.forEach((key, _) {
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

  // Xử lý khi câu trả lời thay đổi
  void _onAnswerChanged(String question, Map<String, dynamic>? answer) {
    setState(() {
      _selectedAnswers[question] = answer;
    });
  }

  // Hàm kiểm tra xem bản ghi có tồn tại hay không
  Future<int> _getCurrentPredictCount() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.2:3000/api/get-predict-count'));

      if (response.statusCode == 200) {
        return json.decode(response.body)['count']; // Số dòng trong bảng
      } else {
        throw Exception('Không thể lấy số dòng hiện tại.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi lấy số dòng: $e')));
      return 0; // Trả về 0 nếu có lỗi
    }
  }

// Hàm lưu dữ liệu vào cơ sở dữ liệu
  Future<void> _savePrediction(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.2:3000/api/save-predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi lưu dự đoán: $e')));
    }
  }

  // Hàm xử lý logic khi nhấn nút dự đoán
  void _onPredict() async {
    // Kiểm tra xem đã trả lời hết chưa
    if (_selectedAnswers.values.contains(null)) {
      _showMessageDialog(
        context,
        'Cảnh báo',
        'Vui lòng trả lời hết tất cả các câu hỏi trước khi dự đoán!',
      );
      return;
    }

    // Lấy số dòng hiện tại trong bảng
    int currentCount = await _getCurrentPredictCount();
    int time = (currentCount / 11).ceil() + 1;

    // Tạo danh sách các record cho mỗi câu trả lời
    List<Map<String, dynamic>> predictionDataList = [];

    _selectedAnswers.forEach((question, answer) {
      if (answer != null) {
        // Tạo UUID cho mỗi câu trả lời
        var uuid = Uuid();
        String predictId = uuid.v4();  // Tạo một PredictID duy nhất cho mỗi câu trả lời

        // Tạo một record cho mỗi câu trả lời
        Map<String, dynamic> predictionData = {
          'PredictID': predictId,  // UUID duy nhất cho mỗi câu trả lời
          'NameKS':'Tình trạng trang trại',
          'CriteriaID': answer['CriteriaID'],  // ID câu hỏi (question)
          'Pointreply': answer['factor'],  // Factor của câu trả lời
          'Timereply': time,  // Số dòng hiện tại trong bảng (hoặc có thể thay bằng thời gian)
          'UserID': widget.userId,  // ID người dùng
        };

        // Thêm record vào danh sách
        predictionDataList.add(predictionData);
      }
    });

    // Lưu tất cả các record vào cơ sở dữ liệu
    for (var data in predictionDataList) {
      await _savePrediction(data);  // Giả sử hàm _savePrediction có thể xử lý từng record
    }

    // Hiển thị kết quả
    double totalFactor = predictionDataList.fold(0.0, (sum, data) => sum + (data['Pointreply'] as num).toDouble());

    if (totalFactor > 5) {
      _showMessageDialog(
        context,
        'Kết quả dự đoán',
        'Đàn heo có nguy cơ bị dịch tả lợn châu Phi!',
      );
    } else {
      _showMessageDialog(
        context,
        'Kết quả dự đoán',
        'Đàn heo an toàn.',
      );
    }
  }

// Hàm hiển thị thông báo ở giữa màn hình
  void _showMessageDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Text(
            message,
            style: TextStyle(fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
              },
              child: Text(
                'Đóng',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tình trạng đàn heo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _groupedAnswers.length,
                itemBuilder: (context, index) {
                  String question = _groupedAnswers.keys.elementAt(index);
                  List<Map<String, dynamic>> options = _groupedAnswers[question]!;
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
                            question,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          Text('Chọn một trong các lựa chọn dưới đây:'),
                          _buildOptions(question, options),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _onPredict,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: Text(
                'Dự đoán',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Xây dựng danh sách lựa chọn
  Widget _buildOptions(String question, List<Map<String, dynamic>> options) {
    return Column(
      children: options.map((option) {
        return RadioListTile<Map<String, dynamic>>(
          title: Text(option['text']),
          value: option,
          groupValue: _selectedAnswers[question],
          onChanged: (value) => _onAnswerChanged(question, value),
        );
      }).toList(),
    );
  }
}

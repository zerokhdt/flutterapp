import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class QuestionPage extends StatefulWidget {
  final String pksId;
  final String userId;

  QuestionPage({required this.pksId, required this.userId});
  @override
  _QuestionPageState createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  List<dynamic> _questions = [];
  List<Map<String, String>> _answers = [];
  List<List<TextEditingController>> _controllers = [];
  List<List<dynamic>> _groupedQuestions = [];
  int _currentGroupIndex = 0;
  Map<int, List<Map<String, String>>> _groupedAnswers = {};

  final Uuid _uuid = Uuid();

  Future<void> _loadQuestions() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.5:3000/api/questions/${widget.pksId}'));
      if (response.statusCode == 200) {
        setState(() {
          _questions = json.decode(response.body);

          // Nhóm câu hỏi theo IsIndex
          _groupedQuestions = [];
          Map<String, List<dynamic>> tempGroups = {};

          for (var question in _questions) {
            String isIndex = question['IsIndex'].toString();
            if (!tempGroups.containsKey(isIndex)) {
              tempGroups[isIndex] = [];
            }
            tempGroups[isIndex]!.add(question);
          }

          // Chuyển đổi map thành list
          _groupedQuestions = tempGroups.values.toList();

          if (_answers.isEmpty) {
            _answers = _groupedQuestions[_currentGroupIndex].map((question) {
              return {
                'AnswerID': _uuid.v4(),
                'PurportAS': '',
                'QuestionID': question['QuestionID'].toString(),
                'UserID': widget.userId,
                'Dates': DateTime.now().toIso8601String().toString(),
              };
            }).toList();
          }
          _controllers = List.generate(_groupedQuestions[_currentGroupIndex].length, (index) {
            return [TextEditingController()];
          });
        });
      } else {
        throw Exception('Lỗi không thể tải câu hỏi');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải câu hỏi: $e')));
    }
  }

  Future<int> _getResultCount() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.5:3000/api/checkresult/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final dynamic result = json.decode(response.body);

        if (result is List && result.isNotEmpty && result[0] is Map<String, dynamic> && result[0].containsKey('DistinctCount')) {
          // Attempt to parse DistinctCount safely
          int distinctCount = (result[0]['DistinctCount'] is int)
              ? result[0]['DistinctCount']
              : (result[0]['DistinctCount'] is String)
              ? int.tryParse(result[0]['DistinctCount']) ?? 0
              : 0;

          return distinctCount; // Return the count
        } else {
          throw Exception('Dữ liệu không hợp lệ: Không có khóa DistinctCount');
        }
      } else {
        throw Exception('Lỗi không thể tải số lượng kết quả: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e'); // Log the error for debugging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải số lượng kết quả: $e')),
      );
      return 0; // Return 0 if there is an error
    }
  }

  Future<void> _saveAllAnswers() async {
    // Tạo danh sách để lưu tất cả câu trả lời từ tất cả các nhóm
    List<Map<String, String>> allAnswers = [];
    String currentDate = DateTime.now().toIso8601String();


    // Duyệt qua tất cả các nhóm và thêm câu trả lời của mỗi nhóm vào danh sách `allAnswers`
    for (var groupAnswers in _groupedAnswers.values) {
      for (var answer in groupAnswers) {
        answer['Dates'] = currentDate;
        allAnswers.add(answer);
      }
    }

    final resultCount = await _getResultCount();

    // Kiểm tra xem tổng số câu trả lời không vượt quá 5
    if (resultCount >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bạn đã lưu đủ 5 câu trả lời. Không thể lưu thêm.')),
      );
      return; // Thoát phương thức để ngăn việc lưu thêm
    }

    // Kiểm tra các câu trả lời có được điền đầy đủ không
    for (var answer in allAnswers) {
      if (answer['PurportAS']!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vui lòng điền đầy đủ câu trả lời trước khi lưu.')),
        );
        return;
      }
    }

    // Gửi tất cả câu trả lời trong một yêu cầu POST duy nhất
    try {
      for (var answer in allAnswers) {
        final postResponse = await http.post(
          Uri.parse('http://192.168.1.5:3000/api/answers'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(answer), // Gửi tất cả câu trả lời cùng một lúc
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lưu tất cả câu trả lời thành công!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xảy ra lỗi: $e')));
    }
  }

  void _loadAnswersForCurrentGroup() {
    if (_groupedAnswers[_currentGroupIndex] == null) {
      // Khởi tạo câu trả lời cho nhóm hiện tại nếu chưa có
      _groupedAnswers[_currentGroupIndex] = _groupedQuestions[_currentGroupIndex].map((question) {
        return {
          'AnswerID': _uuid.v4(),
          'PurportAS': '',
          'QuestionID': question['QuestionID'].toString(),
          'UserID': widget.userId,
        };
      }).toList();
    }

    // Cập nhật `_answers` và `TextEditingController` từ nhóm hiện tại
    _answers = _groupedAnswers[_currentGroupIndex]!;
    _controllers = List.generate(_answers.length, (index) {
      var controller = TextEditingController(text: _answers[index]['PurportAS']);
      return [controller];
    });
  }

// Khi chuyển nhóm, lưu lại kết quả vào `_groupedAnswers`
  void _goToPreviousGroup() {
    _groupedAnswers[_currentGroupIndex] = List.from(_answers); // Lưu câu trả lời vào nhóm hiện tại
    if (_currentGroupIndex > 0) {
      setState(() {
        _currentGroupIndex--;
        _loadAnswersForCurrentGroup();
      });
    }
  }

  void _goToNextGroup() {
    _groupedAnswers[_currentGroupIndex] = List.from(_answers); // Lưu câu trả lời vào nhóm hiện tại
    if (_currentGroupIndex < _groupedQuestions.length - 1) {
      setState(() {
        _currentGroupIndex++;
        _loadAnswersForCurrentGroup();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Câu hỏi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_questions.isNotEmpty) // Đảm bảo danh sách không rỗng
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '${_questions[_currentGroupIndex]['IsIndex']}',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _groupedQuestions.isNotEmpty ? _groupedQuestions[_currentGroupIndex].length : 0,
                itemBuilder: (context, index) {
                  final question = _groupedQuestions[_currentGroupIndex][index];
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
                          _buildInputField(
                            question['QuestiontypeID'],
                            index,
                            question['PurportQT'],
                            question['Fileimg'],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_currentGroupIndex > 0)
                  ElevatedButton(
                    onPressed: _goToPreviousGroup,
                    child: Text('Quay lại'),
                  ),
                if (_currentGroupIndex < _groupedQuestions.length - 1)
                  ElevatedButton(
                    onPressed: _goToNextGroup,
                    child: Text('Tiếp theo'),
                  ),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveAllAnswers,
              child: Text('Lưu'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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

  List<String> _getOptions(String questionContent) {
    List<String> parts = questionContent.split('&');
    return parts.sublist(1).map((e) => e.trim()).toList();
  }

  Widget _buildInputField(String questionTypeID, int index, String questionContent, String? fileImg) {
    List<Widget> inputFields = [];

    if (fileImg != null && fileImg.isNotEmpty) {
      inputFields.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Image.network(fileImg),
        ),
      );
    }

    switch (questionTypeID) {
      case 'QST001':
        inputFields.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Nhập thông tin',
                border: OutlineInputBorder(),
              ),
              controller: _controllers[index][0],
              onChanged: (value) {
                setState(() {
                  _answers[index]['PurportAS'] = value;
                });
              },
            ),
          ),
        );
        break;

      case 'QST002':
        inputFields.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Text('Có'),
                  value: 'Có',
                  groupValue: _answers[index]['PurportAS'],
                  onChanged: (value) {
                    setState(() {
                      _answers[index]['PurportAS'] = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: Text('Không'),
                  value: 'Không',
                  groupValue: _answers[index]['PurportAS'],
                  onChanged: (value) {
                    setState(() {
                      _answers[index]['PurportAS'] = value!;
                    });
                  },
                ),
              ],
            ),
          ),
        );
        break;

      case 'QST003':
        List<String> options = _getOptions(questionContent);
        inputFields.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: options.map((option) {
                return RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: _answers[index]['PurportAS'],
                  onChanged: (value) {
                    setState(() {
                      _answers[index]['PurportAS'] = value!;
                    });
                  },
                );
              }).toList(),
            ),
          ),
        );
        break;

      case 'QST004':
        List<String> multiOptions = _getOptions(questionContent);
        inputFields.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: multiOptions.map((option) {
                return CheckboxListTile(
                  title: Text(option),
                  value: _answers[index]['PurportAS']?.contains(option) ?? false,
                  onChanged: (value) {
                    setState(() {
                      _answers[index]['PurportAS'] = _answers[index]['PurportAS'] ?? '';
                      if (value!) {
                        if (_answers[index]['PurportAS']!.isEmpty) {
                          _answers[index]['PurportAS'] = option;
                        } else {
                          _answers[index]['PurportAS'] = _answers[index]['PurportAS']! + ', $option';
                        }
                      } else {
                        _answers[index]['PurportAS'] = _answers[index]['PurportAS']!
                            .replaceAll(', $option', '')
                            .replaceAll('$option, ', '')
                            .replaceAll(option, '');
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
        );
        break;

      case 'QST005':
        inputFields.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Nhập thông tin',
                border: OutlineInputBorder(),
              ),
              controller: _controllers[index][0],
              onChanged: (value) {
                setState(() {
                  _answers[index]['PurportAS'] = _answers[index]['PurportAS'] ?? '';
                  _answers[index]['PurportAS'] = _controllers[index].map((controller) => controller.text).join('|');
                });
              },
            ),
          ),
        );

        inputFields.addAll(_controllers[index].skip(1).map((controller) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Nhập thông tin',
                border: OutlineInputBorder(),
              ),
              controller: controller,
              onChanged: (value) {
                setState(() {
                  _answers[index]['PurportAS'] = _controllers[index].map((controller) => controller.text).join('|');
                });
              },
            ),
          );
        }).toList());

        inputFields.add(
          ElevatedButton(
            onPressed: () {
              setState(() {
                _controllers[index].add(TextEditingController());
                _answers[index]['PurportAS'] = _controllers[index].map((controller) => controller.text).join('|');
              });
            },
            child: Text('Thêm dòng'),
          ),
        );
        break;

      case 'QST006':
        List<String> options = _getOptions(questionContent);

        // Thêm câu hỏi gốc vào danh sách inputFields
        inputFields.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
            Text('Con thứ 1',style: TextStyle(fontWeight: FontWeight.bold)),
                // Hiển thị danh sách các RadioListTile cho câu hỏi gốc
                ...options.map((option) {
                  return RadioListTile<String>(
                    title: Text(option),
                    value: 'Con thứ 1: '+option,
                    groupValue: _answers[index]['PurportAS'], // Đáp án cho câu hỏi gốc
                    onChanged: (value) {
                      setState(() {
                        _answers[index]['PurportAS'] = value!; // Cập nhật đáp án cho câu hỏi gốc
                      });
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );

        // Render các câu hỏi thêm phía trên nút "Thêm câu hỏi tương tự"
        for (int i = index + 1; i < _answers.length; i++) {
          List<String> addedOptions = _getOptions(questionContent);
          inputFields.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  // Hiển thị chỉ số câu hỏi
                  Text('Con thứ ${i - index +1}',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  // Các lựa chọn RadioListTile cho câu hỏi thêm
                  ...addedOptions.map((option) {
                    return RadioListTile<String>(
                      title: Text(option),
                      value: 'Con thứ ${i - index +1}: '+option,
                      groupValue: _answers[i]['PurportAS'], // Đáp án riêng biệt cho câu hỏi thêm
                      onChanged: (value) {
                        setState(() {
                          _answers[i]['PurportAS'] = value!; // Cập nhật đáp án cho câu hỏi thêm
                        });
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        }

        // Nút "Thêm câu hỏi tương tự" được thêm cuối cùng
        inputFields.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  // Lấy QuestionID và kiểm tra nếu không null
                  String questionID = _answers[index]['QuestionID'] ?? ''; // Nếu null thì gán giá trị mặc định là chuỗi rỗng

                  // Thêm câu hỏi mới với ID của câu hỏi gốc
                  _answers.add({
                    'AnswerID': _uuid.v4(),
                    'UserID': widget.userId,
                    'QuestionID': questionID, // Giữ nguyên QuestionID của câu hỏi gốc
                    'PurportAS': '', // Giá trị đáp án ban đầu của câu hỏi mới
                  });
                });
              },
              child: Text('Thêm câu hỏi tương tự'),
            ),
          ),
        );

        break;

      default:
        return Container();
    }

    return Column(children: inputFields);
  }
}

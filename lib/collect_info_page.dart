import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'MediaLoader.dart';
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

  final Uuid _uuid = Uuid();

  Future<void> _loadQuestions() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/questions/${widget.pksId}'));
      if (response.statusCode == 200) {
        setState(() {
          _questions = json.decode(response.body);

          if (_answers.isEmpty) {
            _answers = _questions.map((question) {
              return {
                'AnswerID': _uuid.v4(),
                'PurportAS': '',
                'QuestionID': question['QuestionID'].toString(),
                'UserID': widget.userId,
                'Dates': DateTime.now().toIso8601String().toString(),
              };
            }).toList();
          }
          _controllers = List.generate(_questions.length, (index) {
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

  Future<void> _saveAllAnswers() async {
    for (var answer in _answers) {
      if (answer['PurportAS']!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vui lòng điền đầy đủ câu trả lời trước khi lưu.')),
        );
        return;
      }
    }

    try {
      for (var answer in _answers) {
        final postResponse = await http.post(
          Uri.parse('http://localhost:3000/api/answers'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(answer),
        );

        if (postResponse.statusCode != 201) {
          throw Exception('Lỗi lưu câu trả lời: ${answer['QuestionID']}');
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lưu câu hỏi thành công!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xảy ra lỗi: $e')));
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
            Expanded(
              child: ListView.builder(
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 10.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: BorderSide(color: Colors.blueAccent, width: 1),
                    ),
                    elevation: 5, // Hiệu ứng bóng
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

      default:
        return Container();
    }

    return Column(children: inputFields);
  }
}

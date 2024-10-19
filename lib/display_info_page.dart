import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ReviewAnswersPage.dart';

class DisplayInfoPage extends StatefulWidget {
  final String userId;

  DisplayInfoPage({required this.userId});
  @override
  _DisplayInfoPageState createState() => _DisplayInfoPageState();
}

class _DisplayInfoPageState extends State<DisplayInfoPage> {
  List<dynamic> DisplayList = [];

  @override
  void initState() {
    super.initState();
    fetchPksData();
  }

  Future<void> fetchPksData() async {
    final response = await http.get(Uri.parse('http://localhost:3000/api/getresult/${widget.userId}'));
    if (response.statusCode == 200) {
      setState(() {
        DisplayList = json.decode(response.body);
      });
    } else {
      throw Exception('Tải dữ liệu phiếu khảo sát bị lỗi');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Danh sách Phiếu'),
      ),
      body: DisplayList.isEmpty
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 3 / 4,
        ),
        itemCount: DisplayList.length,
        itemBuilder: (context, index) {
          final Display = DisplayList[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReviewAnswersPage(pksId: Display['PKSID'],Dates :Display['Dates'], userId: widget.userId,),
                ),
              );
            },
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Lần thứ ${index + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                      Container(
                        height: MediaQuery.of(context).size.height * 0.15,
                        child: Center(
                          child: Image.asset(
                            'ks22.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                      Text(
                        Display['Name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

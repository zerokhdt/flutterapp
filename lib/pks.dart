import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'collect_info_page.dart';

class PksListPage extends StatefulWidget {
  final String userId;

  PksListPage({required this.userId});
  @override
  _PksListPageState createState() => _PksListPageState();
}

class _PksListPageState extends State<PksListPage> {
  List<dynamic> pksList = [];

  @override
  void initState() {
    super.initState();
    fetchPksData();
  }

  Future<void> fetchPksData() async {
    final response = await http.get(Uri.parse('http://localhost:3000/api/getpks'));
    if (response.statusCode == 200) {
      setState(() {
        pksList = json.decode(response.body);
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
      body: pksList.isEmpty
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 3 / 4,
        ),
        itemCount: pksList.length,
        itemBuilder: (context, index) {
          final pks = pksList[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuestionPage(pksId: pks['PKSID'], userId: widget.userId),
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
                        pks['Name'],
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

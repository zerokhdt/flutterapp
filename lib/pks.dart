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
    final response = await http.get(Uri.parse('http://192.168.1.5:3000/api/getpks'));
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
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
      ),
      body: pksList.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(10.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Số cột
            crossAxisSpacing: 10, // Khoảng cách giữa các cột
            mainAxisSpacing: 10, // Khoảng cách giữa các hàng
            childAspectRatio: 2 / 3, // Tỷ lệ chiều rộng/chiều cao
          ),
          itemCount: pksList.length,
          itemBuilder: (context, index) {
            final pks = pksList[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuestionPage(
                      pksId: pks['PKSID'],
                      userId: widget.userId,
                    ),
                  ),
                );
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0), // Bo góc
                ),
                elevation: 5, // Đổ bóng
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.height * 0.15,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          image: DecorationImage(
                            image: AssetImage('assets/ks22.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        pks['Name'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

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
  List<dynamic> displayList = [];

  @override
  void initState() {
    super.initState();
    fetchPksData();
  }

  Future<void> fetchPksData() async {
    final response = await http.get(Uri.parse('http://192.168.1.2:3000/api/getresult/${widget.userId}'));
    if (response.statusCode == 200) {
      setState(() {
        displayList = json.decode(response.body);
      });
    } else {
      throw Exception('Tải dữ liệu phiếu khảo sát bị lỗi');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Danh sách Phiếu Kết quả'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
      ),
      body: displayList.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(10.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Hiển thị 2 cột
            crossAxisSpacing: 10, // Khoảng cách giữa các cột
            mainAxisSpacing: 10, // Khoảng cách giữa các hàng
            childAspectRatio: 2 / 3, // Tỷ lệ chiều rộng/chiều cao
          ),
          itemCount: displayList.length,
          itemBuilder: (context, index) {
            final display = displayList[index];
            return GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReviewAnswersPage(
                      pksId: display['PKSID'],
                      Dates: display['Dates'],
                      userId: widget.userId,
                    ),
                  ),
                );
                // Nếu kết quả trả về là true, reload dữ liệu
                if (result == true) {
                  fetchPksData();
                }
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0), // Bo góc card
                ),
                elevation: 5, // Hiệu ứng bóng mờ
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Lần khảo sát: ${index + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      SizedBox(height: 10),
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
                        display['Name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 5),
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

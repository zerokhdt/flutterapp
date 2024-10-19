import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String _message = '';

  var uuid = Uuid();

  final RegExp emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

  Future<void> _register() async {
    String username = _usernameController.text;
    String email = _emailController.text;
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty) {
      setState(() {
        _message = 'Tên đăng nhập không được để trống!';
      });
      return;
    }

    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _message = 'Email không hợp lệ!';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _message = 'Mật khẩu phải có ít nhất 6 ký tự!';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _message = 'Mật khẩu và Xác nhận mật khẩu không khớp!';
      });
      return;
    }

    try {
      var checkResponse = await http.post(
        Uri.parse('http://localhost:3000/api/checkUsername'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );

      if (checkResponse.statusCode == 200) {
        var result = jsonDecode(checkResponse.body);
        if (result['exists'] == true) {
          setState(() {
            _message = 'Tên đăng nhập đã tồn tại!';
          });
          return;
        }
      }

      String userId = uuid.v4();

      var registerResponse = await http.post(
        Uri.parse('http://localhost:3000/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': userId,
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (registerResponse.statusCode == 200) {
        setState(() {
          _message = 'Tạo tài khoản thành công!';
        });
      } else {
        setState(() {
          _message = 'Đăng ký thất bại. Vui lòng thử lại.';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Có lỗi xảy ra. Vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng ký'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Đăng ký',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Tên đăng nhập',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _register,
                child: Text('Đăng ký'),
              ),
              SizedBox(height: 20),
              Text(
                _message,
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

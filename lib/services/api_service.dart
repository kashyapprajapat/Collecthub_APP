import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      print('Attempting registration to: ${AppConstants.registerUrl}');
      
      final response = await http.post(
        Uri.parse(AppConstants.registerUrl),
        headers: {
          'accept': 'text/plain',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      ).timeout(Duration(seconds: 30)); // Add timeout

      print('Registration response status: ${response.statusCode}');
      print('Registration response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'data': errorData,
          'error': 'Server returned ${response.statusCode}',
        };
      }
    } on SocketException catch (e) {
      print('Network error: $e');
      return {
        'success': false,
        'error': 'Network error: Please check your internet connection and try again.',
        'networkError': true,
      };
    } on HttpException catch (e) {
      print('HTTP error: $e');
      return {
        'success': false,
        'error': 'Server connection failed: $e',
        'networkError': true,
      };
    } on FormatException catch (e) {
      print('Format error: $e');
      return {
        'success': false,
        'error': 'Invalid server response format',
      };
    } catch (e) {
      print('General error: $e');
      return {
        'success': false,
        'error': 'Registration failed: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      print('Attempting login to: ${AppConstants.loginUrl}');
      
      final response = await http.post(
        Uri.parse(AppConstants.loginUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(Duration(seconds: 30)); // Add timeout

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'data': errorData,
          'error': 'Server returned ${response.statusCode}',
        };
      }
    } on SocketException catch (e) {
      print('Network error: $e');
      return {
        'success': false,
        'error': 'Network error: Please check your internet connection and try again.',
        'networkError': true,
      };
    } on HttpException catch (e) {
      print('HTTP error: $e');
      return {
        'success': false,
        'error': 'Server connection failed: $e',
        'networkError': true,
      };
    } on FormatException catch (e) {
      print('Format error: $e');
      return {
        'success': false,
        'error': 'Invalid server response format',
      };
    } catch (e) {
      print('General error: $e');
      return {
        'success': false,
        'error': 'Login failed: ${e.toString()}',
      };
    }
  }
}
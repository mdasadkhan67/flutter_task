import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../models/user_model.dart';

class UserApiService {
  final String _baseUrl = 'https://reqres.in/api';

  Future<List<UserModel>> fetchUsers(int page) async {
    final box = Hive.box('userBox');
    final cacheKey = 'users_page_$page';

    try {
      // Make API request to fetch users
      final response = await http.get(
        Uri.parse('$_baseUrl/users?per_page=10&page=$page'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List users = data['data'];

        // Check if users are empty
        if (users.isEmpty) {
          print('No users found on page $page');
        }

        // Save the fetched data into the cache (Hive)
        box.put(cacheKey, json.encode(users));

        // Return the list of user models
        return users.map((e) => UserModel.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      // If there’s an error, try to fetch cached data from Hive
      print('Error fetching users: $e');
      final cachedData = box.get(cacheKey);
      if (cachedData != null) {
        final List cachedUsers = json.decode(cachedData);
        return cachedUsers.map((e) => UserModel.fromJson(e)).toList();
      } else {
        rethrow;  // If no cached data, rethrow the error
      }
    }
  }

  Future<int> getTotalUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users?per_page=1&page=1'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['total'];
      } else {
        throw Exception('Failed to load total users');
      }
    } catch (e) {
      print('Error fetching total users: $e');
      throw Exception('Error fetching total users: $e');
    }
  }
}

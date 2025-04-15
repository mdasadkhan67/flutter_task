import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import '../data/datasources/user_api_service.dart';
import '../data/models/user_model.dart';

class UserViewModel extends ChangeNotifier {
  final UserApiService userApiService;

  UserViewModel({required this.userApiService});

  List<UserModel> users = [];
  bool isLoading = false;
  int page = 1;
  bool hasMore = true;
  String error = '';
  bool isSearching = false;
  bool isOffline = false;
  int totalUsers = 0;

  Future<void> checkConnectivityAndFetch({bool isRefresh = false}) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    isOffline = connectivityResult == ConnectivityResult.none;
    notifyListeners();

    if (isOffline) {
      await fetchUsersFromHive();
    } else {
      await fetchUsers(isRefresh: isRefresh, page: 1);
      await _fetchTotalUsers();
    }
  }

  Future<void> fetchUsers({bool isRefresh = false, int? page}) async {
    final currentPage = page ?? this.page;

    if (isLoading) return;

    if (isRefresh) {
      this.page = 1;
      users.clear();
      hasMore = true;
      error = '';
    }

    isLoading = true;
    notifyListeners();

    try {
      final fetchedUsers = await userApiService.fetchUsers(currentPage);

      if (fetchedUsers.isEmpty) {
        hasMore = false;
      } else {
        users.addAll(fetchedUsers);
        this.page = currentPage + 1;
        await _saveUsersToHive();
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUsersFromHive() async {
    final box = await Hive.openBox('userBox');
    final cachedData = box.get('users');

    if (cachedData != null) {
      final List<UserModel> cachedUsers =
          (cachedData as List).map((e) => UserModel.fromJson(e)).toList();
      users = cachedUsers;
    } else {
      error = 'No data available';
    }

    notifyListeners();
  }

  Future<void> _saveUsersToHive() async {
    final box = await Hive.openBox('userBox');
    await box.put('users', users.map((user) => user.toJson()).toList());
  }

  Future<void> _fetchTotalUsers() async {
    try {
      totalUsers = await userApiService.getTotalUsers();
      notifyListeners();
    } catch (e) {
      error = e.toString();
    }
  }

  void searchUser(String query) {
    if (query.isEmpty) {
      resetSearch();
    } else {
      isSearching = true;
      users = users.where((user) {
        final fullName = '${user.firstName} ${user.lastName}'.toLowerCase();
        return fullName.contains(query.toLowerCase());
      }).toList();
      notifyListeners();
    }
  }

  void resetSearch() {
    isSearching = false;
    users = [];
    page = 1;
    error = '';
    notifyListeners();
    fetchUsers(isRefresh: true);
  }

  void setError(String message) {
    error = message;
    notifyListeners();
  }
}

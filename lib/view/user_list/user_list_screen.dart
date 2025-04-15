import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hive/hive.dart';
import '../../../view_model/user_view_model.dart';
import '../../../data/models/user_model.dart';
import '../user_detail/user_detail_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<UserViewModel>();
    viewModel.checkConnectivityAndFetch();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent &&
          !viewModel.isLoading &&
          viewModel.hasMore &&
          !viewModel.isOffline) {
        viewModel.fetchUsers();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh(UserViewModel viewModel) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOffline = connectivityResult == ConnectivityResult.none;
    final box = await Hive.openBox('userBox');
    final usersData = box.get('users', defaultValue: null);

    if (isOffline && (usersData == null || usersData.isEmpty)) {
      viewModel.setError("No internet connection and no cached data.");
      return;
    }

    await viewModel.checkConnectivityAndFetch(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserViewModel>(builder: (context, viewModel, _) {
      bool isSearchEmpty = viewModel.users.isEmpty && viewModel.isSearching;

      return Scaffold(
        appBar: AppBar(
          title: const Text('User Directory'),
          centerTitle: true,
          backgroundColor: Colors.blueAccent,
          elevation: 1,
        ),
        body: Column(
          children: [
            _buildSearchBar(viewModel),
            if (viewModel.isOffline &&
                viewModel.users.isEmpty &&
                !isSearchEmpty)
              _buildOfflineView(viewModel)
            else if (viewModel.isLoading && viewModel.users.isEmpty)
              Expanded(child: _buildShimmerLoader())
            else if (isSearchEmpty)
              _buildNoUsersFoundView(viewModel)
            else
              _buildUserList(viewModel),
            if (viewModel.error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  viewModel.error,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildSearchBar(UserViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: TextField(
          controller: _searchController,
          onChanged: viewModel.searchUser,
          decoration: InputDecoration(
            hintText: "Search users by name...",
            prefixIcon: const Icon(Icons.search),
            suffixIcon: viewModel.isSearching
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      viewModel.resetSearch();
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoUsersFoundView(UserViewModel viewModel) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 60, color: Colors.grey),
            const SizedBox(height: 12),
            const Text("No Users Found", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineView(UserViewModel viewModel) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 60, color: Colors.grey),
            const SizedBox(height: 12),
            const Text("No Internet Connection",
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => viewModel.checkConnectivityAndFetch(),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(UserViewModel viewModel) {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: () async {
          await _handleRefresh(viewModel);
        },
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: viewModel.users.length + (viewModel.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < viewModel.users.length) {
              return _buildUserItem(context, viewModel.users[index]);
            } else if (viewModel.isLoading) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }

  Widget _buildUserItem(BuildContext context, UserModel user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade200,
          backgroundImage: NetworkImage(user.avatar),
        ),
        title: Text('${user.firstName} ${user.lastName}'),
        subtitle: Text(user.email),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserDetailScreen(user: user),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Row(
            children: [
              const CircleAvatar(radius: 30, backgroundColor: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(height: 12, width: 150, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

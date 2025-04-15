import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';

class UserDetailScreen extends StatelessWidget {
  final UserModel user;

  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('${user.firstName} ${user.lastName}'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundImage: NetworkImage(user.avatar),
                  radius: 65,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                '${user.firstName} ${user.lastName}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user.email,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 40),
              Divider(
                thickness: 1,
                color: Colors.grey.shade300,
                indent: 40,
                endIndent: 40,
              ),
              const SizedBox(height: 40),
              Icon(
                Icons.person_outline,
                size: 48,
                color: Colors.blueAccent.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

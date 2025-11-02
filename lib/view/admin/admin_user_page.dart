import 'package:ecommerce_app/respository/components/route_names.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Danh sách người dùng',
          style: TextStyle(fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, RouteNames.loginScreen);
            },
            icon: Icon(
              Icons.logout,
              color: Colors.red,
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('User Data').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Không có dữ liệu người dùng"));
          }

          var users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index].data() as Map<String, dynamic>;

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        user['image'] != null && user['image']!.isNotEmpty
                            ? NetworkImage(user['image'])
                            : const AssetImage('assets/default_avatar.png')
                                as ImageProvider,
                  ),
                  title: Text(user['Full name'],
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Email: ${user['Email']}"),
                      Text("SĐT: ${user['phone']}"),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserDetailScreen(userData: user),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class UserDetailScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const UserDetailScreen({super.key, required this.userData});

  Widget _buildUserInfo(String? label, String? value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value ?? ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chi tiết người dùng")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar người dùng
            CircleAvatar(
              radius: 50,
              backgroundImage:
                  userData['image'] != null && userData['image']!.isNotEmpty
                      ? NetworkImage(userData['image'])
                      : const AssetImage('assets/default_avatar.png')
                          as ImageProvider,
            ),

            const SizedBox(height: 20),

            // Thông tin người dùng
            _buildUserInfo("Tên đầy đủ", userData['Full name'], Icons.person),
            _buildUserInfo("Email", userData['Email'], Icons.email),
            _buildUserInfo("Số điện thoại", userData['phone'], Icons.phone),
            _buildUserInfo("Địa chỉ", userData['address'], Icons.location_on),
          ],
        ),
      ),
    );
  }
}

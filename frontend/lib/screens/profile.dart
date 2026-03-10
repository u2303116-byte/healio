import 'package:flutter/material.dart';
import 'user_data.dart';
import 'edit_profile.dart';
import 'login.dart';

class ProfileScreen extends StatefulWidget {
  final UserData userData;

  const ProfileScreen({super.key, required this.userData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserData currentUserData;

  @override
  void initState() {
    super.initState();
    currentUserData = widget.userData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile title at top (in gray area)
            Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Text(
                'Profile',
                style: TextStyle(
                  color: Theme.of(context).textTheme.displaySmall?.color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Profile Picture and Info (white card)
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.04),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  // Edit button at top right of profile card
                  Padding(
                    padding: EdgeInsets.only(right: 16, bottom: 10),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF20B2AA)),
                        onPressed: () async {
                          // Navigate to edit profile and wait for result
                          final updatedData = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(userData: currentUserData),
                            ),
                          );

                          // Update the state if data was returned
                          if (updatedData != null) {
                            setState(() {
                              currentUserData = updatedData;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  
                  // Profile Picture
                  Stack(
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF20B2AA),
                            width: 3,
                          ),
                          color: Theme.of(context).cardTheme.color ?? Colors.white,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 70,
                          color: Color(0xFF20B2AA),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            // Handle profile picture change
                            // You can add image picker functionality here
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF20B2AA),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).cardTheme.color ?? Colors.white,
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Name
                  Text(
                    currentUserData.name,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.displaySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Email
                  Text(
                    currentUserData.email,
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Health Information Section
            Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Health Information',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.headlineMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Health Info Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildHealthInfoCard(
                          icon: Icons.favorite,
                          iconColor: const Color(0xFFE57373),
                          label: 'Blood Type',
                          value: currentUserData.bloodType,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildHealthInfoCard(
                          icon: Icons.calendar_today,
                          iconColor: const Color(0xFF20B2AA),
                          label: 'Age',
                          value: '${currentUserData.age} years',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildHealthInfoCard(
                          icon: Icons.height,
                          iconColor: const Color(0xFF64B5F6),
                          label: 'Height',
                          value: '${currentUserData.height.toStringAsFixed(0)} cm',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildHealthInfoCard(
                          icon: Icons.fitness_center,
                          iconColor: const Color(0xFFFFB74D),
                          label: 'Weight',
                          value: '${currentUserData.weight.toStringAsFixed(1)} kg',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Logout Option
                  _buildSettingsOption(
                    icon: Icons.logout,
                    title: 'Logout',
                    titleColor: Colors.red,
                    iconColor: Colors.red,
                    onTap: () {
                      _showLogoutDialog();
                    },
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthInfoCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.headlineMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    Color? titleColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: iconColor ?? const Color(0xFF20B2AA),
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Navigate to login screen and clear all previous routes
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const Login()),
                (route) => false,
              );
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

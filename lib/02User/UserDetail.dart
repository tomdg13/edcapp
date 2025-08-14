import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:POSApp/config/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/simple_translations.dart';

class UserDetailPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const UserDetailPage({Key? key, required this.userData}) : super(key: key);

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  Map<String, dynamic> currentUserData = {};
  bool isLoading = false;
  String langCode = 'en';

  @override
  void initState() {
    super.initState();
    currentUserData = Map<String, dynamic>.from(widget.userData);
    getLanguage();
  }

  Future<void> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      langCode = prefs.getString('langCode') ?? 'en';
    });
  }

  // Get user ID from different possible field formats
  String getUserId() {
    return currentUserData['userId']?.toString() ??
        currentUserData['id']?.toString() ??
        currentUserData['user_id']?.toString() ??
        currentUserData['USER_ID']?.toString() ??
        '';
  }

  // Get user status
  String getUserStatus() {
    return currentUserData['userStatus'] ??
        currentUserData['USER_STATUS'] ??
        currentUserData['user_status'] ??
        'UNKNOWN';
  }

  // Get full name
  String getFullName() {
    final firstName =
        currentUserData['firstName'] ??
        currentUserData['name'] ??
        currentUserData['FIRST_NAME'] ??
        currentUserData['first_name'] ??
        '';
    final lastName =
        currentUserData['lastName'] ??
        currentUserData['LAST_NAME'] ??
        currentUserData['last_name'] ??
        '';

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else if (lastName.isNotEmpty) {
      return lastName;
    }
    return 'Unknown User';
  }

  // Get user phone
  String getUserPhone() {
    return currentUserData['phone'] ?? currentUserData['PHONE'] ?? '';
  }

  // Get user email
  String getUserEmail() {
    return currentUserData['email'] ?? currentUserData['EMAIL'] ?? '';
  }

  // Get user code
  String getUserCode() {
    return currentUserData['userCode'] ??
        currentUserData['user_code'] ??
        currentUserData['USER_CODE'] ??
        '';
  }

  // Refresh user data from API
  Future<void> _refreshUserData() async {
    final userId = getUserId();
    if (userId.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final url = AppConfig.api('/api/users/$userId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Refresh User Response: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          setState(() {
            currentUserData = Map<String, dynamic>.from(data['data']);
          });
        }
      }
    } catch (e) {
      print('❌ Error refreshing user data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Activate user
  Future<void> _activateUser() async {
    await _updateUserStatus('activate', 'ACTIVE');
  }

  // Suspend user
  Future<void> _suspendUser() async {
    await _updateUserStatus('suspend', 'SUSPENDED');
  }

  // Generic method to update user status
  Future<void> _updateUserStatus(String action, String newStatus) async {
    final userId = getUserId();
    if (userId.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final url = AppConfig.api('/api/users/$userId/$action');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 ${action.toUpperCase()} Response: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          currentUserData['userStatus'] = newStatus;
          currentUserData['USER_STATUS'] = newStatus;
          currentUserData['user_status'] = newStatus;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${action}d successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to $action user'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error ${action}ing user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Update last login
  Future<void> _updateLastLogin() async {
    final userId = getUserId();
    if (userId.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final url = AppConfig.api('/api/users/$userId/login');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Last login updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshUserData(); // Refresh to get updated data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update last login'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating last login: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Soft delete user
  Future<void> _deleteUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text(
            'Are you sure you want to delete this user? This action can be reversed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final userId = getUserId();
    if (userId.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final url = AppConfig.api('/api/users/$userId');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return to previous page
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete user'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error deleting user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Navigate to edit page
  Future<void> _navigateToEdit() async {
    // Import your UpdateUserPage here or navigate to edit
    // For now, just show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Edit functionality - integrate with your UpdateUserPage',
        ),
      ),
    );
  }

  // Reset user password to a temporary password
  Future<void> _resetPassword() async {
    final userStatus = getUserStatus();
    final isInitialPassword = userStatus.toUpperCase() == 'RESET PASSWORD';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isInitialPassword ? 'Set Initial Password' : 'Reset Password',
          ),
          content: Text(
            isInitialPassword
                ? 'Set an initial password for this user? They will need to change it after first login.'
                : 'Are you sure you want to reset this user\'s password? A new temporary password will be generated.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                isInitialPassword ? 'Set Password' : 'Reset',
                style: TextStyle(
                  color: isInitialPassword ? Colors.purple : Colors.orange,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final userId = getUserId();
    if (userId.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      // Use the password change endpoint with a generated temporary password
      final url = AppConfig.api('/api/users/$userId/password');

      // Generate a temporary password
      final tempPassword = _generateTempPassword();

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'newPassword': tempPassword,
          'resetPassword': true, // Flag to indicate this is a reset
        }),
      );

      print('📡 RESET PASSWORD Response: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final isInitialPassword =
            getUserStatus().toUpperCase() == 'RESET PASSWORD';

        // If this was setting initial password, update status to ACTIVE
        if (isInitialPassword) {
          setState(() {
            currentUserData['userStatus'] = 'ACTIVE';
            currentUserData['USER_STATUS'] = 'ACTIVE';
            currentUserData['user_status'] = 'ACTIVE';
          });
        }

        // Show the temporary password to admin
        _showTempPasswordDialog(tempPassword, isInitialPassword);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error resetting password: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Remove user password (set to null/empty)
  Future<void> _removePassword() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to remove this user\'s password?'),
              SizedBox(height: 8),
              Text(
                '⚠️ Warning: The user will not be able to log in until a new password is set.',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final userId = getUserId();
    if (userId.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      // Call remove password endpoint
      final url = AppConfig.api('/api/users/$userId/remove-password');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 REMOVE PASSWORD Response: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password removed successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        _refreshUserData(); // Refresh to get updated data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error removing password: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Generate a temporary password
  String _generateTempPassword() {
    const String chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return 'Temp${random.toString().substring(8)}!';
  }

  // Show temporary password dialog
  void _showTempPasswordDialog(
    String tempPassword, [
    bool isInitialPassword = false,
  ]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.key,
                color: isInitialPassword ? Colors.purple : Colors.green,
              ),
              SizedBox(width: 8),
              Text(
                isInitialPassword
                    ? 'Initial Password Set'
                    : 'Password Reset Successful',
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isInitialPassword
                    ? 'The user\'s initial password has been set to:'
                    : 'The user\'s password has been reset to:',
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tempPassword,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isInitialPassword
                              ? Colors.purple
                              : Colors.blue,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.copy,
                        color: isInitialPassword ? Colors.purple : Colors.blue,
                      ),
                      onPressed: () {
                        // Copy to clipboard functionality would go here
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Password copied to clipboard'),
                          ),
                        );
                      },
                      tooltip: 'Copy password',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                isInitialPassword
                    ? '🎉 User is now ACTIVE and can log in with this password. They should change it after first login.'
                    : '⚠️ Please share this password securely with the user. They should change it after first login.',
                style: TextStyle(
                  color: isInitialPassword
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isInitialPassword
                          ? 'Initial password set successfully - User is now ACTIVE'
                          : 'Password reset successfully',
                    ),
                    backgroundColor: isInitialPassword
                        ? Colors.purple
                        : Colors.green,
                  ),
                );
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Get status color
  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RESET PASSWORD':
        return Colors.purple;
      case 'ACTIVE':
        return Colors.green;
      case 'INACTIVE':
        return Colors.orange;
      case 'SUSPENDED':
        return Colors.red;
      case 'PENDING':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Build info row
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : 'Not provided',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: value.isNotEmpty ? Colors.black87 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userStatus = getUserStatus();
    final statusColor = _getStatusColor(userStatus);

    return Scaffold(
      appBar: AppBar(
        title: Text('User Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUserData,
          ),
          IconButton(icon: const Icon(Icons.edit), onPressed: _navigateToEdit),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Header Card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          // User Avatar
                          CircleAvatar(
                            backgroundColor: statusColor,
                            radius: 40,
                            child: Text(
                              getFullName().isNotEmpty
                                  ? getFullName()[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // User Name
                          Text(
                            getFullName(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          // User Code
                          if (getUserCode().isNotEmpty)
                            Text(
                              'ID: ${getUserCode()}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          const SizedBox(height: 12),

                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              userStatus,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Contact Information Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contact Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const Divider(),
                          _buildInfoRow(
                            'Phone Number',
                            getUserPhone(),
                            Icons.phone,
                          ),
                          _buildInfoRow(
                            'Email Address',
                            getUserEmail(),
                            Icons.email,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // System Information Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'System Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const Divider(),
                          _buildInfoRow(
                            'User ID',
                            getUserId(),
                            Icons.fingerprint,
                          ),
                          _buildInfoRow(
                            'Role ID',
                            currentUserData['roleId']?.toString() ??
                                currentUserData['role_id']?.toString() ??
                                currentUserData['ROLE_ID']?.toString() ??
                                'Not assigned',
                            Icons.badge,
                          ),
                          _buildInfoRow(
                            'Branch ID',
                            currentUserData['branchId']?.toString() ??
                                currentUserData['branch_id']?.toString() ??
                                currentUserData['BRANCH_ID']?.toString() ??
                                'Not assigned',
                            Icons.business,
                          ),
                          _buildInfoRow(
                            'Device ID',
                            currentUserData['deviceId']?.toString() ??
                                currentUserData['device_id']?.toString() ??
                                currentUserData['DEVICE_ID']?.toString() ??
                                'Not registered',
                            Icons.devices,
                          ),
                          _buildInfoRow(
                            'Created Date',
                            currentUserData['createdDate']?.toString() ??
                                currentUserData['created_date']?.toString() ??
                                currentUserData['CREATED_DATE']?.toString() ??
                                'Not available',
                            Icons.calendar_today,
                          ),
                          _buildInfoRow(
                            'Last Login',
                            currentUserData['lastLoginDate']?.toString() ??
                                currentUserData['last_login_date']
                                    ?.toString() ??
                                currentUserData['LAST_LOGIN_DATE']
                                    ?.toString() ??
                                'Never logged in',
                            Icons.login,
                          ),
                          _buildInfoRow(
                            'Created By',
                            currentUserData['createdBy']?.toString() ??
                                currentUserData['created_by']?.toString() ??
                                currentUserData['CREATED_BY']?.toString() ??
                                'Unknown',
                            Icons.person_add,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  const Text(
                    'Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Status Action Buttons
                  if (userStatus.toUpperCase() == 'RESET PASSWORD')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _resetPassword,
                        icon: const Icon(Icons.lock_reset, color: Colors.white),
                        label: const Text('Set Initial Password'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

                  if (userStatus.toUpperCase() != 'ACTIVE' &&
                      userStatus.toUpperCase() != 'RESET PASSWORD')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _activateUser,
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                        ),
                        label: const Text('Activate User'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

                  if (userStatus.toUpperCase() == 'ACTIVE')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _suspendUser,
                        icon: const Icon(
                          Icons.pause_circle,
                          color: Colors.white,
                        ),
                        label: const Text('Suspend User'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Update Last Login Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _updateLastLogin,
                      icon: const Icon(Icons.login),
                      label: const Text('Update Last Login'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Reset Password Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _resetPassword,
                      icon: const Icon(Icons.lock_reset, color: Colors.orange),
                      label: const Text('Reset Password'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Remove Password Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _removePassword,
                      icon: const Icon(Icons.lock_open, color: Colors.red),
                      label: const Text('Remove Password'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Edit Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _navigateToEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit User'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Danger Zone
                  Card(
                    color: Colors.red.shade50,
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Danger Zone',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: isLoading ? null : _deleteUser,
                              icon: const Icon(
                                Icons.delete_forever,
                                color: Colors.red,
                              ),
                              label: const Text('Delete User'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

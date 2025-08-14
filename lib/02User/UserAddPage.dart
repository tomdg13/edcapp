import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:POSApp/config/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/simple_translations.dart';

class UserAddPage extends StatefulWidget {
  const UserAddPage({Key? key}) : super(key: key);

  @override
  State<UserAddPage> createState() => _UserAddPageState();
}

class _UserAddPageState extends State<UserAddPage> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  String langCode = 'en';

  // Form Controllers - Based on your API field names
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController deviceIdController = TextEditingController();
  final TextEditingController roleIdController = TextEditingController();
  final TextEditingController branchIdController = TextEditingController();

  // No status selection - automatically set to INACTIVE
  final String defaultUserStatus = 'INACTIVE';

  @override
  void initState() {
    super.initState();
    getLanguage();
  }

  @override
  void dispose() {
    phoneController.dispose();
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    deviceIdController.dispose();
    roleIdController.dispose();
    branchIdController.dispose();
    super.dispose();
  }

  Future<void> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      langCode = prefs.getString('langCode') ?? 'en';
    });
  }

  // Generate a temporary password that meets API requirements
  String _generateTempPassword() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'Temp${timestamp.substring(timestamp.length - 6)}A1!';
  }

  Future<void> _submitForm() async {
    print('📝 === CREATE USER FORM SUBMIT ===');

    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      // Prepare the data exactly as your API expects (camelCase format)
      // Since API requires password, we'll generate a temporary one
      final tempPassword = _generateTempPassword();

      final userData = <String, dynamic>{
        "phone": phoneController.text.trim(),
        "email": emailController.text.trim(), // API requires email
        "password":
            tempPassword, // Temporary password - user will need to reset
        "firstName": firstNameController.text.trim(),
        "lastName": lastNameController.text.trim(),
        "userStatus": defaultUserStatus, // Automatically set to INACTIVE
      };

      // Add optional fields only if they have values
      if (deviceIdController.text.trim().isNotEmpty) {
        userData["deviceId"] = deviceIdController.text.trim();
      }

      if (roleIdController.text.trim().isNotEmpty) {
        final roleId = int.tryParse(roleIdController.text.trim());
        if (roleId != null) {
          userData["roleId"] = roleId;
        }
      }

      if (branchIdController.text.trim().isNotEmpty) {
        final branchId = int.tryParse(branchIdController.text.trim());
        if (branchId != null) {
          userData["branchId"] = branchId;
        }
      }

      final url = AppConfig.api('/api/users');
      print('🌐 API Endpoint: $url');
      print('📤 Request Data: ${jsonEncode(userData)}');
      print('🔐 Token: $token');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(userData),
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ User created successfully: $responseData');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User created successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Return success to refresh the user list
        Navigator.pop(context, true);
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');

        String errorMessage = 'Failed to create user';
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            if (errorData['message'] is List) {
              errorMessage = (errorData['message'] as List).join(', ');
            } else {
              errorMessage = errorData['message'].toString();
            }
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'].toString();
          }
        } catch (e) {
          print('Error parsing error response: $e');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('💥 Exception creating user: $e');
      print('💥 Stack trace: $stackTrace');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    phoneController.clear();
    emailController.clear();
    firstNameController.clear();
    lastNameController.clear();
    deviceIdController.clear();
    roleIdController.clear();
    branchIdController.clear();
  }

  // Quick fill demo data for testing
  void _fillDemoData() {
    setState(() {
      phoneController.text = '20123456';
      emailController.text = 'demo@example.com';
      firstNameController.text = 'Demo';
      lastNameController.text = 'User';
      deviceIdController.text = 'demo-device-001';
      roleIdController.text = '1';
      branchIdController.text = '2';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          SimpleTranslations.get(langCode, 'addNewUser') ?? 'Add New User',
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          // Demo data button for testing
          IconButton(
            onPressed: _fillDemoData,
            icon: const Icon(Icons.auto_fix_high),
            tooltip: 'Fill Demo Data',
          ),
          TextButton(
            onPressed: _clearForm,
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Card(
                color: Colors.green.shade50,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_add,
                        color: Colors.green.shade700,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create New User Account',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Fill in the required information to create a new user. Users are created as INACTIVE by default.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Required Fields Section
              _buildSectionHeader(
                'Required Information (Phone & Email)',
                Icons.star,
                Colors.red,
              ),
              const SizedBox(height: 12),

              // Phone Number
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: const Icon(Icons.phone),
                  border: const OutlineInputBorder(),
                  hintText: 'e.g., 20XXXXXXXX',
                  counterText: '${phoneController.text.length}/50',
                ),
                keyboardType: TextInputType.phone,
                maxLength: 50,
                onChanged: (value) => setState(() {}), // Update counter
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  if (value.trim().length < 8) {
                    return 'Phone number must be at least 8 digits';
                  }
                  if (value.trim().length > 50) {
                    return 'Phone number must not exceed 50 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address *',
                  prefixIcon: const Icon(Icons.email),
                  border: const OutlineInputBorder(),
                  hintText: 'e.g., user@example.com',
                  counterText: '${emailController.text.length}/255',
                ),
                keyboardType: TextInputType.emailAddress,
                maxLength: 255,
                onChanged: (value) => setState(() {}), // Update counter
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                    return 'Please enter a valid email address';
                  }
                  if (value.trim().length > 255) {
                    return 'Email must not exceed 255 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Personal Information Section
              _buildSectionHeader(
                'Personal Information',
                Icons.person,
                Colors.blue,
              ),
              const SizedBox(height: 12),

              // First Name
              TextFormField(
                controller: firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                  counterText: '${firstNameController.text.length}/100',
                ),
                textCapitalization: TextCapitalization.words,
                maxLength: 100,
                onChanged: (value) => setState(() {}),
                validator: (value) {
                  if (value != null && value.length > 100) {
                    return 'First name must not exceed 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Last Name
              TextFormField(
                controller: lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                  counterText: '${lastNameController.text.length}/100',
                ),
                textCapitalization: TextCapitalization.words,
                maxLength: 100,
                onChanged: (value) => setState(() {}),
                validator: (value) {
                  if (value != null && value.length > 100) {
                    return 'Last name must not exceed 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Optional Information Section
              _buildSectionHeader(
                'Optional Information',
                Icons.info_outline,
                Colors.grey,
              ),
              const SizedBox(height: 12),

              // Device ID
              TextFormField(
                controller: deviceIdController,
                decoration: InputDecoration(
                  labelText: 'Device ID (Optional)',
                  prefixIcon: const Icon(Icons.devices),
                  border: const OutlineInputBorder(),
                  hintText: 'e.g., device_abc123',
                  counterText: '${deviceIdController.text.length}/255',
                ),
                maxLength: 255,
                onChanged: (value) => setState(() {}),
                validator: (value) {
                  if (value != null && value.length > 255) {
                    return 'Device ID must not exceed 255 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Role ID
              TextFormField(
                controller: roleIdController,
                decoration: const InputDecoration(
                  labelText: 'Role ID (Optional)',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 1, 2, 3',
                  helperText: 'Numeric value for user role',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (int.tryParse(value.trim()) == null) {
                      return 'Role ID must be a valid number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Branch ID
              TextFormField(
                controller: branchIdController,
                decoration: const InputDecoration(
                  labelText: 'Branch ID (Optional)',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 100, 101, 102',
                  helperText: 'Numeric value for user branch',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (int.tryParse(value.trim()) == null) {
                      return 'Branch ID must be a valid number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _submitForm,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.save, color: Colors.white),
                  label: Text(
                    isLoading ? 'Creating User...' : 'Create User',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            margin: const EdgeInsets.only(left: 12),
            color: color.withOpacity(0.3),
          ),
        ),
      ],
    );
  }
}

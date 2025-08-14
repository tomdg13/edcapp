import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:POSApp/config/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/simple_translations.dart';

class GroupAddPage extends StatefulWidget {
  const GroupAddPage({Key? key}) : super(key: key);

  @override
  State<GroupAddPage> createState() => _GroupAddPageState();
}

class _GroupAddPageState extends State<GroupAddPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController staffNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController registrationBusinessController =
      TextEditingController();
  final TextEditingController groupIdController = TextEditingController();

  DateTime? birthday;
  bool hasStaff = false;
  bool hasContact = false;
  bool isSubmitting = false;

  String langCode = 'en';

  String _getMimeType(File? file) {
    if (file == null) return 'jpeg';
    final ext = file.path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'png';
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'gif':
        return 'gif';
      default:
        return 'jpeg';
    }
  }

  File? groupImageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    langCode = prefs.getString('langCode') ?? 'en';
    debugPrint('Language code: $langCode');
  }

  @override
  void initState() {
    super.initState();
    getLanguage();
  }

  @override
  void dispose() {
    nameController.dispose();
    staffNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    titleController.dispose();
    registrationBusinessController.dispose();
    groupIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        groupImageFile = File(picked.path);
      });
    }
  }

  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        birthday = picked;
      });
    }
  }

  Widget _buildImagePicker() {
    Widget displayImage;

    if (groupImageFile != null) {
      displayImage = Image.file(
        groupImageFile!,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
      );
    } else {
      displayImage = const Icon(Icons.group, size: 50);
    }

    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey),
            ),
            child: ClipOval(child: displayImage),
          ),
        ),
        const SizedBox(height: 8),
        Text(SimpleTranslations.get(langCode, 'groupImage')),
        const SizedBox(height: 8),
        Text(
          SimpleTranslations.get(langCode, 'tapToAdd'),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  bool _validateForm() {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(SimpleTranslations.get(langCode, 'groupNameRequired')),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (emailController.text.trim().isNotEmpty) {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
      if (!emailRegex.hasMatch(emailController.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(SimpleTranslations.get(langCode, 'invalidEmail')),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }

    return true;
  }

  Future<void> _submitCreate() async {
    if (!_validateForm()) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      print("🔐 Token being sent: $token");

      final newGroupData = {
        "name": nameController.text.trim(),
        "staff_name": staffNameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "title": titleController.text.trim(),
        "registration_business": registrationBusinessController.text.trim(),
        "birthday": birthday?.toIso8601String(),
        "has_staff": hasStaff,
        "has_contact": hasContact,
      };

      // Add group_id if provided
      if (groupIdController.text.trim().isNotEmpty) {
        newGroupData['group_id'] =
            int.tryParse(groupIdController.text.trim()) ?? 0;
      }

      // Add image if selected
      if (groupImageFile != null) {
        final bytes = await groupImageFile!.readAsBytes();
        newGroupData['image'] =
            "data:image/${_getMimeType(groupImageFile)};base64,${base64Encode(bytes)}";
      }

      // Using the groups API endpoint for creation
      final url = AppConfig.api('/api/groups');

      print("➡️ POST URL: $url");
      print("➡️ Payload JSON: ${jsonEncode(newGroupData)}");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(newGroupData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Create Success: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(SimpleTranslations.get(langCode, 'createSuccess')),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(SimpleTranslations.get(langCode, 'AddNewGroup')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Group Image Picker
              _buildImagePicker(),
              const SizedBox(height: 24),

              // Group ID (First field)
              TextFormField(
                controller: groupIdController,
                decoration: InputDecoration(
                  labelText: SimpleTranslations.get(langCode, 'groupID'),
                  border: const OutlineInputBorder(),
                  helperText: SimpleTranslations.get(langCode, 'enterGroupID'),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Group Name (Required)
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText:
                      '${SimpleTranslations.get(langCode, 'groupName')} *',
                  border: const OutlineInputBorder(),
                  helperText: SimpleTranslations.get(langCode, 'required'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return SimpleTranslations.get(
                      langCode,
                      'groupNameRequired',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Staff Name
              TextFormField(
                controller: staffNameController,
                decoration: InputDecoration(
                  labelText: SimpleTranslations.get(langCode, 'staffName'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: SimpleTranslations.get(langCode, 'email'),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: SimpleTranslations.get(langCode, 'phone'),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: SimpleTranslations.get(langCode, 'title'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Registration Business
              TextFormField(
                controller: registrationBusinessController,
                decoration: InputDecoration(
                  labelText: SimpleTranslations.get(
                    langCode,
                    'registrationBusiness',
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Birthday
              GestureDetector(
                onTap: _selectBirthday,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Text(
                        birthday != null
                            ? "${birthday!.day}/${birthday!.month}/${birthday!.year}"
                            : SimpleTranslations.get(
                                langCode,
                                'selectBirthday',
                              ),
                        style: TextStyle(
                          color: birthday != null
                              ? Colors.black
                              : Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Has Staff Checkbox
              CheckboxListTile(
                title: Text(SimpleTranslations.get(langCode, 'hasStaff')),
                subtitle: Text(
                  SimpleTranslations.get(langCode, 'hasStaffDescription'),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                value: hasStaff,
                onChanged: (value) {
                  setState(() {
                    hasStaff = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),

              // Has Contact Checkbox
              CheckboxListTile(
                title: Text(SimpleTranslations.get(langCode, 'hasContact')),
                subtitle: Text(
                  SimpleTranslations.get(langCode, 'hasContactDescription'),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                value: hasContact,
                onChanged: (value) {
                  setState(() {
                    hasContact = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),

              const SizedBox(height: 30),

              // Create Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isSubmitting ? null : _submitCreate,
                  icon: isSubmitting
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
                      : const Icon(Icons.add),
                  label: Text(
                    isSubmitting
                        ? SimpleTranslations.get(langCode, 'creating')
                        : SimpleTranslations.get(langCode, 'createGroup'),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.cancel),
                  label: Text(SimpleTranslations.get(langCode, 'cancel')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

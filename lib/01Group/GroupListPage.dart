import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:POSApp/config/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/simple_translations.dart';
import 'GroupAddPage.dart';

class GroupListPage extends StatefulWidget {
  const GroupListPage({Key? key}) : super(key: key);

  @override
  State<GroupListPage> createState() => _GroupListPageState();
}

class _GroupListPageState extends State<GroupListPage> {
  List<Map<String, dynamic>> groups = [];
  bool isLoading = true;
  String langCode = 'en';

  

  @override
  void initState() {
    super.initState();
    fetchGroups();
  }

  Future<void> fetchGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final url = AppConfig.api('/api/groups');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            groups = List<Map<String, dynamic>>.from(data['data']);
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load groups: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _navigateToUpdateGroup(Map<String, dynamic> groupData) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateGroupPage(groupData: groupData),
      ),
    );

    // Refresh the list if update was successful
    if (result == true) {
      fetchGroups();
    }
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final age = group['age'] ?? 0;
    final hasStaff = group['has_staff'] ?? false;
    final hasContact = group['has_contact'] ?? false;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            group['name'] != null && group['name'].isNotEmpty
                ? group['name'][0].toUpperCase()
                : 'G',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          group['name'] ?? 'Unknown Group',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (group['staff_name'] != null)
              Text('Staff: ${group['staff_name']}'),
            if (group['email'] != null) Text('Email: ${group['email']}'),
            if (group['phone'] != null) Text('Phone: ${group['phone']}'),
            Text('Age: $age'),
            Row(
              children: [
                if (hasStaff)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Has Staff',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                if (hasStaff && hasContact) const SizedBox(width: 4),
                if (hasContact)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Has Contact',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _navigateToUpdateGroup(group),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(SimpleTranslations.get(langCode, 'Groups')),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchGroups),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : groups.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    SimpleTranslations.get(langCode, 'noGroups'),
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchGroups,
              child: ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  return _buildGroupCard(groups[index]);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GroupAddPage()),
          );

          // Refresh the list if creation was successful
          if (result == true) {
            fetchGroups();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  SimpleTranslations.get(langCode, 'groupCreatedSuccess'),
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: SimpleTranslations.get(langCode, 'addNewGroup'),
      ),
    );
  }
}

// Include the UpdateGroupPage class in the same file to avoid import issues
class UpdateGroupPage extends StatefulWidget {
  final Map<String, dynamic> groupData;

  const UpdateGroupPage({Key? key, required this.groupData}) : super(key: key);

  @override
  State<UpdateGroupPage> createState() => _UpdateGroupPageState();
}

class _UpdateGroupPageState extends State<UpdateGroupPage> {
  late TextEditingController nameController;
  late TextEditingController staffNameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController titleController;
  late TextEditingController registrationBusinessController;
  late DateTime? birthday;
  late bool hasStaff;
  late bool hasContact;

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

    nameController = TextEditingController(
      text: widget.groupData['name'] ?? '',
    );
    staffNameController = TextEditingController(
      text: widget.groupData['staff_name'] ?? '',
    );
    emailController = TextEditingController(
      text: widget.groupData['email'] ?? '',
    );
    phoneController = TextEditingController(
      text: widget.groupData['phone'] ?? '',
    );
    titleController = TextEditingController(
      text: widget.groupData['title'] ?? '',
    );
    registrationBusinessController = TextEditingController(
      text: widget.groupData['registration_business'] ?? '',
    );

    // Parse birthday if exists
    if (widget.groupData['birthday'] != null) {
      try {
        birthday = DateTime.parse(widget.groupData['birthday']);
      } catch (e) {
        birthday = null;
      }
    } else {
      birthday = null;
    }

    hasStaff = widget.groupData['has_staff'] ?? false;
    hasContact = widget.groupData['has_contact'] ?? false;

    print("Group ID: ${widget.groupData['id']}");
    print("Group Data: ${widget.groupData}");
  }

  @override
  void dispose() {
    nameController.dispose();
    staffNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    titleController.dispose();
    registrationBusinessController.dispose();
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
      initialDate:
          birthday ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
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
          SimpleTranslations.get(langCode, 'tapToChange'),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Future<void> _submitUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final groupId = widget.groupData['id'];

    print("🔐 Token being sent: $token");
    print("🆔 Updating group ID: $groupId");

    final updatedData = {
      "name": nameController.text,
      "staff_name": staffNameController.text,
      "email": emailController.text,
      "phone": phoneController.text,
      "title": titleController.text,
      "registration_business": registrationBusinessController.text,
      "birthday": birthday?.toIso8601String(),
      "has_staff": hasStaff,
      "has_contact": hasContact,
      "group_id": widget.groupData['group_id'] ?? groupId,
    };

    // Add image if selected
    if (groupImageFile != null) {
      final bytes = await groupImageFile!.readAsBytes();
      updatedData['image'] =
          "data:image/${_getMimeType(groupImageFile)};base64,${base64Encode(bytes)}";
    }

    // Using the new groups API endpoint
    final url = AppConfig.api('/api/groups/$groupId');

    print("➡️ PUT Group ID: $groupId");
    print("➡️ PUT URL: $url");
    print("➡️ Payload JSON: ${jsonEncode(updatedData)}");

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        print('✅ Update Success: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(SimpleTranslations.get(langCode, 'updateSuccess')),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('❌ Exception: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(SimpleTranslations.get(langCode, 'UpdateGroupInfo')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Group Image Picker
              _buildImagePicker(),
              const SizedBox(height: 24),

              // Group Name
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: SimpleTranslations.get(langCode, 'groupName'),
                  border: const OutlineInputBorder(),
                ),
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
                value: hasContact,
                onChanged: (value) {
                  setState(() {
                    hasContact = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),

              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitUpdate,
                  icon: const Icon(Icons.save),
                  label: Text(SimpleTranslations.get(langCode, 'saveChanges')),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
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

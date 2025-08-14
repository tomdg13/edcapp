//  - Group details/info page
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class groupInfoPage extends StatefulWidget {
  final Map<String, dynamic> groupData;

  const groupInfoPage({Key? key, required this.groupData}) : super(key: key);

  @override
  State<groupInfoPage> createState() => _groupInfoPageState();
}

class _groupInfoPageState extends State<groupInfoPage> {
  Map<String, dynamic>? groupDetails;
  List<Map<String, dynamic>> relatedGroups = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchGroupDetails();
    fetchRelatedGroups();
  }

  Future<void> fetchGroupDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final groupId = widget.groupData['id'];

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3030/api/groups/$groupId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            groupDetails = data['data'];
            loading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> fetchRelatedGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final groupId = widget.groupData['id'];

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3030/api/groups/$groupId/related'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            relatedGroups = List<Map<String, dynamic>>.from(data['data'] ?? []);
          });
        }
      }
    } catch (e) {
      // Handle error silently for related groups
    }
  }

  Future<void> _deleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text('Are you sure you want to delete this group? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final groupId = widget.groupData['id'];

    try {
      final response = await http.delete(
        Uri.parse('http://localhost:3030/api/groups/$groupId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Group deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Not provided';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupData['name'] ?? 'Group Details'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _deleteGroup();
              } else if (value == 'edit') {
                // Navigate to edit page
              }
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 16),
                      _buildStaffCard(),
                      const SizedBox(height: 16),
                      _buildContactCard(),
                      const SizedBox(height: 16),
                      if (relatedGroups.isNotEmpty) _buildRelatedGroupsCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoCard() {
    final group = groupDetails ?? widget.groupData;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Group Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Name', group['name'] ?? 'Not provided'),
            _buildInfoRow('Group ID', group['group_id']?.toString() ?? 'Not assigned'),
            _buildInfoRow('Registration Business', group['registration_business'] ?? 'Not provided'),
            _buildInfoRow('Open Date', _formatDate(group['opendate'])),
            _buildInfoRow('Birthday', _formatDate(group['birthday'])),
            if (group['age'] != null)
              _buildInfoRow('Age', '${group['age']} years old'),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffCard() {
    final group = groupDetails ?? widget.groupData;
    final hasStaff = group['has_staff'] == true || group['staff_name']?.isNotEmpty == true;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasStaff ? Icons.person : Icons.person_outline,
                  color: hasStaff ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Staff Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            if (hasStaff) ...[
              _buildInfoRow('Staff Name', group['staff_name'] ?? 'Not provided'),
              _buildInfoRow('Title', group['title'] ?? 'Not provided'),
            ] else
              const Text(
                'No staff assigned to this group',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    final group = groupDetails ?? widget.groupData;
    final hasContact = group['has_contact'] == true || 
                      group['email']?.isNotEmpty == true || 
                      group['phone']?.isNotEmpty == true;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasContact ? Icons.contact_mail : Icons.contact_mail_outlined,
                  color: hasContact ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Contact Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            if (hasContact) ...[
              if (group['email']?.isNotEmpty == true)
                _buildInfoRow('Email', group['email'], isLink: true),
              if (group['phone']?.isNotEmpty == true)
                _buildInfoRow('Phone', group['phone'], isLink: true),
            ] else
              const Text(
                'No contact information available',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedGroupsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.group_work, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Related Groups (${relatedGroups.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            ...relatedGroups.map((relatedGroup) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                radius: 16,
                child: Icon(Icons.group, size: 16),
              ),
              title: Text(relatedGroup['name'] ?? 'Unknown'),
              subtitle: Text(relatedGroup['staff_name'] ?? 'No staff'),
              trailing: Text('#${relatedGroup['id']}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => groupInfoPage(groupData: relatedGroup),
                  ),
                );
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isLink ? Colors.blue : null,
                decoration: isLink ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
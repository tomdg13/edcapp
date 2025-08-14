import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:POSApp/config/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/simple_translations.dart';
import 'UserAddPage.dart';
import 'UserDetail.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({Key? key}) : super(key: key);

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = true;
  String langCode = 'en';

  // Search and Filter
  final TextEditingController searchController = TextEditingController();
  String selectedStatusFilter = 'ALL';
  bool isSearching = false;

  // Pagination
  bool isPaginated = false;
  int currentPage = 1;
  int totalPages = 1;
  int itemsPerPage = 10;
  int totalUsers = 0;

  final List<String> statusFilters = [
    'ALL',
    'Reset password',
    'ACTIVE',
    'INACTIVE',
    'SUSPENDED',
    'PENDING',
  ];

  @override
  void initState() {
    super.initState();
    getLanguage();
    fetchUsers();

    // Listen to search changes
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  Future<void> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      langCode = prefs.getString('langCode') ?? 'en';
    });
  }

  void _onSearchChanged() {
    setState(() {
      isSearching = searchController.text.isNotEmpty;
    });
    _filterUsers();
  }

  void _filterUsers() {
    List<Map<String, dynamic>> filtered = List.from(users);

    // Apply status filter (your API uses 'userStatus')
    if (selectedStatusFilter != 'ALL') {
      filtered = filtered.where((user) {
        final status =
            user['userStatus'] ??
            user['USER_STATUS'] ??
            user['user_status'] ??
            '';
        return status.toString().toUpperCase() == selectedStatusFilter;
      }).toList();
    }

    // Apply search filter (your API uses firstName/lastName)
    if (searchController.text.isNotEmpty) {
      final searchTerm = searchController.text.toLowerCase();
      filtered = filtered.where((user) {
        final firstName =
            (user['firstName'] ??
                    user['name'] ??
                    user['FIRST_NAME'] ??
                    user['first_name'] ??
                    '')
                .toString()
                .toLowerCase();
        final lastName =
            (user['lastName'] ?? user['LAST_NAME'] ?? user['last_name'] ?? '')
                .toString()
                .toLowerCase();
        final phone = (user['phone'] ?? user['PHONE'] ?? '')
            .toString()
            .toLowerCase();
        final email = (user['email'] ?? user['EMAIL'] ?? '')
            .toString()
            .toLowerCase();
        final userCode =
            (user['userCode'] ?? user['user_code'] ?? user['USER_CODE'] ?? '')
                .toString()
                .toLowerCase();

        return firstName.contains(searchTerm) ||
            lastName.contains(searchTerm) ||
            phone.contains(searchTerm) ||
            email.contains(searchTerm) ||
            userCode.contains(searchTerm);
      }).toList();
    }

    setState(() {
      filteredUsers = filtered;
    });
  }

  Future<void> fetchUsers({bool showLoading = true}) async {
    print('🔥 === FETCH USERS DEBUG START ===');

    if (showLoading) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      print('🔐 Token from SharedPreferences: $token');

      // Build URL with filters and pagination
      String endpoint = '/api/users';
      List<String> queryParams = [];

      if (selectedStatusFilter != 'ALL') {
        queryParams.add('status=$selectedStatusFilter');
      }

      if (isPaginated) {
        queryParams.add('paginate=true');
        queryParams.add('page=$currentPage');
        queryParams.add('limit=$itemsPerPage');
      }

      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      final url = AppConfig.api(endpoint);
      print('🌐 Full API URL: $url');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      print('📤 Request Headers: $headers');

      final response = await http.get(url, headers: headers);

      print('📡 === RESPONSE DEBUG ===');
      print('📡 Status Code: ${response.statusCode}');
      print('📡 Response Body (Raw): ${response.body}');

      if (response.statusCode == 200) {
        print('✅ HTTP 200 - Parsing JSON...');

        final data = json.decode(response.body);
        print('📊 Parsed JSON Data: $data');
        print('📊 Data Type: ${data.runtimeType}');

        if (data is List) {
          // Handle direct array response (your current API format)
          print('✅ Direct array response - extracting users...');
          setState(() {
            users = List<Map<String, dynamic>>.from(data);
            totalUsers = users.length;
            isLoading = false;
          });
          _filterUsers();
          print('✅ Users loaded successfully: ${users.length} users');
        } else if (data is Map) {
          // Handle wrapped response formats
          if (data['status'] == 'success') {
            print('✅ Status is "success" - extracting users...');

            if (isPaginated && data['data'] is Map) {
              // Handle paginated response
              final paginatedData = data['data'];
              setState(() {
                users = List<Map<String, dynamic>>.from(
                  paginatedData['users'] ?? paginatedData['data'] ?? [],
                );
                currentPage = paginatedData['currentPage'] ?? 1;
                totalPages = paginatedData['totalPages'] ?? 1;
                totalUsers = paginatedData['total'] ?? users.length;
                isLoading = false;
              });
            } else {
              // Handle regular response
              setState(() {
                users = List<Map<String, dynamic>>.from(data['data'] ?? []);
                totalUsers = users.length;
                isLoading = false;
              });
            }

            _filterUsers(); // Apply current filters
            print('✅ Users loaded successfully: ${users.length} users');
          } else if (data['response'] == '00') {
            // Alternative: NestJS API response structure
            print('✅ Response is "00" (NestJS format) - extracting users...');

            if (data['data'] != null && data['data']['users'] != null) {
              setState(() {
                users = List<Map<String, dynamic>>.from(data['data']['users']);
                totalUsers = users.length;
                isLoading = false;
              });
              _filterUsers();
              print('✅ Users loaded from NestJS format: ${users.length} users');
            } else {
              print('❌ No users array found in data["data"]["users"]');
              setState(() {
                users = [];
                filteredUsers = [];
                isLoading = false;
              });
            }
          } else {
            print('❌ Unexpected response format');
            print('❌ Expected: List OR status="success" OR response="00"');
            print('❌ Got: ${data.keys.toList()}');
            setState(() {
              users = [];
              filteredUsers = [];
              isLoading = false;
            });
          }
        } else {
          print('❌ Response is neither List nor Map: ${data.runtimeType}');
          setState(() {
            isLoading = false;
          });
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });

        if (showLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load users: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('💥 === EXCEPTION DEBUG ===');
      print('💥 Exception: $e');
      print('💥 Stack Trace: $stackTrace');

      setState(() {
        isLoading = false;
      });

      if (showLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }

    print('🔥 === FETCH USERS DEBUG END ===');
  }

  Future<void> _navigateToUserDetail(Map<String, dynamic> userData) async {
    print(
      '👁️ Navigating to user detail: ${userData['id'] ?? userData['user_id']}',
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailPage(userData: userData),
      ),
    );

    // Refresh the list if any changes were made
    if (result == true) {
      print('✅ Changes detected, refreshing user list...');
      fetchUsers(showLoading: false);
    }
  }

  Future<void> _navigateToAddUser() async {
    print('➕ Add user button pressed');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserAddPage()),
    );

    // Refresh the list if creation was successful
    if (result == true) {
      print('✅ User creation successful, refreshing list...');
      fetchUsers(showLoading: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(SimpleTranslations.get(langCode, 'userCreatedSuccess')),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    // Extract names from different possible field formats (your API uses firstName/lastName)
    final firstName =
        user['firstName'] ??
        user['name'] ??
        user['FIRST_NAME'] ??
        user['first_name'] ??
        '';
    final lastName =
        user['lastName'] ?? user['LAST_NAME'] ?? user['last_name'] ?? '';

    // Build full name
    String fullName = '';
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      fullName = '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      fullName = firstName;
    } else if (lastName.isNotEmpty) {
      fullName = lastName;
    } else {
      fullName = 'Unknown User';
    }

    // Extract other fields (your API format)
    final phone = user['phone'] ?? user['PHONE'] ?? '';
    final email = user['email'] ?? user['EMAIL'] ?? '';
    // ignore: unused_local_variable
    final userCode =
        user['userCode'] ?? user['user_code'] ?? user['USER_CODE'] ?? '';
    final status =
        user['userStatus'] ??
        user['USER_STATUS'] ??
        user['user_status'] ??
        'UNKNOWN';

    // Status color
    Color statusColor = Colors.grey;
    switch (status.toString().toUpperCase()) {
      case 'RESET PASSWORD':
        statusColor = Colors.purple;
        break;
      case 'ACTIVE':
        statusColor = Colors.green;
        break;
      case 'INACTIVE':
        statusColor = Colors.orange;
        break;
      case 'SUSPENDED':
        statusColor = Colors.red;
        break;
      case 'PENDING':
        statusColor = Colors.blue;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: statusColor,
          radius: 25,
          child: Text(
            fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Phone
            if (phone.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      phone,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),

            if (phone.isEmpty && email.isEmpty)
              const Row(
                children: [
                  Icon(Icons.info, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'No contact information',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.blue,
          size: 16,
        ),
        onTap: () => _navigateToUserDetail(user),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: isSearching
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        ),

        // Filter Row
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              const Text(
                'Status:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: statusFilters.map((status) {
                      final isSelected = selectedStatusFilter == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              selectedStatusFilter = status;
                            });
                            _filterUsers();
                          },
                          selectedColor: Colors.blue.shade100,
                          checkmarkColor: Colors.blue,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Pagination Toggle
              IconButton(
                icon: Icon(
                  isPaginated ? Icons.view_list : Icons.view_module,
                  color: Colors.blue,
                ),
                onPressed: () {
                  setState(() {
                    isPaginated = !isPaginated;
                    currentPage = 1;
                  });
                  fetchUsers();
                },
                tooltip: isPaginated ? 'Show All' : 'Enable Pagination',
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildPaginationControls() {
    if (!isPaginated || totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page $currentPage of $totalPages',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          Row(
            children: [
              IconButton(
                onPressed: currentPage > 1
                    ? () {
                        setState(() {
                          currentPage--;
                        });
                        fetchUsers();
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: currentPage < totalPages
                    ? () {
                        setState(() {
                          currentPage++;
                        });
                        fetchUsers();
                      }
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: ${isPaginated ? totalUsers : users.length} users',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (filteredUsers.length != users.length)
            Text(
              'Showing: ${filteredUsers.length} users',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(
      '🏗️ Building UserListPage - Users count: ${filteredUsers.length}, isLoading: $isLoading',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(SimpleTranslations.get(langCode, 'Users')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('🔄 Refresh button pressed');
              fetchUsers();
            },
          ),
          // Debug button - remove in production
          if (true) // Set to false in production
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Debug Info'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total users: ${users.length}'),
                        Text('Filtered users: ${filteredUsers.length}'),
                        Text('Is loading: $isLoading'),
                        Text('Is paginated: $isPaginated'),
                        Text('Current page: $currentPage'),
                        Text('Total pages: $totalPages'),
                        Text('Selected filter: $selectedStatusFilter'),
                        Text('Is searching: $isSearching'),
                        const SizedBox(height: 10),
                        const Text('Check console for detailed logs'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          _buildUserStats(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSearching || selectedStatusFilter != 'ALL'
                              ? Icons.search_off
                              : Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isSearching || selectedStatusFilter != 'ALL'
                              ? 'No users found matching your criteria'
                              : SimpleTranslations.get(langCode, 'noUsers'),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        if (!isSearching && selectedStatusFilter == 'ALL')
                          ElevatedButton(
                            onPressed: fetchUsers,
                            child: const Text('Retry'),
                          ),
                        if (isSearching || selectedStatusFilter != 'ALL')
                          ElevatedButton(
                            onPressed: () {
                              searchController.clear();
                              setState(() {
                                selectedStatusFilter = 'ALL';
                              });
                              _filterUsers();
                            },
                            child: const Text('Clear Filters'),
                          ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => fetchUsers(showLoading: false),
                    child: ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        return _buildUserCard(filteredUsers[index]);
                      },
                    ),
                  ),
          ),
          _buildPaginationControls(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddUser,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: SimpleTranslations.get(langCode, 'addNewUser'),
      ),
    );
  }
}

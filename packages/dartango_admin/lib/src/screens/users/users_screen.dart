import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/group.dart';
import '../../theme/app_theme.dart';
import '../../widgets/layout/admin_layout.dart';
import '../../widgets/common/data_table.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_button.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _users = [];
  List<Group> _groups = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _users = _generateSampleUsers();
      _isLoading = false;
    });
  }

  Future<void> _loadGroups() async {
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _groups = _generateSampleGroups();
    });
  }

  List<User> _generateSampleUsers() {
    return [
      User(
        id: '1',
        username: 'admin',
        email: 'admin@example.com',
        firstName: 'Admin',
        lastName: 'User',
        isActive: true,
        isStaff: true,
        isSuperuser: true,
        dateJoined: DateTime.now().subtract(const Duration(days: 365)),
        lastLogin: DateTime.now().subtract(const Duration(minutes: 30)),
        permissions: const ['admin.full'],
      ),
      User(
        id: '2',
        username: 'john_doe',
        email: 'john.doe@example.com',
        firstName: 'John',
        lastName: 'Doe',
        isActive: true,
        isStaff: true,
        isSuperuser: false,
        dateJoined: DateTime.now().subtract(const Duration(days: 180)),
        lastLogin: DateTime.now().subtract(const Duration(hours: 2)),
        permissions: const ['users.view', 'users.change'],
      ),
      User(
        id: '3',
        username: 'jane_smith',
        email: 'jane.smith@example.com',
        firstName: 'Jane',
        lastName: 'Smith',
        isActive: true,
        isStaff: false,
        isSuperuser: false,
        dateJoined: DateTime.now().subtract(const Duration(days: 90)),
        lastLogin: DateTime.now().subtract(const Duration(days: 1)),
        permissions: const ['users.view'],
      ),
      User(
        id: '4',
        username: 'inactive_user',
        email: 'inactive@example.com',
        firstName: 'Inactive',
        lastName: 'User',
        isActive: false,
        isStaff: false,
        isSuperuser: false,
        dateJoined: DateTime.now().subtract(const Duration(days: 30)),
        permissions: const [],
      ),
    ];
  }

  List<Group> _generateSampleGroups() {
    return [
      Group(
        id: '1',
        name: 'Administrators',
        description: 'Full system administrators',
        permissions: const ['admin.full'],
        userCount: 2,
        dateCreated: DateTime.now().subtract(const Duration(days: 365)),
        dateModified: DateTime.now().subtract(const Duration(days: 30)),
        isActive: true,
      ),
      Group(
        id: '2',
        name: 'Staff',
        description: 'Staff members with limited access',
        permissions: const ['users.view', 'users.change'],
        userCount: 5,
        dateCreated: DateTime.now().subtract(const Duration(days: 180)),
        dateModified: DateTime.now().subtract(const Duration(days: 10)),
        isActive: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Users',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadUsers,
          tooltip: 'Refresh',
        ),
        ElevatedButton.icon(
          onPressed: () => _showUserForm(),
          icon: const Icon(Icons.add),
          label: const Text('Add User'),
        ),
      ],
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildUserTable()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: CustomSearchField(
              controller: _searchController,
              hint: 'Search users...',
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: 'all',
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Users')),
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              DropdownMenuItem(value: 'staff', child: Text('Staff')),
              DropdownMenuItem(value: 'superuser', child: Text('Superusers')),
            ],
            onChanged: (value) {
              // Implement filtering
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserTable() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: CustomDataTable<User>(
        columns: [
          DataTableColumn<User>(
            key: 'avatar',
            label: '',
            value: (user) => user.avatar ?? '',
            cellBuilder: (user) => CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text(
                user.username.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          DataTableColumn<User>(
            key: 'username',
            label: 'Username',
            value: (user) => user.username,
          ),
          DataTableColumn<User>(
            key: 'name',
            label: 'Full Name',
            value: (user) => user.fullName.isNotEmpty ? user.fullName : '-',
          ),
          DataTableColumn<User>(
            key: 'email',
            label: 'Email',
            value: (user) => user.email,
          ),
          DataTableColumn<User>(
            key: 'status',
            label: 'Status',
            value: (user) => user.isActive ? 'Active' : 'Inactive',
            cellBuilder: (user) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: user.isActive
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: user.isActive ? AppColors.success : AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          DataTableColumn<User>(
            key: 'role',
            label: 'Role',
            value: (user) => user.isSuperuser
                ? 'Superuser'
                : user.isStaff
                    ? 'Staff'
                    : 'User',
            cellBuilder: (user) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: user.isSuperuser
                    ? AppColors.error.withValues(alpha: 0.1)
                    : user.isStaff
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.isSuperuser
                    ? 'Superuser'
                    : user.isStaff
                        ? 'Staff'
                        : 'User',
                style: TextStyle(
                  color: user.isSuperuser
                      ? AppColors.error
                      : user.isStaff
                          ? AppColors.warning
                          : AppColors.info,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          DataTableColumn<User>(
            key: 'lastLogin',
            label: 'Last Login',
            value: (user) =>
                user.lastLogin != null ? _formatDate(user.lastLogin!) : 'Never',
          ),
          DataTableColumn<User>(
            key: 'dateJoined',
            label: 'Joined',
            value: (user) => _formatDate(user.dateJoined),
          ),
        ],
        data: _users,
        searchQuery: _searchQuery,
        isLoading: _isLoading,
        showSelectAll: true,
        onRowTap: (user) => _showUserDetails(user),
        onEdit: (user) => _showUserForm(user: user),
        onDelete: (user) => _deleteUser(user),
        onBulkAction: (users) => _bulkDeleteUsers(users),
        emptyState: _buildEmptyState(),
        loadingState: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(64),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first user to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showUserForm(),
            icon: const Icon(Icons.add),
            label: const Text('Add User'),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user.username} Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
                'Full Name', user.fullName.isNotEmpty ? user.fullName : '-'),
            _buildDetailRow('Email', user.email),
            _buildDetailRow('Status', user.isActive ? 'Active' : 'Inactive'),
            _buildDetailRow(
                'Role',
                user.isSuperuser
                    ? 'Superuser'
                    : user.isStaff
                        ? 'Staff'
                        : 'User'),
            _buildDetailRow(
                'Last Login',
                user.lastLogin != null
                    ? _formatDate(user.lastLogin!)
                    : 'Never'),
            _buildDetailRow('Date Joined', _formatDate(user.dateJoined)),
            _buildDetailRow('Permissions', user.permissions.join(', ')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showUserForm(user: user);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserForm({User? user}) {
    showDialog(
      context: context,
      builder: (context) => UserFormDialog(
        user: user,
        groups: _groups,
        onSave: (savedUser) {
          setState(() {
            if (user != null) {
              final index = _users.indexWhere((u) => u.id == user.id);
              if (index != -1) {
                _users[index] = savedUser;
              }
            } else {
              _users.add(savedUser);
            }
          });
        },
      ),
    );
  }

  void _deleteUser(User user) {
    setState(() {
      _users.removeWhere((u) => u.id == user.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User ${user.username} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _users.add(user);
            });
          },
        ),
      ),
    );
  }

  void _bulkDeleteUsers(List<User> users) {
    setState(() {
      _users.removeWhere((user) => users.contains(user));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${users.length} users deleted'),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class UserFormDialog extends StatefulWidget {
  final User? user;
  final List<Group> groups;
  final Function(User) onSave;

  const UserFormDialog({
    super.key,
    this.user,
    required this.groups,
    required this.onSave,
  });

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isActive = true;
  bool _isStaff = false;
  bool _isSuperuser = false;
  bool _isLoading = false;
  List<String> _selectedPermissions = [];

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _usernameController.text = widget.user!.username;
      _emailController.text = widget.user!.email;
      _firstNameController.text = widget.user!.firstName;
      _lastNameController.text = widget.user!.lastName;
      _isActive = widget.user!.isActive;
      _isStaff = widget.user!.isStaff;
      _isSuperuser = widget.user!.isSuperuser;
      _selectedPermissions = List.from(widget.user!.permissions);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.user != null ? 'Edit User' : 'Add User'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: _usernameController,
                  label: 'Username',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _firstNameController,
                        label: 'First Name',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        controller: _lastNameController,
                        label: 'Last Name',
                      ),
                    ),
                  ],
                ),
                if (widget.user == null) ...[
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    obscureText: true,
                    validator: (value) {
                      if (widget.user == null &&
                          (value == null || value.isEmpty)) {
                        return 'Password is required for new users';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Active'),
                  subtitle: const Text('User can log in'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value ?? true;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Staff'),
                  subtitle: const Text('User can access admin site'),
                  value: _isStaff,
                  onChanged: (value) {
                    setState(() {
                      _isStaff = value ?? false;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Superuser'),
                  subtitle: const Text('User has all permissions'),
                  value: _isSuperuser,
                  onChanged: (value) {
                    setState(() {
                      _isSuperuser = value ?? false;
                      if (_isSuperuser) {
                        _isStaff = true;
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        LoadingButton(
          onPressed: _isLoading ? null : _handleSave,
          isLoading: _isLoading,
          child: Text(widget.user != null ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final user = User(
      id: widget.user?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      isActive: _isActive,
      isStaff: _isStaff,
      isSuperuser: _isSuperuser,
      dateJoined: widget.user?.dateJoined ?? DateTime.now(),
      lastLogin: widget.user?.lastLogin,
      permissions: _selectedPermissions,
    );

    widget.onSave(user);

    if (mounted) {
      Navigator.pop(context);
    }
  }
}

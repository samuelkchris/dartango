import 'package:flutter/material.dart';
import '../../models/group.dart';
import '../../theme/app_theme.dart';
import '../../widgets/layout/admin_layout.dart';
import '../../widgets/common/data_table.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_button.dart';
import '../../utils/constants.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Group> _groups = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _groups = _generateSampleGroups();
      _isLoading = false;
    });
  }

  List<Group> _generateSampleGroups() {
    return [
      Group(
        id: '1',
        name: 'Administrators',
        description: 'Full system administrators with all permissions',
        permissions: const [
          'admin.full',
          'users.add',
          'users.change',
          'users.delete',
          'users.view',
          'groups.add',
          'groups.change',
          'groups.delete',
          'groups.view',
        ],
        userCount: 2,
        dateCreated: DateTime.now().subtract(const Duration(days: 365)),
        dateModified: DateTime.now().subtract(const Duration(days: 30)),
        isActive: true,
      ),
      Group(
        id: '2',
        name: 'Staff',
        description: 'Staff members with limited administrative access',
        permissions: const [
          'users.view',
          'users.change',
          'groups.view',
          'logs.view',
        ],
        userCount: 5,
        dateCreated: DateTime.now().subtract(const Duration(days: 180)),
        dateModified: DateTime.now().subtract(const Duration(days: 10)),
        isActive: true,
      ),
      Group(
        id: '3',
        name: 'Moderators',
        description: 'Content moderators',
        permissions: const [
          'users.view',
          'logs.view',
        ],
        userCount: 8,
        dateCreated: DateTime.now().subtract(const Duration(days: 120)),
        dateModified: DateTime.now().subtract(const Duration(days: 5)),
        isActive: true,
      ),
      Group(
        id: '4',
        name: 'Inactive Group',
        description: 'An inactive group for testing',
        permissions: const [],
        userCount: 0,
        dateCreated: DateTime.now().subtract(const Duration(days: 60)),
        dateModified: DateTime.now().subtract(const Duration(days: 60)),
        isActive: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Groups',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadGroups,
          tooltip: 'Refresh',
        ),
        ElevatedButton.icon(
          onPressed: () => _showGroupForm(),
          icon: const Icon(Icons.add),
          label: const Text('Add Group'),
        ),
      ],
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildGroupTable()),
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
              hint: 'Search groups...',
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
              DropdownMenuItem(value: 'all', child: Text('All Groups')),
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
            ],
            onChanged: (value) {
              // Implement filtering
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTable() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: CustomDataTable<Group>(
        columns: [
          DataTableColumn<Group>(
            key: 'name',
            label: 'Name',
            value: (group) => group.name,
            cellBuilder: (group) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  group.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (group.description.isNotEmpty)
                  Text(
                    group.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          DataTableColumn<Group>(
            key: 'userCount',
            label: 'Users',
            value: (group) => group.userCount.toString(),
            cellBuilder: (group) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${group.userCount} users',
                style: const TextStyle(
                  color: AppColors.info,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          DataTableColumn<Group>(
            key: 'permissions',
            label: 'Permissions',
            value: (group) => group.permissions.length.toString(),
            cellBuilder: (group) => Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${group.permissions.length} perms',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          DataTableColumn<Group>(
            key: 'status',
            label: 'Status',
            value: (group) => group.isActive ? 'Active' : 'Inactive',
            cellBuilder: (group) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: group.isActive
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                group.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: group.isActive ? AppColors.success : AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          DataTableColumn<Group>(
            key: 'created',
            label: 'Created',
            value: (group) => _formatDate(group.dateCreated),
          ),
          DataTableColumn<Group>(
            key: 'modified',
            label: 'Modified',
            value: (group) => _formatDate(group.dateModified),
          ),
        ],
        data: _groups,
        searchQuery: _searchQuery,
        isLoading: _isLoading,
        showSelectAll: true,
        onRowTap: (group) => _showGroupDetails(group),
        onEdit: (group) => _showGroupForm(group: group),
        onDelete: (group) => _deleteGroup(group),
        onBulkAction: (groups) => _bulkDeleteGroups(groups),
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
            Icons.group_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No groups found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first group to organize user permissions',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showGroupForm(),
            icon: const Icon(Icons.add),
            label: const Text('Add Group'),
          ),
        ],
      ),
    );
  }

  void _showGroupDetails(Group group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${group.name} Details'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Name', group.name),
              _buildDetailRow('Description',
                  group.description.isNotEmpty ? group.description : '-'),
              _buildDetailRow('User Count', '${group.userCount} users'),
              _buildDetailRow('Status', group.isActive ? 'Active' : 'Inactive'),
              _buildDetailRow('Created', _formatDate(group.dateCreated)),
              _buildDetailRow('Modified', _formatDate(group.dateModified)),
              const SizedBox(height: 16),
              Text(
                'Permissions (${group.permissions.length}):',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              if (group.permissions.isEmpty)
                const Text(
                  'No permissions assigned',
                  style: TextStyle(color: AppColors.textSecondary),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: group.permissions.map((permission) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        permission,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showGroupForm(group: group);
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

  void _showGroupForm({Group? group}) {
    showDialog(
      context: context,
      builder: (context) => GroupFormDialog(
        group: group,
        onSave: (savedGroup) {
          setState(() {
            if (group != null) {
              final index = _groups.indexWhere((g) => g.id == group.id);
              if (index != -1) {
                _groups[index] = savedGroup;
              }
            } else {
              _groups.add(savedGroup);
            }
          });
        },
      ),
    );
  }

  void _deleteGroup(Group group) {
    if (group.userCount > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Delete Group'),
          content: Text(
            'Cannot delete group "${group.name}" because it has ${group.userCount} users assigned to it. '
            'Please remove all users from this group first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _groups.removeWhere((g) => g.id == group.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Group ${group.name} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _groups.add(group);
            });
          },
        ),
      ),
    );
  }

  void _bulkDeleteGroups(List<Group> groups) {
    final groupsWithUsers = groups.where((g) => g.userCount > 0).toList();

    if (groupsWithUsers.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Delete Some Groups'),
          content: Text(
            'Cannot delete ${groupsWithUsers.length} groups because they have users assigned. '
            'Please remove all users from these groups first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _groups.removeWhere((group) => groups.contains(group));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${groups.length} groups deleted'),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class GroupFormDialog extends StatefulWidget {
  final Group? group;
  final Function(Group) onSave;

  const GroupFormDialog({
    super.key,
    this.group,
    required this.onSave,
  });

  @override
  State<GroupFormDialog> createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends State<GroupFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isActive = true;
  bool _isLoading = false;
  List<String> _selectedPermissions = [];

  final List<String> _availablePermissions = [
    'admin.full',
    'users.add',
    'users.change',
    'users.delete',
    'users.view',
    'groups.add',
    'groups.change',
    'groups.delete',
    'groups.view',
    'sessions.add',
    'sessions.change',
    'sessions.delete',
    'sessions.view',
    'logs.view',
    'logs.export',
    'settings.change',
    'settings.view',
    'admin.access',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.group != null) {
      _nameController.text = widget.group!.name;
      _descriptionController.text = widget.group!.description;
      _isActive = widget.group!.isActive;
      _selectedPermissions = List.from(widget.group!.permissions);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.group != null ? 'Edit Group' : 'Add Group'),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _nameController,
                label: 'Group Name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Group name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomMultilineField(
                controller: _descriptionController,
                label: 'Description',
                minLines: 2,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Active'),
                subtitle:
                    const Text('Group is active and can be assigned to users'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value ?? true;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Permissions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _availablePermissions.length,
                    itemBuilder: (context, index) {
                      final permission = _availablePermissions[index];
                      final isSelected =
                          _selectedPermissions.contains(permission);

                      return CheckboxListTile(
                        title: Text(permission),
                        subtitle: Text(
                            Constants.permissions[permission] ?? permission),
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedPermissions.add(permission);
                            } else {
                              _selectedPermissions.remove(permission);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
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
          child: Text(widget.group != null ? 'Update' : 'Create'),
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

    final group = Group(
      id: widget.group?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      permissions: _selectedPermissions,
      userCount: widget.group?.userCount ?? 0,
      dateCreated: widget.group?.dateCreated ?? DateTime.now(),
      dateModified: DateTime.now(),
      isActive: _isActive,
    );

    widget.onSave(group);

    if (mounted) {
      Navigator.pop(context);
    }
  }
}

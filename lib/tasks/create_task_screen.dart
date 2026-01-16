import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../circles/circle_service.dart';
import 'task_controller.dart';
import 'task_model.dart';

class CreateTaskScreen extends StatefulWidget {
  final String circleId;
  final Task? editTask; // For editing existing tasks

  const CreateTaskScreen({super.key, required this.circleId, this.editTask});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TaskPriority _selectedPriority = TaskPriority.medium;
  String? _assignedTo;
  DateTime? _dueDate;
  List<Map<String, dynamic>> _circleMembers = [];
  bool _isLoading = false;

  bool get isEditing => widget.editTask != null;

  @override
  void initState() {
    super.initState();
    _loadCircleMembers();

    // If editing, populate fields
    if (isEditing) {
      final task = widget.editTask!;
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _selectedPriority = task.priority;
      _assignedTo = task.assignedTo;
      _dueDate = task.dueDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCircleMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final members = await CircleService.instance.getCircleMembers(
        widget.circleId,
      );
      setState(() {
        _circleMembers = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load members: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          isEditing ? 'Edit Task' : 'Create Task',
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF6366F1)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Consumer<TaskController>(
              builder: (context, taskController, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient:
                        taskController.isLoading
                            ? null
                            : const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                    color:
                        taskController.isLoading
                            ? const Color(0xFFE5E7EB)
                            : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    onPressed: taskController.isLoading ? null : _handleSave,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        taskController.isLoading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Text(
                              isEditing ? 'Update' : 'Create',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Consumer<TaskController>(
                builder: (context, taskController, child) {
                  return Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Title field
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Task Title',
                            hintText: 'What needs to be done?',
                            prefixIcon: Icon(Icons.task_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a task title';
                            }
                            return null;
                          },
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 16),

                        // Description field
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description (Optional)',
                            hintText: 'Add more details...',
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 16),

                        // Priority selector
                        DropdownButtonFormField<TaskPriority>(
                          value: _selectedPriority,
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                          items:
                              TaskPriority.values.map((priority) {
                                return DropdownMenuItem(
                                  value: priority,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        size: 12,
                                        color: _getPriorityColor(priority),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(_getPriorityDisplayName(priority)),
                                    ],
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedPriority = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Assign to member
                        DropdownButtonFormField<String>(
                          value: _assignedTo,
                          decoration: const InputDecoration(
                            labelText: 'Assign To (Optional)',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Unassigned'),
                            ),
                            ..._circleMembers.map((member) {
                              return DropdownMenuItem<String>(
                                value: member['uid'],
                                child: Text(member['name']),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _assignedTo = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Due date picker
                        ListTile(
                          leading: const Icon(Icons.calendar_today_outlined),
                          title: Text(
                            _dueDate == null
                                ? 'Set Due Date (Optional)'
                                : 'Due: ${_formatDate(_dueDate!)}',
                          ),
                          trailing:
                              _dueDate != null
                                  ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _dueDate = null;
                                      });
                                    },
                                  )
                                  : const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                          onTap: _selectDueDate,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 24),

                        // Error message
                        if (taskController.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.error.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              taskController.errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  );
                },
              ),
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _dueDate = date;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final taskController = context.read<TaskController>();

    bool success;
    if (isEditing) {
      success = await taskController.updateTask(
        circleId: widget.circleId,
        taskId: widget.editTask!.id,
        title: _titleController.text.trim(),
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        priority: _selectedPriority,
        assignedTo: _assignedTo,
        dueDate: _dueDate,
      );
    } else {
      success = await taskController.createTask(
        circleId: widget.circleId,
        title: _titleController.text.trim(),
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        priority: _selectedPriority,
        assignedTo: _assignedTo,
        dueDate: _dueDate,
      );
    }

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Task updated successfully!'
                : 'Task created successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.urgent:
        return Colors.purple;
    }
  }

  String _getPriorityDisplayName(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

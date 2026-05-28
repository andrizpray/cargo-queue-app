import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

class WhatsAppSettingsScreen extends StatefulWidget {
  const WhatsAppSettingsScreen({super.key});

  @override
  State<WhatsAppSettingsScreen> createState() => _WhatsAppSettingsScreenState();
}

class _WhatsAppSettingsScreenState extends State<WhatsAppSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _notificationsEnabled = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    final userProvider = context.read<UserProvider>();
    await userProvider.loadNotifications();
    
    if (mounted && userProvider.user != null) {
      setState(() {
        _phoneController.text = userProvider.phoneNumber ?? '';
        _notificationsEnabled = userProvider.notificationsEnabled;
        _isInitialized = true;
      });
    } else if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _savePhoneNumber() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final userId = authProvider.user?.id;

    if (userId == null) {
      _showSnackBar('User not found', isError: true);
      return;
    }

    final success = await userProvider.updatePhoneNumber(
      userId,
      _phoneController.text.trim(),
    );

    if (mounted) {
      if (success) {
        _showSnackBar('Phone number updated successfully');
      } else {
        _showSnackBar(
          userProvider.error ?? 'Failed to update phone number',
          isError: true,
        );
      }
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final userId = authProvider.user?.id;

    if (userId == null) {
      _showSnackBar('User not found', isError: true);
      return;
    }

    final success = await userProvider.toggleNotifications(userId, enabled);

    if (mounted) {
      if (success) {
        setState(() {
          _notificationsEnabled = enabled;
        });
        _showSnackBar(
          enabled
              ? 'WhatsApp notifications enabled'
              : 'WhatsApp notifications disabled',
        );
      } else {
        // Revert toggle if failed
        setState(() {
          _notificationsEnabled = !enabled;
        });
        _showSnackBar(
          userProvider.error ?? 'Failed to update settings',
          isError: true,
        );
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Receive queue status updates via WhatsApp',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Phone Number Section
                  Text(
                    'Phone Number',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your WhatsApp number to receive notifications',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 16),

                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '+1234567890',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (value.length < 8) {
                          return 'Phone number must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: userProvider.isLoading ? null : _savePhoneNumber,
                      child: userProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Update Phone Number'),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Notifications Toggle Section
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: const Text('WhatsApp Notifications'),
                    subtitle: Text(
                      _notificationsEnabled
                          ? 'You will receive queue updates on WhatsApp'
                          : 'Enable to receive WhatsApp notifications',
                    ),
                    secondary: Icon(
                      _notificationsEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      color: _notificationsEnabled ? Colors.green : Colors.grey,
                    ),
                    value: _notificationsEnabled,
                    onChanged: userProvider.isLoading ? null : _toggleNotifications,
                    contentPadding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: 24),

                  // Test Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _notificationsEnabled
                          ? () {
                              _showSnackBar(
                                'Test notification sent! Check your WhatsApp.',
                              );
                            }
                          : null,
                      icon: const Icon(Icons.send),
                      label: const Text('Send Test Notification'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

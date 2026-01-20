import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/widget/shared_app_bar.dart';
import 'package:gemnest_mobile_app/models/notification_model.dart';
import 'package:gemnest_mobile_app/services/notification_service.dart';

/// Notification Settings/Preferences Screen for users
class NotificationSettingsScreen extends StatefulWidget {
  final String userRole; // 'buyer', 'seller', or 'admin'

  const NotificationSettingsScreen({
    super.key,
    required this.userRole,
  });

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late NotificationPreferences _preferences;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final notificationService = NotificationService();
    try {
      final prefs =
          await notificationService.getNotificationPreferences(userId);
      setState(() {
        _preferences = prefs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading preferences: $e')),
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isSaving = true);

    final notificationService = NotificationService();
    try {
      await notificationService.updateNotificationPreferences(_preferences);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: const SharedAppBar(title: 'Notification Settings'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const SharedAppBar(
        title: 'Notification Settings',
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Toggle
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Enable Notifications',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Turn on/off all notifications',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _preferences.enableNotifications,
                        onChanged: (value) {
                          setState(() {
                            _preferences = _preferences.copyWith(
                              enableNotifications: value,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Notification Type Preferences
            if (_preferences.enableNotifications) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Notification Types',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildNotificationTypePreferences(),
            ],

            // Role-Specific Preferences
            if (widget.userRole == 'buyer')
              _buildBuyerPreferences()
            else if (widget.userRole == 'seller')
              _buildSellerPreferences(),

            // Sound and Vibration Settings
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Text(
                'Sound & Vibration',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildNotificationSound(),
            _buildVibration(),

            // Frequency Settings
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Text(
                'Notification Frequency',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildFrequencySettings(),

            // Quiet Hours
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Text(
                'Quiet Hours',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildQuietHours(),

            // Save Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _savePreferences,
                  icon: _isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save Preferences',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypePreferences() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Column(
          children: [
            _buildPreferenceSwitch(
              'Orders & Purchases',
              _preferences.orderNotifications,
              (value) {
                setState(() {
                  _preferences =
                      _preferences.copyWith(orderNotifications: value);
                });
              },
            ),
            const Divider(height: 1),
            _buildPreferenceSwitch(
              'Auction Activity',
              _preferences.auctionNotifications,
              (value) {
                setState(() {
                  _preferences =
                      _preferences.copyWith(auctionNotifications: value);
                });
              },
            ),
            const Divider(height: 1),
            _buildPreferenceSwitch(
              'Payment Updates',
              _preferences.paymentNotifications,
              (value) {
                setState(() {
                  _preferences =
                      _preferences.copyWith(paymentNotifications: value);
                });
              },
            ),
            const Divider(height: 1),
            _buildPreferenceSwitch(
              'Product Approvals',
              _preferences.approvalNotifications,
              (value) {
                setState(() {
                  _preferences =
                      _preferences.copyWith(approvalNotifications: value);
                });
              },
            ),
            const Divider(height: 1),
            _buildPreferenceSwitch(
              'Promotional & Special Offers',
              _preferences.promotionalNotifications,
              (value) {
                setState(() {
                  _preferences =
                      _preferences.copyWith(promotionalNotifications: value);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyerPreferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(
            'Buyer Preferences',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: _buildPreferenceSwitch(
              'Notify me when items in my interests are approved',
              _preferences.interestBasedNotifications,
              (value) {
                setState(() {
                  _preferences = _preferences.copyWith(
                    interestBasedNotifications: value,
                  );
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSellerPreferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(
            'Seller Preferences',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Column(
              children: [
                _buildPreferenceSwitch(
                  'Notify for every new bid',
                  _preferences.bidNotifications,
                  (value) {
                    setState(() {
                      _preferences =
                          _preferences.copyWith(bidNotifications: value);
                    });
                  },
                ),
                const Divider(height: 1),
                _buildPreferenceSwitch(
                  'Digest: Daily bid summary',
                  _preferences.digestNotifications,
                  (value) {
                    setState(() {
                      _preferences =
                          _preferences.copyWith(digestNotifications: value);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSound() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notification Sound',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _preferences.soundEnabled ? 'Enabled' : 'Disabled',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _preferences.soundEnabled,
                onChanged: (value) {
                  setState(() {
                    _preferences = _preferences.copyWith(soundEnabled: value);
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVibration() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vibration',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _preferences.vibrationEnabled ? 'Enabled' : 'Disabled',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _preferences.vibrationEnabled,
                onChanged: (value) {
                  setState(() {
                    _preferences =
                        _preferences.copyWith(vibrationEnabled: value);
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencySettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notification Frequency',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                isExpanded: true,
                value: _preferences.notificationFrequency,
                items: const [
                  DropdownMenuItem(value: 'instant', child: Text('Instant')),
                  DropdownMenuItem(
                      value: 'hourly', child: Text('Hourly digest')),
                  DropdownMenuItem(value: 'daily', child: Text('Daily digest')),
                ]
                    .map((item) => DropdownMenuItem(
                          value: item.value,
                          child: item.child,
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        notificationFrequency: value,
                      );
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuietHours() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quiet Hours',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _preferences.quietHoursEnabled
                              ? 'Enabled (${_preferences.quietHoursStart} - ${_preferences.quietHoursEnd})'
                              : 'Disabled',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _preferences.quietHoursEnabled,
                    onChanged: (value) {
                      setState(() {
                        _preferences =
                            _preferences.copyWith(quietHoursEnabled: value);
                      });
                    },
                  ),
                ],
              ),
              if (_preferences.quietHoursEnabled) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _parseTime(
                              _preferences.quietHoursStart,
                            ),
                          );
                          if (time != null) {
                            setState(() {
                              _preferences = _preferences.copyWith(
                                quietHoursStart:
                                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                              );
                            });
                          }
                        },
                        child: Text(
                          'From: ${_preferences.quietHoursStart}',
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _parseTime(
                              _preferences.quietHoursEnd,
                            ),
                          );
                          if (time != null) {
                            setState(() {
                              _preferences = _preferences.copyWith(
                                quietHoursEnd:
                                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                              );
                            });
                          }
                        },
                        child: Text(
                          'To: ${_preferences.quietHoursEnd}',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceSwitch(
    String label,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}

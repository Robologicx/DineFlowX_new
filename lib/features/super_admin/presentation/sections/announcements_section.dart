import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/features/super_admin/application/super_admin_providers.dart';
import 'package:hotel_management_system/features/super_admin/domain/entities/super_admin_entities.dart';

class AnnouncementsSection extends ConsumerStatefulWidget {
  const AnnouncementsSection({super.key});

  @override
  ConsumerState<AnnouncementsSection> createState() => _AnnouncementsSectionState();
}

class _AnnouncementsSectionState extends ConsumerState<AnnouncementsSection> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _sendInApp = true;
  bool _sendPush = true;
  String _targetType = 'all';
  final Set<String> _selectedBusinessIds = <String>{};
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final businessesAsync = ref.watch(businessesProvider);

    final settingsRef = FirebaseFirestore.instance
        .collection('platform')
        .doc('settings')
        .collection('notifications')
        .doc('channels');

    final jobsStream = FirebaseFirestore.instance
        .collection('platform')
        .doc('announcement_jobs')
        .collection('jobs')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: settingsRef.snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        final inAppEnabled = data['inAppEnabled'] == true;
        final pushEnabled = data['pushEnabled'] == true;
        final emailEnabled = data['emailEnabled'] == true;
        final smsEnabled = data['smsEnabled'] == true;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Announcements',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Broadcast announcements to all or selected businesses via multiple channels.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Composer',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'System maintenance, new feature release...',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _messageController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        hintText: 'Write the announcement content...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilterChip(
                          label: const Text('In-App'),
                          selected: _sendInApp,
                          onSelected: (value) => setState(() => _sendInApp = value),
                        ),
                        FilterChip(
                          label: const Text('Push'),
                          selected: _sendPush,
                          onSelected: (value) => setState(() => _sendPush = value),
                        ),
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<String>(
                            initialValue: _targetType,
                            decoration: const InputDecoration(labelText: 'Target'),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Businesses')),
                              DropdownMenuItem(value: 'selected', child: Text('Selected Businesses')),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _targetType = value);
                            },
                          ),
                        ),
                        if (_targetType == 'selected')
                          OutlinedButton.icon(
                            onPressed: businessesAsync.maybeWhen(
                              data: (items) => () => _selectBusinesses(items),
                              orElse: () => null,
                            ),
                            icon: const Icon(Icons.apartment_rounded),
                            label: Text('Select (${_selectedBusinessIds.length})'),
                          ),
                        FilledButton.icon(
                          onPressed: _isSending
                              ? null
                              : () => _sendAnnouncement(
                                    inAppEnabled: inAppEnabled,
                                    pushEnabled: pushEnabled,
                                  ),
                          icon: _isSending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(_isSending ? 'Sending...' : 'Send Announcement'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Channel Activation', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _NotificationChannelTile(
              icon: Icons.notifications_active_outlined,
              title: 'In-App Notifications',
              subtitle: 'Show announcement banners/messages inside the app.',
              value: inAppEnabled,
              onChanged: (value) => _setChannel(
                ref: settingsRef,
                key: 'inAppEnabled',
                value: value,
                context: context,
              ),
            ),
            _NotificationChannelTile(
              icon: Icons.notifications_outlined,
              title: 'Push Notifications',
              subtitle: 'Send push alerts to user devices.',
              value: pushEnabled,
              onChanged: (value) => _setChannel(
                ref: settingsRef,
                key: 'pushEnabled',
                value: value,
                context: context,
              ),
            ),
            _NotificationChannelTile(
              icon: Icons.email_outlined,
              title: 'Email Broadcasts',
              subtitle: 'Email selected or all businesses.',
              value: emailEnabled,
              onChanged: (value) => _setChannel(
                ref: settingsRef,
                key: 'emailEnabled',
                value: value,
                context: context,
              ),
            ),
            _NotificationChannelTile(
              icon: Icons.sms_outlined,
              title: 'SMS Campaigns',
              subtitle: 'Send announcement SMS where enabled.',
              value: smsEnabled,
              onChanged: (value) => _setChannel(
                ref: settingsRef,
                key: 'smsEnabled',
                value: value,
                context: context,
              ),
            ),
            const SizedBox(height: 12),
            Text('Delivery Status', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: jobsStream,
              builder: (context, jobSnapshot) {
                if (jobSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (jobSnapshot.hasError) {
                  return Card(
                    child: ListTile(
                      title: Text('Failed to load jobs: ${jobSnapshot.error}'),
                    ),
                  );
                }

                final jobs = jobSnapshot.data?.docs ?? const [];
                if (jobs.isEmpty) {
                  return const Card(
                    child: ListTile(
                      title: Text('No announcement jobs found yet.'),
                    ),
                  );
                }

                return Column(
                  children: jobs.map((doc) {
                    final job = doc.data();
                    final status = (job['status'] ?? 'unknown').toString();
                    final total = (job['totalBusinesses'] ?? 0).toString();
                    final inAppCount = (job['inAppSentCount'] ?? 0).toString();
                    final pushCount = (job['pushSentCount'] ?? 0).toString();
                    final pushFailed = (job['pushFailureCount'] ?? 0).toString();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text((job['title'] ?? 'Untitled').toString()),
                        subtitle: Text(
                          'Status: $status | Targets: $total | In-App: $inAppCount | Push: $pushCount | Push Failed: $pushFailed',
                        ),
                        trailing: Text(doc.id.substring(0, 8)),
                      ),
                    );
                  }).toList(growable: false),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectBusinesses(List<BusinessTenantSummary> businesses) async {
    final selected = <String>{..._selectedBusinessIds};

    if (!mounted) return;
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Select Businesses'),
              content: SizedBox(
                width: 420,
                height: 420,
                child: ListView.builder(
                  itemCount: businesses.length,
                  itemBuilder: (context, index) {
                    final business = businesses[index];
                    final checked = selected.contains(business.businessId);
                    return CheckboxListTile(
                      value: checked,
                      title: Text(business.businessName),
                      subtitle: Text(business.businessId),
                      onChanged: (value) {
                        setStateDialog(() {
                          if (value == true) {
                            selected.add(business.businessId);
                          } else {
                            selected.remove(business.businessId);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(selected),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;
    setState(() {
      _selectedBusinessIds
        ..clear()
        ..addAll(result);
    });
  }

  Future<void> _sendAnnouncement({
    required bool inAppEnabled,
    required bool pushEnabled,
  }) async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and message are required.')),
      );
      return;
    }

    if (!_sendInApp && !_sendPush) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one channel (In-App/Push).')),
      );
      return;
    }

    if (_targetType == 'selected' && _selectedBusinessIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one business.')),
      );
      return;
    }

    if (_sendInApp && !inAppEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('In-App channel is disabled. Enable it first.')),
      );
      return;
    }

    if (_sendPush && !pushEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Push channel is disabled. Enable it first.')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('sendPlatformAnnouncement');
      await callable.call(<String, dynamic>{
        'title': title,
        'message': message,
        'targetType': _targetType,
        'targetBusinessIds': _selectedBusinessIds.toList(growable: false),
        'channels': {
          'inApp': _sendInApp,
          'push': _sendPush,
        },
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement job submitted successfully.')),
      );
      _titleController.clear();
      _messageController.clear();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: ${e.message ?? e.code}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _setChannel({
    required DocumentReference<Map<String, dynamic>> ref,
    required String key,
    required bool value,
    required BuildContext context,
  }) async {
    try {
      await ref.set(<String, dynamic>{
        key: value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Updated: $key = $value')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update setting: $e')));
    }
  }
}

class _NotificationChannelTile extends StatelessWidget {
  const _NotificationChannelTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Switch.adaptive(value: value, onChanged: onChanged),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/app_capability.dart';
import '../../../core/routing/app_routes.dart';
import '../../../domain/entities/organizer_announcement.dart';
import '../../../providers/announcement_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/auth/capability_guard.dart';
import '../../../shared/widgets/shared_widgets.dart';

class OrganizerAnnouncementComposeScreen extends StatefulWidget {
  const OrganizerAnnouncementComposeScreen({super.key, this.announcementId});

  final String? announcementId;

  @override
  State<OrganizerAnnouncementComposeScreen> createState() =>
      _OrganizerAnnouncementComposeScreenState();
}

class _OrganizerAnnouncementComposeScreenState
    extends State<OrganizerAnnouncementComposeScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _loading = true;
  OrganizerAnnouncement? _existing;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final id = widget.announcementId;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    final existing = await context.read<AnnouncementState>().getById(id);
    if (!mounted) return;
    _existing = existing;
    if (existing != null) {
      _titleController.text = existing.title;
      _bodyController.text = existing.body;
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return CapabilityGuard(
      capability: AppCapability.publishAnnouncement,
      authState: auth,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.announcementId == null
                ? 'Compose announcement'
                : 'Edit announcement',
          ),
          actions: [
            TextButton(
              onPressed: _loading ? null : () => _save(context, publish: false),
              child: const Text('Save draft'),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ResponsiveLayout(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _bodyController,
                      minLines: 4,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _save(context, publish: true),
                      icon: const Icon(Icons.campaign_outlined),
                      label: const Text('Publish now'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _save(BuildContext context, {required bool publish}) async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and message are required')),
      );
      return;
    }

    final state = context.read<AnnouncementState>();
    final saved = await state.saveDraft(
      id: _existing?.id,
      title: title,
      body: body,
    );
    if (publish) {
      await state.publish(saved.id);
    }
    if (!context.mounted) return;
    context.go(AppRoutes.organizerAnnouncements);
  }
}

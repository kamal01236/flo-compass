import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/mock_user.dart';
import '../../core/auth/platform_role.dart';
import '../../core/config/runtime_config.dart';
import '../../providers/auth_provider.dart';

/// Shows a bottom sheet to pick a dev mock user and signs in.
Future<void> showMockUserPicker(BuildContext context) async {
  final auth = context.read<AuthState>();
  final users = RuntimeConfig.mockUsers;
  if (users.isEmpty) return;

  final selected = await showModalBottomSheet<MockUser>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                'Choose a demo user',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            for (final user in users)
              ListTile(
                title: Text(user.name),
                subtitle: Text(
                  '${user.email} · ${user.role.label}'
                  '${user.organization.isNotEmpty ? ' · ${user.organization}' : ''}',
                ),
                onTap: () => Navigator.of(context).pop(user),
              ),
          ],
        ),
      );
    },
  );

  if (selected == null || !context.mounted) return;
  await auth.signInMock(selected);
}

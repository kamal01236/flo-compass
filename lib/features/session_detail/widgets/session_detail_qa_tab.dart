import 'package:flutter/material.dart';

import 'session_qa_section.dart';

class SessionDetailQaTab extends StatelessWidget {
  const SessionDetailQaTab({
    super.key,
    required this.sessionId,
    required this.sessionTitle,
    this.sessionAbstract,
    this.bottomScrollPadding = 0,
  });

  final String sessionId;
  final String sessionTitle;
  final String? sessionAbstract;
  final double bottomScrollPadding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomScrollPadding),
      children: [
        SessionQaSection(
          sessionId: sessionId,
          sessionTitle: sessionTitle,
          sessionAbstract: sessionAbstract,
        ),
      ],
    );
  }
}

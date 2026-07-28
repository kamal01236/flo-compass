class SessionQaModerationStats {
  const SessionQaModerationStats({
    required this.pendingCount,
    required this.hiddenCount,
    required this.totalCount,
    required this.pendingBySession,
  });

  final int pendingCount;
  final int hiddenCount;
  final int totalCount;
  final Map<String, int> pendingBySession;
}

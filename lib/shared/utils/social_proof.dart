/// Deterministic mock attendee interest — demo only, not real attendance.
int mockSavedCount(String sessionId) => 12 + (sessionId.hashCode.abs() % 88);

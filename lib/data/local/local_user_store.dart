import 'package:shared_preferences/shared_preferences.dart';

/// Typed keys over [SharedPreferences]. Web storage is not encrypted.
///
/// Auth tokens (access, refresh, id) are persisted in browser localStorage
/// via [SharedPreferences], which is **unencrypted** on the web. This
/// mirrors the existing pattern used for consent and locale state; the
/// upgrade to encrypted storage is tracked as a backlog item at
/// `docs/plans/backlog/encrypted-web-storage.md`.
class LocalUserStore {
  LocalUserStore({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  static const consentAcceptedAtKey = 'flo_consent_accepted_at';
  static const consentVersionKey = 'flo_consent_version';
  static const localeCodeKey = 'flo_locale_code';
  static const feedbackDraftKey = 'flo_feedback_draft';
  static const feedbackQueueKey = 'flo_feedback_queue';
  static const analyticsQueueKey = 'flo_analytics_queue';
  static const analyticsAnonymousSessionKey = 'flo_analytics_anonymous_session';
  static const companionQueryCountKey = 'flo_companion_query_count';
  static const authSubjectKey = 'flo_auth_subject';
  static const authDisplayNameKey = 'flo_auth_display_name';
  static const authEmailKey = 'flo_auth_email';
  static const authExpiresAtKey = 'flo_auth_expires_at';
  static const authAccessTokenKey = 'flo_auth_access_token';
  static const authRefreshTokenKey = 'flo_auth_refresh_token';
  static const authIdTokenKey = 'flo_auth_id_token';
  static const authPlatformRoleKey = 'flo_auth_platform_role';
  static const maxFeedbackQueueSize = 50;
  static const maxAnalyticsQueueSize = 500;

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<DateTime?> getConsentAcceptedAt() async {
    final ms = (await _ensurePrefs()).getInt(consentAcceptedAtKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<String?> getConsentVersion() async =>
      (await _ensurePrefs()).getString(consentVersionKey);

  Future<bool> hasAcceptedConsent(String requiredVersion) async {
    final version = await getConsentVersion();
    return version == requiredVersion && await getConsentAcceptedAt() != null;
  }

  Future<void> setConsentAccepted({
    required String version,
    required DateTime acceptedAt,
  }) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(consentVersionKey, version);
    await prefs.setInt(consentAcceptedAtKey, acceptedAt.millisecondsSinceEpoch);
  }

  Future<void> clearConsent() async {
    final prefs = await _ensurePrefs();
    await prefs.remove(consentVersionKey);
    await prefs.remove(consentAcceptedAtKey);
  }

  Future<String?> getLocaleCode() async =>
      (await _ensurePrefs()).getString(localeCodeKey);

  Future<void> setLocaleCode(String code) async {
    await (await _ensurePrefs()).setString(localeCodeKey, code);
  }

  Future<String?> getFeedbackDraft() async =>
      (await _ensurePrefs()).getString(feedbackDraftKey);

  Future<void> setFeedbackDraft(String? draft) async {
    final prefs = await _ensurePrefs();
    if (draft == null) {
      await prefs.remove(feedbackDraftKey);
    } else {
      await prefs.setString(feedbackDraftKey, draft);
    }
  }

  Future<List<String>> getFeedbackQueue() async {
    return (await _ensurePrefs()).getStringList(feedbackQueueKey) ?? [];
  }

  Future<void> enqueueFeedback(String payload) async {
    final prefs = await _ensurePrefs();
    final queue = [...await getFeedbackQueue(), payload];
    final trimmed = queue.length <= maxFeedbackQueueSize
        ? queue
        : queue.sublist(queue.length - maxFeedbackQueueSize);
    await prefs.setStringList(feedbackQueueKey, trimmed);
  }

  Future<void> setFeedbackQueue(List<String> queue) async {
    final prefs = await _ensurePrefs();
    if (queue.isEmpty) {
      await prefs.remove(feedbackQueueKey);
      return;
    }
    final trimmed = queue.length <= maxFeedbackQueueSize
        ? queue
        : queue.sublist(queue.length - maxFeedbackQueueSize);
    await prefs.setStringList(feedbackQueueKey, trimmed);
  }

  Future<void> clearFeedbackQueue() async {
    await (await _ensurePrefs()).remove(feedbackQueueKey);
  }

  Future<List<String>> getAnalyticsQueue() async {
    return (await _ensurePrefs()).getStringList(analyticsQueueKey) ?? [];
  }

  Future<void> enqueueAnalytics(String payload) async {
    final prefs = await _ensurePrefs();
    final queue = [...await getAnalyticsQueue(), payload];
    final trimmed = queue.length <= maxAnalyticsQueueSize
        ? queue
        : queue.sublist(queue.length - maxAnalyticsQueueSize);
    await prefs.setStringList(analyticsQueueKey, trimmed);
  }

  Future<void> setAnalyticsQueue(List<String> queue) async {
    final prefs = await _ensurePrefs();
    if (queue.isEmpty) {
      await prefs.remove(analyticsQueueKey);
      return;
    }
    final trimmed = queue.length <= maxAnalyticsQueueSize
        ? queue
        : queue.sublist(queue.length - maxAnalyticsQueueSize);
    await prefs.setStringList(analyticsQueueKey, trimmed);
  }

  Future<void> dequeueAnalytics(String payload) async {
    final prefs = await _ensurePrefs();
    final queue = [...await getAnalyticsQueue()];
    queue.remove(payload);
    if (queue.isEmpty) {
      await prefs.remove(analyticsQueueKey);
    } else {
      await prefs.setStringList(analyticsQueueKey, queue);
    }
  }

  Future<void> clearAnalyticsQueue() async {
    await (await _ensurePrefs()).remove(analyticsQueueKey);
  }

  Future<String?> getAnalyticsAnonymousSessionKey() async =>
      (await _ensurePrefs()).getString(analyticsAnonymousSessionKey);

  Future<void> setAnalyticsAnonymousSessionKey(String key) async {
    await (await _ensurePrefs()).setString(analyticsAnonymousSessionKey, key);
  }

  Future<int> getCompanionQueryCount() async =>
      (await _ensurePrefs()).getInt(companionQueryCountKey) ?? 0;

  Future<void> setCompanionQueryCount(int count) async {
    await (await _ensurePrefs()).setInt(companionQueryCountKey, count);
  }

  Future<void> clearCompanionQueryCount() async {
    await (await _ensurePrefs()).remove(companionQueryCountKey);
  }

  Future<void> saveAuthMetadata({
    required String subject,
    required String displayName,
    required DateTime expiresAt,
    String? email,
    String? idToken,
    String? accessToken,
    String? refreshToken,
    String? platformRole,
  }) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(authSubjectKey, subject);
    await prefs.setString(authDisplayNameKey, displayName);
    await prefs.setInt(authExpiresAtKey, expiresAt.millisecondsSinceEpoch);
    await _writeOrRemoveString(prefs, authEmailKey, email);
    await _writeOrRemoveString(prefs, authIdTokenKey, idToken);
    await _writeOrRemoveString(prefs, authAccessTokenKey, accessToken);
    await _writeOrRemoveString(prefs, authRefreshTokenKey, refreshToken);
    await _writeOrRemoveString(prefs, authPlatformRoleKey, platformRole);
  }

  Future<void> clearAuthMetadata() async {
    final prefs = await _ensurePrefs();
    await prefs.remove(authSubjectKey);
    await prefs.remove(authDisplayNameKey);
    await prefs.remove(authEmailKey);
    await prefs.remove(authExpiresAtKey);
    await prefs.remove(authIdTokenKey);
    await prefs.remove(authAccessTokenKey);
    await prefs.remove(authRefreshTokenKey);
    await prefs.remove(authPlatformRoleKey);
  }

  Future<
    ({
      String subject,
      String displayName,
      String? email,
      String? idToken,
      String? accessToken,
      String? refreshToken,
      DateTime expiresAt,
      String? platformRole,
    })?
  >
  readAuthMetadata() async {
    final prefs = await _ensurePrefs();
    final subject = prefs.getString(authSubjectKey);
    final displayName = prefs.getString(authDisplayNameKey);
    final expiresMs = prefs.getInt(authExpiresAtKey);
    if (subject == null || displayName == null || expiresMs == null) {
      return null;
    }
    return (
      subject: subject,
      displayName: displayName,
      email: prefs.getString(authEmailKey),
      idToken: prefs.getString(authIdTokenKey),
      accessToken: prefs.getString(authAccessTokenKey),
      refreshToken: prefs.getString(authRefreshTokenKey),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresMs),
      platformRole: prefs.getString(authPlatformRoleKey),
    );
  }

  static Future<void> _writeOrRemoveString(
    SharedPreferences prefs,
    String key,
    String? value,
  ) async {
    if (value == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value);
    }
  }
}

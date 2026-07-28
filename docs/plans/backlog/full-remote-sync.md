# Full remote data sync replacing mock assets

- **Status:** partial
- **Implemented so far:** [lib/data/repositories/remote_event_repository.dart](../../../lib/data/repositories/remote_event_repository.dart) plus the `dataSource` switch in [lib/core/config/runtime_config.dart](../../../lib/core/config/runtime_config.dart) already support a remote data source when configured.
- **Remaining:** Make remote the default source with mock as fallback (today mock is still primary), and cover the end-to-end sync/refresh + offline paths.
- **Problem:** Full remote data sync replacing mock assets is out of scope for the Enterprise Foundation Sprint.
- **Approach:** Capture requirements and promote when foundations (auth, API layer, i18n) are stable.
- **Depends on:** enterprise-foundation-sprint completion
- **Promotion criteria:** Product owner prioritizes; technical prerequisites met; Tier 1/2 validation plan exists.
- **Future plan slug:** `full-remote-sync`

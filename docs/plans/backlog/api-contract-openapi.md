# OpenAPI contract for remote event API

- **Status:** partial
- **Implemented so far:** [lib/core/network/api_client.dart](../../../lib/core/network/api_client.dart), [lib/data/repositories/remote_event_repository.dart](../../../lib/data/repositories/remote_event_repository.dart); typed HTTP client + remote event repository exist against an ad-hoc contract.
- **Remaining:** Formal OpenAPI/Swagger spec + generator to codify request/response schemas and auto-produce client models.
- **Problem:** OpenAPI contract for remote event API is out of scope for the Enterprise Foundation Sprint.
- **Approach:** Capture requirements and promote when foundations (auth, API layer, i18n) are stable.
- **Depends on:** enterprise-foundation-sprint completion
- **Promotion criteria:** Product owner prioritizes; technical prerequisites met; Tier 1/2 validation plan exists.
- **Future plan slug:** `api-contract-openapi`

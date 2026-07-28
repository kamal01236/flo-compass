# Discovery at scale

Flo Compass complements Accelevents — no registration, ticketing, check-in, badge printing, or official agenda CRUD. See [flo-compass-product.mdc](../../../.cursor/rules/flo-compass-product.mdc).

Ideas for cutting through ~640 parallel sessions for ~10K attendees.

Shipped discovery ideas (DS-001/002/004/005/006) are archived in [SHIPPED.md](SHIPPED.md).

---

### IDEA-DS-003 Learning paths by persona

- **Tier:** now
- **Status:** partial
- **Implemented so far:** six track paths in [assets/data/learning_paths.json](../../../assets/data/learning_paths.json).
- **Remaining:** persona paths ("First-time Flo", "Remote from Germany", ...).
- **Problem:** Generic learning paths do not match first-time Flo, remote EU, or hands-on lab personas.
- **Approach:** Add paths in `learning_paths.json`: “First-time Flo”, “Remote from Germany”, “Hands-on lab day”, “Leadership track”. Link from Discover and onboarding.
- **Touches:** `assets/data/learning_paths.json`, `lib/features/learning_path/learning_path_detail_screen.dart`, `lib/features/discover/discover_screen.dart`
- **Depends on:** IDEA-GA-002 for remote-specific paths
- **Related backlog:** none
- **Future plan slug:** `persona-learning-paths`
- **Out of scope (Accelevents):** none

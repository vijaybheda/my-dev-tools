# Claude Code Guidelines — Washy App

## ⚡ Universal Directive: Plan First For Every User Query
> **Core Mandate:** `"We should first plan for user query"`
> 
> Whenever a user sends a prompt from ANY AI Code Editor:
> 1. **Plan First:** The AI Agent MUST ALWAYS first analyze and formulate a plan for the user's query before modifying or creating code.
> 2. **Review Boundaries:** Inspect existing architecture, components (`COMPONENTS.md`), tokens (`AppColors`, `AppSpacing`, `AppStrings`, `AppTypography`), and affected files.
> 3. **Present Approach:** Outline the planned changes clearly so the user has complete visibility into what will be done.

---

## Toolchain & Coding Rules
- **Toolchain Execution:** ALWAYS use `fvm flutter ...` and `fvm dart ...` (NEVER run bare `flutter` or `dart`).
- **Code Generation:** Run `fvm dart run build_runner build --delete-conflicting-outputs` after changing models or assets.
- **Strict Rule on Tests:** AI agents MUST NEVER write, scaffold, or generate test cases.
- **Component Reuse:** Always inspect `COMPONENTS.md` and `lib/core/components/` first before creating new widgets.
- **Design Token Triad (`AppColors`, `AppSpacing`, `AppStrings`, `AppTypography`):**
  - **Colors:** Always use `AppColors`. Never write raw `Color(0x...)` hex literals outside `app_colors.dart`.
  - **Spacing:** Always use `AppSpacing` scalar tokens or presets. Never write raw numeric `EdgeInsets.fromLTRB(...)`, `symmetric(...)`, `all(...)`, or arbitrary `SizedBox` dimensions outside `app_spacing.dart`.
  - **Strings:** Always use `AppStrings` or `l10n/*.arb`. Never write hardcoded inline user-facing strings.
  - **Typography:** Always use `context.textTheme.*` or `AppTypography.*` with Google Fonts `DM Sans`. Never instantiate inline `TextStyle(...)`.
  - **Icons:** Always use custom SVGs via `Assets.icon.*`, `Assets.svg.*`, or `.toSvg()`. Framework icons (`Icons.*`, `CupertinoIcons.*`) are strictly prohibited.
- **Pre-Completion Audit Gate:** Run `git grep "Color(0x" lib/` and `git grep "fromLTRB(" lib/` to verify zero violations outside token files.
- **State Management:** BLoC / Cubit or `ValueNotifier`. `setState` is strictly forbidden.
- **Dedicated Separate Widget, 4-State Handling & RefreshIndicator for ListView:** Never use components or inline UI layouts inside `ListView`, `ListView.builder`, or `ListView.separated` without a dedicated separate `Widget` class for each list item (`_buildX()` helper methods prohibited). All list screens MUST support 4 visual states (Loading shimmer, Empty state, Error with retry, Populated). Lists MUST be wrapped in `RefreshIndicator` (`edgeOffset: 50.0`, `color: AppColors.primaryBlue`, `backgroundColor: AppColors.bgSecondaryDark`) with `physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())` and `clipBehavior: Clip.none`.
- **Navigation:** Direct widget navigation via `AppNavigator.push(...)` and context extensions (`context.pushScreen()`, `context.popScreen()`). Named routes and raw `Navigator.pop()` are prohibited.

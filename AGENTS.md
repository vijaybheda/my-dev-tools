# Comprehensive AGENTS.md — Washy App

AI coding agent instructions for this repository based on the mandatory [`flutter-sop/`](file:///Users/vijaybheda/Documents/development/f/washy/flutter-sop) architecture.

**Mandatory Read Order:** Read `sop.manifest.yaml`, `AGENTS.md`, and `SOP-CORE.md` before performing any task.

---

## ⚡ Universal Directive: Plan First For Every User Query
> **Core Mandate:** `"We should first plan for user query"`
> 
> Whenever a user sends a prompt from **ANY AI Code Editor** (Antigravity, Cursor, Windsurf, Claude Code, Copilot, VS Code AI, etc.):
> 1. **Plan First:** The AI Agent MUST ALWAYS first analyze and formulate a plan for the user's query before modifying or creating code.
> 2. **Review Boundaries:** Inspect existing architecture, components (`COMPONENTS.md`), tokens (`AppColors`, `AppTypography`), and affected files.
> 3. **Present Approach:** Outline the planned changes clearly so the user has complete visibility into what will be done.

---

## 1. Active SOP Modules

| Category | Active Module | Description / Standard |
|---|---|---|
| **Architecture** | `arch-layered-classic` / `arch-standard` | Layered boundary (Presentation, Domain, Data). UI never accesses HTTP/DB directly. |
| **State** | `state-bloc` | BLoC / Cubit pattern for state management. Business logic kept out of widgets. |
| **Navigation** | `nav-direct-widget` | Direct widget navigation via `AppNavigator`. Named routes are strictly forbidden. |
| **Release** | `release-manual` | Manual store release checklist and verification gates. |
| **Agents** | `agents-core` | Safe AI agent operations, planning discipline, and verification gates. |
| **Standards** | `coding-dart-flutter`, `env-flavors-secrets`, `logging-monitoring`, `api-integration` | Dart/Flutter coding rules, Dio API client, logging redaction, env config. |
| **Docs** | `living-docs` | Trigger-based documentation updates in the same change/PR. |

---

## 2. Toolchain Rules & Code Generation
- **Flutter & Dart Execution:** ALWAYS prefix shell commands with `fvm` (`fvm flutter ...`, `fvm dart ...`). NEVER run bare commands.
- **Code Generation (Mandatory):** Whenever models, serializable classes, or assets are added or modified, execute:
  ```bash
  fvm dart run build_runner build --delete-conflicting-outputs
  ```
- **Generated Files Protection:** Agents **MUST NOT** edit `*.g.dart`, `*.freezed.dart`, or generated asset files manually.

---

## 2.1 Strict Rule: Never Write Test Cases
Agents **MUST NEVER** write, scaffold, generate, or add test cases (unit tests, widget tests, integration tests, or regression tests) under any circumstances. Test authoring is strictly prohibited for AI coding agents. Verification relies exclusively on static code analysis (`fvm flutter analyze`), automated formatting (`fvm dart format .`), and manual flow verification on device/emulator.

---

## 2.2 Universal Anti-Static & Dynamic Development Mandate

This is a **universal, feature-agnostic engineering law** across the entire project. AI agents and developers **MUST NEVER** code static or hardcoded shortcuts under any circumstances:

1. **Zero Hardcoded or Static Data in UI:**
   - Hardcoding static strings, static lists, dummy arrays, or mock click actions inside UI widgets or controllers is **STRICTLY PROHIBITED**.
   - Every feature MUST receive its state through strongly-typed domain models and reactive streams (`Bloc`, `Cubit`, `ValueNotifier`).
2. **Anti-Primitive Obsession (Universal):**
   - Never represent business domain concepts with raw primitives (`String`, `double`, `int`, `Map<String, dynamic>`).
   - Complex domain attributes (e.g. addresses, coordinates, configurations, pricing breakdowns, time ranges) MUST be encapsulated in rich, strongly-typed immutable classes.
3. **Decoupled Action Contracts:**
   - UI widgets MUST NOT perform business mutations or direct screen-to-screen navigation in `onPressed`/`onTap` handlers.
   - UI widgets MUST only emit semantic action intents (e.g. BLoC Events / Cubit Intents). The business layer decides routing, validation, and side-effects.
4. **Universal Pre-API Implementation Pattern (Zero Mocks, Zero Tests):**
   - When an API endpoint is not yet available, agents **MUST NOT** create separate mock classes, mock files, or test cases.
   - Instead, simulate the endpoint directly inside the actual feature repository / remote data source using:
     ```dart
     // =========================================================================
     // TODO(api-integration): Replace simulated 2-second delay and static JSON
     // with live API endpoint: [METHOD] [ENDPOINT_PATH]
     // =========================================================================
     await Future.delayed(const Duration(seconds: 2));
     const rawJsonResponse = '''
     {
       "status": "success",
       "data": { ... }
     }
     ''';
     final jsonMap = jsonDecode(rawJsonResponse) as Map<String, dynamic>;
     final dto = ResponseDto.fromJson(jsonMap['data'] as Map<String, dynamic>);
     return dto.toDomain();
     ```
   - **Why:** This forces real JSON decoding, validates `@JsonSerializable` DTO mapping, and tests the UI's loading spinner and disabled buttons under realistic 2-second latency.
5. **Mandatory Standardized `TODO(api-integration)` Protocol:**
   - Whenever ANY static string, temporary JSON payload, simulated delay, or fallback stub is written anywhere in the codebase, the agent **MUST** add an explicit standardized comment:
     `// TODO(api-integration): Replace simulated 2s delay and static JSON with live API endpoint: [METHOD] [ENDPOINT]`
   - Leaving untagged static or dummy data in code is strictly prohibited.
6. **Universal 4-State UI Law:**
   - Every data-driven screen or component MUST explicitly handle and visually verify all 4 states:
     - **Loading State:** Skeleton shimmer via `AppStateViews.loading()` or button progress indicator.
     - **Empty State:** Illustrated empty view with actionable recovery via `AppStateViews.empty()`.
     - **Error State:** Human-readable error message with working `[Retry]` callback via `AppStateViews.error(onRetry: ...)`.
     - **Populated State:** Standard happy-path view.

---

## 2.3 Universal Mandate: ListView Development, 4-State Handling, Pull-to-Refresh & Scroll Guidelines
This is a **strict architectural law** across all screens, tabs, dialogs, and components containing list views:
1. **Parent Component 4-State Handling (Loading Shimmer, Error, Empty, Populated):**
   - The parent screen or container component for any `ListView` MUST explicitly handle all 4 visual states:
     - **Loading State:** Display a skeleton loading shimmer (e.g. `AppStateViews.loading()` or a dedicated shimmer placeholder view like `_ShimmerSkeleton`).
     - **Empty State (No Data):** Display an illustrated empty view with clear messaging and actionable recovery (e.g. `AppStateViews.empty()`). Must be wrapped in a scrollable `RefreshIndicator` container so pull-to-refresh works even when zero items exist.
     - **Error State:** Display a human-readable error message with a working `[Retry]` callback (e.g. `AppStateViews.error(onRetry: ...)`). Must be wrapped in a scrollable `RefreshIndicator` container.
     - **Populated State:** Display the populated list view.
2. **Mandatory Cross-Platform Pull-to-Refresh & TODO Protocol:**
   - Every list screen / list component MUST allow pull-to-refresh using the cross-platform template:
     ```dart
     RefreshIndicator(
       backgroundColor: AppColors.bgSecondaryDark,
       color: AppColors.brandPrimaryBlueDark,
       edgeOffset: 50.0,
       onRefresh: _onRefresh,
       child: SingleChildScrollView( // or ListView
         controller: _scrollController,
         physics: const BouncingScrollPhysics(
           parent: AlwaysScrollableScrollPhysics(),
         ),
         clipBehavior: Clip.none,
         padding: AppSpacing.screenPadding,
         ...
       ),
     )
     ```
   - If pull-to-refresh capability is not yet wired to a live backend endpoint, an explicit standardized comment **MUST** be added:
     `// TODO(api-integration): Implement pull-to-refresh handler for [Screen/Feature Name]`
3. **Proper Scroll Physics & Boundary Layout Behavior:**
   - **Bouncing Physics with Always-Scrollable Parent:** List views and scroll views wrapped inside a `RefreshIndicator` MUST use `physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())` so pull-to-refresh triggers reliably on both iOS and Android even when list items are few or empty.
   - **Unclipped Scrolling (`clipBehavior: Clip.none`):** Scroll views MUST specify `clipBehavior: Clip.none` to prevent boundary clipping of cards, shadows, and over-scroll effects.
   - **Header Offset (`edgeOffset: 50.0`):** `RefreshIndicator` MUST specify `edgeOffset: 50.0` (or appropriate header offset) so the spinner does not obscure top headers or app bars.
   - **Bottom Clearance Padding:** Provide adequate bottom spacing (`AppSpacing.bottomCtaPadding` or `90.0` FAB clearance) so the final list item is never cut off or obscured by floating action buttons or bottom navigation.
   - **Nested Scroll Handling:** For nested lists inside scrollable parents, use `CustomScrollView` with slivers (`SliverList`, `SliverPadding`), or set `shrinkWrap: true` + `physics: const NeverScrollableScrollPhysics()`.
4. **Dedicated Standalone Widget Class Required for ListView Items:**
   - Never use components or inline UI layouts inside `ListView`, `ListView.builder`, `ListView.separated`, or `SliverList` without a dedicated separate `Widget` class.
   - Every list item MUST be encapsulated in its own standalone `StatelessWidget` or `StatefulWidget` class (e.g. `ProviderBookingCard`, `_ServiceItemCard`, `_FilterChipItem`).
   - Placing raw multi-line components directly inside `itemBuilder` (e.g. `AppCard(child: Column(...))`) or delegating item construction to `Widget _buildX()` private helper methods inside `itemBuilder` is **STRICTLY FORBIDDEN**. Helper methods bypass Flutter element reconciliation, prevent `const` subtree caching, and cause unnecessary rebuild cascades during scrolling.

---

## 2.4 Universal Anti-Sycophancy & Critical Failure Mode Mandate

This is a **mandatory engineering law** across all thinking, planning, and coding phases:

1. **Zero Sycophancy Policy (Anti-Validation):**
   - AI agents MUST NEVER default to uncritical agreement ("Great idea!", "That makes sense!") or blindly execute technically flawed approaches.
   - If a proposed design, architecture, or prompt assumption carries hidden risks, performance issues, or SOP violations, the agent **MUST** explicitly highlight the failure modes and present an SOP-compliant alternative.
2. **Mandatory Adversarial Audit in Phase 1 (Thinking & Planning):**
   - Every Implementation Plan MUST include a dedicated `## Adversarial Analysis & Failure Modes` section before presenting the plan to the user.
   - The agent MUST actively play devil's advocate against its own plan, identifying:
     - **Fragile Assumptions & Weakest Links:** Where will this architecture fail under stress?
     - **Unhandled Edge Cases & Race Conditions:** Network disconnects, state desync, concurrency issues.
     - **Performance Bottlenecks:** Unnecessary widget rebuilds, unbounded lists, un-isolated heavy computations.
3. **Rigorous Defensive Coding in Phase 2 (Execution):**
   - Agents MUST NEVER write quick, fragile, or lazy code (such as bang force-unwraps `!`, swallowed exceptions, raw string/hex literals, or missing loading/error states) just to satisfy a prompt quickly.
   - Every boundary (API parsing, state emissions, storage, user inputs) MUST be defensively guarded.

---

## 3. Data Models, Serialization & Equality Standards

Every Data Model (DTO) and Domain Entity in the project **MUST** strictly adhere to the following architecture:

1. **JSON Serialization (`json_serializable`):**
   - Annotate class with `@JsonSerializable(explicitToJson: true)`.
   - Add part file declaration: `part '<filename>.g.dart';`.
   - Implement constructor and factory:
     ```dart
     factory ModelName.fromJson(Map<String, dynamic> json) => _$ModelNameFromJson(json);
     Map<String, dynamic> toJson() => _$ModelNameToJson(this);
     ```
2. **Value Equality (`Equatable`):**
   - Extend `Equatable`.
   - Override `@override List<Object?> get props => [field1, field2, ...];`.
3. **Absolute Immutability:**
   - All fields **MUST** be declared `final`.
   - Implement a `copyWith(...)` method on every domain model.
4. **No Raw Map / JSON Leaks:**
   - Raw JSON maps (`Map<String, dynamic>`) **MUST NOT** cross the Repository boundary into Presentation / BLoC / UI layers. Always parse into strongly-typed models.

---

## 4. Asset Management Standards

1. **Zero Hardcoded Asset Strings:**
   - Raw inline string paths (e.g. `'assets/images/car.png'`) are **STRICTLY PROHIBITED** inside widgets.
   - Reference all assets via centralized constants (e.g. `AppAssets.carPlaceholder`) or generated asset classes.
2. **Bounded Network Images:**
   - Network images **MUST** use caching (`FastCachedNetworkImage` / `CachedNetworkImage`), explicit dimensions, placeholders, and error fallbacks (`AppCachedImage`).

--## 5. Design System: Mandatory Tokenization Triad (`AppColors`, `AppSpacing`, `AppStrings`, `AppTypography`)

1. **36-Token Color System (`AppColors` — Strict Zero Hex Rule):**
   - All colors **MUST** come from [`lib/core/theme/app_colors.dart`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/theme/app_colors.dart) (Brand, Background, Border, Text, CTA, Status).
   - Hardcoded hex literals (e.g. `Color(0xFF...)`) inside UI screens, widgets, cards, dialogs, or controllers are **STRICTLY FORBIDDEN**.
   - If a Figma CSS snippet introduces a new hex value (e.g. `background: #0D1B2A;`), NEVER paste `Color(0xFF0D1B2A)` into widget code. Map it to an existing `AppColors` token or add a semantic token to `app_colors.dart` first.
2. **Layout Spacing & Dimensions (`AppSpacing` — Strict Zero Raw EdgeInsets Rule):**
   - Writing raw numeric padding, margins, or SizedBox offsets (e.g. `EdgeInsets.fromLTRB(16, 8, 16, 16)`, `EdgeInsets.symmetric(horizontal: 16, vertical: 12)`, `EdgeInsets.all(8)`, `SizedBox(height: 16)`) is **STRICTLY FORBIDDEN**.
   - All padding, margins, gaps, and dimensions MUST use `AppSpacing.*` scalar tokens (`AppSpacing.xxs`, `AppSpacing.xs`, `AppSpacing.sm`, `AppSpacing.md`, `AppSpacing.lg`, `AppSpacing.xlg`, `AppSpacing.xxlg`, etc.) or preset geometries (`AppSpacing.screenHorizontal`, `AppSpacing.screenPadding`, `AppSpacing.bottomCtaPadding`, `AppSpacing.cardPadding`, `AppSpacing.chipPadding`, `AppSpacing.modalPadding`, `AppSpacing.gapVerticalMd`, etc.) from [`lib/core/theme/app_spacing.dart`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/theme/app_spacing.dart).
3. **Strings & Localization (`AppStrings` — Strict Zero Inline String Rule):**
   - Hardcoded user-facing strings, button labels, screen titles, subtitles, input labels, hint placeholders, chip labels, dialog messages, or error toasts directly in widgets are **STRICTLY PROHIBITED**. Use `AppStrings` (`lib/core/constants/app_strings.dart`) or `l10n/*.arb`.
4. **Typography & Font Rules (`AppTypography`):**
   - All text styles **MUST** use Google Fonts `DM Sans` via `AppTypography` or `Theme.of(context).textTheme`.
   - Inline `TextStyle(...)` instantiations are **STRICTLY PROHIBITED**.
5. **No Default Framework Icons:**
   - Default framework icons (`Icons.*`, `CupertinoIcons.*`) are **STRICTLY PROHIBITED** across all components and screens. All icons **MUST** use custom SVGs / vector assets managed via generated asset getters (`Assets.icon.*`, `Assets.svg.*`) or `.toSvg()` extensions.
6. **Automated Grep Auditing Gate (Phase 3 Mandatory Verification):**
   - Before completing any UI or feature task, the AI agent MUST run:
     - `git grep "Color(0x" lib/` (Must return 0 results outside `app_colors.dart`)
     - `git grep "fromLTRB(" lib/` (Must return 0 results outside `app_spacing.dart`)
     - Any violation MUST be resolved before declaring completion.

---

## 6. Mandatory Component Reuse & Safe Extension Policy

To maintain visual consistency, prevent code duplication, and adhere strictly to the Figma design system:

1. **Always Check Existing Components First:**
   - Whenever any prompt or task involves creating or modifying UI screens, widgets, modals, forms, or controls, the AI agent **MUST FIRST** consult [`COMPONENTS.md`](file:///Users/vijaybheda/Documents/development/f/washy/COMPONENTS.md) and inspect [`lib/core/components/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components).
   - Re-implementing custom buttons, text fields, cards, chips, dialogs, progress bars, or state views from scratch is **STRICTLY PROHIBITED**.
2. **Direct Usage & Composition:**
   - Use the existing component directly whenever possible (e.g. `AppButton.primary`, `AppTextField.password`, `AppCard.provider`, `AppChip.timeSlot`, `AppBottomSheet.show`, `AppStepIndicator`, `AppPagerIndicator.diamond`, `AppStatusBadge`, `AppImageView`, `AppUploadAvatar`, `AppStateViews`).
3. **Safe Alteration & Extension Rules:**
   - If a new UI requirement or variant is needed, **SAFELY ALTER / EXTEND** the existing component rather than creating a duplicate or ad-hoc widget.
   - **Backwards Compatibility:** Never break existing constructors or default parameter values used across other screens.
   - **Named Constructors:** Add a clean named constructor (e.g. `AppButton.myNewVariant(...)`) for new standardized design system presets.
   - **Parameter Documentation:** Whenever a component is altered or extended, the agent **MUST** immediately update the component's [`README.md`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components) and [`COMPONENTS.md`](file:///Users/vijaybheda/Documents/development/f/washy/COMPONENTS.md) in the same change.

---

## 7. Component Documentation Standard (`README.md` Rules)

Every component under `lib/core/components/` MUST maintain a dedicated `README.md` formatted with:
1. **Comprehensive Parameter Usage Reference Table:**
   - Columns: `Parameter`, `Type`, `Default Value`, `Required / Optional Status`, and `Description & Behavior`.
2. **Constructors & Named Variants Breakdown:**
   - In-depth documentation of default and all named constructors, listing preset values, locked behaviors, and specific use cases.
3. **"How We Can Use" Guide:**
   - Practical step-by-step integration examples (state binding with `ValueNotifier`/BLoC, form validation, theme tokens, controller lifecycles).
   - *Generic or shallow examples without parameter descriptions are prohibited.*

---

## 8. Mandatory 5-Phase Agent Workflow

### Phase 0: Manifest & Intake
1. Read [`flutter-sop/sop.manifest.yaml`](file:///Users/vijaybheda/Documents/development/f/washy/flutter-sop/sop.manifest.yaml) for active modules and pinned toolchain.
2. Read [`flutter-sop/sop/SOP-CORE.md`](file:///Users/vijaybheda/Documents/development/f/washy/flutter-sop/sop/SOP-CORE.md) for core boundaries.
3. Consult [`COMPONENTS.md`](file:///Users/vijaybheda/Documents/development/f/washy/COMPONENTS.md) for reusable UI building blocks.

### Phase 1: Thinking & Planning (*Architect / Plan Mode*)
1. Inspect [`flutter-sop/FEATURE_MAP.md`](file:///Users/vijaybheda/Documents/development/f/washy/flutter-sop/FEATURE_MAP.md) to locate feature code and routes.
2. Check [`flutter-sop/DECISIONS.md`](file:///Users/vijaybheda/Documents/development/f/washy/flutter-sop/DECISIONS.md) to review past ADRs.
3. Write a complete Markdown Implementation Plan covering: Overview, Architecture Decisions, File-by-File Changes, **Adversarial Analysis & Failure Modes (Mandatory Devil's Advocate Audit)**, Dependency Justifications, and Rollback Plan.
4. **STOP and wait for user approval** before writing implementation code. *(Exception: Minor UI tweaks ≤3 files may fast-track directly to implementation per §7).*

### Phase 2: Implementation (*Code Mode*)
1. Scope code changes strictly to the approved files in the plan.
2. **Enforce Defensive Anti-Sycophantic Code:** Zero `!` force-unwraps, zero swallowed errors, zero lazy static placeholders without `// TODO(api-integration): ...`.
3. Keep UI widgets pure; offload state to BLoCs or reactive ValueNotifiers.
4. Maintain immutable models with `@JsonSerializable()` and `Equatable`.
5. Run `fvm dart run build_runner build --delete-conflicting-outputs`.

### Phase 3: Verification (*Verification Mode*)
1. Zero Test Cases Rule: Agents MUST NEVER write, scaffold, or add test cases.
2. Static Analysis: `fvm flutter analyze` MUST return 0 errors and 0 warnings.
3. Formatting: `fvm dart format .`.
4. Automated Grep Audits: Run `git grep "Color(0x"` and `git grep "fromLTRB("` to confirm zero violations outside token files.
5. Existing Tests: Verify existing tests pass if executed (`fvm flutter test`), without authoring new tests.
6. Verify Loading, Empty, Error, and Offline states on an emulator or device.

### Phase 4: Living Docs & Definition of Done
1. Update `CHANGELOG.md` under `## [Unreleased]` in user-facing language.
2. Update `TASKS.md` and `FEATURE_MAP.md` if feature structure changes.
3. Complete full Definition of Done checklist.

---

## 7. UI-Only Task Guidelines

For tasks focused purely on **UI presentation** (styling, layout, widget extraction, animations, fixing pixel overflows):

1. **Mandatory Pixel-Perfect UI Markdown Blueprint & Approval:**
   - Whenever the user requests UI implementations or UI modifications, the AI agent **MUST FIRST** present the planned UI layout breakdown, component hierarchy, design tokens (`AppColors`, `AppSpacing`, `AppTypography`), reusable components from `COMPONENTS.md`, and 4 visual states in **Markdown format**.
   - Implementation code **MUST NOT** be written until the user reviews and provides explicit approval for the Markdown UI blueprint.
   - If the user requests modifications, the AI agent must update the Markdown layout specification iteratively until full user approval is granted. The primary goal is achieving **pixel-perfect, proper UI implementation** aligned with design specifications.
2. **Widget Pure Presentation:** Business logic, HTTP calls, and DB operations are strictly forbidden inside widgets.
3. **Widget Extraction:** Extract standalone `Widget` classes when `build()` exceeds ~80 lines or nests >5 levels deep. Do NOT use `Widget _buildX()` methods.
4. **Four Visual States:** UI must support **Loading**, **Empty**, **Error** (with retry button), and **Offline** states.
5. **Accessibility & Responsive:**
   - Minimum tap target: **48×48 dp**.
   - Must survive **1.3× text scale** without pixel overflow.
   - Semantics labels for icon-only buttons.
   - **No `setState` Usage:** `setState` is STRICTLY FORBIDDEN. Manage UI state reactively using `ValueNotifier` / `ValueListenableBuilder`, `Bloc`, or `Cubit`.

---

## 8. Hard Safety Boundaries (Forbidden Actions)

Agents **MUST NOT**:
- **Write Test Cases:** Agents **MUST NEVER** write, scaffold, generate, or add test cases (unit tests, widget tests, integration tests, or regression tests) under any circumstances.
- **Write Raw `Color(0x...)` Hex Literals:** Hex literals outside `lib/core/theme/app_colors.dart` are strictly prohibited.
- **Write Raw Numeric `EdgeInsets` or Arbitrary `SizedBox` Dimensions:** Ad-hoc numeric padding/spacers outside `lib/core/theme/app_spacing.dart` are strictly prohibited.
- **Write Inline User-Facing Strings:** Hardcoded UI strings outside `lib/core/constants/app_strings.dart` / `l10n/*.arb` are strictly prohibited.
- **Code Static / Hardcoded Shortcuts:** Hardcoding static strings, dummy lists, or fake click handlers inside UI widgets or controllers is strictly forbidden.
- **Write Untagged Temporary Data:** Writing simulated delays, static JSON payloads, or fallback stubs without a standardized `// TODO(api-integration): ...` comment is strictly forbidden.
- **Write Separate Mock Classes:** Creating standalone mock classes, mock repositories, or mock files is strictly forbidden. Always use in-place simulated 2-second JSON string decoding through real DTOs in the actual repository.
- **Never Use Default Framework Icons:** Using default `Icons.*` or `CupertinoIcons.*` across any component or screen is strictly prohibited. All icons MUST use custom SVG vector assets via generated `Assets` class (`lib/gen/assets.gen.dart`).
- **Use AppNavigator for All Navigation & Pops:** Direct low-level `Navigator.pop()`, `Navigator.of(context).pop()`, `Navigator.push()`, or `Navigator.of(...)` calls outside `AppNavigator` implementation are STRICTLY FORBIDDEN. All screen pushes, replacements, and pops MUST use `AppNavigator` static methods (`AppNavigator.pop`, `AppNavigator.push`, `AppNavigator.canPop`) or convenience `BuildContext` extensions (`context.pushScreen`, `context.popScreen`, `context.popDialog`). Named routes (`context.pushNamed`, `context.goNamed`) and raw string URL paths are strictly forbidden.
- **Use Raw Strings for User Roles:** User roles MUST ALWAYS use the canonical `UserRole` enum (`lib/core/enums/user_role.dart`) across the codebase (storage, widget parameters, flow conditions). Raw strings (`'customer'`, `'provider'`) are prohibited.
- **Context Extensions & TextTheme:** Prefer `context.textTheme` (`lib/core/extensions/extensions.dart`), `context.theme`, and `context.colorScheme` over static `AppTypography` getters for widgets in the build tree. Use `context.showSuccessSnackBar()` and `context.showErrorSnackBar()` for feedback.
- **Build-Runner Asset Generation:** Access assets via generated `Assets` class (`lib/gen/assets.gen.dart`) and string vector extensions (`Assets.icon.underMaintenance.toSvg()`). Hardcoded asset path strings in widgets are strictly prohibited.
- **Never Use Components or Inline Trees Without Separate Widget, 4-State Handling & RefreshIndicator for ListView:** Using components directly or inlining multi-line widget trees / `Widget _buildX()` helper methods inside `ListView`, `ListView.builder`, or `ListView.separated` without a dedicated standalone `Widget` class is STRICTLY FORBIDDEN. All list screens MUST support 4 visual states (Loading shimmer, Empty state, Error with retry, Populated). Lists MUST be wrapped in `RefreshIndicator` (`edgeOffset: 50.0`, `color: AppColors.primaryBlue`, `backgroundColor: AppColors.bgSecondaryDark`) with `physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())` and `clipBehavior: Clip.none`.
- Touch keystores, `.env` with real secrets, CI workflows, signing blocks, or `ios/Runner.xcodeproj`.
- Modify `pubspec.lock` manually or add dependencies to `pubspec.yaml` without explicit justification and user approval.
- Execute destructive shell commands (`rm -rf`, `git reset --hard`, force push, database drop/migrations).
- Swallow exceptions with bare `try {} catch (_) {}` or use `!` bang assertions without justification.
- Ship `print()` statements or log tokens, passwords, PII, or headers.
- Skip Phase 1 Planning for any non-UI task affecting >3 files or adding a feature.

---

## 9. Definition of Done Checklist

- [ ] Code matches active modules in `sop.manifest.yaml`.
- [ ] Models use `@JsonSerializable(explicitToJson: true)` and extend `Equatable`.
- [ ] Code generation executed via `fvm dart run build_runner build --delete-conflicting-outputs`.
- [ ] Static analysis `fvm flutter analyze` returns 0 errors and 0 warnings.
- [ ] Formatting `fvm dart format .` applied.
- [ ] Automated grep audits clean (`git grep "Color(0x"` and `git grep "fromLTRB("` return 0 results outside token files).
- [ ] Existing tests pass cleanly if executed (`fvm flutter test`).
- [ ] Zero test cases written or generated (agents must never write test cases).
- [ ] UI handles Loading, Empty, Error, and Offline states.
- [ ] Living documentation (`CHANGELOG.md`, `TASKS.md`, `FEATURE_MAP.md`) updated in the same change.

---

## 10. Autonomous Intent Detection & Silent Adaptability

The user will **NEVER** be required to specify intent tags or project types—they will simply ask what they need directly in plain, natural language.

The AI Editor **MUST AUTOMATICALLY DEDUCE** the intent from the user's prompt, silently adapt to the project environment, and **ALWAYS output the following clean badge as the very first line of every response**:

```markdown
> **Intent Detected:** `[<Intent>]` — <Brief boundary & execution summary>
```

### 10.1 The Core Developer Intents (Autonomous Classification)
1. **`[Add New]`**: User wants a new feature, screen, component, or domain flow. Full layered architecture, immutable models, 4 UI states, checks `COMPONENTS.md` first.
2. **`[UI Polish]`**: User wants visual styling, Figma alignment, spacing, continuous squircle smoothing, micro-animations. **Strictly presentation only** (zero changes to models, APIs, repositories, or BLoC logic).
3. **`[Integration]`**: User wants third-party SDKs (Firebase, Stripe, Maps), hardware permissions, or native configs (Gradle, Info.plist). Enforces least-privilege security.
4. **`[Bug Fix]`**: User reports a defect, crash, overflow, or desync. Fixes root cause (**NEVER write test cases**; agents must never write test cases) + closes issue in `KNOWN_ISSUES.md`.
5. **`[Refactor]`**: User asks for cleanup, widget extraction, tech debt reduction. **Behavior-preserving rule**: zero changes to public APIs or observable behavior.
6. **`[Remove]`**: User asks to delete obsolete features, dependencies, or dead code. Blast-radius search + persistence check + **moves feature to `## Retired` in `FEATURE_MAP.md`**.
7. **`[Investigate]`**: User asks why something happens, where code lives, or to diagnose an issue. **STRICTLY ZERO CODE MODIFICATION**. Returns diagnostic findings and options first.
8. **`[Performance]`**: User reports lag, frame drops, memory leaks. Image decode bounding (`ResizeImage`), controller/stream disposal, isolate offloading (`compute()`).
9. **`[Critique]`**: User asks for harsh review, architectural challenge, or devil's advocate analysis. **STRICTLY ZERO VALIDATION**. Identifies weakest links, failure modes, scale bottlenecks, unhandled state transitions, and presents counterarguments.
*(Bonus: **`[Release]`**: Version bump, store audit, changelog promotion).*

### 10.2 Silent Project Environment Adaptability
- **AI-Native with SOP (e.g. Washy):** Strictly enforce SOP layering, reuse `COMPONENTS.md`, and update living docs (`CHANGELOG.md`, `TASKS.md`, `FEATURE_MAP.md`) in the same change.
- **Existing Human-Built Codebase (Riverpod/Provider/GetX/MVC):** Silently respect existing state management, keep diffs surgical, match existing conventions, and do not create unwanted markdown files.
- **Greenfield (New Project):** Setup clean foundational architecture and design tokens from Day 0.



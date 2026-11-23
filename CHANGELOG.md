# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Central Auth & Screen State Management (`AuthCubit` & `AuthState`)**:
  - Implemented central `AuthCubit` (`lib/features/auth/presentation/cubit/`) with `AuthState` managing user authentication status (`unauthenticated`, `authenticating`, `authenticated`), active role (`customer` vs `provider`), and provider approval status (`setupRequired`, `pendingApproval`, `needsChanges`, `approved`).
  - Added provider approval status and profile setup completion persistence methods to `LocalStorageService` (`saveProviderApprovalStatus`, `getProviderApprovalStatus`, `saveProviderSetupCompleted`, `isProviderSetupCompleted`).
  - Integrated `AuthCubit` into root `MultiBlocProvider` in `main.dart` with splash initialization logic that routes users to `WelcomePage`, `CustomerHomePage`, `ProviderSetupPage`, `ProviderApprovalStatusPage`, or `ProviderDashboardPage` based on persisted auth and approval state.
  - Connected `welcome_page.dart`, `onboarding_page.dart`, `login_page.dart`, `register_page.dart`, `forgot_password_page.dart`, `reset_password_page.dart`, `provider_setup_page.dart`, and `provider_approval_status_page.dart` to `AuthCubit` for unified state handling and deterministic role/status-based navigation.

### Fixed
- **AppTextField & AppTopGradientBackground Material Ancestor Fix**:
  - Resolved `No Material widget found` runtime assertion error by encapsulating `AppTextField` and `AppTopGradientBackground` inside a transparent `Material` widget (`MaterialType.transparency`), ensuring text fields and selection toolbar interactions always locate a Material ancestor in the element tree regardless of parent layout wrappers.

### Added
- **Skeletonizer Loading Shimmer Integration (`skeletonizer: ^2.1.3` & `AppSkeletonizer`)**:
  - Installed and integrated the `skeletonizer` package for 1:1 exact matching loading shimmer skeletons across list screens and UI components.
  - Implemented `AppSkeletonizer` centralized wrapper component in `lib/core/components/skeleton/app_skeletonizer.dart` with dark mode shimmer effect (`baseColor: AppColors.bgSecondaryDark`, `highlightColor: AppColors.borderStrongDark`).
  - Refactored loading views in `MyServicesShimmerSkeleton`, `NotificationsShimmerView`, `ProviderBookingsTabView`, and `ProviderEarningsTabView` to wrap actual UI card components (`MyServiceListItemCard`, `NotificationItemCard`, `ProviderBookingCard`, `ProviderPayoutCard`) in `AppSkeletonizer`, replacing generic circular spinners with true 1:1 layout shimmer representations matching live data layouts.
- **Backend Data Models, Enums & Request DTO Integration (`lib/core/enums/` & `lib/core/models/`)**:
  - Implemented 14 strongly-typed backend enums matching `APP_MODELS_AND_ENUMS.md`: `UserTypeEnum`, `AppTypeEnum`, `PlatformTypeEnum`, `CustomerStatusEnum`, `ProviderStatusEnum`, `ProviderKycStatusEnum`, `ProviderServiceStatusEnum`, `ServiceCategoryStatusEnum`, `DayOfWeekEnum`, `BookingStatusEnum`, `PaymentStatusEnum`, `CommissionTypeEnum`, `CmsPageSlugEnum`, `CmsPageTypeEnum`.
  - Implemented canonical domain models and sub-schemas with `@JsonSerializable(explicitToJson: true)` and `Equatable`: `ApiResponse<T>`, `ApiError`, `CustomerModel`, `CustomerVehicleModel` (with safe dynamic integer/string `vehicleType` parser), `CustomerAddressModel`, `GeoPointModel`, `ProviderModel`, `ProviderServiceModel`, `ProviderAvailabilityModel`, `DayScheduleModel`, `BookingModel`, `ProviderSnapshotModel`, `ServiceSnapshotModel`, `VehicleSnapshotModel`, `AddressSnapshotModel`, `PricingSnapshotModel`, `BookingReviewModel`, `DefaultConfigurationModel`, `AppVersionModel`, `CmsPageModel`.
  - Implemented client request DTOs in `lib/core/models/requests/`: `CustomerSignupRequest`, `CustomerLoginRequest`, `CustomerProfileUpdateRequest`, `DeviceTokenRequest`, `CreateVehicleRequest`, `CreateAddressRequest`, `ProviderSetupRequest`, `CreateProviderServiceRequest`, `UpdateProviderAvailabilityRequest`, `CreateBookingRequest`, `UpdateBookingStatusRequest`.
  - Updated existing core and feature models (`BaseApiResponse`, `DefaultConfigData`, `ProviderServiceDto`, `ProviderBookingEntity`) with backwards-compatible converters and calculated getters for zero-breakage UI integration.

### Changed
- **ListView Development, 4-State Handling, Pull-to-Refresh & Scroll Physics Governance Rules**:
  - Formally codified and updated the mandatory ListView Development Mandates across all repository agent rules and SOP governance documents (`AGENTS.md`, `flutter-sop/AGENTS.md`, `coding-dart-flutter.md`, `.cursorrules`, `.windsurfrules`, `CLAUDE.md`).
  - Mandated the cross-platform `RefreshIndicator` template (`edgeOffset: 50.0`, `color: AppColors.primaryBlue`, `backgroundColor: AppColors.bgSecondaryDark`, `clipBehavior: Clip.none`, `physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())`).
  - Mandated 4-state visual handling (Loading shimmer loader, `AppEmptyView`, `AppErrorView` with retry, Populated state) and required wrapping empty/error states inside scrollable `RefreshIndicator` containers for pull-to-refresh accessibility on zero-item screens.
  - Upgraded all list screens (`CustomerHomePage`, `MyBookingsPage`, `MyServicesPage`, `ProviderEarningsPage`, `ProviderBookingsTabView`, `ProviderDashboardTabView`, `ProviderEarningsTabView`, `MyReviewsPage`) to 100% SOP Rule 2.3 & 2.4 compliance.
  - Added standardized `// TODO(api-integration): Implement pull-to-refresh handler for [Screen]` tags where live endpoint wiring is pending.
- **Unified Header & Back Button Architecture (`AppTopGradientBackground` & `AppBackButton`)**:
  - Refactored `AppAppBar` to consistently render `AppBackButton` (or `AppBackButton.iconOnly`) whenever `showBackButton: true` is configured, preventing missing back buttons and resolving duplicate/overlay back button rendering.
  - Standardized screen headers across `BookingDetailPage`, `CreateEditServicePage`, `CmsPage`, `ContactUsPage`, and `MyServicesPage` to use `AppTopGradientBackground.header(...)`, eliminating custom manual back button rows and ensuring edge-to-edge status bar integration.
- **Notification Item Card Check Icon (`NotificationItemCard`)**:
  - Replaced framework `Icons.check` icon in `_buildLeadingBadge()` with the vector asset `Assets.svg.icNotificationCheck.toSvg()` (`assets/svg/ic_notification_check.svg`).
- **Notifications Empty View Asset (`NotificationEmptyView`)**:
  - Replaced custom coffee mug painter illustration with the official `Assets.svg.noNotification.toSvg()` vector SVG asset (`assets/svg/no_notification.svg`).
  - Removed obsolete `CoffeeMugIllustration` widget and cleaned up barrel exports.
- **Provider Dashboard Profile & Settings Icons (`ProviderMoreTabView` & `AppChevronRightIcon`)**:
  - Replaced `CustomPaint` chevron right painter in `AppChevronRightIcon` with the dedicated vector asset `Assets.svg.rightArrow.toSvg()`.
  - Replaced placeholder SVG icons in `ProviderMoreTabView` menu options with their exact corresponding asset SVGs (`myService`, `availability`, `myReview`, `changePassword`, `aboutWashy`, `contactUs`, `terms`, `privacy`).
- **Login Page Typography (`login_page.dart`)**:
  - Aligned subtitle typography to Figma specifications (`fontSize: 18`, inheriting default `w400` weight from `context.textTheme.bodyLarge`).
  - Aligned `forgotPassword` text link typography to Figma specifications (`fontSize: 18`, inheriting `w500` weight from `context.textTheme.titleMedium`).
  - Aligned `dontHaveAccountSignUp` soft button typography to Figma specifications (`fontSize: 18`, `fontWeight: FontWeight.w600` SemiBold via `context.textTheme.titleLarge`).
  - Excluded explicit `height` and `line-height` properties across all text components.
- **Mobile Build & Release Engine (`build.sh`)**:
  - Upgraded build CLI engine with **Session Memory Persistence** (`.build_last_session.conf`), saving build parameters and allowing 1-click **Fast Deploy** rerun mode.
  - Implemented **Smart Prefilled & Character-by-Character Editable Version Engine** (`read_editable_line`), supporting baseline version retention, build number auto-incrementing (`increment_build_number`), and interactive version string editing.
  - Decoupled sensitive credentials into an auto-generated external configuration file ([`.build-config.env`](file:///Users/vijaybheda/Documents/development/f/washy/.build-config.env)) with auto-detection of `.p8` and `google-play*.json` files.
  - Added Google Workspace CLI (`gws`) integration flags (`--integrate-gdrive`, `--deintegrate-gdrive`) and automated public/download link generation for Google Drive uploads.
  - Enhanced Washy branding, ASCII welcome banner, step progress indicators, and actionable human error diagnostic cards.
  - Maintained full compatibility with `fvm flutter` toolchain and native flavors (`dev`, `staging`, `prod`, `ngrok`).
- **Contact Us Background Stack Graphic (`ContactUsPage`)**:
  - Replaced placeholder custom painter silhouette with the authentic asset `contact_us_bg_img.png` in the background `Stack`.
  - Positioned the asset at the bottom edge (`bottom: 0`) spanning edge-to-edge horizontally with `BoxFit.fitWidth` wrapped in `IgnorePointer` to form an authentic second-half water splash backdrop behind contact cards without obstructing touch events.
  - Standardized screen spacing and string tokens using `AppSpacing` and `AppStrings`.

### Added
- **Provider More Tab Features (`ManageProfilePage`, `MyReviewsPage`, `ChangePasswordPage`, `AppStarWidget`)**:
  - Built `AppStarWidget` (`AppStarRatingBar`) reusable rating component with circular badge mode, custom fill/unfilled colors, rating score clamping (0.0 to 5.0), and `Assets.svg.star.toSvg()` vector assets.
  - Implemented `MyReviewsPage` featuring top summary rating card (4.8 score, 5 circular green star badges, "Based on 108 reviews") and review list items built with dedicated `MyReviewListItemCard` component.
  - Implemented `ManageProfilePage` with sub-tab navigation (`Basic Info`, `Documents`, `Service Photos`), form input controls, base location field, removable service area tags with `AppChip.filterRemovable`, and 52px blue pill submit CTA ("Save Changes").
  - Implemented `ChangePasswordPage` with `AppTextField.password` input fields for Current Password, New Password, and Confirm Password with eye obscure toggles, and 52px blue pill submit CTA ("Update Password").
  - Integrated default navigation handlers in `ProviderMoreTabView` linking Profile header and Menu tiles to push `ManageProfilePage`, `MyReviewsPage`, and `ChangePasswordPage` via `AppNavigator`.
- **Top Gradient Header Extension (`AppTopGradientBackground.header`)**:
  - Added named constructors `AppTopGradientBackground.header(...)` and `AppTopGradientBackground.withHeader(...)` combining top gradient background canvas with a built-in header bar.
  - Added support for optional/nullable header parameters (`title`, `titleWidget`, `showBackButton`, `showBackText`, `onBackPressed`, `actionWidget`, `actions`, `leading`, `centerTitle`) across all constructors and `WidgetGradientExtension` methods (`.withTopGradient()`, `.withAppBarGradient()`, `.withDashboardGradient()`).
  - Added `actionWidget` single property support alongside `actions` list for maximum developer ergonomics.
  - Updated documentation in [`lib/core/components/gradient_background/README.md`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/gradient_background/README.md).

- **Provider Booking Detail Page & Navigation Suite (`BookingDetailPage`)**:
  - Implemented pixel-perfect **Booking Detail Page (`BookingDetailPage`)** conforming to Figma CSS specifications (`booking_detail.txt` & `booking_detail_scenario_2.txt`).
  - Features dual address presentation handling: **Scenario 1 (New Request)** displays blurred address text (`ImageFiltered`) with an *"Accept to view"* indicator; **Scenario 2 (Confirmed / In Progress)** displays unblurred address text with a *"Get Direction"* map launcher link.
  - Features `#16273A` squircle card container with dashed line separators (`#3E5878`), reference code header (`WB-1001`), colored status badge, and dynamic action CTAs (Accept/Reject, Start Service, Mark Completed).
  - Linked all `ProviderBookingCard` widgets across Provider Dashboard and Bookings tabs to push `BookingDetailPage` on tap.
  - Linked `ProviderMoreTabView` menu items ("My Services", "Availability", "Contact Us", "Terms & Conditions", "Privacy Policy") to open their respective target feature screens.

- **Provider Service Management Feature Suite (`lib/features/provider/services/`)**:
  - Implemented unified **Create / Edit Service Screen (`CreateEditServicePage`)** supporting form creation and live editing with title, category dropdown, price stepper (`ServicePriceStepper`), duration stepper (`ServiceDurationStepper`), description field, and dynamic CTA button color animation (`#1F4373` -> `#3D8BFF`).
  - Implemented **My Services Dashboard Screen (`MyServicesPage`)** featuring active services count badge, bottom floating "+ Add New Service" CTA button, and 4 visual UI lifecycle states (Loading, Empty, Error, Populated).
  - Built dedicated **`MyServiceListItemCard`** list item widget with continuous Figma squircle geometry (0.6 smoothing), category chip, price/duration badges, active toggle switch, edit button, and delete action button.
  - Implemented **`MyServicesShimmerSkeleton`** pulse shimmer skeleton for granular loading state visualization without external dependencies.
  - Implemented **Delete Service Confirmation Modal (`DeleteServiceBottomSheet`)** with red starburst warning icon (`Assets.svg.filledZigzagCircular`), active bookings check, and delete confirmation action.
  - Implemented **Delete Service Blocked Warning Modal (`DeleteServiceFailedBottomSheet`)** displaying yellow warning icon (`Assets.icon.underMaintenance`) when service deletion is restricted due to active customer bookings.
  - Implemented strongly-typed entity (`ProviderServiceEntity`), DTO model (`ProviderServiceDto`), repository interface (`ProviderServicesRepository`), and simulated 2-second delay API data source (`ProviderServicesRepositoryImpl`) with standardized `// TODO(api-integration): ...` tags.

- **Mobile Build & Release Engine (`build.sh`)**:
  - Upgraded build automation script with interactive wizard flow, step headers, pre-flight execution summary cards, and confirmation prompts.
  - Added asynchronous background task execution (`spin_engine`) with animated live timers and human error diagnostic cards.
  - Integrated full multi-flavor support (`ngrok`, `prod`, `dev`, `staging`), platform binary resolution (APK, AAB, IPA, Unsigned Archive), and dynamic artifact copying with file size indicators.
  - Added automated distribution pipelines for Google Play Console Internal Track, Apple App Store / TestFlight, Google Drive (`gws`), and Diawi.

- **Architectural Law: Dedicated Separate Widget for ListView Items**:
  - Enforced and codified the universal rule: *"Never use a component without a dedicated separate widget for ListView"* across all agent SOP and governance rules (`AGENTS.md`, `flutter-sop/AGENTS.md`, `.cursorrules`, `.windsurfrules`, `CLAUDE.md`, `SOP-CORE.md`, `coding-dart-flutter.md`).
  - Extracted standalone list item widgets across all existing ListView screens:
    - `_ProviderFilterChipItem` in `ProviderBookingsTabView` (replaced `_buildFilterChip` helper method).
    - `_PlacesAutocompletePredictionTile` in `PlacesAutocompleteField`.
    - `_ManageServiceListItemCard`, `_WorkingDaysCard`, and `_TimeSlotsCard` in `ManageServicesPage`.
    - `_PayoutHistoryListItemCard` in `ProviderEarningsPage`.
    - `_CustomerBookingListItemCard` in `MyBookingsPage`.
    - `_HomeProviderListItemCard` in `CustomerHomePage`.

### Fixed
- **Provider Dashboard Pixel-Perfect Figma Realignment**:
  - Realigned metric cards in `ProviderMetricCard` to display prominent bold values on top and subtitles below matching Figma CSS specifications (e.g., €2,410 in `#3D8BFF` on top with Total Earnings below; €32.30 in `#FBBF24` on top with Pending Payouts below).
  - Formatted rating overview card with rich inline spans (`4.8` in `#34D399` green and `(128 reviews)` in `#FFFFFF` white).
  - Configured `ProviderSegmentedToggle` with 58px container height (`#0D1B2A`), 20px squircle radius (`#2A3F58` border), and bottom 4px glowing indicator line (`#3D8BFF`).
  - Configured `AppBottomNavBar.dashboard()` to render vector SVGs cleanly directly on the nav bar without active background squircle pills.
  - Updated `RegisterPage` to route newly registered providers directly to `ProviderDashboardScreen()`.


### Added
- **Provider Dashboard Skeleton & Keep-Alive Tab System**:
  - Implemented the master `ProviderDashboardScreen` skeleton container with direct widget navigation, defaulting to `ProviderDashboardTab.dashboard`.
  - Implemented `IndexedStack` page state preservation to keep all 4 primary tabs alive (Dashboard, Bookings, Earnings, More) across navigation switches.
  - Implemented strongly-typed `onTabChanged(fromTab, toTab)` transition callbacks to enable on-demand data refreshing, badge recalculations, and analytics without tearing down widget state.
  - Integrated `AppBottomNavBar.dashboard()` with custom vector SVGs (`dashboard`, `calendar`, `earnings`, `more`), active glowing indicators, and tokenized dark styling.
  - Built `ProviderDashboardTabView` with edge-to-edge top gradient, greeting header, dual metric cards with Euro watermarks, rating card with star illustration, quick action link cards, and segmented sub-tab switcher ("Todays' Bookings" vs "New Requests").
  - Built `ProviderBookingsTabView` with horizontal scrollable filter chips (All, New, Confirm, Active, Completed, Rejected) and responsive 4-state UI lifecycle (Loading, Empty, Error, Populated).
  - Built `ProviderEarningsTabView` with 2x3 metrics grid (Completed Bookings, Total Amount, Commission, Net Payable, Paid Out, Pending Payout) and detailed Payout History breakdown cards.
  - Built `ProviderMoreTabView` (Profile & Settings) featuring profile identity card with initials avatar, operations management menu tiles, legal/support links, and safe session logout with confirmation gate.
- **Single Unified Dynamic Booking Card (`ProviderBookingCard`)**:
  - Consolidated disparate booking CSS mockups into a single, high-performance, reusable `ProviderBookingCard` driven by strongly-typed `ProviderBookingEntity` and `ProviderBookingStatus` (`newRequest`, `confirmed`, `inProgress`, `completed`, `rejected`).
  - Dynamic status and action layouts: dual accept/reject buttons for new requests, get-direction/start-service for confirmed appointments, mark-as-completed full button for active jobs, customer review notes for completed services, and refund notes for rejected requests.
  - Designed with continuous Figma squircle curvature (0.6 smoothing), dashed line dividers, and strict zero-hex/zero-framework-icon compliance.
- **Vector Icons & Design System Enhancements**:
  - Created `AppChevronRightIcon` custom vector painter matching Figma's 2px stroke specification to replace framework `Icons.*`.
  - Created `ProviderNotificationButton` 42x42 squircle bell button with direct navigation to `NotificationsPage`.
  - Added centralized Dashboard, Bookings, Earnings, and More strings to `AppStrings`.

- **Provider Work Portfolio 10-Photo Limit Enforcement**:
  - Enforced a strict maximum 10-photo selection limit for 'Photos of your work' in Step 2 (`SetupStepImages`) of Provider Profile Setup.
  - Dynamically capped `_imagePicker.pickMultiImage(limit: remaining)` and added `.take(remaining)` truncation in `ProviderSetupCubit`.
  - Added live responsive `${state.serviceImages.length}/10` counter badge alongside the 'Photos of your work' section header.
  - Added tap-guard validation on `SetupUploadCard` and `BlocListener` error feedback via `context.showErrorSnackBar()` when 10 photos are reached.
  - Added centralized constants `photosOfYourWorkHint`, `maxServiceImagesReached`, and `errMaxServiceImagesReached` in `AppStrings`.
- **Design System Tokenization & Anti-Hallucination Laws in `flutter-sop`**:
  - Formally codified the **Mandatory Tokenization Triad (`AppColors`, `AppSpacing`, `AppStrings`, `AppTypography`)** into `flutter-sop/AGENTS.md`, root `AGENTS.md`, `flutter-sop/sop/SOP-CORE.md`, and `flutter-sop/sop/modules/standards/coding-dart-flutter.md`.
  - Added strict prohibitions against copying raw Figma CSS attributes into Flutter widgets: zero tolerance for raw hex literals (`Color(0x...)`), zero tolerance for raw numeric `EdgeInsets` / arbitrary `SizedBox` dimensions, and zero tolerance for inline user-facing strings.
  - Codified mandatory pre-completion **Automated Grep Auditing Gates** (`git grep "Color(0x" lib/` and `git grep "fromLTRB(" lib/`) into developer and agent verification checklists across all AI editor rules (`.cursorrules`, `.windsurfrules`, `CLAUDE.md`, `AGENTS.md`).
- **Design System Spacing Tokens (`AppSpacing`)**:
  - Ported and integrated `AppSpacing` from scoreboard into `lib/core/theme/app_spacing.dart`.
  - Defined standard scalar tokens: `spaceUnit` (16pt), `xxxs` (1pt), `xxs` (2pt), `xs` (4pt), `sm` (8pt), `md` (12pt), `lg` (16pt), `xlg` (24pt), `xxlg` (40pt), and `xxxlg` (64pt).
  - Provided centralized `EdgeInsets` presets: `screenPadding`, `screenHorizontal`, `bottomCtaPadding` (replacing static `fromLTRB(16, 8, 16, 16)`), `modalPadding`, and `chipPadding`.
- **Centralized Provider Profile Setup Strings in `AppStrings`**:
  - Moved all titles, hints, document descriptions, button texts, and validation messages to `lib/core/constants/app_strings.dart`.

### Refactored & Enhanced
- **Provider Profile Setup Design Token Standardization**:
  - Eliminated all hardcoded `Color(0x...)` literals in `ProviderSetupPage` and all associated widgets, mapping them strictly to `AppColors` tokens (`brandDarkNavy`, `bgSecondaryDark`, `brandLightGrey`, `textSecondaryDark`, `borderStrongDark`, `borderDefaultDark`, `brandPrimaryBlueDark`, `statusSuccessDark`, `statusErrorDark`).
  - Replaced all raw `EdgeInsets.fromLTRB(16, 8, 16, 16)` with `AppSpacing.bottomCtaPadding`.
  - Replaced all ad-hoc SizedBox heights/widths and padding dimensions with `AppSpacing.*` scalars.
  - Replaced hardcoded strings across screens, cards, modals, and Cubit validations with `AppStrings.*`.
- **Universal Anti-Static & Dynamic Development Mandate in `flutter-sop`**:
  - Codified generic, feature-agnostic engineering standards across root `AGENTS.md`, `flutter-sop/AGENTS.md`, `flutter-sop/sop/SOP-CORE.md`, and active standards modules (`api-integration.md`, `coding-dart-flutter.md`).
  - **Zero Hardcoded / Static Data**: Strictly prohibited hardcoding dummy strings, static mock lists, or fake click handlers in UI widgets. All data must flow through strongly-typed, immutable domain entities.
  - **Anti-Primitive Obsession**: Mandated rich, strongly-typed domain models for all business concepts rather than flat primitives (`String`, `double`, `Map`).
  - **Universal Pre-API Implementation Pattern (Zero Mocks, Zero Tests)**: Established in-place endpoint simulation directly in data sources via `await Future.delayed(const Duration(seconds: 2))` + raw JSON strings decoded through `jsonDecode()` into `@JsonSerializable` DTOs and domain models. Prohibited standalone mock classes and test case authoring.
  - **Mandatory `TODO(api-integration)` Protocol**: Enforced standardized `// TODO(api-integration): Replace simulated 2s delay and static JSON with live API endpoint: [METHOD] [URL]` comments on any temporary static payload or simulated delay for seamless codebase auditing.
  - **Universal 4-State UI Law**: Formally mandated exhaustive visual handling of Loading, Empty, Error (with retry), and Populated states across all data-driven screens.

- **Pixel-Perfect Provider Profile Setup 3-Step Onboarding Flow (`ProviderSetupPage`)**:
  - Implemented 3-step PageView onboarding flow strictly matching Figma CSS specifications (`1.txt`, `2_with_some_image_selected.txt`, `2_without_image_selected.txt`, `3_with_some_image_selected.txt`, `3_without_image_selected.txt`).
  - **Step 0 (Business Details)**:
    - 52px height input fields with 30px pill radius, `#16273A` fill, `#3E5878` border, and 18px text.
    - Added `PlacesAutocompleteField` for "Base / Operating Location" with debounced Google Places suggestions and floating squircle overlay.
    - Added IME enter/submit handling on "Service Area Covered" creating dynamic 46px `#0D1B2A` chips with `#2A3F58` border, 12px radius, and `Assets.svg.icClose` remove action.
    - Reactive field validations with single-frame SnackBar throttling and smooth error border highlighting.
  - **Step 1 (Documents Verification)**:
    - Centered subtitle (`18px`, `400`, `#C4CBD4`) and extensible `DocumentSlotConfig` model enabling any document to be mandatory or optional.
    - 152px height dashed upload cards (`20px` radius) with `Assets.svg.imageAdd` and 24px `#F87171` red trash can delete action (`Assets.svg.trash`).
    - Camera / Gallery selection bottom sheet modal via `AppBottomSheet`.
  - **Step 2 (Images & Logo)**:
    - 152x152 square dashed upload card for Business Logo.
    - Multi-image picker support for "Work / Service Images" with live stacked 152px squircle photo preview cards and top-right `#F87171` trash delete icon.
  - **Architecture & API Readiness**:
    - Created domain entities (`PlacePrediction`, `DocumentSlotConfig`, `ProviderProfileDraft`), data DTO (`ProviderProfileSubmissionDto` with `json_serializable` & `toFormData()` for multipart uploads), repository interface (`IProviderOnboardingRepository`), and implementation (`ProviderOnboardingRepositoryImpl`).
    - Added custom vector SVG `assets/svg/trash.svg` to eliminate framework icons, fully conforming to the Zero Framework Icons SOP rule.

### Refactored & Enhanced
- **Mandatory Pixel-Perfect UI Markdown Blueprint & Approval SOP Rule**:
  - Defined strict SOP rule across `flutter-sop/sop/modules/standards/coding-dart-flutter.md`, `flutter-sop/AGENTS.md`, and root `AGENTS.md` mandating that all UI implementations and UI modifications MUST first be shared in Markdown format.
  - Required iterative Markdown layout refinement based on user review until explicit approval is granted before writing implementation code, ensuring pixel-perfect UI execution.
- **Defined Custom Icon SOP Rule & Standardized Asset Rules**:
  - Defined strict SOP rule in `flutter-sop/sop/modules/standards/coding-dart-flutter.md`, `flutter-sop/AGENTS.md`, and root `AGENTS.md` prohibiting default framework icons (`Icons.*`, `CupertinoIcons.*`) across all components and screens.
  - Enforced usage of custom SVG vector assets (`Assets.icon.*`, `Assets.svg.*`) via generated asset getters or vector extensions (`.toSvg()`).
- **Smooth `AppOnboardingView` Backdrop Color & Content Transitions**:
  - Refactored `AppOnboardingView` to position `_OnboardingBackdropPainter` as a single fixed background layer with real-time `ColorTween` color morphing (400ms `Curves.easeInOutCubic`) as active onboarding slides change.
  - Implemented smooth in-place content cross-fade transitions (`AnimatedSwitcher` with fade and subtle vertical slide) for slide artwork, titles, and subtitles without physical page drag seams.
- **Optimized `DefaultConfigCubit` Single Session Sync**:
  - Configured `DefaultConfigCubit` to trigger `api/v1/default-configuration` once per app open session when the user is logged in (`main.dart`).
  - Restricted unauthenticated API calls on app startup when user is not logged in.
  - Added automatic post-login and post-signup configuration sync in `LoginPage` and `RegisterPage` to ensure configuration is fetched fresh for new user sessions.
- **Redesigned Terms & Conditions & Privacy Policy Screens (`CmsPage`)**:
  - Implemented top gradient background overlay using `AppTopGradientBackground` and `#0D1B2A` dark navy background matching Figma design mockups.
  - Added high-contrast white `< Back` button (`AppBackButton`) and 32px bold headline title (`Terms & Conditions` / `Privacy Policy`).
  - Updated webview HTML body styling to `#E2E8F0` light typography with `#3D8BFF` hyper-links for optimal dark mode legibility.
- **Standardized `AppTextField` Form Validator Audit & Error SnackBar Throttling**:
  - Audited and refactored `AppTextField` validator handling across all forms (`LoginPage`, `RegisterPage`, `ForgotPasswordPage`, `ResetPasswordPage`).
  - Completely suppressed Flutter's default inline `errorText` rendering below input containers using transparent `errorStyle` (`height: 0, fontSize: 0`), preventing layout shift.
  - Implemented single-frame SnackBar throttling during multi-field `FormState.validate()` execution so only the top-most failing field's error message is dispatched via floating `AppSnackBar`, while all invalid fields highlight red borders (`AppColors.borderErrorDark`).
  - Added auto-clearing of validation error highlights when the user modifies text in the field (`onChanged`).
- **Standardized `AppTextField` & `AppDropdown` Error Feedback**:
  - Refactored `AppTextField` and `AppDropdown` to eliminate inline `errorText` rendering below input fields, preserving fixed layout height and preventing visual page jumping.
  - Implemented automatic error presentation via floating `AppSnackBar` (`context.showErrorSnackBar`) when `errorText` is provided or when `validator` fails, while retaining red border highlighting (`AppColors.borderErrorDark`) to identify invalid input fields.
- **Standardized Centralized Navigation via `AppNavigator`**:
  - Replaced all direct low-level `Navigator.pop()`, `Navigator.of(context)`, `Navigator.push()` calls across all screens, dialogs, bottom sheets, permission handlers, and showcase views with `AppNavigator` methods and convenience `BuildContext` extensions (`context.popScreen()`, `context.pushScreen()`, `context.popDialog()`).
  - Enforced `AppNavigator` rules in `flutter-sop/sop/modules/navigation/nav-direct-widget.md`, `flutter-sop/AGENTS.md`, and root `AGENTS.md` so AI agents strictly maintain centralized navigation safety boundaries.
- **Enhanced `AppTopGradientBackground` & `WidgetGradientExtension`**:
  - **Fixed Gradient Stack Visibility**: Resolved issue where wrapped screens obscured the top gradient. Enabled automatic transparent Scaffold background handling (`isScaffoldTransparent: true`) so the top gradient overlay shines through seamlessly.
  - **Standalone AppBar Gradient Header**: Added `AppTopGradientBackground.appBarHeader(...)` and `AppAppBar.gradient(...)` constructors to render standalone edge-to-edge gradient headers featuring title text, `< Back` icon button (`AppBackButton`), and action items when NOT used as a background stack.
  - Updated documentation in [`lib/core/components/gradient_background/README.md`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/gradient_background/README.md), [`lib/core/components/app_bar/README.md`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/app_bar/README.md), and [`COMPONENTS.md`](file:///Users/vijaybheda/Documents/development/f/washy/COMPONENTS.md).

### Added
- **Implemented "Contact Us" Feature Screen (`ContactUsPage`)**:
  - Implemented `ContactUsPage` matching Figma design mockups featuring `AppTopGradientBackground`, white `AppBackButton`, 32px bold headline title, and `SplashBottomSilhouette` bottom graphic.
  - Added cached local storage persistence for `DefaultConfigData` and `ContactUs` in `LocalStorageService` (retrieved from `api/v1/default-configuration`).
  - Added instant cached data loading via `ContactUsCubit`, falling back to `ContactUsShimmerView` animated skeleton loader when cache is empty/null while executing an API fetch.
  - Implemented interactive `ContactItemCard` squircle widgets (`#16273A` fill, 20.0 corner radius, size 48 `#3D8BFF` circular action button) launching `tel:` phone call dialer and `mailto:` email composer via `url_launcher`.
- Implemented **Default Configuration** singleton system for app-wide access to vehicle types, service categories, and contact information:
  - Created immutable data models (`VehicleType`, `ServiceCategory`, `ContactUs`, `DefaultConfigData`, `DefaultConfigResponse`) with `@JsonSerializable(explicitToJson: true)` and `Equatable` value equality.
  - Implemented `DefaultConfigRepository` with API integration to `api/v1/default-configuration` endpoint.
  - Created singleton `DefaultConfigCubit` with factory constructor for app-wide state access (`DefaultConfigCubit.instance`).
  - Added `defaultConfiguration` endpoint to `ApiEndpoints`.
- Linked CMS Pages (Terms & Conditions, Privacy Policy) dynamically from `LoginPage` and `RegisterPage` to the universal `CmsPage` via enums (`CmsType.terms`, `CmsType.privacy`).
- Implemented **"Set Up Your Profile"** Onboarding Flow for Providers ([`lib/features/provider/onboarding/presentation/pages/provider_setup_page.dart`](file:///Users/vijaybheda/Documents/development/f/washy/lib/features/provider/onboarding/presentation/pages/provider_setup_page.dart)):
  - 3-step PageView onboarding flow driven by `ProviderSetupCubit` and `AppStepIndicator`.
  - **Step 1 (Business Details)**: Collects business name, description, phone, email, operating location, and dynamic interactive service area tags.
  - **Step 2 (Documents Upload)**: Document upload slots for ID Proof, Business Proof (Optional), and Address Proof (Optional) using squircle dashed-border containers with live image previews and re-pick/remove capabilities.
  - **Step 3 (Images & Logo)**: Business logo square upload card and scrollable service portfolio images list with individual squircle preview cards and trash/delete buttons.
  - Smooth flow transition on final submission navigating directly to `ProviderApprovalStatusPage`.
- Implemented universal **`AppTopGradientBackground`** component and **`WidgetGradientExtension`** ([`lib/core/components/gradient_background/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/gradient_background/)):
  - Built-in Figma gradient presets: `.standard()` (150dp AppBar/Header with 3-stop linear gradient: Primary Blue `#0A6AFF` at 0%, Accent Teal `#00C2B8` 30% alpha at 50%, Dark Navy `#0D1B2A` 0% alpha at 100%) and `.dashboard()` / `.large()` (341dp with 20dp bottom continuous squircle radius).
  - Configurable `.custom()` constructor with explicit heights, color palettes, stops, and smooth corner radiuses.
  - Fluent widget extension methods (`.withTopGradient()`, `.withAppBarGradient()`, `.withDashboardGradient()`) for clean, declarative widget wrapping.
  - Zero status bar clipping: positions top gradient edge-to-edge behind the iOS status bar/notch/island and Android status bar.
  - Published comprehensive parameter reference documentation in [`lib/core/components/gradient_background/README.md`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/gradient_background/README.md) and updated [`COMPONENTS.md`](file:///Users/vijaybheda/Documents/development/f/washy/COMPONENTS.md).

### Changed
- Polished the **Notifications** feature screen for full SOP compliance and design-system alignment:
  - Extracted standalone [`NotificationsHeader`](file:///Users/vijaybheda/Documents/development/f/washy/lib/features/notifications/presentation/widgets/notifications_header.dart) and [`NotificationsContentView`](file:///Users/vijaybheda/Documents/development/f/washy/lib/features/notifications/presentation/widgets/notifications_content_view.dart) widget classes, eliminating `_buildX()` helper methods.
  - Implemented animated skeleton shimmer loader ([`NotificationsShimmerView`](file:///Users/vijaybheda/Documents/development/f/washy/lib/features/notifications/presentation/widgets/notifications_shimmer_view.dart)) for smooth visual feedback during initial data fetch without external dependencies.
  - Updated notifications barrel export ([`notifications.dart`](file:///Users/vijaybheda/Documents/development/f/washy/lib/features/notifications/notifications.dart)) to export all extracted presentation widgets.
- Implemented pixel-perfect **Signup Page** ([`RegisterPage`](file:///Users/vijaybheda/Documents/development/f/washy/lib/features/auth/presentation/pages/register_page.dart)) matching Figma WC_2 CSS specifications and design mockups:
  - Dark Navy background (`#0D1B2A`) with top curved header banner (`#12233A`, 140px height), corner water splash accents, and centered Washy logo.
  - High-contrast 32px headline ("Create an Account") and 18px subtitle ("Join Washy to grow your car business and track your earnings.").
  - 5 Pill text fields (Full Name, Email Address, Phone Number, Password, Confirm Password) styled with `#16273A` fill, `#3E5878` border, and 10px vertical spacing.
  - Interactive password obscure toggles with active `#3D8BFF` blue eye icon indicator when visible.
  - Bright Blue Pill CTA button (`#3D8BFF`, 52px height) for "Sign Up".
  - Integrated legal disclaimer (`AppRichText.termsAndConditions`).
  - Soft Blue Pill secondary button (`rgba(10, 106, 255, 0.15)`) for "Already have an account? Sign In".
- Updated [`AppTextField`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/text_field/app_text_field.dart) password eye icon to highlight active blue (`#3D8BFF`) when unobscured.
- Updated [`AppOnboardingView`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/onboarding/app_onboarding_view.dart) so tapping "Skip" triggers the finish callback flow by default instead of merely animating to the last slide.
- Simplified layout constraints in [`AppOnboardingView`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/onboarding/app_onboarding_view.dart) by removing explicit scaling factor computations (`scaleY`, `imageSize`, `imageHeight`) and unused `LayoutBuilder`, allowing natural illustration rendering and standardized spacing.
- Cleaned all `TextStyle` declarations across the application by removing manual `height:` (line-height) and `letterSpacing:` overrides, and eliminating responsive ternary `fontSize:` checks in favor of canonical `context.textTheme` styles.
- Refactored project typography across all UI feature pages and design system components to directly consume `context.textTheme.<style>` (via `ContextExtensions`) instead of hardcoded static `AppTypography.xxxStyle()` methods, ensuring dynamic Light/Dark theme responsiveness and accessibility text scaling support.
- Deprecated legacy static styling helpers in [`AppTypography`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/theme/app_typography.dart), establishing `AppTypography` as the dedicated theme token builder supplying `lightTextTheme` and `darkTextTheme` to [`AppTheme`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/theme/app_theme.dart).
- Fixed static analysis syntax error in [`AppOnboardingView`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/onboarding/app_onboarding_view.dart) by replacing unsupported dot-shorthand syntax (`.topLeft`) with canonical `Alignment.topLeft`.

### Changed
- Replaced arbitrary magic-offset rotated ellipse container in [`AppOnboardingView`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/onboarding/app_onboarding_view.dart) with a clean, mathematically precise `_OnboardingBackdropPainter` (`CustomPainter`) rendering the organic 2-color dark navy top arc and vibrant blue/teal body across all screen sizes.
- Explicitly anchored the back button at the top-left side using `Positioned(top: 0, left: 0, ...)` with safe-area padding and high-contrast white styling in [`AppOnboardingView`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/onboarding/app_onboarding_view.dart).
- Updated minimum Dart SDK constraint in [`pubspec.yaml`](file:///Users/vijaybheda/Documents/development/f/washy/pubspec.yaml) to `sdk: '>=3.10.0 <4.0.0'`, executed `fvm flutter pub get`, and aligned code styles with updated Dart 3.10+ lint rules (null-aware spread operators and wildcard parameters).
- Refactored [`AppOnboardingView`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/onboarding/app_onboarding_view.dart) layout architecture to pin navigation controls (top `< Back` button, bottom rotated diamond pager indicator, and action buttons) as fixed overlays, scoping horizontal swiping exclusively to slide content (2-color backdrop canvas, center illustration/image, and title/subtitle).
- Reduced circular "Skip" button text size to 13sp with zero inner padding in [`AppButton.circular`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/button/app_button.dart) and [`AppOnboardingView`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/onboarding/app_onboarding_view.dart) for clean text clearance.
- Updated [`OnboardingPage`](file:///Users/vijaybheda/Documents/development/f/washy/lib/features/welcome/presentation/pages/onboarding_page.dart) slide definitions to render dedicated image assets (`Assets.image.carWashEssential`, `Assets.image.giveReview`, `Assets.image.currency` for Providers; `Assets.image.washingCarMachine`, `Assets.image.giveReview`, `Assets.image.reviewImage` for Customers).
- Updated [`welcome_page.dart`](file:///Users/vijaybheda/Documents/development/f/washy/lib/features/welcome/presentation/pages/welcome_page.dart) to render the official white text horizontal brand logo asset (`Assets.image.washyHorizontalLogoWhiteText`) at the top of the welcome screen.
- Migrated all asset references across UI screens ([`welcome_page.dart`](file:///Users/vijaybheda/Documents/development/f/washy/lib/features/welcome/presentation/pages/welcome_page.dart), [`onboarding_page.dart`](file:///Users/vijaybheda/Documents/development/f/washy/lib/features/welcome/presentation/pages/onboarding_page.dart)) and documentation to type-safe auto-generated `Assets.image.*` ([`lib/gen/assets.gen.dart`](file:///Users/vijaybheda/Documents/development/f/washy/lib/gen/assets.gen.dart)) via `flutter_gen`, eliminating manual asset constant definitions.

### Added
- Implemented production-grade **Modular Network Architecture Suite** ([`lib/core/network/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/network/)):
  - Built `ApiClient` with typed HTTP verbs (`get`, `post`, `put`, `patch`, `delete`), progress-tracking multipart uploads (`uploadFile`), and streaming downloads (`downloadFile`).
  - Implemented sealed `ApiResult<T>` (`ApiSuccess` / `ApiError`) equipped with functional `.fold()`, `.onSuccess()`, and `.onError()` callbacks for seamless BLoC/Cubit integration.
  - Implemented `AuthInterceptor` with single-flight mutex (`Completer<String?>`) preventing concurrent token refresh storms on 401s.
  - Implemented `LoggingInterceptor` with latency benchmarking and sensitive field redaction (`authorization`, `passwords`, `tokens`, `PINs`, `cards`).
  - Implemented `RetryInterceptor` with exponential backoff (1s, 2s, 4s) restricted to network timeouts and idempotent 5xx errors.
  - Implemented `ErrorMapper` with automatic server HTML error sanitization (`<!DOCTYPE html>...`) and zero generic "Something went wrong" messages.
  - Implemented `HttpStatusHandler` with status-code-specific, user-friendly fallback messaging dictionary.
  - Implemented `BaseApiResponse<T>` and `PaginationData` with `@JsonSerializable(explicitToJson: true)` and `Equatable`.
  - Implemented `ApiEndpoints` with centralized constant paths and dynamic route generators.
  - Created `AppStatusManager` for safe 503 Maintenance and 426 Force Update screen redirection via `AppNavigator`.
  - Published comprehensive documentation at [`lib/core/network/README.md`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/network/README.md) and [`docs/api/NETWORK_API_STANDARD.md`](file:///Users/vijaybheda/Documents/development/f/washy/docs/api/NETWORK_API_STANDARD.md).
- Implemented standardized **`AppDialog` & `AppDialogContainer`** component suite ([`lib/core/components/dialog/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/dialog/)):
  - Continuous Figma squircle smoothing (0.6) with dark navy / pure white surface theming and elevation shadows.
  - Built-in header support (title, subtitle, icon, close button), scrollable body slot, and positive/negative action CTA row.
  - Confirmation variant (`AppDialog.confirm` / `context.showConfirmationDialog`) returning `Future<bool?>` with destructive action styling.
  - Added comprehensive `README.md` documentation and updated master catalog `COMPONENTS.md`.
- Enhanced **`AppNavigator` & Context Extensions** with automated pre-actions:
  - Software keyboard auto-dismissal (`FocusManager.instance.primaryFocus?.unfocus()`) before executing page transitions or displaying modals.
  - Platform-adaptive page transitions (`CupertinoPageRoute` on iOS, `MaterialPageRoute` on Android/other platforms).
  - Modal lifecycle management (`popDialogOrBottomSheet`, `showAppDialog`, `showConfirmationDialog`, `showAppBottomSheet`).

### Removed
- **Removed redundant `SplashPage`**:
  - Pinned app startup directly to the native splash screen (`flutter_native_splash`).
  - Asynchronous session check (`LocalStorageService().isUserLoggedIn()`) and initial screen determination run natively in `main()` while splash is preserved.
  - App launches directly into `WelcomePage` (unauthenticated) or role dashboard (`CustomerHomePage` / `ProviderDashboardPage`), eliminating the artificial 2-second Flutter splash delay.
  - Retired `SplashPage` in `FEATURE_MAP.md`.

### Changed
- Migrated entire application architecture from named routes to **Direct Widget Navigation**:
  - Prohibited named routing (`context.pushNamed`, `context.goNamed`, `RouteNames`, raw string paths) across all screens and features.
  - Implemented `AppNavigator` (`lib/core/router/app_navigator.dart`) and `BuildContext` extensions (`pushScreen`, `pushReplacementScreen`, `pushAndRemoveAllScreen`, `popScreen`) to instantiate destination widget classes directly.
  - New and existing developers can now immediately identify the destination widget class and jump to its originating source file with a single click in their IDE.
  - Created new official SOP module `nav-direct-widget.md` and activated it in `sop.manifest.yaml`, `AGENTS.md`, `.agents/rules/flutter_sop.md`, and `FEATURE_MAP.md`.
- Enforced canonical **`UserRole` Enum** across the entire application:
  - Created `UserRole` enum (`lib/core/enums/user_role.dart`) with `customer`, `provider`, and `guest` variants, equality helpers, and serialization.
  - Replaced all raw string literals (`'customer'`, `'provider'`) across `LocalStorageService`, `OnboardingPage`, `WelcomePage`, `SplashPage`, and navigation flows.
- Enforced strict "Zero Test Cases Policy" across all repository SOP guidelines and agent operational rules:
  - Updated `AGENTS.md`, `flutter-sop/AGENTS.md`, `.agents/rules/flutter_sop.md`, `flutter-sop/sop/modules/agents/agents-core.md`, and `flutter-sop/sop/SOP-CORE.md` to explicitly forbid AI coding agents from writing, scaffolding, or generating test cases.
  - Formalized approved deviation in `sop.manifest.yaml` designating test authoring as an exclusively human developer responsibility.

### Added
- Implemented **`BuildContext` Extension Suite** ([`lib/core/extensions/context_extension.dart`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/extensions/context_extension.dart)):
  - Theme & Typography: `context.textTheme`, `context.theme`, `context.colorScheme` for reactive theme adaptation.
  - Viewport & Safe Area: `context.screenWidth`, `context.screenHeight`, `context.topPad`, `context.bottomPad`, `context.isKeyboardVisible`, `context.bottomSpacing`, `context.bottomSheetSpacing`, `context.dialogBottomSpacing`.
  - Standardized Feedback: `context.showSuccessSnackBar()`, `context.showErrorSnackBar()`, `context.showWarningSnackBar()`, `context.showInfoSnackBar()`.
- Implemented **Build-Runner Asset Code Generation & SVG Vector Extensions**:
  - Integrated `flutter_gen_runner` into `pubspec.yaml` generating type-safe `Assets` class (`Assets.icon.*`, `Assets.image.*`).
  - Added `StringExtension` ([`lib/core/extensions/string_extension.dart`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/extensions/string_extension.dart)) with `.toSvg(...)` and `.toast()`.
  - Refactored `UnderMaintenancePage` and `NoInternetPage` to demonstrate `Assets.icon.underMaintenance.toSvg()`, `Assets.icon.noInternet.toSvg()`, and `context.textTheme`.
- Implemented role-based **Welcome Screen** matching Figma CSS specifications (`393x852` canvas, high-res background hero with top vignette `#0D1B2A` 250px and bottom gradient fade 426px, centered Washy logo, and dual role pill buttons: "I'm a Customer" `#3D8BFF` and "I'm a Service Provider" `#2DE0D5`).
- Implemented dynamic 3-slide **Service Provider Onboarding Flow** matching Figma CSS:
  - Slide 1: Primary blue `#3D8BFF` background with dark navy `#16273A` rotated curved ellipse, "List your services, set your rates!", and outline circular "Skip" + white pill "Continue".
  - Slide 2: Accent teal `#2DE0D5` background with dark navy `#16273A` rotated curved ellipse, "New request? Accept and go!", and outline circular "Skip" + white pill "Continue".
  - Slide 3: Primary blue `#3D8BFF` background with dark navy `#16273A` rotated curved ellipse, "Earn more, rate by rate!", and full-width "Let's Get Started!" CTA.
- Migrated `LocalStorageService` to `get_storage` exclusively (removing `flutter_secure_storage`), initialized via `await GetStorage.init()` in `main.dart`, with 100% backwards-compatible async API for tokens, roles, and notification preferences.
- Added `AppAssets` (`lib/core/constants/app_assets.dart`) and registered `assets/image/` in `pubspec.yaml` adhering to zero-hardcoded-strings SOP standard.
- Extended `OnboardingSlideData` with dynamic `imagePath` support and updated `AppOnboardingView` with responsive typography and artwork resolution.
- Updated `SplashPage` with automatic authentication check: unauthenticated users redirect to `WelcomePage`, while authenticated users route directly to their respective role dashboard/home.

### Fixed
- Restored AppStepIndicator and AppPagerIndicator demos in the component gallery. Shrink-wrapped `AppButton` variants no longer inherit the theme's infinite `ElevatedButton` min width, which previously left those sections as a blank, never-finishing layout.

### Added
- Integrated Firebase Cloud Messaging (FCM) push notification infrastructure and intelligent token synchronization:
  - Added `NotificationManager` singleton coordinating FCM lifecycle, APNs token checks on iOS, foreground presentation banners, and background message handling (`firebaseMessagingBackgroundHandler`).
  - Implemented differential FCM token synchronization: evaluates whether the current device FCM token is non-null and differs from the cached local token before pushing to the server, cleanly avoiding redundant network calls when the token is unchanged.
  - Automatically pushes token on app startup (`SplashPage`), user authentication (`LoginPage`), and token rotation (`onTokenRefresh`).
  - Added strongly typed, immutable `PushNotificationEntity` model with `@JsonSerializable(explicitToJson: true)` and `Equatable` value equality.
  - Extended `LocalStorageService` with secure getters/setters for FCM token persistence, user login state inspection, and notification preferences.
  - Extended `ApiClient` with RESTful `patch` and `put` HTTP operations, and added `updateFcmToken` to `NotificationsRepository` with offline/mock fallback support.
  - Configured Android and iOS background notification capabilities (`POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, and `remote-notification` background mode).
- Implemented the full **Notifications** feature screen matching the Figma dark design system and reference architecture from Scoreboard:
  - Custom vector `CoffeeMugIllustration` empty state with neon blue/cyan line work, steam curls, and "You're all caught up" status copy.
  - Interactive squircle `NotificationItemCard` with category icon badges (reviews, payouts, cancellations, booking requests, profile approvals), emoji-decorated titles, descriptions, and human-readable relative timestamps ("1 hour ago", "2 hours ago", "1 day ago").
  - `NotificationsCubit` and `NotificationsState` managing reactive data flow across all 4 UI states (Loading, Empty, Error/Offline with retry, Loaded with pull-to-refresh and infinite scroll pagination).
  - Declarative GoRouter route `/notifications` and quick-access preview section in `ComponentShowcaseView`.
- Added production-grade, enterprise permission management subsystem (`AppPermissionService`, `AppPermissionType`, `AppPermissionStatus`, and `AppPermissionDialog`) safely supporting Android 10–17 and iOS 16–26.
- Implemented Figma-squircle permission dialogs including Permanent Denial ("Open Settings"), Pre-prompt Contextual Rationale ("Continue"), and Location Services Disabled (GPS) flows, with automatic AppLifecycle resumption to re-evaluate permissions when returning from device system settings.
- Added concurrency mutex locking to prevent simultaneous OS permission request collisions and race conditions.
- Enforced least-privilege security architecture: declared foreground-only location (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`), granular media (`READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_VISUAL_USER_SELECTED`, scoped `READ_EXTERNAL_STORAGE`), camera (`CAMERA`), microphone (`RECORD_AUDIO`), and notification (`POST_NOTIFICATIONS`) in AndroidManifest.xml and iOS Info.plist without intrusive storage or background location permissions.
- Refactored `AppUploadAvatar` and `CustomerHomePage` to route camera, photo gallery, and location access through the new safe permission handler.
- Revamped documentation across all 30 UI component modules under `lib/core/components/` and the root library index `lib/core/components/README.md`, replacing basic examples with comprehensive Parameter Usage tables (types, defaults, required/optional status, descriptions), in-depth named constructor breakdowns, and practical "How We Can Use" integration guides.
- Added dedicated README documentation for `step_indicator`, `pager_indicator`, `onboarding`, and `showcase` components.
- Added mission-critical defensive system screens: `ForceUpdatePage` (mandatory update blocking screen with safe app store redirection and non-dismissible `PopScope`), `NoInternetPage` (offline disconnection screen with reactive connection check retry mechanism and user feedback toasts), and `UnderMaintenancePage` (scheduled maintenance mode screen with estimated completion time badge and refresh status checking).
- Added `SystemStatusBadge` and `SystemStatusContent` layout components with glowing squircle styling, 100% theme integration, responsive 1.3x text scale support, and 48x48 dp touch targets.
- Registered declarative GoRouter routes (`/force-update`, `/no-internet`, `/under-maintenance`) and integrated interactive full-screen previews in `ComponentShowcaseView`.
- Added high-performance, memory-safe image and avatar component suite (`AppImageView`, `AppImageMetadata`, `AppUploadAvatar`, `AppAvatar`, `AppCachedImage`) with display-resolution decode capping (`ResizeImage` & DPR scaling for OOM bitmap protection), universal source resolution (`http(s)://`, `assets/...`, `file://...`, `ImageProvider`, `AppImageMetadata`), Figma squircle geometry, unicode-safe initials generation, deterministic 10-color background hashing, Hero transitions, fullscreen pinch-to-zoom interactive modal, and reactive camera/gallery photo uploader with file size limits and zero `setState`.
- Added dynamic, reusable `AppOnboardingView` and `OnboardingSlideData` component matching Figma specifications (`#3D8BFF` background, `-13.3°` rotated `#16273A` curved backdrop ellipse, DM Sans 40px w800 headline, DM Sans 18px w400 subtitle, 45°-rotated diamond indicator, outline circular 52x52 'Skip' button, and white pill 'Continue'/'Get Started' buttons) supporting swipe gestures and button navigation with 100% dynamic slide data.
- Added `AppPagerIndicator` (with `PagerIndicator` alias) component matching Figma specifications (`8x8px`, `border-radius: 2px`, `-45°` diamond rotation, `#FFFFFF` full white active / `0.5` opacity inactive) with geometric variants (diamond, circle, capsule, squircle), PageController synchronization, tap callbacks, semantics, and interactive showcase gallery.
- Added `AppStepIndicator` (with `StepIndicator` alias) component matching Figma specifications (`height: 5px`, `border-radius: 10px`, `spacing: 5px`, `#34D399` active green / `#16273A` inactive navy) with animated transitions, customizable step counts, tap callbacks, semantics accessibility, and interactive gallery showcase.
- Fixed range slider callout tooltip indicator shape in `TooltipBubbleClipper` and `AppRangeSlider`, eliminating top-left diagonal cut-out artifacts and ensuring clean speech-bubble callout geometry with a centered pointer arrow.
- Eliminated double border artifact on `AppChip` (actionable, selectable, time-slot, and filter chips) by removing duplicate outer `ShapeDecoration` clip and delegating background, border painting, and ripple clipping directly to a single `Material(shape: chipBorder)`.
- Upgraded `AppDashedBorderContainer` to default `cornerRadius: 24.0` with `1.0` corner smoothing and squircle upload icon container, producing prominent and unmistakable Figma superellipse squircle curvature on large card surfaces.
- Standardized dashed card upload containers to continuous squircles with inset stroke painting in `DashedBorderPainter`, eliminating stroke clipping and duplicate solid/dashed borders.
- Resolved double border rendering artifacts across `AppCard` and `AppChip` by removing redundant outer `ShapeDecoration` strokes and assigning borderless shapes to inner `Material` widgets, ensuring each component paints strictly 1 crisp border.
- Explicitly set `CFBundleDisplayName` to `Washy` in `ios/Runner/Info.plist` ensuring iOS displays `Washy` on the home screen instead of the target product fallback (`Runner`).
- Removed the outline border from `AppBottomSheetContainer`, delivering clean borderless bottom sheets with smooth squircle top corners matching modern design standards.
- Standardized all containers, cards, dialogs, bottom sheet filter cards, dashed upload containers, and badges across the application to continuous squircle shapes (`ShapeDecoration` with `SmoothRectangleBorder` / `SmoothBorderRadius`, `AppCard`, and `AppSquircleContainer`).
- Fixed Android touch ripple & splash clipping across interactive squircle components (`AppCard`, `AppChip`, `AppDropdown`, `AppIconButton`, `CardThemeData`), ensuring `Material(shape: ..., clipBehavior: Clip.antiAlias)` and `InkWell(customBorder: ...)` precisely clip touch highlights and ripples to the exact squircle boundary.
- Upgraded Figma continuous corner smoothing to 1.0 (100% full superellipse/squircle) across `SquircleMixin`, `squircleBorder()`, and `squircleRadius()`, ensuring prominent squircle corners throughout the UI.
- Enhanced squircle extensions in `squircle_utils.dart` with `clipSquircle()` and enabled anti-aliased clipping on `withSquircle()`, fixing rectangular container clipping and preventing child overflows.
- Replaced `ClipRRect` with `ClipSmoothRect` in `_AppProviderCard` for continuous squircle thumbnail clipping.
- Registered Debug and Release SHA-1 & SHA-256 certificate fingerprints for Android (`com.washy.app`) in Firebase project `carcarewashy-f3863`.
- Generated Android release keystore `washy.jks` using parameters from `android/key.properties` and wired release `signingConfigs` in `android/app/build.gradle.kts` with `.gitignore` protection.
- Integrated Firebase Core into the project for Android and iOS using application ID and bundle ID `com.washy.app` connected to Firebase project `carcarewashy-f3863` (`CarCareWASHY`), generating `lib/firebase_options.dart` and native configuration files (`google-services.json`, `GoogleService-Info.plist`).
- Configured native app icons using `assets/image/W-AppIcon.png` for Android and iOS via `flutter_launcher_icons`.
- Configured native splash screens using `assets/image/washy_splash.png` (with background color `#0D1B2A`) for Android (including Android 12+ SplashScreen API) and iOS LaunchScreen via `flutter_native_splash`, removing all branding logos.
- Integrated automatic AI code review pipeline triggered by Git `post-merge` hook on `development`, `main`, and `master` branches, performing automated Flutter static analysis, test execution, format verification, secret redaction, and AI review reporting to `AI_CODE_REVIEW.md`.
- Set default application state in `ThemeBloc` to `ThemeMode.dark` and wrapped `ComponentShowcaseView` with dynamic `Theme` and `Builder` wrappers, ensuring all 26 components inherit the dark navy design system (`#0D1B2A` / `#16273A`) by default.
- Enhanced `AppChip` with full Figma specifications for all states: `AppChip.timeSlot` (`chip_selected_and_notselected_state.txt`), `AppChip.action` (`actionable_chip.txt` and `chip_with_icon_disabled.txt`), `AppChip.filter`, and `AppChip.selectable` with interactive showcase section.
- Fixed stray white colors across components (`AppTextField`, `AppDropdown`, `AppCard`, `AppSquircleContainer`, `AppTheme`), ensuring 100% theme-matched dark navy (`#16273A` / `#0D1B2A`) and light mode tokens.
- Updated `AppDropdown` to directly render an in-place anchored popup dropdown menu at that exact UI location (with theme-matched dark navy/light surfaces, squircle borders, checkmarks, and subtitles) instead of opening a modal bottom sheet.
- Integrated full 36-token Figma color system into `AppColors` (Brand, Backgrounds, Borders, Text, CTA, and Status) for both Customer (Light) and Dark themes with zero hardcoding.
- Integrated `json_serializable`, `json_annotation`, `equatable`, and `build_runner` into project dependencies, establishing strict serialization, immutability, and value equality standards in `AGENTS.md` and SOP guidelines.
- Enhanced `AppBottomSheet` & `AppBottomSheetContainer` with full configurability: drag-to-dismiss gestures (`enableDrag`), barrier dismissal (`isDismissible`), custom drag handler dimensions (`dragHandleWidth`/`dragHandleHeight`/`dragHandleColor`), scrollable vs fixed modes (`AppBottomSheet.showFixed`), expandable/snappable sheets (`AppBottomSheet.showDraggableScrollable`), and pre-styled action dialogs (`AppBottomSheet.showConfirmation`).
- Implemented `AppBackButton` component matching Figma spec with `< Back` chevron and label, integrated with `AppAppBar` and standalone usage across pages.
- Implemented 26 modular, configurable, zero-hardcoded UI components with Google Fonts (`DM Sans`) and Figma continuous squircle corners (`AppButton`, `AppBackButton`, `AppChip`, `AppRangeSlider`, `AppBottomSheet`, `AppTextField`, `AppDashedLine`, `AppNoDataIndicator`, `AppIconButton`, `AppRadioButton`, `AppDropdown`, `AppStatusBadge`/`AppStatusButton`, `AppProfileMenuItem`, `AppSquircleContainer`, `AppDashedBorderContainer`, `AppCard`, `AppSnackBar`, `AppStateViews`, `AppVersionFooter`, `AppDatePicker`, `AppSquircleTabIndicator`/`AppTabBar`, `AppSwitch`, `AppCachedImage`/`AppAvatar`, `AppAppBar`, `AppRichText`, `AppBottomActionBar`, `AppBottomNavBar`).
- Configured 5-second automatic redirection on app launch from `SplashPage` to `ComponentShowcaseView` with countdown indicator and instant skip capability.
- Implemented comprehensive, interactive sample showcase gallery screen (`ComponentShowcaseView`) displaying all 25 UI components across all distinct visual states (Normal, Disabled, Loading, Selected, Error, Outlined, Filled, Soft, Ghost, etc.), shapes (Squircle, Pill, Circle), and sample values.
- Aligned component library shapes with Figma specifications, providing dedicated `.pill` (100+ full corner radius), `.squircle` (10-14 continuous smoothing), `.circular` (52x52 action circle), `.location` (squircle outline with icon), and `.grant` (small squircle) constructors.
- Redesigned `AppRangeSlider` to match Figma specifications: outer squircle container box (`#16273A`), thick rounded rail track (`14dp`), bullseye circle thumbs (outer `#3D8BFF` with solid white inner core), and dynamic speech-bubble callout tooltips pointing to thumbs with distance (`1.5 kms - 10 kms`) and price (`€20 - €80`) formatting.
- Conducted project-wide audit and refactored all screens and widgets to eliminate inline `TextStyle(...)`, legacy `Outfit` font references, and hardcoded user-facing strings in favor of centralized `AppTypography`, `AppStrings`, and semantic `AppColors`.
- Added comprehensive Markdown documentation (`README.md`) for every individual component with parameter tables, usage examples, and nested composition rules.
- Built interactive visual gallery (`ComponentShowcaseView`) in `lib/core/components/showcase/` supporting Light/Dark themes and real-time interaction.
- Added comprehensive unit and widget tests for all 25 components in `test/core/components/` achieving 100% test passing rate.
- Configured project-wide typography with `GoogleFonts.dmSans` across `AppTypography` and `AppTheme`.
- Added complete semantic status color tokens in `AppColors` for all booking/order states (`requested`, `confirmed`, `inProgress`, `completed`, `cancelled`, `refunded`, `paid`, `pending`, `failed`).
- Configured native build flavors: `dev`, `ngrok`, `staging`, and `prod` for Android and iOS.
- Implemented type-safe environment configuration (`AppConfig`) using `--dart-define` and `--dart-define-from-file`.
- Added environment JSON template files in `config/` (`dev.json`, `ngrok.json`, `staging.json`, `prod.json`).
- Integrated Figma Squircle design architecture using `SquircleMixin`, `SquircleNumX` extension on `num`, and `SquircleWidgetX` extension on `Widget` for reusable smooth corners across buttons, text fields, cards, and containers.
- Codified strict coding SOP rules prohibiting hardcoded strings/TextStyles and forbidding `setState` in favor of `ValueNotifier` and `Bloc`/`Cubit`.
- Added centralized `AppStrings` constant repository (`lib/core/constants/app_strings.dart`) to eliminate inline string literals.
- Configured VS Code launch configurations (`.vscode/launch.json`) synchronized with Android Studio/IntelliJ `.run/` configurations for all build flavors (`dev`, `ngrok`, `staging`, `prod`) in both debug and release modes.
- Refactored all presentation pages (`LoginPage`, `RegisterPage`, `CustomerHomePage`, `BookingFlowPage`, `StripePaymentPage`, `DocumentUploadPage`, `JobDetailsPage`) to use `ValueNotifier` and `Theme.of(context).textTheme`.
- Implemented pixel-perfect UI redesign matching design mockups across Splash screen (`SplashPage`), Role Selection landing (`WelcomePage`), 3-slide Onboarding carousel (`OnboardingPage`), and Auth screens (`LoginPage`, `RegisterPage`, `ForgotPasswordPage`).

### Fixed
- Enabled `resValues` build feature in Android Gradle configuration to support custom resource values in product flavors (`dev`, `ngrok`, `staging`, `prod`).
- Updated Android `compileSdk` to `37` in `android/app/build.gradle.kts` to satisfy dependency requirements (`permission_handler_android`).
- Migrated Android app module to Flutter Built-in Kotlin, resolving app-level Kotlin Gradle Plugin (KGP) deprecation warnings.
- Upgraded `image_picker` (`1.2.3`) & `image_picker_android` (`0.8.13+19`) to eliminate plugin-level KGP build warnings.

# Washy UI Component Library & Living Catalog (`COMPONENTS.md`)

This living document is the **single source of truth** for all reusable UI components in the Washy codebase ([`lib/core/components/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components)).

---

## 1. Mandatory Component-First Policy for AI Agents & Developers

Whenever building, modifying, or refactoring ANY user interface, screen, dialog, form, or control:

1. **Search Before Building:**
   - **MUST** inspect this document and [`lib/core/components/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components) to identify existing components.
   - **STRICTLY FORBIDDEN:** Writing custom buttons, raw text fields, hardcoded dialogs, custom state views, or ad-hoc chips from scratch.
2. **Direct Usage & Composition:**
   - Always use the standardized components directly. Combine them into higher-level feature screens.
3. **Safe Alteration & Extension Rules:**
   - When a new visual style, size, or behavior is needed, **safely extend** the existing component.
   - **Preserve Backwards Compatibility:** Never remove or alter existing parameters or change default values used by existing screens.
   - **Add Named Constructors:** Standardize new design variants via explicit named constructors (e.g., `AppButton.myNewVariant(...)`).
   - **Synchronous Documentation Update:** Whenever a component is created, altered, or extended, you **MUST** update its dedicated `README.md` and this `COMPONENTS.md` file in the **SAME change/PR**.

---

## 2. Component Documentation Standard

Every component in [`lib/core/components/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components) **MUST** maintain a dedicated `README.md` structured as follows:

```
# <ComponentName>

<High-level overview, role in design system, Figma alignment>

## Parameter Usage Reference
| Parameter | Type | Default | Status | Description & Behavior |
|---|---|---|---|---|
| `paramName` | `Type` | `defaultValue` | Required / Optional | Detailed explanation of what the parameter does, UI effects, and boundary conditions. |

## Constructors & Named Variants
### `ComponentName(...)`
Universal constructor with full parameter flexibility.

### `ComponentName.namedVariant(...)`
- **Purpose:** Use case explanation.
- **Presets / Locked Values:** Explicit list of locked or pre-configured properties.

## How We Can Use
<Step-by-step practical integration instructions with state binding (ValueNotifier/BLoC), form validation, theme tokens, and controller lifecycles. NO shallow/generic snippets.>

## Best Practices & Rules
<Specific rules on touch targets, Figma continuous curvature (0.6 smoothing), theming tokens, and accessibility.>
```

---

## 3. Master Component Catalog (33 Modules)

| # | Component | Directory & Docs | Purpose | Available Constructors & Key Presets |
|---|---|---|---|---|
| 1 | `AppButton` & `AppBackButton` | [`button/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/button/README.md) | Universal button system with Figma squircle (0.6), pill, circular shapes, custom icons, loading spinners, and navigation back buttons. | `AppButton(...)`, `.primary()`, `.secondary()`, `.pill()`, `.squircle()`, `.outline()`, `.ghost()`, `.soft()`, `.smallAction()`, `.grant()`, `.location()`, `.circular()`, `.icon()`, `AppBackButton(...)`, `AppBackButton.iconOnly()` |
| 2 | `AppTextField` | [`text_field/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/text_field/README.md) | Form text fields supporting password eye toggle, auto-clear search, email keyboards, date picker modals, multi-line text areas, and reactive validation. | `AppTextField(...)`, `.password()`, `.email()`, `.search()`, `.datePicker()`, `.textArea()`, `.pill()` |
| 3 | `AppCard` | [`card/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/card/README.md) | Continuous squircle surface cards with border strokes, elevation shadows, ink ripple taps, and provider listing layouts. | `AppCard(...)`, `.elevated()`, `.outlined()`, `.flat()`, `.interactive()`, `AppCard.provider()` |
| 4 | `AppChip` | [`chip/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/chip/README.md) | Booking time slot chips, action buttons, filter toggles, deletable chips, and pill/squircle tags. | `AppChip(...)`, `.timeSlot()`, `.action()`, `.selectable()`, `.filter()`, `.pill()`, `.squircle()` |
| 5 | `AppAppBar` | [`app_bar/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/app_bar/README.md) | Standardized Scaffold AppBar with Figma `< Back` navigation button, title, actions, and bottom divider. | `AppAppBar(...)` |
| 6 | `AppBottomActionBar` | [`bottom_action_bar/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/bottom_action_bar/README.md) | Sticky bottom bar with safe-area padding, dual CTA buttons, and price breakdown summaries. | `AppBottomActionBar(...)`, `.withPrice()` |
| 7 | `AppBottomNavBar` | [`bottom_nav_bar/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/bottom_nav_bar/README.md) | Squircle navigation bar with badge counters, glowing squircle active indicators, and GoRouter shell integration. | `AppBottomNavBar(...)`, `AppBottomNavBar.standard()`, `AppBottomNavBar.dashboard()`, `AppBottomNavItem(...)` |
| 8 | `AppBottomSheet` & `AppBottomSheetContainer` | [`bottom_sheet/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/bottom_sheet/README.md) | Modal squircle bottom sheet launcher, drag handles, confirmation dialogs, filter sheets, and draggable sheets. | `AppBottomSheet.show()`, `.showConfirmation()`, `.showFilters()`, `.showDraggable()` |
| 9 | `AppIconButton` | [`icon_button/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/icon_button/README.md) | Circular and squircle icon buttons with filled, outlined, ghost styles, size presets (32/44/56dp), and notification badge counters. | `AppIconButton(...)`, `.filled()`, `.outlined()`, `.ghost()`, `.small()`, `.medium()`, `.large()`, `.badge()` |
| 10 | `AppDropdown<T>` | [`dropdown/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/dropdown/README.md) | Generic `<T>` dropdown styled identically to `AppTextField`, triggering an anchored in-place squircle popup menu. | `AppDropdown<T>(...)`, `.pill()`, `.squircle()`, `AppDropdownItem<T>(...)` |
| 11 | `AppDatePicker` | [`date_picker/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/date_picker/README.md) | Cupertino wheels and Material modal date, time, and combined date-time picker bottom sheets. | `AppDatePicker.show()`, `.showTime()`, `.showDateTime()` |
| 12 | `AppRangeSlider` | [`range_slider/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/range_slider/README.md) | Continuous and discrete dual-thumb sliders with squircle thumbs, rail tracks, and dynamic value callout tooltips. | `AppRangeSlider(...)`, `.continuous()`, `.discrete()`, `.currency()`, `.distance()` |
| 13 | `AppImageView`, `AppUploadAvatar`, `AppCachedImage`, `AppAvatar` | [`image/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/image/README.md) | Memory-safe (OOM prevented) images, initials avatars, camera/gallery uploaders with file size limits, permissions, and Hero zooms. | `AppImageView(...)`, `.circular()`, `.avatar()`, `.hero()`, `AppUploadAvatar(...)`, `.circular()`, `AppAvatar(...)` |
| 14 | `AppStatusBadge` & `AppStatusStyle` | [`status_button/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/status_button/README.md) | Centralized status styling for Completed, In Progress, Pending, Requested, Cancelled, Paid, Scheduled, and Failed. | `AppStatusBadge(...)`, `AppStatusBadge.fromStatus()`, `.completed()`, `.inProgress()`, `.pending()`, `.cancelled()`, `.paid()`, `.scheduled()`, `.failed()` |
| 15 | `AppRadioButton<T>` & `AppRadioTile<T>` | [`radio_button/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/radio_button/README.md) | Generic `<T>` radio option groups, standalone boolean toggles, and full-width list row tiles. | `AppRadioButton<T>(...)`, `.boolean()`, `.tile()` |
| 16 | `AppSwitch` | [`switch/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/switch/README.md) | Animated toggle switch with squircle track, smooth sliding thumb, and compact preset. | `AppSwitch(...)`, `.compact()` |
| 17 | `AppProfileMenuItem` | [`profile_menu/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/profile_menu/README.md) | Account menu row with squircle leading icons, title, subtitle, trailing switch or chevron, and card framing. | `AppProfileMenuItem(...)`, `.navigation()`, `.action()`, `.card()` |
| 18 | `AppSquircleContainer` | [`squircle_container/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/squircle_container/README.md) | Base continuous squircle container with Figma smoothing (0.6), background gradients, borders, and shadows. | `AppSquircleContainer(...)`, `.card()`, `.bordered()`, `.pill()` |
| 19 | `AppDashedBorderContainer` | [`dashed_border_container/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/dashed_border_container/README.md) | Dashed rounded border box for photo uploads, document attachments, and drop zones. | `AppDashedBorderContainer(...)`, `.upload()`, `.custom()` |
| 20 | `AppDashedLine` | [`dashed_line/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/dashed_line/README.md) | Horizontal and vertical dashed divider lines with configurable dash width, gaps, and thicknesses. | `AppDashedLine(...)`, `.horizontal()`, `.vertical()` |
| 21 | `AppSnackBar` | [`snackbar/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/snackbar/README.md) | Floating squircle notification snackbars with icon badges, action buttons, and auto-dismiss durations. | `AppSnackBar.show()`, `.showSuccess()`, `.showError()`, `.showWarning()`, `.showInfo()` |
| 22 | `AppStateViews` | [`state_views/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/state_views/README.md) | Standardized 4-state visual handlers: Loading, Empty, Error (with retry), and Offline. | `AppStateViews(...)`, `AppLoadingView(...)`, `AppEmptyView(...)`, `AppErrorView(...)`, `AppOfflineView(...)` |
| 23 | `AppNoDataIndicator` | [`no_data_indicator/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/no_data_indicator/README.md) | Empty state placeholder with centered vector icon, title, subtitle, and primary CTA button. | `AppNoDataIndicator(...)`, `.compact()`, `.withAction()` |
| 24 | `AppRichText` & `AppTextSpanItem` | [`rich_text/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/rich_text/README.md) | Multi-span clickable formatted text, URL links, and legal Terms & Privacy disclaimers. | `AppRichText(...)`, `AppRichText.termsAndConditions(...)` |
| 25 | `AppSquircleTabIndicator` & `AppTabBar` | [`tab_indicator/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/tab_indicator/README.md) | Squircle tab indicator with continuous corner radius and styled TabBar wrapper. | `AppTabBar(...)`, `AppTabBar.capsule(...)`, `AppSquircleTabIndicator(...)` |
| 26 | `AppVersionFooter` | [`version_footer/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/version_footer/README.md) | App version, build number, and flavor diagnostics with tap-to-copy clipboard feedback. | `AppVersionFooter(...)` |
| 27 | `AppStepIndicator` | [`step_indicator/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/step_indicator/README.md) | Multi-step progress indicator bars with active (#34D399) and completed step styling. | `AppStepIndicator(...)`, `AppStepIndicator.count(...)` |
| 28 | `AppPagerIndicator` | [`pager_indicator/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/pager_indicator/README.md) | Rotated diamond / carousel dots matching Figma onboarding and gallery specifications. | `AppPagerIndicator(...)`, `.diamond()`, `.dots()`, `.capsule()`, `.squircle()` |
| 29 | `AppOnboardingView` | [`onboarding/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/onboarding/README.md) | Dynamic, reusable multi-slide onboarding flow with PageView, diamond indicators, and CTA actions. | `AppOnboardingView(...)`, `OnboardingSlideData(...)` |
| 30 | `AppDialog` & `AppDialogContainer` | [`dialog/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/dialog/README.md) | Standardized Figma squircle modal dialog with header, subtitle, action buttons, pre-action keyboard dismissal, and confirmation variants. | `AppDialog.show(...)`, `AppDialog.confirm(...)`, `AppDialog.custom(...)`, `AppDialogContainer(...)` |
| 31 | `ComponentShowcaseView` | [`showcase/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/showcase/README.md) | Interactive component gallery for manual QA and visual regression testing across light and dark themes. | `ComponentShowcaseView(...)` |
| 32 | `AppTopGradientBackground` | [`gradient_background/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/gradient_background/README.md) | Edge-to-edge top linear gradient overlay with status bar integration, Figma color stops, standalone header bar, and declarative widget extension. | `AppTopGradientBackground(...)`, `.appBarHeader()`, `.standard()`, `.appBar()`, `.dashboard()`, `.large()`, `.custom()`, `AppAppBar.gradient()`, `Widget.withTopGradient()` |
| 33 | `AppChevronRightIcon` | [`icon/`](file:///Users/vijaybheda/Documents/development/f/washy/lib/core/components/icon/README.md) | Pixel-perfect vector chevron right painter matching Figma's 2px stroke specification, replacing default framework chevron icons. | `AppChevronRightIcon(...)` |


---

## 4. Key Rules Summary for Agents

1. **Zero Hardcoding:** Typography from `GoogleFonts.dmSans` / `AppTypography`, colors from `AppColors`, strings from `AppStrings`.
2. **Zero `setState`:** Use `ValueNotifier<T>` or `Bloc`/`Cubit` for reactive state changes.
3. **Figma Smoothing:** Always enforce `cornerSmoothing: 0.6` (continuous squircle) across cards, buttons, badges, and modals.
4. **Touch Targets:** Minimum touch target size of 48×48 dp.

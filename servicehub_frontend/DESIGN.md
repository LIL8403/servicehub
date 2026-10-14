# ServiceHUB Design System & Token Specification
**Visual Identity Direction**: Atlantic Sovereign (Atlantic Navy & Ochre Gold)  
**Target Market**: Cameroon Digital Service Marketplace  
**Version**: 1.0.0 (Production Locked)  
**Audience**: Flutter Frontend Engineering, Mobile UI/UX Designers, Product Architects

---

## 1. Executive Brand Identity Summary

ServiceHUB connects Cameroonian households and enterprises with vetted, high-integrity artisans (electricians, plumbers, mechanics, carpenters, masons, painters). In an environment where the informal trade sector often suffers from trust deficits, opaque pricing, and transaction friction, ServiceHUB establishes institutional credibility through:

- **Security & Escrow**: Payments are locked in milestone escrow until the artisan's work is confirmed by the client.
- **Vetted Artisans**: Every tradesperson undergoes CNI identity verification, skill assessment, and location mapping.
- **The "Trust Nexus" Symbol**: An architectural shield with an interlocking kinetic "S" flow and central escrow verification node, expressing authority, modern technology, and local relevance.

---

## 2. Color Palette Specification

The **Atlantic Sovereign** palette blends authoritative deep maritime blues with the earthy, warm ochres and burnt siennas native to Cameroon's soil and craft heritage. It commands institutional trust like a premier financial institution while remaining warm, accessible, and grounded.

### 2.1 Primary Brand Colors

| Token Name | Hex Code | RGB | HSL | Intended Usage |
| :--- | :--- | :--- | :--- | :--- |
| `color_primary` | `#152238` | `rgb(21, 34, 56)` | `hsl(218, 45%, 15%)` | Primary brand anchor, app bars, top navigation headers, primary buttons, authoritative headings. |
| `color_primary_dark` | `#0B1320` | `rgb(11, 19, 32)` | `hsl(217, 49%, 8%)` | Midnight background for dark mode, bottom navigation bar fill, splash screen depth layer. |
| `color_primary_light` | `#243656` | `rgb(36, 54, 86)` | `hsl(218, 41%, 24%)` | Secondary headers in dark surfaces, active list item highlights, border accents on dark backgrounds. |

### 2.2 Secondary Accent Colors

| Token Name | Hex Code | RGB | HSL | Intended Usage |
| :--- | :--- | :--- | :--- | :--- |
| `color_secondary` | `#B86B3E` | `rgb(184, 107, 62)` | `hsl(22, 50%, 48%)` | Primary CTA accents, milestone completion badges, rating stars, price highlights, call-to-action buttons. |
| `color_secondary_dark` | `#944F25` | `rgb(148, 79, 37)` | `hsl(23, 60%, 36%)` | High-contrast secondary text on light cards (WCAG AA compliant for small body text), pressed button state. |
| `color_secondary_light` | `#D48B5C` | `rgb(212, 139, 92)` | `hsl(23, 58%, 60%)` | Secondary accents on dark backgrounds, active icon badges, hover ring highlights. |

### 2.3 Surface & Canvas Tokens

| Token Name | Hex Code | RGB | HSL | Intended Usage |
| :--- | :--- | :--- | :--- | :--- |
| `color_bg_light` | `#F8FAFC` | `rgb(248, 250, 252)` | `hsl(210, 40%, 98%)` | Default scaffold and page background for clean readability under direct sunlight. |
| `color_card_light` | `#FFFFFF` | `rgb(255, 255, 255)` | `hsl(0, 0%, 100%)` | Card surface, modal sheets, bottom sheets, form input backgrounds. |
| `color_bg_dark` | `#0B1320` | `rgb(11, 19, 32)` | `hsl(217, 49%, 8%)` | Dark theme default scaffold background. |
| `color_card_dark` | `#152238` | `rgb(21, 34, 56)` | `hsl(218, 45%, 15%)` | Dark theme card containers, dialog boxes, elevated panels. |

### 2.4 Text & Typography Tokens

| Token Name | Hex Code | RGB | HSL | Intended Usage |
| :--- | :--- | :--- | :--- | :--- |
| `color_text_primary` | `#0F172A` | `rgb(15, 23, 42)` | `hsl(222, 47%, 11%)` | Headings, titles, primary labels, price tags on light surfaces. |
| `color_text_secondary`| `#475569` | `rgb(71, 85, 105)` | `hsl(215, 19%, 35%)` | Body paragraphs, secondary metadata, artisan bios, dates. |
| `color_text_muted` | `#64748B` | `rgb(100, 116, 139)` | `hsl(215, 16%, 47%)` | Form input placeholders, captions, disabled states, unselected tabs. |
| `color_text_inverse` | `#FFFFFF` | `rgb(255, 255, 255)` | `hsl(0, 0%, 100%)` | Text on Primary Navy containers, dark theme text, CTA button labels. |

### 2.5 Borders & Dividers

| Token Name | Hex Code | RGB | HSL | Intended Usage |
| :--- | :--- | :--- | :--- | :--- |
| `color_border_light` | `#E2E8F0` | `rgb(226, 232, 240)` | `hsl(214, 32%, 91%)` | Card borders, text field outlines, horizontal separators in light theme. |
| `color_border_dark` | `#243656` | `rgb(36, 54, 86)` | `hsl(218, 41%, 24%)` | Card borders, modal divider lines in dark theme. |

### 2.6 Semantic & Transaction Status Colors

| Semantic State | Hex Code | Tint Background | Contrast on Tint | Text-on-Color Contrast | Intended Usage |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Success** | `#166534` | `#DCFCE7` | **6.49 : 1** (Pass AA) | **7.13 : 1** (Pass AAA on #FFFFFF) | Escrow released, job completed, verified artisan badge, payment success. |
| **Warning** | `#B45309` | `#FEF3C7` | **4.51 : 1** (Pass AA) | **5.02 : 1** (Pass AA on #FFFFFF) | Escrow pending approval, quotation awaiting acceptance, expiring request. |
| **Error** | `#B91C1C` | `#FEE2E2` | **5.30 : 1** (Pass AA) | **6.47 : 1** (Pass AAA on #FFFFFF) | Payment failed, dispute raised, artisan cancelled, invalid phone number. |
| **Info** | `#1D4ED8` | `#DBEAFE` | **5.49 : 1** (Pass AA) | **6.70 : 1** (Pass AAA on #FFFFFF) | System notice, milestone in progress, quotation revision available. |

### 2.7 Accessibility Verification Matrix (WCAG 2.1 AA)

All core UI pairings exceed WCAG AA requirements (minimum 4.5:1 for normal text, 3:1 for large text and UI components):

- `color_text_primary` on `color_bg_light` (`#0F172A` on `#F8FAFC`): **17.06 : 1** (Certified AAA)
- `color_text_primary` on `color_card_light` (`#0F172A` on `#FFFFFF`): **17.85 : 1** (Certified AAA)
- `color_text_secondary` on `color_bg_light` (`#475569` on `#F8FAFC`): **7.24 : 1** (Certified AAA)
- `color_text_muted` on `color_bg_light` (`#64748B` on `#F8FAFC`): **4.55 : 1** (Certified AA Normal)
- `color_text_inverse` on `color_primary` (`#FFFFFF` on `#152238`): **15.94 : 1** (Certified AAA)
- `color_text_inverse` on `color_primary_dark` (`#FFFFFF` on `#0B1320`): **18.61 : 1** (Certified AAA)
- `color_text_inverse` on `color_secondary` (`#FFFFFF` on `#B86B3E`): **4.03 : 1** (Certified AA for UI buttons and text ≥ 18px)
- `color_text_inverse` on `color_secondary_dark` (`#FFFFFF` on `#944F25`): **6.17 : 1** (Certified AA for all text sizes)

---

## 3. Typography Specification

### 3.1 Primary Typeface
- **Family Name**: Plus Jakarta Sans
- **Category**: Geometric Sans-Serif with Humanist Terminals
- **CSS font-family**: `'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif`
- **Google Fonts CDN**: [https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap](https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap)

### 3.2 Font Weight Hierarchy
- **Regular (400)**: Default body copy, multi-line job descriptions, quotation breakdown terms.
- **Medium (500)**: Form input values, secondary metadata, chips, subtle interactive labels.
- **SemiBold (600)**: Subheadings, section titles, card headers, table headers, verified badges.
- **Bold (700)**: Screen titles, primary CTA button labels, key numeric totals (XAF currency amounts).
- **ExtraBold (800)**: Brand wordmark ("HUB"), display highlights, hero promotion stat counters.

### 3.3 Typeface Justification
1. **Geometric Harmony with Trust Nexus Symbol**: The clean circular curves of Plus Jakarta Sans ('o', 'C', 'G', 'S') mirror the exact mathematical curvature of the Trust Nexus shield and circular verification node.
2. **Mobile Readability on Budget Screens**: ServiceHUB serves users across Cameroon accessing the platform via diverse Android devices (Tecno, Infinix, Samsung A-series) often under harsh sunlight. Plus Jakarta Sans features open counters, tall x-height, and distinct character apertures that resist pixel smearing at low PPI.
3. **Institutional Modernity**: It moves ServiceHUB away from generic system fonts (Roboto/Arial) into a distinctive, world-class fintech aesthetic that reinforces trust and security.

### 3.4 Type Scale Specification

| Scale Step | Font Size | Line Height | Font Weight | Letter Spacing | Flutter TextStyle Equivalent | Intended Usage |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Display** | `36px` | `44px` (`1.22`) | Bold (`700`) | `-0.02em` (`-0.72px`) | `theme.textTheme.displayMedium` | Splash screen slogan, onboarding hero headers. |
| **Heading 1** | `28px` | `36px` (`1.28`) | Bold (`700`) | `-0.015em` (`-0.42px`) | `theme.textTheme.headlineLarge` | Dashboard greeting, marketplace main category titles. |
| **Heading 2** | `22px` | `28px` (`1.27`) | Bold (`700`) | `-0.01em` (`-0.22px`) | `theme.textTheme.headlineMedium` | Artisan profile names, quotation summary title. |
| **Heading 3** | `18px` | `24px` (`1.33`) | SemiBold (`600`) | `0.0em` (`0.0px`) | `theme.textTheme.titleLarge` | Service category card headers, escrow milestone title. |
| **Heading 4** | `16px` | `22px` (`1.38`) | SemiBold (`600`) | `0.0em` (`0.0px`) | `theme.textTheme.titleMedium` | Section sub-headers, list group headers. |
| **Body Large** | `16px` | `24px` (`1.50`) | Regular (`400`) | `0.0em` (`0.0px`) | `theme.textTheme.bodyLarge` | Primary descriptive text, job scope paragraphs. |
| **Body Medium** | `14px` | `20px` (`1.43`) | Regular (`400`) | `0.0em` (`0.0px`) | `theme.textTheme.bodyMedium` | Standard card content, artisan reviews, form labels. |
| **Body Small** | `12px` | `16px` (`1.33`) | Regular (`400`) | `+0.01em` (`+0.12px`) | `theme.textTheme.bodySmall` | Secondary timestamp metadata, artisan trade category. |
| **Caption** | `11px` | `14px` (`1.27`) | Medium (`500`) | `+0.02em` (`+0.22px`) | `theme.textTheme.labelSmall` | Helper text, input validation hints, small badges. |
| **Overline** | `10px` | `14px` (`1.40`) | Bold (`700`) | `+0.08em` (`+0.80px`) | `theme.textTheme.labelSmall` (uppercase) | Taglines ("CAMEROON VERIFIED"), status categories. |

---

## 4. Spacing, Layout & Grid System

### 4.1 Base System
ServiceHUB adheres strictly to an **8-point spatial grid** with a **4-point micro-step** for tight component padding and icon offsets.

### 4.2 Spacing Scale

| Token Name | Size | Multiplier | Intended Usage |
| :--- | :--- | :--- | :--- |
| `spacing_xxs` | `2px` | 0.25x | Border widths, badge inner offsets, micro indicators. |
| `spacing_xs` | `4px` | 0.5x | Icon-to-label gaps, tight tag padding, rating star gutters. |
| `spacing_sm` | `8px` | 1.0x | Inner card element spacing, chip horizontal padding, compact lists. |
| `spacing_md` | `16px` | 2.0x | Standard screen horizontal margin (mobile), form field gaps, card padding. |
| `spacing_lg` | `24px` | 3.0x | Section separators, modal inner margins, bottom sheet top padding. |
| `spacing_xl` | `32px` | 4.0x | Header-to-content separation, hero section bottom margin. |
| `spacing_2xl` | `48px` | 6.0x | Splash screen element spacing, major workflow milestones. |
| `spacing_3xl` | `64px` | 8.0x | Onboarding page margins, tablet layout structural column gutters. |

### 4.3 Border Radius Scale

| Token Name | Radius | Intended Usage |
| :--- | :--- | :--- |
| `radius_none` | `0px` | Full-width divider banners, image strips. |
| `radius_sm` | `4px` | Small status tags, micro badges, tooltips. |
| `radius_md` | `8px` | Text inputs, dropdown menus, secondary buttons, review tiles. |
| `radius_lg` | `12px` | Primary service cards, artisan listing cards, modal dialogs. |
| `radius_xl` | `16px` | Bottom sheets, featured promotional hero cards. |
| `radius_full` | `9999px` | Pill buttons, search bars, verified artisan badges, avatar circles. |

### 4.4 Elevation & Shadow Scale

| Token Name | Blur / Spread | Offset (X, Y) | Color / Opacity | Intended Usage |
| :--- | :--- | :--- | :--- | :--- |
| `shadow_none` | `0px` / `0px` | `(0, 0)` | `transparent` | Flat cards, outlined buttons. |
| `shadow_low` | `4px` / `0px` | `(0, 1px)` | `rgba(15, 23, 42, 0.05)` | Idle card containers, artisan list items on light background. |
| `shadow_medium` | `12px` / `-2px`| `(0, 4px)` | `rgba(15, 23, 42, 0.08)` | Card hover / press state, dropdown menus, floating action buttons. |
| `shadow_high` | `24px` / `-4px`| `(0, 10px)` | `rgba(15, 23, 42, 0.14)` | Bottom sheets, confirmation modals, escrow payment authorization drawers. |

---

## 5. Component Tokens Specification

### 5.1 Button Styles

#### Primary Button (High Priority Actions: "Accept Quotation", "Release Escrow", "Confirm Booking")
- **Height**: `48px` (standard touch target)
- **Border Radius**: `radius_md` (`8px`) or `radius_full` (`9999px` for floating CTAs)
- **Padding**: Horizontal `24px`, Vertical `12px`
- **Typography**: Plus Jakarta Sans Bold (`700`), `16px`, line-height `20px`
- **Default State**: Background `color_primary` (`#152238`), Text `#FFFFFF`
- **Hover / Focus**: Background `color_primary_light` (`#243656`), Box-shadow `shadow_medium`
- **Active / Pressed**: Background `color_primary_dark` (`#0B1320`), scale `0.98`
- **Disabled State**: Background `#E2E8F0`, Text `#94A3B8`, Cursor `not-allowed`

#### Secondary Button (Prominent Accent Actions: "Pay with MTN/Orange Money", "Book Artisan")
- **Height**: `48px`
- **Border Radius**: `radius_md` (`8px`)
- **Default State**: Background `color_secondary` (`#B86B3E`), Text `#FFFFFF`
- **Hover / Focus**: Background `color_secondary_light` (`#D48B5C`)
- **Active / Pressed**: Background `color_secondary_dark` (`#944F25`), scale `0.98`
- **Disabled State**: Background `#F1E5DE`, Text `#C5A898`

#### Outline Button (Secondary Navigation: "View Profile", "Filter Trades")
- **Height**: `48px`
- **Border Radius**: `radius_md` (`8px`)
- **Border**: `1.5px` solid `color_primary` (`#152238`)
- **Default State**: Background `transparent`, Text `color_primary` (`#152238`)
- **Hover / Focus**: Background `rgba(21, 34, 56, 0.05)`
- **Active / Pressed**: Background `rgba(21, 34, 56, 0.10)`
- **Disabled State**: Border `#CBD5E1`, Text `#94A3B8`

#### Ghost Button (Low Priority: "Cancel", "Skip", "Need Help?")
- **Height**: `40px`
- **Border Radius**: `radius_md` (`8px`)
- **Default State**: Background `transparent`, Text `color_text_secondary` (`#475569`)
- **Hover / Focus**: Background `#F1F5F9`, Text `color_text_primary` (`#0F172A`)
- **Active / Pressed**: Background `#E2E8F0`
- **Disabled State**: Text `#CBD5E1`

### 5.2 Input Field Tokens
- **Height**: `48px`
- **Corner Radius**: `radius_md` (`8px`)
- **Inner Padding**: Horizontal `16px`, Vertical `12px`
- **Typography**: Plus Jakarta Sans Regular (`400`), `14px`
- **Default State**: Background `#FFFFFF`, Border `1px` solid `color_border_light` (`#E2E8F0`), Text `#0F172A`, Placeholder `color_text_muted` (`#64748B`)
- **Focus State**: Border `2px` solid `color_primary` (`#152238`), Box-shadow `0 0 0 3px rgba(21, 34, 56, 0.12)`
- **Error State**: Border `1.5px` solid `#B91C1C`, Helper text `#B91C1C` (12px), Background `#FEF2F2`
- **Disabled State**: Background `#F8FAFC`, Border `1px` solid `#E2E8F0`, Text `#94A3B8`

### 5.3 Card Styles
- **Default Flat Card**: Background `#FFFFFF`, Border `1px` solid `color_border_light` (`#E2E8F0`), Radius `radius_lg` (`12px`), Padding `16px`
- **Elevated Card**: Background `#FFFFFF`, Shadow `shadow_low`, Radius `radius_lg` (`12px`), Padding `16px`
- **Interactive Card (Artisan Directory Tile)**:
  - Default: Border `1px` solid `#E2E8F0`, Shadow `shadow_low`
  - Pressed/Active: Border `1.5px` solid `color_primary` (`#152238`), Shadow `shadow_medium`

### 5.4 Badge & Status Tag Styles

| Badge Type | Background Color | Text / Border Color | Icon | Intended Usage |
| :--- | :--- | :--- | :--- | :--- |
| **Default Neutral** | `#F1F5F9` | `#475569` | None | Category filter chip ("Plumbing", "Douala V"). |
| **Success** | `#DCFCE7` | `#166534` | Checkmark | "Completed", "Paid in Full", "CNI Verified". |
| **Warning** | `#FEF3C7` | `#B45309` | Clock / Alert | "Escrow Locked", "Pending Artisan Quote". |
| **Error** | `#FEE2E2` | `#B91C1C` | Alert Triangle | "Dispute Opened", "Action Required". |
| **Info** | `#DBEAFE` | `#1D4ED8` | Info Circle | "In Progress", "Artisan En Route". |

### 5.5 Trust Badge Specification (The ServiceHUB Verification Guarantee)
The Trust Badge is a central component displayed next to vetted artisan names and escrow financial milestones.

- **Component Name**: `ServiceHubTrustBadge`
- **Geometry**: Pill badge (`radius_full`) or standalone `16px` shield icon.
- **Color Treatment**:
  - Background: Soft Cream / Warm Ivory (`#F2EBDC`) or Forest Emerald Tint (`#DCFCE7`)
  - Icon: Atlantic Navy (`#152238`) shield silhouette with Ochre Gold (`#B86B3E`) center checkmark.
  - Text Label: "VERIFIED ARTISAN" or "SECURE ESCROW" in Plus Jakarta Sans Bold (`700`), `10px`, letter-spacing `+0.06em`, color `#152238`.
  - Border: `1px` solid `#D48B5C` (`color_secondary_light`).
- **Escrow Guarantee Ribbon**:
  - Displayed on quotation acceptance and payment confirmation screens:
  - "Funds held safely in ServiceHUB Escrow until you inspect and approve completed work."

---

## 6. Iconography Guidelines

### 6.1 Recommended Icon Set
- **Primary Library**: **Lucide Icons** (recommended for Flutter via `lucide_icons` package) or **Google Material Symbols Rounded**.
- **Rationale**: Clean, consistent geometric stroke curves that harmonize with Plus Jakarta Sans and the Trust Nexus symbol.

### 6.2 Sizing Scale
- **Micro (`16px`)**: Input field clear buttons, inline verified checkmarks, table indicators.
- **Small (`20px`)**: List item trailing chevrons, chip prefix icons, rating stars.
- **Standard (`24px`)**: Bottom navigation bar icons, app bar action icons, form input leading icons.
- **Large (`32px`)**: Service category headers, empty state iconography, payment provider logos.

### 6.3 Stroke Weight Consistency
- Default stroke weight: **`2.0px`** on standard `24px` frames.
- Micro stroke weight: **`1.5px`** on `16px` frames to prevent visual congestion.

### 6.4 Filled vs. Outlined Usage Rules
- **Outlined Icons**: Default state across all navigation items, list headers, and action buttons.
- **Filled Icons**: Reserved exclusively for **Active / Selected states** (e.g., active bottom navigation tab, favorited artisan heart, selected star rating).

---

## 7. Production Asset Inventory

All production brand assets are located in `servicehub_frontend/assets/brand/`:

| File Name | Format | Dimensions | Specs / Details |
| :--- | :--- | :--- | :--- |
| [`logo_primary.svg`](file:///c:/Users/PC/Desktop/DIGITAL-SERVICE-MARKETPLACE/servicehub_frontend/assets/brand/logo_primary.svg) | SVG | `513 x 128` | Full color horizontal lockup (Symbol + Wordmark + Tagline). Text converted to pure vector paths. |
| [`logo_stacked.svg`](file:///c:/Users/PC/Desktop/DIGITAL-SERVICE-MARKETPLACE/servicehub_frontend/assets/brand/logo_stacked.svg) | SVG | `340 x 320` | Full color stacked lockup for splash screens, letterheads, centered documents. Text converted to paths. |
| [`logo_symbol.svg`](file:///c:/Users/PC/Desktop/DIGITAL-SERVICE-MARKETPLACE/servicehub_frontend/assets/brand/logo_symbol.svg) | SVG | `120 x 120` | Standalone Trust Nexus symbol, bounded tight with 8% padding. |
| [`logo_monochrome.svg`](file:///c:/Users/PC/Desktop/DIGITAL-SERVICE-MARKETPLACE/servicehub_frontend/assets/brand/logo_monochrome.svg) | SVG | `513 x 128` | Single-color (`#000000`) using negative space cutouts. Fully functional on white, black, or color. |
| [`logo_light_bg.png`](file:///c:/Users/PC/Desktop/DIGITAL-SERVICE-MARKETPLACE/servicehub_frontend/assets/brand/logo_light_bg.png) | PNG | `2080 x 519` | 4x resolution horizontal lockup for light surfaces. Transparent background. |
| [`logo_dark_bg.png`](file:///c:/Users/PC/Desktop/DIGITAL-SERVICE-MARKETPLACE/servicehub_frontend/assets/brand/logo_dark_bg.png) | PNG | `2080 x 519` | 4x resolution horizontal lockup for dark surfaces (white wordmark + ochre accents). Transparent bg. |
| [`app_icon_1024.png`](file:///c:/Users/PC/Desktop/DIGITAL-SERVICE-MARKETPLACE/servicehub_frontend/assets/brand/app_icon_1024.png) | PNG | `1024 x 1024` | Master app icon with Atlantic Navy gradient background, safe-zone symbol for iOS and Android. |
| [`favicon_32.png`](file:///c:/Users/PC/Desktop/DIGITAL-SERVICE-MARKETPLACE/servicehub_frontend/assets/brand/favicon_32.png) | PNG | `32 x 32` | Pixel-aligned 32px favicon optimized for web browser tabs. Transparent background. |
| [`favicon_16.png`](file:///c:/Users/PC/Desktop/DIGITAL-SERVICE-MARKETPLACE/servicehub_frontend/assets/brand/favicon_16.png) | PNG | `16 x 16` | Pixel-aligned 16px micro-favicon optimized for bookmark bars and URL fields. Transparent background. |

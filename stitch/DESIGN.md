---
name: Financial Clarity
colors:
  surface: '#faf8ff'
  surface-dim: '#d8d9e6'
  surface-bright: '#faf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f3ff'
  surface-container: '#ecedfa'
  surface-container-high: '#e6e7f4'
  surface-container-highest: '#e1e2ee'
  on-surface: '#191b24'
  on-surface-variant: '#424656'
  inverse-surface: '#2e303a'
  inverse-on-surface: '#eff0fd'
  outline: '#737687'
  outline-variant: '#c2c6d8'
  surface-tint: '#0054d8'
  primary: '#004ecb'
  on-primary: '#ffffff'
  primary-container: '#0064ff'
  on-primary-container: '#f5f5ff'
  inverse-primary: '#b3c5ff'
  secondary: '#5c5f61'
  on-secondary: '#ffffff'
  secondary-container: '#e0e3e5'
  on-secondary-container: '#626567'
  tertiary: '#a03200'
  on-tertiary: '#ffffff'
  tertiary-container: '#ca4101'
  on-tertiary-container: '#fff4f0'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dbe1ff'
  primary-fixed-dim: '#b3c5ff'
  on-primary-fixed: '#00174a'
  on-primary-fixed-variant: '#003ea6'
  secondary-fixed: '#e0e3e5'
  secondary-fixed-dim: '#c4c7c9'
  on-secondary-fixed: '#191c1e'
  on-secondary-fixed-variant: '#444749'
  tertiary-fixed: '#ffdbd0'
  tertiary-fixed-dim: '#ffb59c'
  on-tertiary-fixed: '#390c00'
  on-tertiary-fixed-variant: '#832700'
  background: '#faf8ff'
  on-background: '#191b24'
  surface-variant: '#e1e2ee'
typography:
  headline-xl:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: '1.3'
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: '1.3'
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: '1.4'
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Inter
    fontSize: 17px
    fontWeight: '400'
    lineHeight: '1.6'
    letterSpacing: -0.01em
  body-md:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '400'
    lineHeight: '1.6'
    letterSpacing: '0'
  label-md:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '500'
    lineHeight: '1.4'
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: '1.2'
    letterSpacing: 0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 40px
  margin-safe: 20px
  gutter: 12px
---

## Brand & Style

This design system is built on the principles of hyper-functional minimalism and radical clarity. Moving away from the warm, organic tones of the previous aesthetic, this system adopts the precision and trustworthiness of a modern fintech platform. The brand personality is efficient, transparent, and sophisticated, aiming to make every interaction feel instantaneous and effortless.

The design style is **Minimalism** blended with **Corporate Modern**. It prioritizes a reductionist approach where every element serves a functional purpose. High-contrast typography and a restricted color palette ensure that information density remains manageable, while generous whitespace prevents cognitive overload. The result is a UI that feels reliable, premium, and exceptionally easy to navigate.

## Colors

The color palette is anchored by a high-energy primary blue, specifically chosen for its association with digital innovation and financial security. 

- **Primary Action:** Use #0064FF exclusively for primary buttons, active states, and critical interaction points.
- **Surface & Backgrounds:** The base of the application is #FFFFFF. Secondary surfaces, such as card containers or background sections behind content, utilize the cool grey #F2F4F6 to create subtle structural depth.
- **Typography Scale:** A rigorous four-tier grey scale is used to manage information hierarchy:
    - #191F28 for primary headings and titles (High contrast).
    - #4E5968 for body text and descriptive labels.
    - #8B95A1 for metadata and placeholder text.

## Typography

The typography utilizes **Inter**, a typeface designed for maximum readability on digital screens. The hierarchy is characterized by significant weight contrast between bold, impactful headings and clean, utilitarian body text.

To maintain the "financial app" feel:
- Use **negative letter-spacing** on larger headlines to create a tighter, more professional "editorial" look.
- Headings should lead with high weight (600-700) to anchor the page layout.
- Body text uses a generous line height (1.6) to ensure long-form content is digestible.
- Labels and captions should be used sparingly, primarily for supplementary information or overlines.

## Layout & Spacing

This design system employs a **fluid grid** model with a base-4 rhythm. Content is generally housed within a flexible container that stretches to the viewport edges, protected by a 20px safe-area margin on mobile.

Layout components should rely heavily on vertical stacks with generous gaps (typically 24px or 40px) to separate distinct logical sections. Padding within containers (like cards) should be consistent—usually 24px—to provide a luxurious, airy feel that emphasizes ease of use.

## Elevation & Depth

Depth is conveyed through **tonal layers** and **ambient shadows**. Rather than heavy drop shadows, the system uses "soft-touch" elevation to maintain its clean aesthetic.

- **Level 0 (Base):** Pure #FFFFFF background.
- **Level 1 (Sectioning):** Use #F2F4F6 as a background for sections to make white cards "pop."
- **Level 2 (Interactive):** Cards and floating elements use an extremely diffused shadow: `0px 4px 20px rgba(0, 0, 0, 0.04)`.
- **Level 3 (Overlays):** Modals and bottom sheets use a slightly deeper shadow with a larger blur radius to indicate height above the primary UI plane.

Avoid using borders for containment; let the contrast between #FFFFFF surfaces and #F2F4F6 backgrounds define the structure.

## Shapes

The shape language is defined by large, friendly radii that soften the technical nature of the UI. This design system uses a **Rounded** (Level 2) approach. 

- **Standard Buttons & Inputs:** 0.75rem (12px) to 1rem (16px) radius.
- **Cards & Containers:** 1.5rem (24px) radius.
- **Small Elements (Chips/Tags):** Fully rounded (pill-shaped) for maximum distinctiveness.

The curvature should be consistent across all components to ensure the interface feels cohesive and intentionally designed.

## Components

### Buttons
Primary buttons are solid #0064FF with white text and a 16px corner radius. Secondary buttons should use #F2F4F6 as a background with #4E5968 text, avoiding borders to maintain a "soft" appearance.

### Cards
Cards are the primary organizational unit. They are always white (#FFFFFF) with a 24px border radius and a subtle ambient shadow. Use cards to group related information like financial summaries, menu items, or user profiles.

### Inputs
Input fields use the #F2F4F6 background with no border in their default state. Upon focus, they transition to a white background with a 2px #0064FF solid stroke. Text within inputs uses #191F28 for clarity.

### Chips & Tags
Used for filtering or status indicators. They are small, pill-shaped, and use low-saturation background tints (e.g., #F2F4F6) with medium-grey text (#4E5968) to avoid competing with primary action buttons.

### Icons
Use thin, 2px stroke line icons. Icons should be monochromatic, typically using #4E5968 or #8B95A1, unless they are part of a primary action.

### List Items
List items should feature generous vertical padding (16px - 20px) and use subtle dividers (1px solid #F2F4F6) only when necessary for extreme density. Otherwise, whitespace is the preferred separator.
# Design System Strategy: The Curated Canvas

This design system is a transition from utility to editorial excellence. Inspired by the refined energy of the original "Chicken Map" aesthetic, this system evolves those core concepts into a high-end, tactile interface. We are moving away from the "app-template" look toward a "digital boutique" experience, characterized by intentional asymmetry, sophisticated tonal layering, and an uncompromising approach to whitespace.

## 1. Creative North Star: "Refined Utility"
The Creative North Star for this design system is **Refined Utility**. This means every element on the screen—from a single input field to a primary CTA—is treated as an object of design rather than a functional necessity. We break the rigid, centered grid of standard mobile apps by using generous leading, staggered typography scales, and surfaces that feel layered like fine stationery.

## 2. Colors & Tonal Architecture
The palette is a sophisticated interplay of deep navies, vibrant burnt oranges, and a spectrum of "cool-greige" neutrals. 

### The "No-Line" Rule
To achieve a premium, editorial feel, **1px solid borders are strictly prohibited for sectioning.** We define boundaries through background color shifts. A layout should be composed of nested containers:
- **Base Layer:** `surface` (#f7f9fb)
- **Sectional Shift:** Use `surface_container_low` (#f2f4f6) to define large areas like a footer or a header block.
- **Interactive Focus:** Use `surface_container_lowest` (#ffffff) for cards and inputs to make them "pop" against the darker surface tiers.

### Glass & Gradient Rule
Standard flat colors lack "soul." 
- **The Signature CTA:** Buttons should utilize a subtle vertical gradient from `primary` (#000000) to `primary_container` (#341100) or use the accent `on_primary_container` (#da5e00) as a glow effect.
- **Floating Elements:** Use Glassmorphism for elements like "Top Ranking" chips or floating navigation. Apply `surface_container_lowest` at 70% opacity with a `24px` backdrop-blur to allow underlying content to bleed through softly.

## 3. Typography: Editorial Authority
We use **Manrope** as our typographic backbone. Its geometric yet organic curves provide a modern, approachable authority.

- **Display (Display-LG/MD):** Used for the brand identity. Apply a -2% letter spacing to create a compact, "logo-type" feel.
- **Headlines (Headline-SM):** For the primary screen greeting (e.g., "Welcome back"). This is the "voice" of the app.
- **Body (Body-LG):** For descriptions. We prioritize readability with a 1.5x line-height.
- **Labels (Label-MD):** For micro-copy and metadata. Use all-caps with +5% letter spacing to create a high-fashion, "label" look.

## 4. Elevation & Depth: Tonal Layering
Traditional drop shadows are often messy. This design system favors **Tonal Layering** to convey hierarchy.

- **The Layering Principle:** Place a `surface_container_lowest` (#ffffff) card on top of a `surface_container` (#eceef0) background. The contrast in light alone creates the lift.
- **Ambient Shadows:** When a floating effect is mandatory (e.g., a primary login card), use a shadow tinted with the `on_surface` (#191c1e) color at 6% opacity, with a blur radius of `32px`. It should feel like an atmospheric glow, not a dark smudge.
- **The Ghost Border:** If an element requires more definition (like a text input), use the `outline_variant` (#c6c6cd) at 20% opacity. It provides a "whisper" of a container without breaking the minimal aesthetic.

## 5. Components

### Primary Buttons
- **Style:** High roundedness (`full`).
- **Color:** `on_primary_container` (#da5e00) for the main action to echo the "vibrant orange" legacy.
- **Padding:** `1.4rem` (spacing 4) vertical height to ensure a premium, substantial touch target.

### Input Fields
- **Style:** Never use a bottom-line-only input. Use a filled container style using `surface_container_highest` (#e0e3e5) with `xl` (1.5rem) rounded corners.
- **States:** On focus, the container should shift to `surface_container_lowest` (#ffffff) with a 10% `primary` ghost border.

### Social Login Chips
- **Style:** Use a "Glass" variant. A `surface_container_lowest` base at 40% opacity with a `20% outline_variant` ghost border. This allows the login screen background to feel cohesive and expansive.

### Checkboxes & Radios
- **Style:** Use the `primary` (#000000) color for checked states. The "unchecked" state should use `outline_variant` at 30% opacity to remain nearly invisible until needed.

### Layout: Vertical White Space
Forbid the use of divider lines in lists. Use `spacing-6` (2rem) or `spacing-8` (2.75rem) to separate content blocks. Space is the luxury that defines this system.

## 6. Do's and Don'ts

### Do
- **Do** use `surface_bright` for the main background to keep the interface feeling airy and "lit from within."
- **Do** stagger your typography—mix `Display-MD` and `Label-SM` in close proximity to create visual interest through scale.
- **Do** use `xl` (1.5rem) corner radii for large containers to maintain the "sleek and soft" brand promise.

### Don't
- **Don't** use pure black (#000000) for body text; use `on_surface_variant` (#45474c) to keep the contrast high-end and "soft."
- **Don't** use standard "blue" for links. Use the refined navy `on_secondary_container` (#5c6477).
- **Don't** overcrowd the login screen. If a user needs to scroll, you have too much content. The login should be a single, curated moment.
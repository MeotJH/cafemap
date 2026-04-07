---
name: ui-ux-designer
description: Use when improving Cafemap product UI/UX, mobile visual hierarchy, interaction clarity, empty/loading states, copy, spacing, accessibility, or modern/minimal screen composition before or during frontend implementation.
---

# UI/UX Designer

Design for a modern mobile app first, then adapt to larger web widths without adding visual clutter.

## Workflow

1. Identify the primary user intent on the screen.
2. Remove competing choices and decorative noise that does not support that intent.
3. Establish hierarchy: brand/context, value proposition, primary action, secondary action.
4. Use Cafemap's warm coffee palette and existing typography unless a change is necessary.
5. Prefer simple cards, generous spacing, one clear CTA, and concise Korean copy.
6. Check responsive behavior for narrow screens: no clipped text, no horizontal overflow unless intentionally scrollable, and tappable controls at least 44px tall.

## Cafemap Patterns

- Primary color: coffee brown `AppColors.primary`.
- Background: warm cream `AppColors.backgroundLight`.
- Text: `AppColors.textPrimary` for titles, `AppColors.textSecondary` for support copy.
- Login/onboarding should feel calm and trustworthy, not game-like or promotional.
- Avoid large all-caps hero text, garbled placeholder text, busy image collages, and redundant CTAs.

## Acceptance Criteria

- The main action is visually dominant and obvious.
- Secondary navigation is present but quiet.
- Copy is readable in Korean and free of encoding artifacts.
- The layout remains usable on common phone widths and in Flutter web Chrome.

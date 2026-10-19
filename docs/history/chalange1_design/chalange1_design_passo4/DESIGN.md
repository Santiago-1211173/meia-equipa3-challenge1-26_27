---
name: Tactile Playful POS & Guided Retail
colors:
  surface: '#faf8ff'
  surface-dim: '#d2d9f4'
  surface-bright: '#faf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f3ff'
  surface-container: '#eaedff'
  surface-container-high: '#e2e7ff'
  surface-container-highest: '#dae2fd'
  on-surface: '#131b2e'
  on-surface-variant: '#3c4a42'
  inverse-surface: '#283044'
  inverse-on-surface: '#eef0ff'
  outline: '#6c7a71'
  outline-variant: '#bbcabf'
  surface-tint: '#006c49'
  primary: '#006c49'
  on-primary: '#ffffff'
  primary-container: '#10b981'
  on-primary-container: '#00422b'
  inverse-primary: '#4edea3'
  secondary: '#0058be'
  on-secondary: '#ffffff'
  secondary-container: '#2170e4'
  on-secondary-container: '#fefcff'
  tertiary: '#855300'
  on-tertiary: '#ffffff'
  tertiary-container: '#e29100'
  on-tertiary-container: '#523200'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#6ffbbe'
  primary-fixed-dim: '#4edea3'
  on-primary-fixed: '#002113'
  on-primary-fixed-variant: '#005236'
  secondary-fixed: '#d8e2ff'
  secondary-fixed-dim: '#adc6ff'
  on-secondary-fixed: '#001a42'
  on-secondary-fixed-variant: '#004395'
  tertiary-fixed: '#ffddb8'
  tertiary-fixed-dim: '#ffb95f'
  on-tertiary-fixed: '#2a1700'
  on-tertiary-fixed-variant: '#653e00'
  background: '#faf8ff'
  on-background: '#131b2e'
  surface-variant: '#dae2fd'
typography:
  display-hero:
    fontFamily: Plus Jakarta Sans
    fontSize: 40px
    fontWeight: '800'
    lineHeight: 48px
    letterSpacing: -0.03em
  display-hero-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '800'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 30px
    fontWeight: '700'
    lineHeight: 38px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 24px
  body-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 28px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '700'
    lineHeight: 18px
    letterSpacing: 0.02em
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.04em
  caption:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 1.5rem
  gutter-mobile: 1rem
  margin: 2rem
  margin-mobile: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2.5rem
---

## Brand & Style

This design system translates the engaging, friction-free psychology of modern gamified learning into commercial frontline point-of-sale and retail guidance. Frontline store associates face high cognitive load, complex store policies, and impatient customers. Rather than confronting staff with monolithic ERP forms or dense technical policy rule codes, this design system breaks every retail decision into bite-sized, single-focus micro-steps.

The brand personality is **upbeat, empathetic, ultra-clear, and tactile**. It blends gamified micro-interactions with high-trust commercial utility. 

Key aesthetic tenets:
- **Tactile Chunky Affordance:** Physical-feeling 3D button depths (subtle solid bottom borders/offsets), playful pill shapes, and squishy interactive click states that provide unmistakable haptic satisfaction.
- **Conversational Transparency:** Every compliance rule and backend validation step is framed in plain, cheerful human language. Jargon is forbidden on the primary canvas.
- **Cognitive Calm & Optimism:** Crisp, snowy-white floating cards on airy, soft tinted surfaces keep visual clutter at zero, while vibrant emeralds and cobalt blues reinforce confidence and clarity.

## Colors

The palette is engineered to feel vibrant, welcoming, and decisively communicative under bright in-store lighting conditions. The default mode is clean light mode.

- **Primary (`#10B981` / Emerald):** The hero color for resolution, success, and positive progression. Used for the prominent "Continue" actions, policy approvals, and completed progress milestones. Its deep counterpart (`#059669`) provides tactile bottom borders for 3D pressable buttons.
- **Secondary (`#3B82F6` / Bright Royal):** The navigational and interactive accent. Used for tactile selection states, primary interactive cards, and active toggle paths.
- **Tertiary (`#F59E0B` / Sunny Amber):** Reserved for contextual shifts, policy caveats, store credit redirections, and attention-worthy customer notices that do not constitute an error.
- **Neutral (`#0F172A` / Crisp Slate):** Anchors headlines and critical data tokens with high legibility. Supporting slate neutrals include `#64748B` for secondary explanatory copy and `#E2E8F0` for physical borders.
- **Canvas (`#F7F9FD` / Soft Cloud):** A gentle, slightly cool-tinted backdrop that provides soft contrast for pure `#FFFFFF` tactile card decks.

## Typography

The design system exclusively leverages **Plus Jakarta Sans** for headlines, conversational prompts, numeric balances, and UI labels. Its friendly geometric curves, wide apertures, and robust x-height maintain both approachable charm and pristine readability on handheld terminal screens and desktop registers.

Headlines adopt bold and extra-bold weights (`700` and `800`) with tight negative tracking to create compact, punchy question titles. Interactive choices feature prominent `body-xl` and `body-lg` sizes at medium (`500`) weight to eliminate misreads during active customer discussions. Helper prompts and policy walkthrough chips leverage uppercase-accented `label-lg` tokens for crisp hierarchy.

## Layout & Spacing

Layouts follow a focused, center-staged fluid model designed around bite-sized cognitive units. The core interaction zone conforms to a maximum width of `680px` on desktop and tablet terminals, centering the associate's attention entirely on the active decision card.

- **Breakpoints:**
  - `Mobile` (< 640px): Full-width single-column flow, bottom-docked primary action trays, and collapsed helper drawers.
  - `Tablet` (640px – 1024px): Standard POS counter view; centered card flow with balanced padding.
  - `Desktop` (> 1024px): Two-panel split view where the main interactive flow occupies the primary column, flanked by an optional live outcome simulator panel ("What If?") on the right.
- **Rhythm:** The layout scales strictly along `space-xs` through `space-xl`. Grouped multi-choice options use `space-md` gaps to prevent accidental touch strikes on POS hardware. Outer margins dynamically scale from `1rem` on mobile terminals to `2rem` on register displays.

## Elevation & Depth

This design system departs from hazy, realistic shadows in favor of **tactile 3D card borders and crisp stepped elevation** inspired by gamified interactive interfaces.

- **The Tactile Bottom Edge:** Every actionable element (cards, buttons, selection tiles) pairs a subtle outline (`border: 2px solid #E2E8F0`) with a reinforced 3px to 4px solid bottom rim (`border-bottom: 4px solid #CBD5E1` or darker color shades). On press or tap, the element translates downward by 2px with an immediate decrease in bottom border thickness, offering an authentic, mechanical feel.
- **Active Selection Tiers:** Unselected cards sit flat with a muted neutral rim. Selected states pop with a solid primary or secondary rim (`border: 2px solid #3B82F6; border-bottom: 4px solid #1D4ED8; background: #EFF6FF`).
- **Modal Sheets and Overlays:** Floating policy explainers ("Why do we ask this?") use soft ambient containment with pure white cards hovering over a 15% `#0F172A` scrim, accented with crisp 1px borders and no noisy blurs.

## Shapes

The design system embraces high roundedness (Level `3` / Pill-shaped).

- **Buttons & Chips:** Rendered as full pills (`border-radius: 9999px`), inviting immediate, friendly touch contact.
- **Interactive Question Cards:** Built with extra-soft structural corners (`rounded-xl` or `1.5rem / 24px`) to remove industrial sharp edges from customer-facing screens.
- **Timeline & Progress Trackers:** Segmented capsule indicators with smoothly rounded ends ensure continuous, rewarding visual momentum across workflow steps.

## Components

### Buttons
- **Primary Hero Button ("Continue", "Approve Refund"):** Full-width or auto pill button with an emerald base (`#10B981`), white bold typography, and a 4px dark emerald bottom rim (`#059669`). When pressed, translates down 2px with the rim collapsing to 2px.
- **Secondary Neutral Button ("Back", "Skip"):** Pill shape, transparent surface with a 2px `#E2E8F0` border and a `#CBD5E1` bottom rim. Text is `#64748B`.

### Interactive Micro-Choice Cards
- Large, tactile horizontal cards presenting single options (e.g., "Tags are attached", "Tags are missing").
- Includes a leading playful micro-badge or icon container (48x48px rounded pill), bold title, and short supporting subtitle.
- Unselected: White background, 2px `#E2E8F0` border, 3px `#CBD5E1` bottom rim.
- Selected: `#EFF6FF` background, 2px `#3B82F6` border, 4px `#1D4ED8` bottom rim, trailing check circle.

### Progress Trackers
- A segmented top bar with pill-shaped capsules (`height: 10px; border-radius: 9999px; background: #E2E8F0`).
- Completed segments fill with `#10B981` accompanied by a playful spring animation.

### Policy Explainability Chips ("Why do we ask this?")
- A friendly, unobtrusive capsule chip placed immediately below question headlines.
- Styling: Pale slate-blue pill (`background: #F1F5F9; color: #475569; padding: 4px 12px; font-weight: 700`).
- Expands on tap to reveal a conversational single-sentence clarification bubble with a small arrow pointer.

### Decision Timeline ("How we decided")
- A clean, 3-step vertical card stack.
- Each milestone has a pill badge containing a green checkmark (`✓`) or an amber detour icon.
- Explains the outcome in plain retail math (e.g., *"1. Checked purchase date: 18 days ago (Within 30 days) ✓"*).

### "What If?" Scenario Toggles
- A dedicated tactile simulator module featuring chunky, rounded toggle switches.
- Allows the associate to test hypothetical paths (*"What if the customer finds the receipt?"*) with immediate, optimistic live outcome previews.
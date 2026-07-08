---
name: Obsidian Pulse Light
colors:
  surface: '#f9f9f9'
  surface-dim: '#dadada'
  surface-bright: '#f9f9f9'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3f3'
  surface-container: '#eeeeee'
  surface-container-high: '#e8e8e8'
  surface-container-highest: '#e2e2e2'
  on-surface: '#1a1c1c'
  on-surface-variant: '#434933'
  inverse-surface: '#2f3131'
  inverse-on-surface: '#f1f1f1'
  outline: '#737a61'
  outline-variant: '#c3caac'
  surface-tint: '#4c6700'
  primary: '#4c6700'
  on-primary: '#ffffff'
  primary-container: '#c0ff00'
  on-primary-container: '#557300'
  inverse-primary: '#a2d800'
  secondary: '#5e5e5e'
  on-secondary: '#ffffff'
  secondary-container: '#e2e2e2'
  on-secondary-container: '#646464'
  tertiary: '#516070'
  on-tertiary: '#ffffff'
  tertiary-container: '#ddecff'
  on-tertiary-container: '#5c6b7b'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#b9f600'
  primary-fixed-dim: '#a2d800'
  on-primary-fixed: '#141f00'
  on-primary-fixed-variant: '#384e00'
  secondary-fixed: '#e2e2e2'
  secondary-fixed-dim: '#c6c6c6'
  on-secondary-fixed: '#1b1b1b'
  on-secondary-fixed-variant: '#474747'
  tertiary-fixed: '#d5e4f7'
  tertiary-fixed-dim: '#b9c8da'
  on-tertiary-fixed: '#0e1d2a'
  on-tertiary-fixed-variant: '#3a4857'
  background: '#f9f9f9'
  on-background: '#1a1c1c'
  surface-variant: '#e2e2e2'
typography:
  display:
    fontFamily: Inter
    fontSize: 64px
    fontWeight: '800'
    lineHeight: '1.1'
    letterSpacing: -0.04em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.3'
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.6'
    letterSpacing: '0'
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.5'
    letterSpacing: '0'
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: '1'
    letterSpacing: 0.02em
  mono-label:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: '1'
    letterSpacing: 0.05em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 24px
  lg: 48px
  xl: 80px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 40px
---

## Brand & Style

This design system translates a high-energy, performance-driven aesthetic into a pristine, light-mode environment. It targets high-productivity users who require a clean, distraction-free interface that still feels cinematic and intentional. 

The style is **High-Contrast Minimalism**. It leverages the starkness of pure white space against sharp, black typography and a singular, high-impact neon accent. While the vibe remains technical and "pro-grade," the light-themed approach shifts the emotional response from "late-night hacking" to "daylight precision." The UI should feel fast, breathable, and authoritative.

## Colors

The palette is built on a foundation of absolute white (`#FFFFFF`) to ensure maximum clarity and perceived speed. 

- **Primary Neon**: `#C0FF00` is used exclusively for high-priority actions, progress indicators, and status highlights. It must always be paired with black text or icons to maintain accessibility.
- **Pure Black**: Used for primary headings and core UI elements to create a grounded, "ink-on-paper" feel.
- **Surface Grays**: Subtle shifts in gray (`#F9F9F9` and `#F2F2F2`) differentiate containers and cards from the main background without introducing heavy visual weight.
- **Borders**: Soft, low-contrast lines (`#E5E5E5`) define structure while maintaining the minimalist ethos.

## Typography

The typography system relies on **Inter** to deliver a systematic, neutral, and high-performance feel. 

Headlines use tight letter-spacing and heavy weights to create a sense of urgency and importance. Body text is optimized for readability with generous line heights. Labels utilize uppercase styling with increased tracking to differentiate "metadata" from "content." Large display type should be used sparingly for impactful editorial moments.

## Layout & Spacing

The layout philosophy is centered on a **Fluid Grid** with wide margins to emphasize the minimalist aesthetic. 

- **Grid**: A 12-column system for desktop, collapsing to 4 columns on mobile.
- **Rhythm**: All spacing follows an 8px base unit. 
- **Density**: The design favors "Airy" density for information-heavy dashboards, using large `xl` padding for section headers and `md` padding for interior card elements. 
- **Reflow**: On mobile, horizontal margins tighten to 16px, and multi-column card layouts stack vertically to maintain legibility.

## Elevation & Depth

In this design system, depth is achieved through **Tonal Layering** and **Subtle Ambient Shadows**. 

1.  **Level 0 (Background)**: Pure `#FFFFFF`.
2.  **Level 1 (Surface)**: `#F9F9F9`. Used for secondary content areas or sidebars.
3.  **Level 2 (Cards)**: White surfaces with a very soft, highly diffused shadow (5% opacity, 12px blur, 4px Y-offset). This creates a "floating" effect without the heaviness of traditional drop shadows.
4.  **Level 3 (Modals/Popovers)**: White surfaces with a more pronounced shadow (10% opacity, 32px blur) to draw immediate focus.

Avoid deep glows. Focus on clean, crisp edges and very light tinting for depth.

## Shapes

The shape language is **Soft and Precise**. 

A small radius (4px to 8px) is applied to buttons and inputs to take the edge off the brutalist tendencies of the typography, keeping the UI professional and approachable. Cards utilize the `rounded-lg` (8px) setting. Progress bars and status tags use the `rounded-xl` (12px) setting to provide a visual contrast against the more geometric structural elements.

## Components

- **Buttons**:
    - *Primary*: Background `#C0FF00`, Text `#000000`, Heavy weight. No shadow.
    - *Secondary*: Background `#000000`, Text `#FFFFFF`.
    - *Ghost*: Border `1px solid #E5E5E5`, Text `#000000`.
- **Input Fields**: Flat white background with a 1px `#E5E5E5` border. On focus, the border changes to `#000000`. No glows.
- **Chips/Badges**: Small, uppercase text. For "Active" states, use `#C0FF00` background. For "Neutral" states, use `#F2F2F2`.
- **Cards**: Use `#FFFFFF` background with the Level 2 shadow. No border is necessary if the shadow provides enough separation from the `#F9F9F9` surface.
- **Lists**: Clean rows separated by 1px `#E5E5E5` dividers. Use `mono-label` for secondary list data (timestamps, IDs).
- **Progress Bars**: Background `#F2F2F2`, Fill `#C0FF00`. The contrast between the neon green and the light gray signifies high-performance tracking.
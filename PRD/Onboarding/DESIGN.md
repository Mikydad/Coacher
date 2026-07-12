---
name: Ethereal Path
colors:
  surface: '#111317'
  surface-dim: '#111317'
  surface-bright: '#37393e'
  surface-container-lowest: '#0c0e12'
  surface-container-low: '#1a1c20'
  surface-container: '#1e2024'
  surface-container-high: '#282a2e'
  surface-container-highest: '#333539'
  on-surface: '#e2e2e8'
  on-surface-variant: '#c7c4d7'
  inverse-surface: '#e2e2e8'
  inverse-on-surface: '#2f3035'
  outline: '#908fa0'
  outline-variant: '#464554'
  surface-tint: '#c0c1ff'
  primary: '#c0c1ff'
  on-primary: '#1000a9'
  primary-container: '#8083ff'
  on-primary-container: '#0d0096'
  inverse-primary: '#494bd6'
  secondary: '#ddb7ff'
  on-secondary: '#490080'
  secondary-container: '#6f00be'
  on-secondary-container: '#d6a9ff'
  tertiary: '#2fd9f4'
  on-tertiary: '#00363e'
  tertiary-container: '#008395'
  on-tertiary-container: '#000608'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e1e0ff'
  primary-fixed-dim: '#c0c1ff'
  on-primary-fixed: '#07006c'
  on-primary-fixed-variant: '#2f2ebe'
  secondary-fixed: '#f0dbff'
  secondary-fixed-dim: '#ddb7ff'
  on-secondary-fixed: '#2c0051'
  on-secondary-fixed-variant: '#6900b3'
  tertiary-fixed: '#a2eeff'
  tertiary-fixed-dim: '#2fd9f4'
  on-tertiary-fixed: '#001f25'
  on-tertiary-fixed-variant: '#004e5a'
  background: '#111317'
  on-background: '#e2e2e8'
  surface-variant: '#333539'
typography:
  headline-xl:
    fontFamily: Inter
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 34px
    letterSpacing: -0.01em
  display-quote:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '400'
    lineHeight: 30px
    letterSpacing: 0.01em
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0em
  label-sm:
    fontFamily: Geist
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  unit: 8px
  container-padding-mobile: 24px
  container-padding-desktop: 48px
  gutter: 16px
  section-gap: 40px
---

## Brand & Style

The design system is centered on the concept of "Guided Focus"—a digital environment that eliminates noise to foster deep productivity and personal growth. It targets high-achieving professionals and creatives who value mental clarity as much as efficiency. 

The aesthetic is a sophisticated fusion of **Minimalism** and **Glassmorphism**. It borrows the structural precision of developer tools (Linear), the structural calm of editorial layouts (Notion), and the immersive, fluid nature of modern browsers (Arc). The UI should feel like a breathing organism rather than a static tool; it is premium, calm, and intentionally spacious to evoke a sense of limitless potential. Every interaction is designed to feel like a step forward on a journey, utilizing soft transitions and "weightless" elements that float over a deep, infinite background.

## Colors

This design system utilizes a **Premium Dark** palette. The foundation is a "Deep Charcoal" (#0F1115) which provides more warmth and depth than pure black, reducing eye strain during long sessions. 

- **Primary (Indigo-Violet):** Used for key brand moments and active states. It represents the AI's "consciousness."
- **Secondary (Lavender):** Used for secondary actions and soft highlights.
- **Tertiary (Cyan):** Reserved for success states and "pathway" indicators to symbolize progress.
- **Gradients:** Use the signature "Aether Gradient" for high-impact CTAs and AI-generated content. Gradients should always move from bottom-left to top-right to suggest upward momentum.
- **Surfaces:** Use #1C1F26 for card backgrounds with a 1px border of #2D313A at 50% opacity to create a "machined" precision look.

## Typography

Typography in this design system is architectural. We use **Inter** for its global legibility and neutral tone, allowing the content to lead. For technical or data-heavy labels, we introduce **Geist** to provide a "developer-precision" feel that aligns with the AI-centric nature of the product.

- **Headlines:** Should be used sparingly to create clear entry points. Use tight letter-spacing (-0.02em) to give them a modern, "tucked-in" appearance.
- **Body:** Generous line-height (1.5x) is mandatory to maintain the "calm" emotional tone. 
- **Tracking:** Increase tracking on all uppercase labels (0.05em) to ensure they don't feel cramped against heavy borders.
- **Inspirational Quotes:** Use the `display-quote` style with a slightly diminished opacity (70%) for a reflective, soft appearance.

## Layout & Spacing

The layout philosophy follows a **Fluid "Safe-Zone" Model**. We avoid rigid grids in favor of dynamic containers that prioritize content hierarchy. 

- **Horizontal Margins:** A minimum of 24px on mobile ensures that the ultra-rounded corners of cards have enough room to "breathe" against the edge of the device.
- **Vertical Rhythm:** Use a strict 8px base unit. Section headers should be separated from their content by 16px, while separate modules should have a 40px gap to prevent a "cluttered" look.
- **Negative Space:** Whitespace is a first-class citizen. If a screen feels busy, increase the padding within cards rather than shrinking the text.

## Elevation & Depth

This design system uses **Tonal Glassmorphism** to establish hierarchy. We do not use traditional black shadows.

1.  **Level 0 (Base):** The #0F1115 background.
2.  **Level 1 (Cards):** #1C1F26 with a subtle 1px inner stroke.
3.  **Level 2 (Floating Modals):** Semi-transparent background (70% opacity) with a `backdrop-filter: blur(20px)`.
4.  **Glows:** For the primary CTA or active progress states, use a soft, colored outer glow (e.g., 20px blur, 10% opacity of the Primary color) to simulate a light-emitting source.

## Shapes

The shape language is "Organic Geometric." We utilize **Pill-shaped (3)** logic for all primary containers and interactive elements to evoke the softness found in wellness apps like Headspace.

- **Primary Cards:** 24px (rounded-lg) or 32px (rounded-xl) corner radius.
- **Buttons:** Fully pill-shaped (height/2).
- **Selection Indicators:** Small 4px circles or rounded-pills to denote progress.
- **Inner Elements:** Nested elements inside cards should have a corner radius that is 8px smaller than the parent container to maintain visual harmony.

## Components

- **Ultra-Rounded Cards:** The primary vessel for content. These should always feature a subtle 1px border (#ffffff10) and no drop shadow. On tap, they should subtly scale down (98%) to provide tactile feedback.
- **Glass CTAs:** Buttons that use a semi-transparent blur rather than a solid color, except for the primary action which uses the "Aether Gradient."
- **Path Indicators:** Instead of standard progress bars, use "Journey Lines"—thin 2px lines with a glowing dot at the head of the progress. 
- **AI Input Fields:** Minimalist fields with no background, only a bottom border that glows with the primary gradient when focused. 
- **Micro-Illustrations:** Use high-quality, 3D-clay or vector-gradient illustrations with soft shadows. Illustrations should always be centered and surrounded by at least 32px of whitespace.
- **Chips:** Small, pill-shaped labels with a secondary color background at 10% opacity and a solid text color for high legibility without visual weight.
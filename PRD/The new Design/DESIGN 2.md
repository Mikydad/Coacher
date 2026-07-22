# Design System Specification

## 1. Overview & Creative North Star: "The Obsidian Pulse"
This design system is engineered to transform productivity from a chore into a high-stakes, cinematic experience. Moving away from the "cluttered dashboard" aesthetic, we embrace **The Obsidian Pulse**: a philosophy where the UI remains invisible until the moment of action. 

By leveraging deep-space blacks and high-energy neon accents, we create a psychological environment of "Flow State." We break the traditional grid through **intentional asymmetry**—offsetting progress indicators and using overlapping translucent layers to create a sense of mechanical precision and editorial sophistication. This is not just a tool; it is a digital coach that feels premium, urgent, and focused.

## 2. Colors & Tonal Depth
The palette is rooted in the "void." We use varying levels of darkness to imply hierarchy, never relying on lines to separate ideas.

### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders for sectioning. Boundaries must be defined solely through background color shifts or subtle tonal transitions. For example, a `surface-container-low` (#131313) card sits on a `surface` (#0e0e0e) background to create a "soft-edge" separation.

### Color Tokens
*   **Primary (The Kinetic Green):** `primary` (#eaffb8) and `primary-dim` (#b2ed00). Used for achievement, streaks, and "Go" states.
*   **Secondary (The Electric Blue):** `secondary` (#00e3fd). Used for secondary data points and focus-mode indicators.
*   **The Void (Backgrounds):** 
    *   `surface`: #0e0e0e (The baseline).
    *   `surface-container-lowest`: #000000 (For deep inset elements).
    *   `surface-container-highest`: #262626 (For elevated interactive cards).

### The "Glass & Gradient" Rule
To avoid a flat "template" feel, all floating action buttons or high-priority modals must utilize **Glassmorphism**. Use a semi-transparent `surface-variant` (#262626 at 60% opacity) with a `backdrop-filter: blur(20px)`. 

**Signature Gradients:** Hero progress indicators must transition from `primary-dim` (#b2ed00) to `secondary` (#00e3fd) to visualize the "heat" of a streak.

## 3. Typography: Editorial Authority
We use **Inter** exclusively. The goal is a high-contrast scale where large titles feel like magazine headlines and body text feels like technical metadata.

*   **Display-LG (3.5rem):** Used for "The Big Number" (e.g., Days Clean, Total Focus Hours). Tight letter-spacing (-0.04em).
*   **Headline-SM (1.5rem):** Used for section headers. Bold weight to provide an anchor for the eye.
*   **Body-MD (0.875rem):** The workhorse. Medium-grey (`on-surface-variant`) to reduce eye strain against the black background.
*   **Label-SM (0.6875rem):** All-caps with 0.1em letter-spacing. Used for metadata tags to give a "pro-tool" technical feel.

## 4. Elevation & Depth: Tonal Layering
In this design system, "Up" does not mean "Shadow." It means "Lighter."

*   **The Layering Principle:** Stacking follows a light-source logic. 
    *   Level 0: `surface` (#0e0e0e) - The floor.
    *   Level 1: `surface-container-low` (#131313) - Large content areas.
    *   Level 2: `surface-container-high` (#201f1f) - Individual cards.
*   **Ambient Shadows:** If an element must float (e.g., a bottom sheet), use a shadow with a 40px blur, 0% offset, and 6% opacity of `on-surface` (#ffffff). This creates a "glow" of dark energy rather than a muddy drop-shadow.
*   **The "Ghost Border" Fallback:** For accessibility in input fields, use `outline-variant` (#494847) at **15% opacity**. It should be felt, not seen.

## 5. Components

### Hero Progress Indicators
The centerpiece of the app. Circular indicators must use `stroke-linecap: round` and a soft outer glow (`box-shadow` or `drop-shadow`) using the `primary` color at 20% opacity. This makes the progress feel "alive."

### Buttons
*   **Primary:** Solid `primary-container` (#befc00) with `on-primary-container` (#445d00) text. Corner radius: `full` (9999px).
*   **Secondary:** Ghost style. No background, `outline-variant` border at 20%, `on-surface` text.
*   **Active States:** Apply a 4px outer glow of the button's accent color when pressed.

### Cards & Lists
*   **The "No-Divider" Rule:** Vertical whitespace (`spacing-8` or `spacing-10`) is the only permitted separator.
*   **Interaction:** Cards should subtly scale (1.02x) on tap/hover, shifting from `surface-container-high` to `surface-bright`.

### Input Fields
Minimalist under-lines or subtle blocks. Use `surface-container-highest` (#262626) with a `xl` (3rem) corner radius. The cursor should be the `secondary` (#00e3fd) color to act as a beacon.

### Signature Component: The "Streak Pulse"
A specialized chip using a `primary-dim` to `primary` gradient. It features a micro-animation (subtle breathing opacity) to denote an active, ongoing streak.

## 6. Do’s and Don'ts

### Do
*   **Use Asymmetry:** Offset your hero elements. Let a circular gauge bleed off the edge of a card to create visual tension.
*   **Embrace Negative Space:** If you think there’s enough room between elements, double it. Darkness is a feature, not a bug.
*   **Focus on Glow:** Use the `primary` color as a light source. Imagine the screen is an OLED panel where light only exists where there is achievement.

### Don’t
*   **Don't use pure white text (#ffffff) for everything:** It causes "halation" (bleeding) on dark screens. Use `on-surface-variant` (#adaaaa) for secondary text.
*   **Don't use 1px dividers:** It breaks the "Obsidian" immersion and makes the app look like a standard table view.
*   **Don't use sharp corners:** Every interactive element must use at least the `md` (1.5rem) or `xl` (3rem) radius to feel organic and approachable.
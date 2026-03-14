---
name: frontend-design
description: Load when building visually distinctive frontend UI - guides creative design choices to avoid generic AI-generated aesthetics
license: MIT
compatibility: opencode
metadata:
  domain: frontend
  paradigm: design
---

## What I Do

Guide creation of distinctive, production-grade frontend interfaces that avoid generic "AI slop" aesthetics. Produce real working code with exceptional attention to aesthetic details and creative choices.

## When to Use

Use when the user wants a visually striking or creative UI -- a landing page, portfolio, marketing site, interactive component, or any interface where aesthetics matter. Not needed for internal tooling, admin panels, or purely functional forms.

## Design Thinking

Before coding, understand the context and commit to a clear aesthetic direction:

- **Purpose**: What problem does this interface solve? Who uses it?
- **Tone**: Pick a strong direction -- brutally minimal, maximalist chaos, retro-futuristic, organic/natural, luxury/refined, playful/toy-like, editorial/magazine, brutalist/raw, art deco/geometric, soft/pastel, industrial/utilitarian, etc.
- **Constraints**: Framework, performance, accessibility requirements.
- **Differentiation**: What's the one thing someone will remember about this interface?

Then implement working code in whatever framework is being used (HTML/CSS/JS, React, Vue, Angular, Blazor, etc.) that is production-grade, visually cohesive, and meticulously refined.

## Typography

- Choose distinctive, characterful fonts -- never default to Inter, Roboto, Arial, or system fonts
- Pair a display font with a refined body font
- Vary choices between projects -- never converge on the same font (e.g. Space Grotesk) repeatedly

## Color and Theme

- Commit to a cohesive palette using CSS variables
- Dominant colors with sharp accents outperform timid, evenly-distributed palettes
- Vary between light and dark themes across projects
- Avoid cliched color schemes, particularly purple gradients on white backgrounds

## Motion and Animation

- Use animations for micro-interactions and page transitions
- Prioritize CSS-only solutions (transitions, `@keyframes`, `View Transition API`) over JS animation libraries
- Focus on high-impact moments: one well-orchestrated page load with staggered reveals (`animation-delay`) creates more delight than scattered micro-interactions
- Scroll-triggered effects and surprising hover states add character

## Spatial Composition

- Use unexpected layouts: asymmetry, overlap, diagonal flow, grid-breaking elements
- Choose between generous negative space and controlled density -- both work when intentional

## Backgrounds and Visual Details

- Create atmosphere and depth rather than defaulting to solid colors
- Gradient meshes, noise textures, geometric patterns, layered transparencies, dramatic shadows, decorative borders, custom cursors, grain overlays -- pick what fits the aesthetic
- Every detail should reinforce the chosen direction

## Semantic HTML First

- Use native HTML elements before reaching for divs and JavaScript -- `<details>` for accordions, `<dialog>` for modals, `<meter>` for gauges, `<progress>` for progress bars, `<fieldset>` for form groups, `<nav>`, `<aside>`, `<article>`, `<section>` for structure
- Style native elements with CSS rather than rebuilding them from nested divs and ARIA attributes
- Use CSS features over JS when possible -- `:has()`, `:focus-within`, `scroll-snap`, `@container`, `@starting-style`, `popover` attribute
- Only reach for custom components when native elements genuinely can't deliver the interaction

## Key Guidelines

- Match implementation complexity to the aesthetic vision -- maximalist designs need elaborate code, minimalist designs need precision and restraint
- Bold maximalism and refined minimalism both work -- the key is intentionality, not intensity
- No two designs should look the same -- vary fonts, themes, layouts, and aesthetic direction
- Never produce cookie-cutter design that lacks context-specific character

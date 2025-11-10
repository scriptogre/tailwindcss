# Timing Utilities Extension - Design Document

## Problem Statement

Currently, TailwindCSS v4's timing utilities (`duration-*`, `delay-*`, `ease-*`) ONLY apply to CSS transitions, not animations. This has been a pain point since 2021 (GitHub issue #3378), forcing developers to use workarounds like:
- Arbitrary values: `animate-[bounce_1s_infinite_100ms]` (hacky)
- Custom plugins
- Inline styles
- Custom CSS

## Community Evidence

**GitHub Issues:**
- #3378 - Animation utilities for animation-delay etc. (Jan 2021)
- #11669 - View Transitions API support (Jul 2023)
- #16132 - [v4] add support for disabling core plugins (Jan 2024)

**User Quotes:**
- "I find it unexpected and distracting that there is delay-100 for transition-delay, but there's nothing for animation-delay."
- "I'd still vote to have the delay utility in core bifurcate into transition-delay and animation-delay"
- "This should be default!"

## Proposed Solution

### Core Philosophy
Make `duration-*`, `delay-*`, and `ease-*` apply to BOTH transitions AND animations by default (99% use case), while providing specific utilities for edge cases where different values are needed.

### API Design

#### 1. Unified Timing Utilities (Primary API)
These utilities set BOTH transition AND animation properties:

```css
/* duration-* sets both transition-duration AND animation-duration */
duration-100
duration-300
duration-[2s]

/* delay-* sets both transition-delay AND animation-delay */
delay-100
delay-500
delay-[200ms]

/* ease-* sets both transition-timing-function AND animation-timing-function */
ease-in
ease-out
ease-in-out
ease-linear
ease-[cubic-bezier(0.4,0,0.2,1)]
```

#### 2. Specific Utilities (Edge Cases)
For scenarios where an element has both transitions AND animations with different timing:

```css
/* Transition-specific */
transition-duration-*
transition-delay-*
transition-ease-*

/* Animation-specific */
animation-duration-*
animation-delay-*
animation-ease-*
```

**Naming Decision:** Use `animation-*` prefix for consistency with CSS spec, not `animate-*` (which is reserved for the `animation` shorthand property).

#### 3. New Animation-Specific Utilities

##### Animation Iteration Count
```css
animation-count-*         /* animation-count-3 -> animation-iteration-count: 3 */
animation-count-infinite  /* shorthand */
animation-count-[7]       /* arbitrary */

/* DX-friendly shortcuts */
animate-once              /* animation-iteration-count: 1 */
animate-twice             /* animation-iteration-count: 2 */
animate-thrice            /* animation-iteration-count: 3 */
animate-infinite          /* animation-iteration-count: infinite */
```

##### Animation Direction
```css
animate-normal            /* animation-direction: normal */
animate-reverse           /* animation-direction: reverse */
animate-alternate         /* animation-direction: alternate */
animate-alternate-reverse /* animation-direction: alternate-reverse */
```

##### Animation Fill Mode
```css
animate-fill-none         /* animation-fill-mode: none */
animate-fill-forwards     /* animation-fill-mode: forwards */
animate-fill-backwards    /* animation-fill-mode: backwards */
animate-fill-both         /* animation-fill-mode: both */
```

##### Animation Name
```css
animation-name-*          /* animation-name-spin -> animation-name: spin */
animation-name-[fade-in]  /* arbitrary */
animation-name-none       /* reset */
```

#### 4. Existing Utilities (No Change)
```css
animate-*                 /* Sets the entire `animation` shorthand property */
animate-spin              /* animation: var(--animate-spin) */
animate-bounce
animate-none
```

### Implementation Details

#### Current State (utilities.ts:4589-4675)
- `delay` utility: Only sets `transition-delay`
- `duration` utility: Only sets `transition-duration` + `--tw-duration` CSS var
- `ease` utility: Only sets `transition-timing-function` + `--tw-ease` CSS var
- `animate` utility: Sets `animation` shorthand property

#### Proposed Changes

**1. Modify existing utilities to set both properties:**
```typescript
functionalUtility('duration', {
  handleBareValue: ({ value }) => {
    if (!isPositiveInteger(value)) return null
    return `${value}ms`
  },
  themeKeys: ['--transition-duration'],
  handle: (value) => [
    durationProperty(),
    decl('--tw-duration', value),
    decl('transition-duration', value),
    decl('animation-duration', value),  // NEW
  ],
})
```

**2. Add specific utilities:**
```typescript
// Transition-specific
functionalUtility('transition-duration', {
  handleBareValue: ({ value }) => {
    if (!isPositiveInteger(value)) return null
    return `${value}ms`
  },
  themeKeys: ['--transition-duration'],
  handle: (value) => [decl('transition-duration', value)],
})

// Animation-specific
functionalUtility('animation-duration', {
  handleBareValue: ({ value }) => {
    if (!isPositiveInteger(value)) return null
    return `${value}ms`
  },
  themeKeys: ['--transition-duration'],  // Reuse same theme values
  handle: (value) => [decl('animation-duration', value)],
})
```

**3. Add new animation utilities:**
```typescript
// Animation iteration count
functionalUtility('animation-count', {
  handleBareValue: ({ value }) => {
    if (!isPositiveInteger(value)) return null
    return value
  },
  themeKeys: [],
  handle: (value) => [decl('animation-iteration-count', value)],
  staticValues: {
    infinite: [decl('animation-iteration-count', 'infinite')],
  },
})

// Shortcuts
staticUtility('animate-once', [['animation-iteration-count', '1']])
staticUtility('animate-twice', [['animation-iteration-count', '2']])
staticUtility('animate-thrice', [['animation-iteration-count', '3']])
staticUtility('animate-infinite', [['animation-iteration-count', 'infinite']])

// Direction
staticUtility('animate-normal', [['animation-direction', 'normal']])
staticUtility('animate-reverse', [['animation-direction', 'reverse']])
staticUtility('animate-alternate', [['animation-direction', 'alternate']])
staticUtility('animate-alternate-reverse', [['animation-direction', 'alternate-reverse']])

// Fill mode
staticUtility('animate-fill-none', [['animation-fill-mode', 'none']])
staticUtility('animate-fill-forwards', [['animation-fill-mode', 'forwards']])
staticUtility('animate-fill-backwards', [['animation-fill-mode', 'backwards']])
staticUtility('animate-fill-both', [['animation-fill-mode', 'both']])
```

### Benefits

1. **Intuitive DX**: `duration-300` now works for both transitions AND animations (as users expect)
2. **Composability**: Mix and match utilities to build complex animations
3. **View Transitions Ready**: Enables elegant View Transitions API support
4. **Backward Compatible**: Existing code continues to work
5. **Escape Hatch**: Specific utilities available when needed

### Example Usage

```html
<!-- Basic animation with timing utilities -->
<div class="animate-bounce duration-500 delay-100">
  Bouncing with custom timing
</div>

<!-- Composing an animation from scratch -->
<div class="animation-name-fade-in duration-1000 animate-once animate-fill-forwards">
  Custom animation composition
</div>

<!-- Different timing for transition vs animation (edge case) -->
<div class="transition-duration-300 animation-duration-1000 animate-pulse hover:scale-110">
  Different timing for each
</div>

<!-- View Transitions -->
<div class="vt-name-hero vt-old:duration-300 vt-old:ease-out">
  Hero element with view transition
</div>
```

### Testing Strategy

1. Unit tests for each new utility
2. Integration tests for combined utilities
3. Regression tests for existing transition utilities
4. View Transitions integration test

### Migration Path

**For users:** No migration needed! This is a pure enhancement.

**Breaking changes:** None. We're adding properties, not removing them.

### Future Enhancements

1. View Transitions utilities (separate PR)
2. Animation composition helpers
3. Keyframe utilities

## References

- GitHub Issue #3378: https://github.com/tailwindlabs/tailwindcss/issues/3378
- GitHub Issue #11669: https://github.com/tailwindlabs/tailwindcss/issues/11669
- GitHub Issue #16132: https://github.com/tailwindlabs/tailwindcss/issues/16132
- CSS Animation Spec: https://www.w3.org/TR/css-animations-1/
- View Transitions API: https://developer.mozilla.org/en-US/docs/Web/API/View_Transitions_API

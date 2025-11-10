# Timing Utilities Extension - Design Document

## Problem Statement

Currently, TailwindCSS v4's timing utilities (`duration-*`, `delay-*`, `ease-*`) ONLY apply to CSS transitions, not animations. This has been a pain point since 2021 (GitHub issue #3378), forcing developers to use workarounds when they want to customize built-in `animate-*` utilities like `animate-spin` or `animate-bounce`.

Developers cannot:
- Change the duration of `animate-spin` without verbose arbitrary values
- Add delays to animations
- Stop animations after N cycles
- Reverse animations
- Use different easing functions with animations

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
Make `duration-*`, `delay-*`, and `ease-*` apply to BOTH transitions AND animations by default (99% use case), while providing specific utilities for edge cases where different values are needed. Add complementary `animation-*` utilities to enable full control over CSS animation properties.

### API Design

#### 1. Unified Timing Utilities (Primary API)
These utilities set BOTH transition AND animation properties:

```css
/* duration-* sets both transition-duration AND animation-duration */
.duration-300 {
  --tw-duration: 300ms;
  transition-duration: 300ms;
  animation-duration: 300ms;  /* NEW */
}

/* delay-* sets both transition-delay AND animation-delay */
.delay-100 {
  transition-delay: 100ms;
  animation-delay: 100ms;  /* NEW */
}

/* ease-* sets both transition-timing-function AND animation-timing-function */
.ease-in-out {
  --tw-ease: cubic-bezier(0.4, 0, 0.2, 1);
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  animation-timing-function: cubic-bezier(0.4, 0, 0.2, 1);  /* NEW */
}
```

**Usage:**
```html
<div class="animate-spin duration-2000 ease-linear">
  2-second linear spin
</div>
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

**Usage:**
```html
<div class="animate-pulse hover:scale-110
            transition-duration-200 animation-duration-2000">
  Fast hover, slow pulse
</div>
```

#### 3. Animation Control Utilities

Enable customization of built-in `animate-*` classes:

##### Animation Iteration Count
```css
animation-count-*         /* animation-count-3 -> 3 cycles */
animation-count-infinite  /* infinite cycles */
animation-count-[7]       /* arbitrary value */

/* DX-friendly shortcuts */
animation-once            /* 1 cycle */
animation-twice           /* 2 cycles */
animation-thrice          /* 3 cycles */
animation-infinite        /* infinite cycles */
```

**Usage:**
```html
<div class="animate-bounce animation-once animation-forwards">
  Bounces once, stays visible
</div>
```

##### Animation Direction
```css
animation-normal          /* play forward (default) */
animation-reverse         /* play backward */
animation-alternate       /* alternate direction each cycle */
animation-alternate-reverse /* alternate starting backward */
```

**Usage:**
```html
<div class="animate-spin animation-reverse">
  Spins counter-clockwise
</div>
```

##### Animation Fill Mode
```css
animation-none            /* don't apply styles outside animation */
animation-forwards        /* retain final keyframe styles */
animation-backwards       /* apply initial keyframe styles before start */
animation-both            /* apply both forwards and backwards */
```

**Usage:**
```html
<div class="animate-bounce animation-once animation-forwards">
  Bounces once, stays at end position
</div>
```

#### 4. Existing Utilities (No Change)
```css
animate-*                 /* Sets the entire `animation` shorthand property */
animate-spin              /* animation: var(--animate-spin) */
animate-bounce
animate-none
```

### Implementation Details

#### Current State (utilities.ts)
- `delay` utility (line 4589): Only sets `transition-delay`
- `duration` utility (line 4605): Only sets `transition-duration` + `--tw-duration` CSS var
- `ease` utility (line 4667): Only sets `transition-timing-function` + `--tw-ease` CSS var
- `animate` utility (line 3931): Sets `animation` shorthand property

#### Changes Made

**1. Modified existing utilities to set both properties:**
```typescript
// delay utility
functionalUtility('delay', {
  handleBareValue: ({ value }) => {
    if (!isPositiveInteger(value)) return null
    return `${value}ms`
  },
  themeKeys: ['--transition-delay'],
  handle: (value) => [
    decl('transition-delay', value),
    decl('animation-delay', value),  // NEW
  ],
})

// duration utility
utilities.functional('duration', (candidate) => {
  // ... value resolution logic ...
  return [
    transitionDurationProperty(),
    decl('--tw-duration', value),
    decl('transition-duration', value),
    decl('animation-duration', value),  // NEW
  ]
})

// ease utility
functionalUtility('ease', {
  themeKeys: ['--ease'],
  handle: (value) => [
    transitionTimingFunctionProperty(),
    decl('--tw-ease', value),
    decl('transition-timing-function', value),
    decl('animation-timing-function', value),  // NEW
  ],
  // ... staticValues ...
})
```

**2. Added specific utilities:**
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

functionalUtility('transition-delay', { /* similar */ })
functionalUtility('transition-ease', { /* similar */ })

// Animation-specific
functionalUtility('animation-duration', {
  handleBareValue: ({ value }) => {
    if (!isPositiveInteger(value)) return null
    return `${value}ms`
  },
  themeKeys: ['--transition-duration'],  // Reuse same theme values
  handle: (value) => [decl('animation-duration', value)],
})

functionalUtility('animation-delay', { /* similar */ })
functionalUtility('animation-ease', { /* similar */ })
```

**3. Added animation control utilities:**
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
staticUtility('animation-once', [['animation-iteration-count', '1']])
staticUtility('animation-twice', [['animation-iteration-count', '2']])
staticUtility('animation-thrice', [['animation-iteration-count', '3']])
staticUtility('animation-infinite', [['animation-iteration-count', 'infinite']])

// Direction
staticUtility('animation-normal', [['animation-direction', 'normal']])
staticUtility('animation-reverse', [['animation-direction', 'reverse']])
staticUtility('animation-alternate', [['animation-direction', 'alternate']])
staticUtility('animation-alternate-reverse', [['animation-direction', 'alternate-reverse']])

// Fill mode
staticUtility('animation-none', [['animation-fill-mode', 'none']])
staticUtility('animation-forwards', [['animation-fill-mode', 'forwards']])
staticUtility('animation-backwards', [['animation-fill-mode', 'backwards']])
staticUtility('animation-both', [['animation-fill-mode', 'both']])
```

### Naming Conventions

**Consistent `animation-*` prefix throughout:**
- ✅ `animation-count-*`, `animation-once`, `animation-twice`, etc.
- ✅ `animation-normal`, `animation-reverse`, etc.
- ✅ `animation-none`, `animation-forwards`, etc.
- ✅ `animation-duration-*`, `animation-delay-*`, `animation-ease-*`

**Why not `animate-*`?**
- `animate-*` is reserved for the shorthand property utilities (`animate-spin`, `animate-bounce`)
- `animation-*` maps directly to CSS properties (`animation-duration`, `animation-direction`, etc.)
- Provides clear distinction between shorthand (`animate-`) and individual properties (`animation-`)

**Why no `animation-name-*`?**
- You can't create `@keyframes` inline with utilities
- Setting name alone isn't useful without keyframes
- `animate-*` shorthand already handles this
- Focus is on **customizing** existing animations, not creating new ones

### Benefits

1. **Intuitive DX**: `duration-300` now works for both transitions AND animations (as users expect)
2. **Composability**: Mix and match utilities to customize built-in animations
3. **View Transitions Ready**: Enables elegant View Transitions API support
4. **Backward Compatible**: Existing code continues to work
5. **Escape Hatch**: Specific utilities available when needed
6. **Powerful**: Can now stop animations, reverse them, alternate them, etc.

### Example Usage

```html
<!-- Basic: Customize timing -->
<div class="animate-spin duration-2000 ease-linear">
  2-second linear spin
</div>

<!-- Stop after one cycle -->
<div class="animate-bounce animation-once animation-forwards">
  Bounces once, stays visible
</div>

<!-- Reverse -->
<div class="animate-spin animation-reverse">
  Counter-clockwise
</div>

<!-- Yo-yo effect -->
<div class="animate-pulse animation-alternate animation-count-4">
  Pulses in and out 4 times
</div>

<!-- Different timing for transition vs animation (edge case) -->
<div class="animate-pulse hover:scale-110
            transition-duration-300 animation-duration-1000">
  Fast transition, slow animation
</div>

<!-- Staggered animations -->
<div class="animate-fade-in duration-1000 delay-0">Item 1</div>
<div class="animate-fade-in duration-1000 delay-100">Item 2</div>
<div class="animate-fade-in duration-1000 delay-200">Item 3</div>
```

### Testing Strategy

1. Updated existing tests for `duration`, `delay`, `ease` to include animation properties
2. Added tests for specific `transition-*` utilities
3. Added tests for specific `animation-*` utilities
4. Added tests for `animation-count-*` and shortcuts
5. Added tests for animation direction utilities
6. Added tests for animation fill mode utilities
7. Added integration test showing utilities work with `animate-*` classes

All tests include:
- Named values
- Arbitrary values
- Theme integration
- Negative cases

### Migration Path

**For users:** No migration needed! This is a pure enhancement.

**Breaking changes:** None. We're adding properties, not removing them.

### Future Enhancements

This PR enables:

1. **View Transitions API Support** (issue #11669)
   ```css
   @utility vt-name-* { view-transition-name: --value(...); }
   @custom-variant vt-old { ::view-transition-old(*) { @slot; } }
   @custom-variant vt-new { ::view-transition-new(*) { @slot; } }
   ```

2. **Keyframe utilities** - When there's a clear use case
3. **Scroll-Driven Animations** - When the spec stabilizes

## References

- GitHub Issue #3378: https://github.com/tailwindlabs/tailwindcss/issues/3378
- GitHub Issue #11669: https://github.com/tailwindlabs/tailwindcss/issues/11669
- GitHub Issue #16132: https://github.com/tailwindlabs/tailwindcss/issues/16132
- CSS Animation Spec: https://www.w3.org/TR/css-animations-1/
- View Transitions API: https://developer.mozilla.org/en-US/docs/Web/API/View_Transitions_API

## Design Principles Applied

1. **Make the obvious thing work**: `duration-300 animate-spin` should just work
2. **Composition over configuration**: Combine utilities to build complex animations
3. **Escape hatches**: Specific utilities for edge cases
4. **Backward compatibility**: Don't break existing code
5. **Consistent naming**: Follow CSS property naming conventions

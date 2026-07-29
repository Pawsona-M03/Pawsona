# Delete Confirmation Button Hit Area Design

## Problem

`DeleteConfirmationButton` renders a full-width card, but only the centered
title responds to taps. The modifier that expands the view is applied outside
the `Button`, so the visible card is larger than the button label's hit region.

## Scope

Fix the shared `DeleteConfirmationButton` so the full visible row is tappable
in dog, vaccine-record, and reminder edit forms. Keep the current confirmation
alert, destructive role, titles, messages, and caller-owned layout unchanged.

## Design

Use a custom `Button` label containing `Text(title)`. Apply the full-width,
minimum 44-point frame to that label rather than to the outer button, then give
the label a rectangular content shape.

This makes the visible row and native button hit region match without adding
gesture recognizers, overlays, or duplicate accessibility elements.

## Interaction Flow

1. A tap anywhere in the visible delete row sets the existing confirmation
   state.
2. The existing native alert appears.
3. Confirming invokes the caller's destructive action; canceling leaves the
   form unchanged.

## Accessibility

- Preserve the native `Button` and destructive role.
- Preserve the 44-point minimum hit-target height.
- Do not add a second gesture or accessibility element.
- Verify that VoiceOver exposes one destructive button with the supplied title.

## Verification

The project has no UI-test target or view-inspection dependency. Verify the
interaction in Xcode Preview by tapping the row near its left and right edges
and confirming that the alert appears. Build the iOS simulator target to catch
compile regressions.

## Non-goals

- No visual redesign.
- No changes to confirmation copy or destructive actions.
- No caller-specific workaround in `DogFormView`.

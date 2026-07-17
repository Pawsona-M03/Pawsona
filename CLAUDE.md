# Agent guide for Pawsona

Pawsona is an iOS app written in Swift and SwiftUI, backed by SwiftData. Follow the guidelines
below so the codebase stays on modern, safe API usage.

> **`AGENTS.md` and `CLAUDE.md` are duplicates.** Claude Code only reads `CLAUDE.md`; every other
> agent (Codex, Antigravity, Cursor, Gemini) reads `AGENTS.md`. **Edit both, or neither.**


## Role

You are a **Senior iOS Engineer**, specializing in SwiftUI, SwiftData, and related frameworks.
Your code must always adhere to Apple's Human Interface Guidelines and App Review guidelines.


## Ask when unsure

**When you are confused, uncertain, or have a question, ALWAYS ask Nathan before proceeding** —
even when running in auto / accept-edits / bypass-permissions mode. Do not guess or paper over
ambiguity to keep moving. A short question now beats an confidently wrong change.


## Project facts

Confirmed from the Xcode project — do not assume otherwise:

- **Deployment target: iOS 26.5.** Modern APIs are fair game.
- **`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.** The project uses main-actor-by-default
  isolation, so do **not** add redundant `@MainActor` annotations to `@Observable` classes —
  they are already main-actor isolated. Only annotate when opting *out* (`nonisolated`) or onto
  a different actor.
- **Swift language mode is 5.0**, not 6. Strict concurrency is therefore not fully enforced by
  the compiler yet. Still write code as if it were: prefer `async`/`await`, avoid shared mutable
  state across actors. Do not rely on Swift 6-only diagnostics to catch mistakes.
- **CloudKit is wired up.** The entitlements declare container `iCloud.com.nathansudiara.Pawsona`,
  and the `ModelContainer` opts in via `cloudKitDatabase: .automatic`. Treat the SwiftData
  CloudKit constraints below as **mandatory** — every model must stay CloudKit-legal.


## Core instructions

- Target iOS 26.0 or later.
- Use modern Swift concurrency. Always choose `async`/`await` APIs over closure-based variants
  whenever they exist.
- SwiftUI backed by `@Observable` classes for shared data.
- Do not introduce third-party frameworks without asking first.
- Avoid UIKit unless requested.


## Swift instructions

- All shared data should use `@Observable` classes with `@State` (for ownership) and
  `@Bindable` / `@Environment` (for passing).
- Strongly prefer not to use `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject`,
  or `@EnvironmentObject` unless they are unavoidable, or they exist in legacy/integration
  contexts where changing architecture would be complicated.
- Prefer Swift-native alternatives to Foundation methods where they exist, such as
  `replacing("hello", with: "world")` on strings rather than
  `replacingOccurrences(of: "hello", with: "world")`.
- Prefer modern Foundation API — for example `URL.documentsDirectory` to find the app's
  documents directory, and `appending(path:)` to append to a URL.
- Never use C-style number formatting such as `Text(String(format: "%.2f", abs(myNumber)))`;
  use `Text(abs(change), format: .number.precision(.fractionLength(2)))` instead.
- Never use legacy `Formatter` subclasses such as `DateFormatter`, `NumberFormatter`, or
  `MeasurementFormatter`. Always use the modern `FormatStyle` API — for example
  `myDate.formatted(date: .abbreviated, time: .shortened)`, `Date(inputString, strategy: .iso8601)`,
  or `myNumber.formatted(.number)`.
- Prefer static member lookup to struct instances where possible: `.circle` rather than
  `Circle()`, `.borderedProminent` rather than `BorderedProminentButtonStyle()`.
- Never use old-style Grand Central Dispatch such as `DispatchQueue.main.async()`. Use modern
  Swift concurrency instead.
- Filtering text based on user input must use `localizedStandardContains()`, not `contains()`.
- Avoid force unwraps and force `try` unless failure is genuinely unrecoverable.


## SwiftUI instructions

- Always use `foregroundStyle()` instead of `foregroundColor()`.
- Always use `clipShape(.rect(cornerRadius:))` instead of `cornerRadius()`.
- Always use the `Tab` API instead of `tabItem()`.
- Never use the `onChange()` modifier in its 1-parameter variant; use the 2-parameter or
  0-parameter variant.
- Never use `onTapGesture()` unless you specifically need a tap's location or count. Everything
  else should be a `Button` — see Accessibility below for why this matters.
- Never use `Task.sleep(nanoseconds:)`; use `Task.sleep(for:)`.
- Never use `UIScreen.main.bounds` to read available space.
- Do not break views up using computed properties; extract them into new `View` structs.
- Use `navigationDestination(for:)` for navigation, and `NavigationStack`, never `NavigationView`.
- If using an image for a button label, always specify text alongside:
  `Button("Tap me", systemImage: "plus", action: myButtonAction)`.
- Prefer `ImageRenderer` to `UIGraphicsImageRenderer` when rendering SwiftUI views.
- Don't apply `fontWeight()` without good reason — to bold text, use `bold()`.
- Do not use `GeometryReader` if a newer alternative works, such as `containerRelativeFrame()`
  or `visualEffect()`.
- When making a `ForEach` from an `enumerated` sequence, don't convert to an array first:
  prefer `ForEach(x.enumerated(), id: \.element.id)`.
- Hide scroll indicators with `.scrollIndicators(.hidden)`, not `showsIndicators: false`.
- Use the newest ScrollView APIs (`ScrollPosition`, `defaultScrollAnchor`); avoid `ScrollViewReader`.
- Place view logic into view models or similar so it can be tested.
- Avoid `AnyView` unless absolutely required.
- Avoid hard-coded padding and stack spacing unless requested.
- Avoid UIKit colors in SwiftUI code.


## Accessibility

Accessibility is part of the definition of done, not a later pass — retrofitting it is far more
expensive than building it in. Apply these to every view you write.

**Never:**

- **Never put the trait name in a label.** Say `"Close"`, not `"Close button"` — VoiceOver
  already announces the trait.
- **Never use fixed font sizes.** Always use text styles (`.font(.body)`, `.font(.headline)`)
  so Dynamic Type works. This is the single most common accessibility failure.
- **Never hardcode text colors.** Use semantic colors (`.primary`, `.secondary`) so contrast and
  Dark Mode hold up.
- **Never apply `.accessibilityHidden(true)` to an interactive element** — it becomes unreachable
  for assistive-technology users.
- **Never rely on `onTapGesture` alone.** It has no button trait and no VoiceOver affordance.
  Use a `Button`. (This is also a SwiftUI rule above; accessibility is the reason for it.)
- **Never scale navigation bars, toolbars, or tab bars with Dynamic Type.** Use
  `.accessibilityShowsLargeContentViewer` for that chrome instead.
- **Never add hints unless they add real context** beyond the label, value, and traits.

**Always:**

- When grouping with `.accessibilityElement(children: .ignore)`, you **must** supply the combined
  `.accessibilityLabel` (plus value and traits as needed) yourself.
- Give every interactive element a minimum 44x44pt hit target.
- Localize accessibility labels, values, and hints exactly like any other user-facing string.
- Prefer native components over custom ones — they come with accessibility for free.
- When proposing an accessibility fix, offer options with trade-offs where more than one approach
  is viable, and include how to test it.

**Testing:** verify with VoiceOver on, and at the largest Accessibility Dynamic Type size, before
calling a view finished.

For deeper reference (VoiceOver focus order, Switch Control, Voice Control, automated auditing),
install [`dadederk/iOS-Accessibility-Agent-Skill`](https://github.com/dadederk/iOS-Accessibility-Agent-Skill)
into your agent's skills directory. It is optional — the rules above are the load-bearing 90%.


## SwiftData instructions

CloudKit is enabled in this project's entitlements, so **these constraints are mandatory**:

- **Never use `@Attribute(.unique)`** — CloudKit does not support unique constraints.
- **Every model property must have a default value or be optional.**
- **Every relationship must be marked optional.**

These are not theoretical: the `ModelContainer` is pointed at CloudKit (`cloudKitDatabase:
.automatic`), so a model that violates them will fail to load the store at launch. `Item.swift`
is leftover Xcode template code — delete it once you're sure nothing references it.


## Project structure

- Use a consistent structure, with folder layout determined by app features.
- Follow strict naming conventions for types, properties, methods, and SwiftData models.
- One type per file — don't put multiple structs, classes, or enums in a single Swift file.
- Write unit tests for core application logic. Only write UI tests if unit tests aren't possible.
- Never commit secrets such as API keys.
- If the project adopts `Localizable.xcstrings`, add user-facing strings as symbol keys (e.g.
  `helloWorld`) with `extractionState` set to `"manual"`, accessed via generated symbols such as
  `Text(.helloWorld)`.


## Agent tooling setup

**This is a per-developer setup step.** Agent config directories (`.claude/`, `.agents/`,
`.mcp.json`, etc.) are gitignored to keep the repo clean, so each person wires up their own tool.
These two files are the only agent config in version control.

### XcodeBuildMCP (recommended)

Lets your agent build, run on a simulator, run tests, capture logs, and debug — closing the
edit -> build -> verify loop without you relaying Xcode output by hand. Requires macOS 14.5+,
Xcode 16+, Node 18+.

**Claude Code**
```
claude mcp add xcodebuild -- npx -y xcodebuildmcp@latest mcp
```

**Codex CLI** — add to `~/.codex/config.toml`:
```toml
[mcp_servers.xcodebuild]
command = "npx"
args = ["-y", "xcodebuildmcp@latest", "mcp"]
```

**Antigravity** — add the same `npx -y xcodebuildmcp@latest mcp` command as an MCP server in its
MCP settings.

### Apple's Xcode MCP (optional)

Ships with Xcode 26.3+ — already on your Mac, nothing to install. It complements XcodeBuildMCP:
it talks to a *running* Xcode and reflects live IDE state, where XcodeBuildMCP drives `xcodebuild`
headlessly. Launch via `xcrun mcpbridge run-agent <agent>`.

If it is configured, prefer its tools over generic alternatives:

- `DocumentationSearch` — verify API availability and correct usage **before** writing code
- `BuildProject` — build after changes to confirm compilation succeeds
- `GetBuildLog` — inspect build errors and warnings
- `RenderPreview` — visually verify SwiftUI views using Xcode Previews
- `XcodeListNavigatorIssues` — check the Xcode Issue Navigator
- `ExecuteSnippet` — test a snippet in the context of a source file
- `XcodeRead`, `XcodeWrite`, `XcodeUpdate` — prefer these over generic file tools for Xcode
  project files


## PR instructions

- **Always fill the PR body from `.github/pull_request_template.md`.** Match its section
  headings exactly (Summary, Related Issue, Why, How, Checklist, Verification) — do not invent
  your own structure or skip the checklist.
- Follow the branch naming and conventional-commit rules in `README.md`.
- If SwiftLint is installed, make sure it returns no warnings or errors before committing.
- **Never add AI attribution to commits.** No `Co-Authored-By: Claude` (or any other
  Claude/Anthropic/AI trailer), and no `Generated with Claude Code` line. Commit messages are
  written as if by the human author.
- **Never put an AI session link in a pull request.** No `claude.ai/code` session URLs, no
  equivalent links from any other agent. PR descriptions cover what changed and why — nothing
  about the tooling used to write it.

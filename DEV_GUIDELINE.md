# Development Guidelines

This repository contains:

- `LineOfFire`: the game project currently under development.
- `Overload - 593`: the exact Overload engine version used by this project.

When implementing features, you may rely on both the engine documentation and source code from `Overload - 593` for integration decisions.

Lua version target for this project: **Lua 5.1**.

## Global Development Rules

These rules must be followed strictly for every implementation.

## Architecture and Integration

- Implementations must be modular, decoupled, and extensible.
- Use object-oriented programming as much as relevant.
- Leverage OOP benefits: encapsulation, reusability, extensibility, and clear separation of responsibilities.
- Prioritize native Overload engine systems.
- Do not recreate systems in Lua when the engine already provides them (actors, lights, components, prefabs, events, scenes, resources, etc.).
- When relevant, prefer reusable assets (prefabs, reusable components, reusable scripts) over isolated procedural code.
- Modify only what is necessary; avoid unnecessary global refactors.
- Each Lua file must have a single, clearly defined objective.
- Each feature must be grouped in its own dedicated structure when needed.
- Use subdirectories to group related scripts, modules, components, or assets by feature when it improves clarity.
- Split large features into several focused Lua files instead of concentrating too much responsibility in a single script.
- No Lua file should exceed **250 lines of code**.
- Avoid monolithic files, catch-all utility scripts, and files that mix unrelated responsibilities.

## Lua Conventions

- All Lua code must be compatible with Lua 5.1.
- Use tab indentation.
- Variables must use a lowercase type prefix followed by CamelCase.  
  Examples:
- `local tTable`
- `local nNumber`
- `local nNumberToCalculate`
- `local sName`
- `local bIsActive`
- `local oPlayer`
- `local fCallback`

- Private variables must be grouped inside a `_private` sub-table.  
  Example:

```lua
script._private = {
	nSpeed		= 0,
	bIsMoving	= false
}
```

## Style and Readability

* Group variable declarations and assignments whenever possible.
* Align `=` operators vertically with tabs within the same scope.
* Keep code clear, structured, and consistent.
* Keep the code as simple as possible.
* Go straight to the essential implementation.
* Avoid redundant, superfluous, unnecessary, unreachable, or dead code.
* Avoid over-engineering, excessive abstraction, and speculative code that is not required by the current feature.
* Avoid multi-responsibility scripts: each script/class/component should have a clearly defined role.
* Prefer several small, explicit files over one large file that tries to handle everything.
* Any code that does not actively serve the current feature must be removed or avoided.

## Object-Oriented Programming

* Prefer an object-oriented approach when it improves the design.
* Use Lua tables, metatables, and prototypes compatible with Lua 5.1 when they improve structure.
* Encapsulate internal state in `_private` when it should not be manipulated directly.
* Prefer reusable objects/components/modules over global functions or isolated procedural code.
* Avoid unnecessary abstraction: OOP should improve maintainability, not add artificial complexity.
* Keep classes, components, and modules focused on one responsibility.
* Split object behavior into dedicated modules when a class or component becomes too large or handles unrelated concerns.

## Logic

* Prefer Lua `and / or` ternary-style expressions when they improve conciseness.
* Avoid `if / then / else` when a readable expression can replace it cleanly.
* Never sacrifice clarity for excessive conciseness.
* Do not duplicate logic across files; extract reusable behavior into focused modules when needed.
* Remove unused branches, obsolete logic, temporary debug code, and inactive feature fragments.

## File Organization

* Each Lua file must represent one clear responsibility.
* Related files must be grouped by feature, domain, or system inside dedicated subdirectories when appropriate.
* A feature may be split into multiple files such as:

  * one file for the main component,
  * one file for configuration,
  * one file for reusable behavior,
  * one file for feature-specific helpers,
  * one file for data or constants.
* Avoid generic folders becoming dumping grounds for unrelated scripts.
* Avoid generic files such as `Utils.lua`, `Manager.lua`, or `Helpers.lua` unless their responsibility is narrow and explicit.
* File names must describe the actual responsibility of the file.
* No Lua file should exceed **250 lines of code**.
* If a file approaches the 250-line limit, it must be reviewed and split into smaller focused files when possible.

## Methodology

Before implementing anything:

1. Analyze the `LineOfFire` project.
2. Analyze available systems in `Overload - 593`.
3. Identify the best engine-native integration approach.
4. Identify the smallest clean implementation needed.
5. Identify whether the feature should be split into multiple files or subdirectories.

Then:

* Implement only what is necessary.
* Keep every Lua file focused on a single objective.
* Keep the code simple and direct.
* Remove or avoid redundant, superfluous, unused, unreachable, or dead code.
* Briefly explain important technical choices.
* List modified files and why each file was changed.
* Clearly state any assumptions made when information is missing.
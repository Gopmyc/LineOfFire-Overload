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

- Group variable declarations and assignments whenever possible.
- Align `=` operators vertically with tabs within the same scope.
- Keep code clear, structured, and consistent.
- Avoid multi-responsibility scripts: each script/class/component should have a clearly defined role.

## Object-Oriented Programming

- Prefer an object-oriented approach when it improves the design.
- Use Lua tables, metatables, and prototypes compatible with Lua 5.1 when they improve structure.
- Encapsulate internal state in `_private` when it should not be manipulated directly.
- Prefer reusable objects/components/modules over global functions or isolated procedural code.
- Avoid unnecessary abstraction: OOP should improve maintainability, not add artificial complexity.

## Logic

- Prefer Lua `and / or` ternary-style expressions when they improve conciseness.
- Avoid `if / then / else` when a readable expression can replace it cleanly.
- Never sacrifice clarity for excessive conciseness.

## Methodology

Before implementing anything:

1. Analyze the `LineOfFire` project.
2. Analyze available systems in `Overload - 593`.
3. Identify the best engine-native integration approach.

Then:

- Implement only what is necessary.
- Briefly explain important technical choices.
- List modified files and why each file was changed.
- Clearly state any assumptions made when information is missing.

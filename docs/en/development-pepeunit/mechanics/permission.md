# Working with access

The access system works only for `Unit` and `UnitIO` with the `Private` [visibility level](/development-pepeunit/mechanics/visibility). `Public` and `Internal` need no access. For `Repo`, access is granted not by the creator but by the [access credentials](/development-pepeunit/mechanics/entities#repo) of each `User`.

## What a Permission is

A `Permission` is a record of two parts: who (the agent) and to what (the resource).

Part | Allowed values
-- | --
Agent | `User` or `Unit`
Resource | `Unit` or `UnitIO`

A `Permission` does not grant rights to change anything. It makes the resource visible to the agent, including in search, and what can be done with it is determined by the [agent capabilities for visible entities](/development-pepeunit/mechanics/visibility#agent-capabilities-for-visible-entities).

Only the creator of a `Unit` or `UnitIO` can grant a `Permission` for it. The `Admin` or `Owner` role does not give this right.

## Creating access

1. Open `Units` → `Unit` or its `UnitIO`
1. Tap `Access`: a list of agents that see this entity opens
1. Tap `Add`
1. Choose the access kind: `User` or `Unit`
1. Find the agent you need and select it

## Removing access

1. Open `Access` of the `Unit` or `UnitIO`
1. Tap the agent whose access needs to be removed. Access is revoked immediately, without confirmation

A `Permission` can be deleted by the creator of the resource or by the agent itself, that is, a `User` can give up access to someone else's entity.

## Permissions that always exist

Some `Permission` records are created by Pepeunit itself and cannot be removed:

Agent | Resource | Where it comes from
-- | -- | --
Creator | Their own `Unit` and their own `UnitIO` | Created together with the resource. The creator cannot revoke their own access
`Unit` | The `Unit` itself | Created together with the `Unit`
`Unit` | Its own `UnitIO` | Created together with the `UnitIO`, so that a `Unit` always sees its own inputs and outputs

## Permission from Link

When a `User` creates a `Link` between the output of one `Unit` and the input of another, Pepeunit grants a `Permission` automatically, so that the linked `Unit` see each other even on `Private`:

1. The `Unit` with the output gets access to the `UnitIO` of the input
1. The `Unit` with the input gets access to the `UnitIO` of the output
1. The `Unit` with the output gets access to the `Unit` with the input

When a `Link` is deleted, the access of the `Unit` with the output to the input is removed, and the other records remain. If some access had already been granted manually, the error on creation or deletion is ignored.

## Access checks on requests

What is checked | How
-- | --
A single `Unit` or `UnitIO` | `Public` is let through, `Internal` only for `User` and `Unit`, `Private` only with a found `Permission`
List | A `Bot` sees only `Public`. For `User` and `Unit`, `Internal` and those `Private` for which they have a `Permission` are added
Internal `Backend` call | Visibility is not checked

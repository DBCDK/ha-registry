<!--
SPDX-FileCopyrightText: 2024 Christina Sørensen
SPDX-FileContributor: Christina Sørensen

SPDX-License-Identifier: EUPL-1.2
-->

# Contributing Guide

`ha-registry` is a project by [DBC Digital](https://www.dbc.dk/). As such, much
of the development of the project is done by employees from DBC's platform
team.

This means that we have a certain direction that we want the project to strive
towards, and that certain architectural decisions are mostly made in house. 

This also means that if you're not from DBC, it would be wise to reach out to
us early if you wish to contribute, e.g. by opening and issue and asking if the
feature you want to implement is something we would accept, and to make sure
that no one else is already working on it in house.

## Development Environment

`ha-registry` is a [NixOS](https://nixos.org) first project, meaning that we
aim to provide first class support for the NixOS distribution, and that we
expect all contributors to, at minimum, have the [Nix package
manager](https://github.com/nixos/nix) or an equivalent (e.g.
[Lix](https://lix.systems)) installed.

If you have a working Nix package manager, you can enter the development shell
by typing `nix develop` in the root of the project. This will give you several
useful things:
- Pre-commit checks, ensuring your code is up to standard
- All the packages needed to develop on `ha-registry`, including the correct
rust toolchain

We advise installing [direnv](https://direnv.net/), as it makes you
automatically enter the development environment whenever you enter the project
root. That way, you don't forget to turn on all the checks before contributing!

There are NixOS VM tests that spin up a production setup in virtual machines
and checks and ensures that everything is working as expected. These can be run
as part of the larger set of checks included via the nix flake by typing `nix
flake check`. For convenience, you can add the `-L` flag to follow the logs as
the tests are running.

## Standards 

`ha-registry` strives to maintain a high standard when it comes to our "release
engineering" and developemnt process.

As such, we expect all developers to:
- Make only commits that conform to [conventional commits](https://www.conventionalcommits.org).
- Ensure their code if formatted with the projects formatters, which can be done with `nix fmt`.
- Ensure all changes include testing of the functionality they add.
- That all PR branches are only updated with rebase.
- That all merges are rebase merges.
- That code attribution is considered for any changes, and that code is licenses under [EUPL](https://commission.europa.eu/content/european-union-public-licence_en).
- That we maintain productive and welcoming discussions, and that our behavior lives up to [the code of conduct](https://www.contributor-covenant.org/).
- That we document our changes.

We also have certain expectations for readability of the code contributed, that
it's architecture fits with the rest of the project, and that things are kept
performant and "idiomatic".

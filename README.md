# nixpkgs-review-checks

Add additional checks and more information from build logs and outputs to the reports generated by [Mic92/nixpkgs-review](https://github.com/Mic92/nixpkgs-review/).

## Features

- Search through logs to find special keywords that indicate a common error like `Ran 0 tests in 0.000s` by pytest or stale substituteInPlace
- Sort build failures by failing on master and new failing via hydra-check
- Run nixpkgs-hammering, filter warnings and add them to the report
- Automatically upload logs on build failures to termbin
- Check binaries and shared objects for missing objects and left over debugging symbols
- Block the review shell from closing if there are unstaged changes in nixpkgs
- Filter empty reports and non usefull reports for certain people

## Installation

### Shadow nixpkgs-review

- The following programs need to be installed in your enviroment if you want to shadow your nixpkgs-review command:
  - ansi2html
  - bc
  - bloaty
  - coreutils
  - curl
  - gawk
  - gh
  - jq
  - hydra-check
  - mdcat
  - nix
  - nixpkgs-hammer
  - pup
  - ripgrep
  - savepagenow

Optionally you can install [cached-nix-shell](https://github.com/xzfc/cached-nix-shell) to speedup the start of nixpkgs-review.

- Source `nixpkgs-review-checks-hook` in your `~/.bashrc`.

```bash
source ~/source/nixpkgs-review-checks/nixpkgs-review-checks-hook
```

### Invoke nixpkgs-review-checks (Alpha)

If you don't want to change your enviroment you can invoke `nixpkgs-review-checks` instead of `nixpkgs-review`.
This can also be aliased

```bash
alias nixpkgs-review='nixpkgs-review-checks'
```

## Usage

If you opted into shadow the command invoke `nixpkgs-review` otherwise `nixpkgs-review-checks`.

## Configuration

- `$NIXPKGS_REVIEW_CHECKS_DEBUG` Set to not post any reports and show debug output
- `$NIXPKGS_REVIEW_CHECKS_RUN` Set after execution, unset to re-run
- `$NIXPKGS_REVIEW_CHECKS_SOURCE` Path to the nixpkgs repository to be able to run nixpkgs-review from anywhere
- `$NIXPKGS_REVIEW_GITHUB_TOKEN` Token to use for gist uploads

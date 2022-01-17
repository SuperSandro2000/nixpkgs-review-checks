#!/bin/bash
# source this in your .bashrc

nixpkgs-review() {
  case "${1:-}" in
    "post-result")
      # shellcheck disable=SC2154
      if [[ $name == name=review-shell || -v PR ]]; then
        local correct_dir=false

        if [[ -d nixpkgs ]]; then
          cd nixpkgs || return=$? && return=$?
          correct_dir=true
          if [[ $return -eq 0 ]]; then
            correct_dir=true
          else
            echo "Can't cd nixpkgs"
            return
          fi
        fi

        if [[ $correct_dir == "false" && -d "../nixpkgs" ]]; then
          cd ../nixpkgs || return=$? && return=$?
          if [[ $return -eq 0 ]]; then
            correct_dir=true
          else
            echo "Can't cd nixpkgs"
            return
          fi
        fi
        if [[ ! -d pkgs ]]; then
          echo "Not in nixpkgs. Aborting"
          return
        fi

        if [[ -n $(git diff --name-only 2>&1) ]]; then
          echo "There are unstaged files. Not leaving review-shell as long they are present!"
          return
        else
          cd ..
        fi

        # skip posting reports without any summary which means no packages where build
        if [[ -z $(rg -co summary report.md) ]]; then
          echo -e "Report does not contain any \u001b[36msummary\u001b[0m. Report was not posted."
          return
        fi

        # skip posting reports if ofborg already build this exact package
        local arch
        arch=$(nix-instantiate --eval --json --expr builtins.currentSystem | jq -r)
        ofborg_state=$(curl -H "Authorization: token $GITHUB_TOKEN" -X POST https://api.github.com/graphql --data "{ \"query\": \"$(sed 's/"/\\"/g' "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"/ofborg.graphql | tr -d '\n')\", \"variables\": \"{\\\"PR\\\": $PR}\"}" -s | jq -r ".[][][][][][][][][][][][][]|select(.name | contains(\"passthru.tests on $arch\")).conclusion")

        # report contains one summary, one package was build and ofborg reported success for building this package
        if [[ $(rg -co '</summary>' report.md) == 1 && $(rg -co "1 package built:" report.md) == 1 && -z $(rg -co "following issues got" report.md) && $ofborg_state == SUCCESS ]]; then
          echo -e "This report only contains one package build and ofborg already tested this. Report was not posted."
          return
        fi

        if [[ $(gh api /repos/nixos/nixpkgs/pulls/"$PR" | jq -r .state) == closed ]]; then
          echo -e "The PR is already \u001b[36mmerged/closed\u001b[0m. Report was not posted."
          return
        fi

        local author blocklist
        author=$(gh api /repos/nixos/nixpkgs/pulls/"$PR" | jq -r .user.login)
        # hexa -> mweinelt; qyliss -> alyssais
        blocklist=("adisbladis" "alyssais" "ashkitten" "andir" "edef1c" "mweinelt")

        # users which requested to not receive build confirmations
        # shellcheck disable=SC2076
        if [[ " ${blocklist[*]} " =~ " $author " ]]; then
          if ! rg failed report.md &>/dev/null; then
            echo -e "Report does not contain any \u001b[36mfailed\u001b[0m builds. Report was not posted."
            return
          fi
        fi

        if [[ -n $NIXPKGS_REVIEW_CHECKS_DEBUG ]]; then
          echo -e "\u001b[36mDEBUG\u001b[0m: Would post the report."
        else
          command nixpkgs-review "$@" && exit
        fi
      else
        command nixpkgs-review "$@"
      fi
      ;;
    "pr" | "rev")
      local command flags skip_package skip_package_regex skip_package_regex_python

      command=$*
      shift ${#@}

      skip_package="digikam gpt2tc lumo qemu_full tts"
      skip_package_regex=".*ceph.* .*pytorch.* .*sage.* .*tensorflow.*"
      skip_package_regex_python="baselines edward mask-rcnn pyro-ppl pytorchWithCuda scikit-tda tensorboardx tensorflow.* tensorly tflearn torchgpipe torchvision umap-learn"

      for package in $skip_package; do
        flags="${flags:+$flags }--skip-package $package"
      done
      for package in $skip_package_regex; do
        flags="${flags:+$flags }--skip-package-regex $package"
      done
      for package in $skip_package_regex_python; do
        flags="${flags:+$flags }--skip-package-regex 'python\\d+Packages\\.$package'"
      done

      # dedup PR numbers
      if [[ $* =~ - ]]; then
        flags="${flags:+$flags }$*"
      else
        flags="${flags:+$flags }$(echo "$*" | xargs -n1 | sort -u | xargs)"
      fi

      (
        local nixpkgs=${NIXPKGS_REVIEW_CHECKS_SOURCE:-$HOME/src/nixpkgs}
        if [[ -d $nixpkgs ]]; then
          cd "$nixpkgs" || return
        fi

        check() {
          type -P "$1"
        }
        local review_command="command nixpkgs-review $command $flags"

        if check bc && check bloaty && check coreutils && check curl && check gawk && check gh && check sed && check hydra-check && check mdcat && check jp && check pup && ansi2html && check rg && savepagenow; then
          $review_command
        else
          nix_shell=nix-shell
          if type -P cached-nix-shell &>/dev/null; then
            nix_shell=cached-nix-shell
          fi

          $nix_shell -I nixpkgs="$nixpkgs" "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/shell.nix" --run "$review_command"
        fi
      )
      ;;
    *)
      command nixpkgs-review "$@"
      ;;
  esac
}

nixpkgs-review-checks-hook() {
  # shellcheck disable=SC2154
  if [[ ($name == review-shell || -v PR) && -z $NIXPKGS_REVIEW_CHECKS_RUN ]]; then
    # prevent shell from closing with Ctrl+D when changes where made in nixpkgs
    set -o ignoreeof

    # fix python programs when reviewing python2 packages
    export PYTHONPATH=

    "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"/nixpkgs-review-checks
    export NIXPKGS_REVIEW_CHECKS_RUN=1
  fi
}

export PROMPT_COMMAND="${PROMPT_COMMAND:+${PROMPT_COMMAND}; }nixpkgs-review-checks-hook"

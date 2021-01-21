#!/bin/bash
# source this in your .bashrc

nixpkgs-review() {
  case "$1" in
    "post-result")
      if [[ $GIT_AUTHOR_NAME == nixpkgs-review ]]; then
        correct_dir=false

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
          echo -e "Report does not contain any \u001b[36summary\u001b[0m. Report was not posted."
          return
        fi

        if [[ $(gh api /repos/nixos/nixpkgs/pulls/"$PR" | jq -r .state) == closed ]]; then
          echo -e "The PR is already \u001b[36mmerged/closed\u001b[0m. Report was not posted."
          return
        fi

        local author blocklist
        author=$(gh api /repos/nixos/nixpkgs/pulls/"$PR" | jq -r .user.login)
        # hexa -> mweinelt; qyliss -> alyssais
        blocklist=("alyssais" "ashkitten" "andir" "edef1c" "mweinelt")

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
    "pr")
      shift
      local flags skip_package skip_package_regex
      skip_package="bareos digikam iosevka librealsense libreoffice lumo pcl mrtrix simpleitk smesh torchgpipe torchvision tts"
      skip_package_regex="\w*ceph\w* \w*edward freecad\w* opencascade\w* \w*sage\w* samba4?Full \w*pyro-ppl \w*pytorch\w* \w*tensorflow\w* \w*tflearn qgis\w* vtk\w* \w*wine\w*"

      for package in $skip_package; do
        flags="${flags:+$flags }--skip-package $package"
      done
      for package in $skip_package_regex; do
        flags="${flags:+$flags }--skip-package-regex $package"
      done

      cached-nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/nixpkgs-unstable.tar.gz \
        -p bloaty curl gawk gnused hydra-check mdcat jq pup ripgrep \
        --run "nixpkgs-review pr $flags $*"
      ;;
    *)
      command nixpkgs-review "$@"
      ;;
  esac
}

nixpkgs-review-checks() {
  if [[ $GIT_AUTHOR_NAME == nixpkgs-review && -z $NIXPKGS_REVIEW_CHECKS_RUN ]]; then
    # prevent shell from closing when changes where made in nixpkgs
    set -o ignoreeof

    "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"/nixpkgs-review-checks
    export NIXPKGS_REVIEW_CHECKS_RUN=1
  fi
}

PROMPT_COMMAND="${PROMPT_COMMAND:+${PROMPT_COMMAND}; }nixpkgs-review-checks"

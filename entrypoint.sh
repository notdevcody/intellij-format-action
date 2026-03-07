#!/bin/bash
set -e

download_idea() {
  local prefix="idea"
  [[ "$(printf '%s\n' "2025.3" "$idea_version" | sort -V | head -1)" != "2025.3" ]] && prefix="ideaIC"

  wget --no-verbose -O /tmp/idea.tar.gz "https://download.jetbrains.com/idea/${prefix}-${idea_version}.tar.gz"
  mkdir -p "$IDEA_DIR"
  tar xzf /tmp/idea.tar.gz -C "$IDEA_DIR" --strip-components=1
  rm /tmp/idea.tar.gz
}

check_idea_version() {
  if [[ -d "$IDEA_DIR/bin" ]]; then
    local output
    output=$(IDEA_JDK="/usr/lib/jvm/java-17-openjdk" "$IDEA_DIR/bin/idea.sh" --version 2>/dev/null || true)
    if [[ "$output" == *"$idea_version"* ]]; then
      echo "Valid IntelliJ IDEA version found."
      echo "Using cached files at $IDEA_DIR."
    else
      echo "Invalid IntelliJ IDEA version found. Redownloading..."
      rm -rf "$IDEA_DIR"
      download_idea
    fi
  else
    echo "No IntelliJ IDEA installation found. Downloading..."
    download_idea
  fi
}

if [[ $# -ne 9 ]]; then
  echo "Exactly 9 parameters required: idea-version, path, include-glob, push-type, push-title, push-description, fail-on-changes, style-settings-file, mute-formatter-output"
  exit 1
fi

idea_version=$1
base_path=$2
include_pattern=$3
push_type=$4
push_title=$5
push_description=$6
fail_on_changes=$7
style_settings_file=$8
mute_formatter_output=$9

style_flags="-allowDefaults"

if [[ "$style_settings_file" != "unset" ]]; then
  style_flags="-s $style_settings_file"
fi

IDEA_DIR="/github/workflow/idea-cache"

check_idea_version

git config --global --add safe.directory /github/workspace

cd "/github/workspace/$base_path" || exit 2

if [[ "$mute_formatter_output" == "true" ]]; then
  output_redirect=">/dev/null 2>&1"
else
  output_redirect=""
fi

eval IDEA_JDK="/usr/lib/jvm/java-21-openjdk" "$IDEA_DIR/bin/format.sh" -m "$include_pattern" $style_flags -r . $output_redirect

changed_files=$(git status --short)
changed_files_count=$(echo "$changed_files" | grep -v -e '^$' | wc -l)

echo "files-changed=$changed_files_count" >> $GITHUB_OUTPUT

if [[ $changed_files_count -gt 0 ]]; then
  echo "Files changed by formatter:"
  echo "$changed_files"
  git config user.name "GitHub"
  git config user.email "noreply@github.com"
  if [[ "$push_type" == "commit" ]]; then
    git commit --all -m "$push_title" --author="github-actions[bot] <github-actions[bot]@users.noreply.github.com>"
    git push
  elif [[ "$push_type" == "pull-request" ]]; then
    if [[ -z "$GITHUB_TOKEN" ]]; then
      echo "-!- GITHUB_TOKEN not set. Cannot create pull request. -!-"
      exit 1
    fi
    current_branch=$(git branch --show-current)
    branch_name="format-$current_branch-$(date +%s)"
    git checkout -b "$branch_name"
    git add .
    git commit -m "$push_title"
    git push origin "$branch_name"
    gh pr create --title "$push_title" --body "$push_description" --head "$branch_name" --base main
  fi
fi

if [[ "$fail_on_changes" == "true" && $changed_files_count -gt 0 ]]; then
  exit 1
fi

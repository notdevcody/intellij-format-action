# IntelliJ IDEA Format Action

A GitHub Action that formats your code using the IntelliJ formatter.

## Examples

Both examples implement caching of downloaded IDE files.
Cache generation might take a while on the first run, but saves bandwidth and is faster later on. <br>
**NOTE: If the actions fails due to the formatting changing files, cache will not be saved.**

---

Formats all files that are supported by the formatter in your repository and creates a pull request whenever there's a push to the `main` branch, including pull requests to it:

```yaml
name: IDEA Format

on:
  push:
    branches: ["main"]
  pull_request:
    branches: ["main"]

jobs:
  formatting:
    runs-on: ubuntu-latest
    steps:
      - if: github.event_name != 'pull_request'
        uses: actions/checkout@v6
      - if: github.event_name == 'pull_request'
        uses: actions/checkout@v6
        with:
          ref: ${{ github.event.pull_request.head.ref }}
      - name: Cache IDEA
        uses: actions/cache@v5
        with:
          path: /home/runner/work/_temp/_github_workflow/idea-cache
          key: ${{ runner.os }}-idea-cache
      - uses: notdevcody/intellij-format-action@v4
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

Formats all files that are supported by the formatter in your repository and directly commits the changes whenever there's a push to the `main` branch, including pull requests to it:

```yaml
name: IDEA Format

on:
  push:
    branches: ["main"]
  pull_request:
    branches: ["main"]

jobs:
  formatting:
    runs-on: ubuntu-latest
    steps:
      - if: github.event_name != 'pull_request'
        uses: actions/checkout@v6
      - if: github.event_name == 'pull_request'
        uses: actions/checkout@v6
        with:
          ref: ${{ github.event.pull_request.head.ref }}
      - name: Cache IDEA
        uses: actions/cache@v5
        with:
          path: /home/runner/work/_temp/_github_workflow/idea-cache
          key: ${{ runner.os }}-idea-cache
      - uses: notdevcody/intellij-format-action@v4
        with:
          push-type: "commit"
```

## Inputs

While none of these inputs are mandatory, you can specify them to modify the action's behavior.

### `include-glob`

Pattern for files to include. Supports glob-style wildcards. Multiple patterns can be separated by commas.<br>
**Default:** `*.*`

### `path`

Path to project directory. The formatter is executed recursively from here.<br>
Must be relative to the workspace.<br>
**Default:** `.`

### `push-type`

Type of push to perform.<br>
Options are `commit`, `pull-request` or `none`.<br>
**Default:** `pull-request`

### `push-title`

The title to use for the commit or pull request.<br>
**Default:** `IntelliJ Code Format`

### `push-description`

The description to use for the pull request.<br>
Unused for commits.<br>
**Default**: Empty

### `fail-on-changes`

Fail if any files were changed by the formatter.<br>
**Default:** `true`

### `idea-version`

Version of IntelliJ IDEA to use.<br>
**Default:** `2025.2.6`

### `style-settings-file`

A path to IntelliJ IDEA code style settings .xml file.<br>
Leave default if you want the formatter to use .editorconfig files.<br>
**Default:** `unset` (`-allowDefaults` argument)

### `mute-formatter-output`

Mute the formatter output. Action output will still be logged.<br>
**Default:** `true`

## Outputs

### `files-changed`

Outputs the number of files which were formatted.<br>
Zero if none changed.

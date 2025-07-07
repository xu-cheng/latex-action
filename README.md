# latex-action

[![GitHub Actions Status](https://github.com/xu-cheng/latex-action/workflows/test/badge.svg)](https://github.com/xu-cheng/latex-action/actions)

A GitHub Action that compiles LaTeX documents to PDF using a complete TeXLive environment.

## Features

- 🐳 **Containerized**: Run in a [Docker container](https://github.com/xu-cheng/latex-docker/) with a full [TeXLive](https://www.tug.org/texlive/) installation.
- 📅 **TeXLive Version flexibility**: Support both the latest and historic versions of TeXLive.
- 🐧 **Multi-platform**: Support both Alpine and Debian-based Docker images.
- 📁 **Multi-document support**: Compile multiple LaTeX files in a single workflow.
- 🔧 **Flexible compilation**: Support various LaTeX engines (pdfLaTeX, XeLaTeX, LuaLaTeX).
- 🎨 **Custom fonts**: Install additional fonts.
- 📦 **System packages**: Add extra system packages as needed.
- ⚙️ **Customizable**: Run arbitrary pre/post-compile scripts.

> [!TIP]
> For running arbitrary commands in a TeXLive environment, use [texlive-action](https://github.com/xu-cheng/texlive-action) instead.

## Inputs

Configure the action by providing these inputs in the `with` section:

### Required Inputs

- **`root_file`** (required)
  The root LaTeX file(s) to compile. Supports glob patterns and multiple files via multi-line input:

  ```yaml
  - uses: xu-cheng/latex-action@v4
    with:
      root_file: |
        file1.tex
        file2.tex
  ```

### Environment Configuration

- **`texlive_version`**
  TeXLive version to use (2020-2025 or 'latest'). Defaults to latest. Cannot be used with `docker_image`.

  ```yaml
  - uses: xu-cheng/latex-action@v4
    with:
      root_file: main.tex
      texlive_version: 2022
  ```

- **`os`**
  Base operating system for the Docker image (`alpine` or `debian`). Defaults to `alpine`.

  ```yaml
  - uses: xu-cheng/latex-action@v4
    with:
      root_file: main.tex
      os: debian
  ```

- **`docker_image`**
  Custom Docker image to use (overrides `texlive_version` and `os`). We recommend to use [latex-docker images](https://github.com/xu-cheng/latex-docker/). An example if you want to pin the docker image.

  ```yaml
  - uses: xu-cheng/latex-action@v4
    with:
      root_file: main.tex
      docker_image: ghcr.io/xu-cheng/texlive-alpine@sha256:<hash>
  ```

### Compilation Settings

- **`working_directory`**
  Working directory for the compilation process.

- **`work_in_root_file_dir`**
  Change to each root file's directory before compilation. Useful for multi-document builds where each document has its own directory structure.

- **`continue_on_error`**
  Continue building remaining documents even if some fail. The action will still report failure if any document fails.

- **`compiler`**
  LaTeX compiler to use. Defaults to [`latexmk`](https://ctan.org/pkg/latexmk) for automated compilation.

- **`args`**
  Additional arguments passed to the LaTeX compiler. Defaults to `-pdf -file-line-error -halt-on-error -interaction=nonstopmode`.

### Dependencies

- **`extra_system_packages`**
  Additional system packages to install (space-separated). Uses `apk` for Alpine or `apt-get` for Debian.

  ```yaml
  extra_system_packages: "inkscape ghostscript"
  ```

- **`extra_fonts`**
  Extra font files to install for fontspec (.ttf/.otf). Supports glob patterns and multi-line input:

  ```yaml
  extra_fonts: |
    ./path/to/custom.ttf
    ./fonts/*.otf
  ```

### Scripts

- **`pre_compile`**
  Bash commands to execute before compilation (e.g., package updates):

  ```yaml
  pre_compile: "tlmgr update --self && tlmgr update --all"
  ```

- **`post_compile`**
  Bash commands to execute after compilation (e.g., cleanup tasks):

  ```yaml
  post_compile: "latexmk -c"
  ```

### LaTeX Engine Options

> [!IMPORTANT]
> The following inputs only work with the default `latexmk` compiler.

- **`latexmk_shell_escape`**
  Enable shell-escape for latexmk (allows external command execution).

- **`latexmk_use_lualatex`**
  Use LuaLaTeX engine with latexmk.

- **`latexmk_use_xelatex`**
  Use XeLaTeX engine with latexmk.

## Example

```yaml
name: Build LaTeX document
on: [push]
jobs:
  build_latex:
    runs-on: ubuntu-latest
    steps:
      - name: Set up Git repository
        uses: actions/checkout@v4
      - name: Compile LaTeX document
        uses: xu-cheng/latex-action@v4
        with:
          root_file: main.tex
      - name: Upload PDF file
        uses: actions/upload-artifact@v4
        with:
          name: PDF
          path: main.pdf
```

## FAQs

### How to use XeLaTeX or LuaLaTeX instead of pdfLaTeX?

By default, this action uses pdfLaTeX. If you want to use XeLaTeX or LuaLaTeX, you can set the `latexmk_use_xelatex` or `latexmk_use_lualatex` input respectively. For example:

```yaml
- uses: xu-cheng/latex-action@v4
  with:
    root_file: main.tex
    latexmk_use_xelatex: true
```

```yaml
- uses: xu-cheng/latex-action@v4
  with:
    root_file: main.tex
    latexmk_use_lualatex: true
```

Alternatively, you could create a `.latexmkrc` file. Refer to the [`latexmk` document](http://texdoc.net/texmf-dist/doc/support/latexmk/latexmk.pdf) for more information.

### How to enable `--shell-escape`?

To enable `--shell-escape`, set the `latexmk_shell_escape` input.

```yaml
- uses: xu-cheng/latex-action@v4
  with:
    root_file: main.tex
    latexmk_shell_escape: true
```

### Where is the PDF file? How to upload it?

The compiled PDF file will be placed in the same directory as the LaTeX source file. You have several options for handling the generated PDF:

- **Upload as artifact** - Use [`@actions/upload-artifact`](https://github.com/actions/upload-artifact) to make the PDF available in the workflow tab:

  ```yaml
  - uses: actions/upload-artifact@v4
    with:
      name: PDF
      path: main.pdf
  ```

- **Attach to releases** - Use [`@softprops/action-gh-release`](https://github.com/softprops/action-gh-release) to attach the PDF to GitHub releases.

- **Deploy elsewhere** - Use standard tools like `scp`, `git`, or `rsync` to upload the PDF to any destination. For example, push to the `gh-pages` branch to serve via GitHub Pages.

### How to add additional paths to the LaTeX input search path?

Sometimes you may have custom package (`.sty`) or class (`.cls`) files in other directories. If you want to add these directories to the LaTeX input search path, you can add them in `TEXINPUTS` environment variable. For example:

```yaml
- name: Download custom template
  run: |
    curl -OL https://example.com/custom_template.zip
    unzip custom_template.zip
- uses: xu-cheng/latex-action@v4
  with:
    root_file: main.tex
  env:
    TEXINPUTS: ".:./custom_template//:"
```

Note that you should NOT use `{{ github.workspace }}` or `$GITHUB_WORKSPACE` in `TEXINPUTS`. This action runs in a separate Docker container where the workspace directory is mounted. Therefore, the workspace directory inside the Docker container is different from `github.workspace`.

You can find more information of `TEXINPUTS` [here](https://tex.stackexchange.com/a/93733).

### It fails to build the document, how to solve it?

1. **Check the build log** - Examine the GitHub Actions log output for specific error messages
2. **Test locally** - Try building your document locally with the same LaTeX distribution
3. **Create a minimal example** - Narrow down the issue by creating a [minimal working example][mwe]
4. **Check dependencies** - Ensure all required packages and fonts are properly configured
5. **Get help** - [Open an issue](https://github.com/xu-cheng/latex-action/issues/new) with a [minimal working example][mwe] if you need assistance

## License

MIT

[mwe]: https://tex.meta.stackexchange.com/questions/228/ive-just-been-asked-to-write-a-minimal-working-example-mwe-what-is-that

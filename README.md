# latex-action

[![GitHub Actions Status](https://github.com/xu-cheng/latex-action/workflows/Test%20Github%20Action/badge.svg)](https://github.com/xu-cheng/latex-action/actions)

GitHub Action to compile LaTeX documents.

It runs in [a docker container](https://github.com/xu-cheng/latex-docker) with a full [TeXLive](https://www.tug.org/texlive/) environment installed.

If you want to run arbitrary commands in a TeXLive environment, use [texlive-action](https://github.com/xu-cheng/texlive-action) instead.

## Inputs

Each input is provided as a key inside the `with` section of the action.

* `root_file`

    The root LaTeX file to be compiled. This input is required. You can also pass multiple files as a multi-line string to compile multiple documents. Each file path will be interpreted as bash glob pattern. For example:
    ```yaml
    - uses: xu-cheng/latex-action@v3
      with:
        root_file: |
          file1.tex
          file2.tex
    ```

* `working_directory`

    The working directory for this action.

* `work_in_root_file_dir`

    Change directory into each root file's directory before compiling each documents. This will be helpful if you want to build multiple documents and have the compiler work in each of the corresponding directories.

* `continue_on_error`

    Continuing to build document even with LaTeX build errors. This will be helpful if you want to build multiple documents regardless of any build error. Noted that even with this input set, this action will always report failure upon any build error. If you want to prevent the GitHub action job also from failure, please refer to [the upstream document](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#jobsjob_idstepscontinue-on-error).

* `compiler`

    The LaTeX engine to be invoked. By default, [`latexmk`](https://ctan.org/pkg/latexmk) is used, which automates the process of generating LaTeX documents by issuing the appropriate sequence of commands to be run.

* `args`

    The extra arguments to be passed to the LaTeX engine. By default, it is `-pdf -file-line-error -halt-on-error -interaction=nonstopmode`. This tells `latexmk` to use `pdflatex`. Refer to [`latexmk` document](http://texdoc.net/texmf-dist/doc/support/latexmk/latexmk.pdf) for more information.

* `extra_system_packages`

    The extra packages to be installed by [`apk`](https://pkgs.alpinelinux.org/packages) separated by space. For example, `extra_system_packages: "inkscape"` will install the package `inkscape` to allow using SVG images in your LaTeX document.

* `extra_fonts`

    Install extra `.ttf`/`.otf` fonts to be used by `fontspec`. You can also pass multiple files as a multi-line string. Each file path will be interpreted as bash glob pattern. For example:
    ```yaml
    - uses: xu-cheng/latex-action@v3
      with:
        root_file: main.tex
        extra_fonts: |
          ./path/to/custom.ttf
          ./fonts/*.otf
    ```

* `pre_compile`

    Arbitrary bash codes to be executed before compiling LaTeX documents. For example, `pre_compile: "tlmgr update --self && tlmgr update --all"` to update all TeXLive packages.

* `post_compile`

    Arbitrary bash codes to be executed after compiling LaTeX documents. For example, `post_compile: "latexmk -c"` to clean up temporary files.

* `texlive_version`

    The version of TeXLive to be used. Supported inputs include 2020, 2021, 2022, 2023, 2024, and latest. By default the latest TeXLive is used. This input cannot co-exist with `docker_image` input. An example to use this input:
    ```yaml
    - uses: xu-cheng/latex-action@v3
      with:
        root_file: main.tex
        texlive_version: 2022
    ```

* `docker_image`

    Custom which docker image to be used. Only [latex-docker images](https://github.com/xu-cheng/latex-docker/pkgs/container/texlive-full) are supported. For example if you want to pin the docker image:
    ```yaml
    - uses: xu-cheng/latex-action@v3
      with:
        root_file: main.tex
        docker_image: ghcr.io/xu-cheng/texlive-full:20230801
    ```

**The following inputs are only valid if the input `compiler` is not changed.**

* `latexmk_shell_escape`

    Instruct `latexmk` to enable `--shell-escape`.

* `latexmk_use_lualatex`

    Instruct `latexmk` to use LuaLaTeX.

* `latexmk_use_xelatex`

    Instruct `latexmk` to use XeLaTeX.

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
        uses: xu-cheng/latex-action@v3
        with:
          root_file: main.tex
      - name: Upload PDF file
        uses: actions/upload-artifact@v4
        with:
          name: PDF
          path: main.pdf
```

### Build PDF with SVG Support

**Note:** Due to the permission problem, if you're running self-hosted runner change the post_compile command to `post_compile: "latexmk -c && chown 1000:1000 -R *"` to correct permission. Here the `1000:1000` corresponds to the UID & GID of the user running the runner.

``` yaml
name: Build LaTeX document
on: [push]
jobs:
  build_latex:
    runs-on: ubuntu-latest
    steps:
      - name: Set up Git repository
        uses: actions/checkout@v4

      - name: Compile LaTeX document
        uses: xu-cheng/latex-action@v3
        with:
          #pre_compile: "latexmk -C"
          root_file: main.tex
          latexmk_use_xelatex: true
          latexmk_shell_escape: true
          texlive_version: 2023
          extra_system_packages: "inkscape"
          continue_on_error: true
          args: "-pdf -file-line-error -interaction=nonstopmode"
          post_compile: "latexmk -c"

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
- uses: xu-cheng/latex-action@v3
  with:
    root_file: main.tex
    latexmk_use_xelatex: true
```

```yaml
- uses: xu-cheng/latex-action@v3
  with:
    root_file: main.tex
    latexmk_use_lualatex: true
```

Alternatively, you could create a `.latexmkrc` file. Refer to the [`latexmk` document](http://texdoc.net/texmf-dist/doc/support/latexmk/latexmk.pdf) for more information.

### How to enable `--shell-escape`?

To enable `--shell-escape`, set the `latexmk_shell_escape` input.

```yaml
- uses: xu-cheng/latex-action@v3
  with:
    root_file: main.tex
    latexmk_shell_escape: true
```

### Where is the PDF file? How to upload it?

The PDF file will be in the same folder as that of the LaTeX source in the CI environment. It is up to you on whether to upload it to some places. Here are some example.
* You can use [`@actions/upload-artifact`](https://github.com/actions/upload-artifact) to upload a zip containing the PDF file to the workflow tab. For example you can add

  ```yaml
  - uses: actions/upload-artifact@v4
    with:
      name: PDF
      path: main.pdf
  ```

  It will result in a `PDF.zip` being uploaded with `main.pdf` contained inside.

* You can use [`@softprops/action-gh-release`](https://github.com/softprops/action-gh-release) to upload PDF file to the Github Release.
* You can use normal shell tools such as `scp`/`git`/`rsync` to upload PDF file anywhere. For example, you can git push to the `gh-pages` branch in your repo, so you can view the document using Github Pages.

### How to add additional paths to the LaTeX input search path?

Sometimes you may have custom package (`.sty`) or class (`.cls`) files in other directories. If you want to add these directories to the LaTeX input search path, you can add them in `TEXINPUTS` environment variable. For example:

```yaml
- name: Download custom template
  run: |
    curl -OL https://example.com/custom_template.zip
    unzip custom_template.zip
- uses: xu-cheng/latex-action@v3
  with:
    root_file: main.tex
  env:
    TEXINPUTS: ".:./custom_template//:"
```

Noted that you should NOT use `{{ github.workspace }}` or `$GITHUB_WORKSPACE` in `TEXINPUTS`. This action works in a separated docker container, where the workspace directory is mounted into it. Therefore, the workspace directory inside the docker container is different from `github.workspace`.

You can find more information of `TEXINPUTS` [here](https://tex.stackexchange.com/a/93733).

### It fails due to `xindy` cannot be found.

This is an upstream issue where `xindy.x86_64-linuxmusl` is currently missing in TeXLive. To work around it, try [this](https://github.com/xu-cheng/latex-action/issues/32#issuecomment-626086551).

### It fails to build the document, how to solve it?

* Try to solve the problem by examining the build log.
* Try to build the document locally.
* You can also try to narrow the problem by creating a [minimal working example][mwe] to reproduce the problem.
* [Open an issue](https://github.com/xu-cheng/latex-action/issues/new) if you need help. Please include a [minimal working example][mwe] to demonstrate your problem.

[mwe]: https://tex.meta.stackexchange.com/questions/228/ive-just-been-asked-to-write-a-minimal-working-example-mwe-what-is-that

## License

MIT

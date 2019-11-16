# latex-action

[![GitHub Actions Status](https://github.com/xu-cheng/latex-action/workflows/Test%20Github%20Action/badge.svg)](https://github.com/xu-cheng/latex-action/actions)

GitHub Action to compile LaTeX documents.

It runs in [a docker image](https://github.com/xu-cheng/latex-docker) with a full [TeXLive](https://www.tug.org/texlive/) environment installed.

## Inputs

* `root_file`

    The root LaTeX file to be compiled. This input is required.

* `working_directory`

    The working directory for the LaTeX engine.

* `compiler`

    The LaTeX engine to be invoked. By default, [`latexmk`](https://ctan.org/pkg/latexmk) is used, which automates the process of generating LaTeX documents by issuing the appropriate sequence of commands to be run.

* `args`

    The extra arguments to be passed to the LaTeX engine. By default, it is `-pdf -file-line-error -interaction=nonstopmode`. This tells `latexmk` to use `pdflatex`. Refer to [`latexmk` document](http://texdoc.net/texmf-dist/doc/support/latexmk/latexmk.pdf) for more information.

* `extra_system_packages`

    The extra packages to be installed by [`apk`](https://pkgs.alpinelinux.org/packages) separated by space. For example, `extra_system_packages: "py-pygments"` will install the package `py-pygments` to be used by the `minted` for code highlights.

## Example

```yaml
name: Build LaTeX document
on: [push]
jobs:
  build_latex:
    runs-on: ubuntu-latest
    steps:
      - name: Set up Git repository
        uses: actions/checkout@v1
      - name: Compile LaTeX document
        uses: xu-cheng/latex-action@master
        with:
          root_file: main.tex
```

## FAQs

### How to use XeLaTeX or LuaLaTeX instead of pdfLaTeX?

By default, this action uses pdfLaTeX. If you want to use XeLaTeX or LuaLaTeX, you can set the `args` to `-xelatex -file-line-error -interaction=nonstopmode` or `-lualatex --file-line-error --interaction=nonstopmode` respectively. Alternatively, you could create a `.latexmkrc` file. Refer to the [`latexmk` document](http://texdoc.net/texmf-dist/doc/support/latexmk/latexmk.pdf) for more information.

### How to enable `--shell-escape`?

To enable `--shell-escape`, you should add it to `args`. For example, set `args` to `-pdf -file-line-error -interaction=nonstopmode -shell-escape` when using pdfLaTeX.

### It fails to build the document, how to solve it?

[Open an issue](https://github.com/xu-cheng/latex-action/issues/new) if you need help.

## License

MIT

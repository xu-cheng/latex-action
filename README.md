# latex-action

[![GitHub Actions Status](https://github.com/xu-cheng/latex-action/workflows/Test%20Github%20Action/badge.svg)](https://github.com/xu-cheng/latex-action/actions)

GitHub Action to compile LaTeX documents.

It runs in [a docker image](https://github.com/xu-cheng/latex-docker) with a minimal [TeXLive](https://www.tug.org/texlive/) environment installed. Further, it uses [`texliveonfly`](https://ctan.org/pkg/texliveonfly) to find and install the missing packages.

## Inputs

* `root_file`

    The root LaTeX file to be compiled. This input is required.

* `working_directory`

    The working directory for `texliveonfly` to be invoked.

* `compiler`

    The LaTeX engine to used by `texliveonfly`. By default, [`latexmk`](https://ctan.org/pkg/latexmk) is used, which automates the process of generating LaTeX documents by issuing the appropriate sequence of commands to be run.

* `args`

    The extra arguments to be passed to the compiler by `texliveonfly`. By default, it is `-pdf -file-line-error -interaction=nonstopmode`. This tells `latexmk` to use `pdflatex`. Refer to [`latexmk` document](http://texdoc.net/texmf-dist/doc/support/latexmk/latexmk.pdf) for more information.

* `extra_packages`

    The extra packages to be installed by [`tlmgr`](https://www.tug.org/texlive/tlmgr.html) separated by space. For example, `extra_packages: "cm-super biblatex-ieee"` will install packages `cm-super` and `biblatex-ieee` explicitly.

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

If this Github action fails to build the document, it is likely due to `texliveonfly` failing to install the missing packages. In this case, you can pass them explicitly in `extra_packages`. Try to find the missing packages or the missing fonts in the build log. Alternatively, you could use the [`list_tl_pkgs.rb`](https://github.com/xu-cheng/latex-action/blob/master/tools/list_tl_pkgs.rb) script to list all the packages used by your LaTeX document. [Open an issue](https://github.com/xu-cheng/latex-action/issues/new) if you need help.

### Is it possible to change the TeXLive scheme?

The setup script installs TeXLive in small scheme to reduce the size. If you want to change it, you can specify it using `extra_packages`. For example, `extra_packages: scheme-medium` will install medium scheme, while `extra_packages: scheme-full` will install everything.

## License

MIT

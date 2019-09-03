# latex-action

GitHub Actions to compile LaTeX documents.

It runs in the docker with a minimal [TeXLive](https://www.tug.org/texlive/) environment installed. Further, it uses [`texliveonfly`](https://ctan.org/pkg/texliveonfly) to find and install the missing packages.

## Inputs

* `root_file`

    The root LaTeX file to be compiled. This input is required.

* `working_directory`

    The working directory for `texliveonfly` to be invoked.

* `compiler`

    The LaTeX engine to used by `texliveonfly`. By default, [`latexmk`](https://ctan.org/pkg/latexmk) is used.

* `args`

    The extra arguments to be passed to `texliveonfly`. By default, it is `-pdf -file-line-error -interaction=nonstopmode`.

* `extra_packages`

    The extra packages to be installed by [`tlmgr`](https://www.tug.org/texlive/tlmgr.html) separated by space. Sometimes, `texliveonfly` will fail to find the missing packages. In this case, you can pass them explicitly. For example, `extra_packages: "biblatex-trad biblatex-ieee"` will install packages `biblatex-trad` and `biblatex-ieee`.

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

## License

MIT

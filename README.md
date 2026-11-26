# 프로덕트를 처음부터 디자인하는 방법

사용자 중심으로 제품을 디자인하는 방법을 설명하는 소책자.

- [웹사이트에서 읽기](https://keunwoopark.github.io/design-product-from-scratch/)
- [한국어로 읽기](ko/README.md)
- [Read in English](en/README.md)
- [PDF (A5)](pdf/design-product-from-scratch-ko.pdf) · [English PDF (A5)](pdf/design-product-from-scratch-en.pdf)

## Repository layout

| Path | Contents |
|---|---|
| `ko/` | Korean text: `README.md` (preface), `chapter*.md`, `metadata.yaml` |
| `en/` | English translation, same files as `ko/` |
| `book/` | print edition shared by all languages (see [book/README.md](book/README.md)) |
| `figures/` | TikZ sources of the diagrams, with text in every language |
| `img/<lang>/` | diagrams built from `figures/`, per language |
| `img/shared/` | screenshots used by every language |
| `pdf/` | reading PDFs (A5, with covers), built by `make pdf` |
| `site/` | website: page template, styles, pandoc filters (`make site`) |

Each language lives in its own folder with the same file names, so chapters
line up across languages. Build a language's print book with
`make book lang=<folder>` (default `ko`).

The website is built with `make site` (needs only pandoc) into `build/site/`
and published to GitHub Pages by `.github/workflows/pages.yml` on every push
to `main`. It serves every language folder plus `img/` and `pdf/`, so after
changing figures or text, rebuild and commit `make figures` / `make pdf`
for the site to pick them up.

# 프로덕트를 처음부터 디자인하는 방법

사용자 중심으로 제품을 디자인하는 방법을 설명하는 소책자.

- [한국어로 읽기](ko/README.md)
- [PDF (A5)](pdf/design-product-from-scratch-ko.pdf)

## Repository layout

| Path | Contents |
|---|---|
| `ko/` | Korean text: `README.md` (preface), `chapter*.md`, `metadata.yaml` |
| `book/` | print edition shared by all languages (see [book/README.md](book/README.md)) |
| `figures/` | TikZ sources of the diagrams, with text in every language |
| `img/<lang>/` | diagrams built from `figures/`, per language |
| `img/shared/` | screenshots used by every language |
| `pdf/` | reading PDFs (A5, with covers), built by `make pdf` |

Each language lives in its own folder with the same file names, so chapters
line up across languages. Build a language's print book with
`make book lang=<folder>` (default `ko`).

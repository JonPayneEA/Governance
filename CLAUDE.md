# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build

This is a [Quarto](https://quarto.org) book project. The output is a multi-page HTML book rendered to `_book/`.

```bash
quarto render          # full build — all chapters and appendices
quarto preview         # live-reload local server (opens browser)
quarto render index.qmd  # render a single page
```

There are no tests, linters, or CI pipelines configured yet. The R project file `Governance_Documentation.Rproj` is present but the book is pure Quarto — no R code is executed during the build.

## Repository structure

The book is configured in `_quarto.yml`. Chapter and appendix order is defined there — the filename prefixes (`01-`, `03-`, `a-`, etc.) are for human sorting only; Quarto uses the order in `_quarto.yml`.

**Chapters** (core governance documents):
- `01-governance-framework.qmd` — parent document: roles, tier system, asset categories, AI governance, monitoring cadence
- `03-r-code-governance.qmd` — R-specific standards, Flode package architecture, fastverse conventions
- `04-python-code-governance.qmd` — Python standards, Flood Modeller API, ML tool requirements
- `05-hydrometric-data.qmd` — Bronze/Silver/Gold medallion architecture, Parquet schemas, QC flag system
- `06-flood-model-governance.qmd` — FMP/PDM/Black Box governance, model condition scoring, connection register
- `07-training-framework.qmd` — role-based training tracks and sign-off requirements

**Appendices**:
- `a-glossary.qmd` — terms
- `b-document-hierarchy.qmd` — how this suite relates to CDDO/Defra/Cabinet Office guidance
- `c-alignment-register.qmd` — tracks divergences from government policy and their resolutions
- `d-upcoming-changes.qmd` — proposed changes, open weaknesses, and resolved items with changelog
- `e-file-format-reference.qmd` — technical reference for accepted formats (moved from Chapter 2; normative rules live in the domain chapters)

**Other files**:
- `mcp-server-spec.md` — specification for the `fw-governance` MCP server that automates compliance checks against the registers; not part of the rendered book
- `water-theme.scss` — custom SCSS theme layered on top of the Quarto `cosmo` base theme
- `styles.css` — supplementary CSS (callout colours, table sizing, `.version-badge`)

## Document conventions

**Cross-references** use standard Quarto syntax: `@sec-governance-framework`, `@sec-hydrometric-data`, etc. Section anchors are defined with `{#sec-...}` on the heading line.

**Callouts** use the three types `.callout-note` (teal), `.callout-warning` (amber), `.callout-important` (red), styled to match the EA flood information palette.

**Tables** — most content tables use the pipe format. Striped styling is applied with `{.striped}` on the caption line.

**Version metadata** — each companion document opens with a `.callout-note` metadata table (Version, Status, Review Date, Parent Document). The parent framework version referenced there must stay in sync with `_quarto.yml` `version:`.

## Key architectural relationships

The document suite has a strict parent-child dependency:

- `01-governance-framework.qmd` is the parent. When roles, tier definitions, or the asset register structure change there, the same change must be checked in all companion documents.
- `05-hydrometric-data.qmd` defines the Parquet column schemas for Bronze, Silver, and Gold. These schemas are the interface contract with the MCP server spec (`mcp-server-spec.md` `[parquet_schemas.*]`). Schema changes require updating both files.
- `e-file-format-reference.qmd` is reference-only. Normative format requirements (Parquet mandatory, CSV restricted) are stated in the domain chapters; this appendix provides the technical rationale only.
- `c-alignment-register.qmd` must be updated whenever the framework diverges from or re-aligns with CDDO/Defra policy.
- `d-upcoming-changes.qmd` is the living record of proposed and resolved changes. When a weakness is fixed, mark it resolved there with a changelog entry rather than deleting it.

## Branch

Active development branch: `claude/add-water-theme-docs-q7DjC`

# Governance Restructure Design

**Date:** 2026-06-09  
**Author:** Jonathan Payne  
**Status:** Approved for implementation planning

---

## Organisational Context

The **National Forecasting and Warning Service (NFWS)** is headed by a Deputy Director. The operational teams within scope of this framework are:

- **FFM** (Fluvial and Coastal Flood Modelling) and **LFS** (Local Forecasting Service) — share a single G7 Steward
- **Warning team** — G7 Steward

The **Flood Forecasting Centre (FFC)** has its own G7 Steward but is **out of scope** for this work.

---

## Problem Statement

The current governance document is a single Quarto book scoped to the former Forecasting and Warning (F&W) team. As NFWS has grown and new teams look to adopt the same framework, three problems have emerged:

1. **Adding a new team is unclear.** Companion documents are written for a single team. There is no template or process for a new team to onboard without reworking core content.
2. **Shared datasets have no single owner.** Datasets used by multiple teams are derived independently, creating duplicated QC effort and divergent provenance trails. No Steward holds clear cross-team responsibility.
3. **Cross-references are brittle.** Companion documents reference the parent by section number ("Section 7.2") which breaks whenever the parent is restructured.

---

## Goals

- Make it straightforward to add a new operational team under the framework
- Establish a central data team with shared dataset stewardship and a capability/embedding programme
- Make companion documents team-agnostic so they are inherited, not rewritten, by each new team
- Add scope-defined companion documents for Flood Warnings and Procedure Tools
- Fix brittle cross-references throughout
- Add a Future Directions chapter to shape responsible AI adoption across NFWS

---

## Chosen Approach: Two-Repository Split (Option B)

### Repository 1: `governance-core`

Owned and published by the central data team. Rendered to GitHub Pages. Publishes versioned releases (semver tags, e.g. `v3.0`) that team repos pin to. Content is entirely team-agnostic.

**Structure:**

```
governance-core/
  _quarto.yml
  index.qmd                    # Preface, how teams adopt the framework
  01-framework.qmd             # Roles, tiers, registers, monitoring (team-agnostic)
  02-central-data-team.qmd     # NEW: central team structure, embedding model, capability programme
  03-shared-datasets.qmd       # NEW: shared dataset stewardship, single-derivation model
  companions/
    r-governance.qmd           # Existing — de-F&W-ified
    python-governance.qmd      # Existing — de-F&W-ified
    hydrometric-data.qmd       # Existing — de-F&W-ified
    flood-models.qmd           # Existing — de-F&W-ified
    flood-warnings.qmd         # NEW — scope only
    procedure-tools.qmd        # NEW — scope only
  appendices/
    a-glossary.qmd
    b-document-hierarchy.qmd
    c-alignment-register.qmd
    d-upcoming-changes.qmd
    e-file-format-reference.qmd
    f-mcp-server-spec.qmd
  04-future-directions.qmd      # NEW: AI adoption roadmap, emerging capabilities
  governance-template.yml      # Template for tool repos
  scripts/build_tool_register.R
```

### Repository 2: `governance-<team>` (one per operational team)

A thin Quarto book owned by that team's Steward. Does not repeat core content — references it. Created from a starter template when a new team onboards.

**Structure:**

```
governance-<team>/
  _quarto.yml
  index.qmd        # Team context, core version pinned, central data liaison named
  roles.qmd        # Named Owner, Steward, Custodians for each asset category
  assets.qmd       # Team's tier assignments, register entries, deviations from core
  deviations.qmd   # Formal departures from core companion standards (rare, Owner-approved)
  registers/       # The team's actual register files
```

---

## Governance Hierarchy

```
NFWS Deputy Director (Owner)
│
├── Central Data Team (G7 Steward)
│     ├── Shared Asset Register (Gold-tier datasets used by multiple teams)
│     ├── Capability Programme (training, standards, tooling)
│     └── Embedded liaisons → one per operational team
│
├── FFM + LFS (shared G7 Steward) ──────── governance-ffm-lfs
├── Warning Team (G7 Steward) ───────────── governance-warnings
└── [further teams] ─────────────────────── governance-<team>

Out of scope:
  Flood Forecasting Centre (FFC, G7 Steward) — not covered by this framework
```

The NFWS Deputy Director is the Owner across all in-scope teams. The central data team G7 Steward reports to the DD and produces the quarterly governance summary covering shared dataset health and framework adoption across teams. Operational team Stewards (FFM/LFS shared G7, Warnings G7) report to the DD for their domain assets and coordinate with the central data team G7 on shared assets.

---

## Central Data Team Chapter (new: `02-central-data-team.qmd`)

### Structure

The central data team is headed by a G7 Steward accountable to the Deputy Director Owner. It is not embedded within any operational team — it sits above them and serves all of them.

### Shared Stewardship Model

- Datasets used by more than one operational team are declared once in the **Shared Asset Register**, owned by the central data team G7 Steward.
- Operational teams consuming a shared dataset are **Custodians** of that dataset, not Stewards. They do not derive their own copy or hold their own Gold-tier approval.
- When a shared dataset is updated or superseded, the central Steward notifies all consuming team Stewards. The existing cross-asset notification mechanism applies across team boundaries.

### Embedding and Capability Programme

- Each operational team has a named central data team **liaison** (any grade, Custodian-level). The liaison sits on team governance reviews, coordinates shared dataset needs, and supports framework onboarding.
- The capability programme covers: training (linked to the training framework companion), shared tooling (R and Python companions), and standards maintenance (the central team owns companion documents and publishes updates via core releases).

---

## Companion Documents

### Existing companions — changes required

All four existing companions (R, Python, Hydrometric Data, Flood Models) are moved into `governance-core/companions/` and made team-agnostic:

- Remove all team-specific language ("the F&W team", "Senior Modeller (G7)", etc.) — replace with generic terms ("the team's Steward", "the named G7 Steward")
- Replace all section-number cross-references ("Section 7.2", "Section 7.3") with proper `@sec-` Quarto labels pointing into `governance-core`
- Named role holders move out of companion docs entirely — they live in each team's `roles.qmd`

### New companions — scope only

**Flood Warnings (`flood-warnings.qmd`)**

*Scope:* Governs the assets that sit between model outputs and public-facing warning decisions: warning threshold configurations, trigger criteria, issuance records, and the tools that automate or support warning decisions. Covers tier classification for warning assets, version control of threshold configurations, run record requirements for warning-linked model outputs, and audit trail obligations. Out of scope: the models that produce the inputs (covered in `flood-models.qmd`) and the operational procedures for issuing warnings (covered in `procedure-tools.qmd`).

**Procedure Tools (`procedure-tools.qmd`)**

*Scope:* Governs operational procedure documentation and the tools that produce or display it: Standard Operating Procedures, decision trees, response playbooks, and associated tooling. Covers document ownership (Owner/Steward/Custodian model), version control for procedure documents, review cadences, and dependencies on Tier 3 code tools. Out of scope: the warning assets that procedures reference (covered in `flood-warnings.qmd`) and code tool governance (covered in `r-governance.qmd` and `python-governance.qmd`).

---

## Future Directions Chapter (new: `04-future-directions.qmd`)

This chapter sits in `governance-core` and is one of the primary motivations for the restructure. It is not a technical specification — it is a directional statement that gives NFWS a documented position on where the framework is heading and why. It serves two audiences: senior stakeholders who need to understand the strategic intent, and technical staff who need to know what is coming and how to prepare.

The chapter covers three areas:

**AI adoption roadmap.** Builds directly on the existing AI and ML governance section in the framework (which covers assessment before access and ML models in operational use). The future directions chapter looks forward: what classes of AI capability are the service likely to adopt over the next two to three years, what governance structures need to be in place before that is credible, and what the central data team's role is in evaluating and onboarding new AI tooling safely. This includes large language models used for procedure drafting or decision support, ML inference pipelines in the operational forecast chain, and automated data quality tools.

**Shared data as an enabler.** The shift to a central Shared Asset Register and single-derivation Gold datasets is not just a governance improvement — it is the precondition for meaningful AI work across teams. Models trained on inconsistently derived data, or on data whose provenance is unclear, cannot be trusted in operational settings. This section makes that argument explicitly, connecting the structural changes in this redesign to the AI ambition.

**Capability programme trajectory.** How the central data team's embedding and delivery model is expected to evolve as AI tooling matures: from individual tool assessments to shared evaluation frameworks, from team-level training to service-wide competency standards.

The chapter is deliberately forward-looking and does not create new governance obligations. Where future capabilities require new obligations, those will be introduced through companion document updates at the time.

---

## Onboarding a New Team

The process for adding a new team to the framework:

1. Create `governance-<team>` from the starter template repo
2. Pin to the current `governance-core` release version in `index.qmd`
3. Fill in named role holders (Owner, Steward, Custodians) in `roles.qmd`
4. Register existing Tier 3 assets in `assets.qmd`
5. Identify any shared datasets the team uses — notify the central data team Steward to add to the Shared Asset Register if not already present
6. Central data team assigns a named liaison; liaison is noted in `index.qmd`

No companion writing is required unless the team has a genuinely unique asset type not covered by any existing companion.

---

## What Is Not Changing

- The Owner / Steward / Custodian role definitions and grade requirements
- The three-tier system (Tier 3 Operational, Tier 2 Analytical, Tier 1 Experimental)
- The medallion architecture for hydrometric data (Bronze / Silver / Gold)
- The Tool Register and `build_tool_register.R` script
- The `governance.yml` template for tool repositories
- The versioning and change management process for the framework itself
- All appendices (Glossary, Document Hierarchy, Alignment Register, etc.)

---

## Out of Scope for This Redesign

- Writing the detailed content of the Flood Warnings and Procedure Tools companions (scope only for now)
- Populating the Shared Asset Register (operational work, not a document change)
- Creating team repos other than the initial `governance-ffm-lfs` and `governance-warnings` migrations
- Changes to the R or Python companion content beyond removing F&W-specific language

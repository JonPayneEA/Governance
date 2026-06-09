# Governance Restructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Humaniser requirement:** Every task that produces governance prose must have that prose passed through the `/humaniser` skill before committing. Register: formal voice-dna. This is not optional.

**Goal:** Restructure the single-team governance Quarto book into a departmental framework: a team-agnostic `governance-core` repo and thin per-team repos, with three new chapters (Central Data Team, Shared Datasets, Future Directions) and two companion stubs (Flood Warnings, Procedure Tools).

**Architecture:** The current repo becomes `governance-core`. Companion documents move into a `companions/` subdirectory. Three new chapters are written and added to `_quarto.yml`. Two per-team repos (`governance-forecasting`, `governance-warnings`) are created from a starter template with team-specific role and asset files only.

**Tech Stack:** Quarto 1.x, R (for `build_tool_register.R`), Git, GitHub Pages. All prose is written in Quarto Markdown (`.qmd`). No R code is executed during the build.

---

## File map

### Files modified in the current repo (becomes `governance-core`)

| File | Change |
|---|---|
| `_quarto.yml` | New title/subtitle, new chapters, companions moved to `companions/` subfolder |
| `index.qmd` | Updated preface: NFWS context, how teams adopt the framework, document suite table |
| `01-governance-framework.qmd` | Remove team-specific language; replace section-number cross-refs with `@sec-` labels |
| `03-r-code-governance.qmd` | Move to `companions/r-governance.qmd`; remove team-specific language; fix cross-refs |
| `04-python-code-governance.qmd` | Move to `companions/python-governance.qmd`; same treatment |
| `05-hydrometric-data.qmd` | Move to `companions/hydrometric-data.qmd`; same treatment |
| `06-flood-model-governance.qmd` | Move to `companions/flood-models.qmd`; same treatment |
| `07-training-framework.qmd` | Move to `companions/training-framework.qmd`; same treatment |
| `08-implementation.qmd` | Updated for NFWS context; references to new team structure |

### Files created in `governance-core`

| File | Purpose |
|---|---|
| `02-central-data-team.qmd` | The case for a CDT, proposed structure, shared stewardship, embedding model |
| `03-shared-datasets.qmd` | Shared dataset stewardship, single-derivation model, Shared Asset Register |
| `04-future-directions.qmd` | AI adoption roadmap, CDT capability trajectory, shared data as enabler |
| `companions/flood-warnings.qmd` | Scope-only stub for flood warning asset governance |
| `companions/procedure-tools.qmd` | Scope-only stub for procedure documentation governance |
| `governance-template/` | Starter template for new team repos (index, roles, assets, deviations) |

### Files created in new repos

| Repo | Files |
|---|---|
| `governance-forecasting` | `index.qmd`, `roles.qmd`, `assets.qmd`, `deviations.qmd`, `registers/` |
| `governance-warnings` | `index.qmd`, `roles.qmd`, `assets.qmd`, `deviations.qmd`, `registers/` |

---

## Phase 1: Restructure the current repo

### Task 1: Update `_quarto.yml` for the new structure

This is the spine of the book. Get this right first so subsequent tasks can verify renders correctly.

**Files:**
- Modify: `_quarto.yml`

- [ ] **Step 1: Open `_quarto.yml` and replace the chapters block**

Replace the existing `chapters:` and `appendices:` blocks with:

```yaml
book:
  title: "Data and Digital Asset Governance"
  subtitle: "National Forecasting and Warning Service"
  author: "Jonathan Payne"
  date: "2026"
  version: "3.0"
  chapters:
    - index.qmd
    - 01-governance-framework.qmd
    - 02-central-data-team.qmd
    - 03-shared-datasets.qmd
    - 04-future-directions.qmd
    - part: "Code companions"
      chapters:
        - companions/r-governance.qmd
        - companions/python-governance.qmd
    - part: "Data companions"
      chapters:
        - companions/hydrometric-data.qmd
    - part: "Model companions"
      chapters:
        - companions/flood-models.qmd
    - part: "Warning and procedure companions"
      chapters:
        - companions/flood-warnings.qmd
        - companions/procedure-tools.qmd
    - part: "Training and implementation"
      chapters:
        - companions/training-framework.qmd
        - 08-implementation.qmd
  appendices:
    - a-glossary.qmd
    - b-document-hierarchy.qmd
    - c-alignment-register.qmd
    - d-upcoming-changes.qmd
    - e-file-format-reference.qmd
    - f-mcp-server-spec.qmd
```

- [ ] **Step 2: Create the `companions/` directory and move files**

```bash
mkdir companions
mv 03-r-code-governance.qmd companions/r-governance.qmd
mv 04-python-code-governance.qmd companions/python-governance.qmd
mv 05-hydrometric-data.qmd companions/hydrometric-data.qmd
mv 06-flood-model-governance.qmd companions/flood-models.qmd
mv 07-training-framework.qmd companions/training-framework.qmd
```

- [ ] **Step 3: Create placeholder files for chapters that do not exist yet**

Create `02-central-data-team.qmd`:
```markdown
# Central Data Team {#sec-central-data-team}

*Content to be written in Task 5.*
```

Create `03-shared-datasets.qmd`:
```markdown
# Shared Datasets {#sec-shared-datasets}

*Content to be written in Task 6.*
```

Create `04-future-directions.qmd`:
```markdown
# Future Directions {#sec-future-directions}

*Content to be written in Task 7.*
```

Create `companions/flood-warnings.qmd`:
```markdown
# Flood Warning Asset Governance {#sec-flood-warnings}

*Content to be written in Task 8.*
```

Create `companions/procedure-tools.qmd`:
```markdown
# Procedure Tools Governance {#sec-procedure-tools}

*Content to be written in Task 8.*
```

- [ ] **Step 4: Verify the build**

```bash
quarto render
```

Expected: the book renders to `docs/` without errors. All chapters appear in the navigation. Cross-reference errors at this stage are expected (the moved files still reference old section numbers); note them but do not fix yet.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "restructure: move companions to companions/ and add placeholder chapters"
```

---

### Task 2: Fix section anchors and cross-references in `01-governance-framework.qmd`

The companion docs currently reference the parent framework by section number ("Section 7.2", "Section 7.3"). The parent needs proper `@sec-` anchors on every referenced section before the companions can be fixed.

**Files:**
- Modify: `01-governance-framework.qmd`

- [ ] **Step 1: Add `{#sec-}` anchors to all major sections that companion docs reference**

Find every heading in `01-governance-framework.qmd` that is referenced by name in the companion docs. The pattern to search for in companion docs:

```bash
grep -n "Section [0-9]" companions/*.qmd
```

Add anchors to the corresponding headings in `01-governance-framework.qmd`. Example:

```markdown
## Governance Roles {#sec-governance-roles}

### Owner (Deputy Director) {#sec-owner-role}

### Steward (Grade 7) {#sec-steward-role}

### Custodian (Any Grade) {#sec-custodian-role}

## The Tier System {#sec-tier-system}

## Asset Registers {#sec-asset-registers}

## Code and Tool Governance {#sec-code-tool-governance}

### Tool Classification {#sec-tool-classification}

### Custodianship Requirements by Tier {#sec-custodianship-by-tier}

### Routes to Tool Development {#sec-routes-to-development}

### Code Review Requirements {#sec-code-review-requirements}

### Version Control Principles {#sec-version-control}

### Tool Register {#sec-tool-register}

### Handover and Succession {#sec-handover-succession}
```

- [ ] **Step 2: Remove team-specific role names**

Search for hardcoded role names and replace:

```bash
grep -n "F&W\|Forecasting and Warning\|Senior Modeller\|Lead Developer\|Deputy Director (Modelling)\|Deputy Director (Data)\|Deputy Director (Technology)" 01-governance-framework.qmd
```

For each hit, replace with generic terms. Examples:

| Before | After |
|---|---|
| `F&W team` | `the team` |
| `Forecasting and Warning` | `NFWS` (where referring to the service) or `the team` (where referring to a generic team) |
| `Deputy Director (Modelling)` | `the Deputy Director` |
| `Senior Modeller (G7)` | `the named G7 Steward` |
| `Lead Developer (G7)` | `the named G7 Steward` |
| `Data Manager (G7)` | `the named G7 Steward` |

- [ ] **Step 3: Apply humaniser to any rewritten passages**

Any paragraph substantially rewritten in Step 2 must be passed through `/humaniser` (formal voice-dna register) before committing. Paste the paragraph, get the rewrite, replace in the file.

- [ ] **Step 4: Verify render**

```bash
quarto render 01-governance-framework.qmd
```

Expected: renders without errors. Check the output HTML in `docs/` to confirm section anchors appear correctly in the table of contents.

- [ ] **Step 5: Commit**

```bash
git add 01-governance-framework.qmd
git commit -m "refactor: add @sec- anchors and remove team-specific language from framework chapter"
```

---

### Task 3: Fix cross-references in companion docs

Now that `01-governance-framework.qmd` has proper `@sec-` labels, update the companions to use them.

**Files:**
- Modify: `companions/r-governance.qmd`, `companions/python-governance.qmd`, `companions/hydrometric-data.qmd`, `companions/flood-models.qmd`, `companions/training-framework.qmd`

- [ ] **Step 1: Find all section-number references across companion docs**

```bash
grep -n "Section [0-9]\|sec\. [0-9]" companions/*.qmd
```

Note every hit with its file and line number.

- [ ] **Step 2: Replace section-number references with `@sec-` labels**

For each hit, replace the bare section reference with the Quarto cross-reference form. Examples:

| Before | After |
|---|---|
| `Section 3` (roles) | `@sec-governance-roles` |
| `Section 5` (tiers) | `@sec-tier-system` |
| `Section 7.2` (custodianship) | `@sec-custodianship-by-tier` |
| `Section 7.3` (routes) | `@sec-routes-to-development` |
| `Section 7.4` (code review) | `@sec-code-review-requirements` |
| `Section 7.5` (version control) | `@sec-version-control` |
| `Section 7.6` (tool register) | `@sec-tool-register` |
| `Section 7.7` (handover) | `@sec-handover-succession` |
| `Section 12` (audit) | `@sec-monitoring-reporting` |

- [ ] **Step 3: Remove team-specific language from each companion**

Repeat the grep from Task 2, Step 2 across all companion files. Apply the same replacements. The companion docs must not name specific teams, individuals, or grade-role combinations that are F&W-specific. Named role holders move into the per-team repos (Tasks 10 and 11).

- [ ] **Step 4: Apply humaniser to rewritten passages**

Any passage substantially rewritten must go through `/humaniser` (formal voice-dna) before committing.

- [ ] **Step 5: Verify full render**

```bash
quarto render
```

Expected: no unresolved cross-reference warnings. Check the Quarto output log for `WARNING: undefined cross-reference`. All should resolve.

- [ ] **Step 6: Commit**

```bash
git add companions/
git commit -m "refactor: replace section-number cross-refs with @sec- labels across all companions"
```

---

### Task 4: Update `index.qmd`

The preface currently describes a single F&W team document. It needs to describe a departmental framework that any NFWS team can adopt.

**Files:**
- Modify: `index.qmd`

- [ ] **Step 1: Rewrite the preface**

The preface should cover:
- What the framework is and who it is for (NFWS teams, not one team)
- How a new team adopts it (create a thin team repo, inherit companions, fill in roles and assets)
- The document suite table (update versions and add new chapters)

Draft:

```markdown
---
title: "Preface"
---

## National Forecasting and Warning Service: Data and Digital Asset Governance

The NFWS operates a complex set of flood models, data pipelines, code tools,
and warning systems across multiple teams. This framework governs how those
assets are built, owned, and handed over, regardless of which team holds them.

The framework is structured in two layers. This book (`governance-core`)
defines the standards that apply across NFWS: roles, tiers, quality thresholds,
and companion standards for each asset type. Individual teams hold their own
thin governance repo (`governance-<team>`) which names role holders, records
team assets, and documents any formal departures from core standards.

A team adopting this framework for the first time should:

1. Create a `governance-<team>` repo from the starter template.
2. Pin to the current `governance-core` release in `index.qmd`.
3. Fill in named role holders in `roles.qmd`.
4. Register Tier 3 assets in `assets.qmd`.
5. Identify shared datasets and notify the central data team Steward.
6. Note the assigned central data team liaison in `index.qmd`.

## Document suite

| Document | Version | Status |
|---|---|---|
| Data and Digital Asset Governance Framework | 3.0 | Draft |
| Central Data Team | 1.0 | Draft |
| Shared Datasets | 1.0 | Draft |
| Future Directions | 1.0 | Draft |
| R Tool Governance | 2.0 | Draft |
| Python Tool Governance | 2.0 | Draft |
| Hydrometric Data Framework | 2.0 | Draft |
| Flood Model Governance | 2.0 | Draft |
| Flood Warning Asset Governance | 1.0 | Scope only |
| Procedure Tools Governance | 1.0 | Scope only |
| Training Framework | 2.0 | Draft |
: Document suite overview {.striped}
```

- [ ] **Step 2: Apply humaniser**

Pass the full rewritten `index.qmd` body through `/humaniser` (formal voice-dna register). Replace with the humanised output.

- [ ] **Step 3: Verify render**

```bash
quarto render index.qmd
```

Expected: renders cleanly. Document suite table displays correctly.

- [ ] **Step 4: Commit**

```bash
git add index.qmd
git commit -m "refactor: rewrite preface for NFWS departmental framework context"
```

---

## Phase 2: Write new chapters

### Task 5: Write `02-central-data-team.qmd`

This chapter makes the structural case for a CDT and defines what it would do. It does not announce that the CDT exists. It presents a coherent argument that the Deputy Director can act on.

**Files:**
- Modify: `02-central-data-team.qmd`

- [ ] **Step 1: Write the chapter draft**

Structure:

```markdown
# Central Data Team {#sec-central-data-team}

::: {.callout-note}
| | |
|---|---|
| **Version** | 1.0 |
| **Status** | Draft: For Review |
| **Review Date** | 2027-03-31 |
| **Parent Document** | Data and Digital Asset Governance Framework v3.0 |
:::

## The gap this framework cannot close

[Paragraph: the governance problems in this document -- duplicated datasets,
fragmented ownership, no shared AI assessment process -- all point to the same
structural gap. No team has a cross-cutting mandate for data and digital
capability across NFWS. Service Management holds the standards and vision brief
but not the technical depth. Individual operational teams hold technical depth
but not the cross-team view. Neither can fill the other's gap.]

## What a Central Data Team would do {#sec-cdt-role}

### Shared dataset stewardship {#sec-cdt-stewardship}

[Paragraph: datasets used by more than one team are currently derived
independently. The CDT would hold Steward responsibility for those datasets via
the Shared Asset Register (@sec-shared-datasets). Operational teams consuming
a shared dataset are Custodians of it, not Stewards. They do not derive their
own copy.]

### Capability programme {#sec-cdt-capability}

[Paragraph: training (linked to @sec-training-framework), shared tooling
(R and Python companions), and standards maintenance. The CDT owns the
companion documents and publishes updates via core releases.]

### Embedding model {#sec-cdt-embedding}

[Paragraph: each operational team has a named CDT liaison. The liaison sits on
team governance reviews, coordinates shared dataset proposals, and supports
framework onboarding for new teams.]

## Proposed structure {#sec-cdt-structure}

[Paragraph: the CDT would be headed by a G7 Steward accountable to the Deputy
Director. It does not sit within any operational team. The G7 Steward produces
the quarterly governance summary (@sec-monitoring-reporting) covering shared
dataset health and framework adoption across all in-scope teams.]

## Reporting line {#sec-cdt-reporting}

[Diagram or table: DD at top, CDT G7 Steward below, Forecasting G7 and
Warnings G7 alongside as peers, all reporting to DD. CDT liaises horizontally
with operational teams.]

## How this framework supports the case

[Paragraph: this framework is designed so that when the CDT is established, it
steps into a defined role. The Shared Asset Register format is specified in
@sec-shared-datasets. The quarterly reporting cadence is defined in
@sec-monitoring-reporting. The companion ownership model is described in
@sec-companion-ownership. The CDT does not need to invent any of this. It
needs to be resourced to do it.]
```

- [ ] **Step 2: Apply humaniser**

Pass the full drafted prose through `/humaniser` (formal voice-dna register). This chapter makes an organisational argument to a senior audience. Every sentence must earn its place. Replace with humanised output.

- [ ] **Step 3: Verify render**

```bash
quarto render 02-central-data-team.qmd
```

Expected: renders cleanly, all `@sec-` cross-references resolve.

- [ ] **Step 4: Commit**

```bash
git add 02-central-data-team.qmd
git commit -m "feat: add central data team chapter with CDT case and proposed structure"
```

---

### Task 6: Write `03-shared-datasets.qmd`

This chapter defines the single-derivation model for datasets used by more than one team.

**Files:**
- Modify: `03-shared-datasets.qmd`

- [ ] **Step 1: Write the chapter draft**

Structure:

```markdown
# Shared Datasets {#sec-shared-datasets}

::: {.callout-note}
| | |
|---|---|
| **Version** | 1.0 |
| **Status** | Draft: For Review |
| **Review Date** | 2027-03-31 |
| **Parent Document** | Data and Digital Asset Governance Framework v3.0 |
:::

## The problem with independent derivation

[Paragraph: when multiple teams each derive their own version of the same
dataset, three things happen. Provenance trails diverge. QC decisions
diverge. Gold-tier approvals multiply. The result is datasets that look the
same but are not, and no single person who can vouch for any of them.]

## What a shared dataset is {#sec-shared-dataset-definition}

[Definition: a dataset is shared if more than one in-scope NFWS team uses it
as an input to their Tier 3 assets. Examples: gauge metadata, catchment
shapefiles, nationally consistent hydrometric baselines.]

## The Shared Asset Register {#sec-shared-asset-register}

[Paragraph: shared datasets are declared once in the Shared Asset Register,
held in governance-core. Each entry records: dataset name, derivation method,
Gold-tier approval record, CDT Steward, consuming teams and their Custodian
contacts, last review date.]

[Table: Shared Asset Register fields with descriptions.]

## Roles for shared datasets {#sec-shared-dataset-roles}

| Role | Holder | Responsibility |
|---|---|---|
| Owner | Deputy Director | Approves Gold-tier shared datasets. Approves retirement of a shared dataset. |
| Steward | CDT G7 Steward | Maintains the Shared Asset Register. Holds the Gold-tier derivation record. Notifies consuming teams of updates. |
| Custodian | Named contact in each consuming team | Uses the dataset as supplied. Does not derive an independent copy. Reports quality issues to the CDT Steward. |

## Notification requirements {#sec-shared-dataset-notification}

[Paragraph: when a shared dataset is updated or superseded, the CDT Steward
notifies all consuming team Stewards before the change takes effect. The
notified Steward confirms with their Custodians that any dependent model
configurations or tool outputs remain valid. This mirrors the cross-asset
notification requirement in @sec-asset-registers, extended across team
boundaries.]

## Proposing a new shared dataset {#sec-proposing-shared-dataset}

[Paragraph: any team Steward may propose that a dataset be moved to shared
status. The proposal goes to the CDT G7 Steward with a brief statement of
which teams use it and why independent derivation is a risk. The CDT Steward
assesses and, if agreed, takes on Steward responsibility and adds the entry
to the Shared Asset Register. Owner approval is required before the first
Gold-tier record is created.]
```

- [ ] **Step 2: Apply humaniser**

Pass the full chapter prose through `/humaniser` (formal voice-dna). Replace with humanised output.

- [ ] **Step 3: Verify render**

```bash
quarto render 03-shared-datasets.qmd
```

Expected: renders cleanly.

- [ ] **Step 4: Commit**

```bash
git add 03-shared-datasets.qmd
git commit -m "feat: add shared datasets chapter with single-derivation model and Shared Asset Register"
```

---

### Task 7: Write `04-future-directions.qmd`

This chapter is a directional statement, not a governance obligation document. It speaks to a mixed audience: senior stakeholders who need the strategic intent, and technical staff who need to know what is coming.

**Files:**
- Modify: `04-future-directions.qmd`

- [ ] **Step 1: Write the chapter draft**

Structure:

```markdown
# Future Directions {#sec-future-directions}

::: {.callout-note}
| | |
|---|---|
| **Version** | 1.0 |
| **Status** | Draft: For Review |
| **Review Date** | 2027-03-31 |
| **Parent Document** | Data and Digital Asset Governance Framework v3.0 |
:::

## Purpose of this chapter

[Short paragraph: this chapter does not create governance obligations. Where
future capabilities require new obligations, those will come through companion
document updates. This chapter records the direction of travel so that
decisions made now are consistent with where the service is heading.]

## Why shared data comes first {#sec-future-data-first}

[Paragraph: ML models trained on inconsistently derived data cannot be trusted
in operational settings. AI tooling that accesses data with unclear provenance
cannot be assessed for risk. The single-derivation model in @sec-shared-datasets
and the Gold-tier approval process in @sec-hydrometric-data are not just
governance improvements. They are the precondition for credible AI adoption
across NFWS.]

[Paragraph: this is not a new argument. The existing framework already requires
that ML models in operational use draw from Gold-tier training datasets
(@sec-ai-governance). What changes here is that the same requirement now
applies across teams, not just within one team. A model trained by the
Forecasting Team and a model trained by the Warning Team must draw from the
same approved datasets if their outputs are to be compared or combined.]

## AI adoption roadmap {#sec-ai-roadmap}

### Near term (one to two years)

[Paragraph: the most immediate AI applications within NFWS are assistive, not
autonomous: large language models used for procedure drafting, decision support
tools that surface relevant historical events during an incident, automated
data quality flagging in the Bronze-to-Silver pipeline. Each of these already
sits within the existing governance framework. The CDT's role in the near term
is evaluation: assessing candidate tools against the criteria in
@sec-ai-governance before any team adopts them in a shared or production
context.]

### Medium term (two to four years)

[Paragraph: ML inference pipelines in the operational forecast chain. These are
already Tier 3 assets under the existing framework if their outputs feed Tier 3
model runs. The additional requirement at the NFWS level is that training
datasets are drawn from the Shared Asset Register, that model artefacts are
version-controlled under CDT oversight, and that condition assessments are
coordinated across teams where the same model type is used by more than one
team.]

### Long term

[Paragraph: service-wide competency standards for AI tool assessment, shared
evaluation frameworks that teams can apply without CDT involvement for low-risk
tooling, and a published register of approved AI tools alongside the existing
tool and model registers. The CDT moves from evaluating each tool individually
to maintaining a framework that teams can operate within independently.]

## CDT capability programme trajectory {#sec-cdt-trajectory}

[Paragraph: the capability programme begins narrow and expands as the CDT
establishes itself. In the first year, the focus is register currency,
shared dataset consolidation, and supporting the Forecasting and Warning teams
through initial adoption. AI tool assessment is added once the shared data
foundation is in place. By year three, the programme covers training delivery,
cross-team standards maintenance, and the published AI tool register.]
```

- [ ] **Step 2: Apply humaniser**

Pass the full chapter through `/humaniser` (formal voice-dna). This chapter needs to read as a considered argument, not a checklist. Replace with humanised output.

- [ ] **Step 3: Verify render**

```bash
quarto render 04-future-directions.qmd
```

Expected: renders cleanly, all cross-references resolve.

- [ ] **Step 4: Commit**

```bash
git add 04-future-directions.qmd
git commit -m "feat: add future directions chapter covering AI roadmap and CDT capability trajectory"
```

---

### Task 8: Write companion stubs for Flood Warnings and Procedure Tools

These chapters define scope only. They are placeholders for content that subject matter experts will write. The headings signal what needs filling; the scope statements prevent scope creep when that content is written.

**Files:**
- Modify: `companions/flood-warnings.qmd`, `companions/procedure-tools.qmd`

- [ ] **Step 1: Write `companions/flood-warnings.qmd`**

```markdown
# Flood Warning Asset Governance {#sec-flood-warnings}

::: {.callout-note}
| | |
|---|---|
| **Version** | 1.0 |
| **Status** | Scope defined: awaiting content |
| **Review Date** | 2027-03-31 |
| **Parent Document** | Data and Digital Asset Governance Framework v3.0 |
:::

## Purpose and scope

This companion governs the assets that sit between model outputs and
public-facing warning decisions: warning threshold configurations, trigger
criteria, issuance records, and the tools that automate or support warning
decisions.

**In scope:**

- Tier classification for warning assets
- Version control requirements for threshold configurations
- Run record requirements for warning-linked model outputs
- Audit trail obligations for warning decisions

**Out of scope:**

- The models that produce forecast inputs (see @sec-flood-model-governance)
- Operational warning procedures (see @sec-procedure-tools)
- Impact information and result threshold methodology (covered by the Warning
  Team's own documentation)

## Sections to be completed

The following sections are to be drafted by the Warning Team G7 Steward or
a nominated subject matter expert, reviewed by the CDT G7 Steward, and
approved by the Deputy Director before the companion moves to Draft status.

### Warning asset classification

*To be written.*

### Threshold configuration version control

*To be written.*

### Run record requirements

*To be written.*

### Audit trail obligations

*To be written.*
```

- [ ] **Step 2: Write `companions/procedure-tools.qmd`**

```markdown
# Procedure Tools Governance {#sec-procedure-tools}

::: {.callout-note}
| | |
|---|---|
| **Version** | 1.0 |
| **Status** | Scope defined: awaiting content |
| **Review Date** | 2027-03-31 |
| **Parent Document** | Data and Digital Asset Governance Framework v3.0 |
:::

## Purpose and scope

This companion governs operational procedure documentation and the tools that
produce or display it: Standard Operating Procedures, decision trees, response
playbooks, and associated tooling.

**In scope:**

- Document ownership using the Owner / Steward / Custodian model
- Version control requirements for procedure documents
- Review cadences for procedure documentation
- Dependencies between procedure tools and the Tier 3 code tools they rely on

**Out of scope:**

- The warning assets that procedures reference (see @sec-flood-warnings)
- Code tool governance for the tools that produce procedure documents
  (see @sec-r-governance and @sec-python-governance)

## Sections to be completed

The following sections are to be drafted by the relevant G7 Steward or a
nominated subject matter expert, reviewed by the CDT G7 Steward, and approved
by the Deputy Director before the companion moves to Draft status.

### Procedure document classification

*To be written.*

### Version control and review cadence

*To be written.*

### Dependency management with Tier 3 tools

*To be written.*
```

- [ ] **Step 3: Apply humaniser to the scope and purpose sections**

Pass the "Purpose and scope" prose in each file through `/humaniser` (formal voice-dna). Section headings marked "To be written" are not prose and do not need humanising. Replace the purpose/scope paragraphs with humanised output.

- [ ] **Step 4: Verify render**

```bash
quarto render
```

Expected: full book renders. Both new stubs appear in the navigation under "Warning and procedure companions". No cross-reference errors.

- [ ] **Step 5: Commit**

```bash
git add companions/flood-warnings.qmd companions/procedure-tools.qmd
git commit -m "feat: add scope-only stubs for flood warnings and procedure tools companions"
```

---

## Phase 3: Create team repos

### Task 9: Create the team repo starter template

This template is used whenever a new team onboards. It lives in `governance-core` as a reference and is copied to create each new team repo.

**Files:**
- Create: `governance-template/index.qmd`, `governance-template/roles.qmd`, `governance-template/assets.qmd`, `governance-template/deviations.qmd`, `governance-template/_quarto.yml`

- [ ] **Step 1: Create `governance-template/_quarto.yml`**

```yaml
project:
  type: book
  output-dir: docs

book:
  title: "[Team Name] Governance"
  subtitle: "National Forecasting and Warning Service"
  author: "[Steward Name]"
  date: "[Date]"
  chapters:
    - index.qmd
    - roles.qmd
    - assets.qmd
    - deviations.qmd

format:
  html:
    theme:
      light: [cosmo, ../water-theme.scss]
    toc: true
    number-sections: true
```

- [ ] **Step 2: Create `governance-template/index.qmd`**

```markdown
---
title: "About this document"
---

## [Team name] governance

This document records [team name]'s adoption of the NFWS governance framework.
It does not restate core standards. Those are defined in `governance-core`
and inherited by this team.

| | |
|---|---|
| **Core version pinned** | governance-core v3.0 |
| **Team Steward** | [Name, grade] |
| **CDT liaison** | [Name] |
| **Last reviewed** | [Date] |
```

- [ ] **Step 3: Create `governance-template/roles.qmd`**

```markdown
---
title: "Roles"
---

# Named role holders {#sec-roles}

## Owner

| | |
|---|---|
| **Name** | [Deputy Director name] |
| **Grade** | Deputy Director |
| **Domain** | [Domain covered] |

## Steward

| | |
|---|---|
| **Name** | [G7 Steward name] |
| **Grade** | G7 |
| **Delegated Steward** | [Name, if applicable] |

## Custodians

| Asset | Custodian | Grade |
|---|---|---|
| [Asset name] | [Name] | [Grade] |

## CDT liaison

| | |
|---|---|
| **Name** | [CDT liaison name] |
| **Contact** | [Email] |
```

- [ ] **Step 4: Create `governance-template/assets.qmd`**

```markdown
---
title: "Assets"
---

# Team asset register {#sec-assets}

## Tier 3 assets

List all assets this team owns at Tier 3. For each asset, record its entry
in the relevant central register (Tool Register, Model Register, or Shared
Asset Register) and note any team-specific configuration.

| Asset | Type | Register entry | Custodian |
|---|---|---|---|
| [Name] | [Tool / Model / Dataset] | [Register location] | [Name] |

## Shared dataset consumption

List all shared datasets this team uses. These are governed by the CDT
Steward. The team's role is Custodian only.

| Dataset | Shared Asset Register entry | Team Custodian contact |
|---|---|---|
| [Name] | [Entry reference] | [Name] |
```

- [ ] **Step 5: Create `governance-template/deviations.qmd`**

```markdown
---
title: "Deviations"
---

# Formal deviations from core standards {#sec-deviations}

This section records any formal departures from the companion standards in
`governance-core`. Deviations require Owner approval and must be recorded
here with the date approved and the rationale.

If this section is empty, the team operates fully to core standards.

| Companion | Section | Deviation | Rationale | Approved by | Date |
|---|---|---|---|---|---|
```

- [ ] **Step 6: Commit**

```bash
git add governance-template/
git commit -m "feat: add team repo starter template"
```

---

### Task 10: Create `governance-forecasting` repo content

**Note:** This task creates the content for the Forecasting Team's governance repo. The repo itself is created on GitHub as a new repository; the files below are its initial content.

**Files:**
- Create: all files in a new `governance-forecasting/` repo

- [ ] **Step 1: Copy the template**

```bash
cp -r governance-template governance-forecasting
```

- [ ] **Step 2: Fill in `governance-forecasting/index.qmd`**

Replace the placeholders:

```markdown
---
title: "About this document"
---

## Forecasting Team governance

This document records the Forecasting Team's adoption of the NFWS governance
framework. It covers the 3 Local Forecasting Teams, the Coastal Modelling
Team, the 2 Fluvial Modelling Teams, and the Senior Technical Advisor.

Core standards are defined in `governance-core` v3.0 and inherited by this
team without modification unless noted in the deviations register.

| | |
|---|---|
| **Core version pinned** | governance-core v3.0 |
| **Team Steward** | [Forecasting Manager name], G7 |
| **CDT liaison** | [To be assigned] |
| **Last reviewed** | 2026-06-09 |
```

- [ ] **Step 3: Fill in `governance-forecasting/roles.qmd`**

Populate with the Forecasting Team's named role holders for each asset category (models, data, tools). Leave CDT liaison as "[To be assigned]" until the CDT is established.

- [ ] **Step 4: Fill in `governance-forecasting/assets.qmd`**

Register all Tier 3 assets the Forecasting Team holds: flood models, operational R and Python tools, and any hydrometric datasets for which the team holds Custodian responsibility. Cross-reference the central Tool Register and Model Register entries.

- [ ] **Step 5: Apply humaniser to any new prose**

Pass any new narrative paragraphs in index.qmd through `/humaniser` (formal voice-dna). Tables and register entries do not need humanising.

- [ ] **Step 6: Verify render**

From inside `governance-forecasting/`:
```bash
quarto render
```

Expected: renders cleanly as a standalone book.

- [ ] **Step 7: Commit**

```bash
git add governance-forecasting/
git commit -m "feat: add initial governance-forecasting team repo content"
```

---

### Task 11: Create `governance-warnings` repo content

Same process as Task 10, for the Warning Team.

**Files:**
- Create: all files in a new `governance-warnings/` repo

- [ ] **Step 1: Copy the template**

```bash
cp -r governance-template governance-warnings
```

- [ ] **Step 2: Fill in `governance-warnings/index.qmd`**

```markdown
---
title: "About this document"
---

## Warning Team governance

This document records the Warning Team's adoption of the NFWS governance
framework. It covers the 3 Warning Hub Teams.

Core standards are defined in `governance-core` v3.0 and inherited by this
team without modification unless noted in the deviations register.

| | |
|---|---|
| **Core version pinned** | governance-core v3.0 |
| **Team Steward** | [Warning Manager name], G7 |
| **CDT liaison** | [To be assigned] |
| **Last reviewed** | 2026-06-09 |
```

- [ ] **Step 3: Fill in `governance-warnings/roles.qmd`**

Populate with the Warning Team's named role holders. The Warning Team's assets likely span warning threshold configurations, issuance tooling, and any datasets the team holds or consumes.

- [ ] **Step 4: Fill in `governance-warnings/assets.qmd`**

Register Tier 3 warning assets. Note that the detailed companion for these assets (`companions/flood-warnings.qmd`) is currently scope-only; governance of these assets defaults to the core framework until the companion is complete.

- [ ] **Step 5: Apply humaniser to any new prose**

Pass narrative paragraphs through `/humaniser` (formal voice-dna).

- [ ] **Step 6: Verify render**

```bash
quarto render
```

- [ ] **Step 7: Commit**

```bash
git add governance-warnings/
git commit -m "feat: add initial governance-warnings team repo content"
```

---

## Phase 4: Final verification and release

### Task 12: Full build and cross-reference audit

- [ ] **Step 1: Full render of `governance-core`**

```bash
quarto render
```

Expected: zero warnings. Zero unresolved `@sec-` references. Check the Quarto log output carefully.

- [ ] **Step 2: Manual navigation check**

Open `docs/index.html` in a browser. Verify:
- All chapters appear in the left sidebar
- All companion documents appear under the correct part headings
- Clicking a cross-reference (e.g. `@sec-tier-system` in a companion doc) lands on the correct section in the framework chapter
- The flood-warnings and procedure-tools stubs appear and render with their "to be written" notices clearly visible

- [ ] **Step 3: Update `d-upcoming-changes.qmd`**

Add a changelog entry for v3.0:

```markdown
## v3.0 — 2026-06-09

**Major restructure.** The single-team governance book has been restructured
into a departmental framework.

Changes:
- Companion documents moved to `companions/` and made team-agnostic
- Three new chapters added: Central Data Team, Shared Datasets, Future Directions
- Two companion stubs added: Flood Warning Asset Governance, Procedure Tools Governance
- All section-number cross-references replaced with `@sec-` labels
- Per-team repos (`governance-forecasting`, `governance-warnings`) created
- Starter template for new team onboarding added at `governance-template/`
```

- [ ] **Step 4: Apply humaniser to changelog prose**

Pass the changelog entry through `/humaniser` (formal voice-dna).

- [ ] **Step 5: Final commit and tag**

```bash
git add -A
git commit -m "chore: v3.0 final build and changelog"
git tag v3.0
```

---

## Self-review notes

**Spec coverage check:**

| Spec requirement | Task |
|---|---|
| Two-repo split | Tasks 1, 9, 10, 11 |
| Central Data Team chapter | Task 5 |
| Shared Datasets chapter | Task 6 |
| Future Directions chapter | Task 7 |
| Flood Warnings stub | Task 8 |
| Procedure Tools stub | Task 8 |
| De-F&W-ify existing docs | Tasks 2, 3, 4 |
| Fix brittle cross-references | Tasks 2, 3 |
| Onboarding template | Task 9 |
| NFWS naming throughout | Tasks 2, 3, 4 |
| Humaniser applied to all prose | Each task (Steps marked explicitly) |

**Placeholder check:** All "To be written" markers in the stub companions are intentional scope declarations, not plan failures. They are labelled as such in the documents.

**Type consistency:** `@sec-` labels defined in Task 2 are used consistently in Tasks 3, 5, 6, 7, and 8. Any label used before it is defined will produce a Quarto warning caught in Task 12, Step 1.

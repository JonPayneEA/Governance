# F&W Governance MCP Server Specification

**Version 0.1 | Draft | March 2026**

## 1. Overview

This document specifies a Model Context Protocol (MCP) server that exposes the Forecasting & Warning team's governance registers, validation rules, and scaffolding utilities as tools. The server is designed to be consumed by AI coding assistants (Claude Code, Copilot, Cursor) and by CI pipelines, so that governance compliance is checked at the point of authoring rather than only at code review.

The server name is `fw-governance`.

### 1.1 Design Principles

- **Single server, many tools.** One MCP server covers all governance domains (code, data, models) to avoid tool fragmentation.
- **Registers as backend.** The Tool Register, Model Register, Hydrometric Data Register, Connection Register, and Data Catalogue are the source of truth. The server reads them; it does not duplicate them.
- **Rules as configuration.** Governance rules (header formats, naming patterns, schema definitions, tier requirements, prohibited packages) are encoded in a `governance-rules.toml` configuration file. When the framework is updated, the config file is updated — no server code changes needed.
- **Read-heavy, write-light.** Most tools are lookups and validations. The few write operations (scaffolding, register drafting) produce local files or draft entries that a human commits — the server never writes directly to registers.
- **Fail informative.** Every validation tool returns structured results with a pass/fail per check, the governance reference (document, section), and a plain-language explanation of what to fix.

### 1.2 Backend Data Sources

| Source | Format | Location |
|---|---|---|
| Tool Register | Excel or Delta table | `registers/tool_register.xlsx` or `fw_hydrometric.tool_register` |
| Model Register | Excel or Delta table | `registers/model_register.xlsx` |
| Hydrometric Data Register | Excel or Delta table | `registers/hydrometric_data_register.xlsx` or `fw_hydrometric` catalog |
| Connection Register | Excel or Delta table | `registers/connection_register.xlsx` |
| Data Catalogue | TOML or YAML | `governance/data_catalogue.toml` |
| Governance Rules | TOML | `governance/rules.toml` |

---

## 2. Tool Catalogue

Tools are grouped into five domains. Each tool definition includes: name, description, parameters, return schema, and the governance section it implements.

---

### Domain A — Register Lookups

These tools provide read access to the governance registers. They answer the question: *what does the governance framework say about this asset?*

#### `get_tool_info`

Look up a code tool in the Tool Register.

| Field | Detail |
|---|---|
| **Description** | Returns the full Tool Register entry for a named tool, including tier, owner, steward, custodian(s), status, repository location, and last review date. |
| **Governance ref** | Framework §8.6 |

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `tool_name` | string | yes | Tool name as it appears in the register (case-insensitive fuzzy match) |

**Returns:**

```json
{
  "tool_name": "ensemble_processor",
  "tier": 1,
  "language": "R",
  "owner": {"name": "Neil Ryan", "grade": "DD", "delegated": false},
  "steward": {"name": "Jane Smith", "grade": "G7", "delegated": false},
  "custodians": [{"name": "Tom Brown", "grade": "HEO"}],
  "repository": "https://github.com/fw-team/ensemble-processor",
  "status": "Active",
  "last_reviewed": "2025-11-15",
  "notes": "Annual audit due 2026-11",
  "tier_requirements": {
    "review": "Mandatory peer review + senior sign-off",
    "testing": "70% line coverage, testthat",
    "ci": "lintr, testthat, renv::status(), covr"
  }
}
```

---

#### `get_model_info`

Look up a flood model in the Model Register.

| Field | Detail |
|---|---|
| **Description** | Returns the Model Register entry including type, tier, condition rating, calibration reference, connected models, and custodian details. |
| **Governance ref** | Flood Model Governance §3 |

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `model_id` | string | yes | Model ID (e.g. `SEVERN_FMP_v3.2`) or partial match |

**Returns:**

```json
{
  "model_id": "SEVERN_FMP_v3.2",
  "model_type": "FMP 1D",
  "tier": 1,
  "owner": {"name": "Neil Ryan", "grade": "DD"},
  "steward": {"name": "Jane Smith", "grade": "G7"},
  "custodians": [{"name": "Tom Brown"}],
  "current_version": "3.2.0",
  "condition": {
    "score": 8,
    "rating": "Satisfactory",
    "assessed_date": "2025-09-20",
    "factors": {
      "data_currency": 2,
      "structural_integrity": 2,
      "calibration_currency": 1,
      "software_currency": 2,
      "documentation": 1
    }
  },
  "connected_models": ["SEVERN_PDM_v2.1", "SEVERN_LOWER_FMP_v1.4"],
  "status": "Active",
  "calibration_record": "docs/calibration/SEVERN_FMP_v3.2_cal.md"
}
```

---

#### `get_dataset_info`

Look up a hydrometric dataset in the Hydrometric Data Register.

| Field | Detail |
|---|---|
| **Description** | Returns the register entry for a Bronze, Silver, or Gold dataset, including provenance, QC status, lineage, and approval details. |
| **Governance ref** | Hydrometric Data §10 |

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `dataset_id` | string | yes | Full or partial dataset ID (e.g. `EA_39001_Q_20260115`) |
| `tier` | string | no | Filter by `Bronze`, `Silver`, or `Gold` |
| `site_id` | string | no | Filter by site identifier |

**Returns:**

```json
{
  "dataset_id": "EA_39001_Q_20260115_SILVER_v1",
  "tier": "Silver",
  "status": "Active",
  "bronze_source_id": "EA_39001_Q_20260115",
  "data_type": "Q",
  "site_id": "39001",
  "time_period": {"start": "2020-01-01", "end": "2025-12-31"},
  "temporal_resolution": "15min",
  "qc_summary": {
    "good": 98542, "estimated": 312, "suspect": 45,
    "rejected": 23, "no_data": 180, "below_detection": 0
  },
  "qc_completed_by": "Tom Brown",
  "qc_reviewed_by": "Jane Smith",
  "file_path": "silver/Q/39001/EA_39001_Q_20260115_SILVER_v1.parquet"
}
```

---

#### `get_connections`

Look up all upstream and downstream model connections for a given model.

| Field | Detail |
|---|---|
| **Description** | Returns all Connection Register entries where the specified model is either the upstream or downstream component. Used before deploying model changes to identify impact scope. |
| **Governance ref** | Flood Model Governance §5.2, §5.4 |

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `model_id` | string | yes | Model ID to query connections for |
| `direction` | string | no | `upstream`, `downstream`, or `both` (default: `both`) |

**Returns:** Array of connection entries with connection ID, upstream/downstream model, connection type, output/input variables, transfer method, manual override availability, and failure mode.

---

#### `lookup_definition`

Look up a term in the Data Catalogue.

| Field | Detail |
|---|---|
| **Description** | Returns the agreed team definition for a data term, entity, or attribute. Includes source, version, and any notes on conflicts with external definitions. |
| **Governance ref** | Framework §9.5 |

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `term` | string | yes | The term to look up (fuzzy matched) |

**Returns:**

```json
{
  "term": "BFI",
  "definition": "Base Flow Index. The proportion of river flow derived from groundwater or other slowly varying sources. Ranges from 0 to 1.",
  "source": "FEH / HOST classification",
  "source_version": "FEH Web Service v3",
  "used_in": ["Gold ML training sets", "Static catchment attributes"],
  "notes": "NRFA publishes BFI per gauge; team uses BFIHOST19 for ungauged catchments"
}
```

---

#### `get_governance_rule`

Look up a specific governance rule by topic.

| Field | Detail |
|---|---|
| **Description** | Returns the applicable governance rule for a given topic, including the requirement text, which tiers it applies to, the source document and section, and any exceptions. This is the tool a coding assistant calls when it needs to know "what are the rules for X?" |
| **Governance ref** | All documents |

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `topic` | string | yes | Natural language topic (e.g. `pandas usage`, `header block`, `code review tier 2`, `parquet schema bronze`, `commit message format`) |

**Returns:**

```json
{
  "topic": "pandas usage",
  "rule": "pandas must not be used in Tier 3 operational tools or in shared modules. It may be used freely in Tier 1 exploratory work and Jupyter notebooks.",
  "applies_to": {"tiers": [1, 2], "languages": ["Python"]},
  "source": "Python Tool Governance §2.2.3",
  "alternative": "polars (primary); pyarrow for Parquet I/O",
  "exceptions": "Tier 1 exploratory work and Jupyter notebooks"
}
```

---

### Domain B — Code Validation

These tools check source files against governance rules. They answer: *does this code comply?*

#### `validate_header`

Check whether a source file has a complete, correctly formatted header block.

| Field | Detail |
|---|---|
| **Description** | Parses the header block from a source file and checks each field against the mandatory header template for the relevant language. Returns pass/fail per field with an explanation of what is missing or malformed. |
| **Governance ref** | R Governance §2.4, Python Governance §2.3 |

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `file_path` | string | yes | Path to the source file |
| `language` | string | no | `R` or `Python` (auto-detected from extension if omitted) |

**Returns:**

```json
{
  "file": "src/ensemble_processor.R",
  "language": "R",
  "header_found": true,
  "fields": {
    "Tool": {"present": true, "value": "Ensemble Processor", "valid": true},
    "Description": {"present": true, "value": "Aggregates ensemble members", "valid": true},
    "Flode Module": {"present": false, "value": null, "valid": false, "fix": "Add '# Flode Module: [module or standalone]'"},
    "Author": {"present": true, "value": "Tom Brown, tom.brown@ea.gov.uk", "valid": true},
    "Created": {"present": true, "value": "2025-06-01", "valid": true},
    "Modified": {"present": false, "value": null, "valid": false, "fix": "Add '# Modified: YYYY-MM-DD - [initials]: [change summary]'"},
    "Tier": {"present": true, "value": "1", "valid": true},
    "Inputs": {"present": true, "value": "Parquet ensemble output", "valid": true},
    "Outputs": {"present": true, "value": "Aggregated forecast Parquet", "valid": true},
    "Dependencies": {"present": true, "value": "data.table, arrow", "valid": true}
  },
  "overall": "FAIL",
  "missing_count": 2
}
```

---

#### `check_tier_compliance`

Check whether a source file or project meets the governance requirements for its declared tier.

| Field | Detail |
|---|---|
| **Description** | Runs a comprehensive compliance check for a tool against its declared tier. Covers: header completeness, documentation requirements (README, docstrings/roxygen2, runbook), testing presence and coverage, dependency lockfile status, prohibited package usage, naming conventions, and type hints (Python). Returns a structured checklist mirroring the code review checklist. |
| **Governance ref** | R Governance §3.1, Python Governance §3.1, Framework §8.4 |

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `project_path` | string | yes | Path to the tool's root directory |
| `language` | string | no | `R` or `Python` (auto-detected) |
| `tier` | integer | no | 1, 2, or 3 (read from header if omitted) |

**Returns:**

```json
{
  "tool": "ensemble_processor",
  "language": "R",
  "tier": 1,
  "checks": {
    "header_block": {"status": "FAIL", "detail": "Missing Flode Module and Modified fields"},
    "readme": {"status": "PASS"},
    "roxygen2_docs": {"status": "WARN", "detail": "3 of 12 exported functions lack roxygen2 documentation"},
    "runbook": {"status": "FAIL", "detail": "No user guide or runbook found in docs/"},
    "tests_present": {"status": "PASS", "detail": "tests/testthat/ contains 8 test files"},
    "test_coverage": {"status": "FAIL", "detail": "62% line coverage (minimum 70% for Tier 3)", "value": 62},
    "lockfile": {"status": "PASS", "detail": "renv.lock present and committed"},
    "lockfile_sync": {"status": "PASS", "detail": "renv::status() reports no issues"},
    "prohibited_packages": {"status": "PASS", "detail": "No tidyverse/dplyr imports detected"},
    "naming_conventions": {"status": "WARN", "detail": "2 functions use camelCase instead of snake_case"},
    "hard_coded_paths": {"status": "PASS", "detail": "No absolute paths detected; here() used throughout"},
    "changelog": {"status": "PASS", "detail": "CHANGELOG.md present and has entries"}
  },
  "overall": "FAIL",
  "pass_count": 8,
  "fail_count": 3,
  "warn_count": 2,
  "blocking_failures": ["header_block", "runbook", "test_coverage"]
}
```

---

#### `validate_commit_message`

Check whether a commit message follows Conventional Commits.

| Field | Detail |
|---|---|
| **Description** | Validates a commit message against the team's Conventional Commits convention. Checks type is permitted (`feat`, `fix`, `docs`, `refactor`, `test`, `chore`), scope is present, description is present and not too long, and body explains *why* not just *what*. |
| **Governance ref** | Framework §8.5 |

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `message` | string | yes | The full commit message |

**Returns:**

```json
{
  "valid": false,
  "type": {"value": "update", "valid": false, "fix": "Use one of: feat, fix, docs, refactor, test, chore"},
  "scope": {"present": false, "fix": "Add scope in parentheses, e.g. feat(ensemble):"},
  "description": {"present": true, "value": "updated the threshold logic", "valid": true},
  "body": {"present": false, "fix": "Add a body explaining why this change was made"}
}
```

---

#### `validate_parquet_schema`

Check whether a Parquet file matches the required schema for its data tier.

| Field | Detail |
|---|---|
| **Description** | Reads the schema of a Parquet file and validates it against the mandatory column definitions for Bronze, Silver, or Gold tier as defined in the Hydrometric Data Framework. Checks column names, types, presence of mandatory columns, and absence of prohibited columns (e.g. extra columns in Bronze). |
| **Governance ref** | Hydrometric Data §7.2, §7.3, §7.4 |

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `file_path` | string | yes | Path to the Parquet file |
| `expected_tier` | string | yes | `Bronze`, `Silver`, `Gold_timeseries`, `Gold_aggregated`, or `Gold_ml_training` |

**Returns:**

```json
{
  "file": "bronze/EA/Q/2024/EA_39001_Q_20240101.parquet",
  "expected_tier": "Bronze",
  "row_count": 105120,
  "columns_found": ["timestamp", "value", "supplier_flag", "dataset_id", "site_id", "data_type", "notes"],
  "checks": {
    "mandatory_columns": {"status": "PASS", "detail": "All 6 mandatory columns present"},
    "column_types": {
      "status": "FAIL",
      "detail": "timestamp is string, expected timestamp[ns, UTC]",
      "violations": [{"column": "timestamp", "found": "string", "expected": "timestamp[ns, UTC]"}]
    },
    "prohibited_columns": {
      "status": "FAIL",
      "detail": "Column 'notes' is not in the Bronze schema. Bronze must contain only the listed columns.",
      "violations": ["notes"]
    }
  },
  "overall": "FAIL"
}
```

---

#### `validate_naming`

Check whether an identifier follows the team's naming convention for its asset type.

| Field | Detail |
|---|---|
| **Description** | Validates a dataset ID, model ID, file name, or tool name against the relevant naming convention. |
| **Governance ref** | Hydrometric Data Appendix A, Framework §6.2, Flood Model Governance §3 |

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `identifier` | string | yes | The name/ID to validate |
| `asset_type` | string | yes | One of: `bronze_dataset`, `silver_dataset`, `gold_dataset`, `model_id`, `fmp_file`, `pdm_parameter_set`, `tool_name` |

**Returns:**

```json
{
  "identifier": "EA_39001_Q_20260115",
  "asset_type": "bronze_dataset",
  "valid": true,
  "parsed": {
    "supplier": "EA",
    "site_id": "39001",
    "data_type": "Q",
    "date": "2026-01-15"
  },
  "pattern": "[SupplierCode]_[SiteID]_[DataType]_[YYYYMMDD]"
}
```

---

#### `pre_review`

Run the full code review checklist automatically, flagging items that need human judgement.

| Field | Detail |
|---|---|
| **Description** | Executes every mechanical check from the R or Python review checklist and returns a structured result that can be attached to a pull request. Items that require human judgement (e.g. "does the code do what it claims?") are returned as `NEEDS_HUMAN_REVIEW` with the checklist question text. |
| **Governance ref** | R Governance §3.1, Python Governance §3.1 |

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `project_path` | string | yes | Path to the tool's root directory |
| `language` | string | no | Auto-detected |
| `tier` | integer | no | Read from header if omitted |

**Returns:** A structured object with four sections (Correctness, Code Quality, Testing, Dependencies and Reproducibility), each containing an array of checklist items with `status` of `PASS`, `FAIL`, `WARN`, or `NEEDS_HUMAN_REVIEW`.

---

#### `check_file_formats`

Scan a directory for file format violations against the team's accepted format rules.

| Field | Detail |
|---|---|
| **Description** | Walks a project or data directory and checks every data file against the format rules in `governance-rules.toml`. Flags files that use prohibited formats (e.g. CSV in a pipeline directory, Excel outside a deliverables folder), files that use a discouraged format where a preferred one exists, and any format that is unexpected for the directory context. Returns pass/fail per file with the governance reference and a plain-language fix. Does not open file contents — checks extension and location only. For schema-level validation of Parquet files, use `validate_parquet_schema`. |
| **Governance ref** | File Format Reference (Appendix E); Hydrometric Data §7; R Governance §2.2.4; Python Governance §2.2.4 |

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Directory to scan (recursively) |
| `context` | string | no | One of: `pipeline`, `bronze`, `silver`, `gold`, `model`, `deliverables`, `any` (default: `any`). Determines which rules apply. |
| `tier` | integer | no | 1, 2, or 3. Stricter rules apply at Tier 3 (prohibited formats are hard failures; at Tier 1 they are warnings). |

**Returns:**

```json
{
  "path": "data/catchment_flows/",
  "context": "pipeline",
  "tier": 1,
  "files_scanned": 47,
  "violations": [
    {
      "file": "data/catchment_flows/processed/severn_q_2024.csv",
      "issue": "FAIL",
      "rule": "CSV is prohibited in pipeline directories at all tiers",
      "governance_ref": "File Format Reference §8.1; Hydrometric Data §7",
      "fix": "Convert to Parquet using polars.DataFrame.write_parquet() or arrow::write_parquet(). Retain the CSV only if it is a Bronze ingest of a supplier-delivered file."
    },
    {
      "file": "data/catchment_flows/interim/temp_output.xlsx",
      "issue": "FAIL",
      "rule": "Excel is prohibited in pipeline directories. Permitted only in deliverables/ for stakeholder outputs.",
      "governance_ref": "File Format Reference §9.2",
      "fix": "Write intermediate results as Parquet. If this is a stakeholder deliverable, move to deliverables/ and generate programmatically from a Parquet source."
    }
  ],
  "warnings": [
    {
      "file": "data/catchment_flows/archive/old_run_2022.feather",
      "issue": "WARN",
      "rule": "Feather is acceptable for high-speed intermediate files within a single pipeline but Parquet is preferred for archived outputs.",
      "governance_ref": "R Governance §2.2.4",
      "fix": "Consider converting to Parquet if this file is retained long-term or shared with Python tools."
    }
  ],
  "overall": "FAIL",
  "fail_count": 2,
  "warn_count": 1
}
```

---

### Domain C — Data Pipeline Validation

These tools check data assets against the medallion architecture rules.

#### `validate_bronze_ingestion`

Check whether a Bronze ingestion is ready to be stored.

| Field | Detail |
|---|---|
| **Description** | Given a raw file and a proposed dataset ID, validates that: the dataset ID follows naming conventions, the file can be read, mandatory Parquet columns are present and typed correctly, and a provenance record draft can be generated from available metadata. Does **not** write to the register. |
| **Governance ref** | Hydrometric Data §4.1, §4.2, §7.2 |

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `file_path` | string | yes | Path to the raw supplier file or converted Parquet |
| `dataset_id` | string | yes | Proposed Bronze dataset ID |
| `supplier` | string | yes | Supplier code (EA, NRFA, MO, etc.) |
| `data_type` | string | yes | Q, H, P, SM, or SWE |

**Returns:** Schema validation results plus a draft provenance record with fields pre-filled from the file metadata and parameters, and empty fields flagged for manual completion.

---

#### `check_silver_readiness`

Assess whether a Silver dataset meets promotion criteria.

| Field | Detail |
|---|---|
| **Description** | Reads a Silver-candidate Parquet file and checks: all Silver schema columns present and correctly typed, every row has a `qc_flag` value, `qc_value` is populated correctly relative to flags, `estimation_method` is populated for all flag=2 rows, and flag distribution is summarised. Returns a promotion readiness assessment. |
| **Governance ref** | Hydrometric Data §5, §7.3 |

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `file_path` | string | yes | Path to the Silver candidate Parquet file |
| `bronze_source_id` | string | yes | The Bronze dataset ID this was derived from |

**Returns:** Schema validation, flag distribution summary, gap-fill coverage, and a promotion checklist with pass/fail per requirement.

---

#### `check_gold_readiness`

Assess whether a Gold dataset meets approval criteria.

| Field | Detail |
|---|---|
| **Description** | Validates a Gold-candidate Parquet file against the appropriate Gold schema (timeseries, aggregated, or ML training set). For ML training sets, additionally checks that static catchment attributes are present, typed correctly, and repeated on every row. Returns an approval readiness assessment and a draft derivation record. |
| **Governance ref** | Hydrometric Data §6, §7.4 |

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `file_path` | string | yes | Path to the Gold candidate Parquet file |
| `gold_type` | string | yes | `timeseries`, `aggregated`, or `ml_training` |
| `silver_source_ids` | array[string] | yes | Silver dataset IDs used as input |
| `purpose` | string | yes | Intended use of this Gold product |

**Returns:** Schema validation, lineage check against Silver sources, and a draft derivation record template.

---

### Domain D — Scaffolding and Generation

These tools generate compliant skeletons and templates. They answer: *set me up correctly from the start.*

#### `scaffold_tool`

Generate a new tool project with correct structure, header, and configuration.

| Field | Detail |
|---|---|
| **Description** | Creates a directory structure, header-block template, README skeleton, test skeleton, and dependency management initialisation (renv or poetry) for a new tool at the specified tier. Also produces a draft Tool Register entry for manual review and commit. |
| **Governance ref** | R Governance §4.1, Python Governance §4.1, Framework §8.3, §8.6 |

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `name` | string | yes | Tool name (snake_case) |
| `language` | string | yes | `R` or `Python` |
| `tier` | integer | yes | 1, 2, or 3 |
| `author` | string | yes | Author name and email |
| `description` | string | yes | One-sentence description |
| `use_case` | string | no | Python only: `flood_modeller_api`, `ml`, `data_processing`, or `other` |
| `flode_module` | string | no | R only: target Flode module or `standalone` |
| `route` | string | no | Development route: `A`, `B`, `C`, or `D` (default: `A`) |

**Returns:** Object describing all files created, their paths, and the draft Tool Register entry.

**Example output structure (Python, Tier 2, ML):**

```
ml_flood_predictor/
├── src/
│   └── ml_flood_predictor/
│       ├── __init__.py
│       ├── train.py          # Header block pre-filled, training scaffold
│       └── infer.py          # Header block pre-filled, inference scaffold
├── tests/
│   └── test_ml_flood_predictor.py  # pytest skeleton
├── docs/
│   └── README.md             # Skeleton with purpose, tier, governance links
├── pyproject.toml            # poetry init with polars, pytest, ruff, mypy
└── .register_entry.json      # Draft Tool Register entry for Steward review
```

---

#### `generate_header`

Generate a correctly formatted header block for an existing file.

| Field | Detail |
|---|---|
| **Description** | Produces the mandatory header block for R or Python, pre-filled with the provided metadata. Returns the header as a string ready to paste at the top of a file. |
| **Governance ref** | R Governance §2.4, Python Governance §2.3 |

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `language` | string | yes | `R` or `Python` |
| `tool_name` | string | yes | Tool name |
| `description` | string | yes | One-sentence description |
| `author` | string | yes | Name and email |
| `tier` | integer | yes | 1, 2, or 3 |
| `inputs` | string | yes | Description of inputs |
| `outputs` | string | yes | Description of outputs |
| `dependencies` | string | yes | Non-standard package list |
| `use_case` | string | no | Python only |
| `flode_module` | string | no | R only |

**Returns:** The complete header block as a formatted string.

---

#### `generate_run_record`

Generate a pre-filled model run record template.

| Field | Detail |
|---|---|
| **Description** | Pulls the current model version, condition rating, and connection list from the Model Register and Connection Register, and produces a run record template with those fields pre-filled. The operator completes the remaining fields (input datasets, scenario, outputs, warnings). |
| **Governance ref** | Flood Model Governance §6 |

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `model_id` | string | yes | Model ID from the Model Register |
| `run_type` | string | yes | `operational`, `hindcast`, `scenario`, `calibration`, or `validation` |
| `run_by` | string | yes | Name of the person running the model |

**Returns:** A Markdown or YAML run record template with model metadata pre-filled.

---

#### `generate_review_checklist`

Generate the correct code review checklist for a language and tier.

| Field | Detail |
|---|---|
| **Description** | Returns the full review checklist appropriate for the specified language and tier, formatted as Markdown checkboxes ready to paste into a pull request description. |
| **Governance ref** | R Governance §3.1, Python Governance §3.1 |

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `language` | string | yes | `R` or `Python` |
| `tier` | integer | yes | 1, 2, or 3 |
| `is_ml` | boolean | no | Python only: includes ML-specific checklist items |

**Returns:** Markdown-formatted checklist string.

---

### Domain E — Governance Reporting

These tools support the Steward's monitoring and reporting obligations.

#### `governance_summary`

Generate a quarterly governance summary.

| Field | Detail |
|---|---|
| **Description** | Reads all registers and produces the quarterly summary required by the monitoring framework: asset counts by tier, tier changes in period, overdue reviews, open data quality issues, and any condition ratings below Satisfactory. |
| **Governance ref** | Framework §12.5 |

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `period_start` | string | no | ISO date (default: 3 months ago) |
| `period_end` | string | no | ISO date (default: today) |

**Returns:** Structured summary object covering all reporting categories.

---

#### `audit_tier1`

Run the annual Tier 3 audit checks across all registered Tier 3 assets.

| Field | Detail |
|---|---|
| **Description** | Iterates over all Tier 3 entries in the Tool Register and Model Register. For each tool, runs `check_tier_compliance`. For each model, checks condition rating currency and calibration record completeness. Returns a consolidated audit report. |
| **Governance ref** | Framework §12 |

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `asset_type` | string | no | `tools`, `models`, or `all` (default: `all`) |

**Returns:** Array of per-asset audit results with an overall summary.

---

## 3. Configuration Schema — `governance-rules.toml`

The rules file encodes the checkable governance requirements so they can be updated without changing server code.

```toml
[meta]
framework_version = "1.4"
last_updated = "2026-03-22"

[header.R]
fields = [
  "Tool", "Description", "Flode Module", "Author",
  "Created", "Modified", "Tier", "Inputs", "Outputs", "Dependencies"
]
date_format = "YYYY-MM-DD"

[header.Python]
fields = [
  "Tool", "Description", "Use Case", "Author",
  "Created", "Modified", "Tier", "Inputs", "Outputs", "Dependencies"
]
date_format = "YYYY-MM-DD"

[file_type_rules]
# Governance ref: File Format Reference (Appendix E)

# Formats required in each storage context
pipeline_data       = ["parquet"]       # Bronze, Silver, Gold, and all intermediate pipeline data
gridded_data        = ["nc", "zarr"]    # NetCDF required; Zarr requires Tech Lead agreement
spatial_internal    = ["parquet"]       # GeoParquet for all spatial data in internal workflows
model_fmp           = ["ief", "dat", "ied", "inp", "ini", "gxy", "zzn", "zzs"]
model_pdm           = []                # PDM files are vendor-defined; no extension restriction
ml_artefacts        = ["onnx", "json"]  # ONNX for archived models; JSON for metadata

# Formats restricted to specific contexts
[file_type_rules.restricted]
csv  = "deliverables, bronze_raw_ingest"   # Permitted only for small external exchange or supplier Bronze ingest
xlsx = "deliverables"                      # Permitted only for stakeholder deliverables
feather = "pipeline_intermediate"          # High-speed intermediate within a single R pipeline only
rds  = "pipeline_intermediate"             # R-specific intermediate objects only; not for shared outputs
pkl  = "never"                             # Never use pickle for shared or archived artefacts

# Formats prohibited everywhere
[file_type_rules.prohibited]
formats  = ["xls", "rdata", "RData"]
reason   = "Legacy formats with no permitted use case in team workflows"

# Severity by tier: violations are FAIL at Tier 3/2, WARN at Tier 1
[file_type_rules.severity]
tier1 = "FAIL"
tier2 = "FAIL"
tier3 = "WARN"

[naming_patterns]
bronze_dataset = '^\w+_\w+_[QHPSM]\w*_\d{8}$'
silver_dataset = '^\w+_\w+_[QHPSM]\w*_\d{8}_SILVER_v\d+$'
gold_dataset = '^\w+_[QHPSM]\w*_GOLD_\w+_v\d+$'
model_id = '^\w+_(FMP|PDM|BB)_v\d+\.\d+$'
fmp_file = '^\w+_\w+_\w+_v\d+\.\d+\.\d+_\d{8}$'
commit_message = '^(feat|fix|docs|refactor|test|chore)\(.+\): .+'
function_name_r = '^[a-z][a-z0-9_]*$'
function_name_python = '^[a-z][a-z0-9_]*$'
class_name_python = '^[A-Z][a-zA-Z0-9]*$'

[prohibited_packages]
R_tier1 = ["dplyr", "tidyr", "purrr", "readr", "stringr", "forcats", "tibble"]
R_tier2 = ["dplyr", "tidyr", "purrr", "readr", "stringr", "forcats", "tibble"]
Python_tier1 = ["pandas"]
Python_tier2 = ["pandas"]

[parquet_schemas.Bronze]
mandatory_columns = [
  {name = "timestamp",    type = "timestamp[ns, UTC]"},
  {name = "value",        type = "float64"},
  {name = "supplier_flag", type = "string"},
  {name = "dataset_id",   type = "string"},
  {name = "site_id",      type = "string"},
  {name = "data_type",    type = "string"},
]
optional_columns = ["raw_value_str", "uncertainty", "sensor_id"]
extra_columns_allowed = false

[parquet_schemas.Silver]
added_columns = [
  {name = "qc_flag",              type = "int32"},
  {name = "qc_value",             type = "float64"},
  {name = "estimation_method",    type = "string"},
  {name = "rating_curve_version", type = "string"},
  {name = "extrapolated",         type = "bool"},
  {name = "silver_dataset_id",    type = "string"},
  {name = "qc_version",           type = "int32"},
]

[parquet_schemas.Gold_ml_training]
added_columns = [
  {name = "training_set_id",      type = "string"},
  {name = "flag_exclusion_rule",  type = "string"},
  {name = "catchment_area_km2",   type = "float64"},
  {name = "bfi",                  type = "float64"},
  {name = "mean_elevation_m",     type = "float64"},
  {name = "dominant_soil_type",   type = "string"},
  {name = "land_cover_class",     type = "string"},
  {name = "gauge_easting",        type = "float64"},
  {name = "gauge_northing",       type = "float64"},
]

[testing]
tier1_min_coverage = 70
tier2_min_coverage = 0
tier3_min_coverage = 0

[review_requirements]
tier1 = "Mandatory peer review + senior sign-off before first production deployment"
tier2 = "Peer review required; reviewer must have intermediate proficiency"
tier3 = "Self-review checklist minimum; peer review encouraged"

[condition_rating]
good = [9, 10]
satisfactory = [7, 8]
requires_attention = [5, 6]
poor = [3, 4]
critical = [0, 2]
```

---

## 4. Implementation Notes

### 4.1 Transport

The server should support both `stdio` (for local Claude Code / editor integration) and `SSE` (for network access from Databricks notebooks or CI runners). Start with `stdio` for the Claude Code use case; add SSE when the Databricks integration is needed.

### 4.2 Technology

Python is the natural implementation language given the team's existing tooling. Key dependencies: `mcp` (the MCP Python SDK), `polars` (for Parquet schema inspection), `openpyxl` (for reading Excel registers), `tomllib` (for rules config), and `pathlib` throughout.

### 4.3 Register Access

The server reads registers at startup and caches them. A `refresh_registers` tool (not exposed externally) reloads from disk. For Delta table backends in Databricks, the server uses `deltalake` to read tables directly. The server never writes to registers — all write operations produce draft files that a human reviews and commits.

### 4.4 Authentication and Access Control

For `stdio` transport (local use), no authentication is needed — the user's filesystem permissions apply. For `SSE` transport, the server should sit behind the team's existing authentication. No governance data is classified above OFFICIAL, so standard network controls are sufficient.

### 4.5 Phased Delivery

| Phase | Tools | Value |
|---|---|---|
| 1 | `get_governance_rule`, `validate_header`, `generate_header`, `scaffold_tool`, `validate_naming`, `validate_commit_message`, `check_file_formats` | Immediate developer friction reduction; governance rules and format checks available at point of coding |
| 2 | `get_tool_info`, `get_model_info`, `get_dataset_info`, `check_tier_compliance`, `generate_review_checklist`, `generate_run_record` | Register integration; code review automation |
| 3 | `validate_parquet_schema`, `validate_bronze_ingestion`, `check_silver_readiness`, `check_gold_readiness`, `get_connections`, `pre_review` | Full data pipeline validation |
| 4 | `governance_summary`, `audit_tier1`, `lookup_definition` | Steward reporting and data catalogue integration |

`check_file_formats` is included in Phase 1 because it requires only `governance-rules.toml` (no register access) and provides immediate enforcement of the file format rules that were previously ungoverned. It is also the natural candidate for a pre-commit git hook, which can be wired up from day one independently of the full MCP server.

---

## 5. Example Interaction

A developer using Claude Code to write a new R tool:

```
Developer: Create a new Tier 2 R tool for calculating flood frequency statistics

Claude Code:
  → calls scaffold_tool(name="flood_freq_stats", language="R", tier=2,
      author="Tom Brown, tom.brown@ea.gov.uk",
      description="Calculates flood frequency statistics from Gold flow data",
      flode_module="reach.hydro", route="A")
  ← receives: directory structure created, header pre-filled, renv initialised,
     draft register entry at .register_entry.json

Developer: [writes the main function]

Claude Code:
  → calls check_tier_compliance(project_path="./flood_freq_stats", tier=2)
  ← receives: PASS on header, README, naming; WARN on roxygen2 coverage;
     FAIL on tests (none written yet)

Developer: [writes tests, prepares PR]

Claude Code:
  → calls generate_review_checklist(language="R", tier=2)
  ← receives: Markdown checklist pasted into PR description

  → calls pre_review(project_path="./flood_freq_stats")
  ← receives: 10 of 16 checks auto-passed, 2 auto-failed,
     4 marked NEEDS_HUMAN_REVIEW

Developer: [fixes the 2 failures, submits PR with checklist]
```

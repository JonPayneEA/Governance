#!/usr/bin/env Rscript
#
# scripts/build_tool_register.R
#
# Generates tool_register.csv by querying the JonPayneEA GitHub organisation
# and merging each repository's governance.yml with GitHub API metadata.
#
# Output: tool_register.csv in the project root.
#
# Usage:
#   Rscript scripts/build_tool_register.R
#
# Dependencies:
#   install.packages(c("gh", "yaml", "base64enc", "dplyr", "readr"))
#
# Authentication:
#   Public repositories work without a token but are rate-limited to 60
#   requests per hour. Set GITHUB_PAT (or GITHUB_TOKEN) to a personal access
#   token with `repo` scope to raise the limit and include private repos.
#   The gh package picks up either variable automatically.

suppressPackageStartupMessages({
  library(gh)
  library(yaml)
  library(base64enc)
  library(dplyr)
  library(readr)
})

ORG <- "JonPayneEA"
OUT <- "tool_register.csv"

# Null-coalescing: return `a` unless it is NULL, empty string, or length-0.
`%||%` <- function(a, b) {
  if (!is.null(a) && !identical(a, "") && length(a) > 0L) a else b
}

# Decode a base64 GitHub API content field (which contains embedded newlines)
# to a plain character string.
decode_github_content <- function(encoded) {
  rawToChar(base64decode(gsub("\\n", "", encoded)))
}

# Attempt to fetch and parse governance.yml from a repository.
# Returns a named list on success, NULL if the file is absent or malformed.
read_governance_yml <- function(owner, repo) {
  tryCatch({
    raw <- gh(
      "/repos/{owner}/{repo}/contents/{path}",
      owner = owner,
      repo  = repo,
      path  = "governance.yml"
    )
    yaml.load(decode_github_content(raw$content))
  }, error = function(e) NULL)
}

# Return the value portion of the first topic matching `prefix`, or NA.
# e.g. first_topic(c("tier-1", "active"), "tier-") -> "1"
first_topic <- function(topics, prefix) {
  hits <- topics[startsWith(topics, prefix)]
  if (length(hits) == 0L) return(NA_character_)
  sub(paste0("^", prefix), "", hits[[1L]])
}

# Map topics to a Status string using the canonical topic conventions.
topic_status <- function(topics) {
  if ("deprecated"        %in% topics) "Deprecated"        else
  if ("active"            %in% topics) "Active"             else
  if ("under-development" %in% topics) "Under Development"  else
  NULL
}

# Collapse a list of custodian entries to a semicolon-separated name string.
format_custodians <- function(custodians) {
  if (is.null(custodians) || length(custodians) == 0L) return(NA_character_)
  names <- vapply(custodians, function(x) x$name %||% "", character(1L))
  paste(names[nchar(names) > 0L], collapse = "; ")
}

# Build a single-row tibble for one repository.
repo_row <- function(r) {
  gov    <- read_governance_yml(ORG, r$name)
  topics <- r$topics %||% character(0L)

  tibble(
    tool_name         = r$name,
    tier              = as.character(gov$tier %||% first_topic(topics, "tier-")),
    language          = gov$language          %||% r$language      %||% NA_character_,
    status            = gov$status            %||% topic_status(topics) %||% NA_character_,
    owner_name        = gov$owner$name        %||% NA_character_,
    owner_grade       = gov$owner$grade       %||% NA_character_,
    steward_name      = gov$steward$name      %||% NA_character_,
    steward_delegated = gov$steward$delegated_to %||% NA_character_,
    custodians        = format_custodians(gov$custodians),
    iao               = gov$iao               %||% NA_character_,
    repository_url    = r$html_url,
    last_reviewed     = as.character(gov$last_reviewed %||% NA_character_),
    notes             = gov$notes             %||% r$description   %||% NA_character_
  )
}

# ---------------------------------------------------------------------------

message("Fetching repository list for ", ORG, " ...")
repos <- gh("/orgs/{org}/repos", org = ORG, .limit = Inf)
message(length(repos), " repositories found.")

message("Reading governance.yml from each repository ...")
rows <- lapply(repos, function(r) {
  tryCatch(repo_row(r), error = function(e) {
    warning("Failed to process repo '", r$name, "': ", conditionMessage(e))
    NULL
  })
})

register <- bind_rows(Filter(Negate(is.null), rows))

# Sort: Tier 1 first, then by name within each tier.
register <- register |>
  mutate(tier_sort = suppressWarnings(as.integer(tier))) |>
  arrange(tier_sort, tool_name) |>
  select(-tier_sort)

write_csv(register, OUT, na = "")
message(
  "Tool Register written to ", OUT,
  " (", nrow(register), " tools; ",
  sum(!is.na(register$tier)), " with tier assigned)"
)

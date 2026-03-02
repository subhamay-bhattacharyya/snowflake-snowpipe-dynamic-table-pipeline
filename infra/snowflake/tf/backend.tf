# -- infra/snowflake/tf/backend.tf
# ============================================================================
# Terraform Backend Configuration
# ============================================================================

terraform {
  cloud {

    organization = "subhamay-bhattacharyya-projects"

    workspaces {
      name = "snowflake-snowpipe-dynamic-table-pipeline"
    }
  }
}
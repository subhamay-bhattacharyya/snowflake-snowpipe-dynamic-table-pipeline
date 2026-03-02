# -- infra/snowflake/tf/main.tf
# ============================================================================
# Snowflake Resources - Warehouse, Database, Schema, Tables
# ============================================================================

# ----------------------------------------------------------------------------
# 1. Warehouses
# ----------------------------------------------------------------------------
module "warehouse" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-snowflake-warehouse?ref=main"

  providers = {
    snowflake = snowflake.warehouse_provisioner
  }

  warehouse_configs = local.warehouses
}

# ----------------------------------------------------------------------------
# 2. Databases and Schemas
# ----------------------------------------------------------------------------
module "database_schemas" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-snowflake-database-schema?ref=main"

  providers = {
    snowflake = snowflake.db_provisioner
  }

  database_configs = local.database_schemas
}

# ----------------------------------------------------------------------------
# 3. File Formats
# ----------------------------------------------------------------------------
module "file_formats" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-snowflake-file-format?ref=main"

  providers = {
    snowflake = snowflake.db_provisioner
  }

  file_format_configs = local.file_formats

  depends_on = [module.database_schemas]
}

# ----------------------------------------------------------------------------
# 4. Stages
# ----------------------------------------------------------------------------
module "stage" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-snowflake-stage?ref=main"

  providers = {
    snowflake = snowflake.db_provisioner
  }

  stage_configs = local.stages

  depends_on = [module.database_schemas]
}

# # ----------------------------------------------------------------------------
# # Tables
# # ----------------------------------------------------------------------------
module "table" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-snowflake-table?ref=main"

  providers = {
    snowflake = snowflake.db_provisioner
  }

  table_configs = local.tables

  depends_on = [module.database_schemas]
}

# # ----------------------------------------------------------------------------
# # Dynamic Tables
# # ----------------------------------------------------------------------------
# module "dynamic_table" {
#   source = "github.com/subhamay-bhattacharyya-tf/terraform-snowflake-dynamic-table?ref=main"

#   providers = {
#     snowflake = snowflake.db_provisioner
#   }

#   dynamic_table_configs = local.dynamic_tables

#   depends_on = [
#     module.database_schemas,
#     module.table,
#     module.warehouse,
#     module.seed
#   ]
# }

# # ----------------------------------------------------------------------------
# # Seed Data
# # ----------------------------------------------------------------------------
# module "seed" {
#   source = "github.com/subhamay-bhattacharyya-tf/terraform-snowflake-seed-data?ref=main"

#   for_each = var.enable_seed_data ? jsondecode(file("${path.module}/seed-data/seed.json")) : {}

#   providers = {
#     snowflake = snowflake.db_provisioner
#   }

#   seed = merge(each.value, {
#     script_path = "${path.module}/${each.value.script_path}"
#   })

#   depends_on = [module.table]
# }

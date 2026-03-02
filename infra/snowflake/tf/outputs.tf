# -- infra/snowflake/tf/outputs.tf
# ============================================================================
# Outputs
# ============================================================================

# ----------------------------------------------------------------------------
# Warehouses
# ----------------------------------------------------------------------------
output "warehouses" {
  description = "Map of warehouse names to their details"
  value = {
    for k, v in module.warehouse.warehouses : k => {
      name                      = v.name
      fully_qualified_name      = v.fully_qualified_name
      warehouse_size            = v.warehouse_size
      warehouse_type            = v.warehouse_type
      auto_suspend              = v.auto_suspend
      auto_resume               = v.auto_resume
      initially_suspended       = v.initially_suspended
      enable_query_acceleration = v.enable_query_acceleration
      min_cluster_count         = v.min_cluster_count
      max_cluster_count         = v.max_cluster_count
      scaling_policy            = v.scaling_policy
      comment                   = v.comment
    }
  }
}

# ----------------------------------------------------------------------------
# Databases and Schemas
# ----------------------------------------------------------------------------
output "database_schemas" {
  description = "Map of database names with their details"
  value = {
    for k, v in module.database_schemas.databases : k => {
      name                 = v.name
      fully_qualified_name = v.fully_qualified_name
      comment              = v.comment
    }
  }
}

output "schemas" {
  description = "Map of schema names to their details"
  value = {
    for k, v in module.database_schemas.schemas : k => {
      name                 = v.name
      fully_qualified_name = v.fully_qualified_name
      database             = v.database
      comment              = v.comment
    }
  }
}

# ----------------------------------------------------------------------------
# 3. File Formats
# ----------------------------------------------------------------------------
output "file_formats" {
  description = "Map of file format names to their details"
  value = {
    for k, v in module.file_formats.file_formats : k => {
      name                 = v.name
      fully_qualified_name = v.fully_qualified_name
      database             = v.database
      schema               = v.schema
      format_type          = v.format_type
      comment              = v.comment
    }
  }
}

# ----------------------------------------------------------------------------
# 4. Stages
# ----------------------------------------------------------------------------
output "stages" {
  description = "Stage outputs from module"
  value       = module.stage
}

# ----------------------------------------------------------------------------
# Tables
# ----------------------------------------------------------------------------
output "tables" {
  description = "Table outputs from module"
  value       = module.table
}

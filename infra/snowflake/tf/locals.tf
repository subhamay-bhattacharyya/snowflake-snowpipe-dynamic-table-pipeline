# -- infra/snowflake/tf/locals.tf
# ============================================================================
# Local Values
# ============================================================================

locals {
  # Parse config from JSON file (relative to workspace root)
  snowflake_config = jsondecode(file("${path.root}/../../../${var.snowflake_config_path}"))

  # ============================================================================
  # Snowflake Configuration
  # ============================================================================

  # Warehouses - add optional prefix to names and grants
  warehouses = {
    for key, wh in lookup(local.snowflake_config, "warehouses", {}) : key => merge(wh, {
      name = var.project_code != "" ? upper("${var.project_code}_${wh.name}") : wh.name
      # Grants - db_provisioner needs USAGE for dynamic table refresh
      grants = [
        { role_name = var.db_provisioner_role, privileges = ["USAGE"] }
      ]
    })
  }

  # Databases with schemas - nested structure
  database_schemas = {
    for db_key, db in lookup(local.snowflake_config, "databases", {}) : db_key => {
      name    = var.project_code != "" ? upper("${var.project_code}_${db.name}") : db.name
      comment = lookup(db, "comment", "")
      schemas = [
        for schema in lookup(db, "schemas", []) : {
          name    = schema.name
          comment = lookup(schema, "comment", "")
          # Grants - data_object_provisioner needs CREATE FILE FORMAT on schemas with file_formats
          grants = lookup(schema, "file_formats", null) != null ? {
            role_name  = var.data_object_provisioner_role
            privileges = ["CREATE FILE FORMAT", "USAGE"]
            } : {
            role_name  = ""
            privileges = []
          }
        }
      ]
    }
  }

  # File Formats - flatten from all databases/schemas into a map with normalized structure
  # Only pass attributes that are explicitly set in config, let module defaults handle the rest
  file_formats = {
    for item in flatten([
      for db_key, db in lookup(local.snowflake_config, "databases", {}) : [
        for schema in lookup(db, "schemas", []) : [
          for ff_key, ff in lookup(schema, "file_formats", {}) : merge(
            {
              name        = ff.name
              format_type = ff.type
              database    = var.project_code != "" ? upper("${var.project_code}_${db.name}") : db.name
              schema      = schema.name
              # Grants - INGEST_ADMIN needs USAGE to use file formats in pipes (only if role is set)
              usage_roles = var.ingest_object_provisioner_role != "" ? [var.ingest_object_provisioner_role] : []
            },
            # Only include optional attributes if they are explicitly defined in config
            lookup(ff, "comment", null) != null ? { comment = ff.comment } : {},
            lookup(ff, "compression", null) != null ? { compression = ff.compression } : {},
            # CSV options
            lookup(ff, "field_delimiter", null) != null ? { field_delimiter = ff.field_delimiter } : {},
            lookup(ff, "record_delimiter", null) != null ? { record_delimiter = ff.record_delimiter } : {},
            lookup(ff, "skip_header", null) != null ? { skip_header = ff.skip_header } : {},
            lookup(ff, "field_optionally_enclosed_by", null) != null ? { field_optionally_enclosed_by = ff.field_optionally_enclosed_by } : {},
            lookup(ff, "trim_space", null) != null ? { trim_space = ff.trim_space } : {},
            lookup(ff, "error_on_column_count_mismatch", null) != null ? { error_on_column_count_mismatch = ff.error_on_column_count_mismatch } : {},
            lookup(ff, "escape", null) != null ? { escape = ff.escape } : {},
            lookup(ff, "escape_unenclosed_field", null) != null ? { escape_unenclosed_field = ff.escape_unenclosed_field } : {},
            lookup(ff, "date_format", null) != null ? { date_format = ff.date_format } : {},
            lookup(ff, "timestamp_format", null) != null ? { timestamp_format = ff.timestamp_format } : {},
            lookup(ff, "null_if", null) != null ? { null_if = ff.null_if } : {},
            # JSON options
            lookup(ff, "enable_octal", null) != null ? { enable_octal = ff.enable_octal } : {},
            lookup(ff, "allow_duplicate", null) != null ? { allow_duplicate = ff.allow_duplicate } : {},
            lookup(ff, "strip_outer_array", null) != null ? { strip_outer_array = ff.strip_outer_array } : {},
            lookup(ff, "strip_null_values", null) != null ? { strip_null_values = ff.strip_null_values } : {},
            lookup(ff, "ignore_utf8_errors", null) != null ? { ignore_utf8_errors = ff.ignore_utf8_errors } : {},
          )
        ]
      ]
    ]) : item.name => item
  }

  # Stages - flatten from all databases/schemas into a map
  # All stage objects have the same structure (null for non-applicable attributes)
  stages = {
    for item in flatten([
      for db_key, db in lookup(local.snowflake_config, "databases", {}) : [
        for schema in lookup(db, "schemas", []) : [
          for stage_key, stage in lookup(schema, "stages", {}) : {
            name       = stage.name
            database   = var.project_code != "" ? upper("${var.project_code}_${db.name}") : db.name
            schema     = schema.name
            stage_type = lookup(stage, "stage_type", "internal")
            comment    = lookup(stage, "comment", "")
            file_format = lookup(stage, "file_format", null) != null ? (
              upper(lookup(stage, "file_format", "")) == "JSON" ? "JSON_FILE_FORMAT" :
              upper(lookup(stage, "file_format", "")) == "CSV" ? "CSV_FILE_FORMAT" :
              lookup(stage, "file_format", null)
            ) : null
            # Grants - READ privilege for external stages, READ/WRITE for internal stages
            grants = lookup(stage, "stage_type", "internal") == "external" ? [
              { role_name = var.ingest_object_provisioner_role, privileges = ["READ"] },
              { role_name = var.data_object_provisioner_role, privileges = ["READ"] },
              { role_name = var.db_provisioner_role, privileges = ["READ"] }
              ] : [
              { role_name = var.ingest_object_provisioner_role, privileges = ["READ", "WRITE"] },
              { role_name = var.data_object_provisioner_role, privileges = ["READ", "WRITE"] },
              { role_name = var.db_provisioner_role, privileges = ["READ", "WRITE"] }
            ]
            # Internal stage attributes (null for external)
            directory_enabled = lookup(stage, "stage_type", "internal") == "internal" ? lookup(stage, "directory_enabled", false) : null
            # External stage attributes (null for internal)
            url = lookup(stage, "stage_type", "internal") == "external" ? lookup(stage, "url", null) : null
            storage_integration = lookup(stage, "stage_type", "internal") == "external" ? (
              lookup(stage, "storage_integration", null) != null && lookup(stage, "storage_integration", "") != "" ? (var.project_code != "" ? upper("${var.project_code}_${stage.storage_integration}") : stage.storage_integration) : null
            ) : null
          }
        ]
      ]
    ]) : item.name => item
  }
  #   # Dynamic Tables configuration
  #   dynamic_tables = {
  #     dt_emp_dept_lag_60_on_schedule = {
  #       name         = "DT_EMP_DEPT_LAG_60_ON_SCHEDULE"
  #       database     = var.project_code != "" ? upper("${var.project_code}_HRMS") : "HRMS"
  #       schema       = "HR"
  #       warehouse    = "DYT_LAB_01_WH"
  #       target_lag   = "60 minutes"
  #       refresh_mode = "AUTO"
  #       initialize   = "ON_SCHEDULE"
  #       comment      = "Employee-Department join with 60 min lag, auto refresh on schedule"
  #       query = templatefile("${path.module}/templates/dynamic-tables/dyt_emp_dept.tpl", {
  #         database = var.project_code != "" ? upper("${var.project_code}_HRMS") : "HRMS"
  #       })
  #     }
  #     dt_emp_dept_lag_60_on_create = {
  #       name         = "DT_EMP_DEPT_LAG_60_ON_CREATE"
  #       database     = var.project_code != "" ? upper("${var.project_code}_HRMS") : "HRMS"
  #       schema       = "HR"
  #       warehouse    = "DYT_LAB_01_WH"
  #       target_lag   = "60 minutes"
  #       refresh_mode = "AUTO"
  #       initialize   = "ON_CREATE"
  #       comment      = "Employee-Department join with 60 min lag, auto refresh on create"
  #       query = templatefile("${path.module}/templates/dynamic-tables/dyt_emp_dept.tpl", {
  #         database = var.project_code != "" ? upper("${var.project_code}_HRMS") : "HRMS"
  #       })
  #     }
  #     dt_emp_dept_downstream_on_create = {
  #       name         = "DT_EMP_DEPT_DOWNSTREAM_ON_CREATE"
  #       database     = var.project_code != "" ? upper("${var.project_code}_HRMS") : "HRMS"
  #       schema       = "HR"
  #       warehouse    = "DYT_LAB_01_WH"
  #       target_lag   = "DOWNSTREAM"
  #       refresh_mode = "AUTO"
  #       initialize   = "ON_CREATE"
  #       comment      = "Employee-Department join with downstream lag, auto refresh on create"
  #       query = templatefile("${path.module}/templates/dynamic-tables/dyt_emp_dept.tpl", {
  #         database = var.project_code != "" ? upper("${var.project_code}_HRMS") : "HRMS"
  #       })
  #     }
  #   }

  #   # Tables - flatten from all databases/schemas into a map
  tables = {
    for item in flatten([
      for db_key, db in lookup(local.snowflake_config, "databases", {}) : [
        for schema in lookup(db, "schemas", []) : [
          for table_key, table in lookup(schema, "tables", {}) : {
            key        = "${db_key}_${lower(schema.name)}_${table_key}"
            database   = var.project_code != "" ? upper("${var.project_code}_${db.name}") : db.name
            schema     = schema.name
            name       = table.name
            table_type = lookup(table, "table_type", "PERMANENT")
            comment    = lookup(table, "comment", "")
            columns = [
              for col in table.columns : {
                name     = col.name
                type     = col.type
                nullable = lookup(col, "nullable", true)
                default  = lookup(col, "default", null)
                comment  = lookup(col, "comment", null)
                autoincrement = lookup(col, "autoincrement", null) != null ? {
                  start     = lookup(col.autoincrement, "start", 1)
                  increment = lookup(col.autoincrement, "increment", 1)
                  order     = lookup(col.autoincrement, "order", false)
                } : null
              }
            ]
            primary_key                 = lookup(table, "primary_key", null)
            cluster_by                  = lookup(table, "cluster_by", null)
            data_retention_time_in_days = lookup(table, "data_retention_time_in_days", 1)
            change_tracking             = lookup(table, "change_tracking", false)
            drop_before_create          = lookup(table, "drop_before_create", false)
          }
        ]
      ]
    ]) : item.key => item
  }
}

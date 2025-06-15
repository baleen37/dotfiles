$ARGUMENTS

Update or generate the YAML docs for this SQL model or folder of models. Look for a matching YAML file or documentation for this model inside a combined YAML file in the same directory. If the YAML for the given SQL model is not included, generate it from scratch based on the SQL code and anything that can be inferred from the upstream files and their YAML. Put the resulting YAML in a separate file matching the name of the model, and if necessary remove this model from any combined YAML files.

Use the `generate_model_yaml` operation to determine the canonical list of columns and data types. Add/update all data types in any existing YAML. If no there is no existing YAML file, add descriptions (and tests, if necessary) to the output of this operation. In this case (and only this case), remove columns that have been commented out or excluded from the SQL.

- Make sure to add a brief description for the model. Infer the model type (staging, intermediate, or mart) and include information about its sources if important. (This doesn't mean adding a `source` property.)
- Carry over descriptions and tests from any matching upstream columns, or update as necessary for derived columns. Ignore relationship tests to a different modeling layer. Ignore any included models or sources that are not directly referenced in this model.
- If a uniqueness test for more than one column is required, use `unique_combination_of_columns` from the dbt_utils package and put it after the model description and before `columns:`, under `data_tests:`. Only add such a test if explicitly requested or if there is such a test upstream, all columns are present in this model, and the cardinality of this model appears to match. Do not change this test if it already exists.
- A uniqueness/primary key test for a single column should be the standard `unique` and `not_null` tests on that column only.
- Use the `data_tests:` syntax
- Add tests for individual columns under `models.columns`; do not use the model-wide `models.data_tests` unless directed to do so.
- Don't include `version: 2` at the top; just start with `models:`
- Do not make guesses about accepted values. Include accepted values tests when (and only when) the column's values are explicitly limited in the provided code. Do not add accepted values tests to boolean columns.
- Do not put quotes around descriptions.
- Do not add/change the `materialized` property unless instructed.
- Include blank lines between columns.

If updating an existing file:
- Make minimal changes, only adding/removing columns, filling in missing descriptions, or updating outlier descriptions to match the others stylistically.
- Do not update existing descriptions except to correct errors or align with the rules above or stylistically with other descriptions in the file.
- Preserve any tests already added to the model or individual columns, including relationship tests.
- Columns can be commented out if they do not appear explicitly in the SQL and are not included implicitly from an upstream model via a `select *`. Do not delete the lines.

**NOTE:** Do not confuse these docs with the `dbt docs generate` or `dbt docs serve` commands. Those commands generate and serve HTML from YAML files. Your task is to create the YAML.

## Relationship Tests

Once columns have been determined, add relationship tests to the YAML:

1. Identify columns that end with `_id`, `_key`, `_sk`, or `_code` - these are potential foreign keys
2. Look for models that might be related to these foreign keys
3. Add appropriate relationship tests for these foreign key columns

Guidelines for adding relationship tests:
- Use 'relationships' tests (from dbt) for foreign keys
- Tests should be added under the column's 'data_tests:' section
- Only add tests when confident there's a valid relationship
- Only add relationships to models in the same modeling layer (e.g. marts)

Example:
```
  - name: coffee_id
    description: Foreign key to the coffees table
    data_tests:
      - not_null
      - relationships:
          to: ref('coffees')
          field: coffee_id
```

## Coffee Analytics Project Context

When working with this coffee analytics project, consider these domain-specific patterns:

### Common Entity Relationships
- `coffee_id` typically references the main coffees mart table
- `roaster_id` references roaster entities from Collections or Airtable sources
- `origin_id` references geographic origin data
- `flavor_profile_key` is a surrogate key for flavor combinations

### Rating System
- Ratings use text values ('Good', 'Fine', 'Bad') converted to numeric via the `rating_value` macro
- Rating dates are stored as `rated_date`
- Boolean preferences use `is_favorite`, `is_liked`, `is_disliked`

### Coffee Characteristics
- Use `is_` prefix for boolean coffee attributes (is_decaf, is_available)
- Geographic data includes country, world_region, and elevation ranges
- Process and roast information may have '[Unknown]' defaults
- Blend coffees use '[Blend]' for country/region fields

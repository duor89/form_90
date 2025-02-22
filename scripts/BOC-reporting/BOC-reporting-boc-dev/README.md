# BOC-reporting

An automated reporting solution that converts Excel-based reporting processes into Python code, designed to improve processing speed and reduce operational errors.

## Project Overview

This project automates the generation of Bank of China (BOC) reports by:
1. Extracting data from SQL databases
2. Applying mapping rules and business logic
3. Validating data completeness
4. Generating final aggregated reports

## Project Structure

```
BOC-reporting/
├── config/                 # Configuration files
│   ├── RT30_RT32.yaml     # RT30/RT32 specific configurations
│   └── 731.yaml           # 731 report configurations
│   └── MIS_SRS.yaml           # MIS_SRS report configurations
│   └── Facility.yaml           # Facility report configurations
├── data/                  # Input data directory
├── output/                # Output files directory
│   └── logs/             # Processing logs directory
├── queries/              # SQL query files
└── scripts/              # Python processing scripts
    ├── extract.py        # SQL data extraction
    ├── initial_process.py # Initial data processing
    ├── post_review.py    # Post-review data updates
    ├── final_main.py     # Final aggregation and validation
    ├── mapping.py        # Data mapping operations
    ├── post_mapping.py   # Post-mapping operations
    └── validation.py     # Data validation functions
    └── aggregate.py      # Data aggregation
```

## Prerequisites

- Python 3.11+
- Access to required SQL databases
- Required Python packages (install via pip):
  ```
  pandas
  numpy
  openpyxl
  pyyaml
  sqlalchemy
  ```

## Processing Flow

The data processing is divided into three main stages:

### 1. Initial Processing (`initial_process.py`)
- Extracts data from three SQL sources (RMD, RT30, MIS)
- Removes duplicates from RT30 dataset
- Identifies and logs data issues
- Outputs issues to `log.xlsx`

### 2. Post-Review Processing (`post_review.py`)
- Updates dataset based on reviewed `log.xlsx`
- Re-applies mapping and validation
- Can be run multiple times until all data issues are resolved
- Exports updated data to Excel

### 3. Final Processing (`final_main.py`)
- Performs final data validation
- Runs aggregation steps
- Validates AL vs GL figures
- Generates final output report

## Usage

1. Ensure all prerequisites are installed
2. Configure database connections in config files
3. Run the scripts in sequence:

```bash
# 1. Initial processing
python scripts/initial_process.py

# 2. Review log.xlsx and make necessary corrections
# 3. Run post-review processing (can be repeated if needed)
python scripts/post_review.py

# 4. Final processing and report generation
python scripts/final_main.py
```

## Output Files

- `log.xlsx`: Contains data issues that need manual review
- `final_report.xlsx`: Final processed data output
- Additional log files in the `output/logs/` directory

## Error Handling

The system logs various types of data issues:
- Duplicate records
- Mapping inconsistencies
- Validation failures
- AL vs GL discrepancies

All issues are logged to `log.xlsx` for manual review and correction.

## Maintenance

Regular maintenance tasks:
1. Update SQL queries as needed
2. Maintain mapping rules in configuration files
3. Review and update validation rules
4. Keep Python dependencies up to date

## Contributing

1. Follow the existing code structure
2. Document any changes in configurations
3. Test thoroughly before deploying changes
4. Update this README if new features are added
from pathlib import Path
import pandas as pd
from extract import extract_data, extract_test_data
from mapping import ReportMapper
from post_mapping import RT30RT32PostMapper, RMDPostMapper
from utils import ReportingLogger, schema_dict

import warnings
warnings.filterwarnings('ignore')

logger = ReportingLogger(__name__, "reporting.log").logger


def process_rt30_duplicates(data: pd.DataFrame, logs_path: Path) -> pd.DataFrame:
    """Process and log RT30 duplicates"""
    rt30_data = data.sort_values(by='customer_nr', ascending=False)
    duplicates = rt30_data[rt30_data.duplicated(
        subset=rt30_data.columns.drop('customer_nr'), keep='last')]

    if not duplicates.empty:
        logger.warning(f"Found {len(duplicates)} duplicate records in RT30")

        if (logs_path / 'rt30_duplicates.xlsx').exists():
            previous_duplicates = pd.read_excel(
                logs_path / 'rt30_duplicates.xlsx', dtype=schema_dict)
            duplicates = pd.concat(
                [previous_duplicates, duplicates]).drop_duplicates(keep='first')

        duplicates.to_excel(logs_path / 'rt30_duplicates.xlsx', index=False)

    return rt30_data.drop_duplicates(
        subset=rt30_data.columns.drop('customer_nr'),
        keep='first'
    )


def validate_rt30(data: pd.DataFrame) -> pd.DataFrame:
    """Validate RT30 data and generate logs"""

    # Check NA keys
    na_key = data[
        (data['Vis-à-vis counterparty sector'].isna()) &
        (data[['rca_accrint', 'rca_bookv', 'rca_marketv',
               'rca_prov_coll', 'rca_prov_indi']].sum(axis=1) != 0)
    ].copy()

    na_key['log_reason'] = 'NA key with non-zero rca'
    na_key['record_action'] = ''

    # Check estimated value code
    error_est = data[
        (data['估值'] == 'ERROR') &
        (data['rca_mtm_negative'] +
         data['rca_mtm_positive'] != 0)
    ].copy()
    error_est['log_reason'] = 'ERROR估值 with non-zero rca_mtm'
    error_est['record_action'] = ''

    return pd.concat([na_key, error_est])


def validate_rmd(data: pd.DataFrame) -> pd.DataFrame:
    """Validate RMD data and generate logs"""
    invalid_records = data[
        (data['Check with 上期 country'] == False) |
        (data['Check with 上期 counterparty type'] == False)
    ].copy()
    invalid_records['log_reason'] = "False check flag found"
    invalid_records['record_action'] = ''
    return invalid_records


def main():
    # Setup paths
    base_path = Path(__file__).parent.parent
    output_path = base_path / 'output'
    logs_path = output_path / 'logs'

    try:
        # Extract data
        # data = extract_data()
        data = extract_test_data()

        # Process RT30 duplicates
        data['rt30_rt32'] = process_rt30_duplicates(
            data['rt30_rt32'], logs_path)

        # Map and validate RT30
        rt30_mapper = ReportMapper(base_path / 'config' / 'RT30_RT32.json')
        df_rt30_mapped = rt30_mapper.map_data(data['rt30_rt32'])
        rt30_logic = RT30RT32PostMapper(df_rt30_mapped, rt30_mapper)
        rt30_output = rt30_logic.pre_process()
        rt30_log = validate_rt30(rt30_output)

        # Process RMD
        rmd_mapper = ReportMapper(
            base_path / 'config' / 'RMD.json', reuse_mappings=False)
        df_rmd_mapped = rmd_mapper.map_data(rt30_output)
        rmd_logic = RMDPostMapper(df_rmd_mapped)
        data['rmd'] = rmd_logic.process_all()

        # Validate RMD
        rmd_log = validate_rmd(data['rmd'])

        logger.info("Exporting log and raw data")
        # Save logs
        with pd.ExcelWriter(logs_path / 'log.xlsx') as writer:
            rmd_log.to_excel(writer, sheet_name='RMD Log', index=False)
            rt30_log.to_excel(writer, sheet_name='RT30 Log', index=False)

        # Save raw outputs
        with pd.ExcelWriter(output_path / 'raw_data.xlsx') as writer:
            for name, df in data.items():
                df.to_excel(writer, sheet_name=name, index=False)

        logger.info("Initial processing completed successfully")

    except Exception as e:
        logger.error(f"Error in main processing: {e}")
        raise


if __name__ == "__main__":
    main()

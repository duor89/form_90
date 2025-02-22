from pathlib import Path
import pandas as pd
from utils import *
from mapping import ReportMapper
from post_mapping import RT30RT32PostMapper, RMDPostMapper, FacilityPostMapper, MISSRSPostMapper
from initial_process import validate_rt30, validate_rmd

logger = ReportingLogger(__name__, "reporting.log").logger


def load_logs(logs_path: Path) -> dict:
    """Load RT30 and RMD logs"""
    log_file = logs_path / 'log.xlsx'
    logs = {'rt30': pd.DataFrame(), 'rmd': pd.DataFrame()}

    if log_file.exists():
        with pd.ExcelFile(log_file) as xls:
            logs['rt30'] = pd.read_excel(
                xls, 'RT30 Log', dtype=schema_dict, na_values=na_values)
            logs['rmd'] = pd.read_excel(
                xls, 'RMD Log', dtype=schema_dict, na_values=na_values)

            # Initialize status column if it doesn't exist
            for key in logs:
                if 'status' not in logs[key].columns:
                    logs[key]['status'] = 'PENDING'

    return logs


def delete_records(data: pd.DataFrame, log_df: pd.DataFrame, key_cols: list) -> pd.DataFrame:
    if log_df.empty:
        return data

    data = data.merge(
        log_df[key_cols], on=key_cols, how='left', indicator=True)
    data = data[data['_merge'] == 'left_only'].drop(columns=['_merge'])
    return data


def perform_record_actions(data: pd.DataFrame, log_df: pd.DataFrame, key_cols: list = None) -> pd.DataFrame:
    """Update records based on log actions

    Args:
        data: DataFrame containing original records
        log_df: DataFrame containing log records with actions

    Returns:
        Updated DataFrame with log actions applied
    """
    if log_df.empty:
        return data, log_df

    # Only process PENDING records
    pending_logs = log_df[log_df['status'] != 'DONE'].copy()
    if pending_logs.empty:
        return data, log_df

    # Split logs by action type
    delete_logs = pending_logs[pending_logs['record_action'].fillna(
        '').str.lower() == 'delete']
    update_logs = pending_logs[pending_logs['record_action'].fillna(
        '').str.lower() == 'update']
    insert_logs = pending_logs[pending_logs['record_action'].fillna(
        '').str.lower() == 'insert']

    if key_cols is None:
        key_cols = data.columns.tolist()

    # Delete records
    if not delete_logs.empty:
        logger.info(f"Deleting {len(delete_logs)} records")
        data = delete_records(data, delete_logs, key_cols)

    # Update records by replacing with log records
    if not update_logs.empty:
        logger.info(f"Updating {len(update_logs)} records")
        data = delete_records(data, update_logs, key_cols)
        data = pd.concat([data, update_logs[data.columns]], ignore_index=True)

    # Insert new records
    if not insert_logs.empty:
        logger.info(f"Inserting {len(insert_logs)} new records")
        data = pd.concat([data, insert_logs[data.columns]], ignore_index=True)

    # Update status to DONE for processed records with valid actions
    log_df.loc[(log_df['status'] != 'DONE') &
               (log_df['record_action'].fillna('').str.lower().isin(
                   ['delete', 'update', 'insert'])),
               'status'] = 'DONE'

    return data, log_df


def reapply_mappings(data: dict, base_path: Path) -> dict:
    """Re-apply mappings and post-mapping logic"""
    logger.info("Re-applying RT30 mappings")
    # Re-run RT30 mapping with potentially updated mapping files
    rt30_mapper = ReportMapper(base_path / 'config' / 'RT30_RT32.json')
    df_rt30_mapped = rt30_mapper.map_data(data['rt30_rt32'][rt30_cols])
    rt30_logic = RT30RT32PostMapper(df_rt30_mapped, rt30_mapper)
    data['rt30_rt32'] = rt30_logic.pre_process()

    logger.info("Re-applying RMD mappings")

    # Re-run RMD mapping and post-mapping
    rmd_mapper = ReportMapper(
        base_path / 'config' / 'RMD.json', reuse_mappings=False)
    df_rmd_mapped = rmd_mapper.map_data(
        data['rt30_rt32'])  # Note: Using updated RT30 data
    rmd_logic = RMDPostMapper(df_rmd_mapped)
    data['rmd'] = rmd_logic.process_all()

    # facility mapping
    facility_mapper = ReportMapper(
        base_path / 'config' / 'Facility.json')
    facility_mapper.add_mapping('RMD', data['rmd'])

    df_facility = data['facility'][facility_cols]
    df_facility['AP code'] = df_facility['deal_type'].str[-4:]
    df_facility_mapped = facility_mapper.map_data(df_facility)
    facility_logic = FacilityPostMapper(df_facility_mapped)
    data['facility'] = facility_logic.process_all()

    # rt30 post facility process
    data['rt30_rt32'] = rt30_logic.post_process()

    # mis srs process
    mis_mapper = ReportMapper(base_path / 'config' / 'MIS_SRS.json')
    data['mis_srs'] = mis_mapper.map_data(data['mis_srs'][mis_cols])
    mis_logic = MISSRSPostMapper(data['mis_srs'])
    data['mis_srs'] = mis_logic.process_all()

    return data


def main():
    base_path = Path(__file__).parent.parent
    output_path = base_path / 'output'
    logs_path = output_path / 'logs'

    try:
        logger.info("Starting post-review processing")
        # Load the raw data
        logger.info("Loading raw data")

        # check if updated data exists
        updated_file = output_path / 'updated_data.xlsx'
        if updated_file.exists():
            data = pd.read_excel(updated_file, sheet_name=None,
                                 dtype=schema_dict, na_values=na_values)
        else:
            data = pd.read_excel(output_path / 'raw_data.xlsx',
                                 sheet_name=None, dtype=schema_dict, na_values=na_values)

        # Load logs
        logger.info("Loading manual review logs")
        logs = load_logs(logs_path)

        # Step 1: Update RT30 records based on manual actions
        # logger.info("Processing RT30 manual updates")
        # data['rt30_rt32'], logs['rt30'] = perform_record_actions(
        #     data['rt30_rt32'], logs['rt30'])

        # Step 2: Re-apply all mappings and post-mapping logic
        logger.info("Re-applying mappings after RT30 updates")
        data = reapply_mappings(data, base_path)

        # Step 3: Update RMD records based on manual actions
        logger.info("Processing RMD manual updates")
        logs['rmd'] = RMDPostMapper(logs['rmd'], False).process_all()
        data['rmd'], logs['rmd'] = perform_record_actions(
            data['rmd'], logs['rmd'], ['ide_linkage_ref', 'customer_nr'])

        # Step 4: Validate the updated data
        logger.info("Validating updated data")
        rt30_log = pd.concat([logs['rt30'], validate_rt30(data['rt30_rt32'])])
        rmd_log = pd.concat([logs['rmd'], validate_rmd(data['rmd'])])

        # Save updated data
        logger.info("Saving updated data")
        with pd.ExcelWriter(output_path / 'updated_data.xlsx') as writer:
            for name, df in data.items():
                df.to_excel(writer, sheet_name=name, index=False)

        # save logs
        logger.info("Saving validation logs")
        with pd.ExcelWriter(logs_path / 'log.xlsx') as writer:
            rmd_log.to_excel(writer, sheet_name='RMD Log', index=False)
            rt30_log.to_excel(writer, sheet_name='RT30 Log', index=False)

        logger.info("Manual updates processed successfully")

    except Exception as e:
        logger.error(f"Error in post-manual processing: {e}")
        raise


if __name__ == "__main__":
    main()

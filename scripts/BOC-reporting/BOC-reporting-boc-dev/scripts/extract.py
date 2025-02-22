import os
from pathlib import Path
from typing import Dict
from utils import ReportingLogger, log_errors


from sqlalchemy import create_engine, text
import pandas as pd


logger = ReportingLogger(__name__, "reporting.log").logger


def connect_to_db():
    """Create database connection"""
    server = 'DESKTOP-R532DCO\SQLEXPRESS'

    try:
        connection_string = (
            f"mssql+pyodbc:///?"
            f"odbc_connect=DRIVER=ODBC+Driver+17+for+SQL+Server;"
            f"SERVER={server};Trusted_Connection=yes;"
        )

        # # username and password
        # connection_string = (
        #     f"mssql+pyodbc:///?"
        #     f"odbc_connect=DRIVER=ODBC+Driver+17+for+SQL+Server;"
        #     f"SERVER={server};DATABASE={database};"
        #     f"UID={username};PWD={password};"
        # )

        return create_engine(connection_string)
    except Exception as e:
        logger.error(f"Error connecting to database: {e}")
        return None


def extract_data() -> Dict[str, pd.DataFrame]:
    """Extract all required datasets from SQL"""
    queries_path = Path(__file__).parent.parent / 'queries'
    sql_files = {
        'rt30_rt32': '731 RT30RT32 FEE BOCS v2.sql',
        'mis_srs': 'MIS SRS query - All sys.sql',
        'facility': '731 FACILITY BOCS New.sql'
    }
    engine = connect_to_db()
    if engine is None:
        raise ConnectionError("Failed to connect to database")
    results = {}
    try:
        with engine.connect() as conn:

            # create #trn table
            with open(queries_path / '731 RT30 TRN.sql', 'r') as f:
                query = f.read()
            conn.execute(text(query))

            # extract data
            for name, file in sql_files.items():
                logger.info(f"Extracting {name} data")
                with open(queries_path / file, 'r') as f:
                    query = f.read()
                results[name] = pd.read_sql(text(query), conn)

        return results
    except Exception as e:
        logger.error(f"Error extracting data: {e}")
        raise


def extract_test_data():
    path = os.path.join(
        os.path.dirname(__file__),
        r'../data/1.BOCS ARF 731 working 30122024 updates data.xlsb')

    na_values = ['-1.#IND', '1.#QNAN', '1.#IND', '-1.#QNAN', '#N/A N/A', '#N/A', 'N/A',
                 'n/a', '<NA>', '#NA', 'NULL', 'null', 'NaN', '-NaN', 'nan', '-nan', 'None', '']

    schema_dict = {
        'deal_id': str,
        'ide_linkage_ref': str,
        'customer_nr': str,
        'facility_nr': str,
        'AP_CODE': str,
        'SUB CODE': str,
        'PROD_CODE': str,
        'ide_sourcesys_ref': str,
        'ide_linkage_type': str,
        'nationality': str
    }

    output = {}

    output['facility'] = pd.read_excel(
        path,
        sheet_name='Facility',
        dtype=schema_dict)[[
            'entity', 'facility_nr', 'customer_nr', 'customer_legal_name',
            'deal_type', 'currency', 'OBS amount', 'Counterparty type', 'Domicile',
            'source_system']]

    output['rt30_rt32'] = pd.read_excel(
        path,
        sheet_name='RT30_RT32',
        dtype=schema_dict,
        keep_default_na=False,
        na_values=na_values
    )[['ide_internal_party_ref', 'ide_linkage_ref', 'ide_linkage_type',
       'ide_sourcesys_ref', 'lot_type_fk', 'rca_accrint', 'rca_bookv',
       'rca_marketv', 'rca_prov_coll', 'rca_prov_indi', 'rv_coa',
       'rv_cpty_type', 'rv_rel_party_type', 'rv_currency_sub_group',
       'rv_mat_original', 'rv_mat_remaining', 'rca_deferred_fee',
       'rca_mtm_negative', 'rca_mtm_positive', 'entity', 'deal_id',
       'customer_nr', 'nationality', 'domicile', 'customer_legal_name',
       'deal_type', 'currency', 'tfi_id', 'source_table', 'value_date',
       'maturity_date', 'source_system']]
    output['rt30_rt32'].columns = output['rt30_rt32']\
        .columns.str.split('.').str[0]

    output['mis_srs'] = pd.read_excel(
        path,
        sheet_name='MIS-SRS',
        dtype=schema_dict
    )
    output['mis_srs'].columns = output['mis_srs'].columns.str.strip()

    output['mis_srs'] = output['mis_srs'][['DATE', 'ENTITY', 'DBU OBU', 'STATE', 'ORGANISATION CODE', 'RESP CENTER', 'DEAL_ID', 'AP_CODE', 'AP_NAME', 'SUB CODE',
                                           'PROD_CODE', 'A/L/E', 'MGT ITEM', 'SOURCE_SYSTEM', 'p1', 'p2', 'p3', 'p4', '管控类型', '管控部门', '前中后台', 'P DEPT', 'CURRENCY', 'Original Amount',
                                           'AUD Equivalent', 'yearly_average_balance_ori', 'yearly_average_balance_aud', 'monthly_average_balance_ori', 'monthly_average_balance_aud', 'Last mth end YTD-ORI',
                                           'Last mth end YTD-AUD', 'Last year end YTD-ORI', 'Last year end YTD-AUD', 'Last year mth end YTD-ORI', 'Last year mth end YTD-AUD', 'Budget']]

    return output


def main():
    """Extract data and save to CSV"""
    try:
        # Choose between real or test data
        data = extract_data()
        # data = extract_test_data()

        # Save raw data
        output_path = Path(__file__).parent.parent / 'output'

        with pd.ExcelWriter(output_path / 'raw_data.xlsx') as writer:
            for name, df in data.items():
                df.to_excel(writer, sheet_name=name, index=False)
                logger.info(f"Saved raw {name} data")

    except Exception as e:
        logger.error(f"Error in data extraction: {e}")
        raise


if __name__ == "__main__":
    main()

from random import choice
import numpy as np
import pandas as pd


class RT30RT32PostMapper:
    """Handles post-mapping logic for RT30 and RT32 reports"""

    def __init__(self, data, mapper=None):
        self.data = data.copy()
        self.mapper = mapper

    def add_731_category(self):
        """
        add 731.1分类 by mapping logic
        """

        def coa_mapping_rule(row):
            if row['ALE'] == 'A':
                return row['A分类']
            elif row['ALE'] == 'L':
                return row['L分类']
            elif row['ALE'] == 'OB':
                if row['rca_mtm_negative'] == 0:
                    return row['OB-A分类']
                else:
                    return row['OB-L分类']
            else:
                return 'NA'

        # apply rule
        self.data["731.1分类"] = self.data.apply(coa_mapping_rule, axis=1)
        self.data.drop(
            columns=['A分类', 'L分类', 'OB-A分类', 'OB-L分类'], inplace=True)

        return self

    def add_vis_country(self):

        self.data['Vis-à-vis country'] = np.select(
            [
                self.data['customer_nr'] == 'NULL',
                self.data['domicile'].str.upper() == 'XX',
            ],
            ['NULL', 'CN'],
            self.data.domicile.fillna('NULL')
        )

        return self

    def add_vis_counterparty(self):

        self.data['Vis-à-vis counterparty sector'] = np.select(
            [(self.data['ALE'] == 'L') & (self.data['731.1分类'] == '(7)'),
             (self.data['ide_linkage_type'] == 1) & (
                 self.data['customer_nr'] == '1060000001'),
             self.data['rv_rel_party_type'].isin(['DE', 'DEFAULT'])
             ],
            ['Unallocated', 'Unallocated', self.data['731a']],
            self.data['731b']
        )
        self.data.drop(columns=['731a', '731b'], inplace=True)

        return self

    def add_key(self):

        self.data['Key'] = self.data[
            ['731 CCY', 'Vis-à-vis counterparty sector', 'Vis-à-vis country']].fillna('NA')\
            .agg('|'.join, axis=1)
        return self

    def add_fda_table(self):
        self.data['fda_table'] = np.where(
            self.data['ide_linkage_type'] == 10,
            self.data['fda_table_10'],
            self.data['fda_table_others']
        )
        self.data.drop(
            columns=['fda_table_10', 'fda_table_others'], inplace=True)
        return self

    def add_deal_type_derived(self):
        conditions = [
            self.data['fda_table'].isin(
                ['DEPOSIT', 'LOAN', 'BOND', 'FOREX', 'OPTION', 'IR_SWAP']),
            self.data['fda_table'] == 'BALANCE_BOC',
            self.data['fda_table'] == 'FEE',
        ]
        results = [
            self.data['deal_type'].str[-4:],
            self.data['ide_linkage_ref'].str[:4],
            '8475'
        ]
        self.data['deal_type_derived'] = np.select(
            conditions, results, default='NA')

        return self

    def add_interest_type(self):
        if self.mapper:
            result = self.mapper.apply_mapping(
                self.data,
                self.mapper.all_mappings["应收应付利息1"],
                keys={"main": "deal_type_derived", "mapping": "本金"},
                values={"利息": "利息"},
                sheet_name="应收应付利息1"
            )
            self.data['利息'] = result['利息'].fillna('NA')

        return self

    def add_estimate_value(self):
        if self.mapper:
            result = self.mapper.apply_mapping(
                self.data,
                self.mapper.all_mappings["应收应付利息2"],
                keys={"main": "deal_type_derived", "mapping": "表外敞口"},
                values={
                    "MTM_POSITIVE": "MTM_POSITIVE",
                    "MTM_NEGATIVE": "MTM_NEGATIVE"
                },
                sheet_name="应收应付利息2"
            )

            def _logic(row):
                if str(row['ide_linkage_type']) in ['8', '9', '11']:
                    if row['rca_mtm_negative'] != 0:
                        return row['MTM_NEGATIVE']
                    elif row['rca_mtm_positive'] != 0:
                        return row['MTM_POSITIVE']
                    else:
                        return "ERROR"
                else:
                    return "NA"

            self.data['估值'] = result.apply(_logic, axis=1)

        return self

    def add_nationality(self):

        nationality = self.data['nationality'].replace('YY', pd.NA)
        domicile = self.data['domicile'].replace('XX', 'CN')

        self.data['Nationality'] = nationality\
            .fillna(nationality)\
            .fillna(domicile)\
            .fillna('NULL')

        return self

    def add_rv_mat_remaining(self):
        """
        add rv_mat_remaining by excel formula
        """
        def calculate_remaining_maturity(row):
            if row['source_table'] == 'FASM':
                # Calculate the date differences
                date_diff = pd.to_datetime(
                    row['maturity_date']) - pd.to_datetime(row['value_date'])
                years = date_diff.days // 365
                months = date_diff.days // 30
                remaining_days = date_diff.days - (years * 365)

                # Format the result for FASM
                if years >= 5:
                    return f"1060{remaining_days:03d}"
                else:
                    return f"10{months:02d}{remaining_days:03d}"
            else:
                # For non-FASM records
                bgl_ap_codes = self.mapper.all_mappings['BGL AP code']['BGL AP code'].values
                if row['deal_type_derived'] in bgl_ap_codes:
                    return "1001000"
                else:
                    return str(int(row['rv_mat_remaining'] if pd.notna(row['rv_mat_remaining']) else 0))

        self.data['rv_mat_remaining_derived'] = self.data.apply(
            calculate_remaining_maturity, axis=1).astype(int)

        return self

    def add_risk_in(self):
        if self.mapper:
            # Keep existing mapping dictionary setup
            map_from_ide = self.mapper.all_mappings["RMD"]\
                .drop_duplicates(subset=['ide_linkage_ref'], keep='first')\
                .set_index('ide_linkage_ref')\
                .rename(columns={'本期最终风险承担国家 Ultimate risk-bearing countries': 'RMD_country_ide'})['RMD_country_ide']\
                .to_dict()

            map_from_cust = self.mapper.all_mappings["RMD"]\
                .drop_duplicates(subset=['customer_nr'], keep='first')\
                .set_index('customer_nr')\
                .rename(columns={'本期最终风险承担国家 Ultimate risk-bearing countries': 'RMD_country_cust_ref'})['RMD_country_cust_ref']\
                .to_dict()

            def evaluate_row(row):
                # Get the mapped value based on deal type
                if row['deal_type_derived'] == "8475":
                    result = map_from_cust.get(row['customer_nr'], None)
                else:
                    result = map_from_ide.get(row['ide_linkage_ref'], None)

                # If no mapping found or result is 0, fall back to nationality logic
                if result is None:
                    if row['nationality'] == "YY":
                        result = row['Vis-à-vis country']
                    else:
                        result = row['Nationality']

                return result

            self.data['Risk_in'] = self.data.apply(evaluate_row, axis=1)
            self.data['Risk Transfer'] = np.where(
                self.data['Risk_in'] == self.data['Vis-à-vis country'],
                "N",
                "Y"
            )

            return self

    def add_risk_in_counterparty(self):
        if self.mapper:
            result = self.mapper.apply_mapping(
                self.data,
                self.mapper.all_mappings["RMD"],
                keys={"main": "ide_linkage_ref", "mapping": "ide_linkage_ref"},
                values={"本期最终风险承担方性质Description": "Risk_in_counterparty"},
                sheet_name="RMD"
            )

        # logic
        def _logic(row):
            if row['source_system'] in ['2', '002']:
                return row['Risk_in_counterparty']
            else:
                return row['Vis-à-vis counterparty sector']

        self.data['Risk in Counterparty'] = result.apply(_logic, axis=1)

        return self

    def get_data(self):
        return self.data

    def pre_process(self):
        return (self
                .add_731_category()
                .add_vis_country()
                .add_vis_counterparty()
                .add_key()
                .add_fda_table()
                .add_deal_type_derived()
                .add_interest_type()
                .add_estimate_value()
                .add_nationality()
                .add_rv_mat_remaining()
                .get_data())

    def post_process(self):
        return (self
                .add_risk_in()
                .add_risk_in_counterparty()
                .get_data())


class MISSRSPostMapper:
    """Handles post-mapping logic for MIS-SRS report"""

    def __init__(self, data):
        self.data = data.copy()

    def add_ccy(self):
        self.data['CCY'] = self.data['CURRENCY']
        return self

    def get_derivatives(self):
        self.data['Derivatives'] = self.data['MTM_POSITIVE'].fillna(
            self.data['MTM_NEGATIVE'])

        self.data.drop(columns=['MTM_POSITIVE', 'MTM_NEGATIVE'], inplace=True)

        return self

    def fill_na(self):
        self.data['G'] = self.data['G'].fillna('')
        return self

    def get_amount(self):
        self.data['Amount'] = np.where(self.data['AP_CODE'] == '8475',
                                       - self.data['AUD Equivalent'],
                                       self.data['AUD Equivalent'])
        return self

    def get_data(self):
        return self.data

    def process_all(self):
        return (self
                .add_ccy()
                .get_derivatives()
                .fill_na()
                .get_amount()
                .get_data())


class RMDPostMapper:
    """Handles post-mapping logic for MIS-SRS report"""

    REQUIRED_COLUMNS = [
        'ide_linkage_ref', 'customer_nr', 'Vis-à-vis counterparty sector',
        'ide_sourcesys_ref', 'rca_bookv', 'customer_legal_name', 'nationality', 'domicile',
        '本期最终风险承担国家 Ultimate risk-bearing countries', '本期最终风险承担方性质Description',
        'Last ultimate risk-bearing countries', 'Last description'
    ]

    def __init__(self, data, filter_data=True):
        self.input_data = data.copy()
        self.data = self._init_data(filter_data)

    def _init_data(self, filter_data):
        if filter_data:
            res = self.input_data[
                (self.input_data['rv_coa'].isin(['BLS-AST-LOANS-PLAIN', 'BLS-AST-LOANS-TF'])) &
                (self.input_data['rca_bookv'] != 0)
            ][self.REQUIRED_COLUMNS]
        else:
            res = self.input_data.rename(columns={
                '上期最终风险承担方性质Description': 'Last description',
                '上期最终风险承担国': 'Last ultimate risk-bearing countries',
            })
        return res.reset_index(drop=True)

    def add_rca_bookv(self):
        self.data['rca_bookv'] = self.input_data.groupby(
            'ide_linkage_ref')['rca_bookv'].transform('sum').round(1)
        return self

    def add_risk_bearing_country(self):
        """
        add 本期最终风险承担国家 Ultimate risk-bearing countries by mapping logic
        """

        country = np.where(
            self.data['nationality'] == 'YY',
            self.data['domicile'],
            self.data['nationality'])

        self.data['本期最终风险承担国家 Ultimate risk-bearing countries'] = \
            self.data['本期最终风险承担国家 Ultimate risk-bearing countries']\
            .fillna(pd.Series(country))

        return self

    def add_risk_bearing_type(self):

        self.data['本期最终风险承担方性质Description'] = np.where(
            self.data['ide_sourcesys_ref'].str.strip().isin(['2', '002']),
            self.data['本期最终风险承担方性质Description'],
            self.data['Vis-à-vis counterparty sector']
        )

        return self

    def add_last_risk_bearing_country(self):

        self.data['上期最终风险承担国'] = \
            self.data['Last ultimate risk-bearing countries']\
            .fillna("")

        self.data = self.data.drop(
            columns=['Last ultimate risk-bearing countries'])

        return self

    def add_last_risk_bearing_type(self):

        self.data['上期最终风险承担方性质Description'] = self.data['Last description']
        self.data = self.data.drop(
            columns=['Last description'])

        return self

    def add_check_country(self):
        self.data['Check with 上期 country'] = self.data.apply(
            lambda x: "NEW"
            if x['上期最终风险承担国'] == '' or pd.isna(x['上期最终风险承担国'])
            else x['上期最终风险承担国'] == x['本期最终风险承担国家 Ultimate risk-bearing countries'],
            axis=1
        )
        return self

    def add_check_counterparty(self):
        self.data['Check with 上期 counterparty type'] = self.data.apply(
            lambda x: "NEW"
            if x['上期最终风险承担方性质Description'] == '' or pd.isna(x['上期最终风险承担方性质Description'])
            else x['上期最终风险承担方性质Description'] == x['本期最终风险承担方性质Description'],
            axis=1
        )
        return self

    def get_data(self):
        return self.data

    def process_all(self):
        return (self
                .add_rca_bookv()
                .add_risk_bearing_country()
                .add_risk_bearing_type()
                .add_last_risk_bearing_country()
                .add_last_risk_bearing_type()
                .add_check_country()
                .add_check_counterparty()
                .get_data())


class FacilityPostMapper:
    """Handles post-mapping logic for Facility report"""

    def __init__(self, data):
        self.data = data.copy()

    def get_risk_bearing_country(self):
        """
        Get the risk-bearing country for Facility report

        Rules:
        1. If Ultimate risk-bearing countries-RMD is not NaN, use it
        2. If Domicile is 'XX', use 'CN'
        3. If Domicile is not NaN, use it
        4. Otherwise, use 'N/A'
        """
        condtions = [
            pd.notna(self.data['Ultimate risk-bearing countries-RMD']),
            self.data['Domicile'] == 'XX',
            pd.notna(self.data['Domicile']),
        ]
        choices = [
            self.data['Ultimate risk-bearing countries-RMD'],
            'CN',
            self.data['Domicile'],
        ]

        self.data['Ultimate risk-bearing countries-RMD'] = np.select(
            condtions, choices, 'N/A'
        )
        return self

    def process_guarantee(self):
        self.data['Guarantee'] = self.data['Guarantee'].fillna('')
        return self

    def get_data(self):
        return self.data

    def process_all(self):
        return (self
                .get_risk_bearing_country()
                .process_guarantee()
                .get_data())

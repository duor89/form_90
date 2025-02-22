from dataclasses import dataclass
from typing import List, Dict
import pandas as pd
import numpy as np


class AGvsGL:
    def __init__(self, mis_srs, rt30_rt32):
        self.output = self._pivot_mis_srs(mis_srs).copy()
        self.rt30_rt32 = rt30_rt32.copy()

    def _pivot_mis_srs(self, mis_srs):
        """MIS-SRS pivot
        """
        filters = (mis_srs.ALE.isin(['A', 'L'])) & (mis_srs.Derivatives.isna())
        result = mis_srs[filters]\
            .groupby(['AP_CODE', 'AP_NAME', 'CCY', 'rv_coa', 'ALE'], dropna=False)\
            .agg(Total=('AUD Equivalent', 'sum'))\
            .reset_index()

        # result.columns = pd.MultiIndex.from_product([['MIS-SRS'], result.columns])

        return result.rename(columns={'rv_coa': 'COA'})

    def get_rca_bookv(self):

        self.output['ALE-反方向'] = self.output['ALE']\
            .map({'A': 'L', 'L': 'A'})

        # rca_bookv in AGvsGL
        ale_sum = (
            self.rt30_rt32
            .groupby(['deal_type_derived', 'currency', 'ALE'])['rca_bookv']
            .sum()
            .reset_index()
        )

        # base value
        base_ale = self.output.merge(
            ale_sum,
            left_on=['AP_CODE', 'CCY', 'ALE'],
            right_on=['deal_type_derived', 'currency', 'ALE'],
            how='left'
        )

        opposite_ale = self.output.merge(
            ale_sum,
            left_on=['AP_CODE', 'CCY', 'ALE-反方向'],
            right_on=['deal_type_derived', 'currency', 'ALE'],
            how='left'
        )

        self.output['rca_bookv'] = np.where(
            self.output['AP_CODE'] == '8475',
            base_ale['rca_bookv'].fillna(
                0) + opposite_ale['rca_bookv'].fillna(0),
            base_ale['rca_bookv'].fillna(
                0) - opposite_ale['rca_bookv'].fillna(0)
        )

        return self

    def get_interest(self):

        interest_sums = (self.rt30_rt32
                         .groupby(['利息', 'currency'])['rca_accrint']
                         .sum()
                         .reset_index())

        interest_result = self.output.merge(
            interest_sums,
            left_on=['AP_CODE', 'CCY'],
            right_on=['利息', 'currency'],
            how='left'
        )

        self.output['rca_accrint'] = interest_result['rca_accrint'].fillna(0)

        return self

    def get_deferred_fee(self):

        deferred_sums = (self.rt30_rt32
                         .groupby(['currency'])['rca_deferred_fee']
                         .sum()
                         .reset_index())

        deferred_result = self.output.merge(
            deferred_sums,
            left_on=['CCY'],
            right_on=['currency'],
            how='left'
        )

        self.output['rca_deferred_fee'] = np.where(
            self.output['AP_CODE'] == '8475',
            deferred_result['rca_deferred_fee'].fillna(0),
            0
        )

        return self

    def get_mtm(self):

        mtm_sums = (self.rt30_rt32
                    .groupby(['估值', 'currency'])
                    .agg({
                        'rca_mtm_negative': 'sum',
                        'rca_mtm_positive': 'sum'
                    })
                    .reset_index())

        mtm_result = self.output.merge(
            mtm_sums,
            left_on=['AP_CODE', 'CCY'],
            right_on=['估值', 'currency'],
            how='left'
        )
        self.output['rca_mtm'] = (
            mtm_result['rca_mtm_negative'].fillna(0) +
            mtm_result['rca_mtm_positive'].fillna(0)
        )

        return self

    def get_adjustment(self):

        group_sum = (self.output[self.output['AP_CODE'].isin(['7448', '8578'])]
                     .groupby('CCY', as_index=False)
                     .agg(Adjustment=('Total', 'sum'))
                     )

        self.output = self.output.merge(
            group_sum,
            on='CCY',
            how='left'
        )

        self.output['Adjustment'] = np.where(
            self.output['AP_CODE'] == '7271',
            self.output['Adjustment'],
            0
        )

        return self

    def get_rt30_total(self):

        self.output['rt30_total'] = self.output[
            ['rca_bookv', 'rca_accrint', 'rca_deferred_fee', 'rca_mtm', 'Adjustment']].sum(axis=1)

        return self

    def get_diff(self):

        is_7448_8578 = self.output['AP_CODE'].isin(['7448', '8578'])
        is_8475 = self.output['AP_CODE'] == '8475'
        is_bls_lia = self.output['COA'].str.startswith('BLS-LIA')
        is_bls_ast = self.output['COA'].str.startswith('BLS-AST')

        conditions = [
            is_7448_8578,
            is_8475 | is_bls_lia,
            is_bls_ast
        ]

        values = [
            0,
            self.output['rt30_total'] - self.output['Total'],
            self.output['rt30_total'] + self.output['Total']
        ]

        values_desc = [
            0,
            'rt30 - mis',
            'rt30 + mis'
        ]

        self.output['Diff'] = np.select(
            conditions,
            values,
            default=np.nan
        )

        self.output['Diff'] = self.output['Diff'].round(1)
        self.output['Diff_Desc'] = np.select(
            conditions,
            values_desc,
            default=np.nan
        )

        return self

    def get_counterparty(self):

        self.rt30_rt32['核算码CCY'] = self.rt30_rt32['currency'].fillna(
            'NA') + self.rt30_rt32['deal_type_derived'].fillna('NA')
        self.rt30_rt32['利息CCY'] = self.rt30_rt32['currency'].fillna(
            'NA') + self.rt30_rt32['利息'].fillna('NA')

        # col i
        lookup_interest_ccy = (self.rt30_rt32
                               .drop_duplicates(subset=['利息CCY'], keep='first')
                               .set_index('利息CCY')['Key']
                               .to_dict()
                               )

        # col j
        lookup_accounting_ccy = (self.rt30_rt32
                                 .drop_duplicates(subset=['核算码CCY'], keep='first')
                                 .set_index('核算码CCY')['Key']
                                 .to_dict()
                                 )

        def get_result(row):
            ap_code = row['AP_CODE']
            ccy = row['CCY']
            if ap_code == '7451':
                return lookup_interest_ccy.get(ccy + "7431")
            elif ap_code in ['7448', '8578']:
                return lookup_accounting_ccy.get(ccy + "7271")
            elif ap_code == '8451':
                return lookup_accounting_ccy.get(ccy + "7121")
            elif ap_code == '8453':
                return (
                    lookup_accounting_ccy.get(ccy + "7217") or
                    lookup_accounting_ccy.get(ccy + "7216") or
                    lookup_accounting_ccy.get(ccy + "7211")
                )
            else:
                return (
                    lookup_accounting_ccy.get(ccy + ap_code) or
                    lookup_interest_ccy.get(ccy + ap_code)
                )

        self.output['Vis-à-vis counterparty sector'] = self.output.apply(
            get_result, axis=1)
        self.output['Vis-à-vis country'] = self.output['Vis-à-vis counterparty sector'].str[-2:]

        return self

    def get_risk_in(self):

        # Create mapping dictionaries
        lookup_interest_ccy = self.rt30_rt32.set_index('利息CCY')[
            'Risk_in'].to_dict()
        lookup_accounting_ccy = self.rt30_rt32.set_index('核算码CCY')[
            'Risk_in'].to_dict()

        def get_result(row):
            ap_code = row['AP_CODE']
            ccy = row['CCY']

            if ap_code == '7451':
                return lookup_interest_ccy.get(ccy + "7431", None)
            elif ap_code in ['7448', '8578']:
                return lookup_accounting_ccy.get(ccy + "7211", None)
            elif ap_code == '8451':
                return lookup_accounting_ccy.get(ccy + "7121", None)
            elif ap_code == '8453':
                # Try 7211 first, then 7216
                return (
                    lookup_accounting_ccy.get(ccy + "7211", None) or
                    lookup_accounting_ccy.get(ccy + "7216", None)
                )
            else:
                # Try J column first (核算码CCY), then I column (利息CCY)
                return (
                    lookup_accounting_ccy.get(ccy + ap_code, None) or
                    lookup_interest_ccy.get(ccy + ap_code, None)
                )

        self.output['Risk_in'] = self.output.apply(get_result, axis=1)

        return self

    def get_impact(self):
        # Group and sum for bookv and deferred_fee (using deal_type_derived)
        deal_sums = (self.rt30_rt32
                     .groupby(['deal_type_derived', 'currency', 'ALE'])
                     .agg({
                         'rca_bookv': 'sum',
                         'rca_deferred_fee': 'sum'
                     })
                     .reset_index())

        # Group and sum for accrint (using 利息)
        interest_sums = (self.rt30_rt32
                         .groupby(['利息', 'currency', 'ALE'])['rca_accrint']
                         .sum()
                         .reset_index())

        def get_total_by_ale(ale_value='A'):
            # Calculate sums for given ALE value
            results = self.output[['AP_CODE', 'CCY']].merge(
                deal_sums[deal_sums['ALE'] == ale_value],
                left_on=['AP_CODE', 'CCY'],
                right_on=['deal_type_derived', 'currency'],
                how='left',
                suffixes=('', '_deal')
            ).merge(
                interest_sums[interest_sums['ALE'] == ale_value],
                left_on=['AP_CODE', 'CCY'],
                right_on=['利息', 'currency'],
                how='left',
                suffixes=('', '_interest')
            )

            return (
                results['rca_bookv'].fillna(0) +
                results['rca_deferred_fee'].fillna(0) +
                results['rca_accrint'].fillna(0)
            )

        # Calculate results for both 'A' and 'L'
        self.output['AL混乱对730.1A的影响'] = np.where(
            self.output['ALE-反方向'] == 'A',
            get_total_by_ale('A'),
            get_total_by_ale('L')
        )

        self.output['AL混乱对730.1L的影响'] = np.where(
            self.output['ALE-反方向'] == 'A',
            get_total_by_ale('A'),
            get_total_by_ale('L')
        )

        return self

    def get_data(self):
        return self.output

    def process_all(self):
        return (self
                .get_rca_bookv()
                .get_interest()
                .get_deferred_fee()
                .get_mtm()
                .get_adjustment()
                .get_rt30_total()
                .get_diff()
                .get_counterparty()
                .get_risk_in()
                .get_impact()
                .get_data())


class OBcheck:
    def __init__(self, mis_srs, facility, df_731b):
        self.mis_srs = mis_srs.copy()
        self.facility = facility.copy()
        self.df_731b = df_731b.result['Part E'].copy()

    def pivot_mis_srs(self, guarantee, checking):
        """
        Pivots and aggregates MIS-SRS and facility data for a given guarantee type.

        Args:
            guarantee (str): The guarantee type to filter on ('G' or 'F')

        Returns:
            pd.DataFrame: A DataFrame containing:
                - CCY: Currency code
                - Sum_AUD_Equivalent: Sum of AUD equivalent amounts from MIS-SRS
                - Facility: Sum of OBS amounts from facility data
                - diff: Difference between Sum_AUD_Equivalent and Facility
        """
        type_dict = {
            'G': 'Guarantees Checking',
            'F': 'Credit commitments Checking'
        }

        df_mis_agg = self.mis_srs[self.mis_srs['G'] == guarantee]\
            .groupby(['CCY'])\
            .agg(Sum_AUD_Equivalent=('AUD Equivalent', 'sum'))
        df_mis_agg.loc['Grand Total'] = df_mis_agg['Sum_AUD_Equivalent'].sum(
            numeric_only=True).round(1)
        df_mis_agg.loc['731.3B'] = self.df_731b[checking].sum(
            numeric_only=True).round(1)
        df_mis_agg.loc[type_dict[guarantee]
                       ] = df_mis_agg.loc['731.3B'] + df_mis_agg.loc['Grand Total']

        df_facility_agg = self.facility[self.facility['Guarantee'] == guarantee]\
            .rename(columns={'currency': 'CCY'})\
            .groupby(['CCY'])\
            .agg(Facility=('OBS amount', 'sum'))

        result = df_mis_agg.merge(
            df_facility_agg, on='CCY', how='left').reset_index()
        result['diff'] = result['Sum_AUD_Equivalent'] + result['Facility']

        return result

    def process_all(self):
        res_g = self.pivot_mis_srs('G', 'Guarantees')
        res_f = self.pivot_mis_srs('F', 'Credit commitments')

        res_g.columns = pd.MultiIndex.from_product([['G'], res_g.columns])
        res_f.columns = pd.MultiIndex.from_product([['F'], res_f.columns])

        output = pd.concat([
            res_g,
            res_f], axis=1)

        return output


class DervsGL:
    TABLES = {
        "1": ["7444", "7801", "7802"],
        "2": ["8576", "8801", "8802"],
        "3": ["7444", "7804", "7805"],
        "4": ["8576", "8804", "8805"],
        "5": [
            "7342", "7811", "7812", "7814", "7815", "7816", "7817", "7818",
            "7823", "7830", "7831", "7832", "7833", "7834", "7835", "7836"],
        "6": [
            "8342", "8811", "8812", "8814", "8815", "8816", "8817", "8818",
            "8823", "8830", "8831", "8832", "8833", "8834", "8835", "8836"
        ]
    }

    def __init__(self, mapper, rt30_rt32, mis_srs) -> None:
        self.mapper = mapper
        self.result = self._init_tables()
        self.rt30_rt32 = rt30_rt32.copy()
        self.mis_srs = mis_srs.copy()

    def map_ap_name(self, data):

        return self.mapper.apply_mapping(
            data,
            self.mapper.all_mappings["核算码Mapping1"],
            keys={"main": "核算码", "mapping": "AP Code"},
            values={"Suffix Name": "核算码名称"},
            sheet_name="核算码Mapping1"
        )

    def _init_tables(self):
        data = [(group, code) for group, codes in self.TABLES.items()
                for code in codes]
        data = pd.DataFrame(data, columns=['group', '核算码'])
        result = self.map_ap_name(data)
        return result

    def add_rca_mtm(self):
        rca_mtm = self.rt30_rt32.groupby('估值').agg(
            rca_mtm_negative=('rca_mtm_negative', 'sum'),
            rca_mtm_positive=('rca_mtm_positive', 'sum')
        ).sum(axis=1)\
            .round(1)\
            .reset_index()\
            .rename(columns={0: 'rca_mtm'})

        self.result = pd.merge(
            self.result,
            rca_mtm,
            left_on='核算码',
            right_on='估值',
            how='left'
        ).drop(columns=['估值'])

        return self

    def add_dm010(self):
        """Add DM010 calculations based on MIS-SRS data with special conditions.

        Args:
            mis_srs (pd.DataFrame): MIS-SRS data containing columns 'AP_CODE', 'AUD Equivalent', and 'rv_coa'
        """
        sums = []
        mis_agg = self.mis_srs[self.mis_srs['AP_CODE']
                               .isin(self.result['核算码'].drop_duplicates())]\
            .groupby(['AP_CODE', 'PROD_CODE'], as_index=False)['AUD Equivalent']\
            .sum()
        for _, row in self.result.iterrows():
            ap_code = row['核算码']
            group = row['group']

            # special cases
            if ap_code == '7444' and group == '1':
                mask = (mis_agg['AP_CODE'] == ap_code) & (
                    mis_agg['PROD_CODE'] == '6108')
            elif ap_code == '8576' and group == '2':
                mask = (mis_agg['AP_CODE'] == ap_code) & (
                    mis_agg['PROD_CODE'] == '6108')
            elif ap_code == '7444' and group == '3':
                mask = (mis_agg['AP_CODE'] == ap_code) & (
                    mis_agg['PROD_CODE'] == '6114')
            elif ap_code == '8576' and group == '4':
                mask = (mis_agg['AP_CODE'] == ap_code) & (
                    mis_agg['PROD_CODE'] == '6114')
            else:
                # Default case
                mask = mis_agg['AP_CODE'] == ap_code

            sums.append(mis_agg.loc[mask, 'AUD Equivalent'].sum().round(1))

        self.result['DM010'] = sums
        return self

    def add_diff(self):

        self.result['Diff'] = np.where(
            self.result['group'].isin(['1', '3', '5']),
            self.result['rca_mtm'].fillna(0) + self.result['DM010'].fillna(0),
            self.result['rca_mtm'].fillna(0) - self.result['DM010'].fillna(0)
        )
        return self

    def get_results(self):
        output = {}
        for key, group in self.result.groupby('group'):
            total_row = pd.DataFrame(
                [{'核算码': 'TOTAL', 'Diff': group['Diff'].sum()}])
            group = pd.concat([group, total_row])
            output[key] = group\
                .drop(columns=['group'])\
                .reset_index(drop=True)

        return output

    def process_all(self):
        return self\
            .add_rca_mtm()\
            .add_dm010()\
            .add_diff()\
            .get_results()

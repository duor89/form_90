import pandas as pd
import numpy as np
from utils import ReportingLogger, log_errors


class ReportAggregator731AL:
    """
    Aggregator for Bank of China 731 reporting format.
    Handles the aggregation of financial data into required reporting categories.

    Attributes:
        logger: Logging instance for tracking aggregation processes
        data: Copy of input DataFrame containing raw financial data
    """

    # Class-level constants for better maintenance
    _threshold = 1012000

    def __init__(self, data: pd.DataFrame):
        self.logger = ReportingLogger(__name__, "reporting.log").logger
        self.data = data.copy()  # Create copy to prevent modifying original data
        self.logger.info("Initializing ReportAggregator")

    def _compute_sum_for_category(self, group: pd.DataFrame, category: list,
                                  asset_type: list, value_column: str,
                                  additional_condition: callable = None) -> float:
        """
        Helper function to calculate sum for a specific category and asset type.

        Args:
            group: DataFrame group to process
            category: List of category codes
            asset_type: List of asset types
            value_column: Column name to sum
            additional_condition: Optional callable that returns a boolean Series for additional filtering
        """
        mask = (group['731.1分类'].isin(category)) & (
            group['ALE'].isin(asset_type))

        if additional_condition is not None:
            mask = mask & additional_condition(group)

        return group.loc[mask, value_column].sum()

    def calculate_731a_sums(self, group: pd.DataFrame) -> pd.Series:
        """
        Calculates sums for assets report (731.1a).
        Categories: (4) Loans, (5) Securities, (6) Other assets
        """
        # Calculate loans and deposits (category 4, standard assets)
        loans = self._compute_sum_for_category(
            group, ['(4)'], ['A'], 'rca_bookv')

        # Calculate debt securities holdings (category 5, using market value)
        securities = self._compute_sum_for_category(
            group, ['(5)'], ['A'], 'rca_marketv')

        # Other assets components
        other_assets = (
            # Standard assets book value
            self._compute_sum_for_category(
                group, ['(6)'], ['A'], 'rca_bookv') +
            # Accrued interest
            self._compute_sum_for_category(
                group, ['(4)', '(5)'], ['A'], 'rca_accrint') +
            # Off-balance sheet items
            self._compute_sum_for_category(
                group, ['(6)'], ['OB'], 'rca_mtm_positive')
        )

        total = loans + securities + other_assets

        return pd.Series({
            'Loans and deposits': loans,
            'Holdings of debt securities': securities,
            'Other assets': other_assets,
            'Total claims': total
        })

    def calculate_731l_sums(self, group: pd.DataFrame) -> pd.Series:
        """
        Calculates sums for liabilities report (731.1l).
        Categories: (4) Loans, (7) Securities, (8) Other liabilities
        """
        # Standard loans and deposits
        loans = self._compute_sum_for_category(
            group, ['(4)'], ['L'], 'rca_bookv')

        # Securities by maturity
        less_1y = self._compute_sum_for_category(
            group, ['(7)'], ['L'], 'rca_bookv',
            lambda df: df['rv_mat_remaining'] <= self._threshold
        )

        more_1y = self._compute_sum_for_category(
            group, ['(7)'], ['L'], 'rca_bookv',
            lambda df: df['rv_mat_remaining'] > self._threshold
        )

        securities_total = less_1y + more_1y

        # Other liabilities components
        other_liabilities = (
            # Standard book value
            self._compute_sum_for_category(
                group, ['(8)'], ['L'], 'rca_bookv') +
            # Accrued interest
            self._compute_sum_for_category(
                group, ['(4)', '(7)'], ['L'], 'rca_accrint') +
            # Deferred fees
            self._compute_sum_for_category(
                group, ['(8)'], ['L'], 'rca_deferred_fee') +
            # Negative MTM
            self._compute_sum_for_category(
                group, ['(8)'], ['L'], 'rca_mtm_negative')
        )

        total = loans + securities_total + other_liabilities

        return pd.Series({
            'Loans and deposits': loans,
            'Issue of debt securities: remaining maturity <= 1 year': less_1y,
            'Issue of debt securities: remaining maturity > 1 year': more_1y,
            'Issue of debt securities: Total': securities_total,
            'Other liabilities': other_liabilities,
            'Total liabilities': total
        })

    def _generate_report(self, asset_types: list[str],
                         calculation_method: callable) -> pd.DataFrame:
        """Helper method to generate reports with common logic"""
        df_filtered = self.data[self.data.ALE.isin(asset_types)]

        if df_filtered.empty:
            return pd.DataFrame()

        return df_filtered\
            .groupby(
                ['731 CCY', 'Vis-à-vis counterparty sector', 'Vis-à-vis country'],
                as_index=False
            )\
            .apply(calculation_method)\
            .rename(columns={
                '731 CCY': 'Currency',
            })

    def add_adjustment(self, result, ag_gl, asset_type):
        """
        Calculate adjustments for assets or liabilities.

        Args:
            result: DataFrame with aggregated results
            ag_gl: DataFrame with GL adjustments
            asset_type: 'A' for assets or 'L' for liabilities

        Returns:
            Series containing adjustments aligned with result index
        """
        # Filter GL data for the specified asset type
        gl_filtered = ag_gl[ag_gl['ALE'] == asset_type]

        # Calculate base adjustment (adj1)
        adj1 = gl_filtered.groupby(
            'Vis-à-vis counterparty sector')['Diff'].sum()

        if asset_type == 'L':
            adjustment = -adj1
        else:
            # For assets, calculate additional adjustment (adj2)
            adj2 = 2 * gl_filtered[gl_filtered['AP_CODE'] == '8475']\
                .groupby('Vis-à-vis counterparty sector')['Diff'].sum()
            adjustment = -(adj1.subtract(adj2, fill_value=0))

        adj_df = adjustment.reset_index()
        adj_df.columns = ['Vis-à-vis counterparty sector', 'Adjustment']

        join_key = result[['Currency', 'Vis-à-vis counterparty sector', 'Vis-à-vis country']]\
            .agg('|'.join, axis=1)

        return result.merge(
            adj_df,
            left_on=join_key,
            right_on='Vis-à-vis counterparty sector',
            how='left'
        )['Adjustment'].round(1)

    @log_errors
    def generate_731a(self, ag_gl) -> pd.DataFrame:
        """Generates the 731.1a assets report"""
        self.logger.info("Starting 731.1a assets report aggregation")
        try:
            result = self._generate_report(
                asset_types=['A', 'OB'],
                calculation_method=self.calculate_731a_sums
            )
            result['Adjustment'] = self.add_adjustment(result, ag_gl, 'A')
            self.logger.info("731.1a assets report completed successfully")
            return result
        except Exception as e:
            self.logger.error(f"Error during 731.1a aggregation: {str(e)}")
            raise

    @log_errors
    def generate_731l(self, ag_gl) -> pd.DataFrame:
        """Generates the 731.1l liabilities report"""
        self.logger.info("Starting 731.1l liabilities report aggregation")
        try:
            result = self._generate_report(
                asset_types=['L', 'OB'],
                calculation_method=self.calculate_731l_sums
            )
            result['Adjustment'] = self.add_adjustment(result, ag_gl, 'L')

            self.logger.info(
                "731.1l liabilities report completed successfully")
            return result
        except Exception as e:
            self.logger.error(f"Error during 731.1l aggregation: {str(e)}")
            raise


class ReportAggregator731B:

    def __init__(self, mapper=None, rt30=None):
        self.logger = ReportingLogger(__name__, "reporting.log").logger
        self.mapper = mapper
        self.rt30 = rt30.copy()
        self.output = self.get_countries()

    def get_countries(self) -> str:

        # load country code from mapping files
        country = self.mapper.all_mappings["country_code"]\
            .rename(columns={'country_code': 'Vis-à-vis country', 'country name': 'Vis-à-vis country name'})

        # only keep the country code in rt30_rt32
        # country = country[country['Vis-à-vis country'].isin(self.rt30['Vis-à-vis country'])]

        return country

    def add_blank_column(self):
        blank_column = pd.DataFrame(
            [None] * len(self.output), columns=[" "])
        self.output = pd.concat([self.output, blank_column], axis=1)

        return self

    def get_gl_adj(self, algl):

        # algl['diff'] = algl['diff']
        gl_diff = algl[algl['ALE'] == 'A']\
            .groupby('Vis-à-vis country')['Diff'].sum().reset_index()
        gl_diff['Diff'] = - gl_diff['Diff'].round()

        self.output = (self.output
                       .merge(gl_diff, on='Vis-à-vis country', how='left')
                       .rename(columns={'Diff': 'GL adj'})
                       )

        return self

    def calculate_sum_for_country(self, condition, country_column='Vis-à-vis country'):

        base_mask = self.rt30['ALE'] == 'A'
        base_mask &= condition

        rt30_filtered = self.rt30[base_mask]
        rt30_agg = (rt30_filtered
                    .groupby(country_column)
                    .agg({
                        'rca_bookv': 'sum',
                        'rca_accrint': 'sum',
                        'rca_deferred_fee': 'sum',
                    })
                    .reset_index()
                    .rename(columns={
                        country_column: 'Vis-à-vis country'
                    })
                    )

        sum_8754 = (
            rt30_filtered[rt30_filtered['deal_type_derived'] == '8754']
            .groupby(country_column)['rca_bookv']
            .sum()
            .reset_index()
            .rename(columns={
                'rca_bookv': '8754_bookv',
                country_column: 'Vis-à-vis country'
            })
        )

        result = self.output.merge(
            rt30_agg, on='Vis-à-vis country', how='left')
        result = result.merge(sum_8754, on='Vis-à-vis country',
                              how='left').fillna({'8754_bookv': 0})

        output = (
            result['rca_bookv'] -
            2 * result['8754_bookv'] -
            result['rca_deferred_fee'] +
            result['rca_accrint']
        )

        return output

    def add_maturity_bucket_adjustment(self):

        rt30_filtered = self.rt30[
            (self.rt30['ALE'] == 'A') &
            (self.rt30['rv_mat_remaining'] > 1060000)
        ]

        rt30_agg = rt30_filtered\
            .groupby('Vis-à-vis country')\
            .agg(maturity_bucket_adjustment=('rca_deferred_fee', 'sum'))\
            .reset_index()

        return - self.output.merge(rt30_agg, on='Vis-à-vis country', how='left')['maturity_bucket_adjustment']

    def get_part_a(self) -> pd.DataFrame:

        output = self.output.copy()
        params = {
            '<=3 mths': {'start': 1000000, 'end': 1003000},
            '3m-12m': {'start': 1003000, 'end': 1012000},
            '1y-2y': {'start': 1012000, 'end': 1024000},
            '2y-5y': {'start': 1024000, 'end': 1060000},
            '5y+': {'start': 1060000, 'end': float('inf')}
        }

        for k, v in params.items():
            condition = (
                (self.rt30['rv_mat_remaining_derived'] > v['start']) &
                (self.rt30['rv_mat_remaining_derived'] <= v['end'])
            )
            output[k] = self.calculate_sum_for_country(condition)

        output['Maturity bucket Adjustment'] = self.add_maturity_bucket_adjustment()
        output['<=3 mths'] = output['<=3 mths'] + \
            output['GL adj']
        output['5y+'] = output['5y+'] + \
            output['Maturity bucket Adjustment']
        output['Total'] = self.calculate_sum_for_country(
            True) + output['GL adj']
        output['Unallocated'] = output['Total'] - output['<=3 mths'] - \
            output['3m-12m'] - output['1y-2y'] - \
            output['2y-5y'] - output['5y+']

        return output

    def get_part_b(self):
        output = self.output.copy()
        params = {
            'Banking institutions':
                {'=': r'^Banking:.*', '<>': 'Banking: central banks'},
            'Central banks':
                {'=': 'Banking: central bank', '<>': None},
            'General government':
                {'=': 'General government', '<>': None},
            'Non-banking financial institutions':
                {'=': 'Non-banking financial institutions', '<>': None},
            'Non-financial corporations':
                {'=': 'Non-financial corporations', '<>': None},
            'Households and non-profits':
                {'=': 'Households and non-profits', '<>': None},
            'Unallocated':
                {'=': 'Unallocated', '<>': None}
        }

        for k, v in params.items():
            condition = (
                (self.rt30['Vis-à-vis counterparty sector'].str.contains(v['='])) &
                (self.rt30['Vis-à-vis counterparty sector'] != v['<>'])
            )
            output[k] = self.calculate_sum_for_country(condition)

        output['Non-financial corporations'] = \
            output['Non-financial corporations'] + \
            output['GL adj']

        output['Total international claims'] = self.calculate_sum_for_country(
            True) + output['GL adj']
        output['Check'] = \
            (output['Total international claims'] -
             (output[
                 ['Banking institutions', 'Central banks', 'General government',
                  'Non-banking financial institutions', 'Non-financial corporations',
                  'Households and non-profits', 'Unallocated']
             ].fillna(0).sum(axis=1))).round()

        return output.drop(columns=['Vis-à-vis country'])

    def get_part_c(self):

        output = self.output.copy()
        params = {
            'Outward risk transfer': {'risk_transfer': 'Y', 'country_column': 'Vis-à-vis country'},
            'Inward risk transfer': {'risk_transfer': 'Y', 'country_column': 'Risk_in'},
        }

        for k, v in params.items():
            condition = (self.rt30['Risk Transfer'] == v['risk_transfer'])
            output[k] = self.calculate_sum_for_country(
                condition, v['country_column'])

        output['Net transfer of risk to the ultimate borrower'] = output['Inward risk transfer'].fillna(
            0) - output['Outward risk transfer'].fillna(0)

        return output.drop(columns=['Vis-à-vis country', 'GL adj'])

    def get_part_d(self):

        output = self.output.copy()

        params = {
            'Banking institutions':
                {'=': r'^Banking:.*', '<>': 'Banking: central banks'},
            'Central banks':
                {'=': 'Banking: central bank', '<>': None},
            'General government':
                {'=': 'General government', '<>': None},
            'Non-banking financial institutions':
                {'=': 'Non-banking financial institutions', '<>': None},
            'Non-financial corporations':
                {'=': 'Non-financial corporations', '<>': None},
            'Households and non-profits':
                {'=': 'Households and non-profits', '<>': None},
            'Unallocated':
                {'=': 'Unallocated', '<>': None}
        }

        for k, v in params.items():
            condition = (
                (self.rt30['Risk in Counterparty'].str.contains(v['='])) &
                (self.rt30['Risk in Counterparty'] != v['<>'])
            )
            output[k] = self.calculate_sum_for_country(
                condition, 'Risk_in')

        output['Non-financial corporations'] += output['GL adj']
        output['Total international claims'] = \
            self.calculate_sum_for_country(True, 'Risk_in') + \
            output['GL adj']

        output['Check'] = \
            (output['Total international claims'] -
             (output[
                 ['Banking institutions', 'Central banks', 'General government',
                  'Non-banking financial institutions', 'Non-financial corporations',
                  'Households and non-profits', 'Unallocated']
             ].fillna(0).sum(axis=1))).round()

        return output.drop(columns=['Vis-à-vis country', 'GL adj'])

    def get_part_e(self, facility):

        output = self.output.copy()

        derivative = self.rt30[(self.rt30['ALE'] == 'OB')]\
            .groupby('Risk_in')['rca_mtm_positive']\
            .sum()\
            .reset_index()\
            .rename(columns={'Risk_in': 'Vis-à-vis country'})

        guarantees = facility[(facility['Guarantee'] == 'G')]\
            .groupby('Ultimate risk-bearing countries-RMD')['OBS amount']\
            .sum()\
            .reset_index()\
            .rename(columns={'Ultimate risk-bearing countries-RMD': 'Vis-à-vis country'})

        credit_commitments = facility[(facility['Guarantee'] == 'F')]\
            .groupby('Ultimate risk-bearing countries-RMD')['OBS amount']\
            .sum()\
            .reset_index()\
            .rename(columns={'Ultimate risk-bearing countries-RMD': 'Vis-à-vis country'})

        output['Derivative contracts'] = output.merge(
            derivative, on='Vis-à-vis country', how='left')['rca_mtm_positive']
        output['Guarantees'] = output.merge(
            guarantees, on='Vis-à-vis country', how='left')['OBS amount']
        output['Credit commitments'] = output.merge(
            credit_commitments, on='Vis-à-vis country', how='left')['OBS amount']

        return output.drop(columns=['GL adj'])

    def get_part_e_adj(self, ob_check, part_e):

        part_e.loc[part_e['Vis-à-vis country'] == 'AU',
                   'Guarantees adj'] = -ob_check['G']['diff'].sum().round(2)
        part_e.loc[part_e['Vis-à-vis country'] == 'AU',
                   'Guarantees adj'] = -ob_check['F']['diff'].sum().round(2)

        return part_e.drop(columns=['Vis-à-vis country'])

    def add_top_header(self, df, header, start=2):
        multi_index = [('' if col not in df.columns[start:]
                        else header, col) for col in df.columns]
        df.columns = pd.MultiIndex.from_tuples(multi_index)

    def pre_ob_process(self, df_algl, facility):
        obj = self.get_gl_adj(df_algl)
        self.result = {
            'Part A': obj.get_part_a(),
            'Part B': obj.get_part_b(),
            'Part C': obj.get_part_c(),
            'Part D': obj.get_part_d(),
            'Part E': obj.get_part_e(facility)
        }
        return self

    def post_ob_process(self, ob_check):
        self.result['Part E'] = self.get_part_e_adj(
            ob_check, self.result['Part E'])

        for k, v in self.result.items():
            if k == "Part A":
                self.add_top_header(v, k, 3)
            else:
                self.add_top_header(v, k)

        result = pd.concat(self.result.values(), axis=1)

        return result

    def post_ob_process_dict(self, ob_check):
        self.result['Part E'] = self.get_part_e_adj(
            ob_check, self.result['Part E'])

        result = {}
        for part, df in self.result.items():
            float_cols = df.select_dtypes('float').columns
            df[float_cols] = (df[float_cols]/1000000).round(3)
            result[part] = df[df[float_cols].fillna(0).any(axis=1) > 0]

        return result

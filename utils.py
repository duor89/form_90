import logging
import logging.config
import traceback
from functools import wraps
from typing import Callable, Any

import warnings
warnings.filterwarnings('ignore')


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
    'nationality': str,
    'deal_type_derived': str,
    '利息': str,
    '估值': str
}

na_values = [
    '-1.#IND', '1.#QNAN', '1.#IND', '-1.#QNAN', '#N/A N/A', '#N/A', 'N/A',
    'n/a', '<NA>', '#NA', 'NULL', 'null', 'NaN', '-NaN', 'nan', '-nan', 'None', ''
]

rt30_cols = ['ide_internal_party_ref', 'ide_linkage_ref', 'ide_linkage_type',
             'ide_sourcesys_ref', 'lot_type_fk', 'rca_accrint', 'rca_bookv',
             'rca_marketv', 'rca_prov_coll', 'rca_prov_indi', 'rv_coa',
             'rv_cpty_type', 'rv_rel_party_type', 'rv_currency_sub_group',
             'rv_mat_original', 'rv_mat_remaining', 'rca_deferred_fee',
             'rca_mtm_negative', 'rca_mtm_positive', 'entity', 'deal_id',
             'customer_nr', 'nationality', 'domicile', 'customer_legal_name',
             'deal_type', 'currency', 'tfi_id', 'source_table', 'value_date',
             'maturity_date', 'source_system']

facility_cols = ['entity', 'facility_nr', 'customer_nr', 'customer_legal_name',
                 'deal_type', 'currency', 'OBS amount', 'Counterparty type', 'Domicile',
                 'source_system']

rmd_cols = ['ide_linkage_ref', 'customer_nr', 'Vis-à-vis counterparty sector',
           'ide_sourcesys_ref', 'rca_bookv', 'customer_legal_name', 'nationality', 'domicile',
           '本期最终风险承担国家 Ultimate risk-bearing countries', '本期最终风险承担方性质Description',
           '上期最终风险承担国', '上期最终风险承担方性质Description']

mis_cols = ['DATE', 'ENTITY', 'DBU OBU', 'STATE', 'ORGANISATION CODE',
            'RESP CENTER', 'DEAL_ID', 'AP_CODE', 'AP_NAME', 'SUB CODE', 'PROD_CODE',
            'A/L/E', 'MGT ITEM', 'SOURCE_SYSTEM', 'p1', 'p2', 'p3', 'p4', '管控类型',
            '管控部门', '前中后台', 'P DEPT', 'CURRENCY', 'Original Amount',
            'AUD Equivalent', 'yearly_average_balance_ori',
            'yearly_average_balance_aud', 'monthly_average_balance_ori',
            'monthly_average_balance_aud', 'Last mth end YTD-ORI',
            'Last mth end YTD-AUD', 'Last year end YTD-ORI',
            'Last year end YTD-AUD', 'Last year mth end YTD-ORI',
            'Last year mth end YTD-AUD', 'Budget']


def setup_logging(name: str, log_file: str = None) -> None:
    """Setup logging configuration"""
    config = {
        'version': 1,
        'disable_existing_loggers': False,
        'formatters': {
            'console': {
                'format': '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
            },
            'file': {
                'format': '%(asctime)s - %(name)s - %(levelname)s - %(message)s - [%(filename)s:%(lineno)d]'
            }
        },
        'handlers': {
            'console': {
                'class': 'logging.StreamHandler',
                'level': 'INFO',
                'formatter': 'console'
            }
        },
        'loggers': {
            name: {
                'level': 'INFO',
                'handlers': ['console'],
                'propagate': False
            }
        }
    }

    if log_file:
        config['handlers']['file'] = {
            'class': 'logging.FileHandler',
            'filename': log_file,
            'level': 'WARNING',
            'formatter': 'file',
            'encoding': 'utf-8'
        }
        config['loggers'][name]['handlers'].append('file')

    logging.config.dictConfig(config)


class ReportingLogger:
    """Custom logger for the reporting system"""

    def __init__(self, name: str, log_file: str = None):
        setup_logging(name, log_file)
        self.logger = logging.getLogger(name)


def log_errors(func: Callable) -> Callable:
    """Decorator to log function errors"""
    @wraps(func)
    def wrapper(*args, **kwargs) -> Any:
        try:
            return func(*args, **kwargs)
        except Exception as e:
            logger = logging.getLogger(func.__module__)
            logger.error(f"Error in {func.__name__}: {str(e)}")
            logger.debug(f"Traceback: {traceback.format_exc()}")
            raise
    return wrapper

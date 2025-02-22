from pathlib import Path
import pandas as pd
from mapping import ReportMapper
from validation import AGvsGL, DervsGL, OBcheck
from aggregation import ReportAggregator731AL, ReportAggregator731B
from utils import ReportingLogger, schema_dict, na_values
from post_review import perform_record_actions, load_logs, reapply_mappings
import sys
from typing import Union, Dict
logger = ReportingLogger(__name__, "reporting.log").logger


def load_data(file_path: Path) -> dict:
    """Load data from Excel file"""
    return pd.read_excel(file_path, sheet_name=None, dtype=schema_dict, na_values=na_values)


def process_results(data, mapper, use_dict_output: bool = False) -> tuple:
    """Process validation and aggregation"""
    # AG vs GL validation
    ag_gl = AGvsGL(data['mis_srs'], data['rt30_rt32'])
    ag_gl_res = ag_gl.process_all()

    # Derivatives vs GL validation
    dervs_gl = DervsGL(mapper, data['rt30_rt32'], data['mis_srs'])
    dervs_gl_res = dervs_gl.process_all()

    # 731AL aggregation
    agg_731al = ReportAggregator731AL(data['rt30_rt32'])
    report_731a = agg_731al.generate_731a(ag_gl_res)
    report_731l = agg_731al.generate_731l(ag_gl_res)

    # 731B aggregation
    agg_731b = ReportAggregator731B(mapper, rt30=data['rt30_rt32'])
    report_731b_pre = agg_731b.pre_ob_process(ag_gl_res, data['facility'])

    # ob check
    ob_check = OBcheck(data['mis_srs'], data['facility'], report_731b_pre)
    ob_check_res = ob_check.process_all()

    # 731B post ob check process
    if use_dict_output:
        report_731b = report_731b_pre.post_ob_process_dict(ob_check_res)
    else:
        report_731b = report_731b_pre.post_ob_process(ob_check_res)

    return report_731a, report_731l, report_731b, ag_gl_res, ob_check_res, dervs_gl_res


def save_731b_report(report_731b: Union[pd.DataFrame, Dict[str, pd.DataFrame]], writer):
    """Save 731B report based on its type"""
    if isinstance(report_731b, dict):
        # Handle dictionary output with multiple parts
        for part_name, df in report_731b.items():
            df.to_excel(writer, sheet_name=f'731B_{part_name}', index=False)
    else:
        # Handle single DataFrame output
        report_731b.to_excel(writer, sheet_name='731B')


def main():
    base_path = Path(__file__).parent.parent
    output_path = base_path / 'output'
    logs_path = output_path / 'logs'

    # Parse command line argument
    use_dict_output = len(
        sys.argv) > 1 and sys.argv[1].lower() == '--million-scale'

    try:
        # Load updated data
        logger.info("Loading updated data")
        data = load_data(output_path / 'updated_data.xlsx')

        # Check for manual updates and reprocess if needed
        logs = load_logs(logs_path)
        if not logs['rt30'].empty:
            data['rt30_rt32'], logs['rt30'] = perform_record_actions(
                data['rt30_rt32'], logs['rt30'])
            data = reapply_mappings(data, base_path)

        # Process validations and aggregations
        mapper = ReportMapper(base_path / 'config' / 'RT30_RT32.json')
        report_731a, report_731l, report_731b, ag_gl_res, ob_check_res, dervs_gl_res = process_results(
            data, mapper, use_dict_output)

        logs['al_gl_log'] = ag_gl_res[ag_gl_res['Diff'].round() != 0]

        # Save final reports
        with pd.ExcelWriter(output_path / 'final_reports.xlsx') as writer:
            report_731a.to_excel(writer, sheet_name='731A', index=False)
            report_731l.to_excel(writer, sheet_name='731L', index=False)
            save_731b_report(report_731b, writer)

            ag_gl_res.to_excel(writer, sheet_name='AGvsGL', index=False)
            ob_check_res.to_excel(writer, sheet_name='OBcheck')

            start_row = 0
            for _, table in dervs_gl_res.items():
                table.to_excel(writer, sheet_name="DervsGL",
                               startrow=start_row, index=False)
                start_row += len(table) + 2

        # save logs
        logger.info("Saving validation logs")
        with pd.ExcelWriter(logs_path / 'log.xlsx', mode='a', if_sheet_exists='replace') as writer:
            logs['al_gl_log'].to_excel(
                writer, sheet_name='ALvsGL Log', index=False)
            logs['rt30'].to_excel(writer, sheet_name='RT30 Log', index=False)

        logger.info("Final processing completed successfully")

    except Exception as e:
        logger.error(f"Error in final processing: {e}")
        raise


if __name__ == "__main__":
    main()

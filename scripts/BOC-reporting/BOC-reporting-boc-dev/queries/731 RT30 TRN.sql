drop table if exists #trn

select * into #trn from
(
select 
iba.entity, iba.deal_id, iba.customer_nr,  tc.nationality,tc.domicile,tc.customer_legal_name,iba.deal_type, iba.currency, null as 'tfi_id', 'iba' as 'source_table' ,iba.value_date as 'value_date', iba.maturity_date as 'maturity_date',iba.source_system AS 'source_system'
from 
(select*from ONESUMX..t_trn_interest_bearing_accounts where  start_validity_date<=@reportdate and end_validity_date>=@reportdate and entity=@entity) iba
left join 
(select * from ONESUMX..t_customer where start_validity_date<=@reportdate and end_validity_date>=@reportdate) tc
on tc.customer_nr=iba.customer_nr

union all

select 
tl.entity, tl.deal_id, tl.customer_nr, tc.nationality,tc.domicile,tc.customer_legal_name,tl.deal_type, tl.currency, null as 'tfi_id', 'loan' as 'source_table',tl.value_date  as 'value_date', tl.maturity_date as 'maturity_date',tl.source_system AS 'source_system'
from 
(select * from ONESUMX..t_trn_loan where  start_validity_date<=@reportdate and end_validity_date>=@reportdate and entity=@entity) tl
left join
(select * from ONESUMX..t_customer where start_validity_date<=@reportdate and end_validity_date>=@reportdate) tc
on tc.customer_nr=tl.customer_nr

union all

select tbond.entity, tbond.deal_id, tbond.customer_nr, tc.nationality,tc.domicile,tc.customer_legal_name,tbond.deal_type, tbond.currency, tbond.tfi_id, 'bond' as 'source_table' ,tbond.value_date  as 'value_date',tfibond.maturity_date as 'maturity_date','022' AS 'source_system'
from 
(select * from ONESUMX..t_tfi_trn_bond where start_validity_date<=@reportdate and end_validity_date>=@reportdate and entity=@entity) tbond
left join
(select * from ONESUMX..t_customer where start_validity_date<=@reportdate and end_validity_date>=@reportdate) tc
on tc.customer_nr=tbond.customer_nr
left join
(select * from ONESUMX..t_tfi_bond where start_validity_date<=@reportdate and end_validity_date>=@reportdate and object_origin=@entity) tfibond
on tfibond.tfi_id=tbond.tfi_id

union all

select tforex.entity, 
tforex.deal_id, 
tforex.customer_nr, 
tc.nationality,tc.domicile,tc.customer_legal_name,
tforex.deal_type, 
(case when (tforexv.valuation_type = 'ORI MTM_POSITIVE' or tforexv.valuation_type = 'ORI MTM_NEGATIVE')  then tforexv.currency else 'NA' end) as 'currency',
null as 'tfi_id', 'forex' as 'source_table' ,
tforex.value_date  as 'value_date',
tforex.maturity_date as 'maturity_date',
'022' AS 'source_system'
from 
(select * from ONESUMX..t_trn_forex where start_validity_date<=@reportdate and end_validity_date>=@reportdate and entity=@entity) tforex
left join 
(select * from ONESUMX..t_trn_forex_valuation where valuation_date=@reportdate) tforexv
 on tforexv.deal_id = tforex.deal_id and (tforexv.valuation_type = 'ORI MTM_POSITIVE' or tforexv.valuation_type = 'ORI MTM_NEGATIVE')  
left join
(select * from ONESUMX..t_customer where start_validity_date<=@reportdate and end_validity_date>=@reportdate) tc
on tc.customer_nr=tforex.customer_nr

union all

select toption.entity, 
toption.deal_id, 
toption.customer_nr, 
tc.nationality,tc.domicile,tc.customer_legal_name,
toption.deal_type, 
(case when (toptionv.valuation_type = 'ORI MTM_POSITIVE' or toptionv.valuation_type = 'ORI MTM_NEGATIVE')  then toptionv.currency else 'NA' end) as 'currency', 
null as 'tfi_id', 'option' as 'source_table' ,
toption.value_date  as 'value_date',
topt.maturity_date as 'maturity_date',
'022' AS 'source_system'

from 
(select * from ONESUMX..t_tfi_trn_option where start_validity_date<=@reportdate and end_validity_date>=@reportdate and entity=@entity) toption
left join 
(select * from ONESUMX..t_tfi_trn_option_valuation where valuation_date=@reportdate and entity=@entity and (valuation_type= 'ORI MTM_POSITIVE' or valuation_type = 'ORI MTM_NEGATIVE') ) toptionv
on toptionv.deal_id = toption.deal_id 
left join
(select * from ONESUMX..t_customer where start_validity_date<=@reportdate and end_validity_date>=@reportdate) tc
on tc.customer_nr=toption.customer_nr
left join
(select * from onesumx..t_tfi_option where start_validity_date<=@reportdate and end_validity_date>=@reportdate ) topt
on topt.tfi_id =toption.tfi_id

union all

select tswap.entity, 
tswap.deal_id, 
tswap.customer_nr, 
tc.nationality,tc.domicile,tc.customer_legal_name,
tswap.deal_type, 
(case when (tswapv.valuation_type = 'ORI MTM_POSITIVE' or tswapv.valuation_type = 'ORI MTM_NEGATIVE')  then tswapv.currency else 'NA' end) as 'currency', 
null as 'tfi_id', 
'swap' as 'source_table' ,
tswap.value_date  as 'value_date',
tswap.maturity_date as 'maturity_date',
'022' AS 'source_system'

from 
(select * from ONESUMX..t_trn_swap_ir where start_validity_date<=@reportdate and end_validity_date>=@reportdate and entity=@entity) tswap
left join 
(select * from ONESUMX..t_trn_swap_ir_valuation where valuation_date=@reportdate and entity=@entity and (valuation_type= 'ORI MTM_POSITIVE' or valuation_type = 'ORI MTM_NEGATIVE')) tswapv
on tswapv.deal_id = tswap.deal_id
left join
(select * from ONESUMX..t_customer where start_validity_date<=@reportdate and end_validity_date>=@reportdate) tc
on tc.customer_nr=tswap.customer_nr

union all

select tbackoffice.entity, tbackoffice.deal_id, tbackoffice.customer_nr, tc.nationality,tc.domicile,tc.customer_legal_name,element6 as 'deal_type', tbackoffice.currency,  null as 'tfi_id', 'back_office' as 'source_table' ,'9999-12-31' as 'value_date', '9999-12-31' as 'maturity_date', 'backoffice' AS 'source_system' 

from 
(select * from ONESUMX..t_back_office_balance_boc where balance_date=@reportdate and entity=@entity) tbackoffice
left join
(select * from ONESUMX..t_customer where start_validity_date<=@reportdate  and end_validity_date>=@reportdate ) tc
on tc.customer_nr=tbackoffice.customer_nr

) trn
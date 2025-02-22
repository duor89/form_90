declare @reportdate date
declare @entity int
declare @lottype int;

--###please report date below###--
set @reportdate = '2024-09-30'
set @entity = '106'
set @lottype = '992'---------------lottype--------------
--###input end##--



--------------------------------------RT30 RT32 FEE--------------------------------------------------------

-- drop table if exists #trn

-- select * into #trn from
-- (
-- select 
-- iba.entity, iba.deal_id, iba.customer_nr,  tc.nationality,tc.domicile,tc.customer_legal_name,iba.deal_type, iba.currency, null as 'tfi_id', 'iba' as 'source_table' ,iba.value_date as 'value_date', iba.maturity_date as 'maturity_date',iba.source_system AS 'source_system'
-- from 
-- (select*from ONESUMX..t_trn_interest_bearing_accounts where  start_validity_date<=@reportdate and end_validity_date>=@reportdate and entity=@entity) iba
-- left join 
-- (select * from ONESUMX..t_customer where start_validity_date<=@reportdate and end_validity_date>=@reportdate) tc
-- on tc.customer_nr=iba.customer_nr

-- union all

-- select 
-- tl.entity, tl.deal_id, tl.customer_nr, tc.nationality,tc.domicile,tc.customer_legal_name,tl.deal_type, tl.currency, null as 'tfi_id', 'loan' as 'source_table',tl.value_date  as 'value_date', tl.maturity_date as 'maturity_date',tl.source_system AS 'source_system'
-- from 
-- (select * from ONESUMX..t_trn_loan where  start_validity_date<=@reportdate and end_validity_date>=@reportdate and entity=@entity) tl
-- left join
-- (select * from ONESUMX..t_customer where start_validity_date<=@reportdate and end_validity_date>=@reportdate) tc
-- on tc.customer_nr=tl.customer_nr

-- union all

-- select tbond.entity, tbond.deal_id, tbond.customer_nr, tc.nationality,tc.domicile,tc.customer_legal_name,tbond.deal_type, tbond.currency, tbond.tfi_id, 'bond' as 'source_table' ,tbond.value_date  as 'value_date',tfibond.maturity_date as 'maturity_date','022' AS 'source_system'
-- from 
-- (select * from ONESUMX..t_tfi_trn_bond where start_validity_date<=@reportdate and end_validity_date>=@reportdate and entity=@entity) tbond
-- left join
-- (select * from ONESUMX..t_customer where start_validity_date<=@reportdate and end_validity_date>=@reportdate) tc
-- on tc.customer_nr=tbond.customer_nr
-- left join
-- (select * from ONESUMX..t_tfi_bond where start_validity_date<=@reportdate and end_validity_date>=@reportdate and object_origin=@entity) tfibond
-- on tfibond.tfi_id=tbond.tfi_id

-- union all

-- select tforex.entity, 
-- tforex.deal_id, 
-- tforex.customer_nr, 
-- tc.nationality,tc.domicile,tc.customer_legal_name,
-- tforex.deal_type, 
-- (case when (tforexv.valuation_type = 'ORI MTM_POSITIVE' or tforexv.valuation_type = 'ORI MTM_NEGATIVE')  then tforexv.currency else 'NA' end) as 'currency',
-- null as 'tfi_id', 'forex' as 'source_table' ,
-- tforex.value_date  as 'value_date',
-- tforex.maturity_date as 'maturity_date',
-- '022' AS 'source_system'
-- from 
-- (select * from ONESUMX..t_trn_forex where start_validity_date<=@reportdate and end_validity_date>=@reportdate and entity=@entity) tforex
-- left join 
-- (select * from ONESUMX..t_trn_forex_valuation where valuation_date=@reportdate) tforexv
--  on tforexv.deal_id = tforex.deal_id and (tforexv.valuation_type = 'ORI MTM_POSITIVE' or tforexv.valuation_type = 'ORI MTM_NEGATIVE')  
-- left join
-- (select * from ONESUMX..t_customer where start_validity_date<=@reportdate and end_validity_date>=@reportdate) tc
-- on tc.customer_nr=tforex.customer_nr

-- union all

-- select toption.entity, 
-- toption.deal_id, 
-- toption.customer_nr, 
-- tc.nationality,tc.domicile,tc.customer_legal_name,
-- toption.deal_type, 
-- (case when (toptionv.valuation_type = 'ORI MTM_POSITIVE' or toptionv.valuation_type = 'ORI MTM_NEGATIVE')  then toptionv.currency else 'NA' end) as 'currency', 
-- null as 'tfi_id', 'option' as 'source_table' ,
-- toption.value_date  as 'value_date',
-- topt.maturity_date as 'maturity_date',
-- '022' AS 'source_system'

-- from 
-- (select * from ONESUMX..t_tfi_trn_option where start_validity_date<=@reportdate and end_validity_date>=@reportdate and entity=@entity) toption
-- left join 
-- (select * from ONESUMX..t_tfi_trn_option_valuation where valuation_date=@reportdate and entity=@entity and (valuation_type= 'ORI MTM_POSITIVE' or valuation_type = 'ORI MTM_NEGATIVE') ) toptionv
-- on toptionv.deal_id = toption.deal_id 
-- left join
-- (select * from ONESUMX..t_customer where start_validity_date<=@reportdate and end_validity_date>=@reportdate) tc
-- on tc.customer_nr=toption.customer_nr
-- left join
-- (select * from onesumx..t_tfi_option where start_validity_date<=@reportdate and end_validity_date>=@reportdate ) topt
-- on topt.tfi_id =toption.tfi_id

-- union all

-- select tswap.entity, 
-- tswap.deal_id, 
-- tswap.customer_nr, 
-- tc.nationality,tc.domicile,tc.customer_legal_name,
-- tswap.deal_type, 
-- (case when (tswapv.valuation_type = 'ORI MTM_POSITIVE' or tswapv.valuation_type = 'ORI MTM_NEGATIVE')  then tswapv.currency else 'NA' end) as 'currency', 
-- null as 'tfi_id', 
-- 'swap' as 'source_table' ,
-- tswap.value_date  as 'value_date',
-- tswap.maturity_date as 'maturity_date',
-- '022' AS 'source_system'

-- from 
-- (select * from ONESUMX..t_trn_swap_ir where start_validity_date<=@reportdate and end_validity_date>=@reportdate and entity=@entity) tswap
-- left join 
-- (select * from ONESUMX..t_trn_swap_ir_valuation where valuation_date=@reportdate and entity=@entity and (valuation_type= 'ORI MTM_POSITIVE' or valuation_type = 'ORI MTM_NEGATIVE')) tswapv
-- on tswapv.deal_id = tswap.deal_id
-- left join
-- (select * from ONESUMX..t_customer where start_validity_date<=@reportdate and end_validity_date>=@reportdate) tc
-- on tc.customer_nr=tswap.customer_nr

-- union all

-- select tbackoffice.entity, tbackoffice.deal_id, tbackoffice.customer_nr, tc.nationality,tc.domicile,tc.customer_legal_name,element6 as 'deal_type', tbackoffice.currency,  null as 'tfi_id', 'back_office' as 'source_table' ,'9999-12-31' as 'value_date', '9999-12-31' as 'maturity_date', 'backoffice' AS 'source_system' 

-- from 
-- (select * from ONESUMX..t_back_office_balance_boc where balance_date=@reportdate and entity=@entity) tbackoffice
-- left join
-- (select * from ONESUMX..t_customer where start_validity_date<=@reportdate  and end_validity_date>=@reportdate ) tc
-- on tc.customer_nr=tbackoffice.customer_nr

-- ) trn

select
entity as 'ide_internal_party_ref',
deal_id as 'ide_linkage_ref',
12 as 'ide_linkage_type',
source_system as 'ide_sourcesys_ref',
@lottype as 'lot_type_fk',
0 as 'rca_accrint',
0 as 'rca_bookv',
0 as 'rca_marketv',
0 as 'rca_prov_coll',
0 as 'rca_prov_indi',
rv_coa as 'rv_coa',
Counterparty_type as 'rv_cpty_type',
intercompany as 'rv_rel_party_type',
currency as 'rv_currency_sub_group',
0 as 'rv_mat_original',
0 as 'rv_mat_remaining',
amount as 'rca_deferred_fee',
0 as 'rca_mtm_negative',
0 as 'rca_mtm_positive',
entity,
deal_id,
customer_nr,
Nationality as 'nationality',
Domicile as 'domicile',
customer_legal_name,
'8475' as 'deal_type',
currency,
null as 'tfi_id',
source_system as 'source_table',
value_date,
maturity_date,
'fee' AS 'source_system'  

from
(
select t_trn_fee.entity, 
t_trn_fee.deal_id, 
t_trn_fee.source_system,
t_trn_fee.customer_nr, 
t_trn_fee.rv_coa, 
t_trn_fee.currency, 
t_trn_fee.value_date, 
t_trn_fee.maturity_date, 
(case when t_trn_fee_valuation.valuation_type = 'DEFERRED_FEE' then t_trn_fee_valuation.amount else 0 end) as 'amount', 
(case when tc.customer_attribute1 is not null then tc.customer_attribute1 else 'NA' end) as 'Counterparty_type', 
(case when tc.intercompany is not null then tc.intercompany else 'NA' end) as 'intercompany', 
(case when tc.nationality is not null then tc.nationality else 'NA' end) as 'Nationality',
(case when tc.domicile is not null then tc.domicile else 'NA' end) as 'Domicile',
tc.customer_legal_name 


from ONESUMX..t_trn_fee

left join ONESUMX..t_trn_fee_valuation on (t_trn_fee.deal_id=t_trn_fee_valuation.deal_id and t_trn_fee_valuation.valuation_type='DEFERRED_FEE' and t_trn_fee_valuation.valuation_date=@reportdate)
left join (select * from ONESUMX..t_customer where start_validity_date<=@reportdate and end_validity_date>=@reportdate ) tc on (tc.customer_nr=t_trn_fee.customer_nr )

where t_trn_fee.start_validity_date<=@reportdate and t_trn_fee.end_validity_date>=@reportdate and t_trn_fee.source_system='FASM' and t_trn_fee.entity=@entity
) fee

union all
select ide_internal_party_ref,ide_linkage_ref,ide_linkage_type,ide_sourcesys_ref,lot_type_fk,
case when rca_accrint is null then 0 else rca_accrint end as 'rca_accrint',
case when rca_bookv is null then 0 else rca_bookv end as 'rca_book_v',
case when rca_marketv is null then 0 else rca_marketv end as 'rca_marketv',
case when rca_prov_coll is null then 0 else rca_prov_coll end as 'rca_prov_coll',
case when rca_prov_indi is null then 0 else rca_prov_indi end as 'rca_prov_indi',
rv_coa,rv_cpty_type,rv_rel_party_type,rv_currency_sub_group,
case when rv_mat_original is null then 0 else rv_mat_original end as 'rv_mat_original',
case when rv_mat_remaining is null then 0 else rv_mat_remaining end as 'rv_mat_remaining',
case when rca_deferred_fee is null then 0 else rca_deferred_fee end as 'rca_deferred_fee',
0 as 'rca_mtm_negative', 
0 as 'rca_mtm_positive',
#trn.*
from AUA_LDM..recs_type_30 rt30

left join
#trn
on rt30.ide_linkage_ref = #trn.deal_id
where lot_type_fk = @lottype
and (ide_sourcesys_ref <>'' or (ide_sourcesys_ref = '' and ide_internal_one=''))
and (ide_linkage_type in (1,2,3,5,6,8,9,10,11)) --or (ide_linkage_type=12 and ide_linkage_type = 'FASM'))

union all

select 
ide_internal_party_ref,ide_linkage_ref,ide_linkage_type,ide_sourcesys_ref,lot_type_fk, 0 as 'rca_accrint',0 as 'rca_bookv', 0 as 'rca_marketv',0 as 'rca_prov_coll',0 as 'rca_prov_indi', rv_coa_deriv as 'rv_coa',rv_cpty_type,rv_rel_party_type,currency as 'rv_currency_sub_group',0 as 'rv_mat_original',rv_mat_remaining, 
0 as 'rca_deferred_fee', 
rca_mtm_negative, 
rca_mtm_positive,
entity,	deal_id, customer_nr, 
NATIONALITY,
DOMICILE,
customer_legal_name,
deal_type, currency, tfi_id, source_table, value_date, maturity_date,'022' AS 'source_system'
from
(select ide_internal_party_ref,ide_linkage_ref,ide_linkage_type,ide_sourcesys_ref,lot_type_fk,rca_mtm_negative, rca_mtm_positive,rv_coa_deriv,
case when rv_mat_remaining is null then 0 else rv_mat_remaining end as 'rv_mat_remaining',rv_cpty_type,rv_currency_group_mtm,rv_rel_party_type,#trn.*
from AUA_LDM..recs_type_32 rt32

left join
#trn
on rt32.ide_linkage_ref = #trn.deal_id
where lot_type_fk = @lottype) rt32


drop table if exists #trn

/*2023-06-07 */
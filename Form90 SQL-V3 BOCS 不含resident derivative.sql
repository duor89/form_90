declare @last_reportdate date
declare @this_reportdate date
declare @entity int
declare @last_lottype int
declare @this_lottype int;

--###please report date below###--
set @last_reportdate = '2023-12-31'
set @this_reportdate = '2024-03-31'
set @entity = '106'
set @last_lottype = '934'
set @this_lottype = '952'
--###input end##--

--iba--
select * from
(select 
RT30.lot_type_fk,
RT30.ide_linkage_ref,
RT30.ide_linkage_type,
RT30.ide_sourcesys_ref,
(case when RT30.lot_type_fk=@this_lottype then tiba_thisQ.deal_type else tiba_lastQ.deal_type end) as 'dealtype', 
(case when RT30.lot_type_fk=@this_lottype then tiba_thisQ.customer_nr else tiba_lastQ.customer_nr end) as 'customer_nr', 
(case when RT30.lot_type_fk=@this_lottype then tc_thisQ.customer_legal_name else tc_lastQ.customer_legal_name end) as 'customer_name',
RT30.rv_coa,
(case when RT30.lot_type_fk=@this_lottype then RT30_lastQ.rv_cpty_type else RT30_lastQ.rv_cpty_type end) as 'rv_cpty_type_lastQ', 
RT30.rv_cpty_type as 'rv_cpty_type_thisQ',
(case when RT30.lot_type_fk=@this_lottype then RT30_lastQ.rv_rel_party_type else RT30_lastQ.rv_rel_party_type end) as 'rv_rel_party_type_lastQ', 
(case when RT30.lot_type_fk=@this_lottype then RT30_thisQ.rv_rel_party_type else RT30_lastQ.rv_rel_party_type end) as 'rv_rel_party_type_thisQ', 
(case when RT30.lot_type_fk=@this_lottype then RT30_lastQ.rv_resident else RT30_lastQ.rv_resident end) as 'rv_resident_lastQ', 
RT30.rv_resident as 'rv_resident_thisQ',
(case when RT30.lot_type_fk=@this_lottype then (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.nationality end) else (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.nationality end) end) as 'nationality_lastQ', 
(case when RT30.lot_type_fk=@this_lottype then (case when RT30_thisQ.rv_resident='YES' then 'AU' else tc_thisQ.nationality end) else (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.nationality end) end) as 'nationality_thisQ',
(case when RT30.lot_type_fk=@this_lottype then (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.domicile end) else (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.domicile end) end) as 'domicile_lastQ', 
(case when RT30.lot_type_fk=@this_lottype then (case when RT30_thisQ.rv_resident='YES' then 'AU' else tc_thisQ.domicile end) else (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.domicile end) end) as 'domicile_thisQ',
(case when RT30.lot_type_fk=@this_lottype then (case when tiba_thisQ.currency='CNH' then 'CNY' else tiba_thisQ.currency end) else (case when tiba_lastQ.currency='CNH' then 'CNY' else tiba_lastQ.currency end) end) as 'currency', 
(case when RT30.lot_type_fk=@this_lottype then tiba_thisQ.value_date else tiba_lastQ.value_date end) as 'value_date', 
(case when RT30.lot_type_fk=@this_lottype then tiba_thisQ.maturity_date else tiba_lastQ.maturity_date end) as 'maturity_date', 
(case when RT30.lot_type_fk=@this_lottype then (case when tfx_value_thisQ.rate is null then 0 else tfx_value_thisQ.rate end) else (case when tfx_value_lastQ.rate is null then 0 else tfx_value_lastQ.rate end) end) as 'fx_rate_value',
(case when RT30.lot_type_fk=@this_lottype then (case when tfx_maturity_thisQ.rate is null then 0 else tfx_maturity_thisQ.rate end) else (case when tfx_maturity_lastQ.rate is null then 0 else tfx_maturity_lastQ.rate end) end) as 'fx_rate_maturity',
RT30.rv_mat_original,
RT30.rv_mat_remaining,
(case when RT30.lot_type_fk=@this_lottype then (case when tibav_value_thisQ.amount is not null then tibav_value_thisQ.amount else tibav_thisQ.amount end) else (case when tibav_value_lastQ.amount is not null then tibav_value_lastQ.amount else tibav_lastQ.amount end) end) as 'nominal',
0 as 'trade_price',
'NA' as 'ISIN',
(case when RT30_thisQ.rca_bookv is not null then RT30_thisQ.rca_bookv else 0 end) as 'rca_bookv_thisQ', 
(case when tibav_thisQ.valuation_type = 'ORI OUTSTANDING PRINCIPAL' then tibav_thisQ.amount else 0 end) as 'rca_ori_bookv_thisQ', 
(case when RT30_thisQ.rca_marketv is not null then RT30_thisQ.rca_marketv else 0 end) as 'rca_marketv_thisQ',
0 as 'rca_ori_marketv_thisQ', 
(case when RT30_thisQ.rca_accrint is not null then RT30_thisQ.rca_accrint else 0 end) as 'rca_accrint_thisQ',
(case when RT30_thisQ.rca_prov_coll is not null then RT30_thisQ.rca_prov_coll else 0 end) as 'rca_prov_coll_thisQ',
(case when RT30_thisQ.rca_prov_indi is not null then RT30_thisQ.rca_prov_indi else 0 end) as 'rca_prov_indi_thisQ',
(case when tfx_thisQ.rate is not null then tfx_thisQ.rate else 0 end) as 'fx_rate_thisQ',
(case when RT30_lastQ.rca_bookv is not null then RT30_lastQ.rca_bookv else 0 end) as 'rca_bookv_lastQ',
(case when tibav_lastQ.valuation_type = 'ORI OUTSTANDING PRINCIPAL' then tibav_lastQ.amount else 0 end) as 'rca_ori_bookv_lastQ',  
(case when RT30_lastQ.rca_marketv is not null then RT30_lastQ.rca_marketv else 0 end) as 'rca_marketv_lastQ',
0 as 'rca_ori_marketv_lastQ',
(case when RT30_lastQ.rca_accrint is not null then RT30_lastQ.rca_accrint else 0 end) as 'rca_accrint_lastQ',
(case when RT30_lastQ.rca_prov_coll is not null then RT30_lastQ.rca_prov_coll else 0 end) as 'rca_prov_coll_lastQ',
(case when RT30_lastQ.rca_prov_indi is not null then RT30_lastQ.rca_prov_indi else 0 end) as 'rca_prov_indi_lastQ',
(case when tfx_lastQ.rate is not null then tfx_lastQ.rate else 0 end) as 'fx_rate_lastQ'


from 
(select ide_internal_one, lot_type_fk, ide_linkage_ref, ide_linkage_type, ide_sourcesys_ref, rv_coa, rv_cpty_type, rv_rel_party_type, rv_resident, rv_mat_original, rv_mat_remaining, rca_bookv, rca_marketv, rca_accrint, rca_prov_coll, rca_prov_indi from AUA_LDM..recs_type_30 RT30_all
inner join (select ide_linkage_ref as 'max_ide_linkage_ref', max(lot_type_fk) as 'max_lot_type_fk' from AUA_LDM..recs_type_30
where lot_type_fk in (@last_lottype, @this_lottype) and (ide_sourcesys_ref <>'' or (ide_sourcesys_ref = '' and ide_internal_one='')) group by ide_linkage_ref) RT30_group
on (RT30_all.ide_linkage_ref = RT30_group.max_ide_linkage_ref and RT30_all.lot_type_fk=RT30_group.max_lot_type_fk)
where lot_type_fk in (@last_lottype, @this_lottype) and (ide_sourcesys_ref <>'' or (ide_sourcesys_ref = '' and ide_internal_one=''))) RT30

left join AUA_LDM..recs_type_30 RT30_thisQ on (RT30.ide_linkage_type=RT30_thisQ.ide_linkage_type and RT30.ide_linkage_ref=RT30_thisQ.ide_linkage_ref and RT30_thisQ.lot_type_fk=@this_lottype and (RT30_thisQ.ide_sourcesys_ref <>'' or (RT30_thisQ.ide_sourcesys_ref = '' and RT30_thisQ.ide_internal_one='')))
left join AUA_LDM..recs_type_30 RT30_lastQ on (RT30.ide_linkage_type=RT30_lastQ.ide_linkage_type and RT30.ide_linkage_ref=RT30_lastQ.ide_linkage_ref and RT30_lastQ.lot_type_fk=@last_lottype and (RT30_lastQ.ide_sourcesys_ref <>'' or (RT30_lastQ.ide_sourcesys_ref = '' and RT30_lastQ.ide_internal_one='')))
left join ONESUMX..t_trn_interest_bearing_accounts tiba_thisQ on (tiba_thisQ.deal_id =RT30.ide_linkage_ref and tiba_thisQ.start_validity_date<=@this_reportdate and tiba_thisQ.end_validity_date>=@this_reportdate)
left join ONESUMX..t_trn_interest_bearing_accounts tiba_lastQ on (tiba_lastQ.deal_id =RT30.ide_linkage_ref and tiba_lastQ.start_validity_date<=@last_reportdate and tiba_lastQ.end_validity_date>=@last_reportdate)
left join ONESUMX..t_customer tc_thisQ on (tc_thisQ.customer_nr=tiba_thisQ.customer_nr and tc_thisQ.start_validity_date<=@this_reportdate and tc_thisQ.end_validity_date>=@this_reportdate)
left join ONESUMX..t_customer tc_lastQ on (tc_lastQ.customer_nr=tiba_lastQ.customer_nr and tc_lastQ.start_validity_date<=@last_reportdate and tc_lastQ.end_validity_date>=@last_reportdate)
left join ONESUMX..t_trn_interest_bearing_accounts_valuation tibav_thisQ on (tibav_thisQ.deal_id =RT30.ide_linkage_ref and tibav_thisQ.valuation_type='ORI OUTSTANDING PRINCIPAL'and tibav_thisQ.valuation_date=@this_reportdate) 
left join ONESUMX..t_trn_interest_bearing_accounts_valuation tibav_lastQ on (tibav_lastQ.deal_id =RT30.ide_linkage_ref and tibav_lastQ.valuation_type='ORI OUTSTANDING PRINCIPAL'and tibav_lastQ.valuation_date=@last_reportdate) 
left join ONESUMX..t_trn_interest_bearing_accounts_valuation tibav_value_thisQ on (tibav_value_thisQ.deal_id =RT30.ide_linkage_ref and tibav_value_thisQ.valuation_type='ORI OUTSTANDING PRINCIPAL'and tibav_value_thisQ.valuation_date=tiba_thisQ.value_date) 
left join ONESUMX..t_trn_interest_bearing_accounts_valuation tibav_value_lastQ on (tibav_value_lastQ.deal_id =RT30.ide_linkage_ref and tibav_value_lastQ.valuation_type='ORI OUTSTANDING PRINCIPAL'and tibav_value_lastQ.valuation_date=tiba_lastQ.value_date) 
left join ONESUMX..t_currency_rate_boc tfx_thisQ on (((tiba_thisQ.currency<>'CNH' and tfx_thisQ.from_currency=tiba_thisQ.currency) or (tiba_thisQ.currency='CNH' and tfx_thisQ.from_currency='CNY')) and tfx_thisQ.rate_date=@this_reportdate and tfx_thisQ.entity=@entity)
left join ONESUMX..t_currency_rate_boc tfx_lastQ on (((tiba_lastQ.currency<>'CNH' and tfx_lastQ.from_currency=tiba_lastQ.currency) or (tiba_lastQ.currency='CNH' and tfx_lastQ.from_currency='CNY')) and tfx_lastQ.rate_date=@last_reportdate and tfx_lastQ.entity=@entity)
left join ONESUMX..t_currency_rate_boc tfx_value_thisQ on (((tiba_thisQ.currency<>'CNH' and tfx_value_thisQ.from_currency=tiba_thisQ.currency) or (tiba_thisQ.currency='CNH' and tfx_value_thisQ.from_currency='CNY')) and tfx_value_thisQ.rate_date=tiba_thisQ.value_date and tfx_value_thisQ.entity=@entity)
left join ONESUMX..t_currency_rate_boc tfx_value_lastQ on (((tiba_lastQ.currency<>'CNH' and tfx_value_lastQ.from_currency=tiba_lastQ.currency) or (tiba_lastQ.currency='CNH' and tfx_value_lastQ.from_currency='CNY')) and tfx_value_lastQ.rate_date=tiba_lastQ.value_date and tfx_value_lastQ.entity=@entity)
left join ONESUMX..t_currency_rate_boc tfx_maturity_thisQ on (((tiba_thisQ.currency<>'CNH' and tfx_maturity_thisQ.from_currency=tiba_thisQ.currency) or (tiba_thisQ.currency='CNH' and tfx_maturity_thisQ.from_currency='CNY')) and tfx_maturity_thisQ.rate_date=tiba_thisQ.maturity_date and tfx_maturity_thisQ.entity=@entity)
left join ONESUMX..t_currency_rate_boc tfx_maturity_lastQ on (((tiba_lastQ.currency<>'CNH' and tfx_maturity_lastQ.from_currency=tiba_lastQ.currency) or (tiba_lastQ.currency='CNH' and tfx_maturity_lastQ.from_currency='CNY')) and tfx_maturity_lastQ.rate_date=tiba_lastQ.maturity_date and tfx_maturity_lastQ.entity=@entity)

where (RT30.ide_sourcesys_ref <>'' or (RT30.ide_sourcesys_ref = '' and RT30.ide_internal_one='')) 
and (RT30.ide_linkage_type in (2,10)) and rt30.rv_resident ='NO'
and RT30.lot_type_fk in (@last_lottype, @this_lottype)) iba 

union all

--loan--
select * from
(select 
RT30.lot_type_fk,
RT30.ide_linkage_ref,
RT30.ide_linkage_type,
RT30.ide_sourcesys_ref,
(case when RT30.lot_type_fk=@this_lottype then tl_thisQ.deal_type else tl_lastQ.deal_type end) as 'dealtype', 
(case when RT30.lot_type_fk=@this_lottype then tl_thisQ.customer_nr else tl_lastQ.customer_nr end) as 'customer_nr', 
(case when RT30.lot_type_fk=@this_lottype then tc_thisQ.customer_legal_name else tc_lastQ.customer_legal_name end) as 'customer_name',
RT30.rv_coa,
(case when RT30.lot_type_fk=@this_lottype then RT30_lastQ.rv_cpty_type else RT30_lastQ.rv_cpty_type end) as 'rv_cpty_type_lastQ', 
RT30.rv_cpty_type as 'rv_cpty_type_thisQ',
(case when RT30.lot_type_fk=@this_lottype then RT30_lastQ.rv_rel_party_type else RT30_lastQ.rv_rel_party_type end) as 'rv_rel_party_type_lastQ', 
(case when RT30.lot_type_fk=@this_lottype then RT30_thisQ.rv_rel_party_type else RT30_lastQ.rv_rel_party_type end) as 'rv_rel_party_type_thisQ', 
(case when RT30.lot_type_fk=@this_lottype then RT30_lastQ.rv_resident else RT30_lastQ.rv_resident end) as 'rv_resident_lastQ', 
RT30.rv_resident as 'rv_resident_thisQ',
(case when RT30.lot_type_fk=@this_lottype then (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.nationality end) else (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.nationality end) end) as 'nationality_lastQ', 
(case when RT30.lot_type_fk=@this_lottype then (case when RT30_thisQ.rv_resident='YES' then 'AU' else tc_thisQ.nationality end) else (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.nationality end) end) as 'nationality_thisQ',
(case when RT30.lot_type_fk=@this_lottype then (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.domicile end) else (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.domicile end) end) as 'domicile_lastQ', 
(case when RT30.lot_type_fk=@this_lottype then (case when RT30_thisQ.rv_resident='YES' then 'AU' else tc_thisQ.domicile end) else (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.domicile end) end) as 'domicile_thisQ',
(case when RT30.lot_type_fk=@this_lottype then (case when tl_thisQ.currency='CNH' then 'CNY' else tl_thisQ.currency end) else (case when tl_lastQ.currency='CNH' then 'CNY' else tl_lastQ.currency end) end) as 'currency', 
(case when RT30.lot_type_fk=@this_lottype then tl_thisQ.value_date else tl_lastQ.value_date end) as 'value_date', 
(case when RT30.lot_type_fk=@this_lottype then tl_thisQ.maturity_date else tl_lastQ.maturity_date end) as 'maturity_date', 
(case when RT30.lot_type_fk=@this_lottype then (case when tfx_value_thisQ.rate is null then 0 else tfx_value_thisQ.rate end) else (case when tfx_value_lastQ.rate is null then 0 else tfx_value_lastQ.rate end) end) as 'fx_rate_value',
(case when RT30.lot_type_fk=@this_lottype then (case when tfx_maturity_thisQ.rate is null then 0 else tfx_maturity_thisQ.rate end) else (case when tfx_maturity_lastQ.rate is null then 0 else tfx_maturity_lastQ.rate end) end) as 'fx_rate_maturity',
RT30.rv_mat_original,
RT30.rv_mat_remaining,
(case when RT30.lot_type_fk=@this_lottype then (case when trlv_value_thisQ.amount is not null then trlv_value_thisQ.amount else trlv_thisQ.amount end) else (case when trlv_value_lastQ.amount is not null then trlv_value_lastQ.amount else trlv_lastQ.amount end) end) as 'nominal',
0 as 'trade_price',
'NA' as 'ISIN',
(case when RT30_thisQ.rca_bookv is not null then RT30_thisQ.rca_bookv else 0 end) as 'rca_bookv_thisQ', 
(case when trlv_thisQ.valuation_type = 'ORI OUTSTANDING PRINCIPAL' then trlv_thisQ.amount else 0 end) as 'rca_ori_bookv_thisQ', 
(case when RT30_thisQ.rca_marketv is not null then RT30_thisQ.rca_marketv else 0 end) as 'rca_marketv_thisQ',
0 as 'rca_ori_marketv_thisQ',
(case when RT30_thisQ.rca_accrint is not null then RT30_thisQ.rca_accrint else 0 end) as 'rca_accrint_thisQ',
(case when RT30_thisQ.rca_prov_coll is not null then RT30_thisQ.rca_prov_coll else 0 end) as 'rca_prov_coll_thisQ',
(case when RT30_thisQ.rca_prov_indi is not null then RT30_thisQ.rca_prov_indi else 0 end) as 'rca_prov_indi_thisQ',
(case when tfx_thisQ.rate is not null then tfx_thisQ.rate else 0 end) as 'fx_rate_thisQ',
(case when RT30_lastQ.rca_bookv is not null then RT30_lastQ.rca_bookv else 0 end) as 'rca_bookv_lastQ', 
(case when trlv_lastQ.valuation_type = 'ORI OUTSTANDING PRINCIPAL' then trlv_lastQ.amount else 0 end) as 'rca_ori_bookv_lastQ', 
(case when RT30_lastQ.rca_marketv is not null then RT30_lastQ.rca_marketv else 0 end) as 'rca_marketv_lastQ',
0 as 'rca_ori_marketv_lastQ',
(case when RT30_lastQ.rca_accrint is not null then RT30_lastQ.rca_accrint else 0 end) as 'rca_accrint_lastQ',
(case when RT30_lastQ.rca_prov_coll is not null then RT30_lastQ.rca_prov_coll else 0 end) as 'rca_prov_coll_lastQ',
(case when RT30_lastQ.rca_prov_indi is not null then RT30_lastQ.rca_prov_indi else 0 end) as 'rca_prov_indi_lastQ',
(case when tfx_lastQ.rate is not null then tfx_lastQ.rate else 0 end) as 'fx_rate_lastQ'


from 
(select ide_internal_one, lot_type_fk, ide_linkage_ref, ide_linkage_type, ide_sourcesys_ref, rv_coa, rv_cpty_type, rv_rel_party_type, rv_resident, rv_mat_original, rv_mat_remaining, rca_bookv, rca_marketv, rca_accrint, rca_prov_coll, rca_prov_indi from AUA_LDM..recs_type_30 RT30_all
inner join (select ide_linkage_ref as 'max_ide_linkage_ref', max(lot_type_fk) as 'max_lot_type_fk' from AUA_LDM..recs_type_30
where lot_type_fk in (@last_lottype, @this_lottype) and (ide_sourcesys_ref <>'' or (ide_sourcesys_ref = '' and ide_internal_one='')) group by ide_linkage_ref) RT30_group
on (RT30_all.ide_linkage_ref = RT30_group.max_ide_linkage_ref and RT30_all.lot_type_fk=RT30_group.max_lot_type_fk)
where lot_type_fk in (@last_lottype, @this_lottype) and (ide_sourcesys_ref <>'' or (ide_sourcesys_ref = '' and ide_internal_one=''))) RT30

left join AUA_LDM..recs_type_30 RT30_thisQ on (RT30.ide_linkage_type=RT30_thisQ.ide_linkage_type and RT30.ide_linkage_ref=RT30_thisQ.ide_linkage_ref and RT30_thisQ.lot_type_fk=@this_lottype and (RT30_thisQ.ide_sourcesys_ref <>'' or (RT30_thisQ.ide_sourcesys_ref = '' and RT30_thisQ.ide_internal_one='')))
left join AUA_LDM..recs_type_30 RT30_lastQ on (RT30.ide_linkage_type=RT30_lastQ.ide_linkage_type and RT30.ide_linkage_ref=RT30_lastQ.ide_linkage_ref and RT30_lastQ.lot_type_fk=@last_lottype and (RT30_lastQ.ide_sourcesys_ref <>'' or (RT30_lastQ.ide_sourcesys_ref = '' and RT30_lastQ.ide_internal_one='')))
left join ONESUMX..t_trn_loan tl_thisQ on (tl_thisQ.deal_id =RT30.ide_linkage_ref and tl_thisQ.start_validity_date<=@this_reportdate and tl_thisQ.end_validity_date>=@this_reportdate)
left join ONESUMX..t_trn_loan tl_lastQ on (tl_lastQ.deal_id =RT30.ide_linkage_ref and tl_lastQ.start_validity_date<=@last_reportdate and tl_lastQ.end_validity_date>=@last_reportdate)
left join ONESUMX..t_customer tc_thisQ on (tc_thisQ.customer_nr=tl_thisQ.customer_nr and tc_thisQ.start_validity_date<=@this_reportdate and tc_thisQ.end_validity_date>=@this_reportdate)
left join ONESUMX..t_customer tc_lastQ on (tc_lastQ.customer_nr=tl_lastQ.customer_nr and tc_lastQ.start_validity_date<=@last_reportdate and tc_lastQ.end_validity_date>=@last_reportdate)
left join ONESUMX..t_trn_loan_valuation trlv_thisQ on (trlv_thisQ.deal_id =RT30.ide_linkage_ref and trlv_thisQ.valuation_type='ORI OUTSTANDING PRINCIPAL'and trlv_thisQ.valuation_date=@this_reportdate) 
left join ONESUMX..t_trn_loan_valuation trlv_lastQ on (trlv_lastQ.deal_id =RT30.ide_linkage_ref and trlv_lastQ.valuation_type='ORI OUTSTANDING PRINCIPAL'and trlv_lastQ.valuation_date=@last_reportdate) 
left join ONESUMX..t_trn_loan_valuation trlv_value_thisQ on (trlv_value_thisQ.deal_id =RT30.ide_linkage_ref and trlv_value_thisQ.valuation_type='ORI OUTSTANDING PRINCIPAL'and trlv_value_thisQ.valuation_date=tl_thisQ.value_date) 
left join ONESUMX..t_trn_loan_valuation trlv_value_lastQ on (trlv_value_lastQ.deal_id =RT30.ide_linkage_ref and trlv_value_lastQ.valuation_type='ORI OUTSTANDING PRINCIPAL'and trlv_value_lastQ.valuation_date=tl_lastQ.value_date) 
left join ONESUMX..t_currency_rate_boc tfx_thisQ on (((tl_thisQ.currency<>'CNH' and tfx_thisQ.from_currency=tl_thisQ.currency) or (tl_thisQ.currency='CNH' and tfx_thisQ.from_currency='CNY')) and tfx_thisQ.rate_date=@this_reportdate and tfx_thisQ.entity=@entity)
left join ONESUMX..t_currency_rate_boc tfx_lastQ on (((tl_lastQ.currency<>'CNH' and tfx_lastQ.from_currency=tl_lastQ.currency) or (tl_lastQ.currency='CNH' and tfx_lastQ.from_currency='CNY')) and tfx_lastQ.rate_date=@last_reportdate and tfx_lastQ.entity=@entity)
left join ONESUMX..t_currency_rate_boc tfx_value_thisQ on (((tl_thisQ.currency<>'CNH' and tfx_value_thisQ.from_currency=tl_thisQ.currency) or (tl_thisQ.currency='CNH' and tfx_value_thisQ.from_currency='CNY')) and tfx_value_thisQ.rate_date=tl_thisQ.value_date and tfx_value_thisQ.entity=@entity)
left join ONESUMX..t_currency_rate_boc tfx_value_lastQ on (((tl_lastQ.currency<>'CNH' and tfx_value_lastQ.from_currency=tl_lastQ.currency) or (tl_lastQ.currency='CNH' and tfx_value_lastQ.from_currency='CNY')) and tfx_value_lastQ.rate_date=tl_lastQ.value_date and tfx_value_lastQ.entity=@entity)
left join ONESUMX..t_currency_rate_boc tfx_maturity_thisQ on (((tl_thisQ.currency<>'CNH' and tfx_maturity_thisQ.from_currency=tl_thisQ.currency) or (tl_thisQ.currency='CNH' and tfx_maturity_thisQ.from_currency='CNY')) and tfx_maturity_thisQ.rate_date=tl_thisQ.maturity_date and tfx_maturity_thisQ.entity=@entity)
left join ONESUMX..t_currency_rate_boc tfx_maturity_lastQ on (((tl_lastQ.currency<>'CNH' and tfx_maturity_lastQ.from_currency=tl_lastQ.currency) or (tl_lastQ.currency='CNH' and tfx_maturity_lastQ.from_currency='CNY')) and tfx_maturity_lastQ.rate_date=tl_lastQ.maturity_date and tfx_maturity_lastQ.entity=@entity)


where (RT30.ide_sourcesys_ref <>'' or (RT30.ide_sourcesys_ref = '' and RT30.ide_internal_one='')) 
and RT30.ide_linkage_type in (3) and rt30.rv_resident ='NO'
and RT30.lot_type_fk in (@last_lottype, @this_lottype)) loan 

union all

--bond--
select * from
(select 
RT30.lot_type_fk,
RT30.ide_linkage_ref,
RT30.ide_linkage_type,
RT30.ide_sourcesys_ref,
(case when RT30.lot_type_fk=@this_lottype then trb_thisQ.deal_type else trb_lastQ.deal_type end) as 'dealtype', 
(case when RT30.lot_type_fk=@this_lottype then trb_thisQ.customer_nr else trb_lastQ.customer_nr end) as 'customer_nr', 
(case when RT30.lot_type_fk=@this_lottype then tc_thisQ.customer_legal_name else tc_lastQ.customer_legal_name end) as 'customer_name',
RT30.rv_coa,
(case when RT30.lot_type_fk=@this_lottype then RT30_lastQ.rv_cpty_type else RT30_lastQ.rv_cpty_type end) as 'rv_cpty_type_lastQ', 
RT30.rv_cpty_type as 'rv_cpty_type_thisQ',
(case when RT30.lot_type_fk=@this_lottype then RT30_lastQ.rv_rel_party_type else RT30_lastQ.rv_rel_party_type end) as 'rv_rel_party_type_lastQ', 
(case when RT30.lot_type_fk=@this_lottype then RT30_thisQ.rv_rel_party_type else RT30_lastQ.rv_rel_party_type end) as 'rv_rel_party_type_thisQ', 
(case when RT30.lot_type_fk=@this_lottype then RT30_lastQ.rv_resident else RT30_lastQ.rv_resident end) as 'rv_resident_lastQ', 
RT30.rv_resident as 'rv_resident_thisQ',
(case when RT30.lot_type_fk=@this_lottype then (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.nationality end) else (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.nationality end) end) as 'nationality_lastQ', 
(case when RT30.lot_type_fk=@this_lottype then (case when RT30_thisQ.rv_resident='YES' then 'AU' else tc_thisQ.nationality end) else (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.nationality end) end) as 'nationality_thisQ',
(case when RT30.lot_type_fk=@this_lottype then (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.domicile end) else (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.domicile end) end) as 'domicile_lastQ', 
(case when RT30.lot_type_fk=@this_lottype then (case when RT30_thisQ.rv_resident='YES' then 'AU' else tc_thisQ.domicile end) else (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.domicile end) end) as 'domicile_thisQ',
(case when RT30.lot_type_fk=@this_lottype then (case when trb_thisQ.currency='CNH' then 'CNY' else trb_thisQ.currency end) else (case when trb_lastQ.currency='CNH' then 'CNY' else trb_lastQ.currency end) end) as 'currency', 
(case when RT30.lot_type_fk=@this_lottype then trb_thisQ.value_date else trb_lastQ.value_date end) as 'value_date', 
(case when RT30.lot_type_fk=@this_lottype then tfb_thisQ.maturity_date else tfb_lastQ.maturity_date end) as 'maturity_date', 
(case when RT30.lot_type_fk=@this_lottype then (case when tfx_value_thisQ.rate is null then 0 else tfx_value_thisQ.rate end) else (case when tfx_value_lastQ.rate is null then 0 else tfx_value_lastQ.rate end) end) as 'fx_rate_value',
(case when RT30.lot_type_fk=@this_lottype then (case when tfx_maturity_thisQ.rate is null then 0 else tfx_maturity_thisQ.rate end) else (case when tfx_maturity_lastQ.rate is null then 0 else tfx_maturity_lastQ.rate end) end) as 'fx_rate_maturity',
RT30.rv_mat_original,
RT30.rv_mat_remaining,
(case when RT30.lot_type_fk=@this_lottype then trb_thisQ.underlying_notional_amount else trb_lastQ.underlying_notional_amount end) as 'nominal',
(case when RT30.lot_type_fk=@this_lottype then trb_thisQ.trade_price else trb_lastQ.trade_price end) as 'trade_price',
(case when RT30.lot_type_fk=@this_lottype then trb_thisQ.tfi_id else trb_lastQ.tfi_id end) as 'ISIN',
(case when RT30_thisQ.rca_bookv is not null then RT30_thisQ.rca_bookv else 0 end) as 'rca_bookv_thisQ', 
(case when trbv_thisQ1.valuation_type = 'ORI BOOK VALUE' then trbv_thisQ1.amount else 0 end) as 'rca_ori_bookv_thisQ', 
(case when RT30_thisQ.rca_marketv is not null then RT30_thisQ.rca_marketv else 0 end) as 'rca_marketv_thisQ',
(case when trbv_thisQ2.valuation_type = 'ORI MARKET VALUE' then trbv_thisQ2.amount else 0 end) as 'rca_ori_marketv_thisQ', 
(case when RT30_thisQ.rca_accrint is not null then RT30_thisQ.rca_accrint else 0 end) as 'rca_accrint_thisQ',
(case when RT30_thisQ.rca_prov_coll is not null then RT30_thisQ.rca_prov_coll else 0 end) as 'rca_prov_coll_thisQ',
(case when RT30_thisQ.rca_prov_indi is not null then RT30_thisQ.rca_prov_indi else 0 end) as 'rca_prov_indi_thisQ',
(case when tfx_thisQ.rate is not null then tfx_thisQ.rate else 0 end) as 'fx_rate_thisQ',
(case when RT30_lastQ.rca_bookv is not null then RT30_lastQ.rca_bookv else 0 end) as 'rca_bookv_lastQ', 
(case when trbv_lastQ1.valuation_type = 'ORI BOOK VALUE' then trbv_lastQ1.amount else 0 end) as 'rca_ori_bookv_lastQ', 
(case when RT30_lastQ.rca_marketv is not null then RT30_lastQ.rca_marketv else 0 end) as 'rca_marketv_lastQ',
(case when trbv_lastQ2.valuation_type = 'ORI MARKET VALUE' then trbv_lastQ2.amount else 0 end) as 'rca_ori_marketv_lastQ', 
(case when RT30_lastQ.rca_accrint is not null then RT30_lastQ.rca_accrint else 0 end) as 'rca_accrint_lastQ',
(case when RT30_lastQ.rca_prov_coll is not null then RT30_lastQ.rca_prov_coll else 0 end) as 'rca_prov_coll_lastQ',
(case when RT30_lastQ.rca_prov_indi is not null then RT30_lastQ.rca_prov_indi else 0 end) as 'rca_prov_indi_lastQ',
(case when tfx_lastQ.rate is not null then tfx_lastQ.rate else 0 end) as 'fx_rate_lastQ'


from 
(select ide_internal_one, lot_type_fk, ide_linkage_ref, ide_linkage_type, ide_sourcesys_ref, rv_coa, rv_cpty_type, rv_rel_party_type, rv_resident, rv_mat_original, rv_mat_remaining, rca_bookv, rca_marketv, rca_accrint, rca_prov_coll, rca_prov_indi from AUA_LDM..recs_type_30 RT30_all
inner join (select ide_linkage_ref as 'max_ide_linkage_ref', max(lot_type_fk) as 'max_lot_type_fk' from AUA_LDM..recs_type_30
where lot_type_fk in (@last_lottype, @this_lottype) and (ide_sourcesys_ref <>'' or (ide_sourcesys_ref = '' and ide_internal_one='')) group by ide_linkage_ref) RT30_group
on (RT30_all.ide_linkage_ref = RT30_group.max_ide_linkage_ref and RT30_all.lot_type_fk=RT30_group.max_lot_type_fk)
where lot_type_fk in (@last_lottype, @this_lottype) and (ide_sourcesys_ref <>'' or (ide_sourcesys_ref = '' and ide_internal_one=''))) RT30

left join AUA_LDM..recs_type_30 RT30_thisQ on (RT30.ide_linkage_type=RT30_thisQ.ide_linkage_type and RT30.ide_linkage_ref=RT30_thisQ.ide_linkage_ref and RT30_thisQ.lot_type_fk=@this_lottype and (RT30_thisQ.ide_sourcesys_ref <>'' or (RT30_thisQ.ide_sourcesys_ref = '' and RT30_thisQ.ide_internal_one='')))
left join AUA_LDM..recs_type_30 RT30_lastQ on (RT30.ide_linkage_type=RT30_lastQ.ide_linkage_type and RT30.ide_linkage_ref=RT30_lastQ.ide_linkage_ref and RT30_lastQ.lot_type_fk=@last_lottype and (RT30_lastQ.ide_sourcesys_ref <>'' or (RT30_lastQ.ide_sourcesys_ref = '' and RT30_lastQ.ide_internal_one='')))
left join ONESUMX..t_tfi_trn_bond trb_thisQ on (trb_thisQ.deal_id =RT30.ide_linkage_ref and trb_thisQ.start_validity_date<=@this_reportdate and trb_thisQ.end_validity_date>=@this_reportdate)
left join ONESUMX..t_tfi_trn_bond trb_lastQ on (trb_lastQ.deal_id =RT30.ide_linkage_ref and trb_lastQ.start_validity_date<=@last_reportdate and trb_lastQ.end_validity_date>=@last_reportdate)
left join ONESUMX..t_tfi_bond tfb_thisQ on (tfb_thisQ.tfi_id =trb_thisQ.tfi_id and tfb_thisQ.start_validity_date<=@this_reportdate and tfb_thisQ.end_validity_date>=@this_reportdate)
left join ONESUMX..t_tfi_bond tfb_lastQ on (tfb_lastQ.tfi_id =trb_lastQ.tfi_id and tfb_lastQ.start_validity_date<=@last_reportdate and tfb_lastQ.end_validity_date>=@last_reportdate)
left join ONESUMX..t_customer tc_thisQ on (tc_thisQ.customer_nr=trb_thisQ.customer_nr and tc_thisQ.start_validity_date<=@this_reportdate and tc_thisQ.end_validity_date>=@this_reportdate)
left join ONESUMX..t_customer tc_lastQ on (tc_lastQ.customer_nr=trb_lastQ.customer_nr and tc_lastQ.start_validity_date<=@last_reportdate and tc_lastQ.end_validity_date>=@last_reportdate)
left join ONESUMX.. t_tfi_trn_bond_valuation trbv_thisQ1 on ( trbv_thisQ1.deal_id = RT30.ide_linkage_ref and trbv_thisQ1.valuation_type='ORI BOOK VALUE'and trbv_thisQ1.valuation_date=@this_reportdate) 
left join ONESUMX.. t_tfi_trn_bond_valuation trbv_lastQ1 on ( trbv_lastQ1.deal_id = RT30.ide_linkage_ref and trbv_lastQ1.valuation_type='ORI BOOK VALUE'and trbv_lastQ1.valuation_date=@last_reportdate) 
left join ONESUMX.. t_tfi_trn_bond_valuation trbv_thisQ2 on ( trbv_thisQ2.deal_id = RT30.ide_linkage_ref and trbv_thisQ2.valuation_type='ORI MARKET VALUE'and trbv_thisQ2.valuation_date=@this_reportdate) 
left join ONESUMX.. t_tfi_trn_bond_valuation trbv_lastQ2 on ( trbv_lastQ2.deal_id = RT30.ide_linkage_ref and trbv_lastQ2.valuation_type='ORI MARKET VALUE'and trbv_lastQ2.valuation_date=@last_reportdate) 
left join ONESUMX..t_currency_rate_boc tfx_thisQ on (((trb_thisQ.currency<>'CNH' and tfx_thisQ.from_currency=trb_thisQ.currency) or (trb_thisQ.currency='CNH' and tfx_thisQ.from_currency='CNY')) and tfx_thisQ.rate_date=@this_reportdate and tfx_thisQ.entity=@entity)
left join ONESUMX..t_currency_rate_boc tfx_lastQ on (((trb_lastQ.currency<>'CNH' and tfx_lastQ.from_currency=trb_lastQ.currency) or (trb_lastQ.currency='CNH' and tfx_lastQ.from_currency='CNY')) and tfx_lastQ.rate_date=@last_reportdate and tfx_lastQ.entity=@entity)
left join ONESUMX..t_currency_rate_boc tfx_value_thisQ on (((trb_thisQ.currency<>'CNH' and tfx_value_thisQ.from_currency=trb_thisQ.currency) or (trb_thisQ.currency='CNH' and tfx_value_thisQ.from_currency='CNY')) and tfx_value_thisQ.rate_date=trb_thisQ.value_date and tfx_value_thisQ.entity=@entity)
left join ONESUMX..t_currency_rate_boc tfx_value_lastQ on (((trb_lastQ.currency<>'CNH' and tfx_value_lastQ.from_currency=trb_lastQ.currency) or (trb_lastQ.currency='CNH' and tfx_value_lastQ.from_currency='CNY')) and tfx_value_lastQ.rate_date=trb_lastQ.value_date and tfx_value_lastQ.entity=@entity)
left join ONESUMX..t_currency_rate_boc tfx_maturity_thisQ on (((trb_thisQ.currency<>'CNH' and tfx_maturity_thisQ.from_currency=trb_thisQ.currency) or (trb_thisQ.currency='CNH' and tfx_maturity_thisQ.from_currency='CNY')) and tfx_maturity_thisQ.rate_date=tfb_thisQ.maturity_date and tfx_maturity_thisQ.entity=@entity)
left join ONESUMX..t_currency_rate_boc tfx_maturity_lastQ on (((trb_lastQ.currency<>'CNH' and tfx_maturity_lastQ.from_currency=trb_lastQ.currency) or (trb_lastQ.currency='CNH' and tfx_maturity_lastQ.from_currency='CNY')) and tfx_maturity_lastQ.rate_date=tfb_lastQ.maturity_date and tfx_maturity_lastQ.entity=@entity)

where (RT30.ide_sourcesys_ref <>'' or (RT30.ide_sourcesys_ref = '' and RT30.ide_internal_one='')) 
and (RT30.ide_linkage_type in (5))
and RT30.lot_type_fk in (@last_lottype, @this_lottype)) bond


union all

--repo 1--
select * from
(select 
RT30.lot_type_fk,
RT30.ide_linkage_ref,
RT30.ide_linkage_type,
RT30.ide_sourcesys_ref,
(case when RT30.lot_type_fk=@this_lottype then trb_thisQ.deal_type else trb_lastQ.deal_type end) as 'dealtype', 
(case when RT30.lot_type_fk=@this_lottype then trb_thisQ.customer_nr else trb_lastQ.customer_nr end) as 'customer_nr', 
(case when RT30.lot_type_fk=@this_lottype then tc_thisQ.customer_legal_name else tc_lastQ.customer_legal_name end) as 'customer_name',
RT30.rv_repo,
(case when RT30.lot_type_fk=@this_lottype then RT30_lastQ.rv_cpty_type else RT30_lastQ.rv_cpty_type end) as 'rv_cpty_type_lastQ', 
RT30.rv_cpty_type as 'rv_cpty_type_thisQ',
(case when RT30.lot_type_fk=@this_lottype then RT30_lastQ.rv_rel_party_type else RT30_lastQ.rv_rel_party_type end) as 'rv_rel_party_type_lastQ', 
(case when RT30.lot_type_fk=@this_lottype then RT30_thisQ.rv_rel_party_type else RT30_lastQ.rv_rel_party_type end) as 'rv_rel_party_type_thisQ', 
(case when RT30.lot_type_fk=@this_lottype then RT30_lastQ.rv_resident else RT30_lastQ.rv_resident end) as 'rv_resident_lastQ', 
RT30.rv_resident as 'rv_resident_thisQ',
(case when RT30.lot_type_fk=@this_lottype then (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.nationality end) else (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.nationality end) end) as 'nationality_lastQ', 
(case when RT30.lot_type_fk=@this_lottype then (case when RT30_thisQ.rv_resident='YES' then 'AU' else tc_thisQ.nationality end) else (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.nationality end) end) as 'nationality_thisQ',
(case when RT30.lot_type_fk=@this_lottype then (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.domicile end) else (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.domicile end) end) as 'domicile_lastQ', 
(case when RT30.lot_type_fk=@this_lottype then (case when RT30_thisQ.rv_resident='YES' then 'AU' else tc_thisQ.domicile end) else (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.domicile end) end) as 'domicile_thisQ',
(case when RT30.lot_type_fk=@this_lottype then (case when trb_thisQ.currency='CNH' then 'CNY' else trb_thisQ.currency end) else (case when trb_lastQ.currency='CNH' then 'CNY' else trb_lastQ.currency end) end) as 'currency', 
(case when RT30.lot_type_fk=@this_lottype then trb_thisQ.value_date else trb_lastQ.value_date end) as 'value_date', 
(case when RT30.lot_type_fk=@this_lottype then tfb_thisQ.maturity_date else tfb_lastQ.maturity_date end) as 'maturity_date', 
(case when RT30.lot_type_fk=@this_lottype then (case when tfx_value_thisQ.rate is null then 0 else tfx_value_thisQ.rate end) else (case when tfx_value_lastQ.rate is null then 0 else tfx_value_lastQ.rate end) end) as 'fx_rate_value',
(case when RT30.lot_type_fk=@this_lottype then (case when tfx_maturity_thisQ.rate is null then 0 else tfx_maturity_thisQ.rate end) else (case when tfx_maturity_lastQ.rate is null then 0 else tfx_maturity_lastQ.rate end) end) as 'fx_rate_maturity',
RT30.rv_mat_original,
RT30.rv_mat_remaining,
(case when RT30.lot_type_fk=@this_lottype then trp_thisQ.notional_amount else trp_lastQ.notional_amount end) as 'nominal',
1 as 'trade_price',
(case when RT30.lot_type_fk=@this_lottype then trb_thisQ.tfi_id else trb_lastQ.tfi_id end) as 'ISIN',
(case when RT30_thisQ.rca_bookv is not null then RT30_thisQ.rca_bookv else 0 end) as 'rca_bookv_thisQ', 
(case when trbv_thisQ1.valuation_type = 'ORI BOOK VALUE' then trbv_thisQ1.amount else 0 end) as 'rca_ori_bookv_thisQ', 
(case when RT30_thisQ.rca_marketv is not null then RT30_thisQ.rca_marketv else 0 end) as 'rca_marketv_thisQ',
(case when trbv_thisQ2.valuation_type = 'ORI MARKET VALUE' then trbv_thisQ2.amount else 0 end) as 'rca_ori_marketv_thisQ', 
(case when RT30_thisQ.rca_accrint is not null then RT30_thisQ.rca_accrint else 0 end) as 'rca_accrint_thisQ',
(case when RT30_thisQ.rca_prov_coll is not null then RT30_thisQ.rca_prov_coll else 0 end) as 'rca_prov_coll_thisQ',
(case when RT30_thisQ.rca_prov_indi is not null then RT30_thisQ.rca_prov_indi else 0 end) as 'rca_prov_indi_thisQ',
(case when tfx_thisQ.rate is not null then tfx_thisQ.rate else 0 end) as 'fx_rate_thisQ',
(case when RT30_lastQ.rca_bookv is not null then RT30_lastQ.rca_bookv else 0 end) as 'rca_bookv_lastQ', 
(case when trbv_lastQ1.valuation_type = 'ORI BOOK VALUE' then trbv_lastQ1.amount else 0 end) as 'rca_ori_bookv_lastQ', 
(case when RT30_lastQ.rca_marketv is not null then RT30_lastQ.rca_marketv else 0 end) as 'rca_marketv_lastQ',
(case when trbv_lastQ2.valuation_type = 'ORI MARKET VALUE' then trbv_lastQ2.amount else 0 end) as 'rca_ori_marketv_lastQ', 
(case when RT30_lastQ.rca_accrint is not null then RT30_lastQ.rca_accrint else 0 end) as 'rca_accrint_lastQ',
(case when RT30_lastQ.rca_prov_coll is not null then RT30_lastQ.rca_prov_coll else 0 end) as 'rca_prov_coll_lastQ',
(case when RT30_lastQ.rca_prov_indi is not null then RT30_lastQ.rca_prov_indi else 0 end) as 'rca_prov_indi_lastQ',
(case when tfx_lastQ.rate is not null then tfx_lastQ.rate else 0 end) as 'fx_rate_lastQ'


from 
(select ide_internal_one, lot_type_fk, ide_linkage_ref, ide_linkage_type, ide_sourcesys_ref, rv_coa, rv_cpty_type, rv_rel_party_type, rv_resident, rv_mat_original, rv_mat_remaining, rca_bookv, rca_marketv, rca_accrint, rca_prov_coll, rca_prov_indi, rv_repo from AUA_LDM..recs_type_30 RT30_all
inner join (select ide_linkage_ref as 'max_ide_linkage_ref', max(lot_type_fk) as 'max_lot_type_fk' from AUA_LDM..recs_type_30
where lot_type_fk in (@last_lottype, @this_lottype) and (ide_sourcesys_ref <>'' or (ide_sourcesys_ref = '' and ide_internal_one='')) group by ide_linkage_ref) RT30_group
on (RT30_all.ide_linkage_ref = RT30_group.max_ide_linkage_ref and RT30_all.lot_type_fk=RT30_group.max_lot_type_fk)
where lot_type_fk in (@last_lottype, @this_lottype) and (ide_sourcesys_ref <>'' or (ide_sourcesys_ref = '' and ide_internal_one=''))) RT30

left join AUA_LDM..recs_type_30 RT30_thisQ on (RT30.ide_linkage_type=RT30_thisQ.ide_linkage_type and RT30.ide_linkage_ref=RT30_thisQ.ide_linkage_ref and RT30_thisQ.lot_type_fk=@this_lottype and (RT30_thisQ.ide_sourcesys_ref <>'' or (RT30_thisQ.ide_sourcesys_ref = '' and RT30_thisQ.ide_internal_one='')))
left join AUA_LDM..recs_type_30 RT30_lastQ on (RT30.ide_linkage_type=RT30_lastQ.ide_linkage_type and RT30.ide_linkage_ref=RT30_lastQ.ide_linkage_ref and RT30_lastQ.lot_type_fk=@last_lottype and (RT30_lastQ.ide_sourcesys_ref <>'' or (RT30_lastQ.ide_sourcesys_ref = '' and RT30_lastQ.ide_internal_one='')))
left join ONESUMX..t_tfi_trn_bond trb_thisQ on (trb_thisQ.deal_id =RT30.ide_linkage_ref and trb_thisQ.start_validity_date<=@this_reportdate and trb_thisQ.end_validity_date>=@this_reportdate)
left join ONESUMX..t_tfi_trn_bond trb_lastQ on (trb_lastQ.deal_id =RT30.ide_linkage_ref and trb_lastQ.start_validity_date<=@last_reportdate and trb_lastQ.end_validity_date>=@last_reportdate)
left join ONESUMX..t_trn_repo_style trp_thisQ on (trp_thisQ.deal_id =left(RT30.ide_linkage_ref,9) and trp_thisQ.start_validity_date<=@this_reportdate and trp_thisQ.end_validity_date>=@this_reportdate)
left join ONESUMX..t_trn_repo_style trp_lastQ on (trp_lastQ.deal_id =left(RT30.ide_linkage_ref,9) and trp_lastQ.start_validity_date<=@last_reportdate and trp_lastQ.end_validity_date>=@last_reportdate)
left join ONESUMX..t_tfi_bond tfb_thisQ on (tfb_thisQ.tfi_id =trb_thisQ.tfi_id and tfb_thisQ.start_validity_date<=@this_reportdate and tfb_thisQ.end_validity_date>=@this_reportdate)
left join ONESUMX..t_tfi_bond tfb_lastQ on (tfb_lastQ.tfi_id =trb_lastQ.tfi_id and tfb_lastQ.start_validity_date<=@last_reportdate and tfb_lastQ.end_validity_date>=@last_reportdate)
left join ONESUMX..t_customer tc_thisQ on (tc_thisQ.customer_nr=trb_thisQ.customer_nr and tc_thisQ.start_validity_date<=@this_reportdate and tc_thisQ.end_validity_date>=@this_reportdate)
left join ONESUMX..t_customer tc_lastQ on (tc_lastQ.customer_nr=trb_lastQ.customer_nr and tc_lastQ.start_validity_date<=@last_reportdate and tc_lastQ.end_validity_date>=@last_reportdate)
left join ONESUMX.. t_tfi_trn_bond_valuation trbv_thisQ1 on ( trbv_thisQ1.deal_id = RT30.ide_linkage_ref and trbv_thisQ1.valuation_type='ORI BOOK VALUE'and trbv_thisQ1.valuation_date=@this_reportdate) 
left join ONESUMX.. t_tfi_trn_bond_valuation trbv_lastQ1 on ( trbv_lastQ1.deal_id = RT30.ide_linkage_ref and trbv_lastQ1.valuation_type='ORI BOOK VALUE'and trbv_lastQ1.valuation_date=@last_reportdate) 
left join ONESUMX.. t_tfi_trn_bond_valuation trbv_thisQ2 on ( trbv_thisQ2.deal_id = RT30.ide_linkage_ref and trbv_thisQ2.valuation_type='ORI MARKET VALUE'and trbv_thisQ2.valuation_date=@this_reportdate) 
left join ONESUMX.. t_tfi_trn_bond_valuation trbv_lastQ2 on ( trbv_lastQ2.deal_id = RT30.ide_linkage_ref and trbv_lastQ2.valuation_type='ORI MARKET VALUE'and trbv_lastQ2.valuation_date=@last_reportdate) 
left join ONESUMX..t_currency_rate_boc tfx_thisQ on (((trb_thisQ.currency<>'CNH' and tfx_thisQ.from_currency=trb_thisQ.currency) or (trb_thisQ.currency='CNH' and tfx_thisQ.from_currency='CNY')) and tfx_thisQ.rate_date=@this_reportdate and tfx_thisQ.entity=@entity)
left join ONESUMX..t_currency_rate_boc tfx_lastQ on (((trb_lastQ.currency<>'CNH' and tfx_lastQ.from_currency=trb_lastQ.currency) or (trb_lastQ.currency='CNH' and tfx_lastQ.from_currency='CNY')) and tfx_lastQ.rate_date=@last_reportdate and tfx_lastQ.entity=@entity)
left join ONESUMX..t_currency_rate_boc tfx_value_thisQ on (((trb_thisQ.currency<>'CNH' and tfx_value_thisQ.from_currency=trb_thisQ.currency) or (trb_thisQ.currency='CNH' and tfx_value_thisQ.from_currency='CNY')) and tfx_value_thisQ.rate_date=trb_thisQ.value_date and tfx_value_thisQ.entity=@entity)
left join ONESUMX..t_currency_rate_boc tfx_value_lastQ on (((trb_lastQ.currency<>'CNH' and tfx_value_lastQ.from_currency=trb_lastQ.currency) or (trb_lastQ.currency='CNH' and tfx_value_lastQ.from_currency='CNY')) and tfx_value_lastQ.rate_date=trb_lastQ.value_date and tfx_value_lastQ.entity=@entity)
left join ONESUMX..t_currency_rate_boc tfx_maturity_thisQ on (((trb_thisQ.currency<>'CNH' and tfx_maturity_thisQ.from_currency=trb_thisQ.currency) or (trb_thisQ.currency='CNH' and tfx_maturity_thisQ.from_currency='CNY')) and tfx_maturity_thisQ.rate_date=tfb_thisQ.maturity_date and tfx_maturity_thisQ.entity=@entity)
left join ONESUMX..t_currency_rate_boc tfx_maturity_lastQ on (((trb_lastQ.currency<>'CNH' and tfx_maturity_lastQ.from_currency=trb_lastQ.currency) or (trb_lastQ.currency='CNH' and tfx_maturity_lastQ.from_currency='CNY')) and tfx_maturity_lastQ.rate_date=tfb_lastQ.maturity_date and tfx_maturity_lastQ.entity=@entity)

where (RT30.ide_sourcesys_ref <>'' or (RT30.ide_sourcesys_ref = '' and RT30.ide_internal_one='')) 
and RT30.ide_linkage_type in (10)
and RT30.lot_type_fk in (@last_lottype, @this_lottype)) repo


union all

--backoffice--
select * from
(select 
RT30.lot_type_fk,
RT30.ide_linkage_ref,
RT30.ide_linkage_type,
RT30.ide_sourcesys_ref,
left(RT30.ide_linkage_ref,4) as 'dealtype', 
(case when RT30.lot_type_fk=@this_lottype then tbo_thisQ.customer_nr else tbo_lastQ.customer_nr end) as 'customer_nr', 
(case when RT30.lot_type_fk=@this_lottype then tc_thisQ.customer_legal_name else tc_lastQ.customer_legal_name end) as 'customer_name',
RT30.rv_coa,
(case when RT30.lot_type_fk=@this_lottype then RT30_lastQ.rv_cpty_type else RT30_lastQ.rv_cpty_type end) as 'rv_cpty_type_lastQ', 
RT30.rv_cpty_type as 'rv_cpty_type_thisQ',
(case when RT30.lot_type_fk=@this_lottype then RT30_lastQ.rv_rel_party_type else RT30_lastQ.rv_rel_party_type end) as 'rv_rel_party_type_lastQ', 
(case when RT30.lot_type_fk=@this_lottype then RT30_thisQ.rv_rel_party_type else RT30_lastQ.rv_rel_party_type end) as 'rv_rel_party_type_thisQ', 
(case when RT30.lot_type_fk=@this_lottype then RT30_lastQ.rv_resident else RT30_lastQ.rv_resident end) as 'rv_resident_lastQ', 
RT30.rv_resident as 'rv_resident_thisQ',
(case when RT30.lot_type_fk=@this_lottype then (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.nationality end) else (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.nationality end) end) as 'nationality_lastQ', 
(case when RT30.lot_type_fk=@this_lottype then (case when RT30_thisQ.rv_resident='YES' then 'AU' else tc_thisQ.nationality end) else (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.nationality end) end) as 'nationality_thisQ',
(case when RT30.lot_type_fk=@this_lottype then (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.domicile end) else (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.domicile end) end) as 'domicile_lastQ', 
(case when RT30.lot_type_fk=@this_lottype then (case when RT30_thisQ.rv_resident='YES' then 'AU' else tc_thisQ.domicile end) else (case when RT30_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.domicile end) end) as 'domicile_thisQ',
(case when RT30.lot_type_fk=@this_lottype then (case when tbo_thisQ.currency='CNH' then 'CNY' else tbo_thisQ.currency end) else (case when tbo_lastQ.currency='CNH' then 'CNY' else tbo_lastQ.currency end) end) as 'currency', 
(case when RT30.lot_type_fk=@this_lottype then @this_reportdate else @last_reportdate end) as 'value_date',
(case when RT30.lot_type_fk=@this_lottype then @this_reportdate else @last_reportdate end) as 'maturity_date',
0 as 'fx_rate_value',
0 as 'fx_rate_maturity',
RT30.rv_mat_original,
RT30.rv_mat_remaining,
0 as 'nominal',
0 as 'trade_price',
'NA' as 'ISIN',
(case when RT30_thisQ.rca_bookv is not null then RT30_thisQ.rca_bookv else 0 end) as 'rca_bookv_thisQ', 
0 as 'rca_ori_bookv_thisQ', 
(case when RT30_thisQ.rca_marketv is not null then RT30_thisQ.rca_marketv else 0 end) as 'rca_marketv_thisQ',
0 as 'rca_ori_marketv_thisQ', 
(case when RT30_thisQ.rca_accrint is not null then RT30_thisQ.rca_accrint else 0 end) as 'rca_accrint_thisQ',
(case when RT30_thisQ.rca_prov_coll is not null then RT30_thisQ.rca_prov_coll else 0 end) as 'rca_prov_coll_thisQ',
(case when RT30_thisQ.rca_prov_indi is not null then RT30_thisQ.rca_prov_indi else 0 end) as 'rca_prov_indi_thisQ',
(case when tfx_thisQ.rate is not null then tfx_thisQ.rate else 0 end) as 'fx_rate_thisQ',
(case when RT30_lastQ.rca_bookv is not null then RT30_lastQ.rca_bookv else 0 end) as 'rca_bookv_lastQ', 
0 as 'rca_ori_bookv_lastQ', 
(case when RT30_lastQ.rca_marketv is not null then RT30_lastQ.rca_marketv else 0 end) as 'rca_marketv_lastQ',
0 as 'rca_ori_marketv_lastQ', 
(case when RT30_lastQ.rca_accrint is not null then RT30_lastQ.rca_accrint else 0 end) as 'rca_accrint_lastQ',
(case when RT30_lastQ.rca_prov_coll is not null then RT30_lastQ.rca_prov_coll else 0 end) as 'rca_prov_coll_lastQ',
(case when RT30_lastQ.rca_prov_indi is not null then RT30_lastQ.rca_prov_indi else 0 end) as 'rca_prov_indi_lastQ',
(case when tfx_lastQ.rate is not null then tfx_lastQ.rate else 0 end) as 'fx_rate_lastQ'


from 
(select ide_internal_one, lot_type_fk, ide_linkage_ref, ide_linkage_type, ide_sourcesys_ref, rv_coa, rv_cpty_type, rv_rel_party_type, rv_resident, rv_mat_original, rv_mat_remaining, rca_bookv, rca_marketv, rca_accrint, rca_prov_coll, rca_prov_indi from AUA_LDM..recs_type_30 RT30_all
inner join (select ide_linkage_ref as 'max_ide_linkage_ref', max(lot_type_fk) as 'max_lot_type_fk' from AUA_LDM..recs_type_30
where lot_type_fk in (@last_lottype, @this_lottype) and (ide_sourcesys_ref <>'' or (ide_sourcesys_ref = '' and ide_internal_one='')) group by ide_linkage_ref) RT30_group
on (RT30_all.ide_linkage_ref = RT30_group.max_ide_linkage_ref and RT30_all.lot_type_fk=RT30_group.max_lot_type_fk)
where lot_type_fk in (@last_lottype, @this_lottype) and (ide_sourcesys_ref <>'' or (ide_sourcesys_ref = '' and ide_internal_one=''))) RT30

left join AUA_LDM..recs_type_30 RT30_thisQ on (RT30.ide_linkage_type=RT30_thisQ.ide_linkage_type and RT30.ide_linkage_ref=RT30_thisQ.ide_linkage_ref and RT30_thisQ.lot_type_fk=@this_lottype and (RT30_thisQ.ide_sourcesys_ref <>'' or (RT30_thisQ.ide_sourcesys_ref = '' and RT30_thisQ.ide_internal_one='')))
left join AUA_LDM..recs_type_30 RT30_lastQ on (RT30.ide_linkage_type=RT30_lastQ.ide_linkage_type and RT30.ide_linkage_ref=RT30_lastQ.ide_linkage_ref and RT30_lastQ.lot_type_fk=@last_lottype and (RT30_lastQ.ide_sourcesys_ref <>'' or (RT30_lastQ.ide_sourcesys_ref = '' and RT30_lastQ.ide_internal_one='')))
left join ONESUMX..t_back_office_balance_boc tbo_thisQ on (tbo_thisQ.deal_id =RT30.ide_linkage_ref and tbo_thisQ.balance_date=@this_reportdate)
left join ONESUMX..t_back_office_balance_boc tbo_lastQ on (tbo_lastQ.deal_id =RT30.ide_linkage_ref and tbo_lastQ.balance_date=@last_reportdate)
left join ONESUMX..t_customer tc_thisQ on (tc_thisQ.customer_nr=tbo_thisQ.customer_nr and tc_thisQ.start_validity_date<=@this_reportdate and tc_thisQ.end_validity_date>=@this_reportdate)
left join ONESUMX..t_customer tc_lastQ on (tc_lastQ.customer_nr=tbo_lastQ.customer_nr and tc_lastQ.start_validity_date<=@last_reportdate and tc_lastQ.end_validity_date>=@last_reportdate)
left join ONESUMX..t_currency_rate_boc tfx_thisQ on (((tbo_thisQ.currency<>'CNH' and tfx_thisQ.from_currency=tbo_thisQ.currency) or (tbo_thisQ.currency='CNH' and tfx_thisQ.from_currency='CNY')) and tfx_thisQ.rate_date=@this_reportdate and tfx_thisQ.entity=@entity)
left join ONESUMX..t_currency_rate_boc tfx_lastQ on (((tbo_lastQ.currency<>'CNH' and tfx_lastQ.from_currency=tbo_lastQ.currency) or (tbo_lastQ.currency='CNH' and tfx_lastQ.from_currency='CNY')) and tfx_lastQ.rate_date=@last_reportdate and tfx_lastQ.entity=@entity)

where (RT30.ide_sourcesys_ref <>'' or (RT30.ide_sourcesys_ref = '' and RT30.ide_internal_one='')) 
and RT30.ide_linkage_type in (1)
and RT30.lot_type_fk in (@last_lottype, @this_lottype)) backoffice

union all

--RT35--
select * from
(select 
RT35.lot_type_fk,
RT35.ide_linkage_ref,
RT35.ide_linkage_type,
RT35.ide_sourcesys_ref,
left(RT35.ide_linkage_ref,4) as 'dealtype', 
(case when RT35.lot_type_fk=@this_lottype then tbo_thisQ.customer_nr else tbo_lastQ.customer_nr end) as 'customer_nr', 
(case when RT35.lot_type_fk=@this_lottype then tc_thisQ.customer_legal_name else tc_lastQ.customer_legal_name end) as 'customer_name',
RT35.rv_coa_pl,
(case when RT35.lot_type_fk=@this_lottype then RT35_lastQ.rv_cpty_type else RT35_lastQ.rv_cpty_type end) as 'rv_cpty_type_lastQ', 
RT35.rv_cpty_type as 'rv_cpty_type_thisQ',
(case when RT35.lot_type_fk=@this_lottype then tc_lastQ.intercompany else tc_lastQ.intercompany end) as 'rv_rel_party_type_lastQ', 
(case when RT35.lot_type_fk=@this_lottype then tc_thisQ.intercompany else tc_lastQ.intercompany end) as 'rv_rel_party_type_thisQ', 
(case when RT35.lot_type_fk=@this_lottype then RT35_lastQ.rv_resident else RT35_lastQ.rv_resident end) as 'rv_resident_lastQ', 
RT35.rv_resident as 'rv_resident_thisQ',
(case when RT35.lot_type_fk=@this_lottype then (case when RT35_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.nationality end) else (case when RT35_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.nationality end) end) as 'nationality_lastQ', 
(case when RT35.lot_type_fk=@this_lottype then (case when RT35_thisQ.rv_resident='YES' then 'AU' else tc_thisQ.nationality end) else (case when RT35_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.nationality end) end) as 'nationality_thisQ',
(case when RT35.lot_type_fk=@this_lottype then (case when RT35_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.domicile end) else (case when RT35_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.domicile end) end) as 'domicile_lastQ', 
(case when RT35.lot_type_fk=@this_lottype then (case when RT35_thisQ.rv_resident='YES' then 'AU' else tc_thisQ.domicile end) else (case when RT35_lastQ.rv_resident='YES' then 'AU' else tc_lastQ.domicile end) end) as 'domicile_thisQ',
(case when RT35.lot_type_fk=@this_lottype then (case when tbo_thisQ.currency='CNH' then 'CNY' else tbo_thisQ.currency end) else (case when tbo_lastQ.currency='CNH' then 'CNY' else tbo_lastQ.currency end) end) as 'currency', 
(case when RT35.lot_type_fk=@this_lottype then @this_reportdate else @last_reportdate end) as 'value_date',
(case when RT35.lot_type_fk=@this_lottype then @this_reportdate else @last_reportdate end) as 'maturity_date',
0 as 'fx_rate_value',
0 as 'fx_rate_maturity',
0 as 'rv_mat_original',
0 as 'rv_mat_remaining',
0 as 'nominal',
0 as 'trade_price',
'NA' as 'ISIN',
(case when RT35_thisQ.rca_bookv_ytd is not null then RT35_thisQ.rca_bookv_ytd else 0 end) as 'rca_bookv_thisQ', 
0 as 'rca_ori_bookv_thisQ', 
0 as 'rca_marketv_thisQ',
0 as 'rca_ori_marketv_thisQ',
0 as 'rca_accrint_thisQ',
0 as 'rca_prov_coll_thisQ',
0 as 'rca_prov_indi_thisQ',
(case when tfx_thisQ.rate is not null then tfx_thisQ.rate else 0 end) as 'fx_rate_thisQ',
(case when RT35_lastQ.rca_bookv_ytd is not null then RT35_lastQ.rca_bookv_ytd else 0 end) as 'rca_bookv_lastQ', 
0 as 'rca_ori_bookv_lastQ', 
0 as 'rca_marketv_lastQ',
0 as 'rca_ori_marketv_lastQ',
0 as 'rca_accrint_lastQ',
0 as 'rca_prov_coll_lastQ',
0 as 'rca_prov_indi_lastQ',
(case when tfx_lastQ.rate is not null then tfx_lastQ.rate else 0 end) as 'fx_rate_lastQ'


from 
(select lot_type_fk, ide_linkage_ref, ide_linkage_type, ide_sourcesys_ref, rv_coa_pl, rv_cpty_type, rv_resident, rca_bookv_ytd from AUA_LDM..recs_type_35 RT35_all
inner join (select ide_linkage_ref as 'max_ide_linkage_ref', max(lot_type_fk) as 'max_lot_type_fk' from AUA_LDM..recs_type_35
where lot_type_fk in (@last_lottype, @this_lottype) and ide_linkage_type in (1) group by ide_linkage_ref) RT35_group
on (RT35_all.ide_linkage_ref = RT35_group.max_ide_linkage_ref and RT35_all.lot_type_fk=RT35_group.max_lot_type_fk)) RT35

left join AUA_LDM..recs_type_35 RT35_thisQ on (RT35.ide_linkage_type=RT35_thisQ.ide_linkage_type and RT35.ide_linkage_ref=RT35_thisQ.ide_linkage_ref and RT35_thisQ.lot_type_fk=@this_lottype and RT35_thisQ.ide_linkage_type in (1))
left join AUA_LDM..recs_type_35 RT35_lastQ on (RT35.ide_linkage_type=RT35_lastQ.ide_linkage_type and RT35.ide_linkage_ref=RT35_lastQ.ide_linkage_ref and RT35_lastQ.lot_type_fk=@last_lottype and RT35_lastQ.ide_linkage_type in (1))
left join ONESUMX..t_back_office_balance_boc tbo_thisQ on (tbo_thisQ.deal_id =RT35.ide_linkage_ref and tbo_thisQ.balance_date=@this_reportdate)
left join ONESUMX..t_back_office_balance_boc tbo_lastQ on (tbo_lastQ.deal_id =RT35.ide_linkage_ref and tbo_lastQ.balance_date=@last_reportdate)
left join ONESUMX..t_customer tc_thisQ on (tc_thisQ.customer_nr=tbo_thisQ.customer_nr and tc_thisQ.start_validity_date<=@this_reportdate and tc_thisQ.end_validity_date>=@this_reportdate)
left join ONESUMX..t_customer tc_lastQ on (tc_lastQ.customer_nr=tbo_lastQ.customer_nr and tc_lastQ.start_validity_date<=@last_reportdate and tc_lastQ.end_validity_date>=@last_reportdate)
left join ONESUMX..t_currency_rate_boc tfx_thisQ on (tfx_thisQ.from_currency=tbo_thisQ.currency and tfx_thisQ.rate_date=@this_reportdate and tfx_thisQ.entity=@entity)
left join ONESUMX..t_currency_rate_boc tfx_lastQ on (tfx_lastQ.from_currency=tbo_lastQ.currency and tfx_lastQ.rate_date=@last_reportdate and tfx_lastQ.entity=@entity)

where RT35.ide_linkage_type in (1)
and RT35.lot_type_fk in (@last_lottype, @this_lottype)
and (RT35.rv_coa_pl like 'INC%' or RT35.rv_coa_pl like 'EXP%')) PL



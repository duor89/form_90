declare @reportdate date
declare @entity int
declare @lottype int;

--###please report date below###--
set @reportdate = '2024-09-30'
set @entity = '106'
set @lottype = '992'
--###input end##--


--------------------------------------facility--------------------------------------------------------

select t_facility.entity, 
t_facility.facility_nr, 
t_facility.customer_nr, 
t_facility.deal_type, 
right(t_facility.deal_type, 4) as ap_code,
t_facility.currency, 
(case when t_facility_valuation.valuation_type = 'OBS Commitment' then t_facility_valuation.amount else 0 end) as 'OBS amount', 
t_facility.ccy_amount, 
(case when t_customer.customer_attribute1 is not null then t_customer.customer_attribute1 else 'N/A' end) as 'Counterparty type', 
(case when t_customer.domicile is not null then t_customer.domicile else 'N/A' end) as 'Domicile'

from ONESUMX..t_facility 

left join ONESUMX..t_facility_valuation on (t_facility_valuation.facility_nr =t_facility.facility_nr and t_facility_valuation.valuation_type='OBS Commitment'and t_facility_valuation.valuation_date=@reportdate) 

left join ONESUMX..t_customer on (t_customer.customer_nr=t_facility.customer_nr and t_customer.start_validity_date<=@reportdate and t_customer.end_validity_date>=@reportdate)

where t_facility.start_validity_date<=@reportdate and t_facility.end_validity_date>=@reportdate and t_facility.entity=@entity



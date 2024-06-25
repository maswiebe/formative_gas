*************************************************************
** This file makes performs panel analyses from all census 
** data years.
*************************************************************

/* local 	logf "`1'" 
log using "`logf'", replace text */

use 	"./output/censusall_prepped.dta", clear

********************************
** Ensure Sample Restrictions

keep if bpl<100
drop if farm==2

drop if age<=24
drop if age>54

********************************
********************************
** Gas Price Merge	 		****
********************************
********************************

drop	hhwt metro puma conspuma cpuma0010 ownershp hhincome vehicles pernum relate ///
			related pwpuma00 tranwork trantime autos trucks e_* w_* d_*

tab 	year multyear

gen 	year_all = year
replace year_all = multyear if year==2010 | year==2015
tab		year_all

drop 	year 
rename 	year_all censusyear_all

rename 	statefip stfip
rename 	bpl statefip

local 	agelist 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29

foreach age of local agelist {
	gen 	year = birthyr + `age'

	merge m:1 year statefip using "./output/gasprice_prepped.dta", keepusing(gas_price gas_price_99 d1gp_bp d2gp_bp) gen(_merge`age')

	rename	gas_price gas_price_at`age'
	rename	gas_price_99 real_gp_at`age'
	rename	d1gp_bp  d1gp_bp_at`age'
	rename	d2gp_bp  d2gp_bp_at`age'

	drop if _merge`age'==2

	rename 	year yr_age`age'
	lab var yr_age`age' "Year Turned `age'" 
}

/* 	_merge==1 are years with older people but no gasoline data
	_merge==2 are years that are not yet adulted
*/

drop if _merge16!=3
drop	_merge*

rename 	statefip bpl

********************************
********************************
** Panel Regressions 		 ***
********************************
********************************

gen 	age2 = age*age

drop 	gas_price_at?? d2gp_bp_at??

egen	stcenyr_fe = group(stfip censusyear_all)	
egen 	bplcohort = group(bpl yr_age16)

drop	yr_age??

drop if perwt==0
drop if bpl==2
drop if bpl==15
	/* Gas Price panel balanaced except AK HI */

compress

** Table 4 (partial) **


lab var d1gp_bp_at13 "$\Delta P(13,12)$"
lab var d1gp_bp_at14 "$\Delta P(14,13)$"
lab var d1gp_bp_at15 "$\Delta P(15,14)$"
lab var d1gp_bp_at16 "$\Delta P(16,15)$"
lab var d1gp_bp_at17 "$\Delta P(17,16)$"
lab var d1gp_bp_at18 "$\Delta P(18,17)$"
lab var d1gp_bp_at19 "$\Delta P(19,18)$"
lab var d1gp_bp_at20 "$\Delta P(20,19)$"


qui eststo tc1a_1: reghdfe t_transit d1gp_bp_at14 d1gp_bp_at15 d1gp_bp_at16 d1gp_bp_at17 ///
					d1gp_bp_at18 d1gp_bp_at19 if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
qui eststo tc1a_2: reghdfe t_transit d1gp_bp_at13 d1gp_bp_at14 d1gp_bp_at15 d1gp_bp_at16 d1gp_bp_at17 ///
					d1gp_bp_at18 d1gp_bp_at19 d1gp_bp_at20 if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
qui eststo tc1a_3: reghdfe t_vehicle d1gp_bp_at14 d1gp_bp_at15 d1gp_bp_at16 d1gp_bp_at17 ///
					d1gp_bp_at18 d1gp_bp_at19 if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
qui eststo tc1a_4: reghdfe t_vehicle d1gp_bp_at13 d1gp_bp_at14 d1gp_bp_at15 d1gp_bp_at16 d1gp_bp_at17 ///
					d1gp_bp_at18 d1gp_bp_at19 d1gp_bp_at20 if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)

local tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) order(d1gp_bp_at13 d1gp_bp_at14 d1gp_bp_at15 d1gp_bp_at16 d1gp_bp_at17 d1gp_bp_at18 d1gp_bp_at19 d1gp_bp_at20) nocons mtitles("$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$")

esttab 	tc1a_*, replace `tabprefs' 
esttab 	tc1a_* using "$tables/table4_other_outcomes.tex", replace `tabprefs' 

*local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2 N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 
*esttab 	tc1a_* using "./results/table4/census_reald1ages_13-20.tex", booktabs replace `tabprefs' 

*eststo clear		

** Input for Figure 4 (partial) **			
/* 					
local timevars d1gp_bp_at13 d1gp_bp_at14 d1gp_bp_at15 d1gp_bp_at16 d1gp_bp_at17 d1gp_bp_at18 ///
				d1gp_bp_at19 d1gp_bp_at20 d1gp_bp_at21 d1gp_bp_at22 d1gp_bp_at23 d1gp_bp_at24 ///
				d1gp_bp_at25 

reghdfe t_drive `timevars' if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)

postfile handle str32 varname float(b se) using "./results/figures/census_reald1ages_long", replace
foreach v of local timevars {
	post handle ("`v'") (_b[`v']) (_se[`v'])
}
postclose handle

eststo clear

log close
clear */



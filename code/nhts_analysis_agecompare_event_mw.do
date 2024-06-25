* Last update 3-18-2019
*==============================================================================*
*                      	   NHTS analysis do file                               *
*==============================================================================*
* This program uses 1990 and later NHTS data to investigate driving decisions.

*local 	logf "`1'" 
*log using "`logf'", replace text

use 	"./output/NHTScombined_per.dta", clear

**************************************
******* Merge in Gas Price ***********
**************************************

rename whomain_age age

tab		age
drop if age<=24
drop if age>54
drop 	_merge

** MW: have non-numeric values in hhstfips
replace hhstfips="" if hhstfips=="XX" | hhstfips=="."
destring hhstfips, replace
rename hhstfips statefip

/* ADD IN DL DATA */
gen		yr_at16 = yr_16_new
rename 	statefip stfip
merge m:1 stfip yr_at16  using "./output/dlpanel_prepped.dta"
keep	if _merge==3 /* Unmatched are post 2008 or pre 1967 */
drop	_merge year yr_at16
rename 	stfip statefip
/* END: Add in DL */

local 	agelist 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30

foreach age of local agelist {
	gen 	year = yr_16_new + (`age' - 16)

	merge m:1 year statefip using "./output/gasprice_prepped.dta", keepusing(gas_price gas_price_99 d1gp_bp d2gp_bp) gen(_merge`age')

	rename	gas_price gas_price_at`age'
	rename	gas_price_99 real_gp_at`age'
	rename	d1gp_bp d1gp_now_at`age'
	rename	d2gp_bp d2gp_now_at`age'

	drop if _merge`age'==2

	rename 	year yr_age`age'
	lab var yr_age`age' "Year Turned `age'" 
}

/* 	_merge==1 are years with older people but no gasoline data
	_merge==2 are years that are not yet adulted
*/

drop if _merge16!=3
drop	_merge*

foreach diff of numlist 1/4 {
	gen 	year = round(min_age_full) + (yr_16_new - 16) - `diff'

	merge m:1 year statefip using "./output/gasprice_prepped.dta", keepusing(gas_price gas_price_99 d1gp_bp d2gp_bp) gen(_mergen`diff')

	rename	gas_price gas_price_atn`diff'
	rename	gas_price_99 real_gp_atn`diff'
	rename	d1gp_bp  d1gp_now_atn`diff'
	rename	d2gp_bp  d2gp_now_atn`diff'

	drop if _mergen`diff'==2

	rename 	year yr_fulln`diff'
	lab var yr_fulln`diff' "Year before/after (`diff') full age" 
}

foreach diff of numlist 0/6 {
	gen 	year = round(min_age_full) + (yr_16_new - 16) + `diff'

	merge m:1 year statefip using "./output/gasprice_prepped.dta", keepusing(gas_price gas_price_99 d1gp_bp d2gp_bp) gen(_mergep`diff')

	rename	gas_price gas_price_atp`diff'
	rename	gas_price_99 real_gp_atp`diff'
	rename	d1gp_bp  d1gp_now_atp`diff'
	rename	d2gp_bp  d2gp_now_atp`diff'

	drop if _mergep`diff'==2

	rename 	year yr_fullp`diff'
	lab var yr_fullp`diff' "Year before/after (`diff') full age" 
}

drop if statename=="HI"
drop if statename=="AK"
	/* Gas Price panel balanaced except AK HI */

gen 	age2 = age*age

gen		white = (hh_race==1)
gen		urban_bin = 0
replace	urban_bin = 1 if urban==1 & nhtsyear<=1995 & urban!=.
replace	urban_bin = 1 if urban<=3 & nhtsyear>=2001 & urban!=.

replace htppopdn_cont = . if htppopdn_cont==-9
replace htppopdn_cont = . if htppopdn_cont==0
replace htppopdn_cont = . if htppopdn_cont==999998
gen		ldens_all = ln(htppopdn_cont)

gen		htppopdn_cont30 = htppopdn_cont
replace htppopdn_cont30 = 30000 if htppopdn_cont>30000 & !mi(htppopdn_cont) // Top coded in 2009/17
gen		ldens30 = ln(htppopdn_cont30)

gen		htppopdn_stand = htppopdn_cont if nhtsyear==2009 | nhtsyear==2017
replace htppopdn_stand = 50 if nhtsyear<=2001 & htppopdn_cont>=0 & htppopdn_cont<100
replace htppopdn_stand = 300 if nhtsyear<=2001 & htppopdn_cont>=100 & htppopdn_cont<500
replace htppopdn_stand = 750 if nhtsyear<=2001 & htppopdn_cont>=500 & htppopdn_cont<1000
replace htppopdn_stand = 1500 if nhtsyear<=2001 & htppopdn_cont>=1000 & htppopdn_cont<2000
replace htppopdn_stand = 3000 if nhtsyear<=2001 & htppopdn_cont>=2000 & htppopdn_cont<4000
replace htppopdn_stand = 7000 if nhtsyear<=2001 & htppopdn_cont>=4000 & htppopdn_cont<10000
replace htppopdn_stand = 17000 if nhtsyear<=2001 & htppopdn_cont>=10000 & htppopdn_cont<25000
replace htppopdn_stand = 30000 if nhtsyear<=2001 & htppopdn_cont>=25000 & htppopdn_cont<300000 
 /* Verified max legit value is 220815.7 */
gen		ldens = ln(htppopdn_stand)

/* Income bins (quintiles), see Table H-1 and H-3 */
	/* https://www.census.gov/data/tables/time-series/demo/income-poverty/historical-income-households.html */

gen		hhi_bin = .

replace hhi_bin = 1 if nhtsyear==1990 & (hhincome==1 | hhincome==2 | hhincome==3)
replace hhi_bin = 1 if nhtsyear==1995 & (hhincome==1 | hhincome==2 | hhincome==3)
replace hhi_bin = 1 if nhtsyear==2001 & (hhincome==1 | hhincome==2 | hhincome==3 | hhincome==4)
replace hhi_bin = 1 if nhtsyear==2009 & (hhincome==1 | hhincome==2 | hhincome==3 | hhincome==4)
replace hhi_bin = 1 if nhtsyear==2017 & (hhincome==1 | hhincome==2 | hhincome==3)

replace hhi_bin = 2 if nhtsyear==1990 & (hhincome==4 | hhincome==5)
replace hhi_bin = 2 if nhtsyear==1995 & (hhincome==4 | hhincome==5)
replace hhi_bin = 2 if nhtsyear==2001 & (hhincome==5 | hhincome==6 | hhincome==7 )
replace hhi_bin = 2 if nhtsyear==2009 & (hhincome==5 | hhincome==6 | hhincome==7 | hhincome==8)
replace hhi_bin = 2 if nhtsyear==2017 & (hhincome==4 | hhincome==5)

replace hhi_bin = 3 if nhtsyear==1990 & (hhincome==6 | hhincome==7)
replace hhi_bin = 3 if nhtsyear==1995 & (hhincome==6 | hhincome==7 | hhincome==8)
replace hhi_bin = 3 if nhtsyear==2001 & (hhincome==8 | hhincome==9 | hhincome==10 | hhincome==11)
replace hhi_bin = 3 if nhtsyear==2009 & (hhincome==9 | hhincome==10 | hhincome==11 | hhincome==12)
replace hhi_bin = 3 if nhtsyear==2017 & (hhincome==6)

replace hhi_bin = 4 if nhtsyear==1990 & (hhincome==8 | hhincome==9 | hhincome==10 | hhincome==11)
replace hhi_bin = 4 if nhtsyear==1995 & (hhincome==9 | hhincome==10 | hhincome==11 | hhincome==12 | hhincome==13)
replace hhi_bin = 4 if nhtsyear==2001 & (hhincome==12 | hhincome==13 | hhincome==14 | hhincome==15 | hhincome==16)
replace hhi_bin = 4 if nhtsyear==2009 & (hhincome==13 | hhincome==14 | hhincome==15 | hhincome==16 | hhincome==17)
replace hhi_bin = 4 if nhtsyear==2017 & (hhincome==7 | hhincome==8)

replace hhi_bin = 5 if nhtsyear==1990 & (hhincome==12 | hhincome==13 | hhincome==14 | hhincome==15 | hhincome==16 | hhincome==17)
replace hhi_bin = 5 if nhtsyear==1995 & (hhincome==14 | hhincome==15 | hhincome==16 | hhincome==17 | hhincome==18)
replace hhi_bin = 5 if nhtsyear==2001 & (hhincome==17 | hhincome==18)
replace hhi_bin = 5 if nhtsyear==2009 & (hhincome==18)
replace hhi_bin = 5 if nhtsyear==2017 & (hhincome==9 | hhincome==10 | hhincome==11)

tab hhi_bin nhtsyear

egen 	stateid = group(statefip)
egen	stsamyr_fe = group(statefip nhtsyear)	
egen	hhi_bin_yr = group(hhi_bin nhtsyear)

gen 	anyhhveh = .
replace anyhhveh = 0 if hhvehcnt==0
replace anyhhveh = 1 if hhvehcnt>0 & mi(hhvehcnt)==0

gen 	expfllprr = round(expfllpr) /* for use with ppmlhdfe, which doesn't accept aw */

egen 	age_f_grps=cut(min_age_full), at(15(1)19)
replace age_f_grps=16 if age_f_grps==15

egen 	age_i_grps=cut(min_int_age), at(14(1)17)
replace age_i_grps=15 if age_i_grps==14	

gen		byr = yr_16_new-16

sum miles_per_psn
sum miles_per_psn if miles_per_psn>0

/* Define treatment using all vehicle data, enforce topcode of 115k miles */

gen		lvmt_pc 	= log(min(miles_per_psn_ALL,115000))

compress 

********************************
** Panel Regressions 		 ***
********************************

** ** ** **

** Table 4 (partial) **

lab var d1gp_now_at13 "$\Delta P(13,12)$"
lab var d1gp_now_at14 "$\Delta P(14,13)$"
lab var d1gp_now_at15 "$\Delta P(15,14)$"
lab var d1gp_now_at16 "$\Delta P(16,15)$"
lab var d1gp_now_at17 "$\Delta P(17,16)$"
lab var d1gp_now_at18 "$\Delta P(18,17)$"
lab var d1gp_now_at19 "$\Delta P(19,18)$"
lab var d1gp_now_at20 "$\Delta P(20,19)$"

eststo tc1a_1: reghdfe lvmt_pc d1gp_now_at14 d1gp_now_at15 d1gp_now_at16 d1gp_now_at17 ///
					d1gp_now_at18 d1gp_now_at19 [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1a_2: reghdfe lvmt_pc d1gp_now_at13 d1gp_now_at14 d1gp_now_at15 d1gp_now_at16 d1gp_now_at17 ///
					d1gp_now_at18 d1gp_now_at19 d1gp_now_at20 [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)

/* local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2 N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001)  */
local tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) nomtitle order(d1gp_now_at13 d1gp_now_at14 d1gp_now_at15 d1gp_now_at16 d1gp_now_at17 d1gp_now_at18 d1gp_now_at19 d1gp_now_at20) nocons

esttab 	tc1a_* , replace `tabprefs' 
esttab 	tc1a_* using "$tables/table4_replication.tex", replace `tabprefs' 

/* eststo clear					

** Input for Figure 4 (partial) **			
			
local timevars d1gp_now_at13 d1gp_now_at14 d1gp_now_at15 d1gp_now_at16 d1gp_now_at17 d1gp_now_at18 ///
				d1gp_now_at19 d1gp_now_at20 d1gp_now_at21 d1gp_now_at22 d1gp_now_at23 d1gp_now_at24 ///
				d1gp_now_at25

reghdfe lvmt_pc `timevars' [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)

postfile handle str32 varname float(b se) using "./results/figures/nhts_reald1ages_long", replace
foreach v of local timevars {
	post handle ("`v'") (_b[`v']) (_se[`v'])
}
postclose handle

eststo clear

log close
clear */

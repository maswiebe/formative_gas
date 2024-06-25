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

destring r_sex, replace
replace	r_sex = . if r_sex<0
rename	r_sex sex

/* ADD IN DL DATA */
gen		yr_at16 = yr_16_new
rename 	statefip stfip
merge m:1 stfip yr_at16  using "./output/dlpanel_prepped.dta"
keep	if _merge==3 /* Unmatched are post 2008 or pre 1967 */
drop	_merge year yr_at16
rename 	stfip statefip
/* END: Add in DL */

local 	agelist 16 17 18

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

foreach diff of numlist 0/2 {
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

gen		ldens = ln(htppopdn_cont)
replace ldens = . if htppopdn_cont==999998
replace ldens = 0 if htppopdn_cont==0 /* Not true zeros, from rounding error */


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

/* Define treatment using all vehicle data, enforce topcode of 115k miles */

gen		lvmt_pc 	= log(min(miles_per_psn_ALL,115000))

gen		mile_per_psn_ALL_lt115 = min(miles_per_psn_ALL,115000)
sum 	mile_per_psn_ALL_lt115
sum 	mile_per_psn_ALL_lt115 if mile_per_psn_ALL_lt115>0

compress 

********************************
** Panel Regressions 		 ***
********************************

** MW results

*------------------------------------
* replication of Table 3 using public NHTS data 
*------------------------------------
* only using restricted data for 2009 interview date variable (perindt2)

local demc white urban_bin famsize i.sex
lab var d2gp_now_at17 "$\Delta$ Price"

est clear

qui eststo tc2b_1: reghdfe lvmt_pc d2gp_now_at17 [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls ""
estadd local incyear ""
estadd local sy ""
estadd local qby ""
qui eststo tc2b_2:	reghdfe lvmt_pc d2gp_now_at17 `demc' [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear ""
estadd local sy ""
estadd local qby ""
qui eststo tc2b_3:	reghdfe lvmt_pc d2gp_now_at17 `demc' [aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy ""
estadd local qby ""
qui eststo tc2b_4:	reghdfe lvmt_pc d2gp_now_at17 `demc' [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"
estadd local qby ""
qui eststo tc2b_5:	reghdfe lvmt_pc d2gp_now_at17 `demc' c.byr##c.byr  	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"
estadd local qby "Yes"

local tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01)  keep(d2gp_now_at17) nomtitle scalars("year Sample year FEs" "state State FEs" "controls Controls" "incyear Income-by-year bin FEs" "sy State $\times$ year FEs" "qby Quad. birth year")

esttab tc2b_*, replace `tabprefs'
esttab tc2b_* using "$tables/table3_replication.tex", replace `tabprefs'


*--------------------------------
*** Heterogeneity by time
*--------------------------------

gen birthyear_1971 = inrange(byr,1971,1992)
gen d2gp_now_at17_by71 = d2gp_now_at17*birthyear_1971
lab var d2gp_now_at17 "$\Delta$ Price"
lab var d2gp_now_at17_by71 "$\Delta$ Price $\times$ Birthyear$\geq$1971"

table birthyear_1971, c(mean age)
* 43, 34

est clear

qui eststo tc2b_1: reghdfe lvmt_pc d2gp_now_at17 d2gp_now_at17_by71 birthyear_1971 [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls ""
estadd local incyear ""
estadd local sy ""
estadd local qby ""
qui eststo tc2b_2:	reghdfe lvmt_pc d2gp_now_at17 d2gp_now_at17_by71 birthyear_1971 `demc' [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear ""
estadd local sy ""
estadd local qby ""
qui eststo tc2b_3:	reghdfe lvmt_pc d2gp_now_at17 d2gp_now_at17_by71 birthyear_1971 `demc' [aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy ""
estadd local qby ""
qui eststo tc2b_4:	reghdfe lvmt_pc d2gp_now_at17 d2gp_now_at17_by71 birthyear_1971 `demc' [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"
estadd local qby ""
qui eststo tc2b_5:	reghdfe lvmt_pc d2gp_now_at17 d2gp_now_at17_by71 birthyear_1971 `demc' c.byr##c.byr  	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"
estadd local qby "Yes"

local tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01)  keep(d2gp_now_at17 d2gp_now_at17_by71) nomtitle scalars("year Sample year FEs" "state State FEs" "controls Controls" "incyear Income-by-year bin FEs" "sy State $\times$ year FEs" "qby Quad. birth year")

esttab tc2b_*, replace `tabprefs'
esttab tc2b_* using "$tables/table3_het_birthyear.tex", replace `tabprefs'


*--------------------------------
*** Heterogeneity by region
*--------------------------------

destring census_r, replace
gen reg1 = (census_r==1) 
gen reg2 = (census_r==2)
gen reg3 = (census_r==3)
gen d2gp_now_at17_reg1 = d2gp_now_at17*reg1
gen d2gp_now_at17_reg2 = d2gp_now_at17*reg2
gen d2gp_now_at17_reg3 = d2gp_now_at17*reg3
lab var d2gp_now_at17_reg1 "$\Delta$ Price $\times$ Northeast"
lab var d2gp_now_at17_reg2 "$\Delta$ Price $\times$ Midwest"
lab var d2gp_now_at17_reg3 "$\Delta$ Price $\times$ South"
* https://www2.census.gov/geo/pdfs/maps-data/maps/reference/us_regdiv.pdf
* West is omitted

est clear

qui eststo tc2b_1: reghdfe lvmt_pc d2gp_now_at17 d2gp_now_at17_reg1 d2gp_now_at17_reg2 d2gp_now_at17_reg3 [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls ""
estadd local incyear ""
estadd local sy ""
estadd local qby ""
qui eststo tc2b_2:	reghdfe lvmt_pc d2gp_now_at17 d2gp_now_at17_reg1 d2gp_now_at17_reg2 d2gp_now_at17_reg3 `demc' [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear ""
estadd local sy ""
estadd local qby ""
qui eststo tc2b_3:	reghdfe lvmt_pc d2gp_now_at17 d2gp_now_at17_reg1 d2gp_now_at17_reg2 d2gp_now_at17_reg3 `demc' [aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy ""
estadd local qby ""
qui eststo tc2b_4:	reghdfe lvmt_pc d2gp_now_at17 d2gp_now_at17_reg1 d2gp_now_at17_reg2 d2gp_now_at17_reg3 `demc' [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"
estadd local qby ""
qui eststo tc2b_5:	reghdfe lvmt_pc d2gp_now_at17 d2gp_now_at17_reg1 d2gp_now_at17_reg2 d2gp_now_at17_reg3 `demc' c.byr##c.byr  	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"
estadd local qby "Yes"

local tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01)  keep(d2gp_now_at17 d2gp_now_at17_reg1 d2gp_now_at17_reg2 d2gp_now_at17_reg3) nomtitle scalars("year Sample year FEs" "state State FEs" "controls Controls" "incyear Income-by-year bin FEs" "sy State $\times$ year FEs" "qby Quad. birth year")

esttab tc2b_*, replace `tabprefs'
esttab tc2b_* using "$tables/table3_het_region.tex", replace `tabprefs'

*--------------------------------
*** Heterogeneity by sex
*--------------------------------

gen fem = inrange(sex,2,2) if missing(sex)==0
* female==2
gen d2gp_now_at17_fem = d2gp_now_at17*fem
lab var d2gp_now_at17_fem "$\Delta$ Price $\times$ Female"
* sex is included in `demc'

est clear

qui eststo tc2b_1: reghdfe lvmt_pc d2gp_now_at17 d2gp_now_at17_fem fem [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls ""
estadd local incyear ""
estadd local sy ""
estadd local qby ""
qui eststo tc2b_2:	reghdfe lvmt_pc d2gp_now_at17 d2gp_now_at17_fem `demc' [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear ""
estadd local sy ""
estadd local qby ""
qui eststo tc2b_3:	reghdfe lvmt_pc d2gp_now_at17 d2gp_now_at17_fem `demc' [aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy ""
estadd local qby ""
qui eststo tc2b_4:	reghdfe lvmt_pc d2gp_now_at17 d2gp_now_at17_fem `demc' [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"
estadd local qby ""
qui eststo tc2b_5:	reghdfe lvmt_pc d2gp_now_at17 d2gp_now_at17_fem `demc' c.byr##c.byr  	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"
estadd local qby "Yes"

local tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01)  keep(d2gp_now_at17 d2gp_now_at17_fem) nomtitle scalars("year Sample year FEs" "state State FEs" "controls Controls" "incyear Income-by-year bin FEs" "sy State $\times$ year FEs" "qby Quad. birth year")

esttab tc2b_*, replace `tabprefs'
esttab tc2b_* using "$tables/table3_het_sex.tex", replace `tabprefs'

*--------------------------------
*** Heterogeneity by race
*--------------------------------

gen black = hh_race==2 if missing(hh_race)==0
gen d2gp_now_at17_black = d2gp_now_at17*black
lab var d2gp_now_at17_black "$\Delta$ Price $\times$ Black"
* white is included in `demc'

est clear

qui eststo tc2b_1: reghdfe lvmt_pc d2gp_now_at17 d2gp_now_at17_black black [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls ""
estadd local incyear ""
estadd local sy ""
estadd local qby ""
qui eststo tc2b_2:	reghdfe lvmt_pc d2gp_now_at17 d2gp_now_at17_black black `demc' [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear ""
estadd local sy ""
estadd local qby ""
qui eststo tc2b_3:	reghdfe lvmt_pc d2gp_now_at17 d2gp_now_at17_black black `demc' [aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy ""
estadd local qby ""
qui eststo tc2b_4:	reghdfe lvmt_pc d2gp_now_at17 d2gp_now_at17_black black `demc' [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"
estadd local qby ""
qui eststo tc2b_5:	reghdfe lvmt_pc d2gp_now_at17 d2gp_now_at17_black black `demc' c.byr##c.byr  	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"
estadd local qby "Yes"

local tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01)  keep(d2gp_now_at17 d2gp_now_at17_black) nomtitle scalars("year Sample year FEs" "state State FEs" "controls Controls" "incyear Income-by-year bin FEs" "sy State $\times$ year FEs" "qby Quad. birth year")

esttab tc2b_*, replace `tabprefs'
esttab tc2b_* using "$tables/table3_het_race.tex", replace `tabprefs'


*--------------------------------
* Table 3, row 1: interaction
* symmetry: price decreases vs increases
*--------------------------------
gen d2gp_now_at17_sign_pos = inrange(d2gp_now_at17,0,1)
gen d2gp_now_at17_pos = d2gp_now_at17*d2gp_now_at17_sign_pos
lab var d2gp_now_at17 "$\Delta$ Price"
lab var d2gp_now_at17_pos "$\Delta$ Price $\times$ $\Delta$ Price$>$0"

set scheme plotplainblind

binscatter lvmt_pc d2gp_now_at17 [aw=expfllpr] , rd(0) absorb(stateid) controls(age nhtsyear) xtitle("Price change (percent)") ytitle("Log miles travelled")
graph export "$figures/table3_binscatter.png", replace


local demc white urban_bin famsize i.sex

est clear

qui eststo tc2b_1: reghdfe lvmt_pc d2gp_now_at17  d2gp_now_at17_pos d2gp_now_at17_sign_pos [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls ""
estadd local incyear ""
estadd local sy ""
estadd local qby ""
qui eststo tc2b_2:	reghdfe lvmt_pc d2gp_now_at17 d2gp_now_at17_pos d2gp_now_at17_sign_pos `demc' [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear ""
estadd local sy ""
estadd local qby ""
qui eststo tc2b_3:	reghdfe lvmt_pc d2gp_now_at17  d2gp_now_at17_pos d2gp_now_at17_sign_pos `demc' [aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy ""
estadd local qby ""
qui eststo tc2b_4:	reghdfe lvmt_pc d2gp_now_at17  d2gp_now_at17_pos d2gp_now_at17_sign_pos `demc' [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"
estadd local qby ""
qui eststo tc2b_5:	reghdfe lvmt_pc d2gp_now_at17  d2gp_now_at17_pos d2gp_now_at17_sign_pos `demc' c.byr##c.byr  	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"
estadd local qby "Yes"

local tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01)  keep(d2gp_now_at17  d2gp_now_at17_pos) nomtitle scalars("year Sample year FEs" "state State FEs" "controls Controls" "incyear Income-by-year bin FEs" "sy State $\times$ year FEs" "qby Quad. birth year")
*stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared))
    * can't use stats() and scalars()

esttab tc2b_*, replace `tabprefs'
esttab tc2b_* using "$tables/table3_pos_neg.tex", replace `tabprefs'

*---------------------
*** absolute effect (instead of differential effect)
* y = b1 * price_change X 1{price_change>0} + b2 * price_change X 1{price_change<0} + b3* 1{price_change>0}
* ie. report b1 and b1+b3 instead of b1 and b3
    * identical output, but now testing H0:b1+b3=0

gen d2gp_now_at17_sign_neg = inrange(d2gp_now_at17,-1,0)
gen d2gp_now_at17_neg = d2gp_now_at17*d2gp_now_at17_sign_neg
lab var d2gp_now_at17_neg "$\Delta$ Price $\times$ $\Delta$ Price$<$0"

est clear

qui eststo tc2b_1: reghdfe lvmt_pc d2gp_now_at17_neg d2gp_now_at17_pos d2gp_now_at17_sign_pos [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls ""
estadd local incyear ""
estadd local sy ""
estadd local qby ""
qui eststo tc2b_2:	reghdfe lvmt_pc d2gp_now_at17_neg d2gp_now_at17_pos d2gp_now_at17_sign_pos `demc' [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear ""
estadd local sy ""
estadd local qby ""
qui eststo tc2b_3:	reghdfe lvmt_pc d2gp_now_at17_neg d2gp_now_at17_pos d2gp_now_at17_sign_pos `demc' [aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy ""
estadd local qby ""
qui eststo tc2b_4:	reghdfe lvmt_pc d2gp_now_at17_neg d2gp_now_at17_pos d2gp_now_at17_sign_pos `demc' [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"
estadd local qby ""
qui eststo tc2b_5:	reghdfe lvmt_pc d2gp_now_at17_neg d2gp_now_at17_pos d2gp_now_at17_sign_pos `demc' c.byr##c.byr  	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"
estadd local qby "Yes"

local tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01)  keep(d2gp_now_at17_neg d2gp_now_at17_pos) nomtitle scalars("year Sample year FEs" "state State FEs" "controls Controls" "incyear Income-by-year bin FEs" "sy State $\times$ year FEs" "qby Quad. birth year")
*stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared))
    * can't use stats() and scalars()

esttab tc2b_*, replace `tabprefs'
esttab tc2b_* using "$tables/table3_pos_neg_overall.tex", replace `tabprefs'


*----------------------
* subsample regressions

*** price increases

est clear

qui eststo tc2b_1: reghdfe lvmt_pc d2gp_now_at17  [aw=expfllpr] if d2gp_now_at17_sign_pos==1, a(stateid nhtsyear age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls ""
estadd local incyear ""
estadd local sy ""
estadd local qby ""
qui eststo tc2b_2:	reghdfe lvmt_pc d2gp_now_at17 `demc' [aw=expfllpr] if d2gp_now_at17_sign_pos==1, a(stateid nhtsyear age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear ""
estadd local sy ""
estadd local qby ""
qui eststo tc2b_3:	reghdfe lvmt_pc d2gp_now_at17 `demc' [aw=expfllpr] if d2gp_now_at17_sign_pos==1, a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy ""
estadd local qby ""
qui eststo tc2b_4:	reghdfe lvmt_pc d2gp_now_at17  `demc' [aw=expfllpr] if d2gp_now_at17_sign_pos==1, a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"
estadd local qby ""
qui eststo tc2b_5:	reghdfe lvmt_pc d2gp_now_at17  `demc' c.byr##c.byr  	[aw=expfllpr] if d2gp_now_at17_sign_pos==1, a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"
estadd local qby "Yes"

local tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01)  keep(d2gp_now_at17) nomtitle scalars("year Sample year FEs" "state State FEs" "controls Controls" "incyear Income-by-year bin FEs" "sy State $\times$ year FEs" "qby Quad. birth year")
*stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared))
    * can't use stats() and scalars()

esttab tc2b_*, replace `tabprefs'
esttab tc2b_* using "$tables/table3_subsample_pos.tex", replace `tabprefs'

*** price decreases

est clear

qui eststo tc2b_1: reghdfe lvmt_pc d2gp_now_at17  [aw=expfllpr] if d2gp_now_at17_sign_pos==0, a(stateid nhtsyear age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls ""
estadd local incyear ""
estadd local sy ""
estadd local qby ""
qui eststo tc2b_2:	reghdfe lvmt_pc d2gp_now_at17 `demc' [aw=expfllpr] if d2gp_now_at17_sign_pos==0, a(stateid nhtsyear age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear ""
estadd local sy ""
estadd local qby ""
qui eststo tc2b_3:	reghdfe lvmt_pc d2gp_now_at17 `demc' [aw=expfllpr] if d2gp_now_at17_sign_pos==0, a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy ""
estadd local qby ""
qui eststo tc2b_4:	reghdfe lvmt_pc d2gp_now_at17  `demc' [aw=expfllpr] if d2gp_now_at17_sign_pos==0, a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"
estadd local qby ""
qui eststo tc2b_5:	reghdfe lvmt_pc d2gp_now_at17  `demc' c.byr##c.byr  	[aw=expfllpr] if d2gp_now_at17_sign_pos==0, a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"
estadd local qby "Yes"

local tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01)  keep(d2gp_now_at17) nomtitle scalars("year Sample year FEs" "state State FEs" "controls Controls" "incyear Income-by-year bin FEs" "sy State $\times$ year FEs" "qby Quad. birth year")
*stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared))
    * can't use stats() and scalars()

esttab tc2b_*, replace `tabprefs'
esttab tc2b_* using "$tables/table3_subsample_neg.tex", replace `tabprefs'

*---------------------
*---------------------
* Table 3, row 3
* using driver's license age
*---------------------
*---------------------
/* 
binscatter lvmt_pc d2gp_now_atp1 [aw=expfllpr] , rd(0) absorb(stateid) controls(age nhtsyear) xtitle("Price change (percent)") ytitle("Log miles travelled")
graph export "$figures/table3_binscatter_dl.png", replace

*** interaction effect

gen d2gp_now_atp1_sign_pos = inrange(d2gp_now_atp1,0,1)
gen d2gp_now_atp1_pos = d2gp_now_atp1*d2gp_now_atp1_sign_pos
lab var d2gp_now_atp1 "$\Delta$ Price"
lab var d2gp_now_atp1_pos "$\Delta$ Price $\times$ $\Delta$ Price$>$0"

est clear

qui eststo tdlb_1:	reghdfe lvmt_pc d2gp_now_atp1 d2gp_now_atp1_pos d2gp_now_atp1_sign_pos [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls ""
estadd local incyear ""
estadd local sy ""
estadd local qby ""
qui eststo tdlb_2:	reghdfe lvmt_pc d2gp_now_atp1 d2gp_now_atp1_pos d2gp_now_atp1_sign_pos `demc' [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear ""
estadd local sy ""
estadd local qby ""
qui eststo tdlb_3:	reghdfe lvmt_pc d2gp_now_atp1 d2gp_now_atp1_pos d2gp_now_atp1_sign_pos `demc' [aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy ""
estadd local qby ""
qui eststo tdlb_4:	reghdfe lvmt_pc d2gp_now_atp1 d2gp_now_atp1_pos d2gp_now_atp1_sign_pos `demc' [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"
estadd local qby ""
qui eststo tdlb_5:	reghdfe lvmt_pc d2gp_now_atp1 d2gp_now_atp1_pos d2gp_now_atp1_sign_pos `demc' c.byr##c.byr  	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"
estadd local qby "Yes"

local tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01)  keep(d2gp_now_atp1  d2gp_now_atp1_pos) nomtitle scalars("year Sample year FEs" "state State FEs" "controls Controls" "incyear Income-by-year bin FEs" "sy State $\times$ year FEs" "qby Quad. birth year")

esttab tdlb_*, replace `tabprefs'
esttab tdlb_* using "$tables/table3_pos_neg_dl.tex", replace `tabprefs'

*** absolute effect
gen d2gp_now_atp1_sign_neg = inrange(d2gp_now_atp1,-1,0)
gen d2gp_now_atp1_neg = d2gp_now_atp1*d2gp_now_atp1_sign_neg
lab var d2gp_now_atp1_neg "$\Delta$ Price $\times$ $\Delta$ Price$<$0"

est clear

qui eststo tdlb_1:	reghdfe lvmt_pc d2gp_now_atp1_neg d2gp_now_atp1_pos d2gp_now_atp1_sign_pos [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls ""
estadd local incyear ""
estadd local sy ""
estadd local qby ""
qui eststo tdlb_2:	reghdfe lvmt_pc d2gp_now_atp1_neg d2gp_now_atp1_pos d2gp_now_atp1_sign_pos `demc' [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear ""
estadd local sy ""
estadd local qby ""
qui eststo tdlb_3:	reghdfe lvmt_pc d2gp_now_atp1_neg d2gp_now_atp1_pos d2gp_now_atp1_sign_pos `demc' [aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy ""
estadd local qby ""
qui eststo tdlb_4:	reghdfe lvmt_pc d2gp_now_atp1_neg d2gp_now_atp1_pos d2gp_now_atp1_sign_pos `demc' [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"
estadd local qby ""
qui eststo tdlb_5:	reghdfe lvmt_pc d2gp_now_atp1_neg d2gp_now_atp1_pos d2gp_now_atp1_sign_pos `demc' c.byr##c.byr  	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"
estadd local qby "Yes"

local tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01)  keep(d2gp_now_atp1_neg  d2gp_now_atp1_pos) nomtitle scalars("year Sample year FEs" "state State FEs" "controls Controls" "incyear Income-by-year bin FEs" "sy State $\times$ year FEs" "qby Quad. birth year")

esttab tdlb_*, replace `tabprefs'
esttab tdlb_* using "$tables/table3_pos_neg_dl_overall.tex", replace `tabprefs'


*** subsample regressions

* price increases
est clear

qui eststo tdlb_1:	reghdfe lvmt_pc d2gp_now_atp1 [aw=expfllpr] if d2gp_now_atp1_sign_pos==1, a(stateid nhtsyear age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls ""
estadd local incyear ""
estadd local sy ""
estadd local qby ""
qui eststo tdlb_2:	reghdfe lvmt_pc d2gp_now_atp1 `demc' [aw=expfllpr] if d2gp_now_atp1_sign_pos==1, a(stateid nhtsyear age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear ""
estadd local sy ""
estadd local qby ""
qui eststo tdlb_3:	reghdfe lvmt_pc d2gp_now_atp1 `demc' [aw=expfllpr] if d2gp_now_atp1_sign_pos==1, a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy ""
estadd local qby ""
qui eststo tdlb_4:	reghdfe lvmt_pc d2gp_now_atp1 `demc' [aw=expfllpr] if d2gp_now_atp1_sign_pos==1, a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"
estadd local qby ""
qui eststo tdlb_5:	reghdfe lvmt_pc d2gp_now_atp1 `demc' c.byr##c.byr  	[aw=expfllpr] if d2gp_now_atp1_sign_pos==1, a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"
estadd local qby "Yes"

local tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01)  keep(d2gp_now_atp1) nomtitle scalars("year Sample year FEs" "state State FEs" "controls Controls" "incyear Income-by-year bin FEs" "sy State $\times$ year FEs" "qby Quad. birth year")

esttab tdlb_*, replace `tabprefs'
esttab tdlb_* using "$tables/table3_dl_subsample_pos.tex", replace `tabprefs'

* price decreases
est clear

qui eststo tdlb_1:	reghdfe lvmt_pc d2gp_now_atp1 [aw=expfllpr] if d2gp_now_atp1_sign_pos==0, a(stateid nhtsyear age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls ""
estadd local incyear ""
estadd local sy ""
estadd local qby ""
qui eststo tdlb_2:	reghdfe lvmt_pc d2gp_now_atp1 `demc' [aw=expfllpr] if d2gp_now_atp1_sign_pos==0, a(stateid nhtsyear age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear ""
estadd local sy ""
estadd local qby ""
qui eststo tdlb_3:	reghdfe lvmt_pc d2gp_now_atp1 `demc' [aw=expfllpr] if d2gp_now_atp1_sign_pos==0, a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy ""
estadd local qby ""
qui eststo tdlb_4:	reghdfe lvmt_pc d2gp_now_atp1 `demc' [aw=expfllpr] if d2gp_now_atp1_sign_pos==0, a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"
estadd local qby ""
qui eststo tdlb_5:	reghdfe lvmt_pc d2gp_now_atp1 `demc' c.byr##c.byr  	[aw=expfllpr] if d2gp_now_atp1_sign_pos==0, a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"
estadd local qby "Yes"

local tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01)  keep(d2gp_now_atp1) nomtitle scalars("year Sample year FEs" "state State FEs" "controls Controls" "incyear Income-by-year bin FEs" "sy State $\times$ year FEs" "qby Quad. birth year")

esttab tdlb_*, replace `tabprefs'
esttab tdlb_* using "$tables/table3_dl_subsample_neg.tex", replace `tabprefs'
 */
*----------------------
** Table A.12 **
*----------------------

local demc white urban_bin famsize i.sex
lab var d2gp_now_at17 "$\Delta$ Price"

eststo tcodl_a_1:	reghdfe lvmt_pc d2gp_now_at17			[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls ""
estadd local incyear ""
estadd local sy ""
eststo tcodl_a_2:	reghdfe lvmt_pc d2gp_now_at17 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear ""
estadd local sy ""
eststo tcodl_a_3:	reghdfe lvmt_pc d2gp_now_at17 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age hhi_bin_yr) cluster(stateid)
estadd local year "Yes"
estadd local state "Yes"
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy ""
eststo tcodl_a_4:	reghdfe lvmt_pc d2gp_now_at17 `demc' 	[aw=expfllpr], a(stsamyr_fe age yr_age16 hhi_bin_yr) cluster(stateid)
estadd local year ""
estadd local state ""
estadd local controls "Yes"
estadd local incyear "Yes"
estadd local sy "Yes"

local tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01)  keep(d2gp_now_at17) nomtitle scalars("year Sample year FEs" "state State FEs" "controls Controls" "incyear Income-by-year bin FEs" "sy State $\times$ year FEs")

esttab tcodl_a_*, replace `tabprefs'
esttab tcodl_a_* using "$tables/tablea12_1517.tex", replace `tabprefs'

/* eststo clear

/* Summary Stats */ 

** Table A.2 (partial) **

eststo 	sum1: estpost tabstat mile_per_psn_ALL_lt115 d2gp_now_at17 white urban_bin famsize sex age [aw=expfllpr], s(mean sd count) c(s) 
eststo 	sum2: estpost tabstat mile_per_psn_ALL_lt115 if mile_per_psn_ALL_lt115>0 & !mi(mile_per_psn_ALL_lt115) [aw=expfllpr], s(mean sd min max count) c(s) 

esttab sum? using "./results/table_a2/nhts_summary_stats.tex", booktabs replace cells(mean sd min max count)

/* Main specifications at different ages */ 

** Tables 3 and A.11 (partial, see esttab for assignment) **

local demc white urban_bin famsize i.sex

eststo tc2a_1:	reghdfe lvmt_pc d2gp_now_at18  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc2a_2:	reghdfe lvmt_pc d2gp_now_at18 `demc'				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc2a_3:	reghdfe lvmt_pc d2gp_now_at18 `demc' 				[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo tc2a_4:	reghdfe lvmt_pc d2gp_now_at18 `demc' 				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tc2a_5:	reghdfe lvmt_pc d2gp_now_at18 `demc' c.byr##c.byr  	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo tc2b_1:	reghdfe lvmt_pc d2gp_now_at17  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc2b_2:	reghdfe lvmt_pc d2gp_now_at17 `demc'				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc2b_3:	reghdfe lvmt_pc d2gp_now_at17 `demc' 				[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo tc2b_4:	reghdfe lvmt_pc d2gp_now_at17 `demc' 				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tc2b_5:	reghdfe lvmt_pc d2gp_now_at17 `demc' c.byr##c.byr  	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo tc2c_1:	reghdfe lvmt_pc d1gp_now_at18  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc2c_2:	reghdfe lvmt_pc d1gp_now_at18 `demc'				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc2c_3:	reghdfe lvmt_pc d1gp_now_at18 `demc' 				[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo tc2c_4:	reghdfe lvmt_pc d1gp_now_at18 `demc' 				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tc2c_5:	reghdfe lvmt_pc d1gp_now_at18 `demc' c.byr##c.byr  	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo tc2d_1:	reghdfe lvmt_pc d1gp_now_at17  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc2d_2:	reghdfe lvmt_pc d1gp_now_at17 `demc'				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc2d_3:	reghdfe lvmt_pc d1gp_now_at17 `demc' 			 	[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo tc2d_4:	reghdfe lvmt_pc d1gp_now_at17 `demc'				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tc2d_5:	reghdfe lvmt_pc d1gp_now_at17 `demc' c.byr##c.byr	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo tc2e_1:	reghdfe lvmt_pc d1gp_now_at16  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc2e_2:	reghdfe lvmt_pc d1gp_now_at16 `demc'				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc2e_3:	reghdfe lvmt_pc d1gp_now_at16 `demc' 			 	[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo tc2e_4:	reghdfe lvmt_pc d1gp_now_at16 `demc'				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tc2e_5:	reghdfe lvmt_pc d1gp_now_at16 `demc' c.byr##c.byr	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo tc2f_1:	reghdfe lvmt_pc real_gp_at16  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc2f_2:	reghdfe lvmt_pc real_gp_at16  `demc' 				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc2f_3:	reghdfe lvmt_pc real_gp_at16  `demc' 				[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo tc2f_4:	reghdfe lvmt_pc real_gp_at16  `demc' 				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tc2f_5:	reghdfe lvmt_pc real_gp_at16  `demc'  c.byr##c.byr	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

esttab 	tc2a_* using "./results/table_a11/mainspecs_d2_18.tex", booktabs replace `tabprefs'
esttab 	tc2b_* using "./results/table3/nhts_d2_17.tex", booktabs replace `tabprefs'
esttab 	tc2c_* using "./results/table_a11/mainspecs_d1_18.tex", booktabs replace `tabprefs'
esttab 	tc2d_* using "./results/table_a11/mainspecs_d1_17.tex", booktabs replace `tabprefs'
esttab 	tc2e_* using "./results/table_a11/mainspecs_d1_16.tex", booktabs replace `tabprefs'
esttab 	tc2f_* using "./results/table3/nhts_lev16.tex", booktabs replace `tabprefs'

eststo clear

/* Main specifications at different driver license minimums */ 

** Tables 3 and A.11 (partial, see esttab for assignment) **

local demc white urban_bin famsize i.sex

eststo tdla_1:	reghdfe lvmt_pc d2gp_now_atp2  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdla_2:	reghdfe lvmt_pc d2gp_now_atp2 `demc'				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdla_3:	reghdfe lvmt_pc d2gp_now_atp2 `demc' 				[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo tdla_4:	reghdfe lvmt_pc d2gp_now_atp2 `demc' 				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tdla_5:	reghdfe lvmt_pc d2gp_now_atp2 `demc' c.byr##c.byr  	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo tdlb_1:	reghdfe lvmt_pc d2gp_now_atp1  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdlb_2:	reghdfe lvmt_pc d2gp_now_atp1 `demc'				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdlb_3:	reghdfe lvmt_pc d2gp_now_atp1 `demc' 				[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo tdlb_4:	reghdfe lvmt_pc d2gp_now_atp1 `demc' 				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tdlb_5:	reghdfe lvmt_pc d2gp_now_atp1 `demc' c.byr##c.byr  	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo tdlc_1:	reghdfe lvmt_pc d1gp_now_atp2  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdlc_2:	reghdfe lvmt_pc d1gp_now_atp2 `demc'				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdlc_3:	reghdfe lvmt_pc d1gp_now_atp2 `demc' 				[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo tdlc_4:	reghdfe lvmt_pc d1gp_now_atp2 `demc' 				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tdlc_5:	reghdfe lvmt_pc d1gp_now_atp2 `demc' c.byr##c.byr  	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo tdld_1:	reghdfe lvmt_pc d1gp_now_atp1  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdld_2:	reghdfe lvmt_pc d1gp_now_atp1 `demc'				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdld_3:	reghdfe lvmt_pc d1gp_now_atp1 `demc' 			 	[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo tdld_4:	reghdfe lvmt_pc d1gp_now_atp1 `demc'				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tdld_5:	reghdfe lvmt_pc d1gp_now_atp1 `demc' c.byr##c.byr	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo tdle_1:	reghdfe lvmt_pc d1gp_now_atp0  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdle_2:	reghdfe lvmt_pc d1gp_now_atp0 `demc'				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdle_3:	reghdfe lvmt_pc d1gp_now_atp0 `demc' 			 	[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo tdle_4:	reghdfe lvmt_pc d1gp_now_atp0 `demc'				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tdle_5:	reghdfe lvmt_pc d1gp_now_atp0 `demc' c.byr##c.byr	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo tdlf_1:	reghdfe lvmt_pc real_gp_atp0  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdlf_2:	reghdfe lvmt_pc real_gp_atp0  `demc' 				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdlf_3:	reghdfe lvmt_pc real_gp_atp0  `demc' 				[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo tdlf_4:	reghdfe lvmt_pc real_gp_atp0  `demc' 				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tdlf_5:	reghdfe lvmt_pc real_gp_atp0  `demc'  c.byr##c.byr	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

esttab 	tdla_* using "./results/table_a11/mainspecs_d2_p2.tex", booktabs replace `tabprefs'
esttab 	tdlb_* using "./results/table3/nhts_d2_p1.tex", booktabs replace `tabprefs'
esttab 	tdlc_* using "./results/table_a11/mainspecs_d1_p2.tex", booktabs replace `tabprefs'
esttab 	tdld_* using "./results/table_a11/mainspecs_d1_p1.tex", booktabs replace `tabprefs'
esttab 	tdle_* using "./results/table_a11/mainspecs_d1_p0.tex", booktabs replace `tabprefs'
esttab 	tdlf_* using "./results/table3/nhts_levp0.tex", booktabs replace `tabprefs'

eststo clear

/* Main specifications with cohort fixed effects */ 

** Table A.12 **

local demc white urban_bin famsize i.sex

eststo tcodl_a_1:	reghdfe lvmt_pc d2gp_now_atp2			[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcodl_a_2:	reghdfe lvmt_pc d2gp_now_atp2 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcodl_a_3:	reghdfe lvmt_pc d2gp_now_atp2 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age hhi_bin_yr) cluster(stateid)
eststo tcodl_a_4:	reghdfe lvmt_pc d2gp_now_atp2 `demc' 	[aw=expfllpr], a(stsamyr_fe age yr_age16 hhi_bin_yr) cluster(stateid)

eststo tcodl_b_1:	reghdfe lvmt_pc d2gp_now_atp1			[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcodl_b_2:	reghdfe lvmt_pc d2gp_now_atp1 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcodl_b_3:	reghdfe lvmt_pc d2gp_now_atp1 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age hhi_bin_yr) cluster(stateid)
eststo tcodl_b_4:	reghdfe lvmt_pc d2gp_now_atp1 `demc' 	[aw=expfllpr], a(stsamyr_fe age yr_age16 hhi_bin_yr) cluster(stateid)

eststo tcodl_c_1:	reghdfe lvmt_pc d1gp_now_atp2			[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcodl_c_2:	reghdfe lvmt_pc d1gp_now_atp2 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcodl_c_3:	reghdfe lvmt_pc d1gp_now_atp2 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age hhi_bin_yr) cluster(stateid)
eststo tcodl_c_4:	reghdfe lvmt_pc d1gp_now_atp2 `demc' 	[aw=expfllpr], a(stsamyr_fe age yr_age16 hhi_bin_yr) cluster(stateid)

eststo tcodl_d_1:	reghdfe lvmt_pc d1gp_now_atp1			[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcodl_d_2:	reghdfe lvmt_pc d1gp_now_atp1 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcodl_d_3:	reghdfe lvmt_pc d1gp_now_atp1 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age hhi_bin_yr) cluster(stateid)
eststo tcodl_d_4:	reghdfe lvmt_pc d1gp_now_atp1 `demc' 	[aw=expfllpr], a(stsamyr_fe age yr_age16 hhi_bin_yr) cluster(stateid)

eststo tcodl_e_1:	reghdfe lvmt_pc d1gp_now_atp0			[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcodl_e_2:	reghdfe lvmt_pc d1gp_now_atp0 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcodl_e_3:	reghdfe lvmt_pc d1gp_now_atp0 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age hhi_bin_yr) cluster(stateid)
eststo tcodl_e_4:	reghdfe lvmt_pc d1gp_now_atp0 `demc' 	[aw=expfllpr], a(stsamyr_fe age yr_age16 hhi_bin_yr) cluster(stateid)

eststo tcodl_f_1:	reghdfe lvmt_pc real_gp_atp0 			[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcodl_f_2:	reghdfe lvmt_pc real_gp_atp0 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcodl_f_3:	reghdfe lvmt_pc real_gp_atp0 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age hhi_bin_yr) cluster(stateid)
eststo tcodl_f_4:	reghdfe lvmt_pc real_gp_atp0 `demc' 	[aw=expfllpr], a(stsamyr_fe age yr_age16 hhi_bin_yr) cluster(stateid)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

esttab 	tcodl_a_* using "./results/table_a12/cohfespecs_d2_p2.tex", booktabs replace `tabprefs'
esttab 	tcodl_b_* using "./results/table_a12/cohfespecs_d2_p1.tex", booktabs replace `tabprefs'
esttab 	tcodl_c_* using "./results/table_a12/cohfespecs_d1_p2.tex", booktabs replace `tabprefs'
esttab 	tcodl_d_* using "./results/table_a12/cohfespecs_d1_p1.tex", booktabs replace `tabprefs'
esttab 	tcodl_e_* using "./results/table_a12/cohfespecs_d1_p0.tex", booktabs replace `tabprefs'
esttab 	tcodl_f_* using "./results/table_a12/cohfespecs_levp0.tex", booktabs replace `tabprefs'

eststo clear

/* Age Heterogeneity */

** Table A.16 (partial) **

gen		d2gp_age17_2534 = (age>=25 & age<=34)*d2gp_now_at17
gen		d2gp_age17_3544 = (age>=35 & age<=44)*d2gp_now_at17
gen		d2gp_age17_4554 = (age>=45 & age<=54)*d2gp_now_at17

gen		d2gp_agep1_2534 = (age>=25 & age<=34)*d2gp_now_atp1
gen		d2gp_agep1_3544 = (age>=35 & age<=44)*d2gp_now_atp1
gen		d2gp_agep1_4554 = (age>=45 & age<=54)*d2gp_now_atp1

local	bin10yrs_17 d2gp_age17_2534 d2gp_age17_3544 d2gp_age17_4554

local	bin10yrs_p1 d2gp_agep1_2534 d2gp_agep1_3544 d2gp_agep1_4554

local demc white urban_bin famsize i.sex

eststo tcage_3:	reghdfe lvmt_pc  `bin10yrs_17'	 					[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tcage_4:	reghdfe lvmt_pc  `bin10yrs_17' `demc' c.byr##c.byr	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo tcage_7:	reghdfe lvmt_pc  `bin10yrs_p1'	 			[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tcage_8:	reghdfe lvmt_pc  `bin10yrs_p1' c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

esttab 	tcage_? using "./results/table_a16/nhts_agehet_17p1.tex", booktabs replace `tabprefs'

eststo clear
drop  	d2gp_age??_????

** ** ** **
/* Robust to dropping 1979/80 Crisis */

** Table A.18 **

loc y79 "byr!=1965"	
loc y74 "byr!=1960"
loc y70s "(byr<1959 | byr>1966)"

eststo tdrop_1:	reghdfe lvmt_pc d2gp_now_at17  				if `y74' [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdrop_2:	reghdfe lvmt_pc d2gp_now_atp1 				if `y74' [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdrop_3:	reghdfe lvmt_pc d2gp_now_at17  				if `y79' [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdrop_4:	reghdfe lvmt_pc d2gp_now_atp1 				if `y79' [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdrop_5:	reghdfe lvmt_pc d2gp_now_at17  				if `y74' & `y79' [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdrop_6:	reghdfe lvmt_pc d2gp_now_atp1  				if `y74' & `y79' [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdrop_7:	reghdfe lvmt_pc d2gp_now_at17 				if `y70s' [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdrop_8:	reghdfe lvmt_pc d2gp_now_atp1 				if `y70s' [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)


local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

esttab 	tdrop_* using "./results/other/dropoilcrises_nhts.tex", booktabs replace `tabprefs'
est clear

** ** ** **
/* Other robustness */

preserve
	clear
	insheet using 	"./data/state_pops/nhgis0081_ds104_1980_state.csv", c
	keep 	statea c7l001
	rename 	statea statefip
	rename	c7l001 pop
	tempfile p1980
	save	"`p1980'", replace
	
	use 	"./output/gasprice_prepped.dta", clear
	merge 	m:1 statefip using "`p1980'"
	collapse (mean) gas_price_99 d1gp_bp d2gp_bp [aw=pop], by(year)
	rename gas_price_99 rgp_national 
	rename d1gp_bp d1gp_national
	rename d2gp_bp d2gp_national
	tempfile natprice
	save	"`natprice'", replace
	tab 	rgp_national 
	tab 	year
restore

rename 	yr_age17 year
merge m:1 year using "`natprice'"
keep if	_merge==3
drop  	d1gp_national rgp_national _merge
rename  d2gp_national d2gp17_national
rename 	year yr_age17

rename yr_age16 year
merge m:1 year using "`natprice'"
drop if _merge==2
drop  	d1gp_national d2gp_national _merge
rename   rgp_national rgp16_national
rename year yr_age16

** Multiple treatments + national shocks

** Table A.19 (partial) **

local demc white urban_bin famsize i.sex

eststo mt_1:	reghdfe lvmt_pc d2gp_now_at17 real_gp_at16 						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo mt_2:	reghdfe lvmt_pc d2gp_now_at17 real_gp_at16 `demc' c.byr##c.byr  [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo mt_3:	reghdfe lvmt_pc d2gp17_national									[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo mt_4:	reghdfe lvmt_pc d2gp17_national `demc' c.byr##c.byr  			[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo mt_5:	reghdfe lvmt_pc rgp16_national									[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo mt_6:	reghdfe lvmt_pc rgp16_national `demc' c.byr##c.byr  			[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

esttab 	mt_* using "./results/other/nhts_multtreatment_and_national.tex", booktabs replace `tabprefs'
est clear

** SEs

** Table A.20 (partial) **

local demc white urban_bin famsize i.sex

eststo se_1:	reghdfe lvmt_pc d2gp_now_at17 						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo se_2:	reghdfe lvmt_pc d2gp_now_at17						[aw=expfllpr], a(stateid nhtsyear age) cluster(byr)
eststo se_3:	reghdfe lvmt_pc d2gp_now_at17 						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid byr)
eststo se_4:	reghdfe lvmt_pc d2gp_now_at17 `demc' c.byr##c.byr   [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo se_5:	reghdfe lvmt_pc d2gp_now_at17 `demc' c.byr##c.byr   [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(byr)
eststo se_6:	reghdfe lvmt_pc d2gp_now_at17 `demc' c.byr##c.byr   [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid byr)

eststo se_7:	reghdfe lvmt_pc real_gp_at16						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo se_8:	reghdfe lvmt_pc real_gp_at16						[aw=expfllpr], a(stateid nhtsyear age) cluster(byr)
eststo se_9:	reghdfe lvmt_pc real_gp_at16 						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid byr)
eststo se_10:	reghdfe lvmt_pc real_gp_at16 `demc' c.byr##c.byr   [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo se_11:	reghdfe lvmt_pc real_gp_at16 `demc' c.byr##c.byr   [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(byr)
eststo se_12:	reghdfe lvmt_pc real_gp_at16 `demc' c.byr##c.byr   [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid byr)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

esttab 	se_* using "./results/other/nhts_altSEs.tex", booktabs replace `tabprefs'
est clear


**********************************
** Close out

capture noisily log close
clear
 */



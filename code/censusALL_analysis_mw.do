*************************************************************
** This file makes performs panel analyses from all census 
** data years.
*************************************************************

*local 	logf "`1'" 
*log using "`logf'", replace text

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

tab 	year multyear

gen 	year_all = year
replace year_all = multyear if year==2010 | year==2015
tab		year_all

drop 	year 
rename 	year_all censusyear_all

rename 	statefip stfip
rename 	bpl statefip

local 	agelist 16 17 18 

foreach age of local agelist {
	gen 	year = birthyr + `age'

	merge m:1 year statefip using "./output/gasprice_prepped.dta", keepusing(gas_price_99 d1gp_bp d2gp_bp) gen(_merge`age')

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

** Merge to current state prices at age 16 **

rename 	statefip bpl
rename 	stfip statefip

local 	agelist 16 17 18

foreach age of local agelist {
	rename 	yr_age`age' year

	merge m:1 year statefip using "./output/gasprice_prepped.dta", keepusing(gas_price_99 d1gp_bp d2gp_bp)
	/* 	_merge==1 are years with older people but no gasoline data
		_merge==2 are years that are not yet adulted
	*/
	drop if _merge==2
	*drop if _merge!=3
	drop 	_merge

	rename 	year yr_age`age' 

	rename	gas_price_99 real_now_at`age'
	rename	d1gp_bp d1gp_now_at`age'
	rename	d2gp_bp d2gp_now_at`age'
}

*********************
** Set up DL Merge **

rename 	bpl stfip

gen		yr_at16 = birthyr + 16

merge m:1 stfip yr_at16  using "./output/dlpanel_prepped.dta"
keep	if _merge==3 /* Unmatched are post 2008 or pre 1967 */
drop	_merge year yr_at16
rename  min_age_full min_age_full_stbirth


rename 	stfip bpl
rename	statefip stfip
compress

** Set up Specify Merge Year **

rename 	bpl statefip

foreach diff of numlist 0/2 {
	gen 	year = round(min_age_full_stbirth) + birthyr + `diff'

	merge m:1 year statefip using "./output/gasprice_prepped.dta", keepusing(gas_price_99 d1gp_bp d2gp_bp) gen(_mergep`diff')

	rename	gas_price_99 real_gp_atp`diff'
	rename	d1gp_bp  d1gp_bp_atp`diff'
	rename	d2gp_bp  d2gp_bp_atp`diff'

	drop if _mergep`diff'==2

	rename 	year yr_fullp`diff'
	lab var yr_fullp`diff' "Year before/after (`diff') full age" 
}

/* 	_merge==1 are years with older people but no gasoline data
	_merge==2 are years that are not yet adulted
*/

drop	_merge*

** Merge to current state prices at age 16 **

rename 	statefip bpl

gen		yr_at16 = birthyr + 16

merge m:1 stfip yr_at16  using "./output/dlpanel_prepped.dta"
keep	if _merge==3 /* Unmatched are post 2008 or pre 1967 */
drop	_merge year yr_at16
rename  min_age_full min_age_full_stnow

rename 	stfip statefip

foreach diff of numlist 0/2 {
	rename 	yr_fullp`diff' year 

	merge m:1 year statefip using "./output/gasprice_prepped.dta", keepusing(gas_price_99 d1gp_bp d2gp_bp) gen(_mergep`diff')
	/* 	_merge==1 are years with older people but no gasoline data
		_merge==2 are years that are not yet adulted
	*/
	drop if _merge==2
	*drop if _merge!=3
	drop 	_merge

	rename	gas_price_99 real_now_atp`diff'
	rename	d1gp_bp d1gp_now_atp`diff'
	rename	d2gp_bp d2gp_now_atp`diff'
	
	rename 	year yr_fullp`diff'
}

rename 	statefip stfip 
compress

********************************
********************************
** Panel Regressions 		 ***
********************************
********************************

gen 	age2 = age*age
gen 	lhhi = ln(w_hhi)

gegen stcenyr_fe = group(stfip censusyear_all)	
gegen bplcohort = group(bpl yr_age16)

drop if perwt==0
drop if bpl==2
drop if bpl==15
	/* Gas Price panel balanaced except AK HI */

gen 	byr = birthyr-1950

*--------------------------
*--------------------------
*--------------------------
** MW results
*--------------------------
*--------------------------
*--------------------------

*------------------------------------------------
*** Table 1 Row 1: heterogeneity by time period
*------------------------------------------------

* uses cohorts from 1951-1992; midpoint 1971
* include birthyear_1971 as a control
gen birthyear_1971 = inrange(birthyr,1971,1992)
gen d2gp_bp_at17_by71 = d2gp_bp_at17*birthyear_1971
lab var d2gp_bp_at17 "$\Delta$ Price"
lab var d2gp_bp_at17_by71 "$\Delta$ Price $\times$ Birthyear$\geq$1971"

table birthyear_1971, c(mean age)
* 40, 32

qui eststo tc2b_1:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_by71 birthyear_1971 if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_2:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_by71 birthyear_1971 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "All"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

** MW: col3 uses d2gp_now_at17
    * need to use same variable for table presentation
gen placeholder = d2gp_bp_at17
replace d2gp_bp_at17 = d2gp_now_at17
replace d2gp_bp_at17_by71 = d2gp_bp_at17*birthyear_1971

qui eststo tc2b_3:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_by71 birthyear_1971 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "All"
estadd local price_state "Res"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

replace d2gp_bp_at17 = placeholder
drop placeholder
replace d2gp_bp_at17_by71 = d2gp_bp_at17*birthyear_1971

** MW: put d_* in absorb()
qui eststo tc2b_4:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_by71 birthyear_1971 if m_samestate==1 [aw=perwt], a(bpl censusyear_all age d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem "Yes"
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_5:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_by71 birthyear_1971 lhhi if m_samestate==1 [aw=perwt], a(bpl censusyear_all age d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_6:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_by71 birthyear_1971 lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age  d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by ""

qui eststo tc2b_7:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_by71 birthyear_1971 lhhi c.byr##c.byr 	if m_samestate==1 [aw=perwt], a(stcenyr_fe age  d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"

local 	tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) nomtitle keep(d2gp_bp_at17 d2gp_bp_at17_by71) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "dem Demographics" "inc ln HH income" "sy_fe State $\times$ year FEs" "q_by Quad. birth year" "price_state Price in state of" "sample Sample")

esttab 	tc2b_* , replace `tabprefs' 
esttab tc2b_* using "$tables/table1_het_birthyear.tex",  replace `tabprefs'



*------------------------------------------------
*** Table 1 Row 1: heterogeneity by region (birthplace)
*------------------------------------------------

* https://usa.ipums.org/usa-action/variables/REGION#description_section
gen reg1 = (bpl==9|bpl==23|bpl==25|bpl==33|bpl==34|bpl==36|bpl==42|bpl==44|bpl==50)
* northeast
gen reg2 = (bpl==17|bpl==18|bpl==19|bpl==20|bpl==26|bpl==27|bpl==29|bpl==31|bpl==38|bpl==39|bpl==46|bpl==55)
* midwest
gen reg3 = (bpl==1|bpl==5|bpl==10|bpl==11|bpl==12|bpl==13|bpl==21|bpl==22|bpl==24|bpl==28|bpl==37|bpl==40|bpl==45|bpl==47|bpl==48|bpl==51|bpl==54)
* south
* west is omitted

gen d2gp_bp_at17_reg1 = d2gp_bp_at17*reg1
gen d2gp_bp_at17_reg2 = d2gp_bp_at17*reg2
gen d2gp_bp_at17_reg3 = d2gp_bp_at17*reg3
lab var d2gp_bp_at17 "$\Delta$ Price"
lab var d2gp_bp_at17_reg1 "$\Delta$ Price $\times$ Northeast"
lab var d2gp_bp_at17_reg2 "$\Delta$ Price $\times$ Midwest"
lab var d2gp_bp_at17_reg3 "$\Delta$ Price $\times$ South"

qui eststo tc2b_1:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_reg1 d2gp_bp_at17_reg2 d2gp_bp_at17_reg3 if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_2:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_reg1 d2gp_bp_at17_reg2 d2gp_bp_at17_reg3 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "All"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

** MW: col3 uses d2gp_now_at17
    * need to use same variable for table presentation
gen placeholder = d2gp_bp_at17
replace d2gp_bp_at17 = d2gp_now_at17
replace d2gp_bp_at17_reg1 = d2gp_bp_at17*reg1
replace d2gp_bp_at17_reg2 = d2gp_bp_at17*reg2
replace d2gp_bp_at17_reg3 = d2gp_bp_at17*reg3

qui eststo tc2b_3:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_reg1 d2gp_bp_at17_reg2 d2gp_bp_at17_reg3 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "All"
estadd local price_state "Res"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

replace d2gp_bp_at17 = placeholder
drop placeholder
replace d2gp_bp_at17_reg1 = d2gp_bp_at17*reg1
replace d2gp_bp_at17_reg2 = d2gp_bp_at17*reg2
replace d2gp_bp_at17_reg3 = d2gp_bp_at17*reg3

** MW: put d_* in absorb()
qui eststo tc2b_4:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_reg1 d2gp_bp_at17_reg2 d2gp_bp_at17_reg3 if m_samestate==1 [aw=perwt], a(bpl censusyear_all age d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem "Yes"
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_5:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_reg1 d2gp_bp_at17_reg2 d2gp_bp_at17_reg3 lhhi if m_samestate==1 [aw=perwt], a(bpl censusyear_all age d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_6:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_reg1 d2gp_bp_at17_reg2 d2gp_bp_at17_reg3 lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age  d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by ""

qui eststo tc2b_7:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_reg1 d2gp_bp_at17_reg2 d2gp_bp_at17_reg3 lhhi c.byr##c.byr 	if m_samestate==1 [aw=perwt], a(stcenyr_fe age  d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"

local 	tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) nomtitle keep(d2gp_bp_at17 d2gp_bp_at17_reg1 d2gp_bp_at17_reg2 d2gp_bp_at17_reg3) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "dem Demographics" "inc ln HH income" "sy_fe State $\times$ year FEs" "q_by Quad. birth year" "price_state Price in state of" "sample Sample")

esttab 	tc2b_* , replace `tabprefs' 
esttab tc2b_* using "$tables/table1_het_region.tex",  replace `tabprefs'

*------------------------------------------------
*** Table 1 Row 1: heterogeneity by sex
*------------------------------------------------

gen d2gp_bp_at17_fem = d2gp_bp_at17*d_fem
lab var d2gp_bp_at17 "$\Delta$ Price"
lab var d2gp_bp_at17_fem "$\Delta$ Price $\times$ Female"
* include d_fem in cols 1-3

qui eststo tc2b_1:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_fem if m_samestate==1 [aw=perwt], a(bpl censusyear_all age d_fem) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_2:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_fem [aw=perwt], a(bpl censusyear_all age d_fem) cluster(bpl)
estadd local sample "All"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

** MW: col3 uses d2gp_now_at17
    * need to use same variable for table presentation
gen placeholder = d2gp_bp_at17
replace d2gp_bp_at17 = d2gp_now_at17
replace d2gp_bp_at17_fem = d2gp_bp_at17*d_fem

qui eststo tc2b_3:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_fem [aw=perwt], a(bpl censusyear_all age d_fem) cluster(bpl)
estadd local sample "All"
estadd local price_state "Res"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

replace d2gp_bp_at17 = placeholder
drop placeholder
replace d2gp_bp_at17_fem = d2gp_bp_at17*d_fem

** MW: put d_* in absorb()
qui eststo tc2b_4:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_fem if m_samestate==1 [aw=perwt], a(bpl censusyear_all age d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem "Yes"
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_5:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_fem lhhi if m_samestate==1 [aw=perwt], a(bpl censusyear_all age d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_6:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_fem lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age  d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by ""

qui eststo tc2b_7:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_fem lhhi c.byr##c.byr 	if m_samestate==1 [aw=perwt], a(stcenyr_fe age  d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"

local 	tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) nomtitle keep(d2gp_bp_at17 d2gp_bp_at17_fem) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "dem Demographics" "inc ln HH income" "sy_fe State $\times$ year FEs" "q_by Quad. birth year" "price_state Price in state of" "sample Sample")

esttab 	tc2b_* , replace `tabprefs' 
esttab tc2b_* using "$tables/table1_het_sex.tex",  replace `tabprefs'

*------------------------------------------------
*** Table 1 Row 1: heterogeneity by race
*------------------------------------------------

* race variable is dropped in cleaning
gen d2gp_bp_at17_black = d2gp_bp_at17*d_black
lab var d2gp_bp_at17 "$\Delta$ Price"
lab var d2gp_bp_at17_black "$\Delta$ Price $\times$ Black"
* include d_black in cols 1-3

qui eststo tc2b_1:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_black if m_samestate==1 [aw=perwt], a(bpl censusyear_all age d_black) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_2:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_black [aw=perwt], a(bpl censusyear_all age d_black) cluster(bpl)
estadd local sample "All"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

** MW: col3 uses d2gp_now_at17
    * need to use same variable for table presentation
gen placeholder = d2gp_bp_at17
replace d2gp_bp_at17 = d2gp_now_at17
replace d2gp_bp_at17_black = d2gp_bp_at17*d_black

qui eststo tc2b_3:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_black [aw=perwt], a(bpl censusyear_all age d_black) cluster(bpl)
estadd local sample "All"
estadd local price_state "Res"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

replace d2gp_bp_at17 = placeholder
drop placeholder
replace d2gp_bp_at17_black = d2gp_bp_at17*d_black

** MW: put d_* in absorb()
qui eststo tc2b_4:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_black if m_samestate==1 [aw=perwt], a(bpl censusyear_all age d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem "Yes"
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_5:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_black lhhi if m_samestate==1 [aw=perwt], a(bpl censusyear_all age d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_6:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_black lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age  d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by ""

qui eststo tc2b_7:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_black lhhi c.byr##c.byr 	if m_samestate==1 [aw=perwt], a(stcenyr_fe age  d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"

local 	tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) nomtitle keep(d2gp_bp_at17 d2gp_bp_at17_black) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "dem Demographics" "inc ln HH income" "sy_fe State $\times$ year FEs" "q_by Quad. birth year" "price_state Price in state of" "sample Sample")

esttab 	tc2b_* , replace `tabprefs' 
esttab tc2b_* using "$tables/table1_het_race.tex",  replace `tabprefs'



*------------------------------------------------
*------------------------------------------------
*** Table 1 Row 1: price increase vs decrease
*------------------------------------------------
*------------------------------------------------

*** interaction model

gen d2gp_bp_at17_sign_pos = inrange(d2gp_bp_at17,0,1)
gen d2gp_bp_at17_pos = d2gp_bp_at17*d2gp_bp_at17_sign_pos

lab var d2gp_bp_at17 "$\Delta$ Price"
lab var d2gp_bp_at17_pos "$\Delta$ Price $\times$ $\Delta$ Price$>$0"

qui eststo tc2b_1:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_pos d2gp_bp_at17_sign_pos if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_2:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_pos d2gp_bp_at17_sign_pos [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "All"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

** MW: col3 uses d2gp_now_at17
    * need to use same variable for table presentation
gen placeholder = d2gp_bp_at17
replace d2gp_bp_at17 = d2gp_now_at17
replace d2gp_bp_at17_sign_pos = inrange(d2gp_bp_at17,0,1)
replace d2gp_bp_at17_pos = d2gp_bp_at17*d2gp_bp_at17_sign_pos

qui eststo tc2b_3:	reghdfe t_drive d2gp_bp_at17  d2gp_bp_at17_pos d2gp_bp_at17_sign_pos [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "All"
estadd local price_state "Res"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

replace d2gp_bp_at17 = placeholder
drop placeholder
replace d2gp_bp_at17_sign_pos = inrange(d2gp_bp_at17,0,1)
replace d2gp_bp_at17_pos = d2gp_bp_at17*d2gp_bp_at17_sign_pos

** MW: put d_* in absorb()
qui eststo tc2b_4:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_pos d2gp_bp_at17_sign_pos if m_samestate==1 [aw=perwt], a(bpl censusyear_all age d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem "Yes"
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_5:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_pos d2gp_bp_at17_sign_pos lhhi if m_samestate==1 [aw=perwt], a(bpl censusyear_all age d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_6:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_pos d2gp_bp_at17_sign_pos lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age  d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by ""

qui eststo tc2b_7:	reghdfe t_drive d2gp_bp_at17 d2gp_bp_at17_pos d2gp_bp_at17_sign_pos lhhi c.byr##c.byr 	if m_samestate==1 [aw=perwt], a(stcenyr_fe age  d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"

local 	tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) nomtitle keep(d2gp_bp_at17 d2gp_bp_at17_pos) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "dem Demographics" "inc ln HH income" "sy_fe State $\times$ year FEs" "q_by Quad. birth year" "price_state Price in state of" "sample Sample")

esttab 	tc2b_* , replace `tabprefs' 
esttab tc2b_* using "$tables/table1_pos_neg.tex",  replace `tabprefs'


set scheme plotplainblind

binscatter t_drive d2gp_bp_at17 [aw=perwt] if m_samestate==1, rd(0) absorb(bpl) controls(censusyear_all age) xtitle("Price change (percent)") ytitle("Drive")
graph export "$figures/table1_binscatter.png", replace

*----------------------
*** absolute effects

gen d2gp_bp_at17_sign_neg = inrange(d2gp_bp_at17,-1,0)
gen d2gp_bp_at17_neg = d2gp_bp_at17*d2gp_bp_at17_sign_neg
lab var d2gp_bp_at17_neg "$\Delta$ Price $\times$ $\Delta$ Price$<$0"

qui eststo tc2b_1:	reghdfe t_drive d2gp_bp_at17_neg d2gp_bp_at17_pos d2gp_bp_at17_sign_pos if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_2:	reghdfe t_drive d2gp_bp_at17_neg d2gp_bp_at17_pos d2gp_bp_at17_sign_pos [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "All"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

** MW: col3 uses d2gp_now_at17
    * need to use same variable for table presentation
gen placeholder = d2gp_bp_at17
replace d2gp_bp_at17 = d2gp_now_at17
replace d2gp_bp_at17_sign_neg = inrange(d2gp_bp_at17,-1,0)
replace d2gp_bp_at17_neg = d2gp_bp_at17*d2gp_bp_at17_sign_neg
replace d2gp_bp_at17_sign_pos = inrange(d2gp_bp_at17,0,1)
replace d2gp_bp_at17_pos = d2gp_bp_at17*d2gp_bp_at17_sign_pos

qui eststo tc2b_3:	reghdfe t_drive d2gp_bp_at17_neg d2gp_bp_at17_pos d2gp_bp_at17_sign_pos [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "All"
estadd local price_state "Res"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

replace d2gp_bp_at17 = placeholder
drop placeholder
replace d2gp_bp_at17_sign_neg = inrange(d2gp_bp_at17,-1,0)
replace d2gp_bp_at17_neg = d2gp_bp_at17*d2gp_bp_at17_sign_neg
replace d2gp_bp_at17_sign_pos = inrange(d2gp_bp_at17,0,1)
replace d2gp_bp_at17_pos = d2gp_bp_at17*d2gp_bp_at17_sign_pos

** MW: put d_* in absorb()
qui eststo tc2b_4:	reghdfe t_drive d2gp_bp_at17_neg d2gp_bp_at17_pos d2gp_bp_at17_sign_pos if m_samestate==1 [aw=perwt], a(bpl censusyear_all age d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem "Yes"
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_5:	reghdfe t_drive d2gp_bp_at17_neg d2gp_bp_at17_pos d2gp_bp_at17_sign_pos lhhi if m_samestate==1 [aw=perwt], a(bpl censusyear_all age d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_6:	reghdfe t_drive d2gp_bp_at17_neg d2gp_bp_at17_pos d2gp_bp_at17_sign_pos lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age  d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by ""

qui eststo tc2b_7:	reghdfe t_drive d2gp_bp_at17_neg d2gp_bp_at17_pos d2gp_bp_at17_sign_pos lhhi c.byr##c.byr 	if m_samestate==1 [aw=perwt], a(stcenyr_fe age  d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"

local 	tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) nomtitle keep(d2gp_bp_at17_neg d2gp_bp_at17_pos) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "dem Demographics" "inc ln HH income" "sy_fe State $\times$ year FEs" "q_by Quad. birth year" "price_state Price in state of" "sample Sample")

esttab 	tc2b_* , replace `tabprefs' 
esttab tc2b_* using "$tables/table1_pos_neg_overall.tex",  replace `tabprefs'


*------------------------
*** subsample regressions

* price increases
est clear

qui eststo tc2b_1:	reghdfe t_drive d2gp_bp_at17 if m_samestate==1 & d2gp_bp_at17_sign_pos==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_2:	reghdfe t_drive d2gp_bp_at17 if d2gp_bp_at17_sign_pos==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "All"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

** MW: col3 uses d2gp_now_at17
    * need to use same variable for table presentation
gen placeholder = d2gp_bp_at17
replace d2gp_bp_at17 = d2gp_now_at17
replace d2gp_bp_at17_sign_pos = inrange(d2gp_bp_at17,0,1)
replace d2gp_bp_at17_pos = d2gp_bp_at17*d2gp_bp_at17_sign_pos

qui eststo tc2b_3:	reghdfe t_drive d2gp_bp_at17  if d2gp_bp_at17_sign_pos==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "All"
estadd local price_state "Res"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

replace d2gp_bp_at17 = placeholder
drop placeholder
replace d2gp_bp_at17_sign_pos = inrange(d2gp_bp_at17,0,1)
replace d2gp_bp_at17_pos = d2gp_bp_at17*d2gp_bp_at17_sign_pos

** MW: put d_* in absorb()
qui eststo tc2b_4:	reghdfe t_drive d2gp_bp_at17 if m_samestate==1 & d2gp_bp_at17_sign_pos==1 [aw=perwt], a(bpl censusyear_all age d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem "Yes"
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_5:	reghdfe t_drive d2gp_bp_at17 lhhi if m_samestate==1 & d2gp_bp_at17_sign_pos==1 [aw=perwt], a(bpl censusyear_all age d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_6:	reghdfe t_drive d2gp_bp_at17 lhhi if m_samestate==1 & d2gp_bp_at17_sign_pos==1 [aw=perwt], a(stcenyr_fe age  d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by ""

qui eststo tc2b_7:	reghdfe t_drive d2gp_bp_at17 lhhi c.byr##c.byr 	if m_samestate==1  & d2gp_bp_at17_sign_pos==1 [aw=perwt], a(stcenyr_fe age  d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"

local 	tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) nomtitle keep(d2gp_bp_at17) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "dem Demographics" "inc ln HH income" "sy_fe State $\times$ year FEs" "q_by Quad. birth year" "price_state Price in state of" "sample Sample")

esttab 	tc2b_* , replace `tabprefs' 
esttab tc2b_* using "$tables/table1_subsample_pos.tex",  replace `tabprefs'

* price decreases
est clear

qui eststo tc2b_1:	reghdfe t_drive d2gp_bp_at17 if m_samestate==1 & d2gp_bp_at17_sign_pos==0 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_2:	reghdfe t_drive d2gp_bp_at17 if d2gp_bp_at17_sign_pos==0 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "All"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

** MW: col3 uses d2gp_now_at17
    * need to use same variable for table presentation
gen placeholder = d2gp_bp_at17
replace d2gp_bp_at17 = d2gp_now_at17
replace d2gp_bp_at17_sign_pos = inrange(d2gp_bp_at17,0,1)
replace d2gp_bp_at17_pos = d2gp_bp_at17*d2gp_bp_at17_sign_pos

qui eststo tc2b_3:	reghdfe t_drive d2gp_bp_at17  if d2gp_bp_at17_sign_pos==0 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "All"
estadd local price_state "Res"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

replace d2gp_bp_at17 = placeholder
drop placeholder
replace d2gp_bp_at17_sign_pos = inrange(d2gp_bp_at17,0,1)
replace d2gp_bp_at17_pos = d2gp_bp_at17*d2gp_bp_at17_sign_pos

** MW: put d_* in absorb()
qui eststo tc2b_4:	reghdfe t_drive d2gp_bp_at17 if m_samestate==1 & d2gp_bp_at17_sign_pos==0 [aw=perwt], a(bpl censusyear_all age d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem "Yes"
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_5:	reghdfe t_drive d2gp_bp_at17 lhhi if m_samestate==1 & d2gp_bp_at17_sign_pos==0 [aw=perwt], a(bpl censusyear_all age d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_6:	reghdfe t_drive d2gp_bp_at17 lhhi if m_samestate==1 & d2gp_bp_at17_sign_pos==0 [aw=perwt], a(stcenyr_fe age  d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by ""

qui eststo tc2b_7:	reghdfe t_drive d2gp_bp_at17 lhhi c.byr##c.byr 	if m_samestate==1  & d2gp_bp_at17_sign_pos==0 [aw=perwt], a(stcenyr_fe age  d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"

local 	tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) nomtitle keep(d2gp_bp_at17) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "dem Demographics" "inc ln HH income" "sy_fe State $\times$ year FEs" "q_by Quad. birth year" "price_state Price in state of" "sample Sample")

esttab 	tc2b_* , replace `tabprefs' 
esttab tc2b_* using "$tables/table1_subsample_neg.tex",  replace `tabprefs'


*------------------------
*** logistic regression: table 1, row 1
*------------------------

su t_drive t_transit t_vehicle if m_samestate==1
* 0.90 0.03 0.95

est clear

qui eststo tc2b_1:	logit t_drive d2gp_bp_at17 i.censusyear_all i.age i.bpl if m_samestate==1 [pw=perwt], cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_2:	logit t_drive d2gp_bp_at17 i.censusyear_all i.age i.bpl [pw=perwt], cluster(bpl)
estadd local sample "All"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

** MW: col3 uses d2gp_now_at17
    * need to use same variable for table presentation
gen placeholder = d2gp_bp_at17
replace d2gp_bp_at17 = d2gp_now_at17

qui eststo tc2b_3:	logit t_drive d2gp_bp_at17 i.censusyear_all i.age i.bpl  [pw=perwt], cluster(bpl)
estadd local sample "All"
estadd local price_state "Res"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

replace d2gp_bp_at17 = placeholder
drop placeholder

qui eststo tc2b_4:	logit t_drive d2gp_bp_at17 i.censusyear_all i.age i.bpl i.d_* if m_samestate==1 [pw=perwt], cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem "Yes"
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_5:	logit t_drive d2gp_bp_at17 lhhi i.censusyear_all i.age i.bpl i.d_* if m_samestate==1 [pw=perwt], cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe ""
estadd local q_by ""

* doesn't run in 24h
/* qui eststo tc2b_6:	logit t_drive d2gp_bp_at17 lhhi i.stcenyr_fe i.age if m_samestate==1 [pw=perwt], cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by ""

qui eststo tc2b_7:	logit t_drive d2gp_bp_at17 lhhi i.stcenyr_fe i.age c.byr##c.byr i.d_* if m_samestate==1  [pw=perwt], cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes" */

local 	tabprefs b(%9.4f) se label star(* 0.1 ** 0.05 *** 0.01) nomtitle keep(d2gp_bp_at17) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "dem Demographics" "inc ln HH income"  "price_state Price in state of" "sample Sample") eqlabels(none)
*local 	tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) nomtitle keep(d2gp_bp_at17) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "dem Demographics" "inc ln HH income" "sy_fe State $\times$ year FEs" "q_by Quad. birth year" "price_state Price in state of" "sample Sample") eqlabels(none)

esttab 	tc2b_* , replace `tabprefs' 
esttab tc2b_* using "$tables/table1_logit.tex",  replace `tabprefs'


*------------------------------------------
*------------------------------------------
*** Table 1 Row 3: gas price at age of driver's license
*------------------------------------------
*------------------------------------------

*** interaction model 
/* 
gen d2gp_bp_atp1_sign_pos = inrange(d2gp_bp_atp1,0,1)
gen d2gp_bp_atp1_pos = d2gp_bp_atp1*d2gp_bp_atp1_sign_pos

lab var d2gp_bp_atp1 "$\Delta$ Price"
lab var d2gp_bp_atp1_pos "$\Delta$ Price $\times$ $\Delta$ Price$>$0"

qui eststo tc2b_1:	reghdfe t_drive d2gp_bp_atp1 d2gp_bp_atp1_pos d2gp_bp_atp1_sign_pos if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_2:	reghdfe t_drive d2gp_bp_atp1 d2gp_bp_atp1_pos d2gp_bp_atp1_sign_pos [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "All"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

** MW: col3 uses d2gp_now_atp1
    * need to use same variable for table presentation
gen placeholder = d2gp_bp_atp1
replace d2gp_bp_atp1 = d2gp_now_atp1
replace d2gp_bp_atp1_sign_pos = inrange(d2gp_bp_atp1,0,1)
replace d2gp_bp_atp1_pos = d2gp_bp_atp1*d2gp_bp_atp1_sign_pos

qui eststo tc2b_3:	reghdfe t_drive d2gp_bp_atp1  d2gp_bp_atp1_pos d2gp_bp_atp1_sign_pos [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "All"
estadd local price_state "Res"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

replace d2gp_bp_atp1 = placeholder
drop placeholder
replace d2gp_bp_atp1_sign_pos = inrange(d2gp_bp_atp1,0,1)
replace d2gp_bp_atp1_pos = d2gp_bp_atp1*d2gp_bp_atp1_sign_pos

** MW: put d_* in absorb()
qui eststo tc2b_4:	reghdfe t_drive d2gp_bp_atp1 d2gp_bp_atp1_pos d2gp_bp_atp1_sign_pos if m_samestate==1 [aw=perwt], a(bpl censusyear_all age d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem "Yes"
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_5:	reghdfe t_drive d2gp_bp_atp1 d2gp_bp_atp1_pos d2gp_bp_atp1_sign_pos lhhi if m_samestate==1 [aw=perwt], a(bpl censusyear_all age d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_6:	reghdfe t_drive d2gp_bp_atp1 d2gp_bp_atp1_pos d2gp_bp_atp1_sign_pos lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age  d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by ""

qui eststo tc2b_7:	reghdfe t_drive d2gp_bp_atp1 d2gp_bp_atp1_pos d2gp_bp_atp1_sign_pos lhhi c.byr##c.byr 	if m_samestate==1 [aw=perwt], a(stcenyr_fe age  d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"

local 	tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) nomtitle keep(d2gp_bp_atp1 d2gp_bp_atp1_pos) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "dem Demographics" "inc ln HH income" "sy_fe State $\times$ year FEs" "q_by Quad. birth year" "price_state Price in state of" "sample Sample")

esttab 	tc2b_* , replace `tabprefs' 
esttab tc2b_* using "$tables/table1_dl_pos_neg.tex",  replace `tabprefs'



binscatter t_drive d2gp_bp_atp1 [aw=perwt] if m_samestate==1, rd(0) absorb(bpl) controls(censusyear_all age) xtitle("Price change (percent)") ytitle("Drive")
graph export "$figures/table1_dl_binscatter.png", replace

*-----------------------
*** absolute effects

gen d2gp_bp_atp1_sign_neg = inrange(d2gp_bp_atp1,-1,0)
gen d2gp_bp_atp1_neg = d2gp_bp_atp1*d2gp_bp_atp1_sign_neg
lab var d2gp_bp_atp1_neg "$\Delta$ Price $\times$ $\Delta$ Price$<$0"

qui eststo tc2b_1:	reghdfe t_drive d2gp_bp_atp1_neg d2gp_bp_atp1_pos d2gp_bp_atp1_sign_pos if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_2:	reghdfe t_drive d2gp_bp_atp1_neg d2gp_bp_atp1_pos d2gp_bp_atp1_sign_pos [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "All"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

** MW: col3 uses d2gp_now_atp1
    * need to use same variable for table presentation
gen placeholder = d2gp_bp_atp1
replace d2gp_bp_atp1 = d2gp_now_atp1
replace d2gp_bp_atp1_sign_pos = inrange(d2gp_bp_atp1,0,1)
replace d2gp_bp_atp1_pos = d2gp_bp_atp1*d2gp_bp_atp1_sign_pos
replace d2gp_bp_atp1_sign_neg = inrange(d2gp_bp_atp1,-1,0)
replace d2gp_bp_atp1_neg = d2gp_bp_atp1*d2gp_bp_atp1_sign_neg

qui eststo tc2b_3:	reghdfe t_drive d2gp_bp_atp1_neg  d2gp_bp_atp1_pos d2gp_bp_atp1_sign_pos [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "All"
estadd local price_state "Res"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

replace d2gp_bp_atp1 = placeholder
drop placeholder
replace d2gp_bp_atp1_sign_pos = inrange(d2gp_bp_atp1,0,1)
replace d2gp_bp_atp1_pos = d2gp_bp_atp1*d2gp_bp_atp1_sign_pos
replace d2gp_bp_atp1_sign_neg = inrange(d2gp_bp_atp1,-1,0)
replace d2gp_bp_atp1_neg = d2gp_bp_atp1*d2gp_bp_atp1_sign_neg

** MW: put d_* in absorb()
qui eststo tc2b_4:	reghdfe t_drive d2gp_bp_atp1_neg d2gp_bp_atp1_pos d2gp_bp_atp1_sign_pos if m_samestate==1 [aw=perwt], a(bpl censusyear_all age d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem "Yes"
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_5:	reghdfe t_drive d2gp_bp_atp1_neg d2gp_bp_atp1_pos d2gp_bp_atp1_sign_pos lhhi if m_samestate==1 [aw=perwt], a(bpl censusyear_all age d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_6:	reghdfe t_drive d2gp_bp_atp1_neg d2gp_bp_atp1_pos d2gp_bp_atp1_sign_pos lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age  d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by ""

qui eststo tc2b_7:	reghdfe t_drive d2gp_bp_atp1_neg d2gp_bp_atp1_pos d2gp_bp_atp1_sign_pos lhhi c.byr##c.byr 	if m_samestate==1 [aw=perwt], a(stcenyr_fe age  d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"

local 	tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) nomtitle keep(d2gp_bp_atp1_neg d2gp_bp_atp1_pos) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "dem Demographics" "inc ln HH income" "sy_fe State $\times$ year FEs" "q_by Quad. birth year" "price_state Price in state of" "sample Sample")

esttab 	tc2b_* , replace `tabprefs' 
esttab tc2b_* using "$tables/table1_dl_pos_neg_overall.tex",  replace `tabprefs'


*------------------------
*** subsample regressions

*** price increases
est clear

qui eststo tc2b_1:	reghdfe t_drive d2gp_bp_atp1 if m_samestate==1 & d2gp_bp_atp1_sign_pos==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_2:	reghdfe t_drive d2gp_bp_atp1 if d2gp_bp_atp1_sign_pos==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "All"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

** MW: col3 uses d2gp_now_at17
    * need to use same variable for table presentation
gen placeholder = d2gp_bp_atp1
replace d2gp_bp_atp1 = d2gp_now_atp1
replace d2gp_bp_atp1_sign_pos = inrange(d2gp_bp_atp1,0,1)
replace d2gp_bp_atp1_pos = d2gp_bp_atp1*d2gp_bp_atp1_sign_pos

qui eststo tc2b_3:	reghdfe t_drive d2gp_bp_atp1  if d2gp_bp_atp1_sign_pos==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "All"
estadd local price_state "Res"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

replace d2gp_bp_atp1 = placeholder
drop placeholder
replace d2gp_bp_atp1_sign_pos = inrange(d2gp_bp_atp1,0,1)
replace d2gp_bp_atp1_pos = d2gp_bp_atp1*d2gp_bp_atp1_sign_pos

** MW: put d_* in absorb()
qui eststo tc2b_4:	reghdfe t_drive d2gp_bp_atp1 if m_samestate==1 & d2gp_bp_atp1_sign_pos==1 [aw=perwt], a(bpl censusyear_all age d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem "Yes"
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_5:	reghdfe t_drive d2gp_bp_atp1 lhhi if m_samestate==1 & d2gp_bp_atp1_sign_pos==1 [aw=perwt], a(bpl censusyear_all age d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_6:	reghdfe t_drive d2gp_bp_atp1 lhhi if m_samestate==1 & d2gp_bp_atp1_sign_pos==1 [aw=perwt], a(stcenyr_fe age  d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by ""

qui eststo tc2b_7:	reghdfe t_drive d2gp_bp_atp1 lhhi c.byr##c.byr 	if m_samestate==1  & d2gp_bp_atp1_sign_pos==1 [aw=perwt], a(stcenyr_fe age  d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"

local 	tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) nomtitle keep(d2gp_bp_atp1) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "dem Demographics" "inc ln HH income" "sy_fe State $\times$ year FEs" "q_by Quad. birth year" "price_state Price in state of" "sample Sample")

esttab 	tc2b_* , replace `tabprefs' 
esttab tc2b_* using "$tables/table1_dl_subsample_pos.tex",  replace `tabprefs'

*** price decreases
est clear

qui eststo tc2b_1:	reghdfe t_drive d2gp_bp_atp1 if m_samestate==1 & d2gp_bp_atp1_sign_pos==0 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_2:	reghdfe t_drive d2gp_bp_atp1 if d2gp_bp_atp1_sign_pos==0 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "All"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

** MW: col3 uses d2gp_now_at17
    * need to use same variable for table presentation
gen placeholder = d2gp_bp_atp1
replace d2gp_bp_atp1 = d2gp_now_atp1
replace d2gp_bp_atp1_sign_pos = inrange(d2gp_bp_atp1,0,1)
replace d2gp_bp_atp1_pos = d2gp_bp_atp1*d2gp_bp_atp1_sign_pos

qui eststo tc2b_3:	reghdfe t_drive d2gp_bp_atp1  if d2gp_bp_atp1_sign_pos==0 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local sample "All"
estadd local price_state "Res"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

replace d2gp_bp_atp1 = placeholder
drop placeholder
replace d2gp_bp_atp1_sign_pos = inrange(d2gp_bp_atp1,0,1)
replace d2gp_bp_atp1_pos = d2gp_bp_atp1*d2gp_bp_atp1_sign_pos

** MW: put d_* in absorb()
qui eststo tc2b_4:	reghdfe t_drive d2gp_bp_atp1 if m_samestate==1 & d2gp_bp_atp1_sign_pos==0 [aw=perwt], a(bpl censusyear_all age d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem "Yes"
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_5:	reghdfe t_drive d2gp_bp_atp1 lhhi if m_samestate==1 & d2gp_bp_atp1_sign_pos==0 [aw=perwt], a(bpl censusyear_all age d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe ""
estadd local q_by ""

qui eststo tc2b_6:	reghdfe t_drive d2gp_bp_atp1 lhhi if m_samestate==1 & d2gp_bp_atp1_sign_pos==0 [aw=perwt], a(stcenyr_fe age  d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by ""

qui eststo tc2b_7:	reghdfe t_drive d2gp_bp_atp1 lhhi c.byr##c.byr 	if m_samestate==1  & d2gp_bp_atp1_sign_pos==0 [aw=perwt], a(stcenyr_fe age  d_fem d_marr d_hs d_col d_black d_hisp) cluster(bpl)
estadd local sample "Stay"
estadd local price_state "Birth"
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"

local 	tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) nomtitle keep(d2gp_bp_atp1) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "dem Demographics" "inc ln HH income" "sy_fe State $\times$ year FEs" "q_by Quad. birth year" "price_state Price in state of" "sample Sample")

esttab 	tc2b_* , replace `tabprefs' 
esttab tc2b_* using "$tables/table1_dl_subsample_neg.tex",  replace `tabprefs' */


*-----------------------------------
*-----------------------------------
*-----------------------------------
*-----------------------------------
* Table 2 Row 1
*-----------------------------------
*-----------------------------------
*-----------------------------------
*-----------------------------------

*-----------------------------------
*** heterogeneity by time period
*-----------------------------------

* uses cohorts from 1951-1992; midpoint 1971
* include birthyear_1971 as a control

est clear
qui eststo tother_b_1:	reghdfe t_transit d2gp_bp_at17 d2gp_bp_at17_by71 birthyear_1971 if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "Empl"

qui eststo tother_b_2:	reghdfe t_transit d2gp_bp_at17 d2gp_bp_at17_by71 birthyear_1971 c.byr##c.byr d_* lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "Empl"

qui eststo tother_b_3:	reghdfe t_vehicle d2gp_bp_at17 d2gp_bp_at17_by71 birthyear_1971 if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "Empl"

qui eststo tother_b_4:	reghdfe t_vehicle d2gp_bp_at17 d2gp_bp_at17_by71 birthyear_1971 c.byr##c.byr d_* lhhi if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "Empl"

qui eststo tother_b_5:	reghdfe t_vehicle d2gp_bp_at17 d2gp_bp_at17_by71 birthyear_1971 if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "All"

qui eststo tother_b_6:	reghdfe t_vehicle d2gp_bp_at17 d2gp_bp_at17_by71 birthyear_1971 c.byr##c.byr d_* lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "All"

local 	tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) keep(d2gp_bp_at17 d2gp_bp_at17_by71) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "dem Demographics" "inc ln HH income" "sy_fe State $\times$ year FEs" "q_by Quad. birth year" "sample Sample") mtitles("$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$")

esttab 	tother_b_* , replace `tabprefs' 
esttab tother_b_* using "$tables/table2_het_birthyear.tex",  replace `tabprefs'

*-----------------------------------
*** heterogeneity by region
*-----------------------------------

est clear
qui eststo tother_b_1:	reghdfe t_transit d2gp_bp_at17 d2gp_bp_at17_reg1 d2gp_bp_at17_reg2 d2gp_bp_at17_reg3 if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "Empl"

qui eststo tother_b_2:	reghdfe t_transit d2gp_bp_at17 d2gp_bp_at17_reg1 d2gp_bp_at17_reg2 d2gp_bp_at17_reg3 c.byr##c.byr d_* lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "Empl"

qui eststo tother_b_3:	reghdfe t_vehicle d2gp_bp_at17 d2gp_bp_at17_reg1 d2gp_bp_at17_reg2 d2gp_bp_at17_reg3 if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "Empl"

qui eststo tother_b_4:	reghdfe t_vehicle d2gp_bp_at17 d2gp_bp_at17_reg1 d2gp_bp_at17_reg2 d2gp_bp_at17_reg3 c.byr##c.byr d_* lhhi if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "Empl"

qui eststo tother_b_5:	reghdfe t_vehicle d2gp_bp_at17 d2gp_bp_at17_reg1 d2gp_bp_at17_reg2 d2gp_bp_at17_reg3 if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "All"

qui eststo tother_b_6:	reghdfe t_vehicle d2gp_bp_at17 d2gp_bp_at17_reg1 d2gp_bp_at17_reg2 d2gp_bp_at17_reg3 c.byr##c.byr d_* lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "All"

local 	tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) keep(d2gp_bp_at17 d2gp_bp_at17_reg1 d2gp_bp_at17_reg2 d2gp_bp_at17_reg3) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "dem Demographics" "inc ln HH income" "sy_fe State $\times$ year FEs" "q_by Quad. birth year" "sample Sample") mtitles("$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$")

esttab 	tother_b_* , replace `tabprefs' 
esttab tother_b_* using "$tables/table2_het_region.tex",  replace `tabprefs'

*-----------------------------------
*** heterogeneity by sex
*-----------------------------------
* include d_fem in cols 1,3,5

est clear
qui eststo tother_b_1:	reghdfe t_transit d2gp_bp_at17 d2gp_bp_at17_fem if m_samestate==1 [aw=perwt], a(bpl censusyear_all age d_fem) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "Empl"

qui eststo tother_b_2:	reghdfe t_transit d2gp_bp_at17 d2gp_bp_at17_fem c.byr##c.byr d_* lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "Empl"

qui eststo tother_b_3:	reghdfe t_vehicle d2gp_bp_at17 d2gp_bp_at17_fem if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(bpl censusyear_all age d_fem) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "Empl"

qui eststo tother_b_4:	reghdfe t_vehicle d2gp_bp_at17 d2gp_bp_at17_fem c.byr##c.byr d_* lhhi if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "Empl"

qui eststo tother_b_5:	reghdfe t_vehicle d2gp_bp_at17 d2gp_bp_at17_fem if m_samestate==1 [aw=perwt], a(bpl censusyear_all age d_fem) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "All"

qui eststo tother_b_6:	reghdfe t_vehicle d2gp_bp_at17 d2gp_bp_at17_fem c.byr##c.byr d_* lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "All"

local 	tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) keep(d2gp_bp_at17 d2gp_bp_at17_fem) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "dem Demographics" "inc ln HH income" "sy_fe State $\times$ year FEs" "q_by Quad. birth year" "sample Sample") mtitles("$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$")

esttab 	tother_b_* , replace `tabprefs' 
esttab tother_b_* using "$tables/table2_het_sex.tex",  replace `tabprefs'

*-----------------------------------
*** heterogeneity by race
*-----------------------------------
* include d_black in cols 1,3,5

est clear
qui eststo tother_b_1:	reghdfe t_transit d2gp_bp_at17 d2gp_bp_at17_black if m_samestate==1 [aw=perwt], a(bpl censusyear_all age d_black) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "Empl"

qui eststo tother_b_2:	reghdfe t_transit d2gp_bp_at17 d2gp_bp_at17_black c.byr##c.byr d_* lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "Empl"

qui eststo tother_b_3:	reghdfe t_vehicle d2gp_bp_at17 d2gp_bp_at17_black if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(bpl censusyear_all age d_black) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "Empl"

qui eststo tother_b_4:	reghdfe t_vehicle d2gp_bp_at17 d2gp_bp_at17_black c.byr##c.byr d_* lhhi if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "Empl"

qui eststo tother_b_5:	reghdfe t_vehicle d2gp_bp_at17 d2gp_bp_at17_black if m_samestate==1 [aw=perwt], a(bpl censusyear_all age d_black) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "All"

qui eststo tother_b_6:	reghdfe t_vehicle d2gp_bp_at17 d2gp_bp_at17_black c.byr##c.byr d_* lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "All"

local 	tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) keep(d2gp_bp_at17 d2gp_bp_at17_black) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "dem Demographics" "inc ln HH income" "sy_fe State $\times$ year FEs" "q_by Quad. birth year" "sample Sample") mtitles("$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$")

esttab 	tother_b_* , replace `tabprefs' 
esttab tother_b_* using "$tables/table2_het_race.tex",  replace `tabprefs'

*--------------------------
*** interaction model
*--------------------------

est clear
qui eststo tother_b_1:	reghdfe t_transit d2gp_bp_at17 d2gp_bp_at17_pos d2gp_bp_at17_sign_pos if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "Empl"

qui eststo tother_b_2:	reghdfe t_transit d2gp_bp_at17 d2gp_bp_at17_pos d2gp_bp_at17_sign_pos c.byr##c.byr d_* lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "Empl"

qui eststo tother_b_3:	reghdfe t_vehicle d2gp_bp_at17 d2gp_bp_at17_pos d2gp_bp_at17_sign_pos if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "Empl"

qui eststo tother_b_4:	reghdfe t_vehicle d2gp_bp_at17 d2gp_bp_at17_pos d2gp_bp_at17_sign_pos c.byr##c.byr d_* lhhi if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "Empl"

qui eststo tother_b_5:	reghdfe t_vehicle d2gp_bp_at17 d2gp_bp_at17_pos d2gp_bp_at17_sign_pos if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "All"

qui eststo tother_b_6:	reghdfe t_vehicle d2gp_bp_at17 d2gp_bp_at17_pos d2gp_bp_at17_sign_pos c.byr##c.byr d_* lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "All"

local 	tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) keep(d2gp_bp_at17 d2gp_bp_at17_pos) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "dem Demographics" "inc ln HH income" "sy_fe State $\times$ year FEs" "q_by Quad. birth year" "sample Sample") mtitles("$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$")

esttab 	tother_b_* , replace `tabprefs' 
esttab tother_b_* using "$tables/table2_pos_neg.tex",  replace `tabprefs'

*** absolute effects

est clear
qui eststo tother_b_1:	reghdfe t_transit d2gp_bp_at17_neg d2gp_bp_at17_pos d2gp_bp_at17_sign_pos if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "Empl"

qui eststo tother_b_2:	reghdfe t_transit d2gp_bp_at17_neg d2gp_bp_at17_pos d2gp_bp_at17_sign_pos c.byr##c.byr d_* lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "Empl"

qui eststo tother_b_3:	reghdfe t_vehicle d2gp_bp_at17_neg d2gp_bp_at17_pos d2gp_bp_at17_sign_pos if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "Empl"

qui eststo tother_b_4:	reghdfe t_vehicle d2gp_bp_at17_neg d2gp_bp_at17_pos d2gp_bp_at17_sign_pos c.byr##c.byr d_* lhhi if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "Empl"

qui eststo tother_b_5:	reghdfe t_vehicle d2gp_bp_at17_neg d2gp_bp_at17_pos d2gp_bp_at17_sign_pos if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "All"

qui eststo tother_b_6:	reghdfe t_vehicle d2gp_bp_at17_neg d2gp_bp_at17_pos d2gp_bp_at17_sign_pos c.byr##c.byr d_* lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "All"

local 	tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) keep(d2gp_bp_at17_neg d2gp_bp_at17_pos) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "dem Demographics" "inc ln HH income" "sy_fe State $\times$ year FEs" "q_by Quad. birth year" "sample Sample") mtitles("$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$")

esttab 	tother_b_* , replace `tabprefs' 
esttab tother_b_* using "$tables/table2_pos_neg_overall.tex",  replace `tabprefs'



*** subsample regressions
* price increase

est clear

qui eststo tother_b_1:	reghdfe t_transit d2gp_bp_at17 if m_samestate==1 & d2gp_bp_at17_sign_pos==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "Empl"

qui eststo tother_b_2:	reghdfe t_transit d2gp_bp_at17 c.byr##c.byr d_* lhhi if m_samestate==1 & d2gp_bp_at17_sign_pos==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "Empl"

qui eststo tother_b_3:	reghdfe t_vehicle d2gp_bp_at17 if m_samestate==1 & mi(t_transit)==0 & d2gp_bp_at17_sign_pos==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "Empl"

qui eststo tother_b_4:	reghdfe t_vehicle d2gp_bp_at17 c.byr##c.byr d_* lhhi if m_samestate==1 & mi(t_transit)==0 & d2gp_bp_at17_sign_pos==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "Empl"

qui eststo tother_b_5:	reghdfe t_vehicle d2gp_bp_at17 if m_samestate==1 & d2gp_bp_at17_sign_pos==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "All"

qui eststo tother_b_6:	reghdfe t_vehicle d2gp_bp_at17 c.byr##c.byr d_* lhhi if m_samestate==1 & d2gp_bp_at17_sign_pos==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "All"

local 	tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) keep(d2gp_bp_at17) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "dem Demographics" "inc ln HH income" "sy_fe State $\times$ year FEs" "q_by Quad. birth year" "sample Sample") mtitles("$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$")

esttab 	tother_b_* , replace `tabprefs' 
esttab tother_b_* using "$tables/table2_subsample_pos.tex",  replace `tabprefs'

* price decrease

est clear

qui eststo tother_b_1:	reghdfe t_transit d2gp_bp_at17 if m_samestate==1 & d2gp_bp_at17_sign_pos==0 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "Empl"

qui eststo tother_b_2:	reghdfe t_transit d2gp_bp_at17 c.byr##c.byr d_* lhhi if m_samestate==1 & d2gp_bp_at17_sign_pos==0 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "Empl"

qui eststo tother_b_3:	reghdfe t_vehicle d2gp_bp_at17 if m_samestate==1 & mi(t_transit)==0 & d2gp_bp_at17_sign_pos==0 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "Empl"

qui eststo tother_b_4:	reghdfe t_vehicle d2gp_bp_at17 c.byr##c.byr d_* lhhi if m_samestate==1 & mi(t_transit)==0 & d2gp_bp_at17_sign_pos==0 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "Empl"

qui eststo tother_b_5:	reghdfe t_vehicle d2gp_bp_at17 if m_samestate==1 & d2gp_bp_at17_sign_pos==0 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "All"

qui eststo tother_b_6:	reghdfe t_vehicle d2gp_bp_at17 c.byr##c.byr d_* lhhi if m_samestate==1 & d2gp_bp_at17_sign_pos==0 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "All"

local 	tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) keep(d2gp_bp_at17) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "dem Demographics" "inc ln HH income" "sy_fe State $\times$ year FEs" "q_by Quad. birth year" "sample Sample") mtitles("$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$")

esttab 	tother_b_* , replace `tabprefs' 
esttab tother_b_* using "$tables/table2_subsample_neg.tex",  replace `tabprefs'


*------------------------
*** logistic regression: table 2, row 1
*------------------------


est clear
lab var d2gp_bp_at17 "$\Delta$ Price"

qui eststo tother_b_1:	logit  t_transit d2gp_bp_at17 i.bpl i.censusyear_all i.age if m_samestate==1 [pw=perwt], cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "Empl"


qui eststo tother_b_3:	logit  t_vehicle d2gp_bp_at17 i.bpl i.censusyear_all i.age if m_samestate==1 & mi(t_transit)==0 [pw=perwt], cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "Empl"

qui eststo tother_b_5:	logit  t_vehicle d2gp_bp_at17 i.bpl i.censusyear_all i.age if m_samestate==1 [pw=perwt], cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "All"

* doesn't converge
/* qui eststo tother_b_2:	logit  t_transit d2gp_bp_at17 c.byr##c.byr d_* lhhi i.stcenyr_fe i.age if m_samestate==1 [pw=perwt], cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "Empl"

qui eststo tother_b_4:	logit  t_vehicle d2gp_bp_at17 c.byr##c.byr d_* lhhi i.stcenyr_fe i.age if m_samestate==1 & mi(t_transit)==0 [pw=perwt], cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "Empl"

qui eststo tother_b_6:	logit t_vehicle d2gp_bp_at17 c.byr##c.byr d_* lhhi i.stcenyr_fe i.age if m_samestate==1 [pw=perwt], cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "All" */


local 	tabprefs b(%9.4f) se label star(* 0.1 ** 0.05 *** 0.01) keep(d2gp_bp_at17) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "sample Sample") mtitles("$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$") eqlabels(none)

esttab tother_b_1 tother_b_3 tother_b_5 , replace `tabprefs' 
esttab tother_b_1 tother_b_3 tother_b_5 using "$tables/table2_logit.tex",  replace `tabprefs'



*-----------------------------------
*-----------------------------------
*-----------------------------------
* Table 2 Row 3
*-----------------------------------
*-----------------------------------
*-----------------------------------

*** interaction model

/* est clear
qui eststo tother_b_1:	reghdfe t_transit d2gp_bp_atp1 d2gp_bp_atp1_pos d2gp_bp_atp1_sign_pos if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "Empl"

qui eststo tother_b_2:	reghdfe t_transit d2gp_bp_atp1 d2gp_bp_atp1_pos d2gp_bp_atp1_sign_pos c.byr##c.byr d_* lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "Empl"

qui eststo tother_b_3:	reghdfe t_vehicle d2gp_bp_atp1 d2gp_bp_atp1_pos d2gp_bp_atp1_sign_pos if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "Empl"

qui eststo tother_b_4:	reghdfe t_vehicle d2gp_bp_atp1 d2gp_bp_atp1_pos d2gp_bp_atp1_sign_pos c.byr##c.byr d_* lhhi if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "Empl"

qui eststo tother_b_5:	reghdfe t_vehicle d2gp_bp_atp1 d2gp_bp_atp1_pos d2gp_bp_atp1_sign_pos if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "All"

qui eststo tother_b_6:	reghdfe t_vehicle d2gp_bp_atp1 d2gp_bp_atp1_pos d2gp_bp_atp1_sign_pos c.byr##c.byr d_* lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "All"

local 	tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) keep(d2gp_bp_atp1 d2gp_bp_atp1_pos) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "dem Demographics" "inc ln HH income" "sy_fe State $\times$ year FEs" "q_by Quad. birth year" "sample Sample") mtitles("$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$")

esttab 	tother_b_* , replace `tabprefs' 
esttab tother_b_* using "$tables/table2_dl_pos_neg.tex",  replace `tabprefs'

*** absolute effects

est clear
qui eststo tother_b_1:	reghdfe t_transit d2gp_bp_atp1_neg d2gp_bp_atp1_pos d2gp_bp_atp1_sign_pos if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "Empl"

qui eststo tother_b_2:	reghdfe t_transit d2gp_bp_atp1_neg d2gp_bp_atp1_pos d2gp_bp_atp1_sign_pos c.byr##c.byr d_* lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "Empl"

qui eststo tother_b_3:	reghdfe t_vehicle d2gp_bp_atp1_neg d2gp_bp_atp1_pos d2gp_bp_atp1_sign_pos if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "Empl"

qui eststo tother_b_4:	reghdfe t_vehicle d2gp_bp_atp1_neg d2gp_bp_atp1_pos d2gp_bp_atp1_sign_pos c.byr##c.byr d_* lhhi if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "Empl"

qui eststo tother_b_5:	reghdfe t_vehicle d2gp_bp_atp1_neg d2gp_bp_atp1_pos d2gp_bp_atp1_sign_pos if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "All"

qui eststo tother_b_6:	reghdfe t_vehicle d2gp_bp_atp1_neg d2gp_bp_atp1_pos d2gp_bp_atp1_sign_pos c.byr##c.byr d_* lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "All"

local 	tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) keep(d2gp_bp_atp1_neg d2gp_bp_atp1_pos) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "dem Demographics" "inc ln HH income" "sy_fe State $\times$ year FEs" "q_by Quad. birth year" "sample Sample") mtitles("$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$")

esttab 	tother_b_* , replace `tabprefs' 
esttab tother_b_* using "$tables/table2_dl_pos_neg_overall.tex",  replace `tabprefs'


*** subsample regressions
* price increase

est clear

qui eststo tother_b_1:	reghdfe t_transit d2gp_bp_atp1 if m_samestate==1 & d2gp_bp_atp1_sign_pos==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "Empl"

qui eststo tother_b_2:	reghdfe t_transit d2gp_bp_atp1 c.byr##c.byr d_* lhhi if m_samestate==1 & d2gp_bp_atp1_sign_pos==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "Empl"

qui eststo tother_b_3:	reghdfe t_vehicle d2gp_bp_atp1 if m_samestate==1 & mi(t_transit)==0 & d2gp_bp_atp1_sign_pos==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "Empl"

qui eststo tother_b_4:	reghdfe t_vehicle d2gp_bp_atp1 c.byr##c.byr d_* lhhi if m_samestate==1 & mi(t_transit)==0 & d2gp_bp_atp1_sign_pos==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "Empl"

qui eststo tother_b_5:	reghdfe t_vehicle d2gp_bp_atp1 if m_samestate==1 & d2gp_bp_atp1_sign_pos==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "All"

qui eststo tother_b_6:	reghdfe t_vehicle d2gp_bp_atp1 c.byr##c.byr d_* lhhi if m_samestate==1 & d2gp_bp_atp1_sign_pos==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "All"

local 	tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) keep(d2gp_bp_atp1) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "dem Demographics" "inc ln HH income" "sy_fe State $\times$ year FEs" "q_by Quad. birth year" "sample Sample") mtitles("$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$")

esttab 	tother_b_* , replace `tabprefs' 
esttab tother_b_* using "$tables/table2_dl_subsample_pos.tex",  replace `tabprefs'

* price decrease

est clear

qui eststo tother_b_1:	reghdfe t_transit d2gp_bp_atp1 if m_samestate==1 & d2gp_bp_atp1_sign_pos==0 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "Empl"

qui eststo tother_b_2:	reghdfe t_transit d2gp_bp_atp1 c.byr##c.byr d_* lhhi if m_samestate==1 & d2gp_bp_atp1_sign_pos==0 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "Empl"

qui eststo tother_b_3:	reghdfe t_vehicle d2gp_bp_atp1 if m_samestate==1 & mi(t_transit)==0 & d2gp_bp_atp1_sign_pos==0 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "Empl"

qui eststo tother_b_4:	reghdfe t_vehicle d2gp_bp_atp1 c.byr##c.byr d_* lhhi if m_samestate==1 & mi(t_transit)==0 & d2gp_bp_atp1_sign_pos==0 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "Empl"

qui eststo tother_b_5:	reghdfe t_vehicle d2gp_bp_atp1 if m_samestate==1 & d2gp_bp_atp1_sign_pos==0 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
estadd local cy_fe "Yes"
estadd local sob_fe "Yes"
estadd local dem ""
estadd local inc ""
estadd local sy_fe ""
estadd local q_by ""
estadd local sample "All"

qui eststo tother_b_6:	reghdfe t_vehicle d2gp_bp_atp1 c.byr##c.byr d_* lhhi if m_samestate==1 & d2gp_bp_atp1_sign_pos==0 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
estadd local cy_fe ""
estadd local sob_fe ""
estadd local dem "Yes"
estadd local inc "Yes"
estadd local sy_fe "Yes"
estadd local q_by "Yes"
estadd local sample "All"

local 	tabprefs b(%9.4f) se ar2 label star(* 0.1 ** 0.05 *** 0.01) keep(d2gp_bp_atp1) scalars("cy_fe Census year FEs" "sob_fe State of birth FEs" "dem Demographics" "inc ln HH income" "sy_fe State $\times$ year FEs" "q_by Quad. birth year" "sample Sample") mtitles("$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{transit}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$" "$\mathbbm{1}[\text{vehicle}]$")

esttab 	tother_b_* , replace `tabprefs' 
esttab tother_b_* using "$tables/table2_dl_subsample_neg.tex",  replace `tabprefs' */



















/* Summary Statistics */ 
/* 
** Table A2 (partial) **

eststo 	sum1: estpost tabstat t_drive  t_transit  t_vehicle d2gp_bp_at17 e_emp age d_* w_hhi m_samestate [aw=perwt], s(mean sd count) c(s) 
eststo 	sum2: estpost tabstat t_drive  t_transit  t_vehicle d2gp_bp_at17 age d_* w_hhi m_samestate if e_emp==1 [aw=perwt], s(mean sd count) c(s) 
eststo 	sum3: estpost tabstat t_drive  t_transit  t_vehicle d2gp_bp_at17 e_emp age d_* w_hhi if m_samestate==1, s(mean sd count) c(s) 
eststo 	sum4: estpost tabstat t_drive  t_transit  t_vehicle d2gp_bp_at17 age d_* w_hhi if m_samestate==1 & e_emp==1, s(mean sd count) c(s) 
	
esttab sum? using "./results/table_a2/census_summarystats.tex", booktabs replace cells(mean sd count)

** Table A.7 **

eststo 	gsum1: estpost tabstat real_gp_at16 real_gp_atp0 d1gp_bp_at16 d1gp_bp_atp0 d1gp_bp_at17 d1gp_bp_atp1 d2gp_bp_at17 d2gp_bp_atp1 d2gp_now_at17  [aw=perwt], s(mean sd min max) c(s) 
eststo 	gsum2: estpost tabstat real_gp_at16 real_gp_atp0 d1gp_bp_at16 d1gp_bp_atp0 d1gp_bp_at17 d1gp_bp_atp1 d2gp_bp_at17 d2gp_bp_atp1 d2gp_now_at17 if e_emp==1 [aw=perwt], s(mean sd min max) c(s) 
eststo 	gsum3: estpost tabstat real_gp_at16 real_gp_atp0 d1gp_bp_at16 d1gp_bp_atp0 d1gp_bp_at17 d1gp_bp_atp1 d2gp_bp_at17 d2gp_bp_atp1 if m_samestate==1, s(mean sd min max) c(s) 
eststo 	gsum4: estpost tabstat real_gp_at16 real_gp_atp0 d1gp_bp_at16 d1gp_bp_atp0 d1gp_bp_at17 d1gp_bp_atp1 d2gp_bp_at17 d2gp_bp_atp1 if m_samestate==1 & e_emp==1, s(mean sd min max) c(s) 
	
esttab gsum? using "./results/table_a7/census_summarystats_treatment.tex", booktabs replace cells(mean(pattern(1 1 1 1)) sd(pattern(1 1 1 1)) min(pattern(1 1 1 1)) max(pattern(1 1 1 1))) 




/* Main specifications at different ages */ 

** Tables 1 and A8 (partial, see esttab below for assignment) **

eststo tc2a_1:	reghdfe t_drive d2gp_bp_at18 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2a_2:	reghdfe t_drive d2gp_bp_at18 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2a_3:	reghdfe t_drive d2gp_now_at18 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2a_4:	reghdfe t_drive d2gp_bp_at18 d_*					if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2a_5:	reghdfe t_drive d2gp_bp_at18 d_* lhhi				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2a_6:	reghdfe t_drive d2gp_bp_at18 d_* lhhi				if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tc2a_7:	reghdfe t_drive d2gp_bp_at18 d_* lhhi c.byr##c.byr 	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

eststo tc2b_1:	reghdfe t_drive d2gp_bp_at17 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2b_2:	reghdfe t_drive d2gp_bp_at17 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2b_3:	reghdfe t_drive d2gp_now_at17 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2b_4:	reghdfe t_drive d2gp_bp_at17 d_*					if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2b_5:	reghdfe t_drive d2gp_bp_at17 d_* lhhi				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2b_6:	reghdfe t_drive d2gp_bp_at17 d_* lhhi				if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tc2b_7:	reghdfe t_drive d2gp_bp_at17 d_* lhhi c.byr##c.byr 	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

eststo tc2c_1:	reghdfe t_drive d1gp_bp_at18 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2c_2:	reghdfe t_drive d1gp_bp_at18 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2c_3:	reghdfe t_drive d1gp_now_at18 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2c_4:	reghdfe t_drive d1gp_bp_at18 d_*					if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2c_5:	reghdfe t_drive d1gp_bp_at18 d_* lhhi				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2c_6:	reghdfe t_drive d1gp_bp_at18 d_* lhhi				if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tc2c_7:	reghdfe t_drive d1gp_bp_at18 d_* lhhi c.byr##c.byr	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

eststo tc2d_1:	reghdfe t_drive d1gp_bp_at17 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2d_2:	reghdfe t_drive d1gp_bp_at17 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2d_3:	reghdfe t_drive d1gp_now_at17 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2d_4:	reghdfe t_drive d1gp_bp_at17 d_*					if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2d_5:	reghdfe t_drive d1gp_bp_at17 d_* lhhi				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2d_6:	reghdfe t_drive d1gp_bp_at17 d_* lhhi				if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tc2d_7:	reghdfe t_drive d1gp_bp_at17 d_* lhhi c.byr##c.byr	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

eststo tc2e_1:	reghdfe t_drive d1gp_bp_at16 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2e_2:	reghdfe t_drive d1gp_bp_at16 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2e_3:	reghdfe t_drive d1gp_now_at16 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2e_4:	reghdfe t_drive d1gp_bp_at16 d_*					if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2e_5:	reghdfe t_drive d1gp_bp_at16 d_* lhhi				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2e_6:	reghdfe t_drive d1gp_bp_at16 d_* lhhi				if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tc2e_7:	reghdfe t_drive d1gp_bp_at16 d_* lhhi c.byr##c.byr	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

eststo tc2f_1:	reghdfe t_drive real_gp_at16 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2f_2:	reghdfe t_drive real_gp_at16 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2f_3:	reghdfe t_drive real_now_at16 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2f_4:	reghdfe t_drive real_gp_at16 d_*					if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2f_5:	reghdfe t_drive real_gp_at16 d_* lhhi				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2f_6:	reghdfe t_drive real_gp_at16 d_* lhhi				if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tc2f_7:	reghdfe t_drive real_gp_at16 d_* lhhi c.byr##c.byr	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

local 	rnme2a "d2gp_bp_at18 d2gp18 d2gp_now_at18 d2gp18" 
local 	rnme2b "d2gp_bp_at17 d2gp17 d2gp_now_at17 d2gp17"
local 	rnme2c "d1gp_bp_at18 d1gp18 d1gp_now_at18 d1gp18" 
local 	rnme2d "d1gp_bp_at17 d1gp17 d1gp_now_at17 d1gp17"
local 	rnme2e "d1gp_bp_at16 d1gp16 d1gp_now_at16 d1gp16"   
local 	rnme2f "real_gp_at16 real16 real_now_at16 real16" 

esttab 	tc2a_* using "./results/table_a8/census_mainspecs_d2_18.tex", rename(`rnme2a') booktabs replace `tabprefs'
esttab 	tc2b_* using "./results/table1/census_mainspecs_d2_17.tex", rename(`rnme2b') booktabs replace `tabprefs'
esttab 	tc2c_* using "./results/table_a8/census_mainspecs_d1_18.tex", rename(`rnme2c') booktabs replace `tabprefs'
esttab 	tc2d_* using "./results/table_a8/census_mainspecs_d1_17.tex", rename(`rnme2d') booktabs replace `tabprefs'
esttab 	tc2e_* using "./results/table_a8/census_mainspecs_d1_16.tex", rename(`rnme2e') booktabs replace `tabprefs'
esttab 	tc2f_* using "./results/table1/census_mainspecs_lev16.tex", rename(`rnme2f') booktabs replace `tabprefs'

eststo clear

/* Main specifications at different relative driver license minimums */ 

** Tables 1 and A8 (partial, see esttab below for assignment) **

eststo tdla_1:	reghdfe t_drive d2gp_bp_atp2 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdla_2:	reghdfe t_drive d2gp_bp_atp2 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdla_3:	reghdfe t_drive d2gp_now_atp2 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdla_4:	reghdfe t_drive d2gp_bp_atp2 d_*					if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdla_5:	reghdfe t_drive d2gp_bp_atp2 d_* lhhi				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdla_6:	reghdfe t_drive d2gp_bp_atp2 d_* lhhi				if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tdla_7:	reghdfe t_drive d2gp_bp_atp2 d_* lhhi c.byr##c.byr 	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

eststo tdlb_1:	reghdfe t_drive d2gp_bp_atp1 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlb_2:	reghdfe t_drive d2gp_bp_atp1 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlb_3:	reghdfe t_drive d2gp_now_atp1 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlb_4:	reghdfe t_drive d2gp_bp_atp1 d_*					if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlb_5:	reghdfe t_drive d2gp_bp_atp1 d_* lhhi				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlb_6:	reghdfe t_drive d2gp_bp_atp1 d_* lhhi				if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tdlb_7:	reghdfe t_drive d2gp_bp_atp1 d_* lhhi c.byr##c.byr 	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

eststo tdlc_1:	reghdfe t_drive d1gp_bp_atp2 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlc_2:	reghdfe t_drive d1gp_bp_atp2 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlc_3:	reghdfe t_drive d1gp_now_atp2 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlc_4:	reghdfe t_drive d1gp_bp_atp2 d_*					if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlc_5:	reghdfe t_drive d1gp_bp_atp2 d_* lhhi				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlc_6:	reghdfe t_drive d1gp_bp_atp2 d_* lhhi				if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tdlc_7:	reghdfe t_drive d1gp_bp_atp2 d_* lhhi c.byr##c.byr	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

eststo tdld_1:	reghdfe t_drive d1gp_bp_atp1 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdld_2:	reghdfe t_drive d1gp_bp_atp1 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdld_3:	reghdfe t_drive d1gp_now_atp1 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdld_4:	reghdfe t_drive d1gp_bp_atp1 d_*					if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdld_5:	reghdfe t_drive d1gp_bp_atp1 d_* lhhi				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdld_6:	reghdfe t_drive d1gp_bp_atp1 d_* lhhi				if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tdld_7:	reghdfe t_drive d1gp_bp_atp1 d_* lhhi c.byr##c.byr	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

eststo tdle_1:	reghdfe t_drive d1gp_bp_atp0 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdle_2:	reghdfe t_drive d1gp_bp_atp0 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdle_3:	reghdfe t_drive d1gp_now_atp0 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdle_4:	reghdfe t_drive d1gp_bp_atp0 d_*					if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdle_5:	reghdfe t_drive d1gp_bp_atp0 d_* lhhi				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdle_6:	reghdfe t_drive d1gp_bp_atp0 d_* lhhi				if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tdle_7:	reghdfe t_drive d1gp_bp_atp0 d_* lhhi c.byr##c.byr	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

eststo tdlf_1:	reghdfe t_drive real_gp_atp0 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlf_2:	reghdfe t_drive real_gp_atp0 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlf_3:	reghdfe t_drive real_now_atp0 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlf_4:	reghdfe t_drive real_gp_atp0 d_*					if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlf_5:	reghdfe t_drive real_gp_atp0 d_* lhhi				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlf_6:	reghdfe t_drive real_gp_atp0 d_* lhhi				if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tdlf_7:	reghdfe t_drive real_gp_atp0 d_* lhhi c.byr##c.byr	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

local 	rnme2a "d2gp_bp_atp2 d2gpp2 d2gp_now_atp2 d2gpp2" 
local 	rnme2b "d2gp_bp_atp1 d2gpp1 d2gp_now_atp1 d2gpp1"
local 	rnme2c "d1gp_bp_atp2 d1gpp2 d1gp_now_atp2 d1gpp2" 
local 	rnme2d "d1gp_bp_atp1 d1gpp1 d1gp_now_atp1 d1gpp1"
local 	rnme2e "d1gp_bp_atp0 d1gpp0 d1gp_now_atp0 d1gpp0"   
local 	rnme2f "real_gp_atp0 realp0 real_now_atp0 realp0" 

esttab 	tdla_* using "./results/table_a8/census_mainspecs_d2_p2.tex", rename(`rnme2a') booktabs replace `tabprefs'
esttab 	tdlb_* using "./results/table1/census_mainspecs_d2_p1.tex", rename(`rnme2b') booktabs replace `tabprefs'
esttab 	tdlc_* using "./results/table_a8/census_mainspecs_d1_p2.tex", rename(`rnme2c') booktabs replace `tabprefs'
esttab 	tdld_* using "./results/table_a8/census_mainspecs_d1_p1.tex", rename(`rnme2d') booktabs replace `tabprefs'
esttab 	tdle_* using "./results/table_a8/census_mainspecs_d1_p0.tex", rename(`rnme2e') booktabs replace `tabprefs'
esttab 	tdlf_* using "./results/table1/census_mainspecs_levp0.tex", rename(`rnme2f') booktabs replace `tabprefs'

eststo clear

/* Main specifications with cohort fixed effects */ 

** Table A.10 **

eststo tcodl_a_1:	reghdfe t_drive d2gp_bp_atp2 			if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_a_2:	reghdfe t_drive d2gp_bp_atp2 d_*		if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_a_3:	reghdfe t_drive d2gp_bp_atp2 d_* lhhi	if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_a_4:	reghdfe t_drive d2gp_bp_atp2 d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe byr age) cluster(bpl)

eststo tcodl_b_1:	reghdfe t_drive d2gp_bp_atp1 			if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_b_2:	reghdfe t_drive d2gp_bp_atp1 d_*		if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_b_3:	reghdfe t_drive d2gp_bp_atp1 d_* lhhi	if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_b_4:	reghdfe t_drive d2gp_bp_atp1 d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe byr age) cluster(bpl)

eststo tcodl_c_1:	reghdfe t_drive d1gp_bp_atp2			if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_c_2:	reghdfe t_drive d1gp_bp_atp2 d_*		if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_c_3:	reghdfe t_drive d1gp_bp_atp2 d_* lhhi	if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_c_4:	reghdfe t_drive d1gp_bp_atp2 d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe byr age) cluster(bpl)

eststo tcodl_d_1:	reghdfe t_drive d1gp_bp_atp1 			if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_d_2:	reghdfe t_drive d1gp_bp_atp1 d_*		if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_d_3:	reghdfe t_drive d1gp_bp_atp1 d_* lhhi	if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_d_4:	reghdfe t_drive d1gp_bp_atp1 d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe byr age) cluster(bpl)

eststo tcodl_e_1:	reghdfe t_drive d1gp_bp_atp0 			if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_e_2:	reghdfe t_drive d1gp_bp_atp0 d_*		if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_e_3:	reghdfe t_drive d1gp_bp_atp0 d_* lhhi	if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_e_4:	reghdfe t_drive d1gp_bp_atp0 d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe byr age) cluster(bpl)

eststo tcodl_f_1:	reghdfe t_drive real_gp_atp0 			if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_f_2:	reghdfe t_drive real_gp_atp0 d_*		if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_f_3:	reghdfe t_drive real_gp_atp0 d_* lhhi	if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_f_4:	reghdfe t_drive real_gp_atp0 d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe byr age) cluster(bpl)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

esttab 	tcodl_a_* using "./results/table_a10/census_cohfespecs_d2_p2.tex", booktabs replace `tabprefs'
esttab 	tcodl_b_* using "./results/table_a10/census_cohfespecs_d2_p1.tex", booktabs replace `tabprefs'
esttab 	tcodl_c_* using "./results/table_a10/census_cohfespecs_d1_p2.tex", booktabs replace `tabprefs'
esttab 	tcodl_d_* using "./results/table_a10/census_cohfespecs_d1_p1.tex", booktabs replace `tabprefs'
esttab 	tcodl_e_* using "./results/table_a10/census_cohfespecs_d1_p0.tex", booktabs replace `tabprefs'
esttab 	tcodl_f_* using "./results/table_a10/census_cohfespecs_levp0.tex", booktabs replace `tabprefs'

eststo clear

/* Other outcomes */ 

** Table 2 (partial) **

eststo tother_b_1:	reghdfe t_transit d2gp_bp_at17 							if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tother_b_2:	reghdfe t_transit d2gp_bp_at17 c.byr##c.byr d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tother_b_3:	reghdfe t_vehicle d2gp_bp_at17 							if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tother_b_4:	reghdfe t_vehicle d2gp_bp_at17 c.byr##c.byr d_* lhhi	if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tother_b_5:	reghdfe t_vehicle d2gp_bp_at17 							if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tother_b_6:	reghdfe t_vehicle d2gp_bp_at17 c.byr##c.byr d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

eststo tother_f_1:	reghdfe t_transit real_gp_at16  						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tother_f_2:	reghdfe t_transit real_gp_at16 c.byr##c.byr d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tother_f_3:	reghdfe t_vehicle real_gp_at16 							if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tother_f_4:	reghdfe t_vehicle real_gp_at16 c.byr##c.byr d_* lhhi	if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tother_f_5:	reghdfe t_vehicle real_gp_at16 							if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tother_f_6:	reghdfe t_vehicle real_gp_at16 c.byr##c.byr d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

esttab 	tother_b_? using "./results/table2/other_d2_17.tex", booktabs replace `tabprefs'
esttab 	tother_f_? using "./results/table2/other_lev16.tex", booktabs replace `tabprefs'

eststo clear

** Table 2 (partial) **

eststo tother_b_1:	reghdfe t_transit d2gp_bp_atp1 							if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tother_b_2:	reghdfe t_transit d2gp_bp_atp1 c.byr##c.byr d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tother_b_3:	reghdfe t_vehicle d2gp_bp_atp1 							if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tother_b_4:	reghdfe t_vehicle d2gp_bp_atp1 c.byr##c.byr d_* lhhi	if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tother_b_5:	reghdfe t_vehicle d2gp_bp_atp1 							if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tother_b_6:	reghdfe t_vehicle d2gp_bp_atp1 c.byr##c.byr d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

eststo tother_f_1:	reghdfe t_transit real_gp_atp0  						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tother_f_2:	reghdfe t_transit real_gp_atp0 c.byr##c.byr d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tother_f_3:	reghdfe t_vehicle real_gp_atp0 							if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tother_f_4:	reghdfe t_vehicle real_gp_atp0 c.byr##c.byr d_* lhhi	if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tother_f_5:	reghdfe t_vehicle real_gp_atp0 							if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tother_f_6:	reghdfe t_vehicle real_gp_atp0 c.byr##c.byr d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

esttab 	tother_b_? using "./results/table2/other_d2_p1.tex", booktabs replace `tabprefs'
esttab 	tother_f_? using "./results/table2/other_levp0.tex", booktabs replace `tabprefs'

eststo clear

/* Age Heterogeneity */

** Table A.16 **

gen		d2gp_age17_2534 = (age>=25 & age<=34)*d2gp_bp_at17
gen		d2gp_age17_3544 = (age>=35 & age<=44)*d2gp_bp_at17
gen		d2gp_age17_4554 = (age>=45 & age<=54)*d2gp_bp_at17

gen		d2gp_agep1_2534 = (age>=25 & age<=34)*d2gp_bp_atp1
gen		d2gp_agep1_3544 = (age>=35 & age<=44)*d2gp_bp_atp1
gen		d2gp_agep1_4554 = (age>=45 & age<=54)*d2gp_bp_atp1

local	bin10yrs_17 d2gp_age17_2534 d2gp_age17_3544 d2gp_age17_4554

local	bin10yrs_p1 d2gp_agep1_2534 d2gp_agep1_3544 d2gp_agep1_4554

eststo tcage_1:	reghdfe t_drive `bin10yrs_17' 				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tcage_2:	reghdfe t_drive `bin10yrs_17' c.byr##c.byr d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

eststo tcage_3:	reghdfe t_drive `bin10yrs_p1' 				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tcage_4:	reghdfe t_drive `bin10yrs_p1' c.byr##c.byr d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

esttab 	tcage_? using "./results/table_a16/census_agehet_17p1.tex", booktabs replace `tabprefs'

eststo clear
drop  	d2gp_age??_????

** ** ** **
/* Robust to dropping 1979/80 Crisis */

** Table A.18 (partial) **

loc y79 "birthyr!=1965"	
loc y74 "birthyr!=1960"
loc y70s "(birthyr<1959 | birthyr>1966)"

eststo tdrop_1: reghdfe t_drive d2gp_bp_at17 						if m_samestate==1 & `y74'  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)	
eststo tdrop_2: reghdfe t_drive d2gp_bp_atp1						if m_samestate==1 & `y74'  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdrop_3: reghdfe t_drive d2gp_bp_at17 						if m_samestate==1 & `y79'  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)	
eststo tdrop_4: reghdfe t_drive d2gp_bp_atp1 						if m_samestate==1 & `y79'  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)	
eststo tdrop_5: reghdfe t_drive d2gp_bp_at17 						if m_samestate==1 & `y74' & `y79' [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdrop_6: reghdfe t_drive d2gp_bp_atp1 						if m_samestate==1 & `y74' & `y79' [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdrop_7: reghdfe t_drive d2gp_bp_at17 						if m_samestate==1 & `y70s' [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdrop_8: reghdfe t_drive d2gp_bp_atp1 						if m_samestate==1 & `y70s' [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
	
local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 
	
esttab 	tdrop_? using "./results/other/dropoilcrises.tex", booktabs replace `tabprefs'

est clear

** ** ** **
/* Other robustness */

** Table A.19 (partial) **

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
eststo mt_1: reghdfe t_drive d2gp_bp_at17 real_gp_at16 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)	
eststo mt_2: reghdfe t_drive d2gp_bp_at17 real_gp_at16 d_* lhhi c.byr##c.byr if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo mt_3: reghdfe t_drive d2gp17_national 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)	
eststo mt_4: reghdfe t_drive d2gp17_national d_* lhhi c.byr##c.byr if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo mt_5: reghdfe t_drive rgp16_national 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)	
eststo mt_6: reghdfe t_drive rgp16_national d_* lhhi c.byr##c.byr if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 
	
esttab 	mt_? using "./results/other/census_multtreatment_and_national.tex", booktabs replace `tabprefs'
est clear

** SEs

** Table A.20 **

eststo se_1: reghdfe t_drive d2gp_bp_at17 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo se_2: reghdfe t_drive d2gp_bp_at17 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(byr)	
eststo se_3: reghdfe t_drive d2gp_bp_at17 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl byr)
eststo se_4: reghdfe t_drive d2gp_bp_at17 d_* lhhi c.byr##c.byr  if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo se_5: reghdfe t_drive d2gp_bp_at17 d_* lhhi c.byr##c.byr  if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(byr)
eststo se_6: reghdfe t_drive d2gp_bp_at17 d_* lhhi c.byr##c.byr  if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl byr)

eststo se_7: reghdfe t_drive real_gp_at16 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo se_8: reghdfe t_drive real_gp_at16 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(byr)
eststo se_9: reghdfe t_drive real_gp_at16 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl byr)	
eststo se_10: reghdfe t_drive real_gp_at16 d_* lhhi c.byr##c.byr  if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo se_11: reghdfe t_drive real_gp_at16 d_* lhhi c.byr##c.byr  if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(byr)
eststo se_12: reghdfe t_drive real_gp_at16 d_* lhhi c.byr##c.byr  if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl byr)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 
	
esttab 	se_* using "./results/other/census_altSEs.tex", booktabs replace `tabprefs'
est clear

** Put numbers into context by comparing to income **
** Footnote in Section 4.1.1 **

gen 	lincw = ln(w_incw)
gen		lincp = ln(w_pinc)

reghdfe t_drive lhhi  d2gp_bp_at17 			if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
nlcom exp(_b[d2gp_bp_at17]/_b[lhhi])-1
reghdfe t_drive lincw d2gp_bp_at17				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
nlcom exp(_b[d2gp_bp_at17]/_b[lincw])-1
reghdfe t_drive lincp d2gp_bp_at17		if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
nlcom exp(_b[d2gp_bp_at17]/_b[lincp])-1

est clear
**************************************************
/* Mediation Analysis and Additional Robustness */

** Table A.9 **

rename 	bpl statefip
gen		yr_at18 = birthyr + 18
rename 	yr_at18 year

merge m:1 statefip year  using "./output/unemp_prepped.dta"
drop	if _merge==2
drop	_merge year 

rename	statefip bpl

keep d2gp_bp_at17 d2gp_bp_atp1 unemprate lhhi lincw lincp d_fem d_black d_hisp m_samestate perwt bpl censusyear_all age t_drive

local 	i = 1

foreach inc of varlist unemprate lhhi lincw lincp {
	foreach outc of varlist d2gp_bp_at17 d2gp_bp_atp1 {
		preserve
			keep t_drive `outc' `inc' d_fem d_black d_hisp m_samestate perwt bpl censusyear_all age

			* Step 1: sample selection
			reghdfe t_drive `outc' `inc' d_fem d_black d_hisp if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
			gen byte used=e(sample)
			keep if used==1
			drop 	used m_samestate

			*reghdfe t_drive `outc' d_fem d_black d_hisp [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
				*reg adjusted for sample
			
			gen 	bpl_se = bpl

			tempfile maindata
			save "`maindata'", replace

			* Step 2: renaming

			gen		smp = 0
			rename 	t_drive y

			tempfile sample0
			save "`sample0'", replace

			use "`maindata'"
			gen		smp = 1
			rename 	`inc' y
			gen		`inc'=0

			append using "`sample0'"

			foreach v of varlist `outc' d_fem d_black d_hisp {
				gen `v'_1 = `v'*smp
			}

			foreach v of varlist censusyear_all age bpl {
				egen `v'_comb = group(`v' smp)
			}

			reghdfe y `outc' `outc'_1 `inc' d_fem d_black d_hisp d_fem_1 d_black_1 d_hisp_1 [aw=perwt], a(bpl_comb censusyear_all_comb age_comb) cluster(bpl_se)

			local ndf = e(df_r)
			
			local thetaY_b_`i' = _b[`outc']
			local thetaY_se_`i' = _se[`outc']
			local thetaY_p_`i' = 2*ttail(`ndf',abs(`thetaY_b_`i''/`thetaY_se_`i''))

			local gamma_b_`i' = _b[`inc']
			local gamma_se_`i' = _se[`inc']
			local gamma_p_`i' = 2*ttail(`ndf',abs(`gamma_b_`i''/`gamma_se_`i''))
			
			local thetaM_b_`i' = _b[`outc'_1]
			local thetaM_se_`i' = _se[`outc'_1]
			local thetaM_p_`i' = 2*ttail(`ndf',abs(`thetaM_b_`i''/`thetaM_se_`i''))
			
			nlcom (ind: _b[`outc'_1] * _b[`inc']) (tot: _b[`outc'] + _b[`outc'_1] * _b[`inc']), post

			local ind_b_`i' = _b[ind]
			local ind_se_`i' = _se[ind]
			local ind_p_`i' = 2*ttail(`ndf',abs(`ind_b_`i''/`ind_se_`i''))
			
			local tot_b_`i' = _b[tot]
			local tot_se_`i' = _se[tot]
			local tot_p_`i' = 2*ttail(`ndf',abs(`tot_b_`i''/`tot_se_`i''))
			
			local vlist thetaY gamma thetaM ind tot 
			foreach v of local vlist {
				local `v'_b_`i': di %6.4f ``v'_b_`i''
				local `v'_se_`i': di %6.4f ``v'_se_`i''
				local `v'_p_`i': di %6.4f ``v'_p_`i''
			}				
		restore
		local	++i
	}	
}

local vlist thetaY gamma thetaM ind tot

texdoc init "./results/table_a9/mediation.tex", replace force
tex  & unemp & unemp & hhi & hhi & incw & incw & incp & incp  \\
tex  & 17 & p1 & 17 & p1 & 17 & p1 & 17 & p1 \\
tex \addlinespace \hline
foreach coeff of local vlist {
	tex `coeff' & ``coeff'_b_1' & ``coeff'_b_2' & ``coeff'_b_3' & ``coeff'_b_4' & ``coeff'_b_5' & ``coeff'_b_6' & ``coeff'_b_7' & ``coeff'_b_8'  \\
	tex   & (``coeff'_se_1') & (``coeff'_se_2') & (``coeff'_se_3') & (``coeff'_se_4') & (``coeff'_se_5') & (``coeff'_se_6') & (``coeff'_se_7') & (``coeff'_se_8')   \\
	tex   & [``coeff'_p_1'] & [``coeff'_p_2'] & [``coeff'_p_3'] & [``coeff'_p_4'] & [``coeff'_p_5'] & [``coeff'_p_6'] & [``coeff'_p_7'] & [``coeff'_p_8']    \\
}
texdoc close


**********************************
** Close out

capture noisily log close
clear
*/

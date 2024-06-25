* Combine and collapse fuel ratings
* Last updated: 6/4/19

** Set up ----------------------------------------------------------------------
clear
	
** Import, collapse, and append data -------------------------------------------
*** Import 2016-2017 EPA data
import 		excel using "./data/mpg/allcott_knittel/2016-7 Fuel Ratings.xlsx", firstrow clear 

***  Format relevant variables 
keep 		ModelYear Make Model MPGCombined fuelType
rename 		ModelYear Year

*** Save formatted 2016-2017 tempfile for merge
tempfile	ratings
save		`ratings'

***  Read in 1985-2015 EPA data
import 		excel using "./data/mpg/allcott_knittel/EPA Database After E85 Dupe.xlsx", firstrow clear

*** Format relevant variables
keep 		Year Make Model MPGCombined fuelType1
rename		fuelType1 fuelType 

*** Merge in 201-2017 variables
append 		using `ratings' 

** Create dummy variables and save total and collapsed data --------------------
*** Create fueltype dummy - electricity (1) and diesel (2) 
gen 		fueltype = 0 
replace		fueltype = 1 if fuelType == "Electricity"
replace		fueltype = 2 if fuelType == "Diesel" 

*** Create hybrid dummy - hybrid (1) 
gen 		hybrid = 0 
replace 	hybrid = 1 if strpos(Model, "Hybrid")

*** Save combined EPA data with hybrid and fueltype dummies 
tempfile	All_EPA_hybrid_dummy
save 		"`All_EPA_hybrid_dummy'", replace 

*** Collapse (really just to keep unique types, MPGCombined will not be used 
*** here because these are unique by named variables not coded variables
sort		Make Model Year
collapse 	(mean) MPGCombined (count) n_MPGCombined=MPGCombined, by(Year Make Model hybrid fueltype)  

*** Save tempfile to be merged later
tempfile 	merge_1
save 		`merge_1' 

** Import crosswalk file and modify year specific model codes ------------------
*** Loop over make and model codes that may change and create yearly panel data
clear
tempfile	create_years
save		`create_years', emptyok

import 		excel using "./data/mpg/prepped/crosswalk.xlsx", firstrow clear
/* fixes */
replace ModelCode="441" if MakeCode==6 & ModelCode=="442"
replace ModelCode="421" if MakeCode==20 & ModelCode=="401"
/* end */

split 		YearofChange, p("-") destring
		
forvalues v=1984/2017 {
	preserve
	gen 		Year = `v' 
	replace 	ModelCode = YearCodeChange if Year >= YearofChange1
	append		using `create_years'
	save		`create_years', replace 
	restore
}

use			`create_years', clear
keep 		Make Model MakeCode ModelCode Year 

** Prep crosswalk to merge with EPA data names ---------------------------------
merge		1:m Make Model Year using `merge_1'
destring	ModelCode, replace 

** Merge raw EPA data and collapse by MakeCode ModelCode Year
*** Format dataset, remove duplicates 
keep		Make Model MakeCode ModelCode Year hybrid fueltype
bysort 		Make Model Year hybrid fueltype: gen obsnum = _n 
keep		if obsnum == 1

*** Merge raw EPA data 
merge 		1:m Make Model Year hybrid fueltype using "`All_EPA_hybrid_dummy'" 
keep 		if _merge == 3
destring	ModelCode, replace
keep 		if ModelCode != . & MakeCode != . 

*** Save file to use in iterative merge with NHTS 
tempfile 	precollapse 
save 		`precollapse' 

** Collapse by most stringent criteria -----------------------------------------
**** Define GPM, filter, format, and save
collapse 	(mean) MPGCombined, by(Year MakeCode ModelCode hybrid fueltype) 
gen			GPMCombined = 1/MPGCombined
replace 	GPMCombined = 0 if fueltype == 1
keep		if MPGCombined != . 
keep 		MakeCode ModelCode Year GPMCombined hybrid fueltype
rename		MakeCode makecode
rename 		ModelCode modlcode 
rename		Year vehyear

tempfile 	crosswalk_first
save 		"`crosswalk_first'", replace

** Collapse by second level of criteria (year make model fueltype) -------------
**** Define GPM, filter, format, and save
use 		`precollapse', clear 
drop 		hybrid 
collapse 	(mean) MPGCombined, by(Year MakeCode ModelCode fueltype) 
gen 		GPMCombined = 1/MPGCombined
replace 	GPMCombined = 0 if fueltype == 1
keep 		if MPGCombined != . 
keep 		MakeCode ModelCode Year GPMCombined fueltype
rename		MakeCode makecode
rename 		ModelCode modlcode 
rename		Year vehyear

tempfile 	crosswalk_second
save 		"`crosswalk_second'", replace

** Collapse by third level of criteria (year make model) -----------------------
**** Define GPM, filter, format, and save
use 		`precollapse', clear 
drop 		hybrid 
drop 		fueltype
collapse 	(mean) MPGCombined, by(Year MakeCode ModelCode) 
gen 		GPMCombined = 1/MPGCombined
keep 		if MPGCombined != . 
keep 		MakeCode ModelCode Year GPMCombined
rename		MakeCode makecode
rename 		ModelCode modlcode 
rename		Year vehyear

tempfile 	crosswalk_third
save 		"`crosswalk_third'", replace

** Format and prepare NHTS data, creating fueltype and hybrid dummies ----------
use			"./output/NHTScombined_veh.dta", clear

/* fixes */
replace modlcode=441 if makecode==6 & modlcode==442
replace modlcode=421 if makecode==20 & modlcode==401
/* end */

keep 		if makecode != . & modlcode != . 
gen 		fuel_dummy = 0 
replace 	fuel_dummy = 2 if fueltype == 2 & nhtsyear == 2017 
replace 	fuel_dummy = 2 if fueltype == 1 & nhtsyear < 2017
replace 	fuel_dummy = 1 if fueltype == 3 
drop 		fueltype
rename 		fuel_dummy fueltype
destring	hybrid, replace
replace 	hybrid = 0 if hybrid != 1 

** Iterative merge -------------------------------------------------------------
*** FIRST MERGE
merge 		m:1 makecode modlcode vehyear hybrid fueltype using "`crosswalk_first'", gen(_merge_r1)
drop if 	_merge_r1==2

replace		GPMCombined = 0 if fueltype==1 & vehyear>=1984 & !mi(vehyear) & makecode <= 69
replace		_merge_r1 = 3 if _merge_r1==1 & fueltype==1 & vehyear>=1984 & !mi(vehyear) & makecode <= 69

*** Save first pass as temp file to append later 
tempfile 	first_merge_all
save 		`first_merge_all' 

keep if 	_merge_r1 == 3
tempfile 	first_merge_match
save 		`first_merge_match' 

*** Keep unmerged from master for second merge
use 		`first_merge_all' 
keep 		if _merge_r1 == 1 
merge 		m:1 makecode modlcode vehyear fueltype using "`crosswalk_second'", gen(_merge_r2) 
drop if 	_merge_r2==2

tempfile 	second_merge_all
save 		`second_merge_all' 

keep if 	_merge_r2 == 3
tempfile 	second_merge_match
save 		`second_merge_match' 

*** Third merge
use 		`second_merge_all' 
keep 		if _merge_r2 == 1 
merge 		m:1 makecode modlcode vehyear using "`crosswalk_third'", gen(_merge_r3) 
drop if		_merge_r3==2

append 		using `second_merge_match' 
append 		using `first_merge_match' 

tab 	_merge_r1
tab 	_merge_r2
tab 	_merge_r3

gen 	evermerge = 0
replace evermerge = 1 if (_merge_r1==3 | _merge_r2==3 | _merge_r3==3)

tab 	evermerge if vehyear>=1984 & vehyear<=2017 & vehyear!=. & makecode <= 69
drop	evermerge

save	"./output/NHTScombined_veh.dta", replace



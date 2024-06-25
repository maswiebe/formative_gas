** MW: single file to replace import_NHTSyyyy.do files


** MW: note that r_age and public transit variables are not used in the analysis (the census variables are used instead)

*----------------------------------------------------------------------
*** 2017
*----------------------------------------------------------------------
import delimited "$data/data/nhts/2017/perpub.csv", encoding(ISO-8859-2) clear
save "$data/data/nhts/2017/perpub.dta", replace

import delimited "$data/data/nhts/2017/vehpub.csv", encoding(ISO-8859-2) clear
merge n:1 houseid personid using "$data/data/nhts/2017/perpub.dta"
drop if _merge == 2
drop _merge
rename r_age whomain_age
keep whomain_age houseid vehid vehyear vehage make model fueltype vehtype whomain od_read hfuel vehowned vehownmo annmiles hybrid personid travday homeown hhsize hhvehcnt hhfaminc drvrcnt hhstate hhstfips numadlt wrkcount tdaydate lif_cyc msacat msasize rail urban urbansize urbrur census_d census_r cdivmsar hh_race hh_hisp hh_hisp hbhtnrnt hbppopdn hbresdn hteempdn hthtnrnt htppopdn htresdn smplsrce wthhfin
save "$data/data/nhts/2017/vehpub_new.dta", replace

import delimited "$data/data/nhts/2017/hhpub.csv", encoding(ISO-8859-2) clear
merge 1:m houseid using "$data/data/nhts/2017/perpub.dta"
* get age for household, R_RELAT == "01" means household
replace r_age = . if r_age < 0
egen yngch_2017 = min(r_age), by(houseid)

sort houseid
* usepubtr
destring usepubtr, replace force
replace usepubtr=. if usepubtr == -1
replace usepubtr=. if usepubtr == -8
replace usepubtr=. if usepubtr == -9
replace usepubtr=0 if usepubtr == 2
by houseid: egen hh_usepubtr = mean(usepubtr)
* ptused
/* Count of Public Transit Usage
-9=Not ascertained 
-8=I don't know 
-7=I prefer not to answer
Responses=0-30
https://nhts.ornl.gov/assets/2017/doc/codebook_v1.2.pdf */

* unclear definition: within last month? max=30

destring ptused, replace force
replace ptused=. if ptused == -7
replace ptused=. if ptused == -8
replace ptused=. if ptused == -9
replace ptused=. if ptused == -1
*replace ptused=. if ptused == 6
by houseid: egen hh_ptused_freq = mean(ptused)
* drop duplicate household/other members' observations in household;
*drop if r_relat != "01"
**MW: this is incorrect, r_relat is numeric
drop if r_relat != 1

drop _merge
* drop usepubtr and ptused
drop personid
drop ptused
drop usepubtr

save "$data/data/nhts/2017/HHPER2017.dta", replace


*----------------------------------------------------------------------
*** 2009
*----------------------------------------------------------------------

* missing:
* perindt2 hhcntyfp hh_msa
    * only perindt2 is used

*==============================================================================*
*                        MERGE HOUSEHOLD & PERSON FILES                        *
*==============================================================================*
clear
import delimited "$data/data/nhts/2009/Ascii/PERV2PUB.CSV", encoding(ISO-8859-2)
save "$data/data/nhts/2009/pp_dotv2.dta", replace

* 2009 restricted data
clear
import delimited "$data/data/nhts/2009/PERINDT2.csv"
save "$data/data/nhts/2009/perindt2.dta", replace


clear
import delimited "$data/data/nhts/2009/Ascii/HHV2PUB.CSV", encoding(ISO-8859-2)
*use "./data/nhts/2009/2009 restricted/hh_dotv2.dta"
merge 1:m houseid using "$data/data/nhts/2009/pp_dotv2.dta"
rename *, lower
drop _merge
sort houseid
keep numadlt drvrcnt hh_race hbhur cdivmsar hhstfips htppopdn houseid personid wrkcount hhvehcnt census_d census_r hhstate hhstfips urban msasize lif_cyc hhsize hhfaminc r_age ptused usepubtr urbrur wthhfin wtperfin
* usepubtr: Use public transit on travel day
* replace following to missing: -1:Appropriate skip, -7:Refused, -8:Don't know, -9:Not ascertained, 2: NO
* replace yes to 1 and no to 0
* destring usepubtr, replace force
    **MW: already numeric
replace usepubtr=. if usepubtr == -1 
replace usepubtr=. if usepubtr == -7 
replace usepubtr=. if usepubtr == -8
replace usepubtr=. if usepubtr == -9 
replace usepubtr=0 if usepubtr == 2 
by houseid: egen hh_usepubtr = mean(usepubtr)
* ptused: How often S used public transit in past month
* replace following to missing: -7: Refused, -8:Don't know, -9:Not ascertained, -1:Appropriate skip
* values: 0-180

* destring ptused, replace force
    **MW: already numeric
replace ptused=. if ptused == -7 
replace ptused=. if ptused == -8 
replace ptused=. if ptused == -9 
replace ptused=. if ptused == -1 
by houseid: egen HH_ptused = mean(ptused)
* drop duplicate household/other members' observations in household; drop USEPUBTR and PTUSED
sort houseid
quietly by houseid: gen dup = cond(_N==1,0,_n)
**MW: dup=0 if _N==1, dup=_n if _N!=1
    * _N is group size: number of rows for each houseid
    * if singleton household, assign dup=0; else, assign row_number within household
    * would be better to collapse to household level

replace dup=1 if dup==0
    * could have done this inside cond()
drop if dup > 1
    * drop obs in households with more than one member
    * but not sorted by personid; dropping obs randomly
    * this determines which household member is kept, hence age, hence treatment
    * is r_age used later? answer: no, gets overwritten

drop dup
drop personid
drop ptused
drop usepubtr
rename *, lower

save "$data/data/nhts/2009/HHPER2009.dta", replace

*----------------------------------------------------------------------
*** 2001
*----------------------------------------------------------------------

* missing hhcnty, but not clear if it's used

import delimited "$data/data/nhts/2001/PERPUB.csv", clear
* houseid has characters, not numeric
    * same in HHPUB
save "$data/data/nhts/2001/perpub.dta", replace

import delimited "$data/data/nhts/2001/HHPUB.csv", clear
*use "./data/nhts/2001/2001 restricted/hhv4dot.DTA"

**MW: I have the v3 version; SB use v4

merge 1:m houseid using "$data/data/nhts/2001/perpub.dta"
drop _merge
*merge 1:m houseid using "./data/nhts/2001/2001 restricted/perv4dot.DTA"
rename *,lower
keep hhintdt numadlt drvrcnt hhr_race hbhur cdivmsar hhstfips htppopdn urbrur houseid personid hhfaminc lif_cyc hhsize hhr_age wrkcount hhvehcnt hhc_msa hhstate hhstfips urban census_d census_r msasize ptused usepubtr wtperfin wthhfin
* missing: hhcnty

sort houseid
* usepubtr
* destring usepubtr, replace force
replace usepubtr=. if usepubtr == -1
replace usepubtr=. if usepubtr == -8
replace usepubtr=. if usepubtr == -9
replace usepubtr=0 if usepubtr == 2
by houseid: egen hh_usepubtr = mean(usepubtr)
* ptused
**MW: not the same definition as 2009 (which was a count); this is binned, can't take the average
    * hh_usepubtr is not used; transit variable in Table 2 is from census: censusall_prepped.dta

/* Public transit use last 2 months 
-1=Appropriate Skip
-7=Refused
-8=Don't Know
-9=Not Ascertained
1=Two or more days a week
2=About once a week 
3=Once or twice a month
4=Less than once a month
5=Never
6=Not available 
https://nhts.ornl.gov/assets/2001/doc/UsersGuide.pdf
p B-67 = p.198 in pdf
*/

*destring ptused, replace force
replace ptused=. if ptused == -7
replace ptused=. if ptused == -8
replace ptused=. if ptused == -9
replace ptused=. if ptused == -1
replace ptused=. if ptused == 6
by houseid: egen hh_ptused_freq = mean(ptused)
* drop duplicate household/other members' observations in household;
* drop usepubtr and ptused
sort houseid
quietly by houseid: gen dup = cond(_N==1,0,_n)
replace dup=1 if dup==0
drop if dup > 1
drop dup
drop personid
drop ptused
drop usepubtr
save "$data/data/nhts/2001/HHPER2001.dta",replace
*save "./data/nhts/2001/2001 restricted/HHPER2001.dta",replace

*----------------------------------------------------------------------
*** 1995
*----------------------------------------------------------------------

* save file as dta
import dbase using "$data/data/nhts/1995/PERS95_2.DBF", case(lower) clear
save "$data/data/nhts/1995/pers95.dta", replace

import dbase using "$data/data/nhts/1995/VEHICL95.DBF", case(lower) clear
save "$data/data/nhts/1995/veh95.dta", replace


import dbase using "$data/data/nhts/1995/HHOLD95.DBF", case(lower) clear


*use "$data/nhts/nhts1995/HHDOT1.dta"
*use "./data/nhts/1995/1995 restricted/HHDOT1.dta"
merge 1:m houseid using "$data/data/nhts/1995/pers95.dta"
*merge 1:m houseid using "./data/nhts/1995/1995 restricted/PERDOT.dta"
gen hhintdt = "19" + string(mstr_yr) + string(mstr_mon ,"%02.0f")
*rename *,lower
keep hhintdt numadlt drvrcnt hh_race hbhur hhstfips htppopdn wthhfin wtperfin wrkcount houseid personid hhfaminc lif_cyc hhsize ref_age wrkcount hhvehcnt hhmsa hhmsa hhstate hhstfips urban census_d census_r msasize ptused
* missing: hhcounty

sort houseid
* ptused
destring ptused, replace
replace ptused=. if ptused == 94
replace ptused=. if ptused == 98
replace ptused=. if ptused == 99
replace ptused=. if ptused == 6
replace ptused=0 if ptused == 5
sort houseid
by houseid: egen hh_ptused_freq = mean(ptused)
replace ptused=1 if ptused == 1
replace ptused=1 if ptused == 2
replace ptused=1 if ptused == 3
replace ptused=1 if ptused == 4
by houseid: egen hh_usepubtr = mean(ptused)
* drop duplicate household/other members' observations in household;
* drop ptused
sort houseid
quietly by houseid: gen dup = cond(_N==1,0,_n)
replace dup=1 if dup==0
drop if dup > 1
drop dup
drop personid
drop ptused
save "$data/data/nhts/1995/HHPER1995.dta", replace
*save "./data/nhts/1995/1995 restricted/HHPER1995.dta", replace

*----------------------------------------------------------------------
*** 1990
*----------------------------------------------------------------------

* save as dta
import delimited "$data/data/nhts/1990/Vehicle.asc", clear
save "$data/data/nhts/1990/vehicle.dta", replace

import delimited "$data/data/nhts/1990/Person.asc", clear
save "$data/data/nhts/1990/person.dta", replace


import delimited "$data/data/nhts/1990/Househld.asc", clear
*use "./data/nhts/1990/1990 restricted/HOUSEHLD.dta"
gen hhintdt = "19" + string(mstr_yr) + string(mstr_mon ,"%02.0f")
merge 1:m houseid using "$data/data/nhts/1990/person.dta"
*merge 1:m houseid using "./data/nhts/1990/1990 restricted/PERSON.dta"
sort houseid
keep hhintdt numadlt drvrcnt hh_race hhstfips wthhfin wtperfin houseid personid hhvehcnt census_d census_r hhmsa hhstate hhstfips urban msasize lif_cyc hhsize hhfaminc ref_age wrktrans popdnsty
* missing: hhcofips poppersq wrkrcnt
    * I included: popdnsty
        * seems it's not used anyway? nhts_analysis.do generates `ldens', but not used

* use wrktrans to generate the ave number of hh members use public transit
* wrktrans = main means of transportation to work 
replace wrktrans=0 if wrktrans == 01
replace wrktrans=0 if wrktrans == 08
replace wrktrans=0 if wrktrans == 09
replace wrktrans=0 if wrktrans == 10
replace wrktrans=0 if wrktrans == 11
replace wrktrans=0 if wrktrans == 94
replace wrktrans=0 if wrktrans == 98
replace wrktrans=1 if wrktrans == 02
replace wrktrans=1 if wrktrans == 04
replace wrktrans=1 if wrktrans == 05
replace wrktrans=1 if wrktrans == 07
by houseid: egen hh_usepubtr = mean(wrktrans)
* drop duplicate household/other members' observations in household;
* drop other variable
quietly by houseid: gen dup = cond(_N==1,0,_n)
replace dup=1 if dup==0
drop if dup > 1
drop dup
drop personid
drop wrktrans
save "$data/data/nhts/1990/HHPER1990.dta", replace
*save "./data/nhts/1990/1990 restricted/HHPER1990.dta", replace


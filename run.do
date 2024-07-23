* set path: uncomment the following line and set the filepath for the folder containing this run.do file
*global root_mw "[location of replication archive]"
global data_mw "$root_mw/data"
global code_mw "$root_mw/code"
global tables "$root_mw/output/tables"
global figures "$root_mw/output/figures"
global sb_data "$data_mw/sb_files"


* from SB's master.do
global 	data	"$sb_data"
global 	dof 	"$data/codelog" 
cd "$data"

* Stata version control
version 15

do "$code_mw/_config.do"

* clean NHTS data
do "$code_mw/clean_nhts_mw.do"
do "$code_mw/combine_nhts_mw.do"
do "$code_mw/combine_gpm.do"

* reanalysis code
* tables 1 and 2
do "$code_mw/censusALL_analysis_mw.do"

* table 3
do "$code_mw/nhts_analysis_mw.do"

* table 4
do "$code_mw/nhts_analysis_agecompare_event_mw.do"
do "$code_mw/censusALL_analysis_agecompare_event_mw.do"
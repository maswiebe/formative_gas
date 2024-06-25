This repository contains Stata .do files for my [comment](https://michaelwiebe.com/assets/formative_gas/formative_gas.pdf) on "[Formative Experiences and the Price of Gasoline](https://www.aeaweb.org/articles?id=10.1257/app.20200407)", Severen and van Benthem (2022).

To combine my code with the data, first download this repository, then download the original [replication package](https://www.openicpsr.org/openicpsr/project/127261/version/V1/view) and extract the files to the directory 'data/sb_files/'.
This requires signing up for an ICPSR account.
To obtain the NHTS data, [download](https://nhts.ornl.gov/downloads) the CSV files for 2017, 2009, 2001, and 1990; download the DBase file for 1995; save these to 'data/sb_files/data/nhts/yyyy/' for each year 'yyyy'.
You need to create the directories for 'nhts/yyyy/'.
Download the [updated model codes](https://nhts.ornl.gov/assets/2001/download/VEHV4_R2.zip) for 2001.
You need to [request](https://nhts.ornl.gov/contact-us) the interview date variable 'perindt2' from the restricted 2009 data. 
This involves submitting a research proposal to Data User Support.

To rerun the analyses, run the file `run.do` using Stata (version 15). 
Note that you need to set the path in `run.do` on line 2, to define the location of the folder that contains this README.
Required Stata packages are included in 'code/libraries/stata/', so that the user does not have to download anything and the replication can be run offline.
The file `code/_config.do` tells Stata to load packages from this location.

Figures and tables are saved in 'output/'; that directory is created by `code/_config.do`.
It takes approximately 20-30 hours to run the code using Stata-SE. 
It helps to close web browsers to free up memory.
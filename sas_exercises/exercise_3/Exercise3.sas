/**********************************************************************************

PROGRAM:      C:\MEPS\SAS\PROG\EXERCISE6.SAS

DESCRIPTION:  THIS PROGRAM ILLUSTRATES HOW TO POOL MEPS DATA FILES FROM DIFFERENT YEARS
              THE EXAMPLE USED IS POPULATION AGE 26-30 WHO ARE UNINSURED BUT HAVE HIGH INCOME

	         DATA FROM 2015 AND 2016 ARE POOLED.

              VARIABLES WITH YEAR-SPECIFIC NAMES MUST BE RENAMED BEFORE COMBINING FILES.  
              IN THIS PROGRAM THE INSURANCE COVERAGE VARIABLES 'INSCOV15' AND 'INSCOV16' ARE RENAMED TO 'INSCOV'.

	         SEE HC-036 (1996-2015 POOLED ESTIMATION FILE) FOR
              INSTRUCTIONS ON POOOLING AND CONSIDERATIONS FOR VARIANCE
	         ESTIMATION FOR PRE-2002 DATA.

INPUT FILE:   (1) C:\MEPS\SAS\DATA\H192.SAS7BDAT (2016 FULL-YEAR FILE)
	          (2) C:\MEPS\SAS\DATA\H181.SAS7BDAT (2015 FULL-YEAR FILE)

*********************************************************************************/;

ods graphics off;

*LIBNAME CDATA 'C:\MEPS\SAS\DATA';
*LIBNAME CDATA "\\programs.ahrq.local\programs\MEPS\AHRQ4_CY2\B_CFACT\BJ001DVK\Workshop_2018_Fall\SAS\DATA";

OPTIONS NODATE;
TITLE1 '2018 AHRQ MEPS DATA USERS WORKSHOP';
TITLE2 'EXERCISE6.SAS: POOL MEPS DATA FILES FROM DIFFERENT YEARS (2015 and 2016)';

/* LOAD SAS TRANSPORT FILES (.ssp) */
FILENAME in_h181 'C:\MEPS\h181.ssp';
proc xcopy in = in_h181 out = WORK IMPORT;
run;

FILENAME in_h192 'C:\MEPS\h192.ssp';
proc xcopy in = in_h192 out = WORK IMPORT;
run;

/* CREATE FORMATS */
PROC FORMAT;
	VALUE POVCAT 
    1 = '1 POOR/NEGATIVE'
    2 = '2 NEAR POOR'
    3 = '3 LOW INCOME'
    4 = '4 MIDDLE INCOME'
    5 = '5 HIGH INCOME'
    ;

	VALUE INSF
	1 = '1 ANY PRIVATE'
	2 = '2 PUBLIC ONLY'
	3 = '3 UNINSURED';

    VALUE AGE
    26-30='26-30'
    0-25='0-25'
    31-HIGH='31+';
run;

/* FREQUENCY OF 2015 */
DATA YR1;
	SET h181 (KEEP= DUPERSID INSCOV15 PERWT15F VARSTR VARPSU POVCAT15 AGELAST TOTSLF15);
     IF PERWT15F>0;
RUN;

TITLE3 'UNWEIGHTED FREQUENCY FOR 2015 FY PERSONS WITH AGE 26-30';
PROC FREQ DATA= YR1 (WHERE=(26 LE AGELAST LE 30));
	TABLES POVCAT15*INSCOV15/ LIST MISSING ;
	FORMAT INSCOV15 INSF.  POVCAT15 POVCAT.;
RUN;

/* FREQUENCY OF 2016*/
DATA YR2;
	SET h192 (KEEP= DUPERSID INSCOV16 PERWT16F VARSTR VARPSU POVCAT16 AGELAST TOTSLF16);
     IF PERWT16F>0;
run;

TITLE3 'UNWEIGHTED FREQUENCY FOR 2016 FY PERSONS WITH AGE 26-30';
PROC FREQ DATA= YR2 (WHERE=(26 LE AGELAST LE 30));
	TABLES POVCAT16*INSCOV16/ LIST MISSING ;
	FORMAT INSCOV16 INSF.  POVCAT16 POVCAT.;
RUN;


/* RENAME YEAR SPECIFIC VARIABLES PRIOR TO COMBINING FILES */
DATA YR1X;
	SET YR1 (RENAME=(INSCOV15=INSCOV PERWT15F=PERWT POVCAT15=POVCAT TOTSLF15=TOTSLF));
RUN;

DATA YR2X;
	SET YR2 (RENAME=(INSCOV16=INSCOV PERWT16F=PERWT POVCAT16=POVCAT TOTSLF16=TOTSLF));
RUN;

DATA POOL;
     LENGTH INSCOV AGELAST POVCAT VARSTR VARPSU 8;
	SET YR1X YR2X;
     POOLWT = PERWT/2 ;
   
     IF 26 LE AGELAST LE 30 AND POVCAT=5 AND INSCOV=3 THEN SUBPOP=1;
     ELSE SUBPOP=2;

     LABEL SUBPOP='POPULATION WITH AGE=26-30, UNINSURED WHOLE YEAR, AND HIGH INCOME'
           TOTSLF='TOTAL AMT PAID BY SELF/FAMILY';
RUN;

TITLE3 "CHECK MISSING VALUES ON THE COMBINED DATA";
PROC MEANS DATA=POOL N NMISS;
RUN;

TITLE3 'SUPPORTING CROSSTAB FOR THE CREATION OF THE SUBPOP FLAG';
PROC FREQ DATA=POOL;
	TABLES SUBPOP SUBPOP*AGELAST*POVCAT*INSCOV/ LIST MISSING ;
	FORMAT  AGELAST AGE. ;
RUN;

TITLE3 'WEIGHTED ESTIMATE ON TOTSLF FOR COMBINED DATA W/AGE=26-30, UNINSURED WHOLE YEAR, AND HIGH INCOME';
PROC SURVEYMEANS DATA=POOL NOBS MEAN STDERR;
	STRATUM VARSTR ;
	CLUSTER VARPSU ;
	WEIGHT  POOLWT;
	DOMAIN  SUBPOP;
	VAR  TOTSLF;
RUN;
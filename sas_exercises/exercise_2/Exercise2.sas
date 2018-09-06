/*********************************************************************\

PROGRAM: 	C:\MEPS\SAS\PROG\EXERCISE2.SAS

PURPOSE:	THIS PROGRAM GENERATES SELECTED ESTIMATES FOR A 2016 VERSION OF THE Purchases and Expenses for Narcotic analgesics or Narcotic analgesic combos


    (1) FIGURE 1: TOTAL EXPENSE FOR Narcotic analgesics or Narcotic analgesic combos

    (2) FIGURE 2: TOTAL NUMBER OF PURCHASES OF Narcotic analgesics or Narcotic analgesic combos

    (3) FIGURE 3: TOTAL NUMBER OF PERSONS PURCHASING ONE OR MORE Narcotic analgesics or Narcotic analgesic combos

    (4) FIGURE 4: AVERAGE TOTAL, OUT OF POCKET, AND THIRD PARTY PAYER EXPENSE
                  FOR Narcotic analgesics or Narcotic analgesic combos PER PERSON WITH AN Narcotic analgesics or Narcotic analgesic combos MEDICINE PURCHASE

INPUT FILES:  (1) C:\MEPS\SAS\DATA\H192.SAS7BDAT (2016 FULL-YEAR CONSOLIDATED PUF)
              (2) C:\MEPS\SAS\DATA\H188A.SAS7BDAT (2016 PRESCRIBED MEDICINES PUF)

\*********************************************************************/

OPTIONS LS=132 PS=79 NODATE;
ods graphics off;

*LIBNAME CDATA 'C:\MEPS\SAS\DATA';
*LIBNAME CDATA "\\programs.ahrq.local\programs\meps\AHRQ4_CY2\B_CFACT\BJ001DVK\Workshop_2018_Fall\SAS\Data";

TITLE1 '2018 AHRQ MEPS DATA USERS WORKSHOP';
TITLE2 "EXERCISE2.SAS: Narcotic analgesics or Narcotic analgesic combos, 2016";

/* LOAD SAS TRANSPORT FILES (.ssp) */
FILENAME in_h188a 'C:\MEPS\h188a.ssp';
proc xcopy in = in_h188a out = WORK IMPORT;
run;

FILENAME in_h192 'C:\MEPS\h192.ssp';
proc xcopy in = in_h192 out = WORK IMPORT;
run;

/* CREATE FORMATS */
PROC FORMAT;
  VALUE GTZERO
     0         = '0'
     0 <- HIGH = '>0'
     ;
RUN;

/*1) IDENTIFY Narcotic analgesics or Narcotic analgesic combos USING THERAPEUTIC CLASSIFICATION (TC) CODES*/
DATA DRUG;
  SET h188a;
  IF TC1S1_1 IN (60, 191) ; /*definition of Narcotic analgesics or Narcotic analgesic combos*/
RUN;

TITLE3 "A SAMPLE DUMP FOR PMED RECORDS WITH Narcotic analgesics or Narcotic analgesic combos";
PROC PRINT DATA=DRUG (OBS=30);
VAR RXRECIDX LINKIDX TC1S1_1 	RXXP16X RXSF16X;
 BY DUPERSID;
RUN;


/*2) SUM DATA TO PERSON-LEVEL*/

PROC SUMMARY DATA=DRUG NWAY;
  CLASS DUPERSID;
  VAR RXXP16X RXSF16X;
  OUTPUT OUT=PERDRUG (DROP=_TYPE_) sum=TOT OOP;
RUN;

TITLE3 "A SAMPLE DUMP FOR PERSON-LEVEL EXPENDITURES FOR Narcotic analgesics or Narcotic analgesic combos";
PROC PRINT DATA=PERDRUG (OBS=30);
RUN;

DATA PERDRUG2;
 SET PERDRUG;
     RENAME _FREQ_ = N_PHRCHASE ;
     THIRD_PAYER   = TOT - OOP;
RUN;

/*3) MERGE THE PERSON-LEVEL EXPENDITURES TO THE FY PUF*/
DATA  FY;
MERGE h192 (IN=AA KEEP=DUPERSID VARSTR VARPSU PERWT16F) 
      PERDRUG2  (IN=BB KEEP=DUPERSID N_PHRCHASE TOT OOP THIRD_PAYER);
   BY DUPERSID;

      IF AA AND BB THEN DO;
         SUB      = 1 ;
      END;

      ELSE IF NOT BB THEN DO;   /*FOR PERSONS WITHOUT ANY PURCHASE OF Narcotic analgesics or Narcotic analgesic combos*/
         SUB         = 2 ;
         N_PHRCHASE  = 0 ;
         THIRD_PAYER = 0 ;
         TOT         = 0 ;
         OOP         = 0 ;
      END;

      IF AA;

      LABEL 
            THIRD_PAYER = 'TOTAL-OOP'
            N_PHRCHASE  = '# OF PURCHASES PER PERSON'
            SUB         = 'POPULATION FLAG FOR PERSONS WITH 1+ Narcotic analgesics or Narcotic analgesic combos'
                        ;
RUN;

TITLE3 "SUPPORTING CROSSTABS FOR NEW VARIABLES";
PROC FREQ DATA=FY;
  TABLES  SUB * N_PHRCHASE * TOT * OOP * THIRD_PAYER / LIST MISSING ;
  FORMAT N_PHRCHASE TOT OOP THIRD_PAYER gtzero. ;
RUN;


/*4) CALCULATE ESTIMATES ON EXPENDITURES AND USE*/

ODS LISTING CLOSE;
TITLE3 "PERSON-LEVEL ESTIMATES ON EXPENDITURES AND USE FOR Narcotic analgesics or Narcotic analgesic combos, 2016";
PROC SURVEYMEANS DATA=FY NOBS SUMWGT SUM STD MEAN STDERR;
  STRATA  VARSTR ;
  CLUSTER VARPSU;
  WEIGHT  PERWT16F;
  DOMAIN  SUB('1') ;
  VAR TOT N_PHRCHASE  OOP THIRD_PAYER ;
  ODS OUTPUT DOMAIN=OUT1;
RUN;
ODS LISTING;

TITLE3 "RESULTS FROM PROC SURVEYMEANS WITH A DOMAIN STATEMENT";
PROC PRINT DATA=OUT1 (DROP=DOMAINLABEL) NOOBS;
FORMAT N COMMA6.0 SUMWGT SUM  STDDEV comma15.0 MEAN STDERR comma9.2  ;
RUN;

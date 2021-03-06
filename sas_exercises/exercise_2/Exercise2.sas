/*********************************************************************

PROGRAM: 	EXERCISE2.SAS

PURPOSE:	THIS PROGRAM GENERATES SELECTED ESTIMATES FOR A 2018 VERSION OF THE Purchases and Expenses for Narcotic analgesics or Narcotic analgesic combos


    (1) FIGURE 1: TOTAL EXPENSE FOR Narcotic analgesics or Narcotic analgesic combos

    (2) FIGURE 2: TOTAL NUMBER OF PURCHASES OF Narcotic analgesics or Narcotic analgesic combos

    (3) FIGURE 3: TOTAL NUMBER OF PERSONS PURCHASING ONE OR MORE Narcotic analgesics or Narcotic analgesic combos

    (4) FIGURE 4: AVERAGE TOTAL, OUT OF POCKET, AND THIRD PARTY PAYER EXPENSE
                  FOR Narcotic analgesics or Narcotic analgesic combos PER PERSON WITH AN Narcotic analgesics or Narcotic analgesic combos MEDICINE PURCHASE

INPUT FILES:  (1) C:\DATA\MySDS\H209.SAS7BDAT (2018 FULL-YEAR CONSOLIDATED PUF)
              (2) C:\DATA\MySDS\H206A.SAS7BDAT (2018 PRESCRIBED MEDICINES PUF)

************************************************************************************/

proc datasets lib=work nolist kill; quit; /* Delete  all files in the WORK library */
OPTIONS LS=132 PS=79 NODATE FORMCHAR="|----|+|---+=|-/\<>*" PAGENO=1;
%LET DataFolder = C:\DATA\MySDS;  /* Adjust the folder name, if needed */

/*********************************************************************************
    IMPORTANT NOTE:  Use the next 5 lines of code, only if you want SAS to create 
    separate files for SAS log and output.  Otherwise comment  out these lines.
***********************************************************************************/

%LET RootFolder= C:\Fall2020\sas_exercises\Exercise_2;
FILENAME MYLOG "&RootFolder\Exercise2_log.TXT";
FILENAME MYPRINT "&RootFolder\Exercise2_OUTPUT.TXT";
PROC PRINTTO LOG=MYLOG PRINT=MYPRINT NEW;
RUN;


PROC FORMAT;
  VALUE GTZERO
     0         = '0'
     0 <- HIGH = '>0' ;
  VALUE SUBPOP    
          1 = 'PERSONS WITH 1+ Narcotic etc'
		  2 = 'OTHERS';
RUN;

/* KEEP THE SPECIFIED VARIABLES WHEN READING THE INPUT DATA SET AND
   RESTRICT TO OBSERVATIONS HAVING THERAPEUTIC CLASSIFICATION (TC) CODES
   FOR Narcotic analgesics or Narcotic analgesic combos 
*/

libname CDATA "&DataFolder"; 

DATA WORK.DRUG;
  SET CDATA.H206A (KEEP=DUPERSID RXRECIDX LINKIDX TC1S1_1 RXXP18X RXSF18X
                   WHERE=(TC1S1_1 IN (60, 191))); 
RUN;

ODS HTML CLOSE; /* This will make the default HTML output no longer active,
                  and the output will not be displayed in the Results Viewer.*/
TITLE "A SAMPLE DUMP FOR PMED RECORDS WITH Narcotic analgesics or Narcotic analgesic combos, 2098";
PROC PRINT DATA=WORK.DRUG (OBS=30);
VAR RXRECIDX LINKIDX TC1S1_1 RXXP18X RXSF18X;
 BY DUPERSID;
RUN;


/* SUM "RXXP18X and RXSF18X" DATA TO PERSON-LEVEL*/

PROC SUMMARY DATA=WORK.DRUG NWAY;
  CLASS DUPERSID;
  VAR RXXP18X RXSF18X;
  OUTPUT OUT=WORK.PERDRUG (DROP=_TYPE_) sum=TOT OOP;
RUN;

TITLE "A SAMPLE DUMP FOR PERSON-LEVEL EXPENDITURES FOR Narcotic analgesics or Narcotic analgesic combos";
PROC PRINT DATA=PERDRUG (OBS=30);
RUN;

DATA WORK.PERDRUG2;
 SET PERDRUG  (RENAME=(_FREQ_ = N_PHRCHASE)) ; /*# OF PURCHASES PER PERSON */
 /* CREATE A NEW VARIABLE FOR EXPENSES EXCLUDING OUT-OF-POCKET EXPENSES */
 THIRD_PAYER   = TOT - OOP; 
 RUN;
PROC SORT DATA=WORK.PERDRUG2; BY DUPERSID; RUN;

/*SORT THE FULL-YEAR(FY) CONSOLIDATED FILE*/
PROC SORT DATA=CDATA.H209 (KEEP=DUPERSID VARSTR VARPSU PERWT18f) OUT=WORK.H209;
BY DUPERSID; RUN;

/*MERGE THE PERSON-LEVEL EXPENDITURES TO THE FY PUF*/
DATA  WORK.FY;
MERGE WORK.H209 (IN=AA) 
      WORK.PERDRUG2  (IN=BB KEEP=DUPERSID N_PHRCHASE TOT OOP THIRD_PAYER);
   BY DUPERSID;
   IF AA AND BB THEN SUBPOP = 1; /*PERSONS WITH 1+ Narcotic analgesics or Narcotic analgesic combos */
   ELSE IF AA NE BB THEN DO;   
         SUBPOP         = 2 ;  /*PERSONS WITHOUT ANY PURCHASE OF Narcotic analgesics or Narcotic analgesic combos*/
         N_PHRCHASE  = 0 ;  /*# OF PURCHASES PER PERSON */
         THIRD_PAYER = 0 ;
         TOT         = 0 ;
         OOP         = 0 ;
    END;
    IF AA; 
	LABEL   TOT = 'TOTAL EXPENSES FOR NACROTIC ETC'
	        OOP = 'OUT-OF-POCKET EXPENSES'
            THIRD_PAYER = 'TOTAL EXPENSES MINUS OUT-OF-POCKET EXPENSES'
            N_PHRCHASE  = '# OF PURCHASES PER PERSON';
RUN;
/*DELETE ALL THE DATA SETS IN THE LIBRARY WORK and STOPS the DATASETS PROCEDURE*/
PROC DATASETS LIBRARY=WORK; 
 DELETE DRUG PERDRUG2 H209; 
RUN;
QUIT;
TITLE;

/* QC purposes */
/*
PROC FREQ DATA=WORK.FY;
  TABLES  SUBPOP * N_PHRCHASE * TOT * OOP * THIRD_PAYER / LIST MISSING ;
  FORMAT SUBPOP SUBPOP. N_PHRCHASE TOT OOP THIRD_PAYER gtzero. ;
RUN;
*/

/* CALCULATE ESTIMATES ON USE AND EXPENDITURES*/
ods graphics off; /*Suppress the graphics */
ods listing; /* Open the listing destination*/
ods exclude Statistics /* Not to generate output for the overall population */
TITLE "PERSON-LEVEL ESTIMATES ON EXPENDITURES AND USE FOR NARCOTIC ANALGESICS or NARCOTIC COMBOS, 2098";
/* When you request SUM in PROC SURVEYMEANS, the procedure computes STD by default.*/
PROC SURVEYMEANS DATA=WORK.FY NOBS SUMWGT SUM MEAN STDERR SUM;
  VAR TOT N_PHRCHASE  OOP THIRD_PAYER ;
  STRATA  VARSTR ;
  CLUSTER VARPSU;
  WEIGHT  PERWT18f;
  DOMAIN  SUBPOP("PERSONS WITH 1+ Narcotic etc");
  FORMAT SUBPOP SUBPOP.;
 RUN;

/* THE PROC PRINTTO null step is required to close the PROC PRINTTO, 
 only if used earlier., Otherswise. please comment out the next two lines  */
PROC PRINTTO;
RUN;

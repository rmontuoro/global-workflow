      SUBROUTINE GETGB1(LUGB,LUGI,JF,J,JPDS,JGDS,
     &                       GRIB,KF,K,KPDS,KGDS,LB,F,IRET)
C$$$  SUBPROGRAM DOCUMENTATION BLOCK
C
C SUBPROGRAM: GETGB1         FINDS AND UNPACKS A GRIB MESSAGE
C   PRGMMR: IREDELL          ORG: W/NMC23     DATE: 94-04-01
C
C ABSTRACT: FIND AND UNPACK A GRIB MESSAGE.
C   READ AN ASSOCIATED GRIB INDEX FILE (UNLESS IT ALREADY WAS READ).
C   FIND IN THE INDEX FILE A REFERENCE TO THE GRIB MESSAGE REQUESTED.
C   THE GRIB MESSAGE REQUEST SPECIFIES THE NUMBER OF MESSAGES TO SKIP
C   AND THE UNPACKED PDS AND GDS PARAMETERS.  (A REQUESTED PARAMETER
C   OF -1 MEANS TO ALLOW ANY VALUE OF THIS PARAMETER TO BE FOUND.)
C   IF THE REQUESTED GRIB MESSAGE IS FOUND, THEN IT IS READ FROM THE
C   GRIB FILE AND UNPACKED.  ITS MESSAGE NUMBER IS RETURNED ALONG WITH
C   THE UNPACKED PDS AND GDS PARAMETERS, THE UNPACKED BITMAP (IF ANY),
C   AND THE UNPACKED DATA.  IF THE GRIB MESSAGE IS NOT FOUND, THEN THE
C   RETURN CODE WILL BE NONZERO.
C
C PROGRAM HISTORY LOG:
C   94-04-01  IREDELL
C   95-05-10  R.E.JONES  ADD ONE MORE PARAMETER TO GETGB AND
C                        CHANGE NAME TO GETGB1 
C
C USAGE:    CALL GETGB1(LUGB,LUGI,JF,J,JPDS,JGDS,
C    &                       GRIB,KF,K,KPDS,KGDS,LB,F,IRET)
C   INPUT ARGUMENTS:
C     LUGB         LOGICAL UNIT OF THE UNBLOCKED GRIB DATA FILE
C     LUGI         LOGICAL UNIT OF THE UNBLOCKED GRIB INDEX FILE
C     JF           INTEGER MAXIMUM NUMBER OF DATA POINTS TO UNPACK
C     J            INTEGER NUMBER OF MESSAGES TO SKIP
C                  (=0 TO SEARCH FROM BEGINNING)
C                  (<0 TO REOPEN INDEX FILE AND SEARCH FROM BEGINNING)
C     JPDS         INTEGER (25) PDS PARAMETERS FOR WHICH TO SEARCH
C                  (=-1 FOR WILDCARD)
C                  LOOK IN DOC BLOCK OF W3FI63 FOR ARRAY KPDS 
C                  FOR LIST OF ORDER OF UNPACKED PDS VALUES. IN
C                  MOST CASES YOU ONLY NEED TO SET 4 OR 5 VALUES
C                  TO PICK UP RECORD.
C     JGDS         INTEGER (22) GDS PARAMETERS FOR WHICH TO SEARCH
C                  (ONLY SEARCHED IF JPDS(3)=255)
C                  (=-1 FOR WILDCARD)
C   OUTPUT ARGUMENTS:
C     GRIB         GRIB DATA ARRAY BEFORE IT IS UNPACKED
C     KF           INTEGER NUMBER OF DATA POINTS UNPACKED
C     K            INTEGER MESSAGE NUMBER UNPACKED
C                  (CAN BE SAME AS J IN CALLING PROGRAM
C                  IN ORDER TO FACILITATE MULTIPLE SEARCHES)
C     KPDS         INTEGER (25) UNPACKED PDS PARAMETERS
C     KGDS         INTEGER (22) UNPACKED GDS PARAMETERS
C     LB           LOGICAL (KF) UNPACKED BITMAP IF PRESENT
C     F            REAL (KF) UNPACKED DATA
C     IRET         INTEGER RETURN CODE
C                    0      ALL OK
C                    96     ERROR READING INDEX FILE
C                    97     ERROR READING GRIB FILE
C                    98     NUMBER OF DATA POINTS GREATER THAN JF
C                    99     REQUEST NOT FOUND
C                    OTHER  W3FI63 GRIB UNPACKER RETURN CODE
C   
C SUBPROGRAMS CALLED:
C   BAREAD         BYTE-ADDRESSABLE READ
C   GBYTE          UNPACK BYTES
C   FI632          UNPACK PDS
C   FI633          UNPACK GDS
C   W3FI63         UNPACK GRIB
C
C ATTRIBUTES:
C   LANGUAGE: CRAY CFT77 FORTRAN
C   MACHINE:  CRAY C916/256, J916/2048
C
C$$$
C
      PARAMETER (MBUF=8192*128)
      PARAMETER (LPDS=23,LGDS=22)
C
      INTEGER      JPDS(25),JGDS(*),KPDS(25),KGDS(*)
      INTEGER      IPDSP(LPDS),JPDSP(LPDS),IGDSP(LGDS)
      INTEGER      JGDSP(LGDS)
      INTEGER      KPTR(20)
C
      LOGICAL      LB(*)
C
      REAL         F(*)
C
      CHARACTER    CBUF(MBUF)
      CHARACTER*81 CHEAD(2)
      CHARACTER*1  CPDS(28)
      CHARACTER*1  CGDS(42)
      CHARACTER*1  GRIB(*)
      INTEGER IBUF(60)
      EQUIVALENCE (IBUF(1), CBUF(1))
C
C     SAVE LUX,NSKP,NLEN,NNUM,CBUF
      SAVE
C
      DATA LUX/0/
      print *, LUGB,LUGI,JF,J,JPDS,
     &                       KF,K,KPDS,IRET
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
C  READ INDEX FILE
      IF(J.LT.0.OR.LUGI.NE.LUX) THEN
C        REWIND LUGI
C        READ(LUGI,fmt='(2A81)',IOSTAT=IOS) CHEAD
        CALL BAREAD(LUGI,0,162,ios,chead)
        IF(IOS.EQ.162.AND.CHEAD(1)(42:47).EQ.'GB1IX1') THEN
          LUX=0
          READ(CHEAD(2),'(8X,3I10,2X,A40)',IOSTAT=IOS) NSKP,NLEN,NNUM
          IF(IOS.EQ.0) THEN
            NBUF=NNUM*NLEN
            IF(NBUF.GT.MBUF) THEN
              PRINT *,'GETGB1: INCREASE BUFFER FROM ',MBUF,' TO ',NBUF
              NNUM=MBUF/NLEN
              NBUF=NNUM*NLEN
            ENDIF
            CALL BAREAD(LUGI,NSKP,NBUF,LBUF,CBUF)
C            call byteswap(CBUF, 8, LBUF/8)    
            IF(LBUF.EQ.NBUF) THEN
              LUX=LUGI
              J=MAX(J,0)
            ENDIF
          ENDIF
        ENDIF
      ENDIF
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
C  SEARCH FOR REQUEST
      LGRIB=0
      KJ=J
      K=J
      KF=0
      IF(J.GE.0.AND.LUGI.EQ.LUX) THEN
        LPDSP=0
        DO I=1,LPDS
          IF(JPDS(I).NE.-1) THEN
            LPDSP=LPDSP+1
            IPDSP(LPDSP)=I
            JPDSP(LPDSP)=JPDS(I)
          ENDIF
        ENDDO
        LGDSP=0
        IF(JPDS(3).EQ.255) THEN
          DO I=1,LGDS
            IF(JGDS(I).NE.-1) THEN
              LGDSP=LGDSP+1
              IGDSP(LGDSP)=I
              JGDSP(LGDSP)=JGDS(I)
            ENDIF
          ENDDO
        ENDIF
        IRET=99
        DOWHILE(LGRIB.EQ.0.AND.KJ.LT.NNUM)
          KJ=KJ+1
          LT=0
          IF(LPDSP.GT.0) THEN
            CPDS=CBUF((KJ-1)*NLEN+26:(KJ-1)*NLEN+53)
            KPTR=0
            call byteswap(CBUF, 8, LBUF/8) 
            CALL GBYTE(CBUF,KPTR(3),(KJ-1)*NLEN*8+25*8,3*8)
            call byteswap(CBUF, 8,  LBUF/8)
c            print *, KPTR, KJ, LGRIB, NNUM, LT, LPDSP
c            print *, CPDS
            CALL FI632(CPDS,KPTR,KPDS,IRET)
            DO I=1,LPDSP
              IP=IPDSP(I)
              LT=LT+ABS(JPDS(IP)-KPDS(IP))
            ENDDO
          ENDIF
          IF(LT.EQ.0.AND.LGDSP.GT.0) THEN
            CGDS=CBUF((KJ-1)*NLEN+54:(KJ-1)*NLEN+95)
            KPTR=0
            CALL FI633(CGDS,KPTR,KGDS,IRET)
            DO I=1,LGDSP
              IP=IGDSP(I)
              LT=LT+ABS(JGDS(IP)-KGDS(IP))
              print *, i, ip, JGDS(IP), KGDS(IP), LT
            ENDDO
          ENDIF
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
C  READ AND UNPACK GRIB DATA
          IF(LT.EQ.0) THEN
            call byteswap(CBUF, 8, LBUF/8)
            CALL GBYTE(CBUF,LSKIP,(KJ-1)*NLEN*8,4*8)
            CALL GBYTE(CBUF,LGRIB,(KJ-1)*NLEN*8+20*8,4*8)
            call byteswap(CBUF, 8, LBUF/8)
c            call byteswap(LSKIP, 8, 1)
c            call byteswap(LGRIB, 8, 1)
            CGDS=CBUF((KJ-1)*NLEN+54:(KJ-1)*NLEN+95)
            KPTR=0
            print *, CGDS, LSKIP, LGRIB
            CALL FI633(CGDS,KPTR,KGDS,IRET)
C  BSM      IF(LGRIB.LE.200+17*JF/8.AND.KGDS(2)*KGDS(3).LE.JF) THEN
C  Change number of bits that can be handled to 25
            IF(LGRIB.LE.200+25*JF/8.AND.KGDS(2)*KGDS(3).LE.JF) THEN
              CALL BAREAD(LUGB,LSKIP,LGRIB,LREAD,GRIB)
              IF(LREAD.EQ.LGRIB) THEN
                CALL W3FI63(GRIB,KPDS,KGDS,LB,F,KPTR,IRET)
                IF(IRET.EQ.0) THEN
                  K=KJ
                  KF=KPTR(10)
                ENDIF
              ELSE
                IRET=97
              ENDIF
            ELSE
              IRET=98
            ENDIF
          ENDIF
        ENDDO
      ELSE
        IRET=96
      ENDIF
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      RETURN
      END

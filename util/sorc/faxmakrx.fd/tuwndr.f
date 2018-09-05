      SUBROUTINE TUWNDR(GU,GV,IDIR,ISPEED,ANG,VRTLON,ALON,ITRUDR,KEY)
C$$$  SUBPROGRAM DOCUMENTATION BLOCK
C
C SUBPROGRAM: TUWNDR     RETURNS TWO WIND DIRECTIONS.
C   AUTHOR: KRISHNA KUMAR        ORG: W/NP12   DATE: 1999-08-01
C
C ABSTRACT: RETURNS TWO WIND DIRECTIONS.
C
C PROGRAM HISTORY LOG:
C   80-03-12  PETER HENRICHSEN
C   93-04-28  LUKE LIN   CONVERT TO FORTRAN-77 AND ADD DOC BLOCK.
C   97-03-13  LUKE LIN   CONVERT TO CFT-77
C 1999-08-01  KRISHNA KUMAR CONVERTED THIS CODE FROM CRAY TO IBM RS/6000.
C
C USAGE:  CALL TUWNDR(GU,GV,IDIR,ISPEED,ANL,VRTLON,ALON,ITRUDR,KEY)
C   INPUT ARGUMENTS:
C     KEY      -  WIND DIRECTION RETURNED TO NEAREST TEN DEGREES, KEY=0
C                 WIND DIRECTION RETURNED TO NEAREST ONE DEGREE, ELSE.
C     GU,GV    -  THE GRID ORIENTED COMPONENTS OF THE WIND IN ANY
C                 DESIRED UNIT.
C     ANG      -  ANGLE WIND DIR IS TO BE ROTATED TO CONVERT FROM ONE
C                 GRID TO ANOTHER ..IE. TO VONVERT WINDS FROM LFM GRID
C                 FOR DISPLAY ON STANDARD NMC GRID, ANG = +25.0.
C     ALON     -  TRUELON OF WIND.
C     VRTLON   -  VERTICAL LON OF BGRD MAP OR GRID, IE. LFM V. LON. 105.
C
C   OUTPUT ARGUMENTS:
C     ITRUDR   -  TRUE DIRECTION OF WIND
C     ITRUDR   -  TRUE DIRECTION OF WIND TO NEAREST TEN DEGS.
C     ISPEED   -  WIND SPEED RETURNED IN SAME UNITS GIVEN.
C
C   REMARKS: NONE
C
C
C ATTRIBUTES:
C   LANGUAGE: FORTRAN 90
C   MACHINE:  IBM
C
C$$$
C
      REAL    GU,GV,ANG,VRTLON,ALON
      INTEGER IDIR,ISPEED,ITRUDR,KEY
C
      ISPEED = SQRT(GU*GU+GV*GV)+0.5
C     ISPEED = NINT(SQRT(GU*GU+GV*GV))
      IF(GU .NE. 0.0 .OR. GV .NE. 0.0) GO TO 6
      IDIR = 0
      ITRUDR=99
      RETURN
   6  IDIR = 270.0 -57.29578*ATAN2(GV,GU)+ANG + 0.5
      TRUDR= (FLOAT(IDIR)+(VRTLON-ALON))
      IF(TRUDR.LT.0) TRUDR = TRUDR + 360.0
      ITRUDR = (TRUDR + 5.0)*0.1
      IF(ITRUDR.GT.36) ITRUDR=ITRUDR-36
      IF(KEY.NE.0)GO TO 9
      IDIR = (FLOAT(IDIR)+5.0)*0.1
      IF(IDIR .GT. 36) IDIR =IDIR -36
   8  IF(ISPEED .EQ. 0) IDIR = 0
      IF(ISPEED .EQ. 0) ITRUDR =99
      IF(IDIR .EQ. 0 .AND.ISPEED .NE. 0) IDIR = 36
      IF(ITRUDR.EQ.0 .AND.ISPEED .NE. 0)ITRUDR=36
      RETURN
   9  IF(ISPEED .EQ. 0) IDIR = 0
      IF(IDIR .GT.360) IDIR =IDIR -360
      IF(ISPEED .EQ. 0) ITRUDR =99
      IF(IDIR .EQ. 0 .AND.ISPEED .NE. 0) IDIR = 360
      IF(ITRUDR.EQ.0 .AND.ISPEED .NE. 0)ITRUDR=36
      RETURN
      END

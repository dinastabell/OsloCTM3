!//=========================================================================
!// Oslo CTM3
!//=========================================================================
!// Ole Amund Sovde, April 2015
!//=========================================================================
!// Routines for calculating dry deposition rates.
!//=========================================================================
module drydeposition_oslo
  !// ----------------------------------------------------------------------
  !// MODULE: drydeposition_oslo
  !// DESCRIPTION: Routines calculating dry deposition velocities.
  !// ----------------------------------------------------------------------
  !// New calculations for several species, but some still use the
  !// older CTM2 approach.
  !//
  !// MISSING
  !//  - land type crops: growth season correction
  !//
  !//
  !// Contains:
  !//   - subroutine drydepinit
  !//   - subroutine update_drydepvariables
  !//   - subroutine setdrydep
  !//   - subroutine get_ctm2dep
  !//   - subroutine get_vdep2
  !//   - subroutine get_STC
  !//   - subroutine get_PARMEAN
  !//   - subroutine get_PPFD
  !//   - subroutine get_asn24h
  !//   - subroutine aer_vdep2
  !//   - function PSIM, PSIH
  !//
  !// Stefanie Falk, Mai 2019 - ??? 
  !// Stefanie Falk, Februar 2018 - July 2018
  !// Amund Sovde, December 2013 - January 2014
  !// ----------------------------------------------------------------------
  use cmn_precision, only: r8
  use cmn_size, only: IPAR, JPAR, NPAR
  !// ----------------------------------------------------------------------
  implicit none
  !// ----------------------------------------------------------------------

  !// CTM2 dry deposition (for old scheme)
  !// not initilized if new scheme is used!
  real(r8), dimension(5,6) :: &
       VO3DDEP, VHNO3DDEP, VPANDDEP, VCODDEP, VH2O2DDEP, &
       VNOXDDEP, VSO2DDEP, VSO4DDEP, VMSADDEP, VNH3DDEP
  !// Stomatal conductance and mean photolytic active radiation
  real(r8), dimension(IPAR,JPAR,12) :: STC, PARMEAN
  ! Parameters and land use type from Simpson et al. (2012)
  real(r8), dimension(28,16) :: DDEP_PAR
  !// Defines which VDEP to scale according to stability (i.e. only
  !// old CTM2 calculations)
  integer :: SCALESTABILITY(NPAR)


  !// 24-hour average SO2/NH3 (size 96 to allow for NROPSM=12
  integer, parameter :: ASN24H_MAX_STEPS=96
  real(r8) :: ASN24H(ASN24H_MAX_STEPS,IPAR,JPAR)
  !// Monthly averaged Asn to be used if NH3 and SO2 are not included
  !real(r8) :: ASNCLIM(IPAR,JPAR,12) !// Not currently included

    !// ----------------------------------------------------------------------
  character(len=*), parameter, private :: f90file = 'drydeposition_oslo.f90'
  !// ----------------------------------------------------------------------

  save !// All variables are to be saved.
  private
  public drydepinit, update_drydepvariables, setdrydep

  !// ----------------------------------------------------------------------
contains
  !// ----------------------------------------------------------------------

  !// ----------------------------------------------------------------------
  subroutine drydepinit()
    !// --------------------------------------------------------------------
    !// Read drydep.ctm
    !//
    !// Amund Sovde, October 2008
    !// --------------------------------------------------------------------
    use cmn_sfc, only: VDEP, VGSTO3, LDDEPmOSaic, fileDDEPpar
    use utilities, only: get_free_fileid
    !// --------------------------------------------------------------------
    implicit none
    !// --------------------------------------------------------------------
    !// Locals
    integer :: I,J,IOS,IFNR
    character(len=80) :: FILE_NAME
    !// --------------------------------------------------------------------
    character(len=*), parameter :: subr = 'drydepinit'
    !// --------------------------------------------------------------------
    !// Temporare ascii array
    character(len=8), dimension(29,16) :: temp
    !// --------------------------------------------------------------------
    !// Initialize dry deposition
    write(6,'(a)') f90file//':'//subr//': initializing VDEP' 
    VDEP(:,:,:) = 0._r8
    !// Initialize stomata deposition
    write(6,'(a)') f90file//':'//subr//': initializing VGSTO3' 
    VGSTO3(:,:) = 0._r8
    !// Get a free file id
    IFNR = get_free_fileid()
    !// Switch between default scheme and mOSaic scheme
    if (LDDEPmOSaic) then
       open(IFNR,file=fileDDEPpar,Status='OLD',action='read',IOSTAT=IOS)
       if (IOS .eq. 0) then
          write(6,'(a)') '** Reading dry deposition parameters from '//trim(fileDDEPpar)
       else
          write(6,'(a)') f90file//':'//subr//': File not found: '//trim(fileDDEPpar)
          stop
       end if
       ! Read the table header
       read(IFNR, *) 
       ! Read the whole table as ascii (none floating point value in column one)
       read(IFNR, *) temp
       ! Split the temporary table and save the data
       read(temp(2:,:),'(f10.0)') DDEP_PAR
       write(6,*) temp
       close(unit=ifnr)
    else
       
       !// Old scheme
       !// Read in Deposition velocities from file for old CTM2 scheme
       open(IFNR,file=fileDDEPpar,Status='OLD',Form='FORMATTED',IOSTAT=IOS)
       if (IOS .eq. 0) then
          write(6,'(a)') '** Reading dry deposition data from '//trim(fileDDEPpar)
       else
          write(6,'(a)') f90file//':'//subr//': File not found: '//trim(fileDDEPpar)
          stop
       end if

       do I = 1,4
          read(IFNR,*)
       end do
       read(IFNR,*)
       do I = 1,5
          read(IFNR,1200) (VO3DDEP(I,J),J=1,6)
       end do
       read(IFNR,*)
       do I = 1,5
          read(IFNR,1200) (VHNO3DDEP(I,J),J=1,6)
       end do
       read(IFNR,*)
       do I = 1,5
          read(IFNR,1200) (VPANDDEP(I,J),J=1,6)
       end do
       read(IFNR,*)
       do I = 1,5
          read(IFNR,1200) (VCODDEP(I,J),J=1,6)
       end do
       read(IFNR,*)
       do I = 1,5
          read(IFNR,1200) (VH2O2DDEP(I,J),J=1,6)
       end do
       read(IFNR,*)
       do I = 1,5
          read(IFNR,1200) (VNOxDDEP(I,J),J=1,6)
       end do

       !// Read in dry deposition values for sulphur 
       read(IFNR,*)
       do I = 1,5
          read(IFNR,1200) (VSO2DDEP(I,J),J=1,6)
       end do
       read(IFNR,*)
       do I = 1,5
          read(IFNR,1200) (VSO4DDEP(I,J),J=1,6)
       end do
       read(IFNR,*)
       do I = 1,5
          read(IFNR,1200) (VMSADDEP(I,J),J=1,6)
       end do
       !// Nitrate
       read(IFNR,*)
       do I = 1,5
          read(IFNR,1200) (VNH3DDEP(I,J),J=1,6)
       end do
       
       close (IFNR)
!// Jump label - used in reading the file format!
1200   Format(6(1x,f5.2))
    end if
    !// Initialize STC (will be read from file later)
    STC(:,:,:) = 0._r8

    PARMEAN(:,:,:) = 0._r8

    !// Initialise scaling flags
    SCALESTABILITY(:) = 1

    !// --------------------------------------------------------------------
  end subroutine drydepinit
  !// ----------------------------------------------------------------------




  !// ----------------------------------------------------------------------
  subroutine update_drydepvariables(LNEW_MONTH, NDAYI, NDAY, NMET, NOPS)
    !// --------------------------------------------------------------------
    !// Sets up special drydep treatments, e.g. drydep velocities or
    !// soil uptakes needing monthly input.
    !// Also reads stomatal conductance and photsynthetic active radiation
    !// for EMEP-based dry deposition of species.
    !//
    !// Stefanie Falk, July 2018
    !// Amund Sovde, March 2013 - January 2014
    !// --------------------------------------------------------------------
    use cmn_ctm, only: JMON, JDATE, NRMETD
    use cmn_sfc, only: LDDEPmOSaic
    use cmn_oslo, only: TEMPAVG
    use ch4routines, only: updateSOILUPTAKEbousquet
    !// --------------------------------------------------------------------
    implicit none
    !// --------------------------------------------------------------------
    !// Input
    logical, intent(in) :: LNEW_MONTH
    integer, intent(in) :: NDAYI, NDAY, NMET, NOPS
    !// --------------------------------------------------------------------
    !//---time steps -TAU- (hr) and DT-- (s)
    real(r8) :: DTMET, DTAUMT
    !// Time steps
    DTAUMT = 24._r8 / real(NRMETD, r8)  ! in hours
    DTMET  = 3600._r8 *DTAUMT  ! in seconds

    !// CH4 soil uptake, stores values in CH4SOILUPTAKE
    call updateSOILUPTAKEbousquet(LNEW_MONTH)

    !// DRYDEP2
    if (LDDEPmOSaic) then
       !// Find SO2/NH3 fraction for each hour
       call get_asn24h(NDAYI, NDAY, NMET, NOPS)
       !// Update photon flux density
       call get_PPFD(NMET, DTMET)
       
    end if !// if (LDDEPmOSaic) then

    !// --------------------------------------------------------------------
  end subroutine update_drydepvariables
  !// ----------------------------------------------------------------------




  !// ----------------------------------------------------------------------
  subroutine setdrydep(UTTAU, BTT, AIRB, BTEM, MP)
    !// --------------------------------------------------------------------
    !// Sets dry deposition each time step.
    !// Called from p-main.
    !//
    !// Amund Sovde, October 2008
    !// --------------------------------------------------------------------
    use cmn_size, only: LPAR, IDBLK, JDBLK, MPBLK, &
         LOSLOCTROP, LBCOC, LSULPHUR, LNITRATE, LSOA
    use cmn_ctm, only: NTM, MPBLKJB, MPBLKJE, MPBLKIB, MPBLKIE, &
         JMON, GMTAU, XGRD,YGRD, IDAY, PLAND
    use cmn_fjx, only: SZAMAX
    use cmn_met, only: CI, SD, PBL_KEDDY, ZOFLE, SFT
    use cmn_parameters, only: M_AIR, AVOGNR, R_AIR, G0, LDEBUG, VONKARMAN
    use cmn_sfc, only: landSurfTypeFrac, LANDUSE_IDX, VDEP, VGSTO3, LDDEPmOSaic
    use cmn_oslo, only: chem_idx, trsp_idx
    use bcoc_oslo, only: bcoc_setdrydep, bcoc_vdep2
    use soa_oslo, only: soa_setdrydep
    use ch4routines, only: ch4drydep_bousquet
    !// --------------------------------------------------------------------
    implicit none
    !// --------------------------------------------------------------------
    !// Input
    real(r8), intent(in)  :: UTTAU
    real(r8), intent(in)  :: BTT(LPAR,NPAR,IDBLK,JDBLK)
    real(r8), intent(in)  :: AIRB(LPAR,IDBLK,JDBLK), BTEM(LPAR,IDBLK,JDBLK)
    integer, intent(in) :: MP

    !// Locals
    integer :: I,J,II,JJ,L,JIND,ISEA,N
    real(r8) :: RSUM,FR1,FR2,FR3,FR4,FR5, &
         RO3,RHNO3,RPAN,RCO,RH2O2,RNO2, RSO2,RSO4,RMSA, RNH3

    real(r8),dimension(IDBLK,JDBLK) :: DZ, &
         VNO2, VO3, VHNO3, VPAN, VCO, VH2O2, &
         VSO2, VSO4, VMSA, VNH3, &
         VNO,  VHCHO, VCH3CHO, &
         VSto

    integer :: MDAY(IDBLK,JDBLK)    !// 1=day, 2=night
    integer :: MSEASON(IDBLK,JDBLK) !// 0=summer, 3=winter
    real(r8)  :: RFR(5,IDBLK,JDBLK)   !// Fractions of land types (5 of them)
    real(r8)  :: SZA, U0, SOLF        !// To find night/day

    real(r8),parameter :: &
         BGK    = 1.d-19, &
         CONST  = 7.2_r8, &
         T2TV   = 3._r8/5._r8, &  !// Converting to virtual temperature
         ZG0    = 1._r8/G0
    !// --------------------------------------------------------------------
    character(len=*), parameter :: subr = 'setdrydep'
    !// --------------------------------------------------------------------


    !// Find day/night and vegetation fractions
    !// --------------------------------------------------------------------

    !// Loop over latitude (J is global, JJ is block)
    do J = MPBLKJB(MP),MPBLKJE(MP)
      JJ    = J - MPBLKJB(MP) + 1

      !// Loop over longitude (I is global, II is block)
      do I = MPBLKIB(MP),MPBLKIE(MP)
        II    = I - MPBLKIB(MP) + 1

        !// Day and night selector
        !// CTM2 used J_NO2 @ surface; better to use SZA < SZAMAX
        call SOLARZ (UTTAU,IDAY,YGRD(J),XGRD(I), SZA,U0,SOLF)
        if (SZA .lt. SZAMAX) then
           MDAY(II,JJ) = 1 !// day
        Else
           MDAY(II,JJ) = 2 !// night
        End If

        !// In case there are inconsitensies between land fraction grid and 
        !// vegetation fraction, initialize
        MSEASON(II,JJ) = 0

        !// Initialize ISEA
        ISEA = 0

        !// Determine if we have land fraction in the grid.
        if (PLAND(I,J) .gt. 0._r8) then
           !// Check if we have summer, winter or in-between conditions
           !// Too simple approach, but we keep it for now
           if (SFT(I,J) .gt. 278._r8) then
              MSEASON(II,JJ) = 0
           else if (SFT(I,J) .lt. 268._r8) then
              MSEASON(II,JJ) = 3
           else
              !// dirty fix assuming winter for 268K-278K
              MSEASON(II,JJ) = 3
           end if
        end if

        !// The summer/winter definition is different for land and ocean
        !// Use separate definition for ocean season
        if (PLAND(I,J) .lt. 1._r8 .and. CI(I,J).GT.0._r8) Then
           ISEA = 2
        else
           ISEA = 0
        end if


        !// Calculate land fractions from land use dataset
        !// ----------------------------------------------------------------
        !// Indices of Oslo Vxx are as follows
        !// I=1:sea, I=2:forest, I=3:grass, I=4:tundra/desert, I=5:Ice/Snow
        !// J=1-3:summer(day,night,avg),  J=4-6:winter(day,night,avg)
        !// ----------------------------------------------------------------

        if (LANDUSE_IDX .eq. 2) then
           !// -------------------------------------------------------------
           !// ISLSCP2 MODIS land fraction and type data
           !// Note: Type 0 represents water and is not included in
           !//        landSurfTypeFrac.
           !//  0=Water Bodies                    1=Evergreen Needleleaf Forests
           !//  2=Evergreen Broadleaf Forests     3=Deciduous Needleleaf Forests
           !//  4=Deciduous Broadleaf Forests     5=Mixed Forests
           !//  6=Closed Shrublands               7=Open Shrublands
           !//  8=Woody Savannas                  9=Savannas
           !// 10=Grasslands                      11=Permanent Wetlands
           !// 12=Croplands                          13=Urban and Built-Up
           !// 14=Cropland/Natural Vegetation Mosaic 15=Permanent Snow and Ice
           !// 16=Barren or Sparsely Vegetated       17=Unclassified
           !// -------------------------------------------------------------
           !// Forest
           FR2  = landSurfTypeFrac(1,I,J) + landSurfTypeFrac(2,I,J) + landSurfTypeFrac(3,I,J) &
                + landSurfTypeFrac(4,I,J) + landSurfTypeFrac(5,I,J)
           !// Grass
           FR3  = landSurfTypeFrac(8,I,J) + landSurfTypeFrac(9,I,J) + landSurfTypeFrac(10,I,J) &
                + landSurfTypeFrac(11,I,J) + landSurfTypeFrac(12,I,J) + landSurfTypeFrac(14,I,J)
           !// Tundra/desert
           FR4  = landSurfTypeFrac(6,I,J) + landSurfTypeFrac(7,I,J) + landSurfTypeFrac(16,I,J) &
                + landSurfTypeFrac(13,I,J) + landSurfTypeFrac(17,I,J)
           !// Ice/snow
           FR5 = landSurfTypeFrac(15,I,J)
           !// Ocean is the rest
           RSUM = FR2 + FR3 + FR4 + FR5
           FR1  = max(0._r8, 1._r8 - RSUM)
           if (FR1 .lt. 0._r8) then
              write(6,'(a,2i5,2es16.6)') f90file//':'//subr// &
                   ': neg ocean',i,j,FR1,RSUM
              stop
           end if
        else if (LANDUSE_IDX .eq. 3) then
           !// CLM4-PFT
           !//  1    17    Barren land
           !//  2     1    Needleaf evergreen temperate tree
           !//  3     2    Needleaf evergreen boreal tree
           !//  4     3    Needleaf deciduous boreal tree
           !//  5     4    Broadleaf evergreen tropical tree
           !//  6     5    Broadleaf evergreen temperate tree
           !//  7     6    Broadleaf deciduous tropical tree
           !//  8     7    Broadleaf deciduous temperate tree
           !//  9     8    Broadleaf deciduous boreal tree
           !// 10     9    Broadleaf evergreen temperate shrub
           !// 11    10    Broadleaf deciduous temperate shrub
           !// 12    11    Broadleaf deciduous boreal shrub
           !// 13    12    Arctic C3 grass (cold)
           !// 14    13    C3 grass (cool)
           !// 15    14    C4 grass (warm)
           !// 16    15    Crop1
           !// 17    16    Crop2
           !// Forest
           FR2  = sum(landSurfTypeFrac(1:8,I,J))
           !// Grass
           FR3  = sum(landSurfTypeFrac(12:16,I,J))
           !// Tundra/desert (add shrub here)
           FR4  = sum(landSurfTypeFrac(9:11,I,J)) + landSurfTypeFrac(17,I,J)
           !// Ice/snow - will be set below based on snow depth
           FR5 = 0._r8
           !// Ocean is the rest
           RSUM = FR2 + FR3 + FR4 + FR5
           FR1  = max(0._r8, 1._r8 - RSUM)

        else
           write(6,'(a,i5)') f90file//':'//subr// &
                ': No such LANDUS_IDX available',LANDUSE_IDX
           stop
        end if


        if (ISEA .eq. 2) then
           !// Moving ice covered ocean to ice
           FR5  = FR5 + (FR1 - max(FR1 - CI(I,J), 0._r8))
           FR1  = max(FR1 - CI(I,J), 0._r8)
        end if

        !// We also have snow depth information in the 1997 > newer and ERA-40
        !// Use this information to move fractions from
        !// 1. grass, 2. Tundra and finally from forest.
        !// IMPORTANT
        !// SD is meter water equivalents, i.e. 0.01 is approx 0.1m snow,
        !// and 0.1 is approx 1m snow.
        if (SD(I,J) .gt. 0.01_r8) then
           !// Grass - assume snow covered when snowdepth is more than 10cm
           FR5 = FR5 + FR3
           FR3 = 0._r8
           !// Tundra - assume snow covered when snowdepth is more than 10cm
           FR5 = FR5 + FR4
           FR4 = 0._r8

           if (SD(I,J) .gt. 0.1_r8) then
              !// Forest - assume snow covered when snowdepth is more than
              !// 1 meter
              FR5 = FR5 + FR2
              FR2 = 0._r8
           end if
        end if

        !// Check numbers
        if (abs(FR1+FR2+FR3+FR4+FR5 - 1.) .gt. 0.01) then
           write(6,'(a,6es20.12)') f90file//':'//subr// &
                ': wrong fractions ',FR1+FR2+FR3+FR4+FR5,FR1,FR2,FR3,FR4,FR5
           stop
        end if

        !// Save fractions
        RFR(1,II,JJ) = FR1
        RFR(2,II,JJ) = FR2
        RFR(3,II,JJ) = FR3
        RFR(4,II,JJ) = FR4
        RFR(5,II,JJ) = FR5

      end do !// do I = MPBLKIB(MP),MPBLKIE(MP)
    end do !// do J = MPBLKJB(MP),MPBLKJE(MP)


    !// --------------------------------------------------------------------
    !// Find dZ of surface layer
    !// --------------------------------------------------------------------
    !// Loop over latitude (J is global, JJ is block)
    do J = MPBLKJB(MP),MPBLKJE(MP)
       JJ    = J - MPBLKJB(MP) + 1
       !// Loop over longitude (I is global, II is block)
       do I = MPBLKIB(MP),MPBLKIE(MP)
          II    = I - MPBLKIB(MP) + 1
          DZ(II,JJ) = ZOFLE(2,I,J)-ZOFLE(1,I,J)
       end do
    end do


    !// --------------------------------------------------------------------
    !// Tropospheric components - drydep velocities
    !// --------------------------------------------------------------------
    if (LOSLOCTROP) then

       !// Old CTM2 velocities [m/s]
       call get_ctm2dep(MDAY,MSEASON,RFR, MP, &
            VO3,VHNO3,VPAN,VCO,VH2O2,VNO2, VSO2,VSO4,VMSA, VNH3)

       if (LDDEPmOSaic) then
          !// New dry deposition scheme (ala mOSaic)
          
          !// Not to be standard yet...
          !// When it is, remember dtmax=300 in oc_tropchem

          !// Get new dry deposition values [m/s]
          call get_vdep2(UTTAU, BTT, AIRB, BTEM, MP, &
               VO3,VHNO3,VPAN,VH2O2,VNO2, VSO2,VNH3, VNO,VHCHO,VCH3CHO, VSto)

          !// CTM2 drydep is crude and needs to be adjusted to stability
          !// parameters. This is not the case for VDEP2 treatment, which
          !// takes stability into account. Here we define which components
          !// are to be scaled.
          do N = 1,NTM
             if (chem_idx(N) .eq. 1) then
                SCALESTABILITY(N) = 0
             else if (chem_idx(N) .eq. 4) then
                SCALESTABILITY(N) = 0
             else if (chem_idx(N) .eq. 5) then
                SCALESTABILITY(N) = 0
             else if (chem_idx(N) .eq. 13) then
                SCALESTABILITY(N) = 0
             else if (chem_idx(N) .eq. 14) then
                SCALESTABILITY(N) = 0
             else if (chem_idx(N) .eq. 15) then
                SCALESTABILITY(N) = 0
             else if (chem_idx(N) .eq. 43) then
                SCALESTABILITY(N) = 0
             else if (chem_idx(N) .eq. 44) then
                SCALESTABILITY(N) = 0
             else if (chem_idx(N) .eq. 61) then
                SCALESTABILITY(N) = 0
             else if (chem_idx(N) .eq. 72) then
                SCALESTABILITY(N) = 0
             else
                SCALESTABILITY(N) = 1
             end if
          end do !// do N=1,NTM
       else
          !// Old scheme needs these to be zero
          VNO(:,:)     = 0._r8
          VHCHO(:,:)   = 0._r8
          VCH3CHO(:,:) = 0._r8
          VSto(:,:)    = 0._r8

          !// All are scaled by stability
          SCALESTABILITY(:) = 1
       end if

    else !// if (LOSLOCTROP) then

       !// No tropospheric chemistry; set these to zero.
       VO3(:,:)     = 0._r8
       VHNO3(:,:)   = 0._r8
       VPAN(:,:)    = 0._r8
       VH2O2(:,:)   = 0._r8
       VNO2(:,:)    = 0._r8
       VSO2(:,:)    = 0._r8
       VNH3(:,:)    = 0._r8
       VNO(:,:)     = 0._r8
       VHCHO(:,:)   = 0._r8
       VCH3CHO(:,:) = 0._r8
       VSto(:,:)    = 0._r8

    end if !// if (LOSLOCTROP) then

    !// --------------------------------------------------------------------
    !// UCI deposition override [m/s]
    !// --------------------------------------------------------------------
   
    !// Loop over latitude (J is global, JJ is block)
    do J = MPBLKJB(MP),MPBLKJE(MP)
      JJ    = J - MPBLKJB(MP) + 1
      !// Loop over longitude (I is global, II is block)
      do I = MPBLKIB(MP),MPBLKIE(MP)
        II    = I - MPBLKIB(MP) + 1
        VGSTO3(I,J) = VStO(II, JJ)                   !// Stomata deposition
        do N = 1,NTM

          if (chem_idx(N) .eq. 1) then               !// Standard tropchem ---v
             VDEP(N,I,J) = VO3(II,JJ)
          else if (chem_idx(N) .eq. 4) then
             VDEP(N,I,J) = VHNO3(II,JJ)
          else if (chem_idx(N) .eq. 5) then
             VDEP(N,I,J) = VPAN(II,JJ)
          else if (chem_idx(N) .eq. 6) then
             VDEP(N,I,J) = VCO(II,JJ)
          else if (chem_idx(N) .eq. 13) then
             VDEP(N,I,J) = VHCHO(II,JJ)
          else if (chem_idx(N) .eq. 14) then
             VDEP(N,I,J) = VCH3CHO(II,JJ)
          else if (chem_idx(N) .eq. 15) then
             VDEP(N,I,J) = VH2O2(II,JJ)
          else if (chem_idx(N) .eq. 43) then
             VDEP(N,I,J) = VNO(II,JJ)
          else if (chem_idx(N) .eq. 44) then
             VDEP(N,I,J) = VNO2(II,JJ)
          else if (chem_idx(N) .eq. 72) then         !// Sulphate ---v
             VDEP(N,I,J) = VSO2(II,JJ)
          else if (chem_idx(N) .eq. 73) then
             VDEP(N,I,J) = VSO4(II,JJ)
          else if (chem_idx(N) .eq. 75) then
             VDEP(N,I,J) = VMSA(II,JJ)
          else if (chem_idx(N) .eq. 61) then         !// Nitrate ---v
             VDEP(N,I,J) = VNH3(II,JJ)
          else if (chem_idx(N) .eq. 62) then
             VDEP(N,I,J) = VSO4(II,JJ)   !use sulfate ((NO3)2 SO4)
          else if (chem_idx(N) .eq. 64) then
             VDEP(N,I,J) = VSO4(II,JJ)   !use sulfate ((NH4)2 SO4)
          else
             VDEP(N,I,J) = 0._r8
          end if

        end do !// do N=1,NTM
      end do !// do I = MPBLKIB(MP),MPBLKIE(MP)
    end do !// do J = MPBLKJB(MP),MPBLKJE(MP)
    
    if (LDDEPmOSaic) then
       !// Simpson et al. (2012)
       !// Set dry deposition for BCOC (m/s)
       if (LBCOC) call bcoc_vdep2(VDEP,SCALESTABILITY,MP)
       !// Set dry deposition for SOA, sulphur and nitrate (m/s)
       if (LSULPHUR .or. LNITRATE .or. LSOA) &
            call aer_vdep2(VDEP,SCALESTABILITY,MP)
    else
       !// Old treatment
       if (LBCOC) call bcoc_setdrydep(VDEP,RFR,MP)
       !// Set dry deposition for SOA (m/s)
       if (LSOA) call soa_setdrydep(VDEP,MP)
    end if

    !// Set dry deposition for CH4 (m/s)
    call ch4drydep_bousquet(VDEP, BTT, DZ, MP)

    !// --------------------------------------------------------------------
    !// Modify velocity due to stability (still [m/s])
    !// --------------------------------------------------------------------
    !// Loop over latitude (J is global, JJ is block)
    do J = MPBLKJB(MP),MPBLKJE(MP)
      JJ    = J - MPBLKJB(MP) + 1
      !// Loop over longitude (I is global, II is block)
      do I = MPBLKIB(MP),MPBLKIE(MP)
        II    = I - MPBLKIB(MP) + 1

        do N = 1,NTM
          !// Modify "profile" due to stability (still [m/s])
          !// oc_getVDEP_oslo will divide by DZ
          if (SCALESTABILITY(N) .eq. 1 .and. VDEP(N,I,J) .gt. 0._r8) then
             VDEP(N,I,J) = VDEP(N,I,J) / &
                  (1._r8 + VDEP(N,I,J)*DZ(II,JJ)*0.5_r8/PBL_KEDDY(II,JJ,MP))
          end if
        end do !// do N=1,NTM
      end do !// do I = MPBLKIB(MP),MPBLKIE(MP)
    end do !// do J = MPBLKJB(MP),MPBLKJE(MP)


    !// --------------------------------------------------------------------
  end subroutine setdrydep
  !// ----------------------------------------------------------------------





  !// ----------------------------------------------------------------------
  subroutine get_ctm2dep(MDAY,MSEASON,RFR, MP, &
         VO3,VHNO3,VPAN,VCO,VH2O2,VNO2, VSO2,VSO4,VMSA, VNH3)
    !// --------------------------------------------------------------------
    !// Calculate drydep velocities as in CTM2.
    !//
    !// Amund Sovde, December 2013
    !// --------------------------------------------------------------------
    use cmn_size, only: LSULPHUR, LNITRATE, IDBLK,JDBLK
    use cmn_ctm, only: MPBLKJB, MPBLKJE, MPBLKIB, MPBLKIE
    !// --------------------------------------------------------------------
    implicit none
    !// --------------------------------------------------------------------
    !// Input
    integer, intent(in) :: MP
    integer,dimension(IDBLK,JDBLK),intent(in)  :: MDAY  !// 1=day, 2=night
    integer,dimension(IDBLK,JDBLK),intent(in)  :: MSEASON !// 0=summer, 3=winter
    real(r8),dimension(5,IDBLK,JDBLK),intent(in) :: RFR !// Fract. of land types
    !// Output
    real(r8),dimension(IDBLK,JDBLK), intent(out) :: &
         VO3,VHNO3,VPAN,VCO,VH2O2,VNO2, VSO2,VSO4,VMSA, VNH3

    !// Locals
    integer :: I,J,II,JJ, JIND
    real(r8) :: RO3,RHNO3,RPAN,RCO,RH2O2,RNO2, RSO2,RSO4,RMSA, RNH3
    !// --------------------------------------------------------------------
 
    !// Loop over latitude (J is global, JJ is block)
    do J = MPBLKJB(MP),MPBLKJE(MP)
      JJ    = J - MPBLKJB(MP) + 1
      !// Loop over longitude (I is global, II is block)
      do I = MPBLKIB(MP),MPBLKIE(MP)
        II    = I - MPBLKIB(MP) + 1

        !// specify index in what deposition to use (summer, winter, day, night)
        JIND = MDAY(II,JJ) + MSEASON(II,JJ)

        !// For Ozone
        RO3 = VO3DDEP(1,JIND)*RFR(1,II,JJ) + VO3DDEP(2,JIND)*RFR(2,II,JJ) &
            + VO3DDEP(3,JIND)*RFR(3,II,JJ) + VO3DDEP(4,JIND)*RFR(4,II,JJ) &
            + VO3DDEP(5,JIND)*RFR(5,II,JJ)

        !// For HNO3
        RHNO3 = VHNO3DDEP(1,JIND)*RFR(1,II,JJ) &
              + VHNO3DDEP(2,JIND)*RFR(2,II,JJ) &
              + VHNO3DDEP(3,JIND)*RFR(3,II,JJ) &
              + VHNO3DDEP(4,JIND)*RFR(4,II,JJ) &
              + VHNO3DDEP(5,JIND)*RFR(5,II,JJ)

        !// For PAN
        RPAN = VPANDDEP(1,JIND)*RFR(1,II,JJ) + VPANDDEP(2,JIND)*RFR(2,II,JJ) &
             + VPANDDEP(3,JIND)*RFR(3,II,JJ) + VPANDDEP(4,JIND)*RFR(4,II,JJ) &
             + VPANDDEP(5,JIND)*RFR(5,II,JJ)

        !// For CO
        RCO = VCODDEP(1,JIND)*RFR(1,II,JJ) + VCODDEP(2,JIND)*RFR(2,II,JJ) &
            + VCODDEP(3,JIND)*RFR(3,II,JJ) + VCODDEP(4,JIND)*RFR(4,II,JJ) &
            + VCODDEP(5,JIND)*RFR(5,II,JJ)

        !// For H2O2
        RH2O2 = VH2O2DDEP(1,JIND)*RFR(1,II,JJ) &
              + VH2O2DDEP(2,JIND)*RFR(2,II,JJ) &
              + VH2O2DDEP(3,JIND)*RFR(3,II,JJ) &
              + VH2O2DDEP(4,JIND)*RFR(4,II,JJ) &
              + VH2O2DDEP(5,JIND)*RFR(5,II,JJ)

        !// For NO2
        RNO2 = VNOXDDEP(1,JIND)*RFR(1,II,JJ) + VNOXDDEP(2,JIND)*RFR(2,II,JJ) &
             + VNOXDDEP(3,JIND)*RFR(3,II,JJ) + VNOXDDEP(4,JIND)*RFR(4,II,JJ) &
             + VNOXDDEP(5,JIND)*RFR(5,II,JJ)

        !// The dry deposition velocity is in [cm/s]; will be modified due to
        !// stability in the calling routine.
        !// Convert from [cm/s] to [m/s]
        VO3(II,JJ)   = RO3 * 1.e-2_r8
        VHNO3(II,JJ) = RHNO3 * 1.e-2_r8
        VPAN(II,JJ)  = RPAN * 1.e-2_r8
        VCO(II,JJ)   = RCO * 1.e-2_r8
        VH2O2(II,JJ) = RH2O2 * 1.e-2_r8
        VNO2(II,JJ)  = RNO2 * 1.e-2_r8


        if (LSULPHUR) then
           !// Dry deposition rates for SO2, sulphate and MSA
           !// For SO2
           RSO2 = VSO2DDEP(1,JIND)*RFR(1,II,JJ) &
                + VSO2DDEP(2,JIND)*RFR(2,II,JJ) &
                + VSO2DDEP(3,JIND)*RFR(3,II,JJ) &
                + VSO2DDEP(4,JIND)*RFR(4,II,JJ) &
                + VSO2DDEP(5,JIND)*RFR(5,II,JJ)

           !// For SO4
           RSO4 = VSO4DDEP(1,JIND)*RFR(1,II,JJ) &
                + VSO4DDEP(2,JIND)*RFR(2,II,JJ) &
                + VSO4DDEP(3,JIND)*RFR(3,II,JJ) &
                + VSO4DDEP(4,JIND)*RFR(4,II,JJ) &
                + VSO4DDEP(5,JIND)*RFR(5,II,JJ)  

           !// For MSA
           RMSA = VMSADDEP(1,JIND)*RFR(1,II,JJ) &
                + VMSADDEP(2,JIND)*RFR(2,II,JJ) &
                + VMSADDEP(3,JIND)*RFR(3,II,JJ) &
                + VMSADDEP(4,JIND)*RFR(4,II,JJ) &
                + VMSADDEP(5,JIND)*RFR(5,II,JJ)  
           !// Convert from [cm/s] to [m/s]
           VSO2(II,JJ)  = RSO2 * 1.e-2_r8
           VSO4(II,JJ)  = RSO4 * 1.e-2_r8
           VMSA(II,JJ)  = RMSA * 1.e-2_r8
        end if

        if (LNITRATE) then
           RNH3 = VNH3DDEP(1,JIND)*RFR(1,II,JJ) + VNH3DDEP(2,JIND)*RFR(2,II,JJ) &
                + VNH3DDEP(3,JIND)*RFR(3,II,JJ) + VNH3DDEP(4,JIND)*RFR(4,II,JJ) &
                + VNH3DDEP(5,JIND)*RFR(5,II,JJ)   
           !// Convert from [cm/s] to [m/s]
           VNH3(II,JJ)  = RNH3 * 1.e-2_r8
        end if

      end do !// do I = MPBLKIB(MP),MPBLKIE(MP)
    end do !// do J = MPBLKJB(MP),MPBLKJE(MP)

    !// --------------------------------------------------------------------
  end subroutine get_ctm2dep
  !// ----------------------------------------------------------------------





  !// ----------------------------------------------------------------------
  subroutine get_vdep2(UTTAU,BTT,AIRB,BTEM, MP, &
         VO3,VHNO3,VPAN,VH2O2,VNO2, VSO2,VNH3, VNO,VHCHO,VCH3CHO, VSto)
    !// --------------------------------------------------------------------
    !// Calculate drydep of gases as in EMEP model, Simpson et al. (2012),
    !// ACP, doi:10.5194/acp-12-7825-2012, refered to as EMEP in
    !// this routine.
    !//
    !// Based on conventional one-dimensional resistance analogy where
    !// the deposition velocity Vd is
    !//   Vd = 1/(Ra + Rb + Rc)
    !// where
    !//   Ra = Aerodynamic resistance.
    !//   Rb = Integrated quasi-laminar resistance due to differences in
    !//        momentum and mass transfer in the viscous sub-layer adjacent
    !//        to the roughness elements.
    !//   Rc = Canopy (or surface) resistance, combining all processes
    !//        resulting in the final uptake or destruction. Also sometimes
    !//        denoted Rs.
    !// Generally, Ra is common to all species, Rb depends on molecular
    !// diffusity, and Rc differs for most species.
    !//
    !// Amund Sovde, December 2013 - January 2014
    !// --------------------------------------------------------------------
    use cmn_size, only: LPAR, IDBLK, JDBLK, LSULPHUR, LNITRATE
    use cmn_ctm, only: XGRD, YGRD, XDGRD, YDGRD, MPBLKJB, MPBLKJE, &
         MPBLKIB, MPBLKIE, IDAY, JMON, JDAY, PLAND, NRMETD, NROPSM
    use cmn_met, only: PRANDTLL1, P, SD, CI, USTR, ZOFLE, PRECLS, PRECCNV, &
         CLDFR, PPFD, UMS, VMS, SFT, SWVL3
    use cmn_parameters, only: R_AIR, R_UNIV, VONKARMAN
    use cmn_sfc, only: LAI, ZOI, landSurfTypeFrac, LANDUSE_IDX, StomRes, NVGPAR, &
         DDEP_PAR, LGSMAP
    use cmn_oslo, only: trsp_idx
    use utilities_oslo, only: landfrac2mosaic, set_vegetation_height, &
         GROWSEASON, MAPPED_GROWSEASON
    !// --------------------------------------------------------------------
    implicit none
    !// --------------------------------------------------------------------
    !// Input
    real(r8), intent(in)  :: UTTAU
    real(r8), intent(in)  :: BTT(LPAR,NPAR,IDBLK,JDBLK)
    real(r8), intent(in)  :: AIRB(LPAR,IDBLK,JDBLK), BTEM(LPAR,IDBLK,JDBLK)
    integer, intent(in) :: MP
    !// Output
    real(r8),dimension(IDBLK,JDBLK), intent(out) :: &
         VO3,VHNO3,VPAN,VH2O2,VNO2, VSO2,VNH3, VNO,VHCHO,VCH3CHO, VSto

    !// Locals
    integer :: I,J,II,JJ, NN, KK, NTOTAL
    real(r8) :: LAI_IJ, RTOTAL, PAR_IJ, SWVL3_IJ
    real(r8) :: tempVEGH
    integer :: GDAY, GLEN                   !// Growing season from megan

    !// Variables to be set for each EMEP category (10 is treated separately)
    integer, parameter :: NLCAT=10
    real(r8), dimension(NLCAT) :: SAI, SAI0,  FL, gsto, &
          Rinc, GO3, GSO2, fLight, fsnowC, fstcT2, fphen, fD, fSW
    !// Parameters from EMEP.par
    real(r8), dimension(NLCAT) :: gmax, fmin, Dmin, Dmax,   &
         phia, phib, phic, phid, phie, phif, phiAS, phiAE,  &
         RgsO3, RgsSO2, VEGH, topt, tmin, tmax, dSGS, dEGS, &
         fLightAlpha, ddSGS, ddEGS
    !// Resistances and deposition velocities
    integer, parameter :: NDDEP = 14
    real(r8)                   :: Ra, Tot_res
    real(r8), dimension(NDDEP) :: Rb, Rc, VD

    !// Meteorological variables
    real(r8) :: z0, z0w, zref, zthick, RAIN, T2M, PrL, USR, SFNU, PSFC, &
         WINDL1, snowD
    !// To calculate Rb
    real(r8) :: d_i, RbL, RbO
    !// To calculate Rc
    real(r8) :: RsnowO3, RsnowSO2, GnsO3, GcO3, GstO3, d, gext, &
         Rgs, FT, VPD, &
         T2Mcel, ee, RH, M_SO2, M_NH3, Asn, Asn24, &
         GnsSO2, GSO2_dry, GSO2_wet, &
         Gstc_avg 
    
    !// Uptake parameters taken from Wesley (Atm.Env., 1989,
    !// doi:10.1016/0004-6981(89)90153-4)
    !// D_H2O/D_x in Table 2
    real(r8),dimension(NDDEP),parameter :: D_gas=(/ &
    !// O3     SO2    NO     HNO3   H2O2   Aceta  HCHO   PAN
        1.6_r8, 1.9_r8, 1.3_r8, 1.9_r8, 1.4_r8, 1.6_r8, 1.3_r8, 2.6_r8, &
    !// NO2    CH3OOH PAA    HCO2H  HNO2   NH3
        1.6_r8, 1.6_r8, 2.0_r8, 1.6_r8, 1.6_r8, 1._r8 /)
    !// PAA: Peroxyacetic acid
    !// Aceta: Acetaldehyde CH3CHO
    !// Formic acid: HCO2H

    !// H (M/atm) in Table 2 (NH3 as in Stevenson etal (2012, ACP)
    real(r8),dimension(NDDEP),parameter :: Hstar=(/ &
         !// O3      SO2      NO        HNO3      H2O2    Aceta     HCHO
         1.e-2_r8, 1.e5_r8, 2.e-3_r8, 1.e14_r8, 1.e5_r8,  15._r8, 6.e3_r8, &
         !// PAN    NO2     CH3OOH      PAA      HCO2H    HNO2     NH3
         3.6_r8,  1.e-2_r8, 2.4e2_r8, 5.4e2_r8, 4.e6_r8,  6._r8,  1.e5_r8 /)

    !// f0 in Table 2
    real(r8),dimension(NDDEP),parameter :: f0=(/ &
         !// O3   SO2    NO     HNO3    H2O2    Aceta   HCHO
         1._r8, 0._r8,  0._r8,  0._r8,  1._r8,  0._r8,  0._r8, &
         !// PAN NO2  CH3OOH PAA     HCO2H   HNO2    NH3
         0.1_r8, 0.1_r8, 0.1_r8, 0.1_r8, 0._r8,  0.1_r8, 0._r8 /)

    !// Other parameters
    real(r8), parameter :: &
         Sc_H20 = 0.6_r8, &   !// Schmidt number for H2O
         D_H2O  = 0.21e-4_r8, & !// Molecular diffusivity for H2O
         RHlim  = 75._r8, &
         Rd     = 180._r8, &
         Rw     = 100._r8
        
    !// --------------------------------------------------------------------
    character(len=*), parameter :: subr = 'get_vdep2'
    !// --------------------------------------------------------------------
      
    !// Check for correct land use fractions
!    if (LANDUSE_IDX .ne. 2) then
!       write(6,'(a)') f90file//':'//subr// &
!            ': not programmed LANDUSE_IDX /= 2 yet'
!       stop
!    end if

    !// Set parameters to be used for the 8 LPJ land use categories
    !// RgsO3:  Ground surface resistance
    !// RgsSO2: Ground surface resistance
    !// SAI0:   To calculate surface area index SAI = LAI+SAI0
    !// VEG_H:  Vegetation height

    !// Reduced EMEP categories
    !//  1. Forests, Mediterranean scrub
    !//  2. Crops
    !//  3. Moorland (savanna++)
    !//  4. Grassland
    !//  5. Wetlands
    !//  6. Tundra
    !//  7. Desert
    !//  8. Water
    !//  9. Urban
    !// 10. Ice+snow (strictly, EMEP has this as category 9 and urban as 10)
    !// Maximal stomatal conductance
    !// gmax = DDEP_PAR(1,:) !// mmmole O3 m-2 s-1
    !// fmin = DDEP_PAR(2,:)
    !// Phenomenology fphen (Table S17)
    !// phia = DDEP_PAR(3,:)
    !// phib = DDEP_PAR(4,:)
    !// phic = DDEP_PAR(5,:)
    !// phid = DDEP_PAR(6,:)
    !// phie = DDEP_PAR(7,:)
    !// phif = DDEP_PAR(8,:)
    !// phiAS = DDEP_PAR(9,:)
    !// phiAE = DDEP_PAR(10,:)
    !// Light dependent scaling
    !// flightalpha = DDEP_PAR(11,:)
    !// Temperature scaling fT (Supplement Eq. (17))
    !// tmin = DDEP_PAR(12,:)
    !// topt = DDEP_PAR(13,:)
    !// tmax = DDEP_PAR(14,:)
    !// Humidity dependent scaling fD (Supplement Eq. (18))
    !// Dmax = DDEP_PAR(15,:)
    !// Dmin = DDEP_PAR(16,:)
    !// Surface resistance
    !// RgsSO2 = DDEP_PAR(18,:)
    !// RgsO3  = DDEP_PAR(19,:)
    !// Vegetation height
    !// VEGH   = DDEP_PAR(20,:)
    !// Growing season
    !// dSGS = DDEP_PAR(21,:)   !// Start
    !// dEGS = DDEP_PAR(22,:)   !// End
    !// ddSGS = DDEP_PAR(23,:)  !// Latitude dependent change of start (rate)
    !// ddEGS = DDEP_PAR(24,:)  !// Latitude dependent change of end (rate)

    !//  1. Forests, Mediterranean scrub
    gmax(1)        = (sum(DDEP_PAR(1,1:4))+DDEP_PAR(1,10))/5._r8 
    fmin(1)        = (sum(DDEP_PAR(2,1:4))+DDEP_PAR(2,10))/5._r8
    phia(1)        = (sum(DDEP_PAR(3,1:4))+DDEP_PAR(3,10))/5._r8
    phib(1)        = (sum(DDEP_PAR(4,1:4))+DDEP_PAR(4,10))/5._r8
    phic(1)        = (sum(DDEP_PAR(5,1:4))+DDEP_PAR(5,10))/5._r8
    phid(1)        = (sum(DDEP_PAR(6,1:4))+DDEP_PAR(6,10))/5._r8
    phie(1)        = (sum(DDEP_PAR(7,1:4))+DDEP_PAR(7,10))/5._r8
    phif(1)        = (sum(DDEP_PAR(8,1:4))+DDEP_PAR(8,10))/5._r8
    phiAS(1)       = (sum(DDEP_PAR(9,1:4))+DDEP_PAR(9,10))/5._r8
    phiAE(1)       = (sum(DDEP_PAR(10,1:4))+DDEP_PAR(10,10))/5._r8
    flightalpha(1) = (sum(DDEP_PAR(11,1:4))+DDEP_PAR(11,10))/5._r8
    tmin(1)        = (sum(DDEP_PAR(12,1:4))+DDEP_PAR(12,10))/5._r8
    topt(1)        = (sum(DDEP_PAR(13,1:4))+DDEP_PAR(13,10))/5._r8
    tmax(1)        = (sum(DDEP_PAR(14,1:4))+DDEP_PAR(14,10))/5._r8
    Dmax(1)        = (sum(DDEP_PAR(15,1:4))+DDEP_PAR(15,10))/5._r8
    Dmin(1)        = (sum(DDEP_PAR(16,1:4))+DDEP_PAR(16,10))/5._r8
    RgsSO2(1)      = (sum(DDEP_PAR(18,1:4))+DDEP_PAR(18,10))/5._r8 
    RgsO3(1)       = (sum(DDEP_PAR(19,1:4))+DDEP_PAR(19,10))/5._r8
    VEGH(1)        = 0._r8 !// Will be modified
    tempVEGH       = (sum(DDEP_PAR(20,1:4))+DDEP_PAR(20,10))/5._r8 
    dSGS(1)        = (sum(DDEP_PAR(21,1:4))+DDEP_PAR(21,10))/5._r8  !// Start
    dEGS(1)        = (sum(DDEP_PAR(22,1:4))+DDEP_PAR(22,10))/5._r8  !// End
    ddSGS(1)       = (sum(DDEP_PAR(23,1:4))+DDEP_PAR(23,10))/5._r8  !// Latitude dependent change of start (rate)
    ddEGS(1)       = (sum(DDEP_PAR(24,1:4))+DDEP_PAR(24,10))/5._r8
    !//  2. Crops
    gmax(2)        = sum(DDEP_PAR(1,5:7))/3._r8
    fmin(2)        = sum(DDEP_PAR(2,5:7))/3._r8
    phia(2)        = sum(DDEP_PAR(3,5:7))/3._r8
    phib(2)        = sum(DDEP_PAR(4,5:7))/3._r8
    phic(2)        = sum(DDEP_PAR(5,5:7))/3._r8
    phid(2)        = sum(DDEP_PAR(6,5:7))/3._r8
    phie(2)        = sum(DDEP_PAR(7,5:7))/3._r8
    phif(2)        = sum(DDEP_PAR(8,5:7))/3._r8
    phiAS(2)       = sum(DDEP_PAR(9,5:7))/3._r8
    phiAE(2)       = sum(DDEP_PAR(10,5:7))/3._r8
    flightalpha(2) = sum(DDEP_PAR(11,5:7))/3._r8
    tmin(2)        = sum(DDEP_PAR(12,5:7))/3._r8
    topt(2)        = sum(DDEP_PAR(13,5:7))/3._r8
    tmax(2)        = sum(DDEP_PAR(14,5:7))/3._r8
    Dmax(2)        = sum(DDEP_PAR(15,5:7))/3._r8
    Dmin(2)        = sum(DDEP_PAR(16,5:7))/3._r8
    RgsSO2(2)      = sum(DDEP_PAR(18,5:7))/3._r8  !// Will be modified below (in-canopy ok, needs EMEP2012)
    RgsO3(2)       = sum(DDEP_PAR(19,5:7))/3._r8
    VEGH(2)        = sum(DDEP_PAR(20,5:7))/3._r8
    dSGS(2)        = sum(DDEP_PAR(21,5:7))/3._r8  !// Start
    dEGS(2)        = sum(DDEP_PAR(22,5:7))/3._r8  !// End
    ddSGS(2)       = sum(DDEP_PAR(23,5:7))/3._r8  !// Latitude dependent change of start (rate)
    ddEGS(2)       = sum(DDEP_PAR(24,5:7))/3._r8 
    !//  3. Moorland (savanna++)
    gmax(3)        = DDEP_PAR(1,8)
    fmin(3)        = DDEP_PAR(2,8)
    phia(3)        = DDEP_PAR(3,8)
    phib(3)        = DDEP_PAR(4,8)
    phic(3)        = DDEP_PAR(5,8)
    phid(3)        = DDEP_PAR(6,8)
    phie(3)        = DDEP_PAR(7,8)
    phif(3)        = DDEP_PAR(8,8)
    phiAS(3)       = DDEP_PAR(9,8)
    phiAE(3)       = DDEP_PAR(10,8)
    flightalpha(3) = DDEP_PAR(11,8)
    tmin(3)        = DDEP_PAR(12,8)
    topt(3)        = DDEP_PAR(13,8)
    tmax(3)        = DDEP_PAR(14,8)
    Dmax(3)        = DDEP_PAR(15,8)
    Dmin(3)        = DDEP_PAR(16,8)
    RgsSO2(3)      = DDEP_PAR(18,8) !// Will be modified below (in-canopy ok, needs EMEP2012)
    RgsO3(3)       = DDEP_PAR(19,8)
    VEGH(3)        = DDEP_PAR(20,8)
    dSGS(3)        = DDEP_PAR(21,8)  !// Start
    dEGS(3)        = DDEP_PAR(22,8)  !// End
    ddSGS(3)       = DDEP_PAR(23,8)  !// Latitude dependent change of start (rate)
    ddEGS(3)       = DDEP_PAR(24,8) 
    !//  4. Grassland
    gmax(4)        = DDEP_PAR(1,9)
    fmin(4)        = DDEP_PAR(2,9)
    phia(4)        = DDEP_PAR(3,9)
    phib(4)        = DDEP_PAR(4,9)
    phic(4)        = DDEP_PAR(5,9)
    phid(4)        = DDEP_PAR(6,9)
    phie(4)        = DDEP_PAR(7,9)
    phif(4)        = DDEP_PAR(8,9)
    phiAS(4)       = DDEP_PAR(9,9)
    phiAE(4)       = DDEP_PAR(10,9)
    flightalpha(4) = DDEP_PAR(11,9)
    tmin(4)        = DDEP_PAR(12,9)
    topt(4)        = DDEP_PAR(13,9)
    tmax(4)        = DDEP_PAR(14,9)
    Dmax(4)        = DDEP_PAR(15,9)
    Dmin(4)        = DDEP_PAR(16,9)
    RgsSO2(4)      = DDEP_PAR(18,9) !// Will be modified below (in-canopy ok, needs EMEP2012)
    RgsO3(4)       = DDEP_PAR(19,9)
    VEGH(4)        = DDEP_PAR(20,9)
    dSGS(4)        = DDEP_PAR(21,9)  !// Start
    dEGS(4)        = DDEP_PAR(22,9)  !// End
    ddSGS(4)       = DDEP_PAR(23,9)  !// Latitude dependent change of start (rate)
    ddEGS(4)       = DDEP_PAR(24,9) 
    !//  5. Wetlands
    gmax(5)        = DDEP_PAR(1,11)
    fmin(5)        = DDEP_PAR(2,11)
    phia(5)        = DDEP_PAR(3,11)
    phib(5)        = DDEP_PAR(4,11)
    phic(5)        = DDEP_PAR(5,11)
    phid(5)        = DDEP_PAR(6,11)
    phie(5)        = DDEP_PAR(7,11)
    phif(5)        = DDEP_PAR(8,11)
    phiAS(5)       = DDEP_PAR(9,11)
    phiAE(5)       = DDEP_PAR(10,11)
    flightalpha(5) = DDEP_PAR(11,11)
    tmin(5)        = DDEP_PAR(12,11)
    topt(5)        = DDEP_PAR(13,11)
    tmax(5)        = DDEP_PAR(14,11)
    Dmax(5)        = DDEP_PAR(15,11)
    Dmin(5)        = DDEP_PAR(16,11)
    RgsSO2(5)      = DDEP_PAR(18,11) !// Will be modified below (in-canopy ok, needs EMEP2012)
    RgsO3(5)       = DDEP_PAR(19,11)
    VEGH(5)        = DDEP_PAR(20,11)
    dSGS(5)        = DDEP_PAR(21,11)  !// Start
    dEGS(5)        = DDEP_PAR(22,11)  !// End
    ddSGS(5)       = DDEP_PAR(23,11)  !// Latitude dependent change of start (rate)
    ddEGS(5)       = DDEP_PAR(24,11) 
    !//  6. Tundra
    gmax(6)        = DDEP_PAR(1,12)
    fmin(6)        = DDEP_PAR(2,12)
    phia(6)        = DDEP_PAR(3,12)
    phib(6)        = DDEP_PAR(4,12)
    phic(6)        = DDEP_PAR(5,12)
    phid(6)        = DDEP_PAR(6,12)
    phie(6)        = DDEP_PAR(7,12)
    phif(6)        = DDEP_PAR(8,12)
    phiAS(6)       = DDEP_PAR(9,12)
    phiAE(6)       = DDEP_PAR(10,12)
    flightalpha(6) = DDEP_PAR(11,12)
    tmin(6)        = DDEP_PAR(12,12)
    topt(6)        = DDEP_PAR(13,12)
    tmax(6)        = DDEP_PAR(14,12)
    Dmax(6)        = DDEP_PAR(15,12)
    Dmin(6)        = DDEP_PAR(16,12)
    RgsSO2(6)      = DDEP_PAR(18,12) !// Will be modified below (in-canopy ok, needs EMEP2012)
    RgsO3(6)       = DDEP_PAR(19,12)
    VEGH(6)        = DDEP_PAR(20,12)
    dSGS(6)        = DDEP_PAR(21,12)  !// Start
    dEGS(6)        = DDEP_PAR(22,12)  !// End
    ddSGS(6)       = DDEP_PAR(23,12)  !// Latitude dependent change of start (rate)
    ddEGS(6)       = DDEP_PAR(24,12) 
    !//  7. Desert
    gmax(7)        = DDEP_PAR(1,13)
    fmin(7)        = DDEP_PAR(2,13)
    phia(7)        = DDEP_PAR(3,13)
    phib(7)        = DDEP_PAR(4,13)
    phic(7)        = DDEP_PAR(5,13)
    phid(7)        = DDEP_PAR(6,13)
    phie(7)        = DDEP_PAR(7,13)
    phif(7)        = DDEP_PAR(8,13)
    phiAS(7)       = DDEP_PAR(9,13)
    phiAE(7)       = DDEP_PAR(10,13)
    flightalpha(7) = DDEP_PAR(11,13)
    tmin(7)        = DDEP_PAR(12,13)
    topt(7)        = DDEP_PAR(13,13)
    tmax(7)        = DDEP_PAR(14,13)
    Dmax(7)        = DDEP_PAR(15,13)
    Dmin(7)        = DDEP_PAR(16,13)
    RgsSO2(7)      = DDEP_PAR(18,13) !// Will be modified below (in-canopy ok, needs EMEP2012)
    RgsO3(7)       = DDEP_PAR(19,13)
    VEGH(7)        = DDEP_PAR(20,13)
    dSGS(7)        = DDEP_PAR(21,13)  !// Start
    dEGS(7)        = DDEP_PAR(22,13)  !// End
    ddSGS(7)       = DDEP_PAR(23,13)  !// Latitude dependent change of start (rate)
    ddEGS(7)       = DDEP_PAR(24,13) 
    !//  8. Water
    gmax(8)        = DDEP_PAR(1,14)
    fmin(8)        = DDEP_PAR(2,14)
    phia(8)        = DDEP_PAR(3,14)
    phib(8)        = DDEP_PAR(4,14)
    phic(8)        = DDEP_PAR(5,14)
    phid(8)        = DDEP_PAR(6,14)
    phie(8)        = DDEP_PAR(7,14)
    phif(8)        = DDEP_PAR(8,14)
    phiAS(8)       = DDEP_PAR(9,14)
    phiAE(8)       = DDEP_PAR(10,14)
    flightalpha(8) = DDEP_PAR(11,14)
    tmin(8)        = DDEP_PAR(12,14)
    topt(8)        = DDEP_PAR(13,14)
    tmax(8)        = DDEP_PAR(14,14)
    Dmax(8)        = DDEP_PAR(15,14)
    Dmin(8)        = DDEP_PAR(16,14)
    RgsSO2(8)      = DDEP_PAR(18,14) !// Will be modified below (in-canopy ok, needs EMEP2012)
    RgsO3(8)       = DDEP_PAR(19,14)
    VEGH(8)        = DDEP_PAR(20,14)
    dSGS(8)        = DDEP_PAR(21,14)  !// Start
    dEGS(8)        = DDEP_PAR(22,14)  !// End
    ddSGS(8)       = DDEP_PAR(23,14)  !// Latitude dependent change of start (rate)
    ddEGS(8)       = DDEP_PAR(24,14)
    !//  9. Urban
    gmax(9)        = DDEP_PAR(1,16)
    fmin(9)        = DDEP_PAR(2,16)
    phia(9)        = DDEP_PAR(3,16)
    phib(9)        = DDEP_PAR(4,16)
    phic(9)        = DDEP_PAR(5,16)
    phid(9)        = DDEP_PAR(6,16)
    phie(9)        = DDEP_PAR(7,16)
    phif(9)        = DDEP_PAR(8,16)
    phiAS(9)       = DDEP_PAR(9,16)
    phiAE(9)       = DDEP_PAR(10,16)
    flightalpha(9) = DDEP_PAR(11,16)
    tmin(9)        = DDEP_PAR(12,16)
    topt(9)        = DDEP_PAR(13,16)
    tmax(9)        = DDEP_PAR(14,16)
    Dmax(9)        = DDEP_PAR(15,16)
    Dmin(9)        = DDEP_PAR(16,16)
    RgsSO2(9)      = DDEP_PAR(18,16) !// Will be modified below (in-canopy ok, needs EMEP2012)
    RgsO3(9)       = DDEP_PAR(19,16)
    VEGH(9)        = DDEP_PAR(20,16)
    dSGS(9)        = DDEP_PAR(21,16)  !// Start
    dEGS(9)        = DDEP_PAR(22,16)  !// End
    ddSGS(9)       = DDEP_PAR(23,16)  !// Latitude dependent change of start (rate)
    ddEGS(9)       = DDEP_PAR(24,16)
    !// 10. Ice+snow treated separately; not used)
    gmax(10)        = DDEP_PAR(1,15)
    fmin(10)        = DDEP_PAR(2,15)
    phia(10)        = DDEP_PAR(3,15)
    phib(10)        = DDEP_PAR(4,15)
    phic(10)        = DDEP_PAR(5,15)
    phid(10)        = DDEP_PAR(6,15)
    phie(10)        = DDEP_PAR(7,15)
    phif(10)        = DDEP_PAR(8,15)
    phiAS(10)       = DDEP_PAR(9,15)
    phiAE(10)       = DDEP_PAR(10,15)
    flightalpha(10) = DDEP_PAR(11,15)
    tmin(10)        = DDEP_PAR(12,15)
    topt(10)        = DDEP_PAR(13,15)
    tmax(10)        = DDEP_PAR(14,15)
    Dmax(10)        = DDEP_PAR(15,15)
    Dmin(10)        = DDEP_PAR(16,15)
    RgsSO2(10)      = DDEP_PAR(18,15) !// Will be modified below (in-canopy ok, needs EMEP2012)
    RgsO3(10)       = DDEP_PAR(19,15)
    VEGH(10)        = DDEP_PAR(20,15)
    dSGS(10)        = DDEP_PAR(21,15)  !// Start
    dEGS(10)        = DDEP_PAR(22,15)  !// End
    ddSGS(10)       = DDEP_PAR(23,15)  !// Latitude dependent change of start (rate)
    ddEGS(10)       = DDEP_PAR(24,15)
    
    !// Initialize SAI0 for all categories
    !// Surface area index is zero for non-vegetated surfaces
    !// Spezial treatment for crops below
    SAI0    = 0._r8
    !// Forests and scrubs
    SAI0(1) = 1._r8
    !// Wetlands
    SAI0(5) = 1._r8

    !// Total NOPS steps used for ASN24H average
    NTOTAL = NRMETD * NROPSM
    RTOTAL = real(NTOTAL, r8)
    
    !// Loop over latitude (J is global, JJ is block)
    !// ------------------------------------------------------------------
    do J = MPBLKJB(MP),MPBLKJE(MP)
      JJ    = J - MPBLKJB(MP) + 1
      
      !// Set latitude dependent vegetation height for forests
      !// The function is based on the latitude based modification 
      !// north of 60deg in Simpson et al. (2012)
      call set_vegetation_height(tempVEGH,YDGRD(J),VEGH(1))
      
      !// Loop over longitude (I is global, II is block)
      !// ------------------------------------------------------------------
      do I = MPBLKIB(MP),MPBLKIE(MP)
        II    = I - MPBLKIB(MP) + 1


        !// Leaf area index: The method applies one-sided LAI.
        !// LAI climatology from ISLSCP2 FASIR is one-sided.
        LAI_IJ = max(0._r8, LAI(I,J,JMON))

        !// SAI = total surface area index of vegetation
        do NN = 1, NLCAT-1
           SAI(NN) = LAI_IJ + SAI0(NN)
        end do
        
        !// MODIFY SAI for crops growth season (Eq.(61) in EMEP2012)
        !// Will have to distinguish between NH and SH
        if (YDGRD(J).gt.0._r8) then
           !// NH dSGS=90, Ls=140, dEGS=270
           if (JDAY .gt. 90 .and. JDAY.le.140) then
              !// Growth season dSGS to dSGS+Ls
              SAI(2) = 5._r8/3.5_r8 * LAI_IJ
           else if (JDAY .gt. 140 .and. JDAY.le.270) then
              !// Growth season dSGS+Ls to dEGS
              SAI(2) = 1.5_r8 + LAI_IJ
           else
              SAI(2) = 0._r8
           end if
        else
           !// SH dSGS=182+90, Ls=182+140, dEGS=182+270
           if (JDAY .gt. 272 .and. JDAY.le.322) then
              SAI(2) = 5._r8/3.5_r8 * LAI_IJ
           else if (JDAY .gt. 322 .and. JDAY.le.366) then
              !// Growth season dSGS+Ls to dEGS - part 1
              SAI(2) = 1.5_r8 + LAI_IJ
           else if (JDAY .gt. 0 .and. JDAY.le.87) then
              !// Growth season dSGS+Ls to dEGS - part 2
              SAI(2) = 1.5_r8 + LAI_IJ
           else
              SAI(2) = 0._r8
           end if
        end if

        !// Meteorolgical variables (from metdata or pbl-routine)
        PrL    = PRANDTLL1(II,JJ,MP) !// Prandtl number
        !//MOL    = MO_LENGTH(II,JJ,MP) !// Obukhov lenght
        USR    = USTR(I,J)           !// Friction velocity
        if (USR .le. 0._r8) USR = 5.e-3_r8 !// USR should not be <=0
        T2M    = SFT(I,J)            !// Surface temperature (2m) [K]
        T2Mcel = T2M - 273.15_r8     !// Surface temperature (2m) [Celcius]
        PSFC   = P(I,J)              !// Surface pressure [hPa]
        PAR_IJ = PPFD(I,J)           !// Photosynthetic active radiation [W/m2]
        SWVL3_IJ = SWVL3(I,J)        !// Soil water content in level 1 [0-1]

        !// Wind at L1 center
        WINDL1  = sqrt(UMS(1,I,J)*UMS(1,I,J) + VMS(1,I,J)*VMS(1,I,J))

        !// Temperature scaling factor for STC
        where (T2Mcel .le. tmin .or. T2Mcel .ge. tmax)
           !// When outside range, the equation may yield NaN, so
           !// a test is necessary. Use lower limit value.
           fstcT2 = 0.01_r8
        elsewhere
           fstcT2 = (T2Mcel - tmin)/(topt - tmin) * &
               ((tmax - T2Mcel)/(tmax - topt))**((tmax-topt)/(topt-tmin))
        end where
        !// Apply lower limit value if needed
        where (fstcT2 .lt. 0.01_r8)
           fstcT2 = 0.01_r8
        end where
       
        !// Saturation partial pressure of water, Rogers and Yau, page 16
        ee = 6.112_r8*exp(17.67_r8 * T2Mcel / (T2Mcel + 243.5_r8))
        !// Use formulas in Rogers and Yau page 17
        RH = max( ee / PSFC * 100._r8, 100._r8)
        !// Compute the vapour pressure deficit
        VPD = ee * (1-RH/100._r8)
        !// fD from Eq. (18) in Simpson et al. Supplement
        fD = fmin + (1-fmin)*(Dmin-VPD)/(Dmin-Dmax)
        !// TODO: Accumulation of water vapor deficit:
        !// desiged to prevent afternoon gsto increasing after a period of morn-
        !// ing water stress, as suggested by Uddling et al. (2004) and LRTAP (2009)
        
        fLight = 1._r8-exp(-flightalpha*PAR_IJ)
        !fLight = 1._r8
        !// Phenomenology from Table S17
        !// Simpson et al. only defined it for northern hemisphere
        !// Therefore we shall skip it for the time being
        if (LGSMAP) then
           call MAPPED_GROWSEASON(JDAY, I, J, GDAY, GLEN)
        else
           call GROWSEASON(JDAY, YDGRD(J), GDAY, GLEN)
        end if
        if (GDAY .eq. 0) then
           fphen = 0._r8
        elseif (GLEN .ge. 365) then
           ! Exclude tropics!
           fPhen = 1._r8
        else
           !fPhen = max(phia, phic)
           where (GDAY .le. phiAS)
              fPhen = phia
           elsewhere (GDAY .le. phiAS+phie)
              fPhen = phib+(phic-phib)*(GDAY-phiAS)/phie
           elsewhere (GDAY .le. GLEN-phiAE-phif)
              fPhen = phic
           elsewhere (GDAY .le. GLEN-phiAE)
              fPhen = phid+(phic-phid)*(GLEN-phiAE-GDAY)/phif
           elsewhere
              fPhen = phid
           end where
        end if
        !// fSW based on soil moisture in the top soil layer (0-7 cm)
        if (SWVL3_IJ .ge. 0.5) then
           fSW = 1._r8
        else
           fSW = 2*SWVL3_IJ
        end if

        !// Stomatal conductance
             
        !// Unit conversion of [mmol s-1 m-2] to [m s-1]:
        !// Ideal gas law Vm = V/n = R * T/P
        !// Factor 1.d-5 derived from unit conversation:
        !// mmol => 1.d-3 mol and 1/hPa => 1.d-2/Pa
        !// Simpson et al. has gmax = gmaxm/41000
        !// This can be off by +/-25%
        gsto = gmax*fPhen*fLight*max(fmin, fstcT2*fD*fSW)
        gsto = gsto*1.d-5*R_UNIV*T2M/PSFC
        
        !// Fraction of water/ocean in gridbox
        !// Not used, will be set below.
        !focean = max(0._r8, 1._r8 - PLAND(I,J))

        !// Acidity ratio to be used for SO2 and NH3
        !// ----------------------------------------
        !// This is based on Equation (8.15) in Simpson etal (2003).
        !// EMEP multiply with 0.6 to take into account unrealistic/sharp
        !// decline NH3 with height in their model.
        !// These are calculated from concentrations, so when mass is input
        !// we need to convert using molecular weights 17/64=0.265625.
        !// Must check for zero NH3 and SO2
        if (LNITRATE .and. LSULPHUR) then
           M_NH3 = BTT(1,trsp_idx(61),II,JJ)
           M_SO2 = BTT(1,trsp_idx(72),II,JJ)
           !// Find Asn (check for zero NH3 and SO2)
           if (M_NH3 .gt. 0._r8) then
              Asn = M_SO2 / M_NH3 * 0.265625_r8
              !// For very tiny NH3, could we get NaN?
              if (Asn .ne. Asn) Asn = 10._r8
           else
              if (M_SO2 .gt. 0._r8) then
                 Asn = 10._r8 !// NH3 is zero, SO2 is not
              else
                 Asn = 0._r8  !// Both NH3 and SO2 are zero
              end if
           end if
           !// Average daily mean
           Asn24 = min(sum(ASN24H(1:NTOTAL,I,J))/RTOTAL, 3._r8)
        else
           !// If not NH3 and SO2 are included in the run, we set Asn and
           !// the daily mean Asn24 from monthly means, produced by an earlier
           !// simulation.
           Asn   = 1._r8     !// = min(ASNCLIM(I,J,JMON), 3._r8)
           Asn24 = 1._r8     !// = Asn
           write(6,'(a)') f90file//':'//subr// &
                ': No nitrate and sulphur; '// &
                'Remove stop in source code if you want to use Asn=1'
           stop
        end if


        !// Set land fractions
        call landfrac2mosaic(FL,NLCAT,landSurfTypeFrac(:,I,J), &
             NVGPAR, YDGRD(J), LANDUSE_IDX)
        
        !// LAI:    Leaf area index (monthly means)
        !// STC:    Stomatal conductance (monthly means)
        !// Rinc:   In-canopy resistance
        !// SAI:    Surface area index (LAI + SAI0)
        !// RgsO3:  Ground surface resistance O3
        !// RgsSO2: Ground surface resistance SO2
        !// VEG_H:  Vegetation height (needed to get Rinc)


        !// Compute the grid-cell-average stomatal conductance
        !// Devide by sum(FL) to be sure that it is normalized!
        !// Skip barren land (same as gmax=0 in EMEP.par)
        Gstc_avg = sum(FL*gsto)/sum(FL)
                        
        !// Rinc = In-canopy resistance = (SAI * VEGH) *  14/Ustar
        do NN = 1, NLCAT-1
           Rinc(NN) = SAI(NN) * VEGH(NN) * 14._r8 / USR
        end do

        !// Find fraction of vegetation types that are snow covered.
        !// Snow cover SD/SDmax, assuming SDmax=VEGH*0.1, as in
        !// Simpson etal (2012, ACP, doi:10.5194/acp-12-7825-2012)
        !// Because SDmax is [m snow] we convert SD from [m water equivalent]
        !// to [m snow] (by multiplying with 10).
        !// Assume that SD do not cover water unless sea ice is present.
        if (PLAND(I,J) .eq. 1._r8) then
           snowD = SD(I,J) * 10._r8
        else if (PLAND(I,J) .gt. 0._r8) then
           if (CI(I,J) .eq. 0._r8) then
              !// Assume snow depth covers only land
              snowD = SD(I,J) / PLAND(I,J) * 10._r8
           else
              if (CI(I,J) .ge. FL(8)) then
                 !// More sea ice than water; should not occur, but we accept
                 !// it for now and assume ocean to be fully covered by ice.
                 snowD = SD(I,J) * 10._r8
              else
                 !// Part of water is ice covered. The part of the gridbox
                 !// which is NOT covered by snow is (focean - CI(I,J)),
                 !// so we adjust snow depth for the covered part.
                 snowD = SD(I,J) / (1._r8 - (FL(8) - CI(I,J))) * 10._r8
              end if
           end if
        else
           !// All is water
           if (CI(I,J) .gt. 0._r8) then
              snowD = SD(I,J) / CI(I,J) * 10._r8 !// Ice covered
           else
              snowD = 0._r8
           end if
        end if

        !// Find snow depth for all vegetation types
        do NN = 1, NLCAT-1
           if (snowD .eq. 0._r8) then
              fsnowC(NN) = 0._r8 !// No snow present
           else
              if (VEGH(NN).eq.0._r8) then
                 !// Snow and zero vegetation height is assumed to be
                 !// snow covered.
                 fsnowC(NN) = 1._r8
              else
                 !// Calculate snow cover for vegetation type
                 fsnowC(NN) = min(1._r8, snowD / (0.1_r8 * VEGH(NN)))
              end if
           end if
        end do
        !// Adjust ocean
        if (FL(8) .gt. 0._r8) fsnowC(8) = min(1._r8, CI(I,J) / FL(8))
        !// Snow land is of course snow covered
        fsnowC(10)= 1._r8

        !// No need to make a gridbox average fsnow

        !// Aerodynamic resistance (Ra)
        !// ----------------------------------------------------------------
        !// Ra can be defined for heat or moisture.
        !//   RaH = rho * Cp * (Tsfc - T(z)) / SHF
        !// where rho=air density, Cp=specific heat of air at constant pressure
        !// Tsfc=temperature at surface, T(z)=temp at hight z,
        !// SHF=sensible heat flux.
        !// This can be rewritten (e.g. Monteith, 1973) to
        !//   RaH = U(Zref)/(Ustar*Ustar)
        !// where U(Zref) is the wind at reference height Zref.

        !// Define reference height as layer 1 midpoint
        Zthick = ZOFLE(2,I,J) - ZOFLE(1,I,J)  !// L1 thickness
        Zref   = 0.5_r8 * Zthick              !// L1 center height
        d = 0.7_r8 !// a constant displacement height

        if (zref .lt. d) then
           write(6,'(a)') f90file//':'//subr//': zref < d: This is WRONG!'
           print*,'zref,d',zref,d
           stop
        end if

        !// Roughness length (z0) will only be used for water surfaces, and
        !// ZOI is zero for these. That said, z0 over water is generally small.
        !// Will distinguish between z0 and z0w anyway.
        !// Do not allow z0 > (zref-d)
        z0   = min(ZOI(I,J,JMON), (Zref - d) * 0.999_r8)

        !// Water roughness lenght
        !// Calm sea: 0.11 * nu / USR, nu=eta/rho=kin.visc. of air (Hinze,1975)
        !//                            here we use 0.135 instead of 0.11.
        !// Rough sea: a * USR^2 / g, where a=0.016 (Charnock, 1955) here 0.018
        !//                           here a=0.018 (Garratt 1992)
        !// Will use wind of 3m/s to separate these.
        !// SFNU = kinematic visc(nu) = mu/density  (m*m/s), found as in PBL:
        !//   SFCD = SFCP/(SFCT*287._r8) ! density (kg/m^3)
        !//   SFMU = 6.2d-8*SFCT    ! abs.visc. 6.2d-8*T (lin fit:-30C to +40C)
        !//   SFNU = SFMU / SFCD    ! kinematic visc(nu) = mu/density  (m*m/s)
        !// or SFNU = 6.2d-8*T2M*T2M*287._r8/(100._r8*PSFC)
        ! Sutherland's law should be used throughout the code instead
        !SFNU  = ( 1.458e-6_r8*T2M**(3/2._r8)/(T2M+110.4_r8)* T2M * R_AIR) / (100._r8 * PSFC)
        SFNU  = (6.2e-8_r8 * T2M * T2M * R_AIR) / (100._r8 * PSFC)
        !z0w = min(0.135_r8*SFNU/USR + 1.83e-3_r8*USR**2, 2.e-3_r8)
        !// Maximum limit of 2mm surface roughness.
        if (WINDL1 .lt. 3._r8) then
           z0w = min(0.135_r8*SFNU/USR, 2.e-3_r8)
        else
           ! So g is 9.836 ms-2
           z0w = min(1.83d-3*USR**2, 2.e-3_r8)
        end if
        !// Wu (J. Phys. Oceanogr., vol.10, 727-740,1980) suggest a correction
        !// to the Charnock relation, but we skip this here.

        !// Set minimum value to avoid division by zero later (Berge, 1990,
        !/  Tellus B, 42, 389407, doi:10.1034/j.1600-0889.1990.t01-3-00001.x)
        if (z0w .le. 0._r8) z0w = 1.5e-5_r8
        if (z0 .le. 0._r8) z0 = 1.5e-5_r8

        !// Calculation of Ra
        !// Because we already have L and Ustar, we instead assume Ra=RaH
        !// from Monteith (1973):
        Ra = WINDL1 / (USR * USR)

        !// Ra in EMEP2012
        !// Simpson etal (2012) calculate L and Ustar, but do not describe Ra.
        !// Their Ustar (Eqn.52) is an expression similar to an equation for
        !// Ra in EMEP2003 (Eqn.4 in Simpson et al, Characteristics
        !// of an ozone deposition module II: Sensitivity analysis,
        !// Water, Air and Soil Pollution, vol. 143, pp 123-137,
        !// doi: 10.1023/A:1022890603066, 2003).
        !// These calculations are based upon three variables
        !//   e1 = (Zref - d) / z0
        !//   e2 = (Zref - d) / MOL
        !//   e3 = z0 / MOL
        !// and Ra is found by
        !//   Ra = (log(e1) - PHIH(e2) + PHIH(e3)) / (USR * VONKARMAN)
        !// This is problematic: When MOL>>z0, the equation would yield
        !// (-PHIH(e2)+PHIH(e3)) < 0, possibly giving Ra<0.
        !// The same applies to EMEP2012 Ustar, so we cannot use that either.



        !// Quasi-laminar resistance (Rb)
        !// ------------------------------------------------------------------
        do KK = 1, NDDEP

           !// Rb is calculated differently for land and ocean, respectively
           !// using Eqn.53 and Eqn.54 in EMEP2012.

           !// Land (cannot be zero due to USR having lower limit)
           rbL = 2._r8 / (VONKARMAN * USR) * (Sc_H20 * D_gas(KK) / PrL )**(2._r8/3._r8)

           !// Ocean (use z0w, not z0)
           D_i = D_H2O / D_gas(KK) !// molecular diffusivity of the gas
           rbO = log(z0w * VONKARMAN * USR / D_i) / (USR * VONKARMAN)
           !// IMPORTANT
           !// RbO can be very large or even negative from this
           !// formula. Negative rbO can come from z0 being very small,
           !// as is often the case over water.
           !// We impose limits:
           rbO = min( 1000._r8, rbO ) !// i.g. min velocity 0.001 m/s
           rbO = max(   10._r8, rbO ) !// i.e. max velocity 0.10 m/s

           !// Make a weighted mean using land fraction (weighting conductances)
           Rb(KK) = 1._r8 / (PLAND(I,J) / rbL  +  (1._r8 - PLAND(I,J)) / rbO)

        end do !// do N = 1, nddep

        !// Surface (or canopy) resistance (Rc)
        !// ----------------------------------------------------------------
        !// Rc is in general calculated as in EMEP2012.
        !//
        !// The general formula for canopy conductances is
        !//   Gc = LAI * gsto + Gns
        !// where LAI is one-sided leaf-area index and gsto is the stomatal
        !// conductance. Gns is the non-stomatal conductance.
        !// These are calculated separately, and Gns is calculated separately
        !// for each land-use type.


        !// Non stomatal conductance Gns - Ozone
        !// ------------------------------------
        !// In EMEP2012, the Gns for O3 is found from
        !//   GnsO3 = SAI/(rext*FT) + 1/(Rinc + RgsO3)
        !// where FT is temperature correction, and we define
        !//   gext = 1/(rext*FT)
        !// representing external leaf-resistance (cuticles+other surfaces),
        !//
        !// Rinc is in-canopy resistance and RgsO3 is ground surface resistance
        !// (soil or other ground cover). Both depend on vegetation type.
        !//
        !// We will calculate this for each land-type (FL).

        !// Important
        !// For a grid box containing different land types FL, with different
        !// vegetations having their own RgsO3, the gridbox average is not
        !// the average of R, but must be calculated from the average G:
        !// R = 1/G. This is because a molecule cannot choose between e.g.
        !// grass or forest, it is either one or the other.
        !// If 20% is grass with R=1000 and 80% is forest with R=200, the
        !// average R = 1/(0.8*1/1000 + 0.2*1/200) = 556, not
        !// 0.8*1000+0.2*200 = 840.


        !// At temperatures below -1C, non-stomatal resistances are increased
        !// (EMEP2012 Eqn.63). Note that the range is 1-2:
        if (T2Mcel .lt. -1._r8) then
           FT = min(2._r8, exp(-0.2_r8*(1._r8 + T2Mcel)))
        else
           FT = 1._r8
        end if

        !// EMEP2012 assumes value for gext, corrected for temperature effects
        gext = 1._r8/(2500._r8 * FT)


        !// Snow cover will increase resistance, and will be taken into
        !// account for each vegetation type below.
        !// A constant resistance of 2000s/m is assumed for O3 on snow, while
        !// SO2 has a smaller resistance which is temperature dependent.
        !// Both are according to EMEP2012.
        !// Rsnow will only be used if snow cover fsnowC(NN)>0
        RsnowO3 = RgsO3(10)
        if (T2Mcel .ge. 1._r8) then
           RsnowSO2 = 70._r8
        else if (T2Mcel .ge. -1._r8) then
           RsnowSO2 = 70._r8 * (2._r8 - T2Mcel)
        else
           RsnowSO2 = 700._r8
        end if


        !// To calculate GnsO3, we calculate it for each land-type as GO3(NN).
        !// Then we correct GO3(NN) for snow cover, and finally find
        !// the gridbox mean GnsO3 from FL and GO3.

        GnsO3 = 0._r8 !// Grid-average GnsO3
        do NN = 1, NLCAT-1

           Rgs = RgsO3(NN) !// Land-type resistance from tabulated values

           !// Snow/temperature correction based on snow cover fraction.
           !// Using 2*fsnow as in EMEP2012 seems weird, because it assumes
           !// range [0-1] for 2*fsnow. This is weirdly explained in Zhang et
           !// al (2003, ACP, doi:10.5194/acp-3-2067-2003.)
           !// We assume fsnow has range [0,1].
           if (fsnowC(NN) .gt. 0._r8) then
              !// Have snow cover
              if (Rgs .gt. 0._r8) then
                 !// The reason for this weighting is that snow cover should
                 !// be weighted against the deposition velocity 1/R; a
                 !// weighting of R (i.e. fsnow*R instead of 1/(fsnow*R))
                 !// would mean that a molecule over snow could chose to
                 !// deposit over non-snow.

                 !// Include temperature correction FT on Rgs
                 Rgs = 1._r8 / ( (1._r8 - fsnowC(NN)) / (FT * Rgs) &
                                 + fsnowC(NN) / RsnowO3 )
              else
                 !// Only Rsnow exist
                 Rgs = RsnowO3/fsnowC(NN)
              end if
           else
              !// No snow cover; only adjust Rgs for tempereature
              Rgs = FT * Rgs
           end if


           !// Add Rinc = (SAI*h) * 14/Ustar.
           !// Rinc is independent of snow. Note that Rinc is zero for
           !// non-vegetated surfaces.
           Rgs = Rgs + Rinc(NN)

           !// GnsO3 for this land type
           !// (GnsO3 = SAI/(rext*FT) + 1/(Rinc + RgsO3)
           GO3(NN) = SAI(NN) * gext
           if (Rgs .gt. 0._r8) GO3(NN) = GO3(NN) + 1._r8 / Rgs

           !// Grid-average GnsO3
           GnsO3 = GnsO3 + FL(NN) * GO3(NN)

        end do

        !// Finally include FL(10) as snow
        if (FL(10) .gt. 0._r8) GnsO3 = GnsO3 + FL(10)/RsnowO3

        !// Zhang etal (2003, ACP, doi:10.5194/acp-3-2067-2003) suggest
        !// night-time value of R=400s/m for non-stomatal conductance,
        !// giving a night-time G=2.5d-3m/s.
        !// However, it is not clear to which value this could be applied,
        !// it could be the vegetated surfaces or total gridbox. I think
        !// our RgsO3 are large enough in any case, so we skip this.

        !// Stomatal part of canopy conductance - Ozone
        !// -------------------------------------------
        !// As defined above, this is given by LAI * gsto.

        !// This is the usual big-leaf method to calculate canopy stomatal
        !// conductance from leaf stomatal contuctance, where gsto is the
        !// latter.

        !// gsto is estimated in EMEP parameterization, for each vegetation type, and
        !// above the average conductance Gstc_avg was calculated from this.
        !// The estimated canopy stomatal conductance is then:
        !//GstO3 = LAI_IJ * Gstc_avg <- THIS IS WRONG AND NEEDS TO BE CORRECTED!!!
        !// where the vegetation fractions are taken into account.
        !//
        GstO3 = LAI_IJ*Gstc_avg
        !//
        !// Total canopy conductance for O3
        GcO3 = GstO3 + GnsO3
        !// Total canopy resistance for O3
        if (GcO3 .gt. 0._r8) then
           Rc(1) = 1._r8 / GcO3
        else
           !// This should never happen because RgsO3 was defined for all
           !// land-use types. But I include it anyway.
           write(6,'(a)') f90file//':'//subr//': VERY WRONG: GnsO3 ZERO/NEGATIVE!!!'
           print*,GstO3,GnsO3,PAR_IJ,PARMEAN(I,J,JMON),fstcT2
           do NN = 1, NLCAT
              write(6,'(i2,3es12.3)') NN,GO3(NN),FL(NN),fsnowC(NN)
           end do
           stop
        end if
        




        !// Non-stomatal conductance Gns - SO2
        !// ----------------------------------

        !// For SO2 we distinquish between vegetative and non-vegetative
        !// surfaces. RgsSO2 was listed above for non-vegetative categories,
        !// so we need to define it for the vegetated surfaces.
        !//
        !// We apply the EMEP2012 method; the earlier EMEP2003 is assumed
        !// to be outdated, otherwise EMEP would have stuck to it.
        !// EMEP2003
        !// Reference: Simpson et al, Characteristics of an ozone deposition
        !// module II: Sensitivity analysis,
        !// Water, Air and Soil Pollution, vol. 143, pp 123-137,
        !// doi: 10.1023/A:1022890603066, 2003.


        !// EMEP2012
        !// The Simpson etal (2012) treatment applies a 24h mean of Asn,
        !// and is an empirical fit for vegetated surfaces.
        !// Non-vegetated surfaces are done with standard table values
        !// for RgsSO2.


        !// Only loop through vegetative categories
        do NN = 1, 4

           !// EMEP2012 --->
           if (RH .eq. 0._r8) then
              Rgs = 1000._r8 !// To avoid infinity
           else
              Rgs = 11.84_r8 * exp(1.1_r8 * ASN24) * RH**(-1.67_r8)
              Rgs = max(Rgs, 10._r8)
              Rgs = min(Rgs, 1000._r8)
           end if
           !// Override for cold temperatures
           if (T2Mcel .le. -5._r8) then
              Rgs = 500._r8
           else if (T2Mcel .gt. -5._r8 .and. T2Mcel.le.0._r8) then
              Rgs = 100._r8
           end if
           !// Snow correction, not temperature correction:
           !// No temperature correction for SO2 on vegetated surfaces!
           if (fsnowC(NN) .gt. 0._r8) then
              !// See O3 for explanation
              !// Skip FT for SO2 when using EMEP2012 vegetated surfaces
              if (Rgs .gt. 0._r8) then
                 Rgs = 1._r8 / ( (1._r8 - fsnowC(NN)) / Rgs &
                                + fsnowC(NN) / RsnowSO2 )
              else
                 Rgs = RsnowSO2 / fsnowC(NN)
              end if
           else
              !// Skip FT for SO2 when using EMEP2012 vegetated surfaces
              Rgs = Rgs
           end if
           GSO2(NN) = 1._r8 / Rgs
           RgsSO2(NN) = Rgs !// Not necessary (not used further down)
           !// EMEP2012 <---
        end do


        !// Only loop through non-vegetative categories
        do NN = 5, NLCAT-1

           Rgs = RgsSO2(NN) !// Land-type resistance

           !// Snow/temperature correction (EMEP2012)
           if (fsnowC(NN) .gt. 0._r8) then
              !// See O3 for explanation
              if (Rgs .gt. 0._r8) then
                 Rgs = 1._r8 / ( (1._r8 - fsnowC(NN)) / (FT * Rgs) &
                                + fsnowC(NN) / RsnowSO2 )
              else
                 Rgs = RsnowSO2 / fsnowC(NN)
              end if
           else
              Rgs = FT * Rgs
           end if

           !// Do *NOT* update RgsSO2 here, only GSO2 for this land type
           if (Rgs .gt. 0._r8) then
              GSO2(NN) =  1._r8 / Rgs
           else
              GSO2(NN) = 0._r8
           end if

        end do

        !// Gridbox average GnsSO2 (all categories)
        GnsSO2 = 0._r8
        do NN = 1, NLCAT-1
           GnsSO2 = GnsSO2 + FL(NN) * GSO2(NN)
        end do
        !// Include FL(10) as snow
        if (FL(10) .gt. 0._r8) GnsSO2 = GnsSO2 + FL(10)/RsnowSO2


        !// Now we have Rc for SO2
        if (GnsSO2 .gt. 0._r8) then
           Rc(2) = 1._r8 / GnsSO2
        else
           !// This should not happen, I think GSO2 has values for all
           !// land-use types. But I include it anyway.
           write(6,'(a)') f90file//':'//subr// &
                ': VERY WRONG: GnsSO2 ZERO/NEGATIVE!!!'
           print*,GSO2
           print*,fsnowC
           stop
        end if




        !// Non-stomatal conductance Gns - Other gases
        !// ------------------------------------------
        !// Other gases Gns is obtained by interpolating between values for
        !// O3 and SO2, using solubility (Hstar) and reactivity indes (f0)
        !// from Wesely (1989), applied directly to non-stomatal
        !// conductances. This is calculated as Eqn.66 in EMEP2012.

        !// NH3 (KK=ndep) will be done separately below.
        !// HNO3 (KK=4) will be reset below.
        do KK = 3, nddep-1

           !// Use total GnsSO2 and GcO3 in interpolation to other gases.
           !// Another possibility is to do this for each vegetation
           !// category, but there should be no need to do that yet.
           Rc(KK) = 1._r8 / (1.e-5_r8 * Hstar(KK) * GnsSO2 + f0(KK) * GcO3)

        end do




        !// HNO3
        !// ----
        !// HNO3 normal conditions the surface resistance are effectively 0.
        !// Assume lower limit to be 1 (i.e. old CTM scheme for HNO3).
        !// EMEP2012 use a different RclowHNO3, namely 10s/m.
        !// They also use Ts, surface temperature, but I understand that as
        !// 2m temperature.
        Rc(4) = max(1._r8, -2._r8*T2Mcel)




        !// Nitrate - NH3
        !// -------------
        if (LNITRATE) then

           !// Stomatal conductance of NH3: Not yet taken into account.
           !// During growth season, crop fields are basically emitters of
           !// NH3, and do not take up NH3. For crop fields, the Rc should
           !// thus be high.

           !// Non-stomatal conductance (Section 8.6.2 in EMEP2012)
           !// In Simpson etal (2012) the cold values have been halved
           !// from 1000/200 to 500/100 compared to EMEP2003, so we use these
           if (T2M .le. 268._r8) then
              !// Cold temperatures (T<-5C)
              Rc(14) = 500._r8
           else if  (T2M .gt. 268._r8 .and. T2M .le. 273._r8 ) then   
              !// Just below 0C (-5C<T<0C)
              Rc(14) = 100._r8
           else
              !// Above 0C.
              !// Equation uses temperature in C, not K.
              Rc(14) = 0.0455_r8 * 10._r8 * log10(T2Mcel + 2._r8) &
                       * exp((100._r8 - RH)/7._r8) &
                       * 10._r8**(-1.1099_r8 * Asn + 1.6769_r8)
              !// Impose some limits on Rc (EMEP2012)
              Rc(14) = min( 200.0,Rc(14))
              Rc(14) = max(  10.0,Rc(14))
           end if
        end if


        !// Calculate deposition velocity
        !// ----------------------------------------------------------------
        do KK = 1, nddep
           Tot_res = Ra + Rb(KK) + Rc(KK)
           if (Tot_res .ne. Tot_res) then
              write(6,'(a,i3,3es9.3)') f90file//':'//subr// &
                   ': Total resistance is NAN!', KK,Ra,Rb(KK),Rc(KK)
              stop
           end if
 
           !// Unit is m/s
           if (Tot_res .gt. 0._r8) then
              VD(KK) = 1._r8 / Tot_res
           else
              !// Fail-safe check
              write(6,'(a,i3,4es9.3)') f90file//':'//subr// &
                   ': Tot_res is zero/negative/nan!',&
                      KK, Tot_res, Ra, Rb(KK), Rc(KK)
              stop
           end if
        end do


        !// Assign to IJ-block values [m/s]
        VO3(II,JJ)     = VD(1)
        VSO2(II,JJ)    = VD(2)
        VNO(II,JJ)     = VD(3)
        VHNO3(II,JJ)   = VD(4)
        VH2O2(II,JJ)   = VD(5)
        VCH3CHO(II,JJ) = VD(6)
        VHCHO(II,JJ)   = VD(7)
        VPAN(II,JJ)    = VD(8)
        VNO2(II,JJ)    = VD(9)
        VNH3(II,JJ)    = VD(14)
        !//Leaf level stomatal conductance
        !//It is, however, not clear whether canopy conductance (GstO3) 
        !//should be used here (Emberson et al. 2000).
        !//Multiply with ozone concentration yields stomatal flux.
        !//unit [mmol m-2s-1]
        VSto(II,JJ)    = Gstc_avg/(1.d-5*R_UNIV*T2M/PSFC)
     end do !// do I = MPBLKIB(MP),MPBLKIE(MP)
    end do !// do J = MPBLKJB(MP),MPBLKJE(MP)

    !// --------------------------------------------------------------------
  end subroutine get_vdep2
  !// ----------------------------------------------------------------------




  !// ----------------------------------------------------------------------
  subroutine get_STC()
    !// --------------------------------------------------------------------
    !// Read monthly averaged STC from file.
    !// Called from update_drydepvariables.
    !//
    !// Amund Sovde, December 2013
    !// --------------------------------------------------------------------
    use cmn_ctm, only: XDEDG, YDEDG, AREAXY
    use cmn_parameters, only: A0, CPI180
    use cmn_met, only: MYEAR
    use regridding, only: E_GRID
    use ncutils, only: get_netcdf_var_1d, get_netcdf_var_3d
    !// --------------------------------------------------------------------
    implicit none
    !// --------------------------------------------------------------------
    !// Locals
    integer,parameter :: IRES=360, JRES=150,J1x1=180
    real(r8),dimension(IRES,JRES,12) :: indata
    real(r8),dimension(IRES,J1x1,12) :: inSTC
    real(r8) :: YBGRD(J1x1),YBEDGE(J1x1+1),XBEDGE(IRES+1),XYBOX(J1x1)
    real(r8) :: RIN(IRES,J1x1), R8CTM(IPAR,JPAR)

    character(len=80) :: filename,variable
    INTEGER            :: status, ncid
    INTEGER            :: nLon, nLat, nLev, nTime, I, J, M
    CHARACTER(LEN=4)  :: cyear
    REAL(r8), ALLOCATABLE, DIMENSION(:) :: inLon, inLat, inTime
    !// --------------------------------------------------------------------

    !// Hard-coded choice on climatology or year-specific STC
    !// write(cyear(1:4),'(i4.4)') MYEAR
    !// filename = 'Indata_CTM3/DRYDEP/mcond_'//cyear//'.nc'
    !// variable = 'mcan_cond_tot'
    filename = 'Indata_CTM3/DRYDEP/stc_climmean_1997-2006.nc'
    variable = 'STC'

    !// Check resolution (latitude/longitude/time)
    !// This routine allocates inLon/inLat/inTime
    call get_netcdf_var_1d( filename, 'lon',  inLon  )
    call get_netcdf_var_1d( filename, 'lat',  inLat  )
    call get_netcdf_var_1d( filename, 'time', inTime )

    !// Assign non-standard latitudes
    YBGRD(31:J1x1) = inLat(:)
    !// Latitudes for the southern gridboxes not included on file
    do J = 30, 1, -1
       YBGRD(J) = YBGRD(J+1) - 1._r8
    end do

    nLon  = SIZE( inLon  )
    nLat  = SIZE( inLat  )
    nTime = SIZE( inTime )

    !// Deallocate all local variables
    IF ( ALLOCATED(inLon) ) DEALLOCATE(inLon)
    IF ( ALLOCATED(inLat) ) DEALLOCATE(inLat)
    IF ( ALLOCATED(inTime) ) DEALLOCATE(inTime)

    if (nLon.ne.IRES .or. nLat.ne.JRES) then
       write(6,'(a)') '* Horizontal resolution on file does not match specified resolution'
       write(6,'(a)') '  File: '//trim(filename)
       write(6,'(a,2(i5))') '  Specified:',IRES,JRES
       write(6,'(a,2(i5))') '  On file:  ',nLon,nLat
       stop
    end if


    call get_netcdf_var_3d( filename, variable, indata, nlon,nlat,ntime )

    inSTC(:,:,:) = 0._r8
    do M = 1, 12
       do J = 1, JRES
          do I = 1, IRES
             if (indata(I,J,M) .lt. 0._r8) then
                inSTC(I,J+30,M) = 0._r8
             else    
                !// Unit on files are reported as [(mm/s)/m^2], which is weird
                !// since STC is usually either [mm/s] or  [(mmol/m^2)/s].
                !// Values range from 0-11, so based on web search it fits
                !// with [mm/s].
                !// With this assumption we change to [m/s]
                inSTC(I,J+30,M) = indata(I,J,M)*1.e-3_r8

                !// Unit conversion of mmol/s/m2 to m/s (not necessary here):
                !// At 273K and 1013.25hPa, molar density of a gas
                !// is 44.6mol/m3.
                !// From Boyle-Charles law we can find the value at 293K,
                !// giving get n/V = 44.6mol/m3 * 273/293 ~= 41mol/m3.
                !// To get m/s we then have to multiply by 1.d-3/41.
             end if
          end do
       end do
    end do

    !// Interpolate
    !// Set up x-edges (field grid is 0-1,1-2,..)
    XBEDGE(1) = 0.5_r8
    do I = 2, IRES+1
       XBEDGE(I) = XBEDGE(I-1) + 1._r8
    end do

    !// Set up y-edges; assume halfway between grid box centers
    YBEDGE(J1x1+1) = 90._r8
    do J = J1x1, 2, -1
       YBEDGE(J) = 0.5_r8 * (YBGRD(J) + YBGRD(J-1))
    end do
    YBEDGE(1) = -90._r8


    !// Grid box areas
    do J = 1, J1x1
       XYBOX(J) =  A0*A0 * CPI180*(XBEDGE(2)-XBEDGE(1)) &
            * (sin(CPI180*YBEDGE(J+1)) - sin(CPI180*YBEDGE(J)))
    end do

    do M = 1, 12
       !// Multiply with area
       do J = 1, J1x1
          RIN(:,J) = inSTC(:,J,M) * XYBOX(J)
       end do
       call E_GRID(RIN(:,:),XBEDGE,YBEDGE,IRES,J1x1, &
                  R8CTM,XDEDG,YDEDG,IPAR,JPAR,1)

       STC(:,:,M) = R8CTM(:,:) / AREAXY(:,:)
    end do

    write(6,'(a,2es12.5)') '* Min/Max STC on file:     ', &
         minval(inSTC),maxval(inSTC)
    write(6,'(a,2es12.5)') '* Min/Max STC interpolated:', &
         minval(STC),maxval(STC)
    !// --------------------------------------------------------------------
  end subroutine get_STC
  !// ----------------------------------------------------------------------

  !// ----------------------------------------------------------------------
  subroutine get_PPFD(NMET, DTMET)
    !// --------------------------------------------------------------------
    !// Read photsynthetic photon flux density (PPFD) from file.
    !// PPFD is deaccumulated PAR from OpenIFS data.
    !// Called from update_drydepvariables.
    !//
    !// Stefanie Falk, July 2018
    !// --------------------------------------------------------------------
    use cmn_precision, only: r8, r4
    use cmn_ctm, only: JYEAR, JMON, JDAY, JDATE, NRMETD, &
         ZDEGI, ZDEGJ, IMAP, JMAP
    use cmn_size, only: IPARW, JPARW, &
         IPAR, JPAR, IDGRD, JDGRD
    use cmn_met, only: PPFD, PPFDPATH, PPFDFILE, MYEAR, metTYPE
    use regridding, only: TRUNG8
    use ncutils, only: get_netcdf_var_2d, get_netcdf_var_3d
    !//---------------------------------------------------------------------
    implicit none
    !//---------------------------------------------------------------------
    !// Input
    integer, intent(in) :: NMET       ! the meteorological timestep
    real(r8), intent(in) :: DTMET     ! meteorological time step [s]
    !//---------------------------------------------------------------------
    logical, parameter :: VERBOSE = .false.
    !// Local parameters
    real(r8) :: ZDT
    !// To be read from file
    logical :: fex
    !// Filename for metdata
    character(len=160) :: FNAME, FNAME_NEXT
    character(len=2) :: CMON, CDATE, CUTC
    character(len=4) :: MPATH2
    integer :: NMET_NEXT

    !//---------------------------------------------------------------------
    !// Allocatable arrays - double precision
    real(r8), dimension(:,:), allocatable :: W2D, R8XY
        
    !// --------------------------------------------------------------------
    character(len=*), parameter :: subr = 'get_PPFD'
    !//---------------------------------------------------------------------
 
    !// Allocate 2D arrays - native resolution
    allocate( W2D(IPARW,JPARW) )
    !// Allocate 2D arrays - window resolution (IPAR/JPAR)
    allocate( R8XY(IPAR,JPAR) )

    !// File name for this DAY/NMET
    write(CUTC(1:2),'(i2.2)') (NMET - 1) * 24/NRMETD  ! Time UTC
    write(CDATE(1:2),'(i2.2)') JDATE                  ! Date
    write(CMON(1:2),'(i2.2)') JMON                    ! Month
    write(MPATH2(1:4),'(i4.4)') MYEAR                 ! Year

    if (trim(metTYPE) .eq. 'ECMWF_oIFSnc4') then
       !// ECMWF Open IFS netcdf4 file
       !// Date yYYYYmMMdDDhHH
       !// Filename: ECopenIFSc38r1_yYYYYmMMdDDhHH_T159N80L60.nc
       write(PPFDFILE(16:29),'(a1,i4.4,a1,i2.2,a1,a2,a1,a2)') &
            'y',MYEAR,'m',JMON,'d',CDATE,'h',CUTC

       FNAME  = trim(PPFDPATH)//trim(MPATH2)//'/'//CMON//'/'// &
            trim(PPFDFILE)//'.nc'
    else
       write(6,'(a)') f90file//':'//subr// &
            ': Not set up for metTYPE: '//trim(metTYPE)
       if (trim(metTYPE) .eq. 'ECMWF_oIFS') then
          write(6,'(a)') '* If you do not want netcdf4 files, you '// &
               'should use metdata_ecmwf_uioformat.f90 instead'
       end if
       stop
    end if

    !// Check if files exist
    inquire(FILE=trim(FNAME), exist=fex)
    if (.not. fex) then
       write(6,'(a)') f90file//':'//subr// &
            ': No such file: '//trim(FNAME)
       stop
    end if
    !// Photosynthetically active radiation @ sfc (PhotActRad) (accumulated)
    !// --------------------------------------------------------------------
    !// Unit: (W/m2)*s, accumulated. Divide by ZDT to get W/m2.
    call get_netcdf_var_2d(FNAME, 'PPFD',W2D, IPARW, JPARW)
    call TRUNG8(W2D, R8XY, ZDEGI, ZDEGJ, IMAP, JMAP, IDGRD, &
         JDGRD, IPARW, JPARW, IPAR, JPAR, 1, 1)
    PPFD(:,:) = max(0._r8, R8XY(:,:))  !// Limit to positive values (* ZDT)
    if (verbose) call gotData('2da','Photosyn. Photon flux dens. (PPFD)')
    !// --------------------------------------------------------------------
  end subroutine get_PPFD
  !// ----------------------------------------------------------------------

  !// ----------------------------------------------------------------------
  subroutine get_PARMEAN()
    !// --------------------------------------------------------------------
    !// Read monthly averaged photsynthetic active radiation (PAR) from file.
    !// Called from update_drydepvariables.
    !//
    !// Amund Sovde, December 2013
    !// --------------------------------------------------------------------
    use cmn_ctm, only: XDEDG, YDEDG, AREAXY
    use cmn_parameters, only: A0, CPI180
    use cmn_met, only: MYEAR
    use regridding, only: E_GRID
    use ncutils, only: get_netcdf_var_1d, get_netcdf_var_3d
    !// --------------------------------------------------------------------
    implicit none
    !// --------------------------------------------------------------------
    !// Locals
    integer,parameter :: IRES=128, JRES=64
    real(r8),dimension(IRES,JRES,12) :: indata
    real(r8) :: YBEDGE(JRES+1),XBEDGE(IRES+1),XYBOX(JRES)
    real(r8) :: RIN(IRES,JRES), R8CTM(IPAR,JPAR)

    character(len=80) :: filename,variable
    INTEGER            :: status, ncid
    INTEGER            :: nLon, nLat, nLev, nTime, I, J, M
    CHARACTER(LEN=4)  :: cyear
    REAL(r8), ALLOCATABLE, DIMENSION(:) :: &
         inLon, inLat, inTime, inLonE, inLatE
    !// --------------------------------------------------------------------

    !// Hard-coded choice on climatology or year-specific PAR
    !// write(cyear(1:4),'(i4.4)') MYEAR
    !// filename = 'Indata_CTM3/DRYDEP/par_mean_'//cyear//'.nc'
    filename = 'Indata_CTM3/DRYDEP/par30T_climmean_1997-2010.nc'
    write(6,'(a)') '* Reading monthly PAR from: '
    write(6,'(a)') '  '//trim(filename)

    variable = 'PAR'

    !// Check resolution (latitude/longitude/time)
    !// This routine allocates inLon/inLat/inTime
    call get_netcdf_var_1d( filename, 'lon',  inLon  )
    call get_netcdf_var_1d( filename, 'lat',  inLat  )
    call get_netcdf_var_1d( filename, 'time', inTime )

    nLon  = SIZE( inLon  )
    nLat  = SIZE( inLat  )
    nTime = SIZE( inTime )


    if (nLon.ne.IRES .or. nLat.ne.JRES) then
       write(6,'(a)') '* Horizontal resolution on file does not match specified resolution'
       write(6,'(a)') '  File: '//trim(filename)
       write(6,'(a,2(i5))') '  Specified:',IRES,JRES
       write(6,'(a,2(i5))') '  On file:  ',nLon,nLat
       stop
    end if

    !// get lon/lat edges
    call get_netcdf_var_1d( filename, 'lonedge',  inLonE  )
    call get_netcdf_var_1d( filename, 'latedge',  inLatE  )

    call get_netcdf_var_3d( filename, variable, indata, nlon,nlat,ntime )

    if (IPAR .eq. IRES) then
       !// No need to interpolate
       do M = 1, 12
          do J = 1, JPAR
             do I = 1, IPAR
                PARMEAN(I,J,M) = indata(i,j,m)
             end do
          end do
       end do
    else
       !// Interpolate from T42
       do I = 1, IRES+1
          XBEDGE(I) = inLonE(I)
       end do
       do J = 1, JRES+1
          YBEDGE(J) = inLatE(J)
       end do
       !// Grid box areas
       do J=1,JRES
          XYBOX(J) =  A0*A0 * CPI180*(XBEDGE(2)-XBEDGE(1)) &
               * (sin(CPI180*YBEDGE(J+1)) - sin(CPI180*YBEDGE(J)))
       end do

       do M = 1, 12
          !// Multiply with area
          do J = 1, JRES
             RIN(:,J) = indata(:,J,M) * XYBOX(J)
          end do
          call E_GRID(RIN(:,:),XBEDGE,YBEDGE,IRES,JRES, &
               R8CTM,XDEDG,YDEDG,IPAR,JPAR,1)
          PARMEAN(:,:,M) = R8CTM(:,:) / AREAXY(:,:)
       end do

    end if


    !// Deallocate all local variables
    IF ( ALLOCATED(inLon) ) DEALLOCATE(inLon)
    IF ( ALLOCATED(inLat) ) DEALLOCATE(inLat)
    IF ( ALLOCATED(inTime) ) DEALLOCATE(inTime)
    IF ( ALLOCATED(inLonE) ) DEALLOCATE(inLonE)
    IF ( ALLOCATED(inLatE) ) DEALLOCATE(inLatE)

    write(6,'(a,2f12.3)') '* Got PARMEAN min/max:',minval(PARMEAN),maxval(PARMEAN)
    !// --------------------------------------------------------------------
  end subroutine get_PARMEAN
  !// ----------------------------------------------------------------------


  !// ----------------------------------------------------------------------
  subroutine get_asn24h(NDAYI,NDAY,NMET,NOPS)
    !// --------------------------------------------------------------------
    !// Get Asn=SO2/NH3 for all time steps (NOPS), used to calculate
    !// daily mean Asn for SO2 dry deposition.
    !//
    !// Amund Sovde, January 2014
    !// --------------------------------------------------------------------
    use cmn_size, only: LNITRATE, LSULPHUR
    use cmn_ctm, only: STT, NRMETD, NROPSM
    use cmn_oslo, only: trsp_idx
    !// --------------------------------------------------------------------
    implicit none
    !// --------------------------------------------------------------------
    integer, intent(in) :: NDAYI,NDAY,NMET,NOPS
    integer :: I,J, HR, NTOTAL, NDSTEP, IMOD
    real(r8) :: Asn, M_SO2, M_NH3
    !// --------------------------------------------------------------------

    !// Check for NH3 and SO2
    if (.not. (LNITRATE .and. LSULPHUR)) return

    !// Total NOPS steps
    NTOTAL = NRMETD * NROPSM

    if (NDAY.eq.NDAYI .and. NMET.eq.1.and.NOPS.eq.1) then
       !// Initialize all 24 hours at first time step.
       !// Max daily average is set to 3, so we set this as max for all
       !// 24 hours here.
       do J = 1, JPAR
          do I = 1, IPAR
             M_NH3 = STT(I,J,1,trsp_idx(61))
             M_SO2 = STT(I,J,1,trsp_idx(72))
             if (M_NH3 .eq. 0._r8) then
                if (M_SO2 .gt. 0._r8) then
                   Asn=3._r8
                else
                   Asn = 0._r8
                end if
             else
                !// Convert to molar ratio using molecular weights
                !// 17/64=0.265625.
                Asn = min(M_SO2/M_NH3*0.265625_r8, 3._r8)
             end if
             ASN24H(1,I,J) = Asn
             !// Copy to the other time steps
             do HR = 2, NTOTAL
                ASN24H(HR,I,J) = ASN24H(1,I,J)
             end do
             do HR = NTOTAL+1, ASN24H_MAX_STEPS
                ASN24H(HR,I,J) = 0._r8 !// Not necessary
             end do
          end do
       end do
    end if


    !// This step
    NDSTEP = (NMET - 1)*NROPSM + (NOPS - 1) + 1

    !// For hour-to-hour Asn, we set a maximum value to 10.
    do J = 1, JPAR
       do I = 1, IPAR

          M_NH3 = STT(I,J,1,trsp_idx(61))
          M_SO2 = STT(I,J,1,trsp_idx(72))
          !// Convert to molar ratio using molecular weights 17/64=0.265625
          if (M_NH3 .gt. 0._r8) then
             !// Not larger than max limit
             Asn = max(M_SO2 / M_NH3 * 0.265625_r8, 10._r8)
             !// For very tiny NH3, could we get NaN?
             if (Asn .ne. Asn) Asn = 10._r8
          else
             if (M_SO2 .gt. 0._r8) then
                Asn = 10._r8 !// NH3 is zero, SO2 is not
             else
                Asn = 0._r8  !// Both NH3 and SO2 are zero
             end if
          end if

          ASN24H(NDSTEP,I,J) = Asn

       end do
    end do

    !// --------------------------------------------------------------------
  end subroutine get_asn24h
  !// ----------------------------------------------------------------------




  !// ----------------------------------------------------------------------
  subroutine aer_vdep2(VDEP,SCALESTABILITY,MP)
    !// --------------------------------------------------------------------
    !// Set dry deposition for aerosols, in a given IJ-block.
    !// Called from subroutine setdrydep.
    !// This method is based on the treatment in EMEP model, Simpson etal
    !// (2012), ACP, doi:10.5194/acp-12-7825-2012, refered to as EMEP2012
    !// in this routine.
    !//
    !// Amund Sovde, February 2014
    !// --------------------------------------------------------------------
    use cmn_size, only: NPAR, IPAR, JPAR, LSULPHUR, LNITRATE, LSOA
    use cmn_ctm, only:  JMON, MPBLKJB, MPBLKJE, MPBLKIB, MPBLKIE, &
         YDGRD, PLAND
    use cmn_met, only: PRECLS, PRECCNV, MO_LENGTH, USTR, SFT, CI, SD, &
         CLDFR
    use cmn_sfc, only: landSurfTypeFrac, LANDUSE_IDX, NVGPAR, LAI
    use cmn_oslo, only: trsp_idx
    use soa_oslo, only: ndep_soa, soa_deps
    use utilities_oslo, only: landfrac2mosaic, set_vegetation_height
    !// --------------------------------------------------------------------
    implicit none
    !// --------------------------------------------------------------------
    !// Input
    integer, intent(in) :: MP
    !// Output
    real(r8), intent(inout) :: VDEP(NPAR,IPAR,JPAR)
    integer, intent(inout) :: SCALESTABILITY(NPAR)

    !// Locals
    integer :: I,II,J,JJ,N, K, NN
    real(r8) :: SAI1, MOL, USR, RAIN, T2M, &
         a1L, a1W, a1I, a1Lfor, amol, amolN, Vtot, WETFRAC, fice, snowD
    real(r8) :: tempVEGH
    integer, parameter :: NLCAT=10
    real(r8),dimension(NLCAT) :: FL, VD, VEGH, fsnowC

    !// Ustar mean for year 2006 0.293m = 29.3cm
    !real(r8), parameter :: ZmeanUSR = 1._r8/29.3_r8
    !// --------------------------------------------------------------------
    character(len=*), parameter :: subr = 'aer_vdep2'
    !// --------------------------------------------------------------------

    !// Return if there are no aerosol packages (ONLY sulphur and nitrate
    !// for now)
    if (.not.(LSULPHUR .or. LNITRATE .or. LSOA)) return

    !// EMEP categories
    !//  1. Forrests, Mediterranean scrub
    !//  2. Crops
    !//  3. Moorland (savanna++)
    !//  4. Grassland
    !//  5. Wetlands
    !//  6. Tundra
    !//  7. Desert
    !//  8. Water
    !//  9. Urban
    !// 10. Ice+snow (strictly, EMEP has this as category 9 and urban as 10)
    !// Vegetation heights
    VEGH(1)  = 0._r8  !// Will be modified below 
    tempVEGH = (sum(DDEP_PAR(20,1:4))+DDEP_PAR(20,10))/5._r8 
    VEGH(2)  = sum(DDEP_PAR(20,5:7))/3._r8
    VEGH(3)  = DDEP_PAR(20,8)
    VEGH(4)  = DDEP_PAR(20,9)
    VEGH(5)  = DDEP_PAR(20,11)
    VEGH(6)  = DDEP_PAR(20,12)
    VEGH(7)  = DDEP_PAR(20,13)
    VEGH(8)  = DDEP_PAR(20,14)
    VEGH(9)  = DDEP_PAR(20,16)
    VEGH(10) = 0._r8

    !// Loop over latitude (J is global, JJ is block)
    do J = MPBLKJB(MP),MPBLKJE(MP)
      JJ    = J - MPBLKJB(MP) + 1
      
      !// Set latitude dependent vegetation height for forests
      call set_vegetation_height(tempVEGH,YDGRD(J),VEGH(1))
      
      !// Loop over longitude (I is global, II is block)
      do I = MPBLKIB(MP),MPBLKIE(MP)
        II    = I - MPBLKIB(MP) + 1

        !// Basis of method:
        !//   Vd/USTAR = a1
        !//   a1=0.002 (Wesely, 1985)
        !//     for Obukhov length L<0 also multiply with (1 + (-300/L)^(2/3))
        !//     with limit 1/L>-0.04; L<-25m
        !//   Forests: a1=0.008 SAI/10
        !// Instead we find a1 from our deposition velocities and assume
        !// they apply to the mean USTAR, which is 0.293m.

        !// Method needs surface area index for forests, i.e. LAI+1:
        SAI1 = max(0._r8, LAI(I,J,JMON)) + 1._r8

        !// Meteorological parameters
        RAIN = PRECLS(I,J,1) + PRECCNV(I,J,1) !// Rain at surface
        T2M = SFT(I,J)                        !// Surface (2m) temperature
        MOL    = MO_LENGTH(II,JJ,MP)          !// Obukhov lenght
        USR    = USTR(I,J)                    !// Friction velocity
        if (USR .le. 0._r8) USR = 5.e-3_r8    !// USR should not be <=0

        !// Adjustment for negative Obukhov length
        if (MOL .lt. 0._r8) then
           !// Restriction: 1/L> -0.04, i.e. L<-25.
           if (MOL.le.-25._r8) then
              amol = 1._r8 + (-300._r8/MOL)**(2._r8/3._r8)
           else
              !// -300/-25=12
              amol = 1._r8 + (12._r8)**(2._r8/3._r8)
           end if
           amolN = 3._r8 * amol !// For N-species: multiply by 3
        else
           amol  = 1._r8
           amolN = 1._r8 !// For N-species: same value
        end if


        !// Set land fractions
        call landfrac2mosaic(FL,NLCAT,landSurfTypeFrac(:,I,J), &
             NVGPAR, YDGRD(J), LANDUSE_IDX)


        !// Snow cover for each vegetation type, calculate snowD as meter snow.
        if (PLAND(I,J) .eq. 1._r8) then
           snowD = SD(I,J) * 10._r8
        else if (PLAND(I,J) .gt. 0._r8) then
           if (CI(I,J) .eq. 0._r8) then
              !// Assume snow depth covers only land
              snowD = SD(I,J) / PLAND(I,J) * 10._r8
           else
              if (CI(I,J) .ge. FL(8)) then
                 !// More sea ice than water; should not occur, but we accept
                 !// it for now and assume ocean to be fully covered by ice.
                 snowD = SD(I,J) * 10._r8
              else
                 !// Part of water is ice covered. The part of the gridbox
                 !// which is NOT covered by snow is (focean - CI(I,J)),
                 !// so we adjust snow depth for the covered part.
                 snowD = SD(I,J) / (1._r8 - (FL(8) - CI(I,J))) * 10._r8
              end if
           end if
        else
           !// All is water
           if (CI(I,J) .gt. 0._r8) then
              snowD = SD(I,J) / CI(I,J) * 10._r8 !// Snow depth on ice
           else
              snowD = 0._r8
           end if
        end if

        !// Find snow depth for all vegetation types
        do NN = 1, NLCAT-1
           if (snowD .eq. 0._r8) then
              fsnowC(NN) = 0._r8 !// No snow present
           else
              if (VEGH(NN).eq.0._r8) then
                 !// Snow and zero vegetation height is assumed to be
                 !// snow covered.
                 fsnowC(NN) = 1._r8
              else
                 !// Calculate snow cover for vegetation type
                 fsnowC(NN) = min(1._r8, snowD / (0.1_r8 * VEGH(NN)))
              end if
           end if
        end do
        !// Ocean snow cover is done below where fice is calculated.
        !// Snow land is of course snow covered
        fsnowC(10)= 1._r8


        !// Sea ice - check if we need to reduce fraction of ocean
        if (CI(I,J) .eq. 0._r8) then
           fice = 0._r8
        else
           !// Cannot have more sea ice than sea, so the fraction of sea
           !// covered by ice is
           if (FL(8) .gt. 0._r8) then
              fice = min(CI(I,J)/FL(8), 1._r8)
           else
              fice = 0._r8
           end if
        end if
        fsnowC(8) = fice

        !// Taking snow cover and sea ice into account.
        !// Above 0C, snow should be treated as a wet surface.
        !// Because ice is probably not wet until a few degrees above 0C, we
        !// should perhaps use 1-2C, but this must be tested.

        !// Change snow covered land fractions to snow/ice when T<0C
        if (T2M.le.273.15_r8) then
           !// Check for snow cover at cold temperatures
           do NN = 1, 9
              if (fsnowC(NN).gt.0._r8) then
                 !// Move the snow covered fraction of each land type to FL(10)
                 FL(10) = FL(10) + FL(NN)*fsnowC(NN)
                 FL(NN) = FL(NN) * (1._r8 - fsnowC(NN))
              end if
           end do
        else
           !// Snow cover for T>0C should be treated as wet surface.
           !// To simplify, we put all wet surfaces into FL(8).
           do NN = 1, 7
              if (fsnowC(NN).gt.0._r8) then
                 !// Move the snow covered fraction of each land type to FL(8)
                 FL(8) = FL(8) + FL(NN)*fsnowC(NN)
                 FL(NN) = FL(NN) * (1._r8 - fsnowC(NN))
              end if
           end do
           do NN = 9, 10
              if (fsnowC(NN).gt.0._r8) then
                 FL(8) = FL(8) + FL(NN)*fsnowC(NN)
                 FL(NN) = FL(NN) * (1._r8 - fsnowC(NN))
              end if
           end do
        end if


        !// Final check: wetland is wet when T>0C, but assume ice when T<0C
        if (T2M .lt. 273.15_r8 .and. FL(5).gt.0._r8) then
           FL(10) = FL(10) + FL(5)
           FL(5) = 0._r8
        end if



        !// Rainy surface, i.e. wet surface
        !// This fraction should be assumed to be distributed equally
        !// on all land types, in lack of other information
        if (RAIN.gt.0._r8 .and. T2M.gt.273.15_r8) then
           if (PLAND(I,J) .gt. 0._r8) then
              WETFRAC = maxval(CLDFR(I,J,:))
           else
              WETFRAC = 0._r8
           end if
        else
           WETFRAC = 0._r8
        end if


        !// Standard EMEP values water/land/ice
        a1W = 0.002_r8
        a1L = 0.002_r8
        a1I = 0.002_r8

        !// Forest; limit forest to our land value
        a1Lfor = max(0.008_r8 * SAI1*0.1_r8, a1L)

        !// All VDs must be multiplied with amol or amolN.
        !// This is done at the end as separate factors

        !// If rain, perhaps wet forest should increase? Try increasing
        !// 1.5 times.
        VD(1) = (a1Lfor * (1._r8 - WETFRAC) &
                  + 1.5_r8 * a1Lfor * WETFRAC) * USR
        !// Assume wetland is wet. Have already checked it for temperature,
        !// assuming T<0C is to treated as snow/ice.
        VD(5) = a1W * USR
        !// Ocean is wet
        VD(8) = a1W * USR
        !// Non-wet surfaces - weight with WETFRAC
        VD(2) = (a1L * (1._r8 - WETFRAC) + a1W * WETFRAC) * USR
        VD(3) = (a1L * (1._r8 - WETFRAC) + a1W * WETFRAC) * USR
        VD(4) = (a1L * (1._r8 - WETFRAC) + a1W * WETFRAC) * USR
        VD(6) = (a1L * (1._r8 - WETFRAC) + a1W * WETFRAC) * USR
        VD(7) = (a1L * (1._r8 - WETFRAC) + a1W * WETFRAC) * USR
        VD(9) = (a1L * (1._r8 - WETFRAC) + a1W * WETFRAC) * USR
        !// Ice - weight with WETFRAC
        VD(10) = (a1I * (1._r8 - WETFRAC) + a1W * WETFRAC) * USR

        !// Make average velocity
        Vtot = 0._r8
        do NN=1,10
           Vtot = Vtot + VD(NN) * FL(NN)
        end do

        !// Sulphur
        if (LSULPHUR) then
           !// Old sulphur code used 0.2cm/s, which with our mean Ustar
           !// gives a1 = 0.0068. It is a bit off from the 0.002 value
           !// used here, and may have to be revised.
           !// SO4
           N = trsp_idx(73)
           VDEP(N,I,J) = Vtot * amol
           SCALESTABILITY(N) = 0
           !// MSA
           N = trsp_idx(75)
           VDEP(N,I,J) = Vtot * amol
           SCALESTABILITY(N) = 0
        end if

        !// Nitrate
        if (LNITRATE) then
           !// Old nitrate code used values as SO4, i.e. 0.2cm/s. As for
           !// sulphur species, that is a bit off from this method and may
           !// have to be revised.
           !// NH4fine (NH4coarse is set in sea salt module)
           N = trsp_idx(62)
           VDEP(N,I,J) = Vtot * amolN
           SCALESTABILITY(N) = 0
           !// NO3fine (NO3coarse is set in sea salt module)
           N = trsp_idx(64)
           VDEP(N,I,J) = Vtot * amolN
           SCALESTABILITY(N) = 0
        end if

        !// SOA
        if (LSOA) then
           !// Original SOA code used 0.1cm/s, which with our mean Ustar
           !// gives a1 = 0.0034, which is not too far off from the 0.002
           !// value used here.
           do K = 1, ndep_soa
              N = trsp_idx(soa_deps(K))
              VDEP(N,I,J) = Vtot * amol
              SCALESTABILITY(N) = 0
           end do
        end if

      end do !// do I = MPBLKIB(MP),MPBLKIE(MP)
    end do !// do J = MPBLKJB(MP),MPBLKJE(MP)


    !// ------------------------------------------------------------------
  end subroutine aer_vdep2
  !// ------------------------------------------------------------------
  !// ----------------------------------------------------------------------
  real(r8) function PSIM(CETA)
    !// --------------------------------------------------------------------
    !// Description: 
    !//  The integral function of the similarity profile of momentum
    !//  (Garratt, 1992). It is used to iteratively compute the local Ra
    !//  in the mosaic approach to dry deposition.
    !//
    !// History: 
    !//  Stefanie Falk, Mai 2019
    !// --------------------------------------------------------------------
    use cmn_parameters, only: CSIM_BETA, CSIM_GAMMA, CPI
    !// --------------------------------------------------------------------
    implicit none
    !// --------------------------------------------------------------------
    !// Input
    real(r8), intent(in) :: CETA
    !// Local variables
    real(r8) :: x 
    x = (1-CSIM_GAMMA*CETA)**0.25_r8
    !// --------------------------------------------------------------------
    if (CETA .lt. 0._r8) then
       ! Unstable PBL
       PSIM = LOG((1+x**2)*0.5_r8*((1+x)*0.5_r8)**2) - 2*ATAN(x+CPI*0.5_r8)
    else
       ! Stable PBL
       PSIM = -1._r8*CSIM_BETA*CETA
    end if
    return
  end function PSIM
  !// ----------------------------------------------------------------------
  !// ----------------------------------------------------------------------
  real(r8) function PSIH(CETA)
    !// --------------------------------------------------------------------
    !// Description: 
    !//  The integral function of the similarity profile of heat
    !//  (Garratt, 1992). It is used to iteratively compute the local Ra
    !//  in the mosaic approach to dry deposition.
    !//
    !// History: 
    !//  Stefanie Falk, Mai 2019
    !// --------------------------------------------------------------------
    use cmn_parameters, only: CSIM_BETA, CSIM_GAMMA, CPI
    !// --------------------------------------------------------------------
    implicit none
    !// --------------------------------------------------------------------
    !// Input
    real(r8), intent(in) :: CETA
    !// Local variables
    real(r8) :: x 
    x = (1-CSIM_GAMMA*CETA)**0.25_r8
    !// --------------------------------------------------------------------
    if (CETA .lt. 0._r8) then
       ! Unstable PBL
       PSIH = 2*LOG((1+x**2)*0.5_r8)
    else
       ! Stable PBL
       PSIH = -1._r8*CSIM_BETA*CETA
    end if
    return
  end function PSIH
  !// ----------------------------------------------------------------------
  !// ------------------------------------------------------------------
end module drydeposition_oslo
!// ------------------------------------------------------------------

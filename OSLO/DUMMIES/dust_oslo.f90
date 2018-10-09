!//=========================================================================
!// Oslo CTM3
!//=========================================================================
!// Ole Amund Sovde, April 2015
!//=========================================================================
!// Mineral dust.
!//=========================================================================
module dust_oslo
  !// ----------------------------------------------------------------------
  !// MODULE: dust_oslo
  !// DESCRIPTION: DUMMY
  !//
  !// Ole Amund Sovde, October 2009
  !// ----------------------------------------------------------------------
  use cmn_precision, only: r8
  !// ----------------------------------------------------------------------
  implicit none
  !// ----------------------------------------------------------------------
  integer   :: dust_trsp_idx(1)
  character(len=*), parameter, private :: f90file = 'dust_oslo.f90 (DUMMY)'
  !// ----------------------------------------------------------------------


contains

  !// ----------------------------------------------------------------------
  subroutine dust_init(NDAY,DT_DUST)
    !// --------------------------------------------------------------------
    !// DUMMY
    !//
    !// Ole Amund Sovde, October 2009
    !// --------------------------------------------------------------------
    implicit none
    !// --------------------------------------------------------------------
    !// Input
    integer, intent(in) :: NDAY
    real(r8), intent(in) :: DT_DUST
    !// --------------------------------------------------------------------
    return
    !// --------------------------------------------------------------------
  end subroutine dust_init
  !// ----------------------------------------------------------------------

  !// ----------------------------------------------------------------------
  subroutine dust_globalupdate(NDAY)
    !// --------------------------------------------------------------------
    !// DUMMY
    !//
    !// Ole Amund Sovde, October 2009
    !// --------------------------------------------------------------------
    !// --------------------------------------------------------------------
    Implicit NONE
    !// --------------------------------------------------------------------
    !// Input
    integer, intent(in) :: NDAY
    !// --------------------------------------------------------------------
    return
    !// --------------------------------------------------------------------
  end subroutine dust_globalupdate
  !// ----------------------------------------------------------------------

  !// ----------------------------------------------------------------------
  subroutine dust_master(BTT, AIRB, BTEM, DTCHM, NOPS, MP)
    !// --------------------------------------------------------------------
    !// Master interaction between Oslo CTM3 and DEAD.
    !// Called from oc_master in oc_main.f
    !//
    !//
    !// Ole Amund Sovde, October 2009
    !// --------------------------------------------------------------------
    use cmn_size, only: NPAR, JPAR, LPAR, IDBLK, JDBLK
    !// --------------------------------------------------------------------
    Implicit NONE
    !// --------------------------------------------------------------------
    !// Input
    integer, intent(in)   :: NOPS, MP
    real(r8), intent(in)  :: DTCHM
    real(r8), intent(in), dimension(LPAR,IDBLK,JDBLK) :: AIRB, BTEM
    real(r8), intent(in), dimension(LPAR,NPAR,IDBLK,JDBLK) :: BTT
    !// --------------------------------------------------------------------
    return
    !// --------------------------------------------------------------------
  end subroutine dust_master
  !// ----------------------------------------------------------------------


  !// ----------------------------------------------------------------------
  subroutine dustbdg2file(NDAY, NDAYI, NDAY0)
    !// --------------------------------------------------------------------
    !// DUMMY.
    !//
    !// Ole Amund Sovde, March 2016
    !// --------------------------------------------------------------------
    implicit none
    !// --------------------------------------------------------------------
    !// Input
    !// --------------------------------------------------------------------
    integer, intent(in) :: NDAY, NDAYI, NDAY0
    !// --------------------------------------------------------------------
    !character(len=*), parameter :: subr = 'dustbdg2file'
    !// --------------------------------------------------------------------
    return
    !// --------------------------------------------------------------------
  end subroutine dustbdg2file
  !// ----------------------------------------------------------------------


  !// ----------------------------------------------------------------------
  subroutine dustInstBdg(NDAY,NDAY0,NMET,NOPS,DTOPS)
    !// --------------------------------------------------------------------
    !// DUMMY.
    !// Should never be called due to LDUST test, but it is needed for
    !// compilation.
    !//
    !// Ole Amund Sovde, February 2015
    !// --------------------------------------------------------------------
    implicit none
    !// --------------------------------------------------------------------
    integer, intent(in) :: NDAY,NDAY0,NMET,NOPS
    real(r8), intent(in) :: DTOPS
    !// --------------------------------------------------------------------
    !character(len=*), parameter :: subr = 'dustInstBdg'
    !// --------------------------------------------------------------------
    return
    !// --------------------------------------------------------------------
  end subroutine dustInstBdg
  !// ----------------------------------------------------------------------


  !//-----------------------------------------------------------------------
  subroutine dust_set_ssrd(r8data)
    !//---------------------------------------------------------------------
    !// DUMMY.
    !//
    !// Ole Amund Sovde, January 2016
    !//---------------------------------------------------------------------
    use cmn_size, only: IPAR, JPAR
    !//---------------------------------------------------------------------
    implicit none
    !//---------------------------------------------------------------------
    !// Input
    real(r8), intent(in) :: r8data(ipar,jpar)
    !//---------------------------------------------------------------------
    return
    !//---------------------------------------------------------------------
  end subroutine dust_set_ssrd
  !//-----------------------------------------------------------------------


  !//-----------------------------------------------------------------------
  subroutine dust_set_strd(r8data)
    !//---------------------------------------------------------------------
    !// DUMMY.
    !//
    !// Ole Amund Sovde, January 2016
    !//---------------------------------------------------------------------
    use cmn_size, only: IPAR, JPAR
    !//---------------------------------------------------------------------
    implicit none
    !//---------------------------------------------------------------------
    !// Input
    real(r8), intent(in) :: r8data(ipar,jpar)
    !//---------------------------------------------------------------------
    return
    !//---------------------------------------------------------------------
  end subroutine dust_set_strd
  !//-----------------------------------------------------------------------


  !//-----------------------------------------------------------------------
  subroutine dust_set_SWVL1(r8data)
    !//---------------------------------------------------------------------
    !// DUMMY.
    !//
    !// Ole Amund Sovde, January 2016
    !//---------------------------------------------------------------------
    use cmn_size, only: IPAR, JPAR
    !//---------------------------------------------------------------------
    implicit none
    !//---------------------------------------------------------------------
    !// Input
    real(r8), intent(in) :: r8data(ipar,jpar)
    !//---------------------------------------------------------------------
    return
    !//---------------------------------------------------------------------
  end subroutine dust_set_SWVL1
  !//-----------------------------------------------------------------------


  !//-----------------------------------------------------------------------
  subroutine dust_set_mbl_name_ff(name,fudgefactor)
    !//---------------------------------------------------------------------
    !// DUMMY.
    !//
    !// Ole Amund Sovde, March 2016
    !//---------------------------------------------------------------------
    implicit none
    !//---------------------------------------------------------------------
    !// Input
    character(len=*), intent(in) :: name
    real(r8), intent(in) :: fudgefactor
    !//---------------------------------------------------------------------
    character(len=*), parameter :: subr = 'dust_set_mbl_name'
    !// --------------------------------------------------------------------
    write(6,'(a)') f90file//':'//subr// &
         ': DUST not included; skip defining mobilisation variable name'// &
         ' and fudge factor'
    !//---------------------------------------------------------------------
  end subroutine dust_set_mbl_name_ff
  !//-----------------------------------------------------------------------


  !// ----------------------------------------------------------------------
end module dust_oslo
!//=========================================================================

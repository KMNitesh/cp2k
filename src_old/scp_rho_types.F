!-----------------------------------------------------------------------------!
!   CP2K: A general program to perform molecular dynamics simulations         !
!   Copyright (C) 2000 - 2011  CP2K developers group                          !
!-----------------------------------------------------------------------------!

! *****************************************************************************
!> \brief rho_types
!> \author CJM
! *****************************************************************************
MODULE scp_rho_types
  USE f77_blas
  USE kinds,                           ONLY: dp
  USE pw_types,                        ONLY: pw_p_type,&
                                             pw_release
  USE timings,                         ONLY: timeset,&
                                             timestop
#include "cp_common_uses.h"

  IMPLICIT NONE

  PRIVATE
  CHARACTER(len=*), PARAMETER, PRIVATE :: moduleN = 'scp_rho_types'
  PUBLIC :: scp_rho_type, scp_rho_release, scp_rho_get, &
            scp_rho_retain

! *****************************************************************************
  TYPE scp_rho_type
     INTEGER :: ref_count, id_nr
     REAL(KIND=dp) :: total_rho_gspace, total_rho_rspace
     TYPE ( pw_p_type ), POINTER ::  rhop_g,  rhop_r
  END TYPE scp_rho_type

CONTAINS

! *****************************************************************************
SUBROUTINE scp_rho_get(rho_scp,  rhop_r, rhop_g, error)
    TYPE(scp_rho_type), POINTER              :: rho_scp
    TYPE(pw_p_type), OPTIONAL, POINTER       :: rhop_r, rhop_g
    TYPE(cp_error_type), INTENT(inout)       :: error

    CHARACTER(len=*), PARAMETER :: routineN = 'scp_rho_get', &
      routineP = moduleN//':'//routineN

    LOGICAL                                  :: failure

  failure=.FALSE.

  CPPrecondition(ASSOCIATED(rho_scp),cp_failure_level,routineP,error,failure)
  CPPrecondition(rho_scp%ref_count>0,cp_failure_level,routineP,error,failure)

  IF (.NOT. failure) THEN
    IF (PRESENT(rhop_r)) rhop_r => rho_scp%rhop_r
    IF (PRESENT(rhop_g)) rhop_g => rho_scp%rhop_g
  END IF
END SUBROUTINE scp_rho_get
! *****************************************************************************
SUBROUTINE scp_rho_retain(rho_scp,error)
    TYPE(scp_rho_type), POINTER              :: rho_scp
    TYPE(cp_error_type), INTENT(inout)       :: error

    CHARACTER(len=*), PARAMETER :: routineN = 'scp_rho_retain', &
      routineP = moduleN//':'//routineN

    LOGICAL                                  :: failure

  failure=.FALSE.

  CPPrecondition(ASSOCIATED(rho_scp),cp_failure_level,routineP,error,failure)
  IF (.NOT. failure) THEN
     CPPrecondition(rho_scp%ref_count>0,cp_failure_level,routineP,error,failure)
     rho_scp%ref_count=rho_scp%ref_count+1
  END IF
END SUBROUTINE scp_rho_retain

! *****************************************************************************
!> \brief releases the memory used by the scp_rho and scp_rho
! *****************************************************************************
  SUBROUTINE scp_rho_release(rho_scp,error)

    TYPE(scp_rho_type), POINTER              :: rho_scp
    TYPE(cp_error_type), INTENT(inout)       :: error

    CHARACTER(len=*), PARAMETER :: routineN = 'scp_rho_release', &
      routineP = moduleN//':'//routineN

    INTEGER                                  :: handle, stat
    LOGICAL                                  :: failure

  CALL timeset(routineN,handle)
  failure=.FALSE.
  IF (ASSOCIATED(rho_scp)) THEN
    CPPrecondition(rho_scp%ref_count>0,cp_failure_level,routineP,error,failure)
    rho_scp%ref_count=rho_scp%ref_count-1
    IF (rho_scp%ref_count<1) THEN
      IF (ASSOCIATED(rho_scp%rhop_r)) THEN
        CALL pw_release(rho_scp%rhop_r%pw,error=error)
        DEALLOCATE(rho_scp%rhop_r,stat=stat)
        CPPostconditionNoFail(stat==0,cp_warning_level,routineP,error)
      END IF
      IF (ASSOCIATED(rho_scp%rhop_g)) THEN
        CALL pw_release(rho_scp%rhop_g%pw,error=error)
        DEALLOCATE(rho_scp%rhop_g,stat=stat)
        CPPostconditionNoFail(stat==0,cp_warning_level,routineP,error)
      END IF
      DEALLOCATE(rho_scp,stat=stat)
      CPPostcondition(stat==0,cp_warning_level,routineP,error,failure)
    END IF
  END IF
  NULLIFY(rho_scp)
  CALL timestop(handle)
  END SUBROUTINE scp_rho_release

END MODULE scp_rho_types

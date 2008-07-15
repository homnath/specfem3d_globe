!=====================================================================
!
!          S p e c f e m 3 D  G l o b e  V e r s i o n  4 . 0
!          --------------------------------------------------
!
!          Main authors: Dimitri Komatitsch and Jeroen Tromp
!    Seismological Laboratory, California Institute of Technology, USA
!             and University of Pau / CNRS / INRIA, France
! (c) California Institute of Technology and University of Pau / CNRS / INRIA
!                            February 2008
!
! This program is free software; you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation; either version 2 of the License, or
! (at your option) any later version.
!
! This program is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License along
! with this program; if not, write to the Free Software Foundation, Inc.,
! 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
!
!=====================================================================

!  This portion of the SPECFEM3D Code was written by:
!  Brian Savage while at
!     California Institute of Technology
!     Department of Terrestrial Magnetism / Carnegie Institute of Washington
!     Univeristy of Rhode Island
!
!  <savage@uri.edu>.
!  <savage13@gps.caltech.edu>
!  <savage13@dtm.ciw.edu>
!
!   It is based upon formulation in the following references:
!
!   Dahlen and Tromp, 1998
!      Theoretical Global Seismology
!
!   Liu et al. 1976
!      Velocity dispersion due to anelasticity: implications for seismology and mantle composition
!      Geophys, J. R. asts. Soc, Vol 47, pp. 41-58
!
!   The methodology can be found in Savage and Tromp, 2006, unpublished
!

subroutine attenuation_lookup_value(i, r)

  implicit none

  include 'constants.h'

  integer i
  double precision r

  r = dble(i) / TABLE_ATTENUATION

end subroutine attenuation_lookup_value

! This Subroutine is Hackish.  It could probably all be moved to an input attenuation file.
! Actually all the velocities, densities and attenuations could be moved to seperate input
! files rather than be defined within the CODE
!
! All this subroutine does is define the Attenuation vs Radius and then Compute the Attenuation
! Variables (tau_sigma and tau_epslion ( or tau_mu) )
subroutine attenuation_model_setup(REFERENCE_1D_MODEL,RICB,RCMB,R670,R220,R80,AM_V,M1066a_V,Mak135_V,Mref_V,SEA1DM_V,AM_S,AS_V)

  implicit none

  include 'mpif.h'
  include 'constants.h'

! attenuation_model_variables
  type attenuation_model_variables
    sequence
    double precision min_period, max_period
    double precision                          :: QT_c_source        ! Source Frequency
    double precision, dimension(:), pointer   :: Qtau_s             ! tau_sigma
    double precision, dimension(:), pointer   :: QrDisc             ! Discontinutitues Defined
    double precision, dimension(:), pointer   :: Qr                 ! Radius
    integer, dimension(:), pointer            :: interval_Q                 ! Steps
    double precision, dimension(:), pointer   :: Qmu                ! Shear Attenuation
    double precision, dimension(:,:), pointer :: Qtau_e             ! tau_epsilon
    double precision, dimension(:), pointer   :: Qomsb, Qomsb2      ! one_minus_sum_beta
    double precision, dimension(:,:), pointer :: Qfc, Qfc2          ! factor_common
    double precision, dimension(:), pointer   :: Qsf, Qsf2          ! scale_factor
    integer, dimension(:), pointer            :: Qrmin              ! Max and Mins of idoubling
    integer, dimension(:), pointer            :: Qrmax              ! Max and Mins of idoubling
    integer                                   :: Qn                 ! Number of points
  end type attenuation_model_variables

  type (attenuation_model_variables) AM_V
! attenuation_model_variables

! model_1066a_variables
  type model_1066a_variables
    sequence
      double precision, dimension(NR_1066A) :: radius_1066a
      double precision, dimension(NR_1066A) :: density_1066a
      double precision, dimension(NR_1066A) :: vp_1066a
      double precision, dimension(NR_1066A) :: vs_1066a
      double precision, dimension(NR_1066A) :: Qkappa_1066a
      double precision, dimension(NR_1066A) :: Qmu_1066a
  end type model_1066a_variables

  type (model_1066a_variables) M1066a_V
! model_1066a_variables

! model_ak135_variables
  type model_ak135_variables
    sequence
    double precision, dimension(NR_AK135) :: radius_ak135
    double precision, dimension(NR_AK135) :: density_ak135
    double precision, dimension(NR_AK135) :: vp_ak135
    double precision, dimension(NR_AK135) :: vs_ak135
    double precision, dimension(NR_AK135) :: Qkappa_ak135
    double precision, dimension(NR_AK135) :: Qmu_ak135
  end type model_ak135_variables

 type (model_ak135_variables) Mak135_V
! model_ak135_variables

! model_ref_variables
  type model_ref_variables
    sequence
    double precision, dimension(NR_REF) :: radius_ref
    double precision, dimension(NR_REF) :: density_ref
    double precision, dimension(NR_REF) :: vpv_ref
    double precision, dimension(NR_REF) :: vph_ref
    double precision, dimension(NR_REF) :: vsv_ref
    double precision, dimension(NR_REF) :: vsh_ref
    double precision, dimension(NR_REF) :: eta_ref
    double precision, dimension(NR_REF) :: Qkappa_ref
    double precision, dimension(NR_REF) :: Qmu_ref
  end type model_ref_variables

 type (model_ref_variables) Mref_V
! model_ref_variables

! sea1d_model_variables
  type sea1d_model_variables
    sequence
     double precision, dimension(NR_SEA1D) :: radius_sea1d
     double precision, dimension(NR_SEA1D) :: density_sea1d
     double precision, dimension(NR_SEA1D) :: vp_sea1d
     double precision, dimension(NR_SEA1D) :: vs_sea1d
     double precision, dimension(NR_SEA1D) :: Qkappa_sea1d
     double precision, dimension(NR_SEA1D) :: Qmu_sea1d
  end type sea1d_model_variables

  type (sea1d_model_variables) SEA1DM_V
! sea1d_model_variables

! attenuation_model_storage
  type attenuation_model_storage
    sequence
    integer Q_resolution
    integer Q_max
    double precision, dimension(:,:), pointer :: tau_e_storage
    double precision, dimension(:), pointer :: Qmu_storage
  end type attenuation_model_storage

  type (attenuation_model_storage) AM_S
! attenuation_model_storage

! attenuation_simplex_variables
  type attenuation_simplex_variables
    sequence
    integer nf          ! nf    = Number of Frequencies
    integer nsls        ! nsls  = Number of Standard Linear Solids
    double precision Q  ! Q     = Desired Value of Attenuation or Q
    double precision iQ ! iQ    = 1/Q
    double precision, dimension(:), pointer ::  f
    ! f = Frequencies at which to evaluate the solution
    double precision, dimension(:), pointer :: tau_s
    ! tau_s = Tau_sigma defined by the frequency range and
    !             number of standard linear solids
  end type attenuation_simplex_variables

  type(attenuation_simplex_variables) AS_V
! attenuation_simplex_variables

  integer myrank
  integer REFERENCE_1D_MODEL
  double precision RICB, RCMB, R670, R220, R80
  double precision tau_e(N_SLS)

  integer i,ier
  double precision Qb
  double precision R120

  Qb = 57287.0d0
  R120 = 6251.d3

  call MPI_COMM_RANK(MPI_COMM_WORLD, myrank, ier)
  if(myrank > 0) return

  if(REFERENCE_1D_MODEL == REFERENCE_MODEL_PREM) then
     AM_V%Qn = 12
  else if(REFERENCE_1D_MODEL == REFERENCE_MODEL_IASP91) then
     AM_V%Qn = 12
  else if(REFERENCE_1D_MODEL == REFERENCE_MODEL_AK135) then
     call define_model_ak135(.FALSE.,Mak135_V)
     AM_V%Qn = NR_AK135
  else if(REFERENCE_1D_MODEL == REFERENCE_MODEL_1066A) then
     call define_model_1066a(.FALSE., M1066a_V)
     AM_V%Qn = NR_1066A
  else if(REFERENCE_1D_MODEL == REFERENCE_MODEL_REF) then
     call define_model_ref(Mref_V)
     AM_V%Qn = NR_REF
  else if(REFERENCE_1D_MODEL == REFERENCE_MODEL_JP1D) then
     AM_V%Qn = 12
  else if(REFERENCE_1D_MODEL == REFERENCE_MODEL_SEA1D) then
     call define_model_sea1d(.FALSE., SEA1DM_V)
     AM_V%Qn = NR_SEA1D
  else
     call exit_MPI(myrank, 'Reference 1D Model Not recognized')
  endif

  allocate(AM_V%Qr(AM_V%Qn))
  allocate(AM_V%Qmu(AM_V%Qn))
  allocate(AM_V%interval_Q(AM_V%Qn))
  allocate(AM_V%Qtau_e(N_SLS,AM_V%Qn))

  if(REFERENCE_1D_MODEL == REFERENCE_MODEL_PREM) then
     AM_V%Qr(:)     = (/    0.0d0,     RICB,  RICB,  RCMB,    RCMB,    R670,    R670,   R220,    R220,    R80,     R80, R_EARTH /)
     AM_V%Qmu(:)    = (/   84.6d0,   84.6d0, 0.0d0, 0.0d0, 312.0d0, 312.0d0, 143.0d0, 143.0d0, 80.0d0, 80.0d0, 600.0d0, 600.0d0 /)
  else if(REFERENCE_1D_MODEL == REFERENCE_MODEL_IASP91) then
     AM_V%Qr(:)     = (/    0.0d0,     RICB,  RICB,  RCMB,    RCMB,    R670,    R670,    R220,   R220,   R120,    R120, R_EARTH /)
     AM_V%Qmu(:)    = (/   84.6d0,   84.6d0, 0.0d0, 0.0d0, 312.0d0, 312.0d0, 143.0d0, 143.0d0, 80.0d0, 80.0d0, 600.0d0, 600.0d0 /)
  else if(REFERENCE_1D_MODEL == REFERENCE_MODEL_AK135) then
     AM_V%Qr(:)     = Mak135_V%radius_ak135(:)
     AM_V%Qmu(:)    = Mak135_V%Qmu_ak135(:)
  else if(REFERENCE_1D_MODEL == REFERENCE_MODEL_1066A) then
     AM_V%Qr(:)     = M1066a_V%radius_1066a(:)
     AM_V%Qmu(:)    = M1066a_V%Qmu_1066a(:)
  else if(REFERENCE_1D_MODEL == REFERENCE_MODEL_ref) then
     AM_V%Qr(:)     = Mref_V%radius_ref(:)
     AM_V%Qmu(:)    = Mref_V%Qmu_ref(:)
  else if(REFERENCE_1D_MODEL == REFERENCE_MODEL_JP1D) then
     AM_V%Qr(:)     = (/    0.0d0,     RICB,  RICB,  RCMB,    RCMB,    R670,    R670,    R220,   R220,   R120,    R120, R_EARTH /)
     AM_V%Qmu(:)    = (/   84.6d0,   84.6d0, 0.0d0, 0.0d0, 312.0d0, 312.0d0, 143.0d0, 143.0d0, 80.0d0, 80.0d0, 600.0d0, 600.0d0 /)
  else if(REFERENCE_1D_MODEL == REFERENCE_MODEL_SEA1D) then
     AM_V%Qr(:)     = SEA1DM_V%radius_sea1d(:)
     AM_V%Qmu(:)    = SEA1DM_V%Qmu_sea1d(:)
  end if

  do i = 1, AM_V%Qn
     call attenuation_conversion(AM_V%Qmu(i), AM_V%QT_c_source, AM_V%Qtau_s, tau_e, AM_V, AM_S,AS_V)
     AM_V%Qtau_e(:,i) = tau_e(:)
  end do

end subroutine attenuation_model_setup

subroutine attenuation_save_arrays(prname, iregion_code, AM_V)

  implicit none

  include 'mpif.h'
  include 'constants.h'

! attenuation_model_variables
  type attenuation_model_variables
    sequence
    double precision min_period, max_period
    double precision                          :: QT_c_source        ! Source Frequency
    double precision, dimension(:), pointer   :: Qtau_s             ! tau_sigma
    double precision, dimension(:), pointer   :: QrDisc             ! Discontinutitues Defined
    double precision, dimension(:), pointer   :: Qr                 ! Radius
    integer, dimension(:), pointer            :: interval_Q                 ! Steps
    double precision, dimension(:), pointer   :: Qmu                ! Shear Attenuation
    double precision, dimension(:,:), pointer :: Qtau_e             ! tau_epsilon
    double precision, dimension(:), pointer   :: Qomsb, Qomsb2      ! one_minus_sum_beta
    double precision, dimension(:,:), pointer :: Qfc, Qfc2          ! factor_common
    double precision, dimension(:), pointer   :: Qsf, Qsf2          ! scale_factor
    integer, dimension(:), pointer            :: Qrmin              ! Max and Mins of idoubling
    integer, dimension(:), pointer            :: Qrmax              ! Max and Mins of idoubling
    integer                                   :: Qn                 ! Number of points
  end type attenuation_model_variables

  type (attenuation_model_variables) AM_V
! attenuation_model_variables

  integer iregion_code
  character(len=150) prname
  integer ier
  integer myrank
  integer, save :: first_time_called = 1

  call MPI_COMM_RANK(MPI_COMM_WORLD, myrank, ier)
  if(myrank == 0 .AND. iregion_code == IREGION_CRUST_MANTLE .AND. first_time_called == 1) then
    first_time_called = 0
    open(unit=27,file=prname(1:len_trim(prname))//'1D_Q.bin',status='unknown',form='unformatted')
    write(27) AM_V%QT_c_source
    write(27) AM_V%Qtau_s
    write(27) AM_V%Qn
    write(27) AM_V%Qr
    write(27) AM_V%Qmu
    write(27) AM_V%Qtau_e
    close(27)
  endif

end subroutine attenuation_save_arrays

subroutine attenuation_storage(Qmu, tau_e, rw, AM_S)

  implicit none
  include 'mpif.h'
  include 'constants.h'

! attenuation_model_storage
  type attenuation_model_storage
    sequence
    integer Q_resolution
    integer Q_max
    double precision, dimension(:,:), pointer :: tau_e_storage
    double precision, dimension(:), pointer :: Qmu_storage
  end type attenuation_model_storage

  type (attenuation_model_storage) AM_S
! attenuation_model_storage

  integer myrank, ier
  double precision Qmu, Qmu_new
  double precision, dimension(N_SLS) :: tau_e
  integer rw

  integer Qtmp
  integer, save :: first_time_called = 1

  if(first_time_called == 1) then
     first_time_called       = 0
     AM_S%Q_resolution = 10**ATTENUATION_COMP_RESOLUTION
     AM_S%Q_max        = ATTENUATION_COMP_MAXIMUM
     Qtmp         = AM_S%Q_resolution * AM_S%Q_max
     allocate(AM_S%tau_e_storage(N_SLS, Qtmp))
     allocate(AM_S%Qmu_storage(Qtmp))
     AM_S%Qmu_storage(:) = -1
  endif

  if(Qmu < 0.0d0 .OR. Qmu >= AM_S%Q_max) then
     write(IMAIN,*) 'Error'
     write(IMAIN,*) 'attenuation_conversion/storage()'
     write(IMAIN,*) 'Attenuation Value out of Range: ', Qmu
     write(IMAIN,*) 'Attenuation Value out of Range: Min, Max ', 0, AM_S%Q_max
     call MPI_COMM_RANK(MPI_COMM_WORLD, myrank, ier)
     call exit_MPI(myrank, 'Attenuation Value out of Range')
  endif

  if(rw > 0 .AND. Qmu == 0.0d0) then
     Qmu = 0.0d0;
     tau_e(:) = 0.0d0;
     return
  endif
  ! Generate index for Storage Array
  ! and Recast Qmu using this index
  ! Accroding to Brian, use float
  !Qtmp = Qmu * Q_resolution
  !Qmu = Qtmp / Q_resolution;

  !
  Qtmp    = Qmu * dble(AM_S%Q_resolution)
  Qmu_new = dble(Qtmp) / dble(AM_S%Q_resolution)

  if(rw > 0) then
     ! READ
     if(AM_S%Qmu_storage(Qtmp) > 0) then
        ! READ SUCCESSFUL
        tau_e(:)   = AM_S%tau_e_storage(:, Qtmp)
        Qmu        = AM_S%Qmu_storage(Qtmp)
        rw = 1
     else
        ! READ NOT SUCCESSFUL
        rw = -1
     endif
  else
     ! WRITE SUCCESSFUL
     AM_S%tau_e_storage(:,Qtmp)    = tau_e(:)
     AM_S%Qmu_storage(Qtmp)        = Qmu
     rw = 1
  endif

end subroutine attenuation_storage

subroutine attenuation_conversion(Qmu_in, T_c_source, tau_s, tau_e, AM_V, AM_S, AS_V)
! includes min_period, max_period, and N_SLS

  implicit none

  include 'constants.h'

! attenuation_model_variables
  type attenuation_model_variables
    sequence
    double precision min_period, max_period
    double precision                          :: QT_c_source        ! Source Frequency
    double precision, dimension(:), pointer   :: Qtau_s             ! tau_sigma
    double precision, dimension(:), pointer   :: QrDisc             ! Discontinutitues Defined
    double precision, dimension(:), pointer   :: Qr                 ! Radius
    integer, dimension(:), pointer            :: interval_Q                 ! Steps
    double precision, dimension(:), pointer   :: Qmu                ! Shear Attenuation
    double precision, dimension(:,:), pointer :: Qtau_e             ! tau_epsilon
    double precision, dimension(:), pointer   :: Qomsb, Qomsb2      ! one_minus_sum_beta
    double precision, dimension(:,:), pointer :: Qfc, Qfc2          ! factor_common
    double precision, dimension(:), pointer   :: Qsf, Qsf2          ! scale_factor
    integer, dimension(:), pointer            :: Qrmin              ! Max and Mins of idoubling
    integer, dimension(:), pointer            :: Qrmax              ! Max and Mins of idoubling
    integer                                   :: Qn                 ! Number of points
  end type attenuation_model_variables

  type (attenuation_model_variables) AM_V
! attenuation_model_variables

! attenuation_model_storage
  type attenuation_model_storage
    sequence
    integer Q_resolution
    integer Q_max
    double precision, dimension(:,:), pointer :: tau_e_storage
    double precision, dimension(:), pointer :: Qmu_storage
  end type attenuation_model_storage

  type (attenuation_model_storage) AM_S
! attenuation_model_storage

! attenuation_simplex_variables
  type attenuation_simplex_variables
    sequence
    integer nf          ! nf    = Number of Frequencies
    integer nsls        ! nsls  = Number of Standard Linear Solids
    double precision Q  ! Q     = Desired Value of Attenuation or Q
    double precision iQ ! iQ    = 1/Q
    double precision, dimension(:), pointer ::  f
    ! f = Frequencies at which to evaluate the solution
    double precision, dimension(:), pointer :: tau_s
    ! tau_s = Tau_sigma defined by the frequency range and
    !             number of standard linear solids
  end type attenuation_simplex_variables

  type(attenuation_simplex_variables) AS_V
! attenuation_simplex_variables

  double precision Qmu_in, T_c_source
  double precision, dimension(N_SLS) :: tau_s, tau_e

  integer rw

  ! READ
  rw = 1
  call attenuation_storage(Qmu_in, tau_e, rw, AM_S)
  if(rw > 0) return

  call attenuation_invert_by_simplex(AM_V%min_period, AM_V%max_period, N_SLS, Qmu_in, T_c_source, tau_s, tau_e, AS_V)

  ! WRITE
  rw = -1
  call attenuation_storage(Qmu_in, tau_e, rw, AM_S)

end subroutine attenuation_conversion

subroutine read_attenuation_model(min_att_period, max_att_period, AM_V)

  implicit none

  include 'constants.h'

! attenuation_model_variables
  type attenuation_model_variables
    sequence
    double precision min_period, max_period
    double precision                          :: QT_c_source        ! Source Frequency
    double precision, dimension(:), pointer   :: Qtau_s             ! tau_sigma
    double precision, dimension(:), pointer   :: QrDisc             ! Discontinutitues Defined
    double precision, dimension(:), pointer   :: Qr                 ! Radius
    integer, dimension(:), pointer            :: interval_Q                 ! Steps
    double precision, dimension(:), pointer   :: Qmu                ! Shear Attenuation
    double precision, dimension(:,:), pointer :: Qtau_e             ! tau_epsilon
    double precision, dimension(:), pointer   :: Qomsb, Qomsb2      ! one_minus_sum_beta
    double precision, dimension(:,:), pointer :: Qfc, Qfc2          ! factor_common
    double precision, dimension(:), pointer   :: Qsf, Qsf2          ! scale_factor
    integer, dimension(:), pointer            :: Qrmin              ! Max and Mins of idoubling
    integer, dimension(:), pointer            :: Qrmax              ! Max and Mins of idoubling
    integer                                   :: Qn                 ! Number of points
  end type attenuation_model_variables

  type (attenuation_model_variables) AM_V
! attenuation_model_variables

  integer min_att_period, max_att_period

  AM_V%min_period = min_att_period * 1.0d0
  AM_V%max_period = max_att_period * 1.0d0

  allocate(AM_V%Qtau_s(N_SLS))

  call attenuation_tau_sigma(AM_V%Qtau_s, N_SLS, AM_V%min_period, AM_V%max_period)
  call attenuation_source_frequency(AM_V%QT_c_source, AM_V%min_period, AM_V%max_period)

end subroutine read_attenuation_model

subroutine attenuation_memory_values(tau_s, deltat, alphaval,betaval,gammaval)

  implicit none

  include 'constants.h'

  double precision, dimension(N_SLS) :: tau_s, alphaval, betaval,gammaval
  real(kind=CUSTOM_REAL) deltat

  double precision, dimension(N_SLS) :: tauinv

  tauinv(:) = - 1.0 / tau_s(:)

  alphaval(:)  = 1 + deltat*tauinv(:) + deltat**2*tauinv(:)**2 / 2. + &
       deltat**3*tauinv(:)**3 / 6. + deltat**4*tauinv(:)**4 / 24.
  betaval(:)   = deltat / 2. + deltat**2*tauinv(:) / 3. + deltat**3*tauinv(:)**2 / 8. + deltat**4*tauinv(:)**3 / 24.
  gammaval(:)  = deltat / 2. + deltat**2*tauinv(:) / 6. + deltat**3*tauinv(:)**2 / 24.0

end subroutine attenuation_memory_values

subroutine attenuation_scale_factor(myrank, T_c_source, tau_mu, tau_sigma, Q_mu, scale_factor)

  implicit none

  include 'constants.h'

  integer myrank
  double precision scale_factor, Q_mu, T_c_source
  double precision, dimension(N_SLS) :: tau_mu, tau_sigma

  double precision scale_t
  double precision f_c_source, w_c_source, f_0_prem
  double precision factor_scale_mu0, factor_scale_mu
  double precision a_val, b_val
  double precision big_omega
  integer i

  scale_t = ONE/dsqrt(PI*GRAV*RHOAV)

!--- compute central angular frequency of source (non dimensionalized)
  f_c_source = ONE / T_c_source
  w_c_source = TWO_PI * f_c_source

!--- non dimensionalize PREM reference of 1 second
  f_0_prem = ONE / ( ONE / scale_t)

!--- quantity by which to scale mu_0 to get mu
! this formula can be found for instance in
! Liu, H. P., Anderson, D. L. and Kanamori, H., Velocity dispersion due to
! anelasticity: implications for seismology and mantle composition,
! Geophys. J. R. Astron. Soc., vol. 47, pp. 41-58 (1976)
! and in Aki, K. and Richards, P. G., Quantitative seismology, theory and methods,
! W. H. Freeman, (1980), second edition, sections 5.5 and 5.5.2, eq. (5.81) p. 170
  factor_scale_mu0 = ONE + TWO * log(f_c_source / f_0_prem) / (PI * Q_mu)

!--- compute a, b and Omega parameters, also compute one minus sum of betas
  a_val = ONE
  b_val = ZERO

  do i = 1,N_SLS
    a_val = a_val - w_c_source * w_c_source * tau_mu(i) * &
      (tau_mu(i) - tau_sigma(i)) / (1.d0 + w_c_source * w_c_source * tau_mu(i) * tau_mu(i))
    b_val = b_val + w_c_source * (tau_mu(i) - tau_sigma(i)) / &
      (1.d0 + w_c_source * w_c_source * tau_mu(i) * tau_mu(i))
  enddo

  big_omega = a_val*(sqrt(1.d0 + b_val*b_val/(a_val*a_val))-1.d0)

!--- quantity by which to scale mu to get mu_relaxed
  factor_scale_mu = b_val * b_val / (TWO * big_omega)

!--- total factor by which to scale mu0
  scale_factor = factor_scale_mu * factor_scale_mu0

!--- check that the correction factor is close to one
  if(scale_factor < 0.8 .or. scale_factor > 1.2) then
     write(*,*)'scale factor: ', scale_factor
     call exit_MPI(myrank,'incorrect correction factor in attenuation model')
  endif

end subroutine attenuation_scale_factor

!----

subroutine attenuation_property_values(tau_s, tau_e, factor_common, one_minus_sum_beta)

  implicit none

  include 'constants.h'

  double precision, dimension(N_SLS) :: tau_s, tau_e, beta, factor_common
  double precision  one_minus_sum_beta

  double precision, dimension(N_SLS) :: tauinv
  integer i

  tauinv(:) = -1.0d0 / tau_s(:)

  beta(:) = 1.0d0 - tau_e(:) / tau_s(:)
  one_minus_sum_beta = 1.0d0

  do i = 1,N_SLS
     one_minus_sum_beta = one_minus_sum_beta - beta(i)
  enddo

  factor_common(:) = 2.0d0 * beta(:) * tauinv(:)

end subroutine attenuation_property_values

!---
!---
!---

subroutine get_attenuation_model_1D(myrank, prname, iregion_code, tau_s, one_minus_sum_beta, &
                                    factor_common, scale_factor, vn,vx,vy,vz, AM_V)

  implicit none

  include 'mpif.h'
  include 'constants.h'

! attenuation_model_variables
  type attenuation_model_variables
    sequence
    double precision min_period, max_period
    double precision                          :: QT_c_source        ! Source Frequency
    double precision, dimension(:), pointer   :: Qtau_s             ! tau_sigma
    double precision, dimension(:), pointer   :: QrDisc             ! Discontinutitues Defined
    double precision, dimension(:), pointer   :: Qr                 ! Radius
    integer, dimension(:), pointer            :: interval_Q                 ! Steps
    double precision, dimension(:), pointer   :: Qmu                ! Shear Attenuation
    double precision, dimension(:,:), pointer :: Qtau_e             ! tau_epsilon
    double precision, dimension(:), pointer   :: Qomsb, Qomsb2      ! one_minus_sum_beta
    double precision, dimension(:,:), pointer :: Qfc, Qfc2          ! factor_common
    double precision, dimension(:), pointer   :: Qsf, Qsf2          ! scale_factor
    integer, dimension(:), pointer            :: Qrmin              ! Max and Mins of idoubling
    integer, dimension(:), pointer            :: Qrmax              ! Max and Mins of idoubling
    integer                                   :: Qn                 ! Number of points
  end type attenuation_model_variables

  type (attenuation_model_variables) AM_V
! attenuation_model_variables

  integer myrank, iregion_code
  character(len=150) prname
  integer vn, vx,vy,vz
  double precision, dimension(N_SLS)              :: tau_s
  double precision, dimension(vx,vy,vz,vn)        :: scale_factor, one_minus_sum_beta
  double precision, dimension(N_SLS, vx,vy,vz,vn) :: factor_common

  integer i,j,ier,rmax
  double precision scale_t
  double precision Qp1, Qpn, radius, fctmp
  double precision, dimension(:), allocatable :: Qfctmp, Qfc2tmp

  integer, save :: first_time_called = 1

  if(myrank == 0 .AND. iregion_code == IREGION_CRUST_MANTLE .AND. first_time_called == 1) then
     first_time_called = 0
     open(unit=27, file=prname(1:len_trim(prname))//'1D_Q.bin', status='unknown', form='unformatted')
     read(27) AM_V%QT_c_source
     read(27) tau_s
     read(27) AM_V%Qn

     allocate(AM_V%Qr(AM_V%Qn))
     allocate(AM_V%Qmu(AM_V%Qn))
     allocate(AM_V%Qtau_e(N_SLS,AM_V%Qn))

     read(27) AM_V%Qr
     read(27) AM_V%Qmu
     read(27) AM_V%Qtau_e
     close(27)
  endif

  ! Synch up after the Read
  call MPI_BCAST(AM_V%QT_c_source,1,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ier)
  call MPI_BCAST(tau_s,N_SLS,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ier)
  call MPI_BCAST(AM_V%Qn,1,MPI_INTEGER,0,MPI_COMM_WORLD,ier)

  if(myrank /= 0) then
     allocate(AM_V%Qr(AM_V%Qn))
     allocate(AM_V%Qmu(AM_V%Qn))
     allocate(AM_V%Qtau_e(N_SLS,AM_V%Qn))
  endif

  call MPI_BCAST(AM_V%Qr,AM_V%Qn,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ier)
  call MPI_BCAST(AM_V%Qmu,AM_V%Qn,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ier)
  call MPI_BCAST(AM_V%Qtau_e,AM_V%Qn*N_SLS,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ier)

  scale_t = ONE/dsqrt(PI*GRAV*RHOAV)

  ! Scale the Attenuation Values
  tau_s(:) = tau_s(:) / scale_t
  AM_V%Qtau_e(:,:) = AM_V%Qtau_e(:,:) / scale_t
  AM_V%QT_c_source = 1000.0d0 / AM_V%QT_c_source / scale_t
  AM_V%Qr(:) = AM_V%Qr(:) / R_EARTH

  allocate(AM_V%Qsf(AM_V%Qn))
  allocate(AM_V%Qomsb(AM_V%Qn))
  allocate(AM_V%Qfc(N_SLS,AM_V%Qn))

  allocate(AM_V%Qsf2(AM_V%Qn))
  allocate(AM_V%Qomsb2(AM_V%Qn))
  allocate(AM_V%Qfc2(N_SLS,AM_V%Qn))

  allocate(AM_V%interval_Q(AM_V%Qn))

  allocate(Qfctmp(AM_V%Qn))
  allocate(Qfc2tmp(AM_V%Qn))

  do i = 1,AM_V%Qn
     if(AM_V%Qmu(i) == 0.0d0) then
        AM_V%Qomsb(i) = 0.0d0
        AM_V%Qfc(:,i) = 0.0d0
        AM_V%Qsf(i)   = 0.0d0
     else
        call attenuation_property_values(tau_s, AM_V%Qtau_e(:,i), AM_V%Qfc(:,i), AM_V%Qomsb(i))
        call attenuation_scale_factor(myrank, AM_V%QT_c_source, AM_V%Qtau_e(:,i), tau_s, AM_V%Qmu(i), AM_V%Qsf(i))
     endif
  enddo

  ! Determine the Spline Coefficients or Second Derivatives
  call pspline_construction(AM_V%Qr, AM_V%Qsf,   AM_V%Qn, Qp1, Qpn, AM_V%Qsf2,   AM_V%interval_Q)
  call pspline_construction(AM_V%Qr, AM_V%Qomsb, AM_V%Qn, Qp1, Qpn, AM_V%Qomsb2, AM_V%interval_Q)
  do i = 1,N_SLS
! copy the sub-arrays to temporary arrays to avoid a warning by some compilers
! about temporary arrays being created automatically when using this expression
! directly in the call to the subroutine
     Qfctmp(:) = AM_V%Qfc(i,:)
     Qfc2tmp(:) = AM_V%Qfc2(i,:)
     call pspline_construction(AM_V%Qr, Qfctmp, AM_V%Qn, Qp1, Qpn, Qfc2tmp, AM_V%interval_Q)
! copy the arrays back to the sub-arrays, since these sub-arrays are used
! as input and output
     AM_V%Qfc(i,:) = Qfctmp(:)
     AM_V%Qfc2(i,:) = Qfc2tmp(:)
  enddo

  radius = 0.0d0
  rmax = nint(TABLE_ATTENUATION)
  do i = 1,rmax
     call attenuation_lookup_value(i, radius)
     call pspline_evaluation(AM_V%Qr, AM_V%Qsf,   AM_V%Qsf2,   AM_V%Qn, radius, scale_factor(1,1,1,i),       AM_V%interval_Q)
     call pspline_evaluation(AM_V%Qr, AM_V%Qomsb, AM_V%Qomsb2, AM_V%Qn, radius, one_minus_sum_beta(1,1,1,i), AM_V%interval_Q)
     do j = 1,N_SLS
        Qfctmp  = AM_V%Qfc(j,:)
        Qfc2tmp = AM_V%Qfc2(j,:)
        call pspline_evaluation(AM_V%Qr, Qfctmp, Qfc2tmp, AM_V%Qn, radius, fctmp, AM_V%interval_Q)
        factor_common(j,1,1,1,i) = fctmp
     enddo
  enddo
  do i = rmax+1,NRAD_ATTENUATION
     scale_factor(1,1,1,i)       = scale_factor(1,1,1,rmax)
     one_minus_sum_beta(1,1,1,i) = one_minus_sum_beta(1,1,1,rmax)
     factor_common(1,1,1,1,i)    = factor_common(1,1,1,1,rmax)
     factor_common(2,1,1,1,i)    = factor_common(2,1,1,1,rmax)
     factor_common(3,1,1,1,i)    = factor_common(3,1,1,1,rmax)
  enddo

  deallocate(AM_V%Qfc2)
  deallocate(AM_V%Qsf2)
  deallocate(AM_V%Qomsb2)
  deallocate(AM_V%Qfc)
  deallocate(AM_V%Qsf)
  deallocate(AM_V%Qomsb)
  deallocate(AM_V%Qtau_e)
  deallocate(Qfctmp)
  deallocate(Qfc2tmp)

  call MPI_BARRIER(MPI_COMM_WORLD, ier)

end subroutine get_attenuation_model_1D

subroutine set_attenuation_regions_1D(RICB, RCMB, R670, R220, R80, AM_V)

  implicit none

  include 'constants.h'

! attenuation_model_variables
  type attenuation_model_variables
    sequence
    double precision min_period, max_period
    double precision                          :: QT_c_source        ! Source Frequency
    double precision, dimension(:), pointer   :: Qtau_s             ! tau_sigma
    double precision, dimension(:), pointer   :: QrDisc             ! Discontinutitues Defined
    double precision, dimension(:), pointer   :: Qr                 ! Radius
    integer, dimension(:), pointer            :: interval_Q                 ! Steps
    double precision, dimension(:), pointer   :: Qmu                ! Shear Attenuation
    double precision, dimension(:,:), pointer :: Qtau_e             ! tau_epsilon
    double precision, dimension(:), pointer   :: Qomsb, Qomsb2      ! one_minus_sum_beta
    double precision, dimension(:,:), pointer :: Qfc, Qfc2          ! factor_common
    double precision, dimension(:), pointer   :: Qsf, Qsf2          ! scale_factor
    integer, dimension(:), pointer            :: Qrmin              ! Max and Mins of idoubling
    integer, dimension(:), pointer            :: Qrmax              ! Max and Mins of idoubling
    integer                                   :: Qn                 ! Number of points
  end type attenuation_model_variables

  type (attenuation_model_variables) AM_V
! attenuation_model_variables

  double precision RICB, RCMB, R670, R220, R80
  integer i

  allocate(AM_V%Qrmin(6))
  allocate(AM_V%Qrmax(6))
  allocate(AM_V%QrDisc(5))

  AM_V%QrDisc(1) = RICB
  AM_V%QrDisc(2) = RCMB
  AM_V%QrDisc(3) = R670
  AM_V%QrDisc(4) = R220
  AM_V%QrDisc(5) = R80

   ! INNER CORE
  AM_V%Qrmin(IREGION_ATTENUATION_INNER_CORE) = 1      ! Center of the Earth
     i = nint(RICB / 100.d0)   ! === BOUNDARY === INNER CORE / OUTER CORE
  AM_V%Qrmax(IREGION_ATTENUATION_INNER_CORE) = i - 1  ! Inner Core Boundary (Inner)

  ! OUTER_CORE
  AM_V%Qrmin(6) = i ! Inner Core Boundary (Outer)
      i = nint(RCMB / 100.d0)  ! === BOUNDARY === INNER CORE / OUTER CORE
  AM_V%Qrmax(6) = i - 1

  ! LOWER MANTLE
  AM_V%Qrmin(IREGION_ATTENUATION_CMB_670) = i
       i = nint(R670 / 100.d0) ! === BOUNDARY === 670 km
  AM_V%Qrmax(IREGION_ATTENUATION_CMB_670) = i - 1

  ! UPPER MANTLE
  AM_V%Qrmin(IREGION_ATTENUATION_670_220) = i
       i = nint(R220 / 100.d0) ! === BOUNDARY === 220 km
  AM_V%Qrmax(IREGION_ATTENUATION_670_220) = i - 1

  ! MANTLE ISH LITHOSPHERE
  AM_V%Qrmin(IREGION_ATTENUATION_220_80) = i
       i = nint(R80 / 100.d0) ! === BOUNDARY === 80 km
  AM_V%Qrmax(IREGION_ATTENUATION_220_80) = i - 1

  ! CRUST ISH LITHOSPHERE
  AM_V%Qrmin(IREGION_ATTENUATION_80_SURFACE) = i
  AM_V%Qrmax(IREGION_ATTENUATION_80_SURFACE) = NRAD_ATTENUATION

end subroutine set_attenuation_regions_1D

subroutine get_attenuation_index(iflag, radius, index, inner_core, AM_V)

  implicit none

  include 'constants.h'

! attenuation_model_variables
  type attenuation_model_variables
    sequence
    double precision min_period, max_period
    double precision                          :: QT_c_source        ! Source Frequency
    double precision, dimension(:), pointer   :: Qtau_s             ! tau_sigma
    double precision, dimension(:), pointer   :: QrDisc             ! Discontinutitues Defined
    double precision, dimension(:), pointer   :: Qr                 ! Radius
    integer, dimension(:), pointer            :: interval_Q                 ! Steps
    double precision, dimension(:), pointer   :: Qmu                ! Shear Attenuation
    double precision, dimension(:,:), pointer :: Qtau_e             ! tau_epsilon
    double precision, dimension(:), pointer   :: Qomsb, Qomsb2      ! one_minus_sum_beta
    double precision, dimension(:,:), pointer :: Qfc, Qfc2          ! factor_common
    double precision, dimension(:), pointer   :: Qsf, Qsf2          ! scale_factor
    integer, dimension(:), pointer            :: Qrmin              ! Max and Mins of idoubling
    integer, dimension(:), pointer            :: Qrmax              ! Max and Mins of idoubling
    integer                                   :: Qn                 ! Number of points
  end type attenuation_model_variables

  type (attenuation_model_variables) AM_V
! attenuation_model_variables

  integer iflag, iregion, index
  double precision radius

  ! Inner Core or not
  logical inner_core

  index = nint(radius * TABLE_ATTENUATION)

!! DK DK this seems incorrect and is difficult to read anyway
!! DK DK therefore let me rewrite it better
! if(inner_core) then
!   if(iflag >= IFLAG_INNER_CORE_NORMAL) then
!     iregion = IREGION_ATTENUATION_INNER_CORE
!   else if(iflag >= IFLAG_OUTER_CORE_NORMAL) then
!     iregion = 6
!   endif
! else
!   if(iflag >= IFLAG_MANTLE_NORMAL) then
!     iregion = IREGION_ATTENUATION_CMB_670
!   else if(iflag == IFLAG_670_220) then
!     iregion = IREGION_ATTENUATION_670_220
!   else if(iflag <= IFLAG_220_80) then
!     iregion = IREGION_ATTENUATION_220_80
!   else
!     iregion = IREGION_ATTENUATION_80_SURFACE
!   endif
! endif
  if(inner_core) then

    if(iflag == IFLAG_INNER_CORE_NORMAL .or. iflag == IFLAG_MIDDLE_CENTRAL_CUBE .or. &
       iflag == IFLAG_BOTTOM_CENTRAL_CUBE .or. iflag == IFLAG_TOP_CENTRAL_CUBE .or. &
       iflag == IFLAG_IN_FICTITIOUS_CUBE) then
      iregion = IREGION_ATTENUATION_INNER_CORE
    else
! this is fictitious for the outer core, which has no Qmu attenuation since it is fluid
!      iregion = IREGION_ATTENUATION_80_SURFACE + 1
       iregion = IREGION_ATTENUATION_UNDEFINED
    endif

  else

    if(iflag == IFLAG_MANTLE_NORMAL) then
      iregion = IREGION_ATTENUATION_CMB_670
    else if(iflag == IFLAG_670_220) then
      iregion = IREGION_ATTENUATION_670_220
    else if(iflag == IFLAG_220_80) then
      iregion = IREGION_ATTENUATION_220_80
    else if(iflag == IFLAG_CRUST .or. iflag == IFLAG_80_MOHO) then
      iregion = IREGION_ATTENUATION_80_SURFACE
    else
! this is fictitious for the outer core, which has no Qmu attenuation since it is fluid
!      iregion = IREGION_ATTENUATION_80_SURFACE + 1
       iregion = IREGION_ATTENUATION_UNDEFINED
    endif

  endif

! Clamp regions
  if(index < AM_V%Qrmin(iregion)) index = AM_V%Qrmin(iregion)
  if(index > AM_V%Qrmax(iregion)) index = AM_V%Qrmax(iregion)

end subroutine get_attenuation_index

subroutine get_attenuation_model_3D(myrank, prname, one_minus_sum_beta, factor_common, scale_factor, tau_s, vnspec)

  implicit none

  include 'constants.h'

  integer myrank, vnspec
  character(len=150) prname
  double precision, dimension(NGLLX,NGLLY,NGLLZ,vnspec)       :: one_minus_sum_beta, scale_factor
  double precision, dimension(N_SLS,NGLLX,NGLLY,NGLLZ,vnspec) :: factor_common
  double precision, dimension(N_SLS)                          :: tau_s

  integer i,j,k,ispec

  double precision, dimension(N_SLS) :: tau_e, fc
  double precision  omsb, Q_mu, sf, T_c_source, scale_t

  ! All of the following reads use the output parameters as their temporary arrays
  ! use the filename to determine the actual contents of the read

  open(unit=27, file=prname(1:len_trim(prname))//'attenuation3D.bin',status='old',action='read',form='unformatted')
  read(27) tau_s
  read(27) factor_common
  read(27) scale_factor
  read(27) T_c_source
  close(27)

  scale_t = ONE/dsqrt(PI*GRAV*RHOAV)

  factor_common(:,:,:,:,:) = factor_common(:,:,:,:,:) / scale_t ! This is really tau_e, not factor_common
  tau_s(:)                 = tau_s(:) / scale_t
  T_c_source               = 1000.0d0 / T_c_source
  T_c_source               = T_c_source / scale_t

  do ispec = 1, vnspec
     do k = 1, NGLLZ
        do j = 1, NGLLY
           do i = 1, NGLLX
              tau_e(:) = factor_common(:,i,j,k,ispec)
              Q_mu     = scale_factor(i,j,k,ispec)

              ! Determine the factor_common and one_minus_sum_beta from tau_s and tau_e
              call attenuation_property_values(tau_s, tau_e, fc, omsb)

              factor_common(:,i,j,k,ispec)    = fc(:)
              one_minus_sum_beta(i,j,k,ispec) = omsb

              ! Determine the "scale_factor" from tau_s, tau_e, central source frequency, and Q
              call attenuation_scale_factor(myrank, T_c_source, tau_e, tau_s, Q_mu, sf)
              scale_factor(i,j,k,ispec) = sf
           enddo
        enddo
     enddo
  enddo
end subroutine get_attenuation_model_3D

subroutine attenuation_source_frequency(omega_not, min_period, max_period)
  ! Determine the Source Frequency

  implicit none

  double precision omega_not
  double precision f1, f2
  double precision min_period, max_period

  f1 = 1.0d0 / max_period
  f2 = 1.0d0 / min_period

  omega_not =  1.0e+03 * 10.0d0**(0.5 * (log10(f1) + log10(f2)))

end subroutine attenuation_source_frequency

subroutine attenuation_tau_sigma(tau_s, n, min_period, max_period)
  ! Set the Tau_sigma (tau_s) to be equally spaced in log10 frequency

  implicit none

  integer n
  double precision tau_s(n)
  double precision min_period, max_period
  double precision f1, f2
  double precision exp1, exp2
  double precision dexp
  integer i
  double precision, parameter :: PI = 3.14159265358979d0

  f1 = 1.0d0 / max_period
  f2 = 1.0d0 / min_period

  exp1 = log10(f1)
  exp2 = log10(f2)

  dexp = (exp2-exp1) / ((n*1.0d0) - 1)
  do i = 1,n
     tau_s(i) = 1.0 / (PI * 2.0d0 * 10**(exp1 + (i - 1)* 1.0d0 *dexp))
  enddo

end subroutine attenuation_tau_sigma

subroutine attenuation_invert_by_simplex(t2, t1, n, Q_real, omega_not, tau_s, tau_e, AS_V)

  implicit none

  include 'mpif.h'

! attenuation_simplex_variables
  type attenuation_simplex_variables
    sequence
    integer nf          ! nf    = Number of Frequencies
    integer nsls        ! nsls  = Number of Standard Linear Solids
    double precision Q  ! Q     = Desired Value of Attenuation or Q
    double precision iQ ! iQ    = 1/Q
    double precision, dimension(:), pointer ::  f
    ! f = Frequencies at which to evaluate the solution
    double precision, dimension(:), pointer :: tau_s
    ! tau_s = Tau_sigma defined by the frequency range and
    !             number of standard linear solids
  end type attenuation_simplex_variables

  type(attenuation_simplex_variables) AS_V
! attenuation_simplex_variables

  ! Input / Output
  integer myrank, ier
  double precision  t1, t2
  double precision  Q_real
  double precision  omega_not
  integer  n
  double precision, dimension(n)   :: tau_s, tau_e

  ! Internal
  integer i, iterations, err,prnt
  double precision f1, f2, exp1,exp2,dexp, min_value
  double precision, allocatable, dimension(:) :: f
  double precision, parameter :: PI = 3.14159265358979d0
  integer, parameter :: nf = 100
  double precision, external :: attenuation_eval

  ! Values to be passed into the simplex minimization routine
  iterations = -1
  min_value  = -1.0e-4
  err        = 0
  prnt       = 0

  allocate(f(nf))
  ! Determine the min and max frequencies
  f1 = 1.0d0 / t1
  f2 = 1.0d0 / t2

  ! Determine the exponents of the frequencies
  exp1 = log10(f1)
  exp2 = log10(f2)

  if(f2 < f1 .OR. Q_real < 0.0d0 .OR. n < 1) then
     call MPI_COMM_RANK(MPI_COMM_WORLD, myrank, ier)
     call exit_MPI(myrank, 'frequencies flipped or Q less than zero or N_SLS < 0')
  endif

  ! Determine the Source frequency
  omega_not =  1.0e+03 * 10.0d0**(0.5 * (log10(f1) + log10(f2)))

  ! Determine the Frequencies at which to compare solutions
  !   The frequencies should be equally spaced in log10 frequency
  do i = 1,nf
     f(i) = exp1 + ((i-1)*1.0d0 * (exp2-exp1) / ((nf-1)*1.0d0))
  enddo

  ! Set the Tau_sigma (tau_s) to be equally spaced in log10 frequency
  dexp = (exp2-exp1) / ((n*1.0d0) - 1)
  do i = 1,n
     tau_s(i) = 1.0 / (PI * 2.0d0 * 10**(exp1 + (i - 1)* 1.0d0 *dexp))
  enddo

  ! Shove the paramters into the module
  call attenuation_simplex_setup(nf,n,f,Q_real,tau_s,AS_V)

  ! Set the Tau_epsilon (tau_e) to an initial value at omega*tau = 1
  ! tan_delta = 1/Q = (tau_e - tau_s)/(2 * sqrt(tau e*tau_s))
  !    if we assume tau_e =~ tau_s
  !    we get the equation below
  do i = 1,n
     tau_e(i) = tau_s(i) + (tau_s(i) * 2.0d0/Q_real)
  enddo

  ! Run a simplex search to determine the optimum values of tau_e
  call fminsearch(attenuation_eval, tau_e, n, iterations, min_value, prnt, err,AS_V)
  if(err > 0) then
     write(*,*)'Search did not converge for an attenuation of ', Q_real
     write(*,*)'    Iterations: ', iterations
     write(*,*)'    Min Value:  ', min_value
     write(*,*)'    Aborting program'
     call MPI_COMM_RANK(MPI_COMM_WORLD, myrank, ier)
     call exit_MPI(myrank,'attenuation_simplex: Search for Strain relaxation times did not converge')
  endif
  deallocate(f)

  call attenuation_simplex_finish(AS_V)

end subroutine attenuation_invert_by_simplex

subroutine attenuation_simplex_finish(AS_V)

  implicit none

! attenuation_simplex_variables
  type attenuation_simplex_variables
    sequence
    integer nf          ! nf    = Number of Frequencies
    integer nsls        ! nsls  = Number of Standard Linear Solids
    double precision Q  ! Q     = Desired Value of Attenuation or Q
    double precision iQ ! iQ    = 1/Q
    double precision, dimension(:), pointer ::  f
    ! f = Frequencies at which to evaluate the solution
    double precision, dimension(:), pointer :: tau_s
    ! tau_s = Tau_sigma defined by the frequency range and
    !             number of standard linear solids
  end type attenuation_simplex_variables

  type(attenuation_simplex_variables) AS_V
! attenuation_simplex_variables

  deallocate(AS_V%f)
  deallocate(AS_V%tau_s)

end subroutine attenuation_simplex_finish

!   - Inserts necessary parameters into the module attenuation_simplex_variables
!   - See module for explaination
subroutine attenuation_simplex_setup(nf_in,nsls_in,f_in,Q_in,tau_s_in,AS_V)

  implicit none

! attenuation_simplex_variables
  type attenuation_simplex_variables
    sequence
    integer nf          ! nf    = Number of Frequencies
    integer nsls        ! nsls  = Number of Standard Linear Solids
    double precision Q  ! Q     = Desired Value of Attenuation or Q
    double precision iQ ! iQ    = 1/Q
    double precision, dimension(:), pointer ::  f
    ! f = Frequencies at which to evaluate the solution
    double precision, dimension(:), pointer :: tau_s
    ! tau_s = Tau_sigma defined by the frequency range and
    !             number of standard linear solids
  end type attenuation_simplex_variables

  type(attenuation_simplex_variables) AS_V
! attenuation_simplex_variables

  integer nf_in, nsls_in
  double precision Q_in
  double precision, dimension(nf_in)   :: f_in
  double precision, dimension(nsls_in) :: tau_s_in

  allocate(AS_V%f(nf_in))
  allocate(AS_V%tau_s(nsls_in))

  AS_V%nf    = nf_in
  AS_V%nsls  = nsls_in
  AS_V%f     = f_in
  AS_V%Q     = Q_in
  AS_V%iQ    = 1.0d0/AS_V%Q
  AS_V%tau_s = tau_s_in

end subroutine attenuation_simplex_setup

!   - Computes the Moduli (Maxwell Solid) for a series of
!         Standard Linear Solids
!   - Computes M1 and M2 parameters after Dahlen and Tromp pp.203
!         here called B and A after Liu et al. 1976
!   - Another formulation uses Kelvin-Voigt Solids and computes
!         Compliences J1 and J2 after Dahlen and Tromp pp.203
!
!   Input
!     nf    = Number of Frequencies
!     nsls  = Number of Standard Linear Solids
!     f     = Frequencies (in log10 of frequencies)
!                dimension(nf)
!     tau_s = Tau_sigma  Stress relaxation time (see References)
!                dimension(nsls)
!     tau_e = Tau_epislon Strain relaxation time (see References)
!                dimension(nsls)!
!   Output
!     B     = Real Moduli      ( M2 Dahlen and Tromp pp.203 )
!                dimension(nf)
!     A     = Imaginary Moduli ( M1 Dahlen and Tromp pp.203 )
!                dimension(nf)
!
!   Dahlen and Tromp, 1998
!      Theoretical Global Seismology
!
!   Liu et al. 1976
!      Velocity dispersion due to anelasticity: implications for seismology and mantle composition
!      Geophys, J. R. asts. Soc, Vol 47, pp. 41-58
subroutine attenuation_maxwell(nf,nsls,f,tau_s,tau_e,B,A)

  implicit none

  ! Input
  integer nf, nsls
  double precision, dimension(nf)   :: f
  double precision, dimension(nsls) :: tau_s, tau_e
  ! Output
  double precision, dimension(nf)   :: A,B

  integer i,j
  double precision w, pi, demon

  PI = 3.14159265358979d0

  A(:) = 1.0d0 -  nsls*1.0d0
  B(:) = 0.0d0
  do i = 1,nf
     w = 2.0d0 * PI * 10**f(i)
     do j = 1,nsls
!        write(*,*)j,tau_s(j),tau_e(j)
        demon = 1.0d0 + w**2 * tau_s(j)**2
        A(i) = A(i) + ((1.0d0 + (w**2 * tau_e(j) * tau_s(j)))/ demon)
        B(i) = B(i) + ((w * (tau_e(j) - tau_s(j))) / demon)
     end do
!     write(*,*)A(i),B(i),10**f(i)
  enddo

end subroutine attenuation_maxwell

!    - Computes the misfit from a set of relaxation paramters
!          given a set of frequencies and target attenuation
!    - Evaluates only at the given frequencies
!    - Evaluation is done with an L2 norm
!
!    Input
!      Xin = Tau_epsilon, Strain Relaxation Time
!                Note: Tau_sigma the Stress Relaxation Time is loaded
!                      with attenuation_simplex_setup and stored in
!                      attenuation_simplex_variables
!
!    Xi = Sum_i^N sqrt [ (1/Qc_i - 1/Qt_i)^2 / 1/Qt_i^2 ]
!
!     where Qc_i is the computed attenuation at a specific frequency
!           Qt_i is the desired attenuaiton at that frequency
!
!    Uses attenuation_simplex_variables to store constant values
!
!    See atteunation_simplex_setup
!
double precision function attenuation_eval(Xin,AS_V)

  implicit none

! attenuation_simplex_variables
  type attenuation_simplex_variables
    sequence
    integer nf          ! nf    = Number of Frequencies
    integer nsls        ! nsls  = Number of Standard Linear Solids
    double precision Q  ! Q     = Desired Value of Attenuation or Q
    double precision iQ ! iQ    = 1/Q
    double precision, dimension(:), pointer ::  f
    ! f = Frequencies at which to evaluate the solution
    double precision, dimension(:), pointer :: tau_s
    ! tau_s = Tau_sigma defined by the frequency range and
    !             number of standard linear solids
  end type attenuation_simplex_variables

  type(attenuation_simplex_variables) AS_V
! attenuation_simplex_variables

   ! Input
  double precision, dimension(AS_V%nsls) :: Xin
  double precision, dimension(AS_V%nsls) :: tau_e

  double precision, dimension(AS_V%nf)   :: A, B, tan_delta

  integer i
  double precision xi, iQ2

  tau_e = Xin

  call attenuation_maxwell(AS_V%nf,AS_V%nsls,AS_V%f,AS_V%tau_s,tau_e,B,A)

  tan_delta = B / A

  attenuation_eval = 0.0d0
  iQ2 = AS_V%iQ**2
  do i = 1,AS_V%nf
     xi = sqrt(( ( (tan_delta(i) - AS_V%iQ) ** 2 ) / iQ2 ))
     attenuation_eval = attenuation_eval + xi
  enddo

end function attenuation_eval

! subroutine fminsearch
!   - Computes the minimization of funk(x(n)) using the simplex method
!   - This subroutine is copied from Matlab fminsearch.m
!         and modified to suit my nefarious needs
!   Input
!     funk = double precision function with one input parameter
!                double precision function the_funk(x)
!     x    = Input/Output
!               variables to be minimized
!               dimension(n)
!            Input:  Initial Value
!            Output: Mimimized Value
!     n    = number of variables
!     itercount = Input/Output
!                 Input:  maximum number of iterations
!                         if < 0 default is used (200 * n)
!                 Output: total number of iterations on output
!     tolf      = Input/Output
!                 Input:  minimium tolerance of the function funk(x)
!                 Output: minimium value of funk(x)(i.e. "a" solution)
!     prnt      = Input
!                 3 => report every iteration
!                 4 => report every iteration, total simplex
!     err       = Output
!                 0 => Normal exeecution, converged within desired range
!                 1 => Function Evaluation exceeded limit
!                 2 => Iterations exceeded limit
!
!     See Matlab fminsearch
subroutine fminsearch(funk, x, n, itercount, tolf, prnt, err, AS_V)

  implicit none

! attenuation_simplex_variables
  type attenuation_simplex_variables
    sequence
    integer nf          ! nf    = Number of Frequencies
    integer nsls        ! nsls  = Number of Standard Linear Solids
    double precision Q  ! Q     = Desired Value of Attenuation or Q
    double precision iQ ! iQ    = 1/Q
    double precision, dimension(:), pointer ::  f
    ! f = Frequencies at which to evaluate the solution
    double precision, dimension(:), pointer :: tau_s
    ! tau_s = Tau_sigma defined by the frequency range and
    !             number of standard linear solids
  end type attenuation_simplex_variables

  type(attenuation_simplex_variables) AS_V
! attenuation_simplex_variables

  ! Input
  double precision, external :: funk

  integer n
  double precision x(n) ! Also Output
  integer itercount, prnt, err
  double precision tolf

  !Internal
  integer i,j, how
  integer, parameter :: none             = 0
  integer, parameter :: initial          = 1
  integer, parameter :: expand           = 2
  integer, parameter :: reflect          = 3
  integer, parameter :: contract_outside = 4
  integer, parameter :: contract_inside  = 5
  integer, parameter :: shrink           = 6

  integer maxiter, maxfun
  integer func_evals
  double precision tolx

  double precision rho, chi, psi, sigma
  double precision xin(n), y(n), v(n,n+1), fv(n+1)
  double precision vtmp(n,n+1)
  double precision usual_delta, zero_term_delta
  double precision xbar(n), xr(n), fxr, xe(n), fxe, xc(n), fxc, fxcc, xcc(n)
  integer place(n+1)

  double precision max_size_simplex, max_value

  rho   = 1.0d0
  chi   = 2.0d0
  psi   = 0.5d0
  sigma = 0.5d0


  if(itercount > 0) then
     maxiter = itercount
  else
     maxiter = 200 * n
  endif
  itercount = 0
  maxfun  = 200 * n

  if(tolf > 0.0d0) then
     tolx = 1.0e-4
  else
     tolx = 1.0e-4
     tolf = 1.0e-4
  endif

  err = 0

  xin    = x
  v(:,:) = 0.0d0
  fv(:)  = 0.0d0

  v(:,1) = xin
  x      = xin

  fv(1) = funk(xin,AS_V)

  usual_delta = 0.05
  zero_term_delta = 0.00025

  do j = 1,n
     y = xin
     if(y(j) /= 0.0d0) then
        y(j) = (1.0d0 + usual_delta) * y(j)
     else
        y(j) = zero_term_delta
     endif
     v(:,j+1) = y
     x(:) = y
     fv(j+1) = funk(x,AS_V)
  enddo

  call qsort_local(fv,n+1,place)

  do i = 1,n+1
     vtmp(:,i) = v(:,place(i))
  enddo
  v = vtmp

  how = initial
  itercount = 1
  func_evals = n+1
  if(prnt == 3) then
     write(*,*)'Iterations   Funk Evals   Value How'
     write(*,*)itercount, func_evals, fv(1), how
  endif
  if(prnt == 4) then
     write(*,*)'How: ',how
     write(*,*)'V: ', v
     write(*,*)'fv: ',fv
     write(*,*)'evals: ',func_evals
  endif

  do while (func_evals < maxfun .AND. itercount < maxiter)

     if(max_size_simplex(v,n) <= tolx .AND. &
          max_value(fv,n+1) <= tolf) then
        goto 666
     endif
     how = none

     ! xbar = average of the n (NOT n+1) best points
     !     xbar = sum(v(:,1:n), 2)/n
     xbar(:) = 0.0d0
     do i = 1,n
        do j = 1,n
           xbar(i) = xbar(i) + v(i,j)
        enddo
        xbar(i) = xbar(i) / (n*1.0d0)
     enddo
     xr = (1 + rho)*xbar - rho*v(:,n+1)
     x(:) = xr
     fxr = funk(x,AS_V)
     func_evals = func_evals + 1
     if (fxr < fv(1)) then
        ! Calculate the expansion point
        xe = (1 + rho*chi)*xbar - rho*chi*v(:,n+1)
        x = xe
        fxe = funk(x,AS_V)
        func_evals = func_evals+1
        if (fxe < fxr) then
           v(:,n+1) = xe
           fv(n+1) = fxe
           how = expand
        else
           v(:,n+1) = xr
           fv(n+1) = fxr
           how = reflect
        endif
     else ! fv(:,1) <= fxr
        if (fxr < fv(n)) then
           v(:,n+1) = xr
           fv(n+1) = fxr
           how = reflect
        else ! fxr >= fv(:,n)
           ! Perform contraction
           if (fxr < fv(n+1)) then
              ! Perform an outside contraction
              xc = (1 + psi*rho)*xbar - psi*rho*v(:,n+1)
              x(:) = xc
              fxc = funk(x,AS_V)
              func_evals = func_evals+1

              if (fxc <= fxr) then
                 v(:,n+1) = xc
                 fv(n+1) = fxc
                 how = contract_outside
              else
                 ! perform a shrink
                 how = shrink
              endif
           else
              ! Perform an inside contraction
              xcc = (1-psi)*xbar + psi*v(:,n+1)
              x(:) = xcc
              fxcc = funk(x,AS_V)
              func_evals = func_evals+1

              if (fxcc < fv(n+1)) then
                 v(:,n+1) = xcc
                 fv(n+1) = fxcc
                 how = contract_inside
              else
                 ! perform a shrink
                 how = shrink
              endif
           endif
           if (how == shrink) then
              do j=2,n+1
                 v(:,j)=v(:,1)+sigma*(v(:,j) - v(:,1))
                 x(:) = v(:,j)
                 fv(j) = funk(x,AS_V)
              enddo
              func_evals = func_evals + n
           endif
        endif
     endif

     call qsort_local(fv,n+1,place)
     do i = 1,n+1
        vtmp(:,i) = v(:,place(i))
     enddo
     v = vtmp

     itercount = itercount + 1
     if (prnt == 3) then
        write(*,*)itercount, func_evals, fv(1), how
     elseif (prnt == 4) then
        write(*,*)
        write(*,*)'How: ',how
        write(*,*)'v: ',v
        write(*,*)'fv: ',fv
        write(*,*)'evals: ',func_evals
     endif
  enddo

  if(func_evals > maxfun) then
     write(*,*)'function evaluations exceeded prescribed limit', maxfun
     err = 1
  endif
  if(itercount > maxiter) then
     write(*,*)'iterations exceeded prescribed limit', maxiter
     err = 2
  endif

666 continue
  x = v(:,1)
  tolf = fv(1)

end subroutine fminsearch

!    - Finds the maximim value of the difference of between the first
!          value and the remaining values of a vector
!    Input
!      fv = Input
!             Vector
!             dimension(n)
!      n  = Input
!             Length of fv
!
!      Returns:
!         Xi = max( || fv(1)- fv(i) || ) for i=2:n
!
double precision function max_value(fv,n)
  implicit none
  integer n
  double precision fv(n)

  integer i
  double precision m, z

  m = 0.0d0
  do i = 2,n
     z = abs(fv(1) - fv(i))
     if(z > m) then
        m = z
     endif
  enddo

  max_value = m

end function max_value

!   - Determines the maximum distance between two point in a simplex
!   Input
!     v  = Input
!            Simplex Verticies
!            dimension(n, n+1)
!     n  = Pseudo Length of n
!
!     Returns:
!       Xi = max( max( || v(:,1) - v(:,i) || ) ) for i=2:n+1
!
double precision function max_size_simplex(v,n)
  implicit none
  integer n
  double precision v(n,n+1)

  integer i,j
  double precision m, z

  m = 0.0d0
  do i = 1,n
     do j = 2,n+1
        z = abs(v(i,j) - v(i,1))
        if(z > m) then
           m = z
        endif
     enddo
  enddo

  max_size_simplex = m

end function max_size_simplex

!    - Implementation of a Bubble Sort Routine
!    Input
!      X = Input/Output
!         Vector to be sorted
!         dimension(n)
!      n = Input
!         Length of X
!      I = Output
!         Sorted Indicies of vecotr X
!
!      Example:
!         X = [ 4 3 1 2 ] on Input
!         I = [ 1 2 3 4 ] Computed Internally (in order)
!
!         X = [ 1 2 3 4 ] on Output
!         I = [ 3 4 2 1 ] on Output
!
subroutine qsort_local(X,n,I)

  implicit none

  integer n
  double precision X(n)
  integer I(n)

  integer j,k
  double precision rtmp
  integer itmp

  do j = 1,n
     I(j) = j
  enddo

  do j = 1,n
     do k = 1,n-j
        if(X(k+1) < X(k)) then
           rtmp   = X(k)
           X(k)   = X(k+1)
           X(k+1) = rtmp

           itmp   = I(k)
           I(k)   = I(k+1)
           I(k+1) = itmp
        endif
     enddo
  enddo

end subroutine qsort_local

! Piecewise Continuous Splines
!   - Added Steps which describes the discontinuities
!   - Steps must be repeats in the dependent variable, X
!   - Derivates at the steps are computed using the point
!     at the derivate and the closest point within that piece
!   - A point lying directly on the discontinuity will recieve the
!     value of the first or smallest piece in terms of X
!   - Beginning and Ending points of the Function become beginning
!     and ending points of the first and last splines
!   - A Step with a value of zero is undefined
!   - Works with functions with steps or no steps
! See the comment below about the ScS bug
subroutine pspline_evaluation(xa, ya, y2a, n, x, y, steps)

  implicit none

  integer n
  double precision xa(n),ya(n),y2a(n)
  integer steps(n)
  double precision x, y

  integer i, l, n1, n2

  do i = 1,n-1,1
     if(steps(i+1) == 0) return
     if(x >= xa(steps(i)) .and. x <= xa(steps(i+1))) then
        call pspline_piece(i,n1,n2,l,n,steps)
        call spline_evaluation(xa(n1), ya(n1), y2a(n1), l, x, y)
!        return <-- Commented out to fix ScS bug
     endif
  enddo

end subroutine pspline_evaluation

subroutine pspline_piece(i,n1,n2,l,n,s)

  implicit none

  integer i, n1, n2, l, n, s(n)
  n1 = s(i)+1
  if(i == 1) n1 = s(i)
  n2 = s(i+1)
  l = n2 - n1 + 1

end subroutine pspline_piece

subroutine pspline_construction(x, y, n, yp1, ypn, y2, steps)

  implicit none

  integer n
  double precision x(n),y(n),y2(n)
  double precision yp1, ypn
  integer steps(n)

  integer i,r, l, n1,n2

  steps(:) = 0

  ! Find steps in x, defining pieces
  steps(1) = 1
  r = 2
  do i = 2,n
     if(x(i) == x(i-1)) then
        steps(r) = i-1
        r = r + 1
     endif
  end do
  steps(r) = n

  ! Run spline for each piece
  do i = 1,r-1
     call pspline_piece(i,n1,n2,l,n,steps)
     ! Determine the First Derivates at Begin/End Points
     yp1 = ( y(n1+1) - y(n1) ) / ( x(n1+1) - x(n1))
     ypn = ( y(n2) - y(n2-1) ) / ( x(n2) - x(n2-1))
     call spline_construction(x(n1),y(n1),l,yp1,ypn,y2(n1))
  enddo

end subroutine pspline_construction

subroutine attenuation_model_1D_PREM(x, Qmu, iflag)

! x in the radius from 0 to 1 where 0 is the center and 1 is the surface
! This version is for 1D PREM.

  implicit none

  include 'constants.h'

  integer iflag
  double precision r, x, Qmu,RICB,RCMB, &
      RTOPDDOUBLEPRIME,R600,R670,R220,R771,R400,R80, ROCEAN, RMOHO, RMIDDLE_CRUST
  double precision Qkappa

  r = x * R_EARTH

  ROCEAN = 6368000.d0
  RMIDDLE_CRUST = 6356000.d0
  RMOHO = 6346600.d0
  R80  = 6291000.d0
  R220 = 6151000.d0
  R400 = 5971000.d0
  R600 = 5771000.d0
  R670 = 5701000.d0
  R771 = 5600000.d0
  RTOPDDOUBLEPRIME = 3630000.d0
  RCMB = 3480000.d0
  RICB = 1221000.d0

! PREM
!
!--- inner core
!
  if(r >= 0.d0 .and. r <= RICB) then
     Qmu=84.6d0
     Qkappa=1327.7d0
!
!--- outer core
!
  else if(r > RICB .and. r <= RCMB) then
     Qmu=0.0d0
     Qkappa=57827.0d0
     if(RCMB - r < r - RICB) then
        Qmu = 312.0d0  ! CMB
     else
        Qmu = 84.6d0   ! ICB
     endif
!
!--- D" at the base of the mantle
!
  else if(r > RCMB .and. r <= RTOPDDOUBLEPRIME) then
     Qmu=312.0d0
     Qkappa=57827.0d0
!
!--- mantle: from top of D" to d670
!
  else if(r > RTOPDDOUBLEPRIME .and. r <= R771) then
     Qmu=312.0d0
     Qkappa=57827.0d0
  else if(r > R771 .and. r <= R670) then
     Qmu=312.0d0
     Qkappa=57827.0d0
!
!--- mantle: above d670
!
  else if(r > R670 .and. r <= R600) then
     Qmu=143.0d0
     Qkappa=57827.0d0
  else if(r > R600 .and. r <= R400) then
     Qmu=143.0d0
     Qkappa=57827.0d0
  else if(r > R400 .and. r <= R220) then
     Qmu=143.0d0
     Qkappa=57827.0d0
  else if(r > R220 .and. r <= R80) then
     Qmu=80.0d0
     Qkappa=57827.0d0
  else if(r > R80) then
     Qmu=600.0d0
     Qkappa=57827.0d0
  endif

  ! We determine the attenuation value here dependent on the doubling flag and
  ! which region we are sitting in. The radius reported is not accurate for
  ! determination of which region we are actually in, whereas the idoubling flag is
  if(iflag == IFLAG_INNER_CORE_NORMAL .or. iflag == IFLAG_MIDDLE_CENTRAL_CUBE .or. &
       iflag == IFLAG_BOTTOM_CENTRAL_CUBE .or. iflag == IFLAG_TOP_CENTRAL_CUBE .or. &
       iflag == IFLAG_IN_FICTITIOUS_CUBE) then
     Qmu =  84.6d0
     Qkappa = 1327.7d0
  else if(iflag == IFLAG_OUTER_CORE_NORMAL) then
     Qmu = 0.0d0
     Qkappa = 57827.0d0
  else if(iflag == IFLAG_MANTLE_NORMAL) then ! D'' to 670 km
     Qmu = 312.0d0
     Qkappa = 57827.0d0
  else if(iflag == IFLAG_670_220) then
     Qmu=143.0d0
     Qkappa = 57827.0d0
  else if(iflag == IFLAG_220_80) then
     Qmu=80.0d0
     Qkappa = 57827.0d0
  else if(iflag == IFLAG_80_MOHO) then
     Qmu=600.0d0
     Qkappa = 57827.0d0
  else if(iflag == IFLAG_CRUST) then
     Qmu=600.0d0
     Qkappa = 57827.0d0
  else
     write(*,*)'iflag:',iflag
     call exit_MPI_without_rank('Invalid idoubling flag in attenuation_model_1D_prem from get_model()')
  endif

end subroutine attenuation_model_1D_PREM


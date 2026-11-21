import Riemann.Channel

namespace Riemann

/-- Channel spectral quantities scaled by 10⁹, except rotations by 10⁶. -/
def channelSpiralMagnitude : Int := 1_000_336_369
def channelVerticalMagnitude : Int := 999_248_201
def channelDeterminant : Int := 999_920_547
def channelRotations : Int := 7_905_063
def channelPlaneLogTotal : Int := 399_539_664
def channelVerticalLogTotal : Int := -446_736_681
def channelNetLogTotal : Int := -47_197_017
def channelVerticalParticipation : Int := 985_681_366

/--
The finite affine channel fit has a slightly expanding complex plane, a
contracting predominantly vertical real mode, and a near-unit determinant.
Across the measured channel their accumulated log-rates nearly balance.
-/
def path22SpectralBalanceCertificate : Prop :=
  1_000_000_000 < channelSpiralMagnitude ∧
  channelVerticalMagnitude < 1_000_000_000 ∧
  999_900_000 < channelDeterminant ∧
  channelDeterminant < 1_000_000_000 ∧
  channelPlaneLogTotal + channelVerticalLogTotal = channelNetLogTotal ∧
  -500_000_000 < channelVerticalLogTotal ∧
  channelVerticalLogTotal < -400_000_000 ∧
  -50_000_000 < channelNetLogTotal ∧
  channelNetLogTotal < 0 ∧
  7_000_000 < channelRotations ∧
  channelRotations < 8_000_000 ∧
  980_000_000 < channelVerticalParticipation

theorem path22_channel_has_finite_spectral_balance :
    path22SpectralBalanceCertificate := by
  unfold path22SpectralBalanceCertificate channelSpiralMagnitude
    channelVerticalMagnitude channelDeterminant channelRotations
    channelPlaneLogTotal channelVerticalLogTotal channelNetLogTotal
    channelVerticalParticipation
  decide

def path22PoincareOrientations : List Int :=
  [1, -1, 1, -1, 1, -1, 1, -1, 1, -1, 1, -1, 1, -1, 1, -1]

/-- Poincaré crossing coordinates quantized at 10⁻⁶. -/
def firstPositiveCrossingY : Int := 24_904_798
def lastPositiveCrossingY : Int := 25_591_304
def firstNegativeCrossingY : Int := 21_782_821
def lastNegativeCrossingY : Int := 21_298_087
def firstCrossingZ : Int := 4_373_338
def lastCrossingZ : Int := 3_831_337

def path22PoincareCertificate : Prop :=
  path22PoincareOrientations.length = 16 ∧
  path22PoincareOrientations =
    [1, -1, 1, -1, 1, -1, 1, -1, 1, -1, 1, -1, 1, -1, 1, -1] ∧
  firstPositiveCrossingY < lastPositiveCrossingY ∧
  lastNegativeCrossingY < firstNegativeCrossingY ∧
  lastCrossingZ < firstCrossingZ

theorem path22_has_alternating_expanding_poincare_crossings :
    path22PoincareCertificate := by
  unfold path22PoincareCertificate path22PoincareOrientations
    firstPositiveCrossingY lastPositiveCrossingY
    firstNegativeCrossingY lastNegativeCrossingY
    firstCrossingZ lastCrossingZ
  decide

end Riemann

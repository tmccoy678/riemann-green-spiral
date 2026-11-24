# Path 22 entry-wave view

Date: 2026-11-24  
Status: reproducible geometry check

## Question

Does the incoming portion of Path 22, viewed from the side and in its native
order, have a wave-like profile before it enters the recurrent spiral channel?

## Frozen segment

The segment begins at the measured lower-`y` field edge found by integrating
the original `wind.mat` field backward from `(80,20,6)`. It continues through
the original seed and ends at forward sample 1176, the previously declared
start of the central recurrent channel.

The segment boundary is inherited from earlier work and is not selected from
the side-view result.

## Coordinates

- ordering coordinate: cumulative three-dimensional arc length `s`;
- vertical side profile: `z(s)`;
- transverse side profile: displacement perpendicular to the horizontal chord
  joining the field edge to the channel-entry endpoint;
- top view: the original `(x,y)` coordinates.

A straight reference is the endpoint chord in each side profile. The analysis
records residual turning points and a descriptive dominant cycle count after
linear detrending. These quantities describe the measured streamline geometry;
they do not identify a physical propagating wave or a particle clock.


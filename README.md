Tue Mar  3 15:48:38 2015  jpmorgen@snipe

This contains the Solar System Object package (SSO) , which works
together with the Parameterized Function Object (PFO) package to fit
spectra of sunlit solar system objects recorded at high spectroscopic
resolving power.  The package tracks the relative Doppler shifts of
the sun, solar system object(s) and the observer to predict line
positions in the observer's frame.  It adds structure elements to the
parinfo in the PFO system to do this.  It currently works with the
ssg_pfo branch of PFO and is called from ssg_fit1spec and related
routines in the ssg (Solar-Stellar Spectrograph) package.


# notchNLModel

## WHAT IS IT?

This is a restricted version of the notch signalling model designed to allow reviewers to explore the range of results provided in the accompanying paper.  The goal of this program to provide reviewers of immediate results.  The only allowed modified parameters are those identified in the paper and uses a continually changing random seed value.  The parameters that can be modified are: Notch Cleaved Time, Delta Transform Time, Notch Initial, and Delta Initial.

## HOW IT IS USED

The four control buttons on the upper-left of the netlogo model perform the following:

 * __Setup__ : will clear any running simulation, then rebuild a new simulation set up with the given parameters.
 * __Go While Pressed__ : A press button that will run the simulation until it is pressed a second time, stopping the simulation.
 * __Go 1 tick__ : will increment the model by one time step.
 * __Go 1000 ticks__ : will increment the model by 1000 time steps.

The sliders can be changed, modifying the parameter values at anytime during the model execution.  When the setup of the model is performed, these parameters are not fixed, thus changing these sliders will alter the model functionality from that point forward.

The current-seed is for display only, changing the value will have no effect.  To change the speed by which the model is run, use the speed slider at the top of the simulation.  To visualize all components on smaller screens, use the zoom drop-down menu to reduce the size of the viewable space.

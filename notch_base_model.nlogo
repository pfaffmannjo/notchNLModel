;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                        ;;;
;;;  Copyright 2017 Jeffrey Pfaffmann and Elaine Reynolds                  ;;;
;;;                                                                        ;;;
;;;  This program is free software: you can redistribute it and/or modify  ;;;
;;;  it under the terms of the GNU General Public License as published by  ;;;
;;;  the Free Software Foundation, either version 3 of the License, or     ;;;
;;;  (at your option) any later version.                                   ;;;
;;;                                                                        ;;;
;;;  This program is distributed in the hope that it will be useful,       ;;;
;;;  but WITHOUT ANY WARRANTY; without even the implied warranty of        ;;;
;;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         ;;;
;;;  GNU General Public License for more details.                          ;;;
;;;                                                                        ;;;
;;;  You should have received a copy of the GNU General Public License     ;;;
;;;  along with this program.  If not, see http://www.gnu.org/licenses/    ;;;
;;;                                                                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

globals [

  ;;;; Used to determine the border around the cell sheet.
  ;;;; Thus these are cosmetic and to not contribute to simulation.

  diameter                 ;;;; diameter of the cell
  lipid-distance           ;;;; distance between lipids on the membrane

  delta-transcription-rate ;;;;; computed rate modulated by cleaved notch
  notch-transcription-rate ;;;;; computed rate modulated by cleaved notch

  unitMove                 ;;;;; computed move on radius

  radius
  radiusFraction
  lipid-density
  notch-cleaved-diffusion-time-signal
  cell-row-cnt
  cell-col-cnt
  centersomeSize
  deltaAge
  notchAge

]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; create breeds ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;=====================================================================
;; the central nucleus

breed [nucleus-breed    nucleus]

nucleus-breed-own [

  lipid-set    ;-- set of lipids owned by nucleus
  lipid-start  ;-- first id in range of lipid names
  lipid-end    ;-- last id in range of lipid names

  cleaved-nuc-notch-count-value

  roset-neighbors
  currentNuclearNotchCnt
  placed
]
;;=====================================================================


;;=====================================================================
;; the proteins that compose the membrane

breed [lipid-breed lipid]

lipid-breed-own [

  parent     ;-- owning nucleus
  parent-who ;-- owning nucleus id

  left-mem  ;-- lipid to left
  right-mem ;-- lipid to right

  curr-proteins ;-- membrane proteins currently stored at that region
  border-region ;-- the lipids in the neighboring cell region
]
;;=====================================================================


;;=====================================================================
;; recently transcribed delta transporting to membrane

breed [delta-breed       delta]

delta-breed-own [
  birth      ;-- the tick that the delta was created
  parent     ;-- owning nucleus
  parent-who ;-- owning nucleus id
  mem-time   ;-- the time delta became a membrane.
]
;;=====================================================================


;;=====================================================================
;; the delta diffusing on the membrane

breed [delta-mem-breed   delta-mem]

delta-mem-breed-own [
  birth       ;-- the tick that the original delta was created
  local-lipid ;-- the lipid that the membrane delta is associated with
  parent      ;-- owning nucleus
  parent-who  ;-- owning nucleus id
  mem-time    ;-- the time delta became a membrane.
]
;;=====================================================================



;;=====================================================================
;; the delta diffusing on the membrane in active form

breed [delta-mem-prime-breed   delta-mem-prime]

delta-mem-prime-breed-own [
  birth       ;-- the tick that the original delta was created
  local-lipid ;-- the lipid that the membrane delta prime is associated with
  parent      ;-- owning nucleus
  parent-who  ;-- owning nucleus id
  mem-time    ;-- the time delta became a membrane.
]
;;=====================================================================


;;=====================================================================
;; recently transcribed notch transporting to membrane

breed [notch-breed      notch]

notch-breed-own [
  birth      ;-- the tick that the notch was created
  parent     ;-- owning nucleus
  parent-who ;-- owning nucleus id
]
;;=====================================================================


;;=====================================================================
;; notch that is diffusing on membrane

breed [notch-mem-breed  notch-mem]

notch-mem-breed-own [
  birth       ;-- the tick that the original notch was created
  parent      ;-- owning nucleus
  parent-who  ;-- owning nucleus id
  local-lipid ;-- the lipid that the membrane notch is associated with
  protected
]
;;=====================================================================


;;=====================================================================
;; diffusing notch

breed [cleaved-notch-breed  cleaved-notch]

cleaved-notch-breed-own [
  birth       ;-- the tick that the original notch was created
  parent      ;-- owning nucleus
  parent-who  ;-- owning nucleus id
  time-cleaved;-- time the protein was cleaved and sent to nucleus
  indCleavedDiffTime
]
;;=====================================================================


;;=====================================================================
;; cleaved notch that has reached nucleus and modulating transcription

breed [notch-nuc-breed  nucleus-notch]

notch-nuc-breed-own [
  birth       ;-- the tick that the original notch was created
  parent      ;-- owning nucleus
  parent-who  ;-- owning nucleus id
  time-cleaved;-- time the protein was cleaved and sent to nucleus
  indCleavedDiffTime
  time-nuc    ;-- time the protein was cleaved and sent to nucleus
]
;;=====================================================================


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; setup proceedure   ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; executed initially ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup

  ;;--------------------------------------------------
  ;; initialize the space as empty
  clear-all
  ;;--------------------------------------------------

  ;;--------------------------------------------------
  ;; establish the random seed
  set current-seed new-seed
  random-seed current-seed
  ;;--------------------------------------------------

  ;;--------------------------------------------------
  ;; initialize all globals
  set radius          10
  set radiusFraction  0.0550
  set diameter        (radius * 2)
  set lipid-density    12

  set cell-row-cnt      7
  set cell-col-cnt     11
  set centersomeSize   10
  set deltaAge        400
  set notchAge        400


  set notch-cleaved-diffusion-time-signal (notch-cleaved-diffusion-time / 4.0)

  set lipid-distance     (radius / lipid-density)

  ;; specifies the granularity of the physical space and influences
  ;; distance components move.
  set unitMove (radius * radiusFraction)

  ;;--------------------------------------------------
  ;; initialize transcription to base rate
  set delta-transcription-rate delta-transcription-initial-rate
  set notch-transcription-rate notch-transcription-initial-rate
  ;;--------------------------------------------------

  ;;--------------------------------------------------
  ;; create the nucleus-breed
  layout-nucleus-breed-sheet
  ;;--------------------------------------------------

  ;;--------------------------------------------------
  ;; ask all nucleus to create a roset neighbor list
  ask nucleus-breed [
    set roset-neighbors (turtle-set nucleus-breed with [(self != myself) and (distance myself) < (diameter + 1)])
  ]
  ;;--------------------------------------------------

  ;;--------------------------------------------------
  ;; create the cell lipids
  layout-lipids
  ;;--------------------------------------------------

  reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;; go proceedure      ;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;; run with each tick ;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go-1

  go-x 1

end

to go-1000

  go-x 1000

end

to go-x [interations]

  print (word " ticks " ticks "   :  " date-and-time )

  repeat interations [go]

end


to go

  age-out-proteins    ;; remove proteins that have hit the maximum age

  plot-current-data

  transcribe-proteins ;; transcribe any new proteins

  diffuse-proteins    ;; diffuse all diffusable components

  transform-proteins  ;; perform all interprotein manipulations

  tick                ;; clock tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;; eliminate old proteins ;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; ageout mechanism for the model
to age-out-proteins

  ask delta-breed            with [ticks > ( birth + deltaAge )] [ die ]
  ask delta-mem-breed        with [ticks > ( birth + deltaAge )] [ die ]
  ask delta-mem-prime-breed  with [ticks > ( birth + deltaAge )] [ die ]

  ask notch-breed            with [ticks > ( birth + notchAge )] [ die ]
  ask notch-mem-breed        with [ticks > ( birth + notchAge )] [ die ]

  ; cleaved notch also provides protein tracking information
  ask cleaved-notch-breed    with [ticks > ( birth + notchAge )] [ die ]

  ; protein production signal value is reduced as nuclear notch is
  ; removed
  ask notch-nuc-breed        with [ticks > ( birth + notchAge )] [

    ask parent [
      set cleaved-nuc-notch-count-value ( cleaved-nuc-notch-count-value - 1 )
    ]

    die
  ]

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;; transcribe proteins ;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to transcribe-proteins

  ask nucleus-breed [

    set notch-transcription-rate (notch-transcription-initial-rate + cleaved-nuc-notch-count-value)
    set delta-transcription-rate (delta-transcription-initial-rate - cleaved-nuc-notch-count-value)

    ;; transcribe notch proteins
    if notch-transcription-rate >= random 100 [
      hatch-notch-breed 1 [
        set birth ticks
        set heading    (random 360)
        set color      blue
        set shape      "diffuser1"
        set parent     myself
        set parent-who [who] of myself
      ]
    ]

    ;; transcribe delta proteins
    if delta-transcription-rate >= random 100 [
      hatch-delta-breed 1 [
        set birth      ticks
        set heading    (random 360)
        set color      red
        set shape      "diffuser1"
        set parent     myself
        set parent-who [who] of myself
      ]
    ]
  ]

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;; move proteins around cellspace ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to diffuse-proteins

  ;;--------------------------------------------------
  ;; diffuse non-lipid bound components
  diffuse-cytosol-proteins
  ;;--------------------------------------------------

  ;;--------------------------------------------------
  ;; diffuse proteins on lipid surface
  diffuse-lipid-proteins
  ;;--------------------------------------------------

end


;; proteins diffuse in cytosol by moving is specfic directions
;; or randomly moving.  The lipids help keep proteins from wandering
;; beyond the cell edge.
to diffuse-cytosol-proteins

  ;; diffuse transcribed delta-breed
  ask delta-breed [
    forward unitMove * 0.5
  ]

  ;; diffuse transcribed notches
  ask notch-breed [
    forward unitMove * 0.5
  ]

end


;; proteins diffuse on the membranes by initially aligning with a
;; given lipid and then moving the the lipid on left or right
to diffuse-lipid-proteins

  let result 0

  ;; Ask lipid diffusers to move along the lipid
  ;; with equal probability of going left, right, or
  ;; remaining in the same location.

  ask lipid-breed [
    set curr-proteins nobody
  ]

  ask notch-mem-breed [

    set result (random 3)

    if result = 0 [

      set local-lipid    [left-mem]  of local-lipid
      set xcor           [xcor]      of local-lipid
      set ycor           [ycor]      of local-lipid
      set heading        [heading]   of local-lipid
    ]

    if result = 1 [

      set local-lipid    [right-mem] of local-lipid
      set xcor           [xcor]      of local-lipid
      set ycor           [ycor]      of local-lipid
      set heading        [heading]   of local-lipid
    ]

    ask local-lipid [
      set curr-proteins (turtle-set curr-proteins myself)
    ]
  ]

  ask delta-mem-breed [

    set result (random 3)

    if result = 0 [
      set local-lipid    [left-mem]  of local-lipid
      set xcor           [xcor]      of local-lipid
      set ycor           [ycor]      of local-lipid
      set heading        [heading]   of local-lipid
    ]

    if result = 1 [
      set local-lipid    [right-mem] of local-lipid
      set xcor           [xcor]      of local-lipid
      set ycor           [ycor]      of local-lipid
      set heading        [heading]   of local-lipid
    ]

    ask local-lipid [
      set curr-proteins (turtle-set curr-proteins myself)
    ]
  ]

  ask delta-mem-prime-breed [

    set result (random 3)

    if result = 0 [
      set local-lipid    [left-mem]  of local-lipid
      set xcor           [xcor]      of local-lipid
      set ycor           [ycor]      of local-lipid
      set heading        [heading]   of local-lipid
    ]

    if result = 1 [
      set local-lipid    [right-mem] of local-lipid
      set xcor           [xcor]      of local-lipid
      set ycor           [ycor]      of local-lipid
      set heading        [heading]   of local-lipid
    ]

    ask local-lipid [
      set curr-proteins (turtle-set curr-proteins myself)
    ]
  ]

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;; additional protein manipulations ;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; these are the trickiest but critical to the proper functioning
;; of the system.
to transform-proteins

  ;;-----------------------------------------------------------------
  ;;-----------------------------------------------------------------
  ;; ask lipids to pull diffusers on to the surface
  ask lipid-breed [

    ask delta-breed in-radius (lipid-distance / 1) [

      set breed          delta-mem-breed
      set xcor           [xcor]    of myself
      set ycor           [ycor]    of myself
      set heading        [heading] of myself
      set shape          "diffuser2"
      set mem-time       ticks

      set local-lipid myself
      ask local-lipid [
        set curr-proteins (turtle-set curr-proteins myself)
      ]
    ]

    ;;-- process transcribed notches --------------------------
    ask notch-breed in-radius (lipid-distance / 1) [

      set breed          notch-mem-breed
      set xcor           [xcor] of myself
      set ycor           [ycor] of myself
      set heading        [heading] of myself
      set shape          "diffuser2"
      ;set color          blue
      set local-lipid myself
      ask local-lipid [
        set curr-proteins (turtle-set curr-proteins myself)
      ]
    ]
  ]

  ;;-----------------------------------------------------------------
  ;;-----------------------------------------------------------------
  ;; Transform membrane delta to delta prime after a specific period,
  ;; if period is zero, do it autmatically.
  ifelse delta-transform-time = 0 [

    ask delta-mem-breed [
      set breed delta-mem-prime-breed
      set color pink
    ]

  ][

    let transform-tick (ticks - delta-transform-time)
    ask delta-mem-breed [
      if mem-time < transform-tick [
        set breed delta-mem-prime-breed
        set color pink
      ]
    ]
  ]

  ;;-----------------------------------------------------------------
  ;;-----------------------------------------------------------------
  ;; ask all cleaved-notch agents to diffuse a certain amount
  ask cleaved-notch-breed with [time-cleaved + indCleavedDiffTime < ticks] [

    set heading towards parent

    forward (distance parent) - (unitMove * centersomeSize) + 3

    set breed          notch-nuc-breed

    ask parent [
      set cleaved-nuc-notch-count-value ( cleaved-nuc-notch-count-value + 1 )
    ]

    set time-nuc       ticks
  ]

  ;;-----------------------------------------------------------------
  ;;-----------------------------------------------------------------
  ;; ask delta-mem-breed to laterally protect notches
  ask notch-mem-breed [ set protected false ]

  let p nobody

  ;;-----------------------------------------------------------------
  ;;-----------------------------------------------------------------
  ;; ask delta-mem-prime-breed to horizontally cleave notches
  let cntr 0
  let region-set nobody
  let ind-to-cleave nobody

  ask delta-mem-prime-breed [

    set cntr 0

    set region-set nobody

    ask local-lipid [

      if border-region != 0 [

         ask border-region [
           set region-set (turtle-set region-set curr-proteins)
         ]

         set ind-to-cleave one-of region-set with [breed = notch-mem-breed and protected = false]

         if ind-to-cleave != nobody [

           set cntr (cntr + 1)

           ask ind-to-cleave [
             set breed           cleaved-notch-breed
             set shape           "square"
             set color           green
             set heading towards parent

             set time-cleaved    ticks
             forward unitMove * 3

             ;; establish the time to destination for the current cleaved agent
             set indCleavedDiffTime (random-normal notch-cleaved-diffusion-time notch-cleaved-diffusion-time-signal)
           ]
         ]
      ]
    ]

    if cntr > 1 [
      print (word "number of cleaved notch is " cntr)
    ]
  ]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; proceedures for ploting and storing data ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to plot-current-data

  set-current-plot "Neuron Count"
  plot neuron-cnt

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  Reporting tools                           ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report neuron-cnt

  let neuronCnt 0

  ;;--- compute neuron count
  ask nucleus-breed [

    set currentNuclearNotchCnt (count notch-nuc-breed with [parent = myself])

    if currentNuclearNotchCnt = 0 [
      set neuronCnt (neuronCnt + 1)
    ]

  ]

  report neuronCnt

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; proceedures for generating topology ;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to layout-nucleus-breed-sheet

  let total-rows cell-row-cnt
  let total-cols cell-col-cnt
  let border-size 1
  let xborder border-size
  let yborder border-size + radius

  let row-pos 0
  let col-pos 0
  let row-cnt 0
  let col-cnt 0

  while [col-pos < total-cols] [

    ifelse col-pos = 0 [
      ;; create nucleus-breed for first column
      create-nucleus-breed total-rows [

        set   color white
        set   shape "nucleus-breed"
        set   placed false

        ;; make room for a half row at the top
        setxy (radius + xborder) ( max-pycor - (radius + yborder))

      ]
    ][
      set row-cnt total-rows

      ;; create nucleus-breed for first column
      create-nucleus-breed row-cnt [

        set color    white
        set shape   "nucleus-breed"
        set placed   false

        ;; make room for a half row at the top

        set col-cnt  0
        setxy (radius + xborder) ( max-pycor - (radius + yborder))

        while [col-cnt < col-pos] [

          ifelse (col-cnt mod 2) = 0 [
            set heading  60
          ][
            set heading 120
          ]

          forward diameter
          set col-cnt col-cnt + 1
        ]
      ]
    ]

    set row-pos 0

    foreach sort-by [[who] of ?1 < [who] of ?2] (nucleus-breed with [placed = false])
    [ ask ? [

      ;; move starting column nucleus to start position
      set heading 180
      forward (row-pos * diameter)
      set row-pos row-pos + 1
      set placed true

    ] ]

    set col-pos col-pos + 1
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; misc. proceedures  ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;------------------------------------------------------
;--- generate the lipids ---------------------------
to layout-lipids

  ask nucleus-breed [

    ;--- build lipid set
    hatch-lipid-breed (lipid-density * 6) [
      set color yellow
      set shape "lipid"
      set parent myself
      set parent-who [who] of myself
    ]

    ;--- collect lipid proteins in agentset
    set lipid-set lipid-breed-here

    ;--- collect lipid proteins in ordered list
    let tempory-lipid-list sort lipid-set

    ;;;----------------------------------------------------------
    ;;;--- relate lipids to neighbors START-PROCESSING
    ; configure first lipid --------------------------------
    ask first tempory-lipid-list [
      set left-mem  (last   tempory-lipid-list)
      set right-mem (item 1 tempory-lipid-list)
    ]

    ; configure middle lipids --------------------------------
    let list-pos         1
    let middle-list-size (count lipid-set - 2)

    repeat middle-list-size [
      ask item list-pos tempory-lipid-list [
        set left-mem  item (list-pos - 1) tempory-lipid-list
        set right-mem item (list-pos + 1) tempory-lipid-list
      ]

      set list-pos (list-pos + 1)
    ]

    ; configure last lipid --------------------------------
    ask last tempory-lipid-list [
      set left-mem  (item  middle-list-size tempory-lipid-list)
      set right-mem (first                  tempory-lipid-list)
    ]
    ;;;--- relate lipids to neighbors   END-PROCESSING
    ;;;----------------------------------------------------------

    ;;;----------------------------------------------------------
    ;;;--- place lipid proteins       START-PROCESSING
    ; initialize nucleus-breed variables -----------------------------
    let lipid-cnt     0
    set lipid-start  -1

    ;--- initialize local variables ---------------------------
    let moveIncrement   (radius / lipid-density)
    let incrementSteps   0
    let hex-edge         0

    foreach tempory-lipid-list [

      if (incrementSteps = lipid-density) [
        set hex-edge       (hex-edge + 1)
        set incrementSteps 0
      ]

      ask ? [

        ;;;--- define first and last lipid in nucleus
        if [lipid-start] of myself = -1 [
          ask myself [
            set lipid-start myself
          ]
        ]

        ask myself [
          set lipid-end myself
        ]

        ;;;--- move lipid to corner
        set heading (hex-edge * 60 + 30)
        forward radius

        ;;;--- move non-corner lipid along the edge
        if incrementSteps > 0 [
          set heading (heading + 120)
          forward (incrementSteps * moveIncrement)
          set heading (heading - 90)
        ]
      ]

      set incrementSteps (incrementSteps + 1)
    ]
    ;;;--- place lipid proteins        END-PROCESSING
    ;;;----------------------------------------------------------
  ]

  draw-centersome

  let region nobody
  ask lipid-breed [

    set region lipid-breed in-cone (lipid-distance * 4) 45

    if (count region) > 1 [

      set border-region region with [self != myself]

    ]
  ]

end

to draw-centersome

  let dia    (unitMove * centersomeSize * 2)
  let circum (pi * dia)
  ask nucleus-breed [
    hatch 1 [
      set color   green
      set heading 0

      forward dia / 2
      rt 90
      pd

      forward (circum / 360)
      rt 1

      while [heading != 90] [
        forward (circum / 360)
        rt 1
      ]

      die

    ]
  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
250
10
1265
846
-1
-1
5.0
1
10
1
1
1
0
0
0
1
0
200
0
160
1
1
1
ticks
1.0

BUTTON
5
10
240
43
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
5
50
240
83
go until pressed again
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
5
90
240
123
go 1 tick
go-1
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
5
210
240
243
delta-transcription-initial-rate
delta-transcription-initial-rate
8
24
12
2
1
NIL
HORIZONTAL

SLIDER
5
170
240
203
notch-transcription-initial-rate
notch-transcription-initial-rate
8
24
12
2
1
NIL
HORIZONTAL

INPUTBOX
5
330
241
399
current-seed
920635658
1
0
Number

SLIDER
5
250
240
283
delta-transform-time
delta-transform-time
0
150
100
50
1
NIL
HORIZONTAL

SLIDER
5
290
240
323
notch-cleaved-diffusion-time
notch-cleaved-diffusion-time
75
225
125
50
1
NIL
HORIZONTAL

BUTTON
5
130
240
163
go 1000 ticks
go-1000
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1273
26
1991
396
Neuron Count
Time
Neurons
0.0
5000.0
0.0
77.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

@#$#@#$#@
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

## CREDITS AND REFERENCES

Copyright 2017 Jeffrey Pfaffmann and Elaine Reynolds

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

diffuser1
true
0
Circle -7500403 true true 108 108 85

diffuser2
true
0
Rectangle -7500403 true true 30 60 270 180

lipid
true
0
Rectangle -1184463 true false 120 15 180 285

nucleus-breed
true
0
Circle -1 true false 0 0 300
Circle -7500403 true true 33 33 234

square
true
0
Rectangle -7500403 true true 120 120 180 180

@#$#@#$#@
NetLogo 5.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
1
@#$#@#$#@

extensions [table  py  ]

globals [n_obj x y sep comp comp2 shp mean_x area colors integrator height_1 height_2 height_3 back_1 back_2 back_3]

patches-own [pluck]
turtles-own []

breed [ centroids centroid ]
breed [ bugs bug ]

bugs-own [ pluck_type ]

;; SETUP

to setup
  clear-all
  set-default-shape bugs "bug"
  set-default-shape centroids "x"

  set area world-width * pi
  set colors 3

   create-centroids 1 [
    set size 3
    set color blue
    ]

  create-bugs population
  [ set size 2         ;; easier to see
    set color blue      ;; blue = not carrying objects
    setxy random world-width  random world-height
    if not show-ants[
    set hidden? true
      ]
    ]
  ask patches [setup-patches]
  ask centroid 0 [
    setxy mean [pxcor] of patches with [pcolor != black] mean [pycor] of patches with [pcolor != black]
  ]

   py:setup py:python
  (py:run
    "import os, sys"
  )

  ;performance-metric
  reset-ticks
end

to setup-patches
  if ( random ( ( world-width ^ 2 ) / ( n_objects * colors ) ) ) < 1
      [ set pcolor ( random colors ) * 24 + red]
  ifelse pcolor = 0 [
    set pluck -1
  ]
  [
    set pluck color_to_size pcolor
  ]
end

to go
  ; black = 0
  let MAX_HEIGHT 200
  let BACK_PROPORTION .02
  let integrator_1  (max (list (density_1 * height_1 * gravity) (0)))
  let integrator_2  (max (list (( density_1 * height_1 + density_2 * height_2) * gravity) (0)))
  let integrator_3  (max (list (( density_1 * height_1 + density_2 * height_2 + density_3 * height_3) * gravity) (0)))

  set back_1 round (integrator_1 * BACK_PROPORTION * .7)
  set back_2 round (integrator_2 * BACK_PROPORTION)
  set back_3 round (integrator_3 * BACK_PROPORTION * 1.2)

  set integrator (list (integrator_1) (integrator_2) (integrator_3))

  ask bugs [

  ifelse not show-ants [set hidden? true] [set hidden? false]

  ifelse ( color != blue ) [ ; Carrying objects

   ;; RULE 1 - hit another robot or wall
   if patch-ahead 1 = nobody [
     rt 180
     rt random 10
     lt random 10

   ]
   ;; RULE 2 - hit object
      if patch-ahead 1 != nobody and (any? patches in-radius vision-distance with [pcolor != 0]) [ ; not black

      if pluck_type = 0 [
          back back_1
          set height_1 height_1 + 15
        ]

      if pluck_type = 1 [
          back back_2
          set height_2 height_2 + 15
        ]

      if pluck_type = 2 [
          back back_3
          set height_3 height_3 + 15
        ]




     if pcolor != black [ ; no drop on another object
       let candidates neighbors with [pcolor = black]
       if any? candidates [ move-to one-of candidates ]
     ]

     set pcolor color
     set color blue
     set pluck_type (-1)
     back 1
     rt one-of [ 90 270 ] ; randomly turn right or left

     ]
    fd 1
   ]

   [ ;; RULE 3 - Not Carrying objects
     if patch-ahead 1 = nobody [rt 180] ; hit a wall
     if any? patches in-radius vision-distance with [pcolor != 0]
      [
       move-to one-of patches in-radius vision-distance with [pcolor != 0]
       set color pcolor
       set pcolor 0
       set pluck_type color_to_size color
     ]
     rt random 15
     lt random 15
     fd 1
   ]


   ]

  set-plucks
  set n_obj count patches with [pcolor != black]
  if ticks mod 4 = 0[
    set height_1 max (list (height_1 - 1) (0))
    set height_1 min (list (height_1) (MAX_HEIGHT))
    set height_2 max (list (height_2 - 1) (0))
    set height_2 min (list (height_2) (MAX_HEIGHT))
    set height_3 max (list (height_3 - 1) (0))
    set height_3 min (list (height_3) (MAX_HEIGHT))
  ]

  performance-metric
  tick
end

to-report color_to_size [c]
  report (c - red) / 24
end

to set-plucks
  ask patches [
    ifelse pcolor = 0 [
      set pluck -1
    ]
    [
      set pluck color_to_size pcolor
    ]
  ]
end

to performance-metric
  let i 0
  let n_c []
  let mean_x_c [] ; mean distance to centre for objects of type c
  let q_c [] ; lower quartile of distances x_c for type c
  let p_c [] ; upper quartile
  set mean_x mean [distance centroid 0] of patches with [pcolor != black]
  set n_obj count patches with [pcolor != black]

  set x mean [pxcor] of patches with [pcolor != black]
  set y mean [pycor] of patches with [pcolor != black]

  ask centroid 0 [setxy x y ]

  ; let x_c [distance centroid 0] of objects with [size = 1]


  repeat colors [

    let distances [distance centroid 0] of patches with [pluck = i]
    ;set n_c lput count objects with [size = i] n_c
    set mean_x_c lput mean distances mean_x_c

    set q_c lput lower-quartile distances q_c
    set p_c lput upper-quartile distances p_c
    set i i + 1
  ]

   set sep separation q_c p_c
   set comp compactness
   set shp shape-metric mean_x_c
   set comp2 my_compactness

  ;show item 1 mean_x_c
end

to-report upper-quartile [ xs ]
  let med median xs
  let upper filter [ z -> z > med ] xs
  report ifelse-value empty? upper [ med ] [ median upper ]
end

to-report lower-quartile [ xs ]
  let med median xs
  let lower filter [ z -> z < med ] xs
  report ifelse-value empty? lower [ med ] [ median lower ]
end

to-report separation [q_c p_c]
  let k 1
  ;central type: distance to the centre greater than the lower quartile range of any other type
  let central count patches with [pluck = 0 and distance centroid 0 > max q_c]
  ; outer type: distance to the centre less than the upper quartile range of any other type
  let outer count patches with [pluck = (colors - 1) and distance centroid 0 < min p_c]

  let intermediate_sum []

  repeat colors - 2 [
    let intermediate_greater count patches with [pluck = k and distance centroid 0 > min q_c] / 4
    let intermediate_less count patches with [pluck = k and distance centroid 0 < max p_c] / 4
    set intermediate_sum lput ( intermediate_greater + intermediate_less ) intermediate_sum
    set k k + 1
  ]
  ;show (word "c " central " o " outer " i " intermediate_sum " obj " n_obj)
  report 100 * ( 1 - ( ( central + outer + ( sum intermediate_sum ) ) / count patches with [pluck != -1] ) )
end

to-report compactness

  let max_mean .5 * world-width
  py:set "filename" (word n_obj ".txt")
  let opt_D py:runresult "float(open(f'mean/{filename}','r').read())"

  let normalize_mean mean_x ;mean (map [n -> n / (world-width / 2)] [distance centroid 0] of objects with [carried = 0])
  set opt_D opt_D * patch-size

  ;show (word "mean " normalize_mean " opt " opt_D " dis " [distance centroid 0] of object 20)

  report 100 * ( 1 - ( normalize_mean - opt_D ) / (max_mean - opt_D))

end

to-report shape-metric [mean_x_c]
  ; Shape Metric = (Cluster Percentage + Sum of performances for each band)/ number of object types
  ; colors = n of object types
  let c 1

  let k count patches with [pluck = 0 and distance centroid 0 < ((mean_x / colors) + 1.5)]
  let n_1 count patches with [pluck = 0]




  let contrib_bands []

  repeat colors - 2 [
    let distances [distance centroid 0] of patches with [pluck = c]
    set distances map [n -> abs( n - (item c mean_x_c))] distances
    set contrib_bands lput (100 * ( 1 - ( ( sum distances ) / ( count patches with [pluck = c] * (item c mean_x_c))))) contrib_bands
    set c c + 1
  ]


  report ( 100 * (k / n_1) + sum contrib_bands / colors )
end

to-report my_compactness

  let max_d world-width / 2

  let optimal 3

  report 100 * ( 1 - ( mean_x - optimal ) / (max_d - optimal))

end
@#$#@#$#@
GRAPHICS-WINDOW
226
10
731
516
-1
-1
6.81
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
72
0
72
0
0
1
ticks
60.0

SLIDER
41
61
213
94
population
population
1
20
6.0
1
1
ants
HORIZONTAL

SLIDER
41
134
213
167
n_objects
n_objects
1
100
21.0
1
1
NIL
HORIZONTAL

BUTTON
57
24
122
57
NIL
setup\n
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
130
24
193
57
NIL
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

MONITOR
30
239
167
284
Mean distance to centroid
mean_x
3
1
11

SWITCH
43
175
215
208
show-ants
show-ants
0
1
-1000

SLIDER
748
10
920
43
cone
cone
2
90
40.0
2
1
°
HORIZONTAL

SLIDER
748
54
920
87
vision-distance
vision-distance
0.1
2
1.5
.1
1
NIL
HORIZONTAL

PLOT
736
271
1071
510
Metrics
NIL
NIL
0.0
10.0
1.0
100.0
true
true
"" " set-plot-y-range 0 100\n"
PENS
"Separation" 1.0 0 -2674135 true "" "if ticks > 10 [plot sep]"
"Compactness" 1.0 0 -13345367 true "" "if ticks > 10 [plot comp]"
"Shape" 1.0 0 -13840069 true "" "if ticks > 10 [plot shp]"

MONITOR
30
291
104
336
Separation
sep
3
1
11

MONITOR
136
293
226
338
Compactness
comp
3
1
11

MONITOR
175
239
225
284
NIL
n_obj
17
1
11

MONITOR
30
344
87
389
Shape
shp
3
1
11

TEXTBOX
84
223
234
241
----- Metrics ------
12
0.0
1

SLIDER
748
108
920
141
gravity
gravity
1
20
1.0
1
1
NIL
HORIZONTAL

SLIDER
748
156
920
189
density_1
density_1
1
20
1.0
1
1
NIL
HORIZONTAL

SLIDER
748
191
920
224
density_2
density_2
1
20
1.0
1
1
NIL
HORIZONTAL

SLIDER
748
225
920
258
density_3
density_3
1
20
1.0
1
1
NIL
HORIZONTAL

PLOT
1118
125
1286
525
Integrators
NIL
NIL
0.0
3.0
0.0
600.0
false
false
"" "clear-plot"
PENS
"default" 1.0 1 -2674135 true "" "plot item 0 integrator"
"pen-1" 1.0 1 -16777216 true "" "plotxy 0 0\nplot item 1 integrator"
"pen-2" 1.0 1 -10899396 true "" "plotxy 1 0\nplot item 2 integrator"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
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
0
@#$#@#$#@

;;razas
;;El pez representara al pez chub (Leuciscus cephalus)
breed [peces pez]
breed [insectos insecto]
;;propiedades
peces-own [edad sexo saciedad fertil? pez-contaminado? ciclo-reproduccion?]
patches-own [ cantidad concentracion-activo]
insectos-own [contaminado]
globals[
  ciclo?
  ciclo-cont
  umbral-color ; Umbral para cambiar el color del parche a rojo
  cant-hijos
  conj-patches
  edades-peces
]
;;setup
to setup
  ca
  setup-peces
  ask patches[set pcolor cyan set cantidad 0 ]
  setup-algas
  setup-insectos
  set edades-peces []
  set ciclo? false
  set ciclo-cont 30
  set umbral-color 0.5 ; Puedes ajustar el umbral según tus necesidades
  reset-ticks
end

to setup-peces
  create-peces num-peces
  [
    set shape one-of ["fish"]
    set saciedad random 70 + 1
    set edad random 8
    set xcor random-pxcor
    set ycor random-pycor
    set sexo one-of ["macho" "hembra"]
    set color ifelse-value (sexo = "macho") [blue] [red]
    ifelse edad > 2 [set fertil? true] [set fertil? false]
    set pez-contaminado? false
    set ciclo-reproduccion? false
  ]
end

to setup-algas
  ask n-of algas-inicial patches[
    set pcolor green
    set cantidad random 50 + 1
  ]
  set conj-patches(patch-set [self] of patches)
end

to crear-algas
  ask conj-patches[
    if pcolor = green [set cantidad cantidad + cantidad-algas-reproducir ]
  ]
end

to setup-insectos
  create-insectos cantidad-insectos
  [
    set shape "bug"
    set xcor random-pxcor
    set ycor random-pycor
    set color brown
  ]
end

to mover-insectos
  ask insectos [
    ;; Mover insectos de forma aleatoria
    set heading random 360
    fd 0.5
  ]
end

to go
  if ticks mod 80 = 0
  [
    cumplir-años
    reproducir
  ]
  if ciclo? [set ciclo-cont ciclo-cont - 1]
  if ciclo-cont = 0
  [
    parar-reproducir
  ]
  if ticks mod 100 = 0 [
    setup-insectos
    morir-insectos
    crear-algas
  ]

  propagar-compuesto
  if ticks mod 10 = 0[
    reducir-concentracion
  ]
  mover-insectos
  nadar-y-comer
  morir
  if count peces = 0 [stop]
  tick
end

;;instrucciones
to parar-reproducir
  ask peces with [fertil? = true] [
   set ciclo-reproduccion? false
  ]
  set ciclo? false
  set ciclo-cont 0
end
to reproducir
  set cant-hijos 0
  ask peces with [fertil? = true] [
   set ciclo-reproduccion? true
  ]
  set ciclo? true
  set ciclo-cont 20
end

to buscar-y-reproducir
  ask peces with [ciclo-reproduccion? = true and fertil? = true] [
    let posibles-parejas other peces-here in-radius 2 with [sexo != [sexo] of myself and fertil? = true and ciclo-reproduccion? = true]
    if any? posibles-parejas [
      let pareja one-of posibles-parejas
      ;; Reproducir con la pareja
      face pareja
      fd 1
      ;; Crea un nuevo pez como descendiente y establece propiedades
      if cant-hijos < 50 [ nacer-en-vecindad ]
      ask peces with [self = myself or self = pareja] [
        set ciclo-reproduccion? false
      ]
    ]
  ]
end

to nacer-en-vecindad
  let hijos random 5
  hatch hijos [
    setxy [xcor] of myself [ycor] of myself
    set sexo one-of ["macho" "hembra"]
    set fertil? false
    set edad 0
    set color ifelse-value (sexo = "macho") [blue] [red]
    set shape one-of ["fish"]
    set saciedad random 30 + 1
    set ciclo-reproduccion? false
    set pez-contaminado? false
  ]
  set cant-hijos cant-hijos + hijos
end

to morir
  ask peces [
    ifelse edad > 10 [
      if random-float 1 < calcular-probabilidad-muerte-edad [
        die
      ]
    ][
      if random-float 1 < calcular-probabilidad-muerte-edad-temprana and ticks mod 10 = 0 [
        die
      ]
    ]
    if saciedad < 1 [die]
  ]
end

to morir-insectos
  ask insectos[
    if random-float 1 < 0.3[ ; Ajusta la función según tus necesidades
        die
     ]
  ]
end
to-report calcular-probabilidad-muerte-edad-temprana
  ;; Esta función calcula la probabilidad de muerte en función de la edad
  ;; Puedes ajustar la función según tus necesidades
  let probabilidad-base 0.1 ; Probabilidad base de muerte
  report probabilidad-base * edad / 100
end

to-report calcular-probabilidad-muerte-edad
  ;; Esta función calcula la probabilidad de muerte en función de la edad
  ;; Puedes ajustar la función según tus necesidades
  let probabilidad-base 0.3 ; Probabilidad base de muerte
  report probabilidad-base * edad / 10
end

to cumplir-años
  set edades-peces []
  ask peces[
    set edad edad + 1
    if edad > 2 [set fertil? true]
    set edades-peces fput edad edades-peces
  ]
end

to nadar-y-comer
  ask peces [
    let direccion buscar-alimento
    ;;show direccion
    ifelse direccion != nobody [
      ;; Si se encontró un alimento, dirigirse hacia él y moverse hacia él
      face direccion
      fd 1

      ifelse patch-here = direccion and cantidad > 0 [
        ;; Comer la comida y aumentar la saciedad
        set saciedad saciedad + 2
        if saciedad > 100 [set saciedad 100]  ;; Limitar la saciedad a 100
        set cantidad cantidad - 1  ;; Reducir la cantidad de comida en el parche
        if cantidad = 0 [
          ;; Si la cantidad es 0, cambiar el color del parche a cyan
          set pcolor cyan
        ]
      ][
        ;; Si el pez está en el mismo parche que un insecto
        let insectos-en-parche insectos-here
        if any? insectos-en-parche [
          ;; Comer el insecto y aumentar la saciedad
          let insect one-of insectos-en-parche
          ask insect [die]  ;; Eliminar el insecto
          set saciedad saciedad + 3  ;; Ajusta según tus necesidades
          if saciedad > 100 [set saciedad 100]
        ]
      ]
    ] [
      ifelse ciclo-reproduccion? [ buscar-y-reproducir]
      ;; Si no se encontró alimento, ni esta en ciclo de reproducción, dar un movimiento aleatorio
      [mover]
    ]
    if not pez-contaminado?[
      let concentracion-ajustada [concentracion-activo] of patch-here / 1.0 ; Ajustar la concentración al rango de 0 a 1

      ;; Asegurarse de que la concentración ajustada esté en el rango [0, 1]
      set concentracion-ajustada max list 0 min list 1 concentracion-ajustada
      let probabilidad-base 0.5
      let concentracion-patch [concentracion-activo] of patch-here
      let probabilidad probabilidad-base * concentracion-ajustada
      if random-float 1 < probabilidad[
        if sexo = "macho"
        [
          set sexo "hembra"
          set color red
        ]
        set pez-contaminado? true
        if random-float 1 < 0.3 [
          set fertil? false
        ]



      ]
    ]
  ]
end

to-report buscar-alimento
  let umbral-saciedad 30

  ifelse saciedad < umbral-saciedad [
    ;; Buscar tanto comida (vegetal) como insectos cuando la saciedad es baja
    let comida-en-parche one-of patches with [pcolor = green and cantidad > 0] in-radius 10
    let insecto-en-parche one-of insectos in-radius 10

    ifelse comida-en-parche != nobody [
    ;; Si hay comida en el parche, retornar el parche
    report comida-en-parche
    ] [
      ;; Si no hay comida en el parche, pero hay un insecto en el parche, retornar el parche
      ifelse insecto-en-parche != nobody [
        report insecto-en-parche
      ] [
        ;; Si no hay ni comida ni insecto en el parche, retornar nobody
        report nobody
      ]
    ]
  ][
    ;; Si la saciedad es suficiente, hay una probabilidad de buscar comida de algas
    ifelse random-float 1 < 0.5 [
      let comida-algas one-of patches with [pcolor = green and cantidad > 0] in-radius 10
      report comida-algas
    ] [
      report nobody
    ]
  ]
end

to mover
  ;; Mover peces de forma aleatoria
  set heading random 360
  fd 1
end


to propagar-compuesto
  if ticks mod ticks-entre-propagaciones = 0 [
    ;; Cada ciertos ticks, iniciar la propagación del compuesto químico desde un punto aleatorio en la parte superior del río
    let path-inicial patch random-xcor random-pycor
    ask path-inicial [
      ;; Establecer la concentración inicial en el punto de inicio
      set concentracion-activo 1.0 ; Puedes ajustar la concentración inicial según tus necesidades
    ]

    ;; Propagar el compuesto químico hacia abajo en el radio especificado
    ask path-inicial[
      ask patches in-radius radio-propagacion [
        ;;Calcular la distancia desde el punto inicial y ajustar la concentración en función de la distancia
        let distancia distance path-inicial
        let concentracion-nueva 1.0 - (distancia / radio-propagacion)
        set concentracion-activo max list 0.0 concentracion-nueva ; Asegurarse de que la concentración no sea negativa
      ]
    ]
    ;; Cambiar el color del parche a rojo si la concentración es mayor que el umbral
    ask patches[
      if concentracion-activo > umbral-color [set pcolor red]
    ]
  ]
end

to reducir-concentracion
  ;; Reducción gradual de la concentración en todos los parches
  ask patches [
    set concentracion-activo max list 0.0 concentracion-activo - tasa-reduccion ; Ajusta la tasa de reducción según tus necesidades
    if concentracion-activo <= 0.5 [
       ifelse cantidad > 0 [set pcolor green]
      [set pcolor cyan]
    ]
    if concentracion-activo <= 0.0[
      ifelse cantidad > 0 [set pcolor green]
      [set pcolor cyan]
      set concentracion-activo 0.0
    ]
  ]
end


@#$#@#$#@
GRAPHICS-WINDOW
276
10
832
567
-1
-1
16.61
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
0
10
173
43
setup
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
1
52
173
86
go
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

SLIDER
0
95
172
128
num-peces
num-peces
0
50
22.0
1
1
NIL
HORIZONTAL

SLIDER
0
134
172
167
algas-inicial
algas-inicial
1
100
41.0
1
1
NIL
HORIZONTAL

SLIDER
0
174
174
207
cantidad-algas-reproducir
cantidad-algas-reproducir
0
50
30.0
1
1
NIL
HORIZONTAL

SLIDER
1
214
173
247
cantidad-insectos
cantidad-insectos
0
50
5.0
1
1
NIL
HORIZONTAL

PLOT
848
14
1144
248
Cantidad de peces por sexo
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Macho" 1.0 0 -13791810 true "" "plot count peces with [sexo = \"macho\"]"
"Hembra" 1.0 0 -2674135 true "" "plot count peces with [sexo = \"hembra\"]"

PLOT
847
265
1147
460
Cantiad de peces
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count peces"

SLIDER
0
254
172
287
radio-propagacion
radio-propagacion
0
20
9.0
1
1
NIL
HORIZONTAL

SLIDER
0
294
172
327
tasa-reduccion
tasa-reduccion
0.0
1.0
0.115
0.001
1
NIL
HORIZONTAL

SLIDER
0
335
173
368
ticks-entre-propagaciones
ticks-entre-propagaciones
0
240
50.0
1
1
NIL
HORIZONTAL

PLOT
1168
16
1459
289
Promedio de edad de peces
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"edades-promedio" 1.0 0 -13840069 true "" "plot mean edades-peces"

@#$#@#$#@
## ¿Qué es esto?
Modelo que simula un ecosistema marino compuesto por peces chub, insectos y algas, el cual es sometido a focos de residuos químicos que pueden generar el fenómeno de intersexo en los peces. La finalidad del modelo es simular la supervivencia de la especie bajo estos fenómenos y generar conciencia sobre la importancia de la ecofarmacovigilancia, la cual se encarga de estudiar el impacto de los desechos de residuos quimicos en el medio ambiente y de buscar mejores formas de deshacerse de ellos. 

## Cómo funciona
Los peces son el principal agente de este modelo, los cuales buscan comida en el entorno, ya sea algas o insectos. Tienen su periodo de reproducción y poseen una esperanza de vida de 10 años, donde es más probable que mueran. Las zonas de residuos químicos pueden cambiar el sexo de los peces machos, lo cual puede causar problemas para la supervivencia de la especie.

## Cómo utilizarlo
### Deslizadores
- num-peces: cantidad inicial de peces
- algas-inicial: cantidad inicial de algas
- cantidad-de-algas-reproducir: cantidad de algas para reabastecer periódicamente
- cantidad-insectos: cantidad inicial de insectos
- radio-propagación: radio de área de residuos químicos
- tasa-reducción: tasa de reducción de concentración de residuos químicos
- ticks-entre-propagaciones: tiempo que pasa entre una y otra propagación de residuos

### Botones
- setup: inicia el modelo con los valores dados de los deslizadores
- go: avanza el tiempo de simulación del modelo

## Cosas que intentar
### Parámetros interesantes a probar
- num-peces: 22
- algas-inicial: 41
- cantidad-algas-reproducir: 30
- cantidad-insectos: 5
- radio-propagación: 9
- tasa-reducción: 0.115
- ticks-entre-propagaciones: 50

Con estos parámetros se pudo ver cómo aumentaba bastante la población y cómo, en cierto punto, debido a la reducción en la población de peces machos, hubo una reducción en la población que los llevó a la extinción.


## Referencias
- Bahamonde, P. A., Munkittrick, K. R., & Martyniuk, C. J. (Year). Intersex in teleost fish: Are we distinguishing endocrine disruption from natural phenomena?
- Randak, T., Zlabek, V., Pulkrabova, J., Kolarova, J., Kroupova, H., Siroka, Z., Velisek, J., Svobodova, Z., & Hajslova, J. (2008, November 18). Effects of pollution on chub in the River Elbe, Czech Republic.

## Autores
- Elizabeth Bravo Campos
- Gustavo González Gutiérrez
- Richard González Lara
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

fish 3
false
0
Polygon -7500403 true true 137 105 124 83 103 76 77 75 53 104 47 136
Polygon -7500403 true true 226 194 223 229 207 243 178 237 169 203 167 175
Polygon -7500403 true true 137 195 124 217 103 224 77 225 53 196 47 164
Polygon -7500403 true true 40 123 32 109 16 108 0 130 0 151 7 182 23 190 40 179 47 145
Polygon -7500403 true true 45 120 90 105 195 90 275 120 294 152 285 165 293 171 270 195 210 210 150 210 45 180
Circle -1184463 true false 244 128 26
Circle -16777216 true false 248 135 14
Line -16777216 false 48 121 133 96
Line -16777216 false 48 179 133 204
Polygon -7500403 true true 241 106 241 77 217 71 190 75 167 99 182 125
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -1 true false 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -1 true false 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -1 true false 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

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

shark
false
0
Polygon -7500403 true true 283 153 288 149 271 146 301 145 300 138 247 119 190 107 104 117 54 133 39 134 10 99 9 112 19 142 9 175 10 185 40 158 69 154 64 164 80 161 86 156 132 160 209 164
Polygon -7500403 true true 199 161 152 166 137 164 169 154
Polygon -7500403 true true 188 108 172 83 160 74 156 76 159 97 153 112
Circle -16777216 true false 256 129 12
Line -16777216 false 222 134 222 150
Line -16777216 false 217 134 217 150
Line -16777216 false 212 134 212 150
Polygon -7500403 true true 78 125 62 118 63 130
Polygon -7500403 true true 121 157 105 161 101 156 106 152

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
NetLogo 6.3.0
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

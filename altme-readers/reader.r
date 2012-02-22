REBOL [
    Purpose: {AltME group reader}
    Author:  "Gregg Irwin"
    File:    %reader.r
    Date:    28-nov-2002
]

;run it directory-independent and with protect-system ;VN
unprotect [layout save-prefs]
;do view-root/developer/projects/vid/prototype/resizing/auto-resize.r
do %auto-resize.r


world: 'rebol


groups: copy []
msgs:   copy []
; altme_path: %../worlds/
; altme_path: %/c/program%20files/safeworlds/altme/worlds/  ; Graham's path :)

; Prefs - AK
prefs-file: %reader-prefs.r
;default prefs
prefs: context [offset: 100x100 size: 600x400 altme_path: %/d/altme/worlds/] load-prefs: does [error? try [prefs: make prefs load/all prefs-file]]
save-prefs: does [error? try [save prefs-file third prefs]]
load-prefs
if not exists? prefs-file [save-prefs]

altme_path: prefs/altme_path



; get rid of the first item in the list; it's special.
groups: remove load/all rejoin [altme_path world "/users.set"] [
    append/only either find item/6 'group [groups][users] item
]

group-names: copy []
user-names: copy []
foreach item groups [
    append either find item/6 'group [group-names][user-names] item/3
]
sort group-names
sort user-names


; Linear searching, ack!

id-from-name: func [name] [
    foreach item groups [
        if item/3 = name [return item/1]
    ]
]

name-from-id: func [id] [
    foreach item groups [
        if item/1 = id [return item/3]
    ]
]

find-id: func [id] [
    foreach item groups [
        if item/1 = id [return item]
    ]
]

row-height: 21

load-group: func [name /local file] [
    file: rejoin [altme_path world "/chat/" id-from-name name ".set"]
    ; get rid of the first item in the list; it's special.
    msgs: either exists? file [remove load/all file][copy []]
    v-sld/data: 0
    show v-sld
    display-data
]

map-slider-to-value: func [
    "Converts a slider value between 0 and 1 to a value within a range."
    value   [number!] "A value between 0 and 1."
    min-val [number!] "The minimum range value (if value = 0)."
    max-val [number!] "The maximum range value (if value = 1)."
][
    max-val - min-val * value + min-val
]

; no locals for testing. Let's us look at msg and user in the console.
display-data: does [
;display-data: has [msg user] [
    v-base-val: map-slider-to-value v-sld/data 1 length? msgs
    ;h-base-val: map-slider-to-value h-sld/data 1 3000
    clear head draw-cmds
    append draw-cmds [pen black font plain-font]
    if not empty? msgs [
        repeat row to-integer divide grd/size/y row-height [
            msg:  pick msgs to-integer (row - 1 + v-base-val)
            if msg [
                user: find-id msg/4 ; msg/4 = user id
                append draw-cmds compose [
                    pen (msg/5) font bold-font
                    text (to-pair reduce [5  row - 1 * row-height + 2]) (user/3)
                    pen black   font plain-font
                    text (to-pair reduce [60 row - 1 * row-height + 2]) (last msg)
                    ;msg/2 = timestamp
                ]
            ]
        ]
    ]
    show grd
]

plain-font:  make face/font [size: 11 style: [] name: 'font-serif]
bold-font:   make face/font [size: 11 style: [bold] name: 'font-serif]
italic-font: make face/font [size: 11 style: [italic] name: 'font-serif]

lay: layout [
    across
    group-lst: text-list 125x350 data group-names [
        load-group first face/picked
    ] resize-all
    ;user-lst:  text-list 125 data user-names
    space 1x1
    guide
    grd: box snow 500x350 effect compose [draw []]
        edge [size: 2x2 color: svvc/bevel effect: 'ibevel] resize-all

    v-sld: slider 15x350 [display-data] resize-v
    ;return
    ;h-sld: slider 500x15 [display-data]
]

draw-cmds: grd/effect/draw
display-data

view/options lay 'resize





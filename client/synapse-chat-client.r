Rebol [
    Author: "Graham Chiu" 
    Notes: {
    ^-Beer from whywire (GPL)
^-^-Some display functions from DideC's altme offline reader    ^-
    ^-Link parse added by Allen Kamp.
    ^-List-View from Henrik.
    ^-Pattern Generator from Cyphre.
    ^-Shrink ( aka Eliza on server side ) from Martin Johannesson.
    ^-Case from Ladislav ( for plugin ).
    ^-Buttons from  Baron RK Von Wolfsheild
    ^-Announce from Gabriele and Allen
    ^-Mapquest code from Franck
    } 
    Date: [31-Dec-2005 9-Jan-2006] 
    Title: "Synapse Chat" 
    File: %synapse-chat.r 
    Version: 0.0.112 
    Rights: 'GPL 
    Encap: [title "Synapse Chat v 0.0.112 " quiet secure none]
] 
log-error: none 
debug-on: false 
no-of-links: 5 
ctx-announcer: context [
    server-name: join "Synapse Chat " system/script/header/Version 
    twho: none 
    lay: layout [
        origin 0x0 space 2x2 
        image logo.gif feel [
            engage: func [face action event] [
                if action = 'away [action: 'over] 
                switch action [
                    down [face/state: event/offset] 
                    up [face/state: none] 
                    over [
                        if face/state [
                            face/parent-face/offset: face/parent-face/offset + event/offset - face/state 
                            show face/parent-face
                        ]
                    ]
                ]
            ]
        ] 
        twho: text "" 100x60 center wrap 
        text 100 server-name center navy
    ] 
    lay/state: 'hidden 
    lay/feel: make lay/feel [] 
    lay/data: lay/size/y 
    lay/size/y: 1 
    lay/offset: system/view/screen-face/size - lay/size - 20x50 
    lay/edge: make face/edge [size: 1x1 color: black] 
    lay/options: [no-border no-title] 
    set-twho: func [text action] [twho/text: text twho/action: func [face value] action] 
    pop-up-text: func [
        "Pops up a window showing the text" 
        text [string!] "Should be short" 
        action [block!] "What to do when text is clicked"
    ] [
        switch lay/state [
            hidden [
                lay/state: 'appearing 
                lay/rate: 25 
                lay/feel/engage: :appear-engage 
                append system/view/screen-face/pane lay 
                set-twho text action 
                show system/view/screen-face
            ] 
            appearing [
                while [lay/state = 'appearing] [wait 0:00:02] 
                lay/rate: none 
                show lay 
                set-twho text action 
                lay/rate: 0:00:06 
                show lay
            ] 
            waiting [
                lay/rate: none 
                show lay 
                set-twho text action 
                lay/rate: 0:00:06 
                show lay
            ] 
            disappearing [
                lay/state: 'appearing 
                lay/feel/engage: :appear-engage 
                set-twho text action 
                show lay
            ]
        ]
    ] 
    appear-engage: func [face action event] [
        if action = 'time [
            face/size/y: face/size/y + 3 
            face/offset/y: face/offset/y - 3 
            if face/size/y >= face/data [
                face/rate: 0:00:06 
                face/feel/engage: :wait-engage 
                face/state: 'waiting
            ] 
            show face
        ]
    ] 
    wait-engage: func [face action event] [
        if action = 'time [
            face/rate: 25 
            face/feel/engage: :disappear-engage 
            face/state: 'disappearing
        ]
    ] 
    disappear-engage: func [face action event] [
        if action = 'time [
            face/size/y: face/size/y - 3 
            face/offset/y: face/offset/y + 3 
            either face/size/y <= 60 [
                unview/only face 
                face/state: 'hidden
            ] [
                show face
            ]
        ]
    ] 
    set 'announce func [msg action] [
        msg: join msg [" in " servername] 
        pop-up-text msg action
    ]
] 
chat-history: [] 
start-time: now 
if not exists? %synapse-buttons.r [
    fl: flash "Downloading images" 
    write %synapse-buttons.r read http://www.compkarori.com/reb/buttons.r 
    unview/only fl
] 
if not exists? %beer2.r [
    fl: flash "Download beer library" 
    write %beer2.r read http://www.compkarori.com/reb/beer2.r 
    unview/only fl
] 
fl: flash "Checking for updates ... " 
if error? try [
    read http://www.compkarori.com/reb/synapse-chat112.r 
    unview/only fl 
    request-download/to http://www.compkarori.com/reb/synapse-chat112.r %synapse-chat.r 
    do %synapse-chat.r
] [unview/only fl] 
tip-face: none 
untip: has [win p] [
    if all [
        tip-face 
        win: find-window tip-face 
        p: find win/pane tip-face
    ] [
        remove p 
        hide tip-face 
        tip-face: none
    ]
] 
tip: func [face offset act te /local win] [
    untip 
    if act [
        win: find-window face 
        layout/tight [
            tip-face: text (te) gold black rate 0:00:03 
            feel [engage: func [face action event] [
                    if action = 'time [if face/show? [hide face]]
                ]]
        ] 
        tip-face/offset: either face/offset/x > ((face/parent-face/size/x / 4) * 3) 
        [as-pair (offset/x - tip-face/size/x) offset/y] [offset - 40x0] 
        append win/pane tip-face show win
    ]
] 
tip-over: make block! [if all [in f 'tooltip f/tooltip (length? f/tooltip) > 0] [
        tip f e a f/tooltip
    ]
] 
effect-face: func [
    {Permet d'ajouter du code dans le gestionnaire d'événements d'une facet.  
        Le code ajouté peut faire usage des variables f a e  (la face, l'action et l'événement courants)} 
    face [object!] 
    fu [word!] 
    code
] [
    set in face/feel :fu func [f a e] bind append compose [
        (get in face/feel :fu) f a e
    ] code in face/feel :fu
] 
Add-tooltip-2-style: func [{ Permet d'ajouter le support des info-bulles aux styles passés en paramètre} 
    style-lst [block!] "Contient la liste des styles à patcher" 
    style-root {Contient le chemin commun d'accès aux styles à patcher}
] [
    foreach style style-lst [
        if find style-root style [
            effect-face style-root/:style 'over tip-over
        ]
    ]
] 
vid-styles: [image btn backtile box sensor key base-text vtext text body txt banner vh1 vh2 vh3 vh4 
    title h1 h2 h3 h4 h5 tt code button check radio check-line radio-line led 
    arrow toggle rotary choice drop-down icon field info area slider scroller progress 
    anim btn-enter btn-cancel btn-help logo-bar tog
] 
update-tface: func [txt bar] [
    txt/line-list: none 
    txt/user-data: second size-text txt 
    bar/redrag txt/size/y / txt/user-data
] 
reset-tface: func [txt bar] [
    txt/para/scroll/y: 
    either none? txt/user-data [0
    ] [
        negate (max 0 txt/user-data - txt/size/y + 15)
    ] 
    bar/data: 1 
    update-tface txt bar 
    show [txt bar]
] 
open-tface: func [txt bar /local file] [
    if file: request-file [
        txt/text: read first file 
        reset-tface txt bar
    ]
] 
scroll-tface: func [txt bar] [
    txt/para/scroll/y: negate bar/data * 
    (max 0 txt/user-data - txt/size/y) 
    show txt
] 
save-links: has [bt links] [
    links: copy [] 
    for i 1 no-of-links 1 [
        bt: do join "b" i 
        append links bt/text 
        repend links [reduce [bt/data bt/effect/2]]
    ] 
    synapse-config/links: copy/deep links 
    save/all to-file rejoin [home-dir servername "/" %synapse-config.r] synapse-config
] 
comment {
    links: [
        "View" [[{call "d:\rebol\rebgui\rebcmdview.exe"}] 255.0.0] 
        "SC" [["do %synapse-chat.r"] 0.141.0] 
        "Carl" [["browse http://www.rebol.net/cgi-bin/blog.r"] 255.255.255] 
        "EMR" [["browse http://compkarori.com/emr/"] 255.255.255] 
        "GMail" [["browse http://mail.google.com/mail/"] 0.0.255]
    ]
} 
setup-links: has [cnt bt nm act details ef] [
    cnt: 0 
    l-rule: [
        set nm string! (
            bt: do to-word join "b" cnt: cnt + 1 
            set in bt 'text nm
        ) 
        set details into [block! opt tuple!] (
            set in bt 'data details/1 
            if found? details/2 [
                ef: get in bt 'effect 
                ef/2: details/2
            ]
        )
    ] 
    parse synapse-config/links [some l-rule]
] 
has-systray: false 
if 3 = system/version/4 [has-systray: true] 
home-dir: switch/default system/version/4 [
    2 [%~/Library/Application%20Support/Synapse%20Chat/] 
    3 [%synapse-chat/] 
    4 [%~/.synapse/] 
    7 [%~/.synapse/] 
    8 [%~/.synapse/] 
    9 [%~/.synapse/] 
    10 [%~/.synapse/]
] [%./] 
if error? try [
    if not exists? home-dir [make-dir/deep home-dir]
] [
    home-dir %./
] 
servers: copy [] 
do get-servers: has [tmp] [
    foreach f read home-dir [
        tmp: form f 
        if #"/" = last tmp [
            append/only servers copy/part tmp find/last tmp "/"
        ]
    ] 
    if empty? servers [
        append servers "Compkarori"
    ]
] 
do select-server: has [default] [
    default: pick servers 1 
    inform layout compose/deep [
        across 
        vh2 "Select Server" return 
        stl: text-list data copy servers 180x60 [sname/text: first face/picked show sname] return 
        text bold "Server:" sname: field (default) 120 return 
        pad 80 btn-enter #"^M" [servername: copy sname/text append/only stl/data servername hide-popup] 
        btn-cancel #"^[" [Quit]
    ]
] 
if empty? servername [quit] 
either exists? to-file rejoin [home-dir sname/text "/" %synapse-config.r] [
    synapse-config: load to-file rejoin [home-dir servername "/" %synapse-config.r]
] [
    synapse-config: make object! [
        servername: sname/text 
        server: http://www.compkarori.co.nz:8012 
        username: "Guest" 
        password: "Guest123" 
        usercolour: 128.128.128 
        lastmessage: now - 3:00 
        popups: false 
        enter: [#"^M"] 
        links: [
            "View" [["call {d:\rebol\rebgui\rebcmdview.exe}"] 255.0.0] 
            "Qtask" [["browse http://www.qtask.com/home.cgi"]] 
            "Carl" [["browse http://www.rebol.net/cgi-bin/blog.r"]] 
            "EMR" [["browse http://compkarori.com/emr/"]] 
            "GMail" [["browse http://mail.google.com/mail/"] 0.0.255]
        ] 
        email: none 
        city: none 
        tz: now/zone 
        language: "EN" 
        daily-dir: rejoin [home-dir sname/text "/" %daily/] 
        shared-dir: rejoin [home-dir sname/text "/" %shared/] 
        download-dir: rejoin [home-dir sname/text "/" %downloads/] 
        position: make object! [
            last-size: last-offset: 
            small-size: small-offset: 
            large-size: large-offset: none
        ]
    ]
] 
if not find first synapse-config 'position [
    tmp-config: make synapse-config [position: make object! [last-size: last-offset: 
            small-size: small-offset: 
            large-size: large-offset: none
        ]] 
    synapse-config: make tmp-config []
] 
if error? try [
    if not exists? synapse-config/daily-dir [make-dir/deep synapse-config/daily-dir]
] [
    alert "Unable to create daily directory"
] 
if error? try [
    if not exists? synapse-config/shared-dir [make-dir/deep synapse-config/shared-dir]
] [
    alert "Unable to create shared directory"
] 
if error? try [
    if not exists? synapse-config/download-dir [make-dir/deep synapse-config/download-dir]
] [
    alert "Unable to create download directory"
] 
sy-announce: either synapse-config/popups [:announce] [none] 
buttonsize: 25x25 
either viewDLL?: 'viewDLL = system/product 
[dr-block: []] 
[dr-block: 
    [pen none fill-pen diagonal -176x-99 0 122 125 5 3 38.58.108.153 80.108.142.167 0.48.0.168 255.0.255.179 255.164.200.192 72.72.16.174 128.0.0.136 178.34.34.179 255.0.0.180 250.240.230.128 178.34.34.144 128.0.0.177 0.255.255.180 220.20.60.165 44.80.132.147 240.240.240.191 0.0.0.151 box 0x0 1024x768 pen none fill-pen radial -30x-288 0 171 117 8 8 76.26.0.181 0.255.255.144 255.205.40.181 255.150.10.187 160.180.160.129 40.100.130.156 255.255.0.193 255.0.0.129 255.0.255.138 0.255.0.153 255.255.240.140 160.82.45.175 40.100.130.133 0.255.255.184 142.128.110.161 box 0x0 1024x768]
] 
dr-block: copy [] 
save-synapse-config: does [
    save/all to-file rejoin [home-dir synapse-config/servername "/" %synapse-config.r] synapse-config
] 
view center-face layout compose/deep [
    across space 2x1 
    text bold 80 right "Server:" text (sname/text) return 
    text bold 80 right "URL:" sfield: field (form synapse-config/server) return 
    pad 160x3 
    btn-enter #"^M" [
        synapse-config/server: form server: to-url sfield/text 
        save-synapse-config 
        unview
    ] 
    btn-cancel #"^[" [Quit]
] 
add-user: [
    across 
    title "Registration Screen" red return space 1x1 
    text "Username" bold 90 userfld: field 80x20 font [size: 11] return 
    text "Password" bold 90 passfld: field 80x20 font [size: 11] text "(minimum 8 characters)" return 
    text "Given Name" bold 90 fnamefld: field 160x20 font [size: 11] return 
    text "SurName" bold 90 snamefld: field 160x20 font [size: 11] return 
    text "Gender" bold 90 genderfld: field "M" 20x20 font [size: 11] text "(Email used for password recovery)" return 
    text "Email" bold 90 emailfld: field 200x20 font [size: 11] return 
    text "Secret Prompt" bold 90 secretfld: field 200x20 "Mother's maiden surname?" font [size: 11] return 
    text "Answer" bold 90 answerfld: field 200x20 font [size: 11] return 
    pad 200 btn "Submit" [
        either all [not empty? userfld/text not empty? passfld/text not empty? fnamefld/text not empty? snamefld/text not empty? genderfld/text not empty? secretfld/text not empty? answerfld/text (length? passfld/text) > 7] [
            register-user userfld/text passfld/text fnamefld/text snamefld/text genderfld/text emailfld/text secretfld/text answerfld/text
        ] [
            alert "Fill in all fields as specified!"
        ]
    ] 
    btn-cancel "Quit" [quit] 
    do [focus userfld]
] 
request-pass: func [
    "Requests a username and password." 
    /offset xy 
    /user username 
    /pwd password 
    /only "Password only." 
    /title title-text
] [
    if none? user [username: copy ""] 
    pass-lay: layout compose [
        style tx text 40x24 middle right 
        across origin 10x10 space 2x4 
        h3 (either title [title-text] [either only ["Enter password:"] ["Enter username and password:"]]) 
        return 
        (either only [[]] [[tx "User:" userf: field username return]]) 
        tx "Pass:" pass: field hide [ok: yes hide-popup] with [flags: [return tabbed]] return 
        pad 42 btn-enter "Register" 50 [
            unview/all 
            if viewDLL? [
                view/new layout [title "Synapse chat"]
            ] 
            inform center-face layout add-user
        ] 
        pad 46 
        btn-enter 50 [ok: yes hide-popup] 
        btn-cancel 50 #"^[" [hide-popup] 
        do [
            if pwd [
                pass/data: copy password 
                pass/text: copy "**masked**" 
                show pass
            ]
        ]
    ] 
    ok: no 
    focus either only [pass] [userf] 
    either offset [inform/offset pass-lay xy] [inform pass-lay] 
    all [ok either only [pass/data] [reduce [userf/data pass/data]]]
] 
viewing-current-list: "lobby-list" 
digit: net-utils/URL-Parser/digit 
ip-rule: [1 3 digit "." 1 3 digit "." 1 3 digit "." 1 3 digit ":" 1 5 digit] 
do %synapse-buttons.r 
foreach [word data] imagefiles [
    word: to-word form word 
    set word load data
] 
attempt [
    make-ping: func [len pitch /local ping] [
        ping: copy 64#{} 
        for amplitude len 1 -1 [
            for phase 1 360 pitch [
                val: 128 + to-integer 127 * sine phase 
                val: amplitude * val / len 
                append ping to-char val
            ]
        ] 
        ping
    ] 
    ping1: make-ping 200 20 
    ping2: make-ping 400 30 
    ping3: make-ping 600 40 
    sample: make sound [
        rate: 44100 / 2 
        channels: 1 
        bits: 8 
        volume: 0.5 
        data: 64#{}
    ] 
    Comment {
;    print "Arrange pings in a sequence:"
    loop 4 [
        append sample/data ping1
        append sample/data ping2
        append sample/data ping3
        append sample/data ping3
    ]
} 
    clear sample/data 
    loop 20 [append sample/data ping1] 
    data: sample/data 
    forall data [
        d1: first data 
        d2: first ping2 
        d3: first ping3 
        change data to-char d1 + d2 + d3 / 3 
        ping2: next ping2 
        if tail? ping2 [ping2: head ping2] 
        ping3: next ping3 
        if tail? ping3 [ping3: head ping3]
    ]
] 
ring-bells: does [
    attempt [
        sound-port: open sound:// 
        insert sound-port sample 
        wait sound-port 
        close sound-port
    ]
] 
unless value? 'case [
    case: func [
        [throw catch] 
        args [block!] /local res
    ] [
        either unset? first res: do/next args [
            if not empty? args [
                throw make error! [script no-arg case condition]
            ]
        ] [
            either first res [
                either block? first res: do/next second res [
                    do first res
                ] [
                    throw make error! [
                        script expect-arg case block [block!]
                    ]
                ]
            ] [
                case second do/next second res
            ]
        ]
    ]
] 
pattern-ctx: context [
    scr: 1024x768 
    random/seed now 
    seed: random 65535 
    colors: [40.100.130 100.120.100 160.180.160 255.228.196 
        0.0.0 0.0.255 178.34.34 139.69.19 44.80.132 64.64.64 76.26.0 
        220.20.6 0 0.255.255 0.48.0 255.205.40 128.128.128 0.255.0 
        255.255.240 179.179.126 0.128.0 250.240.230 255.0.255 175.155.120 
        128.0.0 100.136.116 0.0.128 72.72.16 128.128.0 255.150.10 44.80.132 
        255.80.37 170.170.170 255.164.200 128.0.128 38.58.108 142.128.110 
        255.0.0 160.82.45 192.192.192 164.200.255 240.240.240 222.184.135 
        0.128.128 72.0.90 80.108.142 245.222.129 255.255.255 255.255.0
    ] 
    gen-draw: has [tmp] [
        set-face sdf seed 
        refresh-keep 
        random/seed seed 
        loop random 5 [
            loop t: (3 + random 20) [
                insert tmp: [] (first random colors) + 0.0.0.128 + random (t * 0.0.0.5)
            ] 
            append dr-block compose [
                pen none 
                fill-pen 
                (first random [radial conic diamond linear cubic diagonal]) 
                ((first random reduce [negate scr scr * 2 scr * 0x2 scr * 2x0]) + random scr) 0 (random 300) 
                (random 360) 2 
                (random 10) (random 10) 
                (tmp)
            ] 
            append dr-block reduce ['box 0x0 scr] 
            clear tmp
        ]
    ] 
    rand-seed: does [until [seed: random 65535 not find keeps seed]] 
    regen: does [clear dr-block gen-draw show cbd] 
    seed-it: does [attempt [seed: to-integer sdf/text save-seed regen]] 
    save-seed: does [seeds: back insert tail seeds seed] 
    refresh-keep: does [
    ] 
    keeps: [] 
    seeds: copy keeps 
    prev-pattern: does [
        seeds: back seeds seed: seeds/1 regen
    ] 
    next-pattern: does [
        either tail? next seeds [rand-seed save-seed] [seeds: next seeds seed: seeds/1] 
        regen
    ]
] 
stylize/master [
    list-field: BOX with [
        size: 0x20 
        edge: make edge [size: 1x1 effect: 'ibevel color: 240.240.240] 
        color: 240.240.240 
        font: none 
        para: make para [wrap?: false] 
        access: make ctx-access/field [] 
        flags: [field tabbed return on-unfocus input] 
        feel: make ctx-text/edit bind [
            redraw: func [face act pos] [
                if all [in face 'colors block? face/colors] [
                    face/color: pick face/colors face <> view*/focal-face
                ]
            ] 
            detect: none 
            over: none 
            engage: func [face act event /local f lv] [
                lv: get in f: face/parent-face/parent-face 'parent-face 
                switch act [
                    down [
                        f/focus-column: face/var 
                        either equal? face view*/focal-face [unlight-text] [
                            focus/no-show face
                        ] 
                        view*/caret: offset-to-caret face event/offset 
                        show face
                    ] 
                    over [
                        if not-equal? view*/caret offset-to-caret face event/offset [
                            if not view*/highlight-start [view*/highlight-start: view*/caret] 
                            view*/highlight-end: view*/caret: 
                            offset-to-caret face event/offset 
                            show face
                        ]
                    ] 
                    key [
                        edit-text face event get in face 'action 
                        if event/key = #"^-" [
                            f/edit-field: face 
                            f/focus-column: face/var 
                            f/edit-value: get-face face 
                            f/edit-index: index? find face/parent-face/pane face 
                            if f/tab-edit-action [
                                use f/data-columns [
                                    set bind f/editable-columns f f/edt/pane 
                                    do bind f/tab-edit-action f
                                ]
                            ] 
                            either event/shift [
                                either 1 = length? f/editable-columns [focus face] [
                                    if 1 = f/edit-index [focus get last f/editable-columns]
                                ]
                            ] [
                                if f/edit-index = length? f/editable-columns [
                                    if f/finish-edit-action [
                                        use f/data-columns [
                                            set bind f/editable-columns f f/edt/pane 
                                            do bind f/finish-edit-action f
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ] in ctx-text 'self
    ] 
    list-text: BOX with [
        size: 0x20 
        font: make font [
            size: 11 shadow: none style: none align: 'left color: black
        ] 
        para: make para [wrap?: false] 
        flags: [text] 
        truncated?: false 
        range: func [pair1 pair2 /local r p1 p2] [
            p1: min pair1 pair2 
            p2: max pair1 pair2 
            r: copy [] 
            for x p1/1 p2/1 1 [
                for y p1/2 p2/2 1 [insert tail r as-pair x y]
            ] r
        ] 
        full-text: none 
        pane: none 
        feel: make feel [
            over: func [face ovr /local f lv pos] [
                lv: get in f: face/parent-face/parent-face 'parent-face 
                if all [ovr] [
                    lv/over-cell-text: face/full-text 
                    lv/over-data: face/data 
                    all [
                        lv/over-row-action 
                        use f/data-columns [
                            set bind f/editable-columns f f/edt/pane 
                            do bind f/over-row-action f
                        ]
                    ] 
                    if face/truncated? [
                    ]
                ]
            ] 
            engage: func [face act evt /local f lv p1 p2 r fd] [
                lv: get in f: face/parent-face/parent-face 'parent-face 
                if all [
                    lv/lock-list = false 
                    find [down alt-down] act 
                    face
                ] [
                    fd: any [face/data none] 
                    if lv/editable? [lv/hide-edit] 
                    if fd [
                        pos: as-pair index? find face/parent-face/pane face fd 
                        either all [
                            evt/shift 
                            find [multi multi-row] lv/select-mode 
                            lv/sel-cnt 
                            lv/selected-column
                        ] [
                            lv/range: copy reduce switch lv/select-mode [
                                row [[
                                        as-pair 
                                        index? find lv/viewed-columns 
                                        lv/selected-column lv/sel-cnt 
                                        pos
                                    ]] 
                                multi [[
                                        as-pair 
                                        index? find lv/viewed-columns 
                                        lv/selected-column lv/sel-cnt 
                                        pos
                                    ]] 
                                multi-row [[
                                        as-pair 1 lv/sel-cnt as-pair 
                                        length? lv/viewed-columns 
                                        fd
                                    ]]
                            ] 
                            p1: min lv/range/1 lv/range/2 
                            p2: max lv/range/1 lv/range/2 
                            lv/range: copy [] 
                            r: copy sort reduce [
                                index? find lv/sort-index p1/2 
                                index? find lv/sort-index p2/2
                            ] 
                            for x p1/1 p2/1 1 [
                                for y r/1 r/2 1 [
                                    insert tail lv/range as-pair x lv/sort-index/:y
                                ]
                            ]
                        ] [
                            lv/range: copy [] 
                            lv/selected-column: pick lv/viewed-columns pos/1 
                            switch lv/select-mode [
                                single [lv/range: copy reduce [pos]] 
                                multi [lv/range: copy reduce [pos]] 
                                row [
                                    repeat i length? lv/viewed-columns [
                                        append lv/range as-pair i fd
                                    ]
                                ] 
                                multi-row [
                                    repeat i length? lv/viewed-columns [
                                        append lv/range as-pair i fd
                                    ]
                                ] 
                                column [
                                    repeat i length? lv/sort-index [
                                        append lv/range as-pair pos/1 i
                                    ]
                                ]
                            ] 
                            lv/mouse?: true 
                            lv/old-sel-cnt: lv/sel-cnt 
                            lv/sel-cnt: fd
                        ] 
                        switch act [
                            down [all [lv/list-action do bind lv/list-action lv]] 
                            alt-down [all [lv/alt-list-action do bind lv/alt-list-action lv]]
                        ] 
                        if lv/old-sel-cnt <> lv/sel-cnt [
                            show f
                        ]
                    ] 
                    if all [
                        not lv/lock-list fd lv/editable? lv/immediate-edit?
                    ] [lv/show-edit] 
                    if act = 'up [row: face/row] 
                    if evt/double-click [
                        if lv/lock-list = false [
                            all [
                                lv/doubleclick-list-action 
                                do bind lv/doubleclick-list-action lv
                            ] 
                            if all [fd lv/editable? not lv/immediate-edit?] [lv/show-edit]
                        ]
                    ]
                ]
            ]
        ] 
        data: 0 
        row: 0
    ] 
    list-view: FACE with [
        hdr: hdr-btn: hdr-fill-btn: hdr-corner-btn: lst: lst-fld: scr: edt: none 
        hdr-face: hdr-btn-face: hdr-fill-btn-face: hdr-corner-btn-face: lst-face: lst-fld-face: scr-face: edt-face: none 
        size: 300x200 
        dirty?: fill: true 
        click: none 
        edge: make edge [size: 0x0 color: 140.140.140 effect: 'ibevel] 
        colors: [240.240.240 220.230.220 180.200.180 180.180.180 140.140.140] 
        color: does [either fill [first colors] [last colors]] 
        spacing-color: third colors 
        select-color: third colors 
        old-data-columns: copy data-columns: copy indices: copy conditions: [] 
        old-viewed-columns: viewed-columns: header-columns: none 
        readonly-columns: editable-columns: none 
        old-widths: widths: px-widths: none 
        old-fonts: fonts: none 
        old-paras: paras: none 
        over-cell-text: over-data: none 
        types: none 
        truncate: false 
        drag: false 
        fit: true 
        scroller-width: row-height: 20 
        vo-set: 0 
        limit: none 
        col-widths: h-fill: 0 
        spacing: 0x0 
        range: copy data: [] 
        resize-column: selected-column: sort-column: old-sort-column: none 
        readonly-columns: copy [] 
        editable?: false 
        immediate-edit?: false 
        update?: true 
        last-edit: none 
        h-scroll: false 
        sort-index: [] 
        sort-modes: [asc desc nosort] 
        select-modes: [single multi row multi-row column] 
        select-mode: third select-modes 
        drag-modes: [drag-select drag-move] 
        drag-mode: first drag-modes 
        sort-direction: copy [] 
        tri-state-sort: true 
        variable-height: true 
        paint-columns: false 
        ovr-cnt: old-sel-cnt: sel-cnt: none 
        cnt: ovr: old-ovr: 0 
        mouse?: false 
        then: now/time/precise 
        update-speed: 0:00 
        cell: cells: none 
        idx: 1 
        lock-list: false 
        follow?: true 
        row-face: none 
        debug: false 
        standard-font: make system/standard/face/font [
            size: 11 shadow: none style: none align: 'left color: black
        ] 
        standard-para: make system/standard/face/para [wrap?: false] 
        standard-header-font: make standard-font [
            size: 12 shadow: 0x1 color: white
        ] 
        standard-header-para: make standard-para [] 
        acquire-func: [] 
        list-size: value-size: 0 
        resize: func [sz] [size: sz refresh] 
        update-pair: func [from to] [
            lst/single: from 
            show lst/subface 
            lst/single: to 
            show lst/subface
        ] 
        follow: func [/pair from to] [
            if update? [
                either follow? [scroll-here] [
                    either pair [update-pair from to] [show lst]
                ]
            ]
        ] 
        edit-value: edit-index: edit-field: focus-column: none 
        list-action: over-row-action: alt-list-action: doubleclick-list-action: 
        edit-action: tab-edit-action: finish-edit-action: row-action: none 
        do-action: func [action-name] [
            mouse?: false 
            if all [sel-cnt not empty? sort-index] [
                do bind get in self action-name 'self
            ]
        ] 
        block-data?: does [not all [not empty? data not block? first data]] 
        focus-list: func [/no-show] [
            select-color: third colors 
            any [no-show refresh] 
            sel-cnt
        ] 
        unfocus-list: func [/no-show] [
            select-color: fourth colors 
            any [no-show refresh] 
            sel-cnt
        ] 
        import: func [data [object!]] [
        ] 
        export: does [
            make object! third self
        ] 
        first-cnt: func [/act] [
            old-sel-cnt: sel-cnt 
            sel-cnt: either empty? sort-index [none] [first sort-index] 
            follow 
            if act [do-action 'list-action] 
            sel-cnt
        ] 
        prev-page-cnt: func [/act] [
            prev-cnt/skip-size list-size 
            if act [do-action 'list-action] 
            sel-cnt
        ] 
        prev-cnt: func [/act /skip-size size /local f sz si] [
            sz: negate either skip-size [size] [1] 
            sel-cnt: either empty? sort-index [none] [
                all [
                    f: find sort-index sel-cnt 
                    not empty? si: skip f sz first si
                ]
            ] follow 
            if act [do-action 'list-action] 
            sel-cnt
        ] 
        next-cnt: func [/act /skip-size size /local f sz si] [
            sz: either skip-size [size] [1] 
            sel-cnt: either empty? sort-index [none] [
                either all [
                    f: find sort-index sel-cnt 
                    not empty? f: skip f sz 
                    not tail? f
                ] [first f] [sel-cnt]
            ] follow 
            if act [do-action 'list-action] 
            sel-cnt
        ] 
        next-page-cnt: func [/act] [
            next-cnt/skip-size list-size 
            if act [do-action 'list-action] 
            sel-cnt
        ] 
        last-cnt: func [/act] [
            sel-cnt: either empty? sort-index [none] [last sort-index] 
            follow 
            if act [do-action 'list-action] 
            sel-cnt
        ] 
        max-cnt: func [/act] [
            sel-cnt: either empty? sort-index [none] [first maximum-of sort-index] 
            follow 
            if act [do-action 'list-action] 
            sel-cnt
        ] 
        min-cnt: func [/act] [
            sel-cnt: either empty? sort-index [none] [first minimum-of sort-index] 
            follow 
            if act [do-action 'list-action] 
            sel-cnt
        ] 
        limit-sel-cnt: does [
            if all [sel-cnt not found? find sort-index sel-cnt] [last-cnt] sel-cnt
        ] 
        reset-sel-cnt: does [ovr-cnt: sel-cnt: none mouse?: false] 
        selected?: does [not none? sel-cnt] 
        tail-cnt?: has [val] [
            all [
                sel-cnt 
                val: find sort-index sel-cnt 
                equal? index? val length? sort-index
            ]
        ] 
        search: func [value /part /column col [word!] /local i j out] [
            out: 0 
            either block-data? [
                either column [
                    i: index? find data-columns col 
                    either part [
                        repeat j length? data [
                            all [found? find to-string data/:j/:i value out: j break]
                        ]
                    ] [
                        repeat j length? data [all [value = data/:j/:i out: j break]]
                    ]
                ] [
                    either part [
                        repeat j length? data [
                            repeat l length? data/:j [
                                all [found? find to-string data/:j/:l value out: j break]
                            ]
                        ]
                    ] [
                        repeat j length? data [all [found? find data/:j value out: j break]]
                    ]
                ]
            ] [
                either part [
                    repeat j length? data [all [found? find data/:j value out: j break]]
                ] [
                    out: index? find data value
                ]
            ] either not zero? out [get-row/raw out] [none]
        ] 
        old-filter-string: copy filter-string: copy "" 
        filter-pos: func [pos] [attempt [index? find sort-index pos]] 
        filter-sel-cnt: does [all [sel-cnt filter-pos sel-cnt]] 
        filter-specs: copy filter-index: copy sort-index: copy [] 
        filter-row: func [
            row [block!] spec-block [block!] 
            /local id ids string indices out
        ] [
            ids: copy [] 
            string: first back indices: next spec-block/2 
            out: either all [series? string empty? string] [true] [
                either empty? indices [
                    if not found? find spec-block/1 'only [row: form row] 
                    found? find row string
                ] [
                    foreach i indices [
                        all [id: find data-columns i append ids index? id]
                    ] 
                    found? find either find spec-block/1 'only [
                        foreach i ids [append [] row/:i]
                    ] [
                        form foreach i ids [append [] row/:i]
                    ] string
                ]
            ] 
            either find spec-block/1 'not [system/words/not out] [out]
        ] 
        filter-rows: has [row-flags filter-index] [
            filter-index: copy [] 
            repeat i length? data [
                row-flags: copy [] 
                if not empty? filter-specs [
                    foreach f extract filter-specs 3 [
                        insert tail row-flags filter-row 
                        data/:i 
                        copy/part next find filter-specs f 2
                    ]
                ] 
                if all row-flags [insert tail filter-index i]
            ] copy filter-index
        ] 
        set-filter-spec: func [
            name [word!] value columns [block!] /only /not /local spec-block params
        ] [
            params: copy [] 
            if only [insert tail params 'only] 
            if not [insert tail params 'not] 
            spec-block: reduce [params append reduce [value] columns] 
            either select filter-specs name [
                change next find filter-specs name spec-block
            ] [
                append append filter-specs name spec-block
            ] 
            refresh
        ] 
        remove-filter-spec: func [name] [
            remove remove remove find filter-specs name refresh
        ] 
        reset-filter-specs: does [filter-specs: copy [] refresh] 
        filter: has [default-i i w string result g-length] [
            either empty? filter-specs [
                filter-index: copy [] 
                either not none? data [
                    g-length: length? g: parse to-string filter-string none 
                    either g-length > 0 [
                        result: copy i: copy 
                        default-i: make bitset! (g-length + 8 - (g-length // 8)) 
                        w: 1 
                        until [
                            insert result w 
                            w: w + 1 
                            w > g-length
                        ] 
                        repeat j length? data [
                            string: mold data/:j 
                            repeat num g-length [if find string g/:num [insert i num]] 
                            if i = result [
                                i: copy default-i 
                                insert tail filter-index j
                            ]
                        ] filter-index
                    ] [copy []]
                ] [copy []]
            ] [filter-index: filter-rows]
        ] 
        scrolling?: none 
        list-sort: has [i vals] [
            sort-index: either not empty? data [
                head repeat i length? data [insert tail [] i]
            ] [copy []] 
            vals: copy [] 
            either sort-column [
                i: col-idx/viewed sort-column 
                either block-data? [
                    repeat j length? data [
                        insert tail vals reduce [data/:j/:i j copy data/:j]
                    ]
                ] [
                    repeat j length? data [
                        insert tail vals reduce [data/:j j data/:j]
                    ]
                ] 
                sort-index: extract/index switch/default sort-direction/:i [
                    asc [sort/skip vals 3] 
                    desc [sort/skip/reverse vals 3]
                ] [vals] 3 2
            ] [sort-index]
        ] 
        reset-sort: does [
            sort-column: none 
            sort-direction: array/initial length? viewed-columns 'nosort 
            list-sort 
            foreach p hdr/pane [if p/style = 'hdr-btn [p/effect: none]] 
            refresh 
            follow
        ] 
        set-sorting: func [column [word!] direction [word!]] [
            if not empty? sort-direction [
                sort-column: column 
                change at sort-direction col-idx/viewed column direction 
                set-header-buttons 
                refresh/force
            ]
        ] 
        set-header-buttons: does [
            if update? [
                foreach button hdr/pane [
                    if not button/style = 'hdr-corner-btn [
                        button/effect: either all [sort-column button/var = sort-column] [
                            switch/default pick sort-direction col-idx/viewed sort-column [
                                asc [head insert tail copy button/eff-blk 1x1] 
                                desc [head insert tail copy button/eff-blk 1x0]
                            ] [none]
                        ] [none] 
                        button/color: either all [
                            sort-column button/var = sort-column
                        ] [155.155.155] [140.140.140]
                    ]
                ]
            ]
        ] 
        filter-list: func [/single id] [
            either any [sort-column not single] [
                sort-index: either empty? filter [
                    either any [
                        dirty? all [empty? filter-specs empty? filter-string]
                    ] [dirty?: false list-sort] [
                        copy []
                    ]
                ] [
                    if any [
                        dirty? old-filter-string <> filter-string 
                        not empty? filter-specs
                    ] [
                        cnt: 0 
                        old-filter-string: copy filter-string 
                        list-sort
                    ] 
                    intersect sort-index filter-index
                ] 
                if limit [sort-index: copy/part sort-index limit] 
                if any [not empty? filter-specs not empty? filter-string] [
                    if not found? find sort-index sel-cnt [reset-sel-cnt]
                ] 
                set-scr
            ] [
                lst/single: id 
                if update? [show lst/subface]
            ]
        ] 
        set-filter: func [string [string!]] [
            filter-string: copy string 
            refresh
        ] 
        reset-filter: does [
            old-filter-string: copy filter-string: copy "" 
            refresh
        ] 
        set-limit: func [size [integer!]] [
            limit: size 
            cnt: 0 
            refresh
        ] 
        reset-limit: does [limit: none cnt: 0 refresh] 
        scroll-here: func [/local sl old-cnt] [
            old-cnt: cnt 
            if all [
                sel-cnt 
                not empty? sort-index 
                not found? find [column multi multi-row] select-mode
            ] [
                limit-sel-cnt 
                sl: index? find sort-index sel-cnt 
                cnt: min sl - 1 cnt 
                cnt: (max sl cnt + list-size) - list-size 
                if list-size < length? sort-index [
                    cnt: (min cnt + list-size value-size) - list-size
                ] 
                if old-cnt <> cnt [
                    set-scr 
                    move-edit
                ] 
                if update? [show [lst scr]]
            ]
        ] 
        set-scr: has [old-update] [
            scr/redrag list-size / max 1 value-size 
            scr/data: either value-size = list-size [0] [
                cnt / (value-size - list-size)
            ] 
            if update? [show [lst scr]]
        ] 
        move-edit: does [
            if edt/show? [
                edt/offset/y: either not zero? sel-cnt - cnt [
                    lst/subface/size/y * (sel-cnt - cnt)
                ] [
                    negate edt/size/y
                ] 
                show edt
            ]
        ] 
        sorted-data: has [out j] [
            out: copy [] 
            j: either limit [min limit length? sort-index] [length? sort-index] 
            repeat i j [append/only out pick data sort-index/:i] 
            out
        ] 
        totals: does [
            as-pair 
            any [all [limit min limit length? sort-index] length? sort-index] 
            length? data
        ] 
        get-id: func [pos rpos h r /inserting] [
            either r [rpos] [either h [filter-pos pos] [
                    either sel-cnt [sel-cnt] [1]
                ]]
        ] 
        row: does [
            make object! insert tail foreach c data-columns [
                insert tail [] either block-data? [to-set-word c] [
                    to-set-word first parse c none
                ]
            ] reduce ['copy copy ""]
        ] 
        get-row: func [/over /range /here pos /raw rpos /keys /local id] [
            id: get-id pos rpos here raw 
            either all [id select-mode <> 'multi select-mode <> 'multi-row] [
                either keys [
                    obj: make row [] set obj pick data id obj
                ] [pick data id]
            ] [if over [pick data over-data]]
        ] 
        get-range: func [/flat /local out] [
            out: copy [] 
            either flat [
                foreach c range [insert tail out pick pick data c/2 c/1]
            ] [
                y: copy range 
                repeat i length? y [change at y i y/:i/2] 
                y: unique y 
                repeat i length? y [
                    row: copy [] 
                    row-size: 0 
                    foreach r range [if y/:i = r/2 [row-size: row-size + 1]] 
                    repeat j row-size [
                        insert tail row pick 
                        pick data y/:i 
                        pick pick range j * length? y 1
                    ] 
                    insert/only tail out row
                ]
            ] out
        ] 
        find-row: func [value /col colname /act /local i j fnd?] [
            i: 0 
            fnd?: false 
            either empty? data [none] [
                either col [
                    c: col-idx colname 
                    until [
                        i: i + 1 
                        any [
                            all [i = length? data data/:i/:c value <> data/:i/:c] 
                            all [data/:i/:c value = data/:i/:c fnd?: true]
                        ]
                    ]
                ] [
                    either block? value [
                        until [
                            i: i + 1 
                            any [
                                all [i = length? data value <> pick data i] 
                                all [value = pick data i fnd?: true]
                            ]
                        ]
                    ] [
                        until [
                            i: i + 1 
                            any [
                                i > length? data 
                                all [
                                    data/:i 
                                    fnd?: found? find data/:i value
                                ]
                            ]
                        ]
                    ]
                ] 
                either fnd? [
                    sel-cnt: i 
                    follow 
                    if act [do-action 'list-action] 
                    get-row
                ] [none]
            ]
        ] 
        get-cell: func [cell [integer! word!] /here pos /raw rpos /local id] [
            id: get-id pos rpos here raw 
            if all [id not empty? data-columns not empty? data] [
                attempt [
                    pick get-row/raw id 
                    either word? cell [index? find data-columns cell] [cell]
                ]
            ]
        ] 
        get-block: has [ar r] [
            if all [not empty? range] [
                ar: 1 + abs subtract first range last range 
                ar-blk: array/initial ar/2 array/initial ar/1 copy "" 
                r: range/1 - 1 
                repeat i length? range [
                    poke pick ar-blk range/:i/2 - r/2 range/:i/1 - r/1 
                    pick pick data range/:i/2 range/:i/1
                ] ar-blk
            ] copy []
        ] 
        get-col: func [column [word!]] [
            c: col-idx column 
            out: copy [] 
            foreach d data [insert tail out d/:c] 
            out
        ] 
        get-unique: func [column [word!] /local c] [unique get-col column] 
        unkey: func [vals] [
            copy/deep either all [block? vals find vals set-word!] [
                extract/index vals 2 2
            ] [vals]
        ] 
        col-idx: func [column [word!] /viewed] [
            index? find either viewed [viewed-columns] [data-columns] column
        ] 
        sel-col-idx: does [col-idx selected-column] 
        clear: does [data: copy [] dirty?: true filter-list] 
        insert-row: func [
            /here pos [integer!] /raw rpos [integer!] /act /values vals /local id
        ] [
            id: get-id pos rpos here raw 
            either empty? data [
                insert/only data either values [unkey vals] [make-row]
            ] [
                all [
                    id data/:id insert/only at data id 
                    either values [unkey vals] [make-row]
                ]
            ] 
            dirty?: true 
            filter-list 
            if act [do-action 'list-action] 
            get-row/raw id
        ] 
        insert-block: func [pos [integer!] vals] [
            all [pos data/:pos insert at data pos vals filter-list]
        ] 
        append-row: func [/values vals /act /no-select /local old-update] [
            old-update: update? 
            update?: false 
            either values [
                all [vals insert/only tail data unkey vals]
            ] [
                insert/only tail data make-row
            ] 
            dirty?: true 
            filter-list 
            update?: old-update 
            if not no-select [
                max-cnt 
                if act [do-action 'list-action]
            ] 
            if update? [show [lst scr]] 
            get-row/raw length? data
        ] 
        append-block: func [vals /local old-update] [
            old-update: update? 
            update?: false 
            insert tail data vals 
            dirty?: true 
            filter-list 
            update?: old-update 
            last-cnt
        ] 
        remove-row: func [
            /here pos [integer!] /raw rpos [integer!] /no-select /act /local id
        ] [
            id: get-id pos rpos here raw 
            all [
                id 
                data/:id 
                any [hide-edit true] 
                remove at data id 
                dirty?: true 
                filter-list 
                either no-select [sel-cnt: none] [limit-sel-cnt] 
                act 
                do-action 'list-action
            ]
        ] 
        remove-block: func [pos range] [
            for i pos range 1 [remove at data pick sort-index i] 
            dirty?: true 
            filter-list
        ] 
        remove-block-here: func [range] [remove-block range filter-sel-cnt] 
        change-row: func [
            vals /here pos [integer!] /raw rpos [integer!] /top /act /local id tmp
        ] [
            id: get-id pos rpos here raw 
            all [id data/:id change/only at data id unkey vals] 
            if top [
                tmp: copy get-row/raw id 
                remove-row/raw id 
                insert-row/values/raw tmp 1 
                first-cnt
            ] 
            dirty?: true 
            filter-list 
            if act [do-action 'list-action] 
            get-row/raw id
        ] 
        change-block: func [pos [integer! pair!] vals [block!]] [
            either pair? pos [] [
                for i sel-cnt length? vals 1 [change at data pick sort-index i]
            ] 
            dirty?: true 
            filter-list
        ] 
        change-block-here: func [vals [block!]] [
            switch select-mode [
                single [change-block as-pair sel-cnt col-idx selected-column vals] 
                row [change-block sel-cnt reduce [vals]] 
                multi [change-block range/1 vals] 
                multi-row [change-block range/1 vals] 
                column [change-block range/1 vals]
            ]
        ] 
        move-row: func [
            from-cnt to-cnt /local tmp old-update
        ] [
            old-update: update? 
            update?: false 
            tmp: get-row/raw from-cnt 
            remove-row/raw from-cnt 
            insert-row/values/raw to-cnt 
            update?: old-update 
            follow
        ] 
        move-selected-row: func [to-cnt] [move-row sel-cnt to-cnt] 
        move-row-up: has [tmp old-update] [
            old-update: update? 
            tmp: get-row 
            update?: false 
            either not tail-cnt? [remove-row prev-cnt] [remove-row limit-sel-cnt] 
            insert-row/values tmp 
            update?: old-update 
            follow
        ] 
        move-row-down: has [tmp old-update] [
            if not tail-cnt? [
                old-update: update? 
                update?: false 
                next-cnt 
                move-row-up 
                update?: old-update 
                next-cnt
            ]
        ] 
        change-cell: func [
            col val /here pos [integer!] /raw rpos [integer!] /top /act /local id tmp
        ] [
            id: get-id pos rpos here raw 
            if all [id data/:id] [
                change at pick data id col-idx col val 
                filter-list 
                if top [
                    tmp: copy data/:id 
                    remove at data id 
                    data/1: tmp
                ] 
                if act [do-action 'list-action] 
                get-row/raw id
            ]
        ] 
        make-row: does [
            either block-data? [array/initial length? data-columns copy ""] [copy ""]
        ] 
        acquire: does [
            if not empty? acquire-func [append-row/values do acquire-func]
        ] 
        show-edit: func [/column col /local vals idx result] [
            if sel-cnt [
                idx: either sort-column [index? find sort-index sel-cnt] [sel-cnt] 
                edt/offset/y: (lst/subface/size/y) * (idx - cnt - 1) + hdr/size/y 
                vals: get-row 
                use data-columns compose/deep [
                    set bind viewed-columns self edt/pane 
                    repeat i length? viewed-columns [
                        set in get viewed-columns/:i 'text pick vals indices/:i 
                        set in get viewed-columns/:i 'data pick vals indices/:i 
                        set in get viewed-columns/:i 'var viewed-columns/:i
                    ] 
                    result: either all [edit-action not empty? edit-action] [
                        do [(edit-action)]
                    ] [true]
                ] 
                if result [
                    if not selected-column [selected-column: first editable-columns] 
                    f-col: index? find viewed-columns selected-column 
                    either edt/pane/:f-col/style = 'list-field [focus edt/pane/:f-col] [
                        until [
                            f-col: (f-col + 1) // length? viewed-columns 
                            any [
                                all [
                                    edt/pane/:f-col/style = 'list-field 
                                    focus edt/pane/:f-col true
                                ] 
                                f-col = length? viewed-columns
                            ]
                        ]
                    ] 
                    show [lst edt]
                ]
            ]
        ] 
        hide-edit: does [if edt/show? [
                submit-edit edt/show?: false unfocus refresh
            ]
        ] 
        submit-edit: has [vals] [
            if sel-cnt [
                vals: get-row 
                repeat i length? data-columns [
                    if found? find editable-columns data-columns/:i [
                        change at vals i get in get data-columns/:i 'text
                    ]
                ] 
                last-edit: either edt/show? [get-row] [none]
            ]
        ] 
        init-code: has [o-set e-size val resize-column-index no-header-columns] [
            if none? data [data: copy []] 
            if empty? data-columns [
                data-columns: either empty? data [
                    copy [column1]
                ] [
                    either block-data? [
                        repeat i length? first data [
                            append [] either attempt [to-integer pick first data i] [
                                to-word join 'Number i
                            ] [to-word pick first data i]
                        ]
                    ] [copy [column1]]
                ]
            ] 
            if none? viewed-columns [viewed-columns: copy data-columns] 
            no-header-columns: false 
            if none? header-columns [
                no-header-columns: true header-columns: copy data-columns
            ] 
            if all [fit none? resize-column] [resize-column: first viewed-columns] 
            if none? types [types: copy array/initial length? data-columns 'text] 
            indices: copy [] 
            either empty? viewed-columns [
                repeat i length? data-columns [insert tail indices i]
            ] [
                foreach f viewed-columns [
                    all [val: find data-columns f insert tail indices index? val]
                ]
            ] 
            if not block? editable-columns [
                editable-columns: either block? readonly-columns [
                    difference viewed-columns readonly-columns
                ] [
                    viewed-columns
                ]
            ] 
            if empty? sort-direction [
                sort-direction: array/initial length? viewed-columns 'nosort
            ] 
            hdr-face: make face [
                edge: none 
                size: 0x20 
                pane: copy []
            ] 
            hdr-fill-btn-face: make face [
                style: hdr-fill-btn 
                color: 120.120.120 
                var: none 
                edge: make edge [size: 0x1 color: 140.140.140 effect: 'bevel]
            ] 
            hdr-btn-face: make face [
                edge: none 
                style: 'hdr-btn 
                size: 20x20 
                color: 140.140.140 
                var: none 
                eff-blk: copy/deep [draw [
                        pen none fill-pen white polygon 3x5 7x14 11x5
                    ] flip
                ] 
                show-sort-hdr: func [face] [
                    if all [sort-column face/var = sort-column] [
                        face/effect: switch pick sort-direction col-idx sort-column [
                            asc [head insert tail copy eff-blk 1x1] 
                            desc [head insert tail copy eff-blk 1x0]
                        ] [none]
                    ]
                ] 
                corner: none 
                font: make standard-header-font [] 
                feel: make feel [
                    engage: func [face act evt /local i] [
                        if editable? [hide-edit] 
                        switch act [
                            down [
                                foreach h hdr/pane [all [h/style = 'hdr-btn h/effect: none]] 
                                either face/corner [sort-column: none] [
                                    sort-column: face/var 
                                    i: col-idx/viewed sort-column 
                                    either all [
                                        sort-column old-sort-column 
                                        old-sort-column = sort-column
                                    ] [
                                        either tri-state-sort [
                                            sort-modes: find head sort-modes sort-direction/:i 
                                            sort-modes: either tail? next sort-modes [
                                                head sort-modes
                                            ] [next sort-modes] 
                                            change at sort-direction i first sort-modes
                                        ] [
                                            change at sort-direction i 
                                            either sort-direction/:i = 'asc ['desc] ['asc]
                                        ]
                                    ] [
                                        old-sort-column: sort-column
                                    ] 
                                    set-header-buttons
                                ]
                            ] 
                            alt-down [
                                foreach h hdr/pane [all [h/style = 'hdr-btn h/effect: none]] 
                                sort-column: none
                            ]
                        ] 
                        if find [down alt-down] act [
                            face/edge/effect: 'ibevel 
                            list-sort 
                            if not empty? filter [
                                sort-index: intersect sort-index filter-index
                            ] 
                            if limit [sort-index: copy/part sort-index limit] 
                            follow 
                            show face
                        ] 
                        if act = 'up [
                            face/edge/effect: 'bevel 
                            show face/parent-face/parent-face
                        ]
                    ]
                ]
            ] 
            hdr-corner-btn-face: make face [
                edge: none 
                style: 'hdr-corner-btn 
                size: 20x20 
                color: 140.140.140 
                effect: none 
                var: none 
                feel: make feel [
                    engage: func [face act evt] [
                        if editable? [hide-edit] 
                        if find [down alt-down] act [
                            face/edge/effect: 'ibevel 
                            repeat i subtract length? hdr/pane 1 [hdr/pane/:i/effect: none] 
                            show face
                        ] 
                        if act = 'up [
                            face/edge/effect: 'bevel 
                            sort-column: none 
                            sort-direction: array/initial length? data-columns 'nosort 
                            filter-list 
                            follow 
                            set-header-buttons 
                            show face/parent-face
                        ]
                    ]
                ]
            ] 
            lst-face: make face [
                edge: none 
                size: 100x100 
                subface: none 
                single: none 
                pane-fill: none 
                feel: make feel [
                    over: func [face ovr /local f lv] [
                    ]
                ]
            ] 
            scr-face: make-face get-style 'scroller 
            edt-face: make face [
                edge: none 
                text: "" 
                pane: none 
                show?: false
            ] 
            hscr-face: make-face get-style 'scroller 
            pane: reduce [
                make hdr-face [] 
                make lst-face [] 
                make scr-face [] 
                make edt-face [] 
                make hscr-face []
            ] 
            set [hdr lst scr edt hscr] pane 
            if any [
                none? px-widths 
                old-widths <> widths 
                old-size <> size 
                old-viewed-columns <> viewed-columns
            ] [
                if any [
                    none? widths 
                    all [old-viewed-columns old-viewed-columns <> viewed-columns]
                ] [
                    widths: array/initial 
                    length? viewed-columns to-decimal 1 / length? viewed-columns
                ] 
                px-widths: copy widths 
                repeat i length? widths [
                    if decimal? widths/:i [
                        poke px-widths i to-integer widths/:i * (size/x - scr/size/x)
                    ]
                ] 
                if any [
                    none? fonts 
                    all [old-fonts old-fonts <> fonts]
                ] [
                    fonts: array/initial length? viewed-columns make standard-font []
                ] 
                if any [
                    none? paras 
                    all [old-paras old-paras <> paras]
                ] [
                    paras: array/initial length? viewed-columns make standard-para []
                ] 
                old-viewed-columns: copy viewed-columns 
                old-widths: copy widths
            ] 
            e-size: size - (2 * edge/size) 
            hdr/size/x: e-size/x 
            scr/resize/x scroller-width 
            lst/size: as-pair 
            e-size/x - scr/size/x 
            e-size/y - add 
            either h-scroll [scroller-width] [0] 
            lst/offset/y: either empty? header-columns [0] [hdr/size/y] 
            scr/resize/y lst/size/y 
            col-widths: do replace/all trim/with mold px-widths "[]" " " " + " 
            either h-scroll [
                hscr/offset/y: lst/size/y + lst/offset/y 
                hscr/axis: 'x 
                hscr/resize as-pair lst/size/x either h-scroll [scroller-width] [0] 
                hscr/redrag divide (size/x - scroller-width) col-widths
            ] [hscr/size: 0x0] 
            scr/offset: as-pair lst/size/x lst/offset/y 
            either fit [
                resize-column-index: any [
                    attempt [index? find viewed-columns resize-column] 1
                ] 
                sz: lst/size/x 
                repeat i length? px-widths [
                    all [resize-column-index <> i sz: sz - px-widths/:i]
                ] 
                if resize-column-index [change at px-widths resize-column-index sz]
            ] [
                if col-widths < lst/size/x [h-fill: lst/size/x - col-widths]
            ] 
            lst-lo: has [lo sp] [
                lst/subface: layout/tight either row-face [row-face] [
                    lo: copy compose [across space 0 pad (as-pair 0 spacing/y)] 
                    repeat i length? viewed-columns [
                        sp: either i = length? viewed-columns [0] [spacing/x] 
                        insert tail lo compose [
                            list-text (as-pair px-widths/:i - sp row-height) 
                            pad (as-pair sp 0)
                        ]
                    ] 
                    if h-fill > 0 [
                        insert insert tail lo 'list-text as-pair h-fill row-height
                    ] 
                    lo
                ] 
                either row-face [row-height: lst/subface/size/y] [
                    fonts: reduce fonts 
                    paras: reduce paras 
                    repeat i length? lst/subface/pane [
                        lst/subface/pane/:i/font: make standard-font 
                        either i > length? fonts [last fonts] [fonts/:i] 
                        lst/subface/pane/:i/para: make standard-para 
                        either i > length? paras [last paras] [paras/:i]
                    ]
                ] 
                lst/subface/color: spacing-color 
                cells: copy viewed-columns 
                repeat i subtract length? lst/subface/pane either fit [0] [1] [
                    insert next find cells viewed-columns/:i lst/subface/pane/:i
                ]
            ] 
            if not empty? viewed-columns [lst-lo] 
            lst/subface/size/x: lst/size/x 
            list-size: does [to-integer lst/size/y / lst/subface/size/y] 
            value-size: does [
                l: length? either all [empty? filter-specs empty? filter-string] [data] [
                    either empty? filter-index [[]] [sort-index]
                ] 
                any [all [limit min l limit] l]
            ] 
            long-enough: does [
                time? all [
                    greater? now/time/precise - then update-speed then: now/time/precise
                ]
            ] 
            scr/action: has [value] [
                value: to-integer scr/data * max 0 value-size - list-size 
                if all [cnt <> value] [
                    cnt: value 
                    show lst 
                    move-edit
                ]
            ] 
            hscr/action: has [value] [
                scrolling?: true 
                value: do replace/all trim/with mold px-widths "[]" " " " + " 
                hdr/offset/x: lst/offset/x: negate (value - lst/size/x) * hscr/data 
                show self
            ] 
            edt/pane: get in layout/tight either row-face [
                use [pos edt-face i j] [
                    edt-face: copy row-face 
                    i: j: 0 
                    pos: edt-face 
                    until [
                        i: i + 1 
                        pos: find pos 'list-text 
                        either vc: find editable-columns viewed-columns/:i [
                            j: j + 1 
                            change pos 'list-field 
                            if j = length? editable-columns [
                                insert/only next pos 
                                either not all [tab-edit-action not empty? tab-edit-action] [
                                    [hide-edit]
                                ] [[]]
                            ]
                        ] [
                            insert pos: next pos [feel none]
                        ] 
                        any [
                            none? pos 
                            tail? pos 
                            i = length? viewed-columns
                        ]
                    ] edt-face
                ]
            ] [
                edt-lo: copy [across space 0] 
                use [found-columns j] [
                    found-columns: copy [] 
                    repeat i length? viewed-columns [
                        either j: find editable-columns viewed-columns/:i [
                            insert tail edt-lo compose [
                                list-field (
                                    lst/subface/pane/:i/size - 
                                    either i = length? viewed-columns [1x1] [0x1]
                                )
                            ] 
                            append found-columns first j 
                            if empty? difference editable-columns found-columns [
                                insert/only tail edt-lo 
                                either not all [tab-edit-action not empty? tab-edit-action] [
                                    [hide-edit]
                                ] [[]]
                            ]
                        ] [
                            insert tail edt-lo compose [
                                list-text (lst/subface/pane/:i/size/x) feel none
                            ]
                        ] 
                        insert tail edt-lo reduce ['pad spacing/x]
                    ]
                ] edt-lo
            ] 'pane 
            if editable? [
                foreach e edt/pane [
                    e/color: 240.240.240 
                    either row-face [
                        e/font: make standard-font [
                            size: e/font/size 
                            style: e/font/style 
                            align: e/font/align
                        ] 
                        e/para: make standard-para [
                            origin: 0x0 
                            margin: 0x0 
                            indent: e/para/indent
                        ]
                    ] [
                        e/font: make standard-font []
                    ]
                ]
            ] 
            edt/size: lst/subface/size 
            set-scr 
            filter-list 
            cell?: [] 
            row?: [] 
            lst/color: either fill [
                either even? list-size [second colors] [first colors]
            ] [last colors] 
            lst/single: none 
            lst/pane-fill: func [
                face index /local c-index j k rh s o-set t col sp
            ] [
                col: either col: find viewed-columns selected-column [index? col] [none] 
                either integer? index [
                    rh: row-height 
                    c-index: index + cnt 
                    if all [index <= list-size any [fill sort-index/:c-index]] [
                        o-set: k: 0 
                        repeat i length? lst/subface/pane [
                            sp: either i = length? lst/subface/pane [0] [spacing/x] 
                            s: lst/subface 
                            cell: j: s/pane/:i 
                            column: viewed-columns/:i 
                            if not scrolling? [
                                if not row-face [j/offset/x: o-set] 
                                o-set: o-set + j/size/x + sp 
                                if all [not row-face resize-column = data-columns/:i] [
                                    j/size/x: px-widths/:i - sp
                                ]
                            ] 
                            j/color: either 
                            switch select-mode [
                                single [
                                    all [
                                        sort-index/:c-index 
                                        any [
                                            all [
                                                not empty? range 
                                                sort-index/:c-index = second first range
                                            ]
                                        ] 
                                        col = i
                                    ]
                                ] 
                                row [
                                    all [sort-index/:c-index sel-cnt = sort-index/:c-index]
                                ] 
                                column [all [sort-index/:c-index col = i]] 
                                multi [
                                    all [
                                        col 
                                        sort-index/:c-index 
                                        any [
                                            all [
                                                sel-cnt = sort-index/:c-index 
                                                col = i
                                            ] 
                                            found? find range as-pair i sort-index/:c-index
                                        ]
                                    ]
                                ] 
                                multi-row [
                                    all [
                                        col 
                                        sort-index/:c-index 
                                        any [
                                            all [sort-index/:c-index sel-cnt = sort-index/:c-index] 
                                            found? find range as-pair i sort-index/:c-index
                                        ]
                                    ]
                                ]
                            ] [select-color] [pick colors c-index // 2 + 1] 
                            if all [not row-face h-fill > 0 i = length? lst/subface/pane] [
                                j/color: j/color * 0.9
                            ] 
                            if flag-face? j 'text [
                                k: k + 1 
                                j/data: sort-index/:c-index 
                                j/row: index 
                                either all [sort-index/:c-index indices/:k] [
                                    j/text: j/full-text: do either block-data? [
                                        [pick pick data sort-index/:c-index indices/:k]
                                    ] [
                                        [pick data sort-index/:c-index]
                                    ] 
                                    either image? j/text [
                                        j/effect: compose/deep [
                                            draw [
                                                translate ((j/size - j/text/size) / 2) 
                                                image (j/text)
                                            ]
                                        ] 
                                        j/text: none 
                                        row-height
                                    ] [
                                        j/effect: none 
                                        either all [
                                            j/text 
                                            truncate 
                                            not empty? j/text 
                                            (t: index? offset-to-caret j as-pair j/size/x 15) <= 
                                            length? to-string j/text
                                        ] [
                                            either j/para/wrap? [
                                                rh: either variable-height [
                                                    second size-text j
                                                ] [row-height]
                                            ] [
                                                j/truncated?: true 
                                                j/text: join copy/part to-string j/text t - 3 "..."
                                            ]
                                        ] [j/truncated?: false]
                                    ] 
                                    use data-columns compose/deep [
                                        if all [row-action not empty? row-action] [
                                            set either block-data? 
                                            [[(data-columns)]] [[(data-columns/1)]] 
                                            pick data sort-index/:c-index 
                                            do [(row-action)]
                                        ]
                                    ]
                                ] [j/text: j/full-text: j/effect: none]
                            ] 
                            s/offset/y: (index - 1 * s/size/y) - spacing/y
                        ] 
                        s/size/y: rh + spacing/y + either index = list-size [spacing/y] [0] 
                        return s
                    ]
                ] [return to-integer index/y / lst/subface/size/y + 1]
            ] 
            lst/pane: func [face index] [
                either lst/single [
                    either index > 1 [
                        lst/single: none
                    ] [
                        lst/pane-fill face lst/single
                    ]
                ] [
                    if all [debug index = list-size] [
                        print ["filling list:" var now/time/precise]
                    ] 
                    lst/pane-fill face index
                ]
            ] 
            if not empty? header-columns [
                o-set: o-size: 0 
                repeat i min length? header-columns length? viewed-columns [
                    insert tail hdr/pane make hdr-btn-face compose [
                        corner: none 
                        edge: (make edge [size: 1x1 color: 140.140.140 effect: 'bevel]) 
                        offset: (as-pair o-set 0) 
                        text: (
                            to-string to-word pick header-columns 
                            either all [no-header-columns not empty? indices] [
                                indices/:i
                            ] [i]
                        ) 
                        var: (
                            either all [sort-column 1 = length? viewed-columns] [
                                to-lit-word sort-column
                            ] [to-lit-word viewed-columns/:i]
                        ) 
                        size: (as-pair 
                            o-size: either 1 = length? header-columns [
                                either any [not fit h-scroll] [px-widths/:i] [lst/size/x]
                            ] [px-widths/:i] hdr/size/y
                        ) 
                        related: 'hdr-btns
                    ] 
                    o-set: o-set + o-size
                ] 
                if h-fill > 0 [
                    insert tail hdr/pane make hdr-fill-btn-face compose [
                        size: (as-pair h-fill hdr/size/y) 
                        offset: (as-pair o-set 0)
                    ] o-set: o-set + h-fill
                ] 
                glyph-scale: (min scroller-width hdr/size/y) / 3 
                glyph-adjust: as-pair 
                scroller-width / 2 - 1 
                hdr/size/y / 2 - 1 
                insert tail hdr/pane make hdr-corner-btn-face compose/deep [
                    offset: (as-pair o-set 0) 
                    color: 140.140.140 
                    edge: (make edge [size: 1x1 color: 140.140.140 effect: 'bevel]) 
                    size: (as-pair scr/size/x hdr/size/y) 
                    effect: compose/deep [
                        draw [
                            (either 1.3.0.0.0 <= system/version [[anti-alias off]] []) 
                            pen none fill-pen 200.200.200 polygon 
                            (0x-1 * glyph-scale + glyph-adjust) 
                            (1x0 * glyph-scale + glyph-adjust) 
                            (0x1 * glyph-scale + glyph-adjust) 
                            (-1x0 * glyph-scale + glyph-adjust)
                        ]
                    ]
                ] 
                hdr/pane: reduce hdr/pane 
                hdr/size/x: size/x 
                foreach h hdr/pane [all [h/style = 'hdr-btn h/show-sort-hdr h]]
            ]
        ] 
        init: [init-code] 
        refresh: func [/force] [
            scrolling?: false 
            update-speed: now/time/precise 
            either force [init-code] [
                either size <> old-size [init-code] [set-header-buttons filter-list]
            ] 
            if update? [
                if all [self/parent-face show?] [show [lst]] 
                update-speed: now/time/precise - update-speed
            ]
        ] 
        update: func [/local old-update] [
            old-update: update? 
            update?: true 
            refresh 
            update?: old-update
        ]
    ]
] 
login-screen: layout [
    across 
    vh2 "Login Status" return 
    loginarea: area 200x250 wrap return 
    pad 80 btn-cancel "Quit" [Quit] keycode [#"^["] 
    btn-enter "Login Again" [loginarea/text: copy "" login-synapse]
] 
update-loginstatus: func [txt] [
    loginarea/text: rejoin [loginarea/text txt "^/"] 
    show loginarea
] 
comment "end of beer" 
do %beer2.r 
chatroom-peers: make block! [] 
chat-list: copy [] 
chat-users: copy [] 
noeliza: false 
all-lists: copy [] 
chat-debug: false 
update-chatlist: func [/local oldstate ndx newstate oldprivate private-chat?] [
    if value? 'chatlist [
        oldstate: copy/deep chatlist/data 
        oldprivate: chatlist/get-row 
        private-chat?: not any [none? oldprivate empty? oldprivate] 
        chatlist/data: copy [] 
        foreach [user state ipaddress port prefsobj] chat-users [
            newstate: copy "" 
            attempt [ipaddress: to-tuple ipaddress] 
            port: to-integer port 
            if private-chat? [
                if all [oldprivate/1 = ipaddress oldprivate/2 = port] [
                    private-chat?: false
                ]
            ] 
            foreach userbl oldstate [
                if all [userbl/1 = ipaddress userbl/2 = port] [
                    if none? newstate: userbl/6 [
                        newstate: copy ""
                    ] 
                    break
                ]
            ] 
            either empty? newstate [
                repend/only chatlist/data [ipaddress port prefsobj user state]
            ] [
                repend/only chatlist/data [ipaddress port prefsobj user state newstate]
            ]
        ] 
        if private-chat? [
            chatlist/sel-cnt: none 
            pstatus/text: join Oldprivate/4 " has left" 
            show pstatus
        ] 
        chatlist/update
    ]
] 
register context [
    profile: 'PUBTALK-ETIQUETTE 
    version: 1.0.0 
    init: func [
        {Initialize channel specific data and dynamic handlers} 
        channel [object!]
    ] [
        if channel/port/user-data/role = 'L [append chatroom-peers :channel] 
        channel/prof-data: make object! [
        ] 
        channel/read-msg: func [
            "handle incoming MSGs" 
            channel 
            msg
        ] [
            ack-msg channel 
            clientmsg: load msg/payload 
            sound-message 
            if chat-debug [
                print "raw message" probe clientmsg
            ] 
            if error? set/any 'err try [
                case [
                    parse clientmsg ['cmd set usercmd block!] [
                        case [
                            parse usercmd ['revise set msgno integer! set msg string! to end] [
                                revise-message msgno msg
                            ] 
                            parse usercmd ['groups set new-groups block!] [
                                add-new-groups new-groups
                            ] 
                            parse usercmd ['set-userstate set chat-users block!] [
                                update-chatlist
                            ] 
                            parse usercmd ['arrived set arrivee string!] [
                                new-arrival arrivee
                            ] 
                            parse usercmd ['downloading 'started end] [
                                dfl: flash "Downloading Messages" 
                                temp-announce: :sy-announce 
                                sy-announce: none
                            ] 
                            parse usercmd ['downloading 'finished end] [
                                unview/only dfl 
                                post-msg1 ft-chat mold/all reduce [
                                    'cmd reduce ['status "active"]
                                ] 
                                sy-announce: :temp-announce
                            ]
                        ]
                    ] 
                    parse clientmsg ['action set cmdblock block!] [
                        case [
                            cmdblock/1/1 = "nudge" [nudge chat-lay] 
                            cmdblock/1/1 = "ring-bell" [ring-bells] 
                            cmdblock/1/1 = "directory" [
                                use [myip p upfiles tmp rootdir dirdata ipaddress callback-handler3 post-callback-handler fname fsize fdate finf] [
                                    post-callback-handler: [
                                        switch action [
                                            init [
                                                ftprog/data: 0
                                            ] 
                                            read [
                                                ftprog/data: 
                                                either data/5 = 0 [1
                                                ] [
                                                    ftprog/data + (data/6 / data/5)
                                                ] 
                                                show ftprog
                                            ] 
                                            write [
                                                if value? 'update-ftstatus [
                                                    update-ftstatus/timestamp "^/File sent at"
                                                ]
                                            ] 
                                            error []
                                        ]
                                    ] 
                                    update-ftstatus: func [txt 
                                        /timestamp 
                                        /local stamp
                                    ] [
                                        stamp: either timestamp [join " " now/time] [copy ""] 
                                        ftstate/text: rejoin [ftstate/text txt stamp] 
                                        reset-tface ftstate s1
                                    ] 
                                    callback-handler3: [
                                        switch action [
                                            init [
                                                ftprog/data: 0 
                                                show ftprog 
                                                update-ftstatus/timestamp "^/File download started at" 
                                                insert tail file-keys data/1
                                            ] 
                                            read [
                                                ftprog/data: 
                                                either data/5 = 0 [1
                                                ] [
                                                    ftprog/data + (data/6 / data/5)
                                                ] 
                                                show ftprog
                                            ] 
                                            write [
                                                new-name: second split-path data/3 
                                                if exists? join data/7 new-name [
                                                    nr: 0 
                                                    until [
                                                        nr: nr + 1 
                                                        either find tmp-name: copy new-name "." [
                                                            insert find/reverse tail tmp-name "." rejoin ["[" nr "]"]
                                                        ] [
                                                            insert tail tmp-name rejoin ["[" nr "]"]
                                                        ] 
                                                        tmp-name: replace/all tmp-name "/" "" 
                                                        not exists? join data/7 tmp-name
                                                    ] 
                                                    new-name: tmp-name
                                                ] 
                                                rename join data/7 data/1 new-name 
                                                remove at file-list idx: index? find file-keys data/1 
                                                remove at file-keys idx 
                                                update-ftstatus/timestamp "^/Download completed at"
                                            ] 
                                            error []
                                        ]
                                    ] 
                                    dirdata: load cmdblock/1/2 
                                    ipaddress: first parse/all cmdblock/2 ":" 
                                    view/new layout compose [
                                        across 
                                        ft-list: list-view with [
                                            data-columns: [Name Size Date] 
                                            widths: [0.5 0.15 0.35] 
                                            data: (dirdata) 
                                            follow?: false 
                                            list-action: [
                                                finf: ft-list/get-row 
                                                ftname/text: finf/1 
                                                ftsize/text: finf/2 
                                                ftdate/text: finf/3 
                                                show [ftname ftsize ftdate]
                                            ]
                                        ] return 
                                        space 1x1 
                                        text bold "Server:" text (ipaddress) return 
                                        text bold "Status:" 
                                        pad 100 
                                        btn "Test Remote" [
                                            update-ftstatus join "^/Opening 8012 to " ipaddress 
                                            port: make port! [scheme: 'tcp host: ipaddress port-id: 8012 async-modes: [connect]] 
                                            timeout: now + 0:00:15 
                                            do open-loop: [
                                                either now > timeout [
                                                    update-ftstatus "^/Timed out - listener is firewalled"
                                                ] [
                                                    either error? try [open port] [
                                                        wait port do open-loop
                                                    ] [
                                                        update-ftstatus "^/Succeeded" 
                                                        close port
                                                    ]
                                                ]
                                            ] 
                                            comment {^-^-^-^-^-^-^-^-^-^-^-
^-^-^-^-^-^-^-^-^-^-^-if error? try [
^-^-^-^-^-^-^-^-^-^-^-^-p: open/direct to-url rejoin ["tcp://" ipaddress ":8012"]
^-^-^-^-^-^-^-^-^-^-^-^-update-ftstatus "
Succeeded"
^-^-^-^-^-^-^-^-^-^-^-^-close p
^-^-^-^-^-^-^-^-^-^-^-] [
^-^-^-^-^-^-^-^-^-^-^-^-update-ftstatus "
Remote listener is firewalled"
^-^-^-^-^-^-^-^-^-^-^-]
}
                                        ] 
                                        btn "Test Local" [
                                            update-ftstatus "^/Fetching ipaddress" 
                                            if error? set/any 'err try [
                                                myip: read http://www.compkarori.com/cgi-local/whatismyip.r 
                                                either parse myip [thru <ip> copy myip to </ip> to end] [
                                                    trim myip 
                                                    update-ftstatus join "^/Opening connection to " myip 
                                                    port: make port! [scheme: 'tcp host: myip port-id: 8012 async-modes: [connect]] 
                                                    timeout: now + 0:00:15 
                                                    do open-loop: [
                                                        either now > timeout [
                                                            update-ftstatus {
You are currently firewalled. Check NAT settings and make sure port 8012 is open and forwarded to your client PC!}
                                                        ] [
                                                            either error? try [open port] [
                                                                wait port do open-loop
                                                            ] [
                                                                update-ftstatus {
Connection to self succeeded
You should be able to share files.} 
                                                                close port
                                                            ]
                                                        ]
                                                    ] 
                                                    comment {^-^-^-^-^-^-^-^-^-^-^-^-^-
^-^-^-^-^-^-^-^-^-^-^-^-^-if error? try [
^-^-^-^-^-^-^-^-^-^-^-^-^-^-p: open/direct to-url rejoin [tcp:// myip ":8012"]
^-^-^-^-^-^-^-^-^-^-^-^-^-^-update-ftstatus "
Connection to self succeeded
You should be able to share files."

^-^-^-^-^-^-^-^-^-^-^-^-^-^-close p
^-^-^-^-^-^-^-^-^-^-^-^-^-] [
^-^-^-^-^-^-^-^-^-^-^-^-^-^-update-ftstatus "
You are currently firewalled. Check NAT settings and make sure port 8012 is open and forwarded to your client PC!"
^-^-^-^-^-^-^-^-^-^-^-^-^-]
}
                                                ] [
                                                    update-ftstatus "^/http read error?"
                                                ]
                                            ] [
                                                update-ftstatus "^/Unable to reach outside" 
                                                update-ftstatus mold disarm err
                                            ]
                                        ] 
                                        return 
                                        ftstate: text green black font-name font-fixed wrap 280x90 "Not connected" s1: scroller 15x90 [scroll-tface ftstate s1] 
                                        return 
                                        text bold "Name:" ftname: text 280 return 
                                        text bold "Size:" ftsize: text 80 text bold "Date:" ftdate: text 120 return 
                                        ftprog: progress 280 return 
                                        btn "Connect" [open-ft-session (ipaddress)] 
                                        pdbtn: btn "Download" [
                                            if not value? 'ft-get [
                                                update-ftstatus "^/Need to open a GET connection to peer" 
                                                return
                                            ] 
                                            if not none? ft-list/sel-cnt [
                                                get-file/dst-dir ft-get reduce [to-file first ft-list/get-row] callback-handler3 synapse-config/download-dir
                                            ]
                                        ] 
                                        pubtn: btn "Upload" [
                                            if not value? 'ft-post [
                                                update-ftstatus "^/Need to open a POST connection to peer" 
                                                return
                                            ] 
                                            upfiles: request-file/keep/path 
                                            if any [found? upfiles not empty? upfiles] [
                                                tmp: copy [] 
                                                rootdir: first upfiles 
                                                remove upfiles 
                                                foreach file upfiles [
                                                    append tmp join rootdir file
                                                ] 
                                                post-file ft-post tmp post-callback-handler
                                            ]
                                        ] 
                                        btn "Close" keycode [#"^["] [
                                            log-error: none 
                                            if value? 'ft-peer [
                                                destroy-session ft-peer "closed session" 
                                                attempt [
                                                    unset 'ft-get 
                                                    unset 'ft-post 
                                                    unset 'ft-peer
                                                ]
                                            ] 
                                            unview
                                        ] return 
                                        do [
                                            reset-tface ftstate s1 
                                            hide [pdbtn pubtn]
                                        ]
                                    ]
                                ]
                            ] 
                            cmdblock/1/1 = "get-dir" [
                                use [files ip-port filedata inf] [
                                    ip-port: cmdblock/2 
                                    files: read synapse-config/shared-dir 
                                    filedata: copy [] 
                                    foreach file files [
                                        inf: info? join synapse-config/shared-dir file 
                                        repend/only filedata [file inf/size inf/date]
                                    ] 
                                    send-directory reduce [ip-port] filedata
                                ]
                            ] 
                            cmdblock/1/1 = "get-pdir" [
                                use [files ip-port] [
                                    attempt [
                                        ip-port: cmdblock/2 
                                        files: read to-file join synapse-config/shared-dir ip-port 
                                        send-directory reduce [ip-port] files
                                    ]
                                ]
                            ] 
                            (copy/part cmdblock/1/1 17) = "change-background" [
                                dr-block: load skip cmdblock/1 17 
                                patch-cbd 
                                show chat-lay
                            ]
                        ]
                    ] 
                    parse clientmsg [['gchat (pchat: false) | 'pchat (pchat: true)] set groupblock block! set payload block! to end] [
                        use [group newlist] [
                            group: join groupblock/1 "-list" 
                            if none? newlist: select all-lists group [
                                repend all-lists copy/deep [group [] 0] 
                                newlist: select all-lists group 
                                if all [value? 'grouplist not pchat] [
                                    if not non-unique-group? groupblock/1 [
                                        grouplist/append-row/values/no-select reduce [groupblock/1 "<<"] 
                                        grouplist/update
                                    ]
                                ]
                            ] 
                            payload: load payload 
                            repend/only newlist copy payload 
                            save/all todays-chat all-lists 
                            if all [not pchat payload/1 <> "Eliza" payload/1 <> "server"] [
                                synapse-config/lastmessage: payload/7 
                                save-synapse-config
                            ] 
                            either viewing-current-list = group [
                                update-chat-window copy payload
                            ] [
                                either pchat [
                                    update-private-status groupblock/1
                                ] [
                                    update-room-status groupblock/1
                                ]
                            ]
                        ]
                    ] 
                    true [
                    ]
                ]
            ] [
                print "Error occurred with incoming message of content" 
                ?? clientmsg 
                probe mold disarm err
            ]
        ] 
        channel/read-rpy: func [
            "handle incoming replies" 
            channel 
            rpy
        ] [
        ] 
        channel/close: func [
            {to let the profile know, that the channel is being closed} 
            channel
        ] [
            cleanup-chatroom channel
        ]
    ] 
    ack-msg: func [channel] [
        send-frame/callback channel make frame-object [
            msgtype: 'RPY 
            more: '. 
            payload: to binary! "ok"
        ] [
        ]
    ] 
    set 'post-msg func [channel msg] [
        send-frame/callback channel make frame-object [
            msgtype: 'MSG 
            more: '. 
            payload: to binary! :msg
        ] [
        ]
    ] 
    set 'post-msg1 func [channel msg] [
        send-frame channel make frame-object [
            msgtype: 'MSG 
            more: '. 
            payload: to binary! :msg
        ]
    ] 
    set 'cleanup-chatroom func [channel] [
        remove-each peer chatroom-peers [:peer = :channel]
    ] 
    update-chat-window: func [msgline] [
        either viewed? chat-lay [
            use [slide-it] [
                slide-it: f-sld/data = 1 
                f-chat/pane/size/y: append-msg reduce msgline f-chat/pane/size/y 
                f-sld/redrag f-chat/size/y / max 1 f-chat/pane/size/y 
                f-sld/step: 1 / max 1 (length? chat-list) 
                if slide-it [
                    slide-chatpane 1
                ] 
                show [f-chat f-sld]
            ]
        ] [
            display-chat/new 10x10
        ]
    ]
] 
debug: none 
groups: [
    root [
        filetransfer [all-rights] 
        rpc [] 
        PUBTALK-ETIQUETTE []
    ] 
    synapse-guest [
        filetransfer [all-rights] 
        rpc [] 
        PUBTALK-ETIQUETTE []
    ] 
    admin [
    ] 
    monitor [
    ] 
    anonymous [
        filetransfer [all-rights] 
        rpc [] 
        PUBTALK-ETIQUETTE []
    ]
] 
users: [
    "anonymous" 64#{} nologin [anonymous] 
    "listener" 64#{} nologin [monitor] 
    "initializer" 64#{iYoMptG0FDYM36X7K3e+hogrjQ4=} login [initializer] 
    "admin" 64#{x69siejazhnYYfJFuVAzJOEsAa4=} login [admin] 
    "monitor" 64#{Bo+d1ne9PqOnFHaf4v4Qf2NrkGg=} login [monitor] 
    "root" 64#{9xwvZF6BUE65zHr8Ncd3eZOVe00=} login [root] 
    "synapse-guest" 64#{qfSU4SPe7jAqaRkhAfejVoVV0tQ=} login [synapse-guest]
] 
register-user: func [userid pass fname sname gender email secret answer] [
    open-session to-url server func [port] [
        either port? port [
            rpc-peer: port 
            login aa/get rpc-peer/user-data/channels 0 "Guest" "Guest123" func [result] [
                either result [
                    open-lns rpc-peer userid pass fname sname gender email secret answer
                ] [
                    print "login unsuccessful"
                ]
            ]
        ] [
            print "^/Can't connect"
        ]
    ]
] 
open-lns: func [peer userid pass fname sname gender email secret answer] [
    open-channel peer 'rpc 1.0.0 func [channel] [
        either channel [
            lns-channel: channel 
            complete-registration userid pass fname sname gender email secret answer
        ] [
            false
        ]
    ]
] 
open-server-lns: func [peer] [
    update-loginstatus "Requesting RPC channel" 
    open-channel peer 'rpc 1.0.0 func [channel] [
        either channel [
            update-loginstatus "RPC channel opened" 
            server-lns-channel: channel 
            open-server-ft-get peer
        ] [
            false
        ]
    ]
] 
comment {
result: [done [commands 1 time 0:00:00.078]
    ok [register-user ["Colin" "colin1234" "Colin" "Chiu" "M" "colin.chiu@mail.com" "Mother's maiden surname?" "Lowe
"] [true]]
]
result: [true]
} 
complete-registration: func [userid pass fname sname gender email secret answer] [
    send-service lns-channel "basic services" compose/deep [
        [service registration] 
        [register-user (userid) (pass) (fname) (sname) (gender) (email) (secret) (answer)]
    ] func [channel result] [
        either all [
            parse result ['done skip 'ok set result block! end] 
            parse result ['register-user skip set result block! end]
        ] [
            case [
                parse result [integer! string! end] [alert result/2 quit] 
                true [
                    inform layout [
                        across 
                        info 200x100 {Registration accepted - you will receive email notification when your account is activated.  In the meantime you can use the Guest account userid: Guest password: Guest123} wrap 
                        return 
                        pad 150 btn-cancel "Quit" [quit]
                    ]
                ]
            ]
        ] [
            alert result 
            quit
        ]
    ]
] 
ft-profile: profile-registry/filetransfer 
if ft-profile/destination-dir: synapse-config/download-dir [make-dir ft-profile/destination-dir] 
attempt [open-listener 8012] 
file-list: copy [] 
file-keys: make hash! [] 
ft-profile/post-handler: [
    switch action [
        init [
            insert tail file-keys data/1
        ] 
        read [
            comment {
^-^-^-ln: 3 * ((idx: index? find file-keys data/1) - (lst/cnt - 1)) - 1
^-^-^-if bar: lst/grid/pane/:ln [
^-^-^-^-bar/data: either data/5 = 0 [
^-^-^-^-^-1
^-^-^-^-][
^-^-^-^-^-bar/data + (data/6 / data/5)
^-^-^-^-]
^-^-^-^-show bar
^-^-^-]
^-^-^-ln: pick file-list idx
^-^-^-either data/5 = 0 [
^-^-^-^-ln/2/2: 1
^-^-^-][
^-^-^-^-ln/2/2: ln/2/2 + (data/6 / data/5)
^-^-^-]
}
        ] 
        write [
            new-name: second split-path data/3 
            if exists? join data/7 new-name [
                nr: 0 
                until [
                    nr: nr + 1 
                    either find tmp-name: copy new-name "." [
                        insert find/reverse tail tmp-name "." rejoin ["[" nr "]"]
                    ] [
                        insert tail tmp-name rejoin ["[" nr "]"]
                    ] 
                    tmp-name: replace/all tmp-name "/" "" 
                    not exists? join data/7 tmp-name
                ] 
                new-name: tmp-name
            ] 
            rename join data/7 data/1 new-name 
            view/new layout [
                across 
                at 0x0 
                origin 15x10 
                image exclamation.gif 
                pad 0x12 
                guide 
                msg: text bold black copy join new-name " has just been received" return 
                pad 50 btn "OK" #" " [unview]
            ] 
            remove at file-list idx: index? find file-keys data/1 
            remove at file-keys idx
        ] 
        error []
    ]
] 
ft-profile/get-handler: func [channel action data] [
    switch action [
        init [
            insert tail file-keys data/1
        ] 
        read [
            comment {^-^-
^-^-^-ln: 3 * ((idx: index? find file-keys data/1) - (lst/cnt - 1)) - 1
^-^-^-if bar: lst/grid/pane/:ln [
^-^-^-^-bar/data: either data/5 = 0 [
^-^-^-^-^-1
^-^-^-^-][
^-^-^-^-^-bar/data + (data/6 / data/5)
^-^-^-^-]
^-^-^-^-show bar
^-^-^-]
^-^-^-ln: pick file-list idx
^-^-^-either data/5 = 0 [
^-^-^-^-ln/2/2: 1
^-^-^-][
^-^-^-^-ln/2/2: ln/2/2 + (data/6 / data/5)
^-^-^-]
}
        ] 
        write [
            remove at file-list idx: index? find file-keys data/1 
            remove at file-keys idx
        ] 
        error []
    ]
] 
open-ft-session: func [ip] [
    open-session to-url rejoin [atcp:// ip ":8012"] func [port] [
        either port? port [
            ft-peer: port 
            update-ftstatus "^/Connected" 
            do-ft-login ft-peer
        ] [
            update-ftstatus "^/Can't connect"
        ]
    ]
] 
do-ft-login: func [peer] [
    login aa/get peer/user-data/channels 0 "synapse-guest" "Guest" func [result] [
        either result [
            update-ftstatus "^/Logged in as synapse-guest" 
            open-ft-get peer
        ] [update-ftstatus "^/login failed"]
    ]
] 
open-ft-get: func [peer] [
    open-channel peer 'filetransfer 1.0.0 func [channel] [
        either channel [
            ft-get: channel 
            update-ftstatus "^/Channel GET open" 
            show pdbtn 
            open-ft-post peer
        ] ["^/Open Get failed"]
    ]
] 
open-ft-post: func [peer] [
    open-channel peer 'filetransfer 1.0.0 func [channel] [
        either channel [
            ft-post: channel 
            update-ftstatus "^/Channel Post open^/Ready for transfers" 
            show pubtn
        ] [update-ftstatus "^/Open Post failed"]
    ]
] 
open-server-ft-get: func [peer] [
    open-channel peer 'filetransfer 1.0.0 func [channel] [
        either channel [
            server-ft-get: channel 
            update-loginstatus "Channel GET open" 
            open-server-ft-post peer
        ] [update-loginstatus "Open Get failed"]
    ]
] 
open-server-ft-post: func [peer] [
    open-channel peer 'filetransfer 1.0.0 func [channel] [
        either channel [
            server-ft-post: channel 
            update-loginstatus "Channel Post open^/Ready for server transfers" 
            unview/only login-screen
        ] [update-loginstatus "Open Post failed"]
    ]
] 
if debug-on [chat-debug: true] 
if viewDLL? [
    view/new layout [title "Synapse chat"]
] 
view/new login-screen 
update-loginstatus "Login preparation" 
vid-request-color: :request-color 
connected?: false 
no-of-connections: 0 
reconnect: does [
    if connected? [return] 
    no-of-connections: no-of-connections + 1 
    if no-of-connections > 5 [
        alert "Failed to reconnect" 
        return
    ] 
    do open-session server func [port] [
        no-of-connections: 0 
        either port? port [
            peer: port 
            peer/user-data/on-close: func [msg] [
                connected?: false 
                reconnect
            ] 
            do-login
        ] [
            print port
        ]
    ]
] 
do-login: does [
    update-loginstatus "Sending username and password" 
    login aa/get peer/user-data/channels 0 ub/1 ub/2 func [result] [
        either result [
            update-loginstatus "Login successful" 
            open-chat
        ] [
            update-loginstatus "login unsuccessful"
        ]
    ]
] 
do login-synapse: does [
    if none? ub: request-pass/user/pwd/title synapse-config/username synapse-config/password join "Synapse Chat " system/script/header/Version [
        quit
    ] 
    synapse-config/username: pick ub 1 
    synapse-config/password: pick ub 2 
    save-synapse-config 
    all-lists: ["lobby-list" [] 0] 
    if exists? todays-chat: to-file rejoin [home-dir servername "/" now/date "-chat.r"] [
        if error? try [
            update-loginstatus "Loading todays chat" 
            all-lists: load todays-chat
        ] [alert "Error loading today's chat"]
    ] 
    connected?: false 
    reconnect
] 
chat-list: copy [] 
comment {
display-messages: func [msg] [
^-if error? set/any 'err try [
^-^-payload: load msg
^-^-insert tail payload now
^-^-repend/only chat-list msgline: copy payload

^-^-either viewed? chat-lay [
^-^-^-f-chat/pane/size/y: append-msg reduce msgline f-chat/pane/size/y
^-^-^-f-sld/redrag f-chat/size/y / max 1 f-chat/pane/size/y
^-^-^-f-sld/step: 1 / max 1 (length? chat-list)

^-^-^-; scroll chat window only if scroller already set to max
^-^-^-; ie. user is presumed to be reading current messages and not old ones
^-^-^-if f-sld/data = 1 [
^-^-^-^-slide-chatpane 1
^-^-^-]

^-^-^-show [f-chat f-sld]

^-^-] [
^-^-^-display-chat/new 10x10
^-^-]
^-] [

^-^-probe disarm err
^-]
]
} 
chat-lay: layout [] 
open-chat: does [
    update-loginstatus "Opening chat channel" 
    open-channel peer 'PUBTALK-ETIQUETTE 1.0.0 func [channel] [
        either channel [
            ft-chat: channel 
            update-loginstatus "Channel Chat open, sending configuration" 
            post-msg1 ft-chat mold/all reduce [
                'cmd reduce ['login synapse-config/username]
            ] 
            if found? synapse-config/email [
                post-msg1 ft-chat mold/all reduce [
                    'cmd reduce ['email synapse-config/email]
                ]
            ] 
            if not none? synapse-config/city [
                post-msg1 ft-chat mold/all reduce [
                    'cmd reduce ['city synapse-config/city]
                ]
            ] 
            post-msg1 ft-chat mold/all reduce [
                'cmd reduce ['language synapse-config/language]
            ] 
            post-msg1 ft-chat mold/all reduce [
                'cmd [get groups]
            ] 
            append/only chat-history join "/cmd new " synapse-config/lastmessage 
            post-msg1 ft-chat mold/all reduce [
                'cmd reduce ['sync synapse-config/lastmessage]
            ] 
            post-msg1 ft-chat mold/all reduce [
                'cmd [status "active"]
            ] 
            post-msg1 ft-chat mold/all reduce [
                'cmd reduce ['timezone now/zone]
            ] 
            if not viewed? chat-lay [
                display-chat
            ] 
            connected?: true 
            open-server-lns peer 
            true
        ] [update-loginstatus "Failed to open insecure chat channel"]
    ]
] 
min-size: 250x0 
edgesize: 30x135 
go: 0 
dest-file: %"" 
display-chat: func [/new offset /local flh has-focus] [
    has-focus: true 
    set 'sound-message func [] [
        if not has-focus [
            attempt [
                insert sound-port ping1 
                wait sound-port 
                close sound-port
            ]
        ]
    ] 
    form-date: func [dt [date!] /local hr min tm] [
        dt/time: dt/time - dt/zone + now/zone 
        form either now/date = dt/date [
            dt/time
        ] [
            tm: dt/time 
            rejoin [dt/date "/" tm/1 ":" tm/2]
        ]
    ] 
    to-htmlcolor: func [color [tuple!] /local col c] [
        join "#" [
            to-string copy/part at to-hex color/1 7 2 
            to-string copy/part at to-hex color/2 7 2 
            to-string copy/part at to-hex color/3 7 2
        ]
    ] 
    export-html: func [/no-browse /local emit result fil] [
        result: make string! 1000 
        emit: func [d] [append result d] 
        emit rejoin [
            {<html><head><title>Synapse Chat content</title>
^-^-<style type="text/css">
^-^-td.u {font-weight: bold; text-align: right;}
^-^-td.t {white-space: pre;}
^-^-td.d {font-stretch: condensed; font-size: small;} </style></head><body>}
        ] 
        emit join "<h2>Chat " [" for " now/date " at " now/time </h2>] 
        emit {<table style="width: 100%; text-align: left;" border="1" cellpadding="2" cellspacing="1">
^-^- <thead style="text-align: center; vertical-align: top; background-color: rgb(204, 204, 204);">
^-^- <tr><th style="width: 100px;">User </th><th>Talk</th>
^-^- <th style="width: 100px;">Date </th></tr>
^-^- </thead>
^-^- <tbody style="text-align: left; vertical-align: top;">} 
        foreach line chat-list [
            emit join {<tr><td class="u" style="color: } [to-htmlcolor line/2 {;">} line/1 ":</td>"] 
            emit join {<td class="t" style="} [
                any [(if line/4 <> black [join " color: " [to-htmlcolor line/4 ";"]]) ""] 
                any [(if line/5 <> snow [join " background-color: " [to-htmlcolor line/5 ";"]]) ""] 
                any [(if find line/6 'bold [" font-weight: bold;"]) ""] 
                any [(if find line/6 'italic [" font-style: italic;"]) ""] 
                {">} line/3 "</td>"
            ] 
            emit join {<td class="d">} [form-date line/7 "</td></tr>^/"]
        ] 
        emit "^/</tbody></table></body></html>" 
        if all [go <= 0 empty? dest-file] [
            fil: request-file/title/save "Save to HTML file" "Save" 
            either block? fil [dest-file: first fil] [exit]
        ] 
        if error? try [
            write dest-file result 
            if not no-browse [browse dest-file]
        ] [
            alert join {Error while writing the output file "} [dest-file {" !!}]
        ]
    ] 
    cnt: 0 lng: 1 
    offset: any [offset 10x10] 
    comment {
            ^-(either none? line/8 
^-^-^-^-^-[join line/1 ":"]
^-^-^-^-^-[rejoin [ "(" line/8 ") " line/1 ":"]]
^-^-^-t0: tx 30 font [ color: line/2] left bold (form line/8) 


} 
    make-msg-line: func [line [block!] vert-offset [integer!] /local lay t1 t2 t3 colour-state] [
        colour-state: either line/7 < start-time [236.250.152] [snow] 
        lay: layout/tight compose/deep [
            space 0x0 across 
            style tx text font-size (chat-config/fontsize) with [color: snow] 
            t0: tx 30 as-is font [color: gray] font-size 9 left 
            (
                either none? line/8 
                [""] 
                [form line/8]
            ) 
            with [color: snow] 
            [edit-message face/text] 
            t1: tx 80 font [color: line/2] right bold 
            join line/1 ":" 
            with [color: (colour-state)] 
            t2: tx (f-chat/size/x - 210) as-is font [color: line/4 style: line/6] line/3 
            with [color: line/5 pane: copy []] 
            feel [
                engage: func [face act event] [
                    switch act [
                        alt-up [attempt [write clipboard:// face/text cstatus/text: "Message copied" show cstatus]] 
                        down [
                            either not-equal? face system/view/focal-face [
                                focus/no-show face
                            ] [
                                system/view/highlight-start: 
                                system/view/highlight-end: none
                            ] 
                            system/view/caret: offset-to-caret face event/offset 
                            show face 
                            face/action face face/text
                        ] 
                        up [
                            if system/view/highlight-start = system/view/highlight-end [unfocus]
                        ] 
                        over [
                            if not-equal? system/view/caret offset-to-caret face event/offset [
                                if not system/view/highlight-start [system/view/highlight-start: system/view/caret] 
                                system/view/highlight-end: system/view/caret: offset-to-caret face event/offset 
                                show face
                            ]
                        ] 
                        key [
                            if 'copy-text = select ctx-text/keymap event/key [
                                ctx-text/copy-text face unlight-text
                            ]
                        ]
                    ]
                ]
            ] 
            t3: tx 110 form-date line/7 gray
        ] 
        add-hyperlinks t2 
        t0/size/y: t1/size/y: t3/size/y: max t1/size/y t2/size/y 
        t0/offset/y: t1/offset/y: t2/offset/y: t3/offset/y: vert-offset 
        lay/pane
    ] 
    edit-message: func [msgno [string!]] [
        attempt [if empty? msgno [return]] 
        view/new center-face oldeditlo: layout compose [
            across 
            vh3 join "Edit Old Message No: " (msgno) return 
            oldmsg: area 500x300 return 
            pad 395 btn-enter "Submit" [
                post-msg1 ft-chat mold/all reduce [
                    'cmd 
                    reduce ['edit to-integer msgno oldmsg/text]
                ] 
                unview/only oldeditlo
            ] btn-cancel #"^[" [unview/only oldeditlo]
        ] 
        fetch-message to-integer msgno
    ] 
    fetch-message: func [msgno] [
        send-service server-lns-channel "basic services" compose/deep [
            [service maintenance] 
            [fetch-message (msgno)]
        ] func [channel result] [
            either all [
                parse result ['done skip 'ok set result block! end] 
                parse result ['fetch-message skip set result string! end]
            ] [
                oldmsg/line-list: none 
                oldmsg/text: copy result
            ] [
                oldmsg/line-list: none 
                oldmsg/text: copy "message could not be retrieved"
            ] 
            show oldmsg
        ]
    ] 
    scroll: func [of /local nb] [
        nb: f-chat/pane/size/y - f-chat/size/y 
        f-chat/pane/offset/y: negate max 0 min nb of/y * 21 - f-chat/pane/offset/y 
        f-sld/data: max 0 min 1 negate f-chat/pane/offset/y / max 1 nb 
        show [f-chat f-sld]
    ] 
    scroll-feel-lay: func [lay] [
        lay/feel: make lay/feel [
            detect: func [face event /local nb] [
                switch event/type [
                    scroll-line [scroll event/offset] 
                    resize [resize-layout] 
                    close [if not viewed? chat-lay [quit]] 
                    active [has-focus: true] 
                    inactive [has-focus: false]
                ] 
                event
            ]
        ]
    ] 
    save-chat: has [filename] [
        if none? filename: request-file/title/save "Save chat name" "Save" [
            return
        ] 
        filename: filename/1 
        if error? try [
            save/all to-file rejoin [home-dir servername "/" filename] chat-list
        ] [
            alert "Error when saving chat file"
        ]
    ] 
    load-chat: has [filename] [
        if none? filename: request-file/title "Select chat file name" "Load" [
            return
        ] 
        filename: filename/1 
        if error? try [
            chat-list: load filename 
            resize-layout
        ] [
            chat-list: copy [] 
            alert "Error when loading chat file"
        ]
    ] 
    chat-config: make object! [
        user-color: synapse-config/usercolour 
        font-color: black 
        bgd-color: 240.240.240 
        italics: false 
        bold: false 
        fontsize: 11
    ] 
    get-chat-font: has [bl] [
        bl: copy [] 
        if chat-config/italics [append bl 'italic] 
        if chat-config/bold [append bl 'bold] 
        bl
    ] 
    select-color: func [mem /local col] [
        if not none? col: vid-request-color [
            set in chat-config mem col 
            if mem = 'user-color [
                synapse-config/usercolour: col 
                save-synapse-config
            ]
        ] 
        focus f-chatbox
    ] 
    slide-chatpane: func [val] [
        f-chat/pane/offset/y: val * min 0 negate f-chat/pane/size/y - f-chat/size/y 
        show f-chat
    ] 
    patch-cbd: has [img] [
        if not empty? dr-block [
            layout [
                img: image effect [gradient 0x1 255.255.255 190.190.190 draw dr-block] cbd/size
            ] 
            cbd/image: to-image img 
            show cbd
        ]
    ] 
    get-groups: has [data users cdata] [
        users: copy [] 
        data: copy/deep [["lobby" ""]] 
        either value? 'chatlist [
            cdata: copy chatlist/data
        ] [
            return data
        ] 
        foreach bl cdata [
            append users bl/4
        ] 
        foreach [name chat offset] all-lists [
            if name <> "lobby-list" [
                if error? try [
                    name: copy/part name find/last name "-list" 
                    if not find users name [
                        repend/only data [name ""]
                    ]
                ] [
                ]
            ]
        ] 
        data
    ] 
    cbd: [] 
    safe-browse: func [url] [
        if error? try [
            browse url
        ] [
            alert "There's an error with your browser settings"
        ]
    ] 
    set-button: func [f [object!] /local action colour] [
        action: f/data/1 
        colour: form f/effect/2 
        inform btnlo: layout compose/deep [
            style lab text bold 60 right 
            across space 0x2 backdrop 163.214.100 
            vh2 "Configure button" across return 
            lab "Label:" bold c1: field (f/text) 70 return 
            lab "Colour:" bold c2: info (colour) 60 btn "Colour" [c2/text: form request-color show c2] return 
            lab "Action:" bold c3: field (action) 205 return 
            pad 160 btn "Apply" keycode [#"^M"] [
                f/text: copy c1/text 
                f/effect/2: load c2/text 
                f/data/1: copy c3/text 
                show f 
                hide-popup 
                save-links
            ] pad 5 
            btn "Cancel" keycode [#"^["] [hide-popup]
        ]
    ] 
    chat-lay: layout compose/deep [
        style link-btn btn white "Empty" 60 [
            attempt [do face/data/1]
        ] [set-button face] 
        across origin 8x8 space 0x4 
        cbd: backdrop 163.214.144 
        vh2 "Synapse Chat " gold [
            either chat-lay/size/x < 130 [
                synapse-config/position/small-size: chat-lay/size 
                synapse-config/position/small-offset: chat-lay/offset 
                chat-lay/size: 
                either pair? synapse-config/position/large-size [
                    synapse-config/position/large-size
                ] [
                    800x600
                ] 
                if pair? synapse-config/position/large-offset [
                    chat-lay/offset: synapse-config/position/large-offset - 4x30
                ]
            ] [
                synapse-config/position/large-size: chat-lay/size 
                synapse-config/position/large-offset: chat-lay/offset 
                chat-lay/size: 
                either pair? synapse-config/position/small-size [
                    synapse-config/position/small-size
                ] [
                    120x600
                ] 
                if pair? synapse-config/position/small-offset [
                    chat-lay/offset: synapse-config/position/small-offset - 4x30
                ]
            ] 
            save-synapse-config 
            show chat-lay
        ] text form system/script/header/Version bold 
        rate 0:00:30 feel [
            engage: func [face action event] [
                post-msg1 ft-chat mold/all [
                    cmd 
                    [ping]
                ]
            ]
        ] 
        pad 20 
        htmlbtn: btn print.png printdown.png 50x25 [export-html] 
        with [tooltip: "Output chat to html file"] 
        pad 10 b0: btn "Admin" [administer] 
        pad 10 b01: btn "Files" [share-files] 
        pad 10 b02: btn "Reconnect" [reconnect] 
        pad 10 b1: link-btn 
        pad 10 b2: link-btn 
        pad 10 b3: link-btn 
        pad 10 b4: link-btn 
        pad 10 b5: link-btn 
        pad 10 btn "Quit" red [Quit] 
        below space 0x0 
        chatlist: list-view with [
            DATA-COLUMNS: [IPAddress Port Obj User State ?] 
            VIEWED-COLUMNS: [User State ?] 
            HEADER-COLUMNS: ["User" "State" "?"] 
            data: [] 
            sort-column: 'state 
            sort-direction: [asc desc nosort] 
            SCROLLER-WIDTH: 12 
            colors: reduce [snow snow gold snow] 
            widths: [45 40 13] 
            fonts: [
                [size: 11 align: 'left] 
                [size: 11 align: 'left] 
                make object! [size: 11 style: 'bold color: red align: 'center]
            ] 
            row-action: [
                cells/user/font/style: 
                cells/state/font/style: none 
                if "0.0.0.0" <> copy/part form IPAddress 7 [
                    cells/user/font/style: 'bold 
                    cells/state/font/style: 'bold
                ]
            ] 
            row-height: 15 
            fit: false 
            list-action: [
                grouplist/sel-cnt: none show grouplist 
                use [newlist offset] [
                    chatlist/change-row copy/part chatlist/GET-ROW 5 
                    change next next find all-lists viewing-current-list f-sld/data 
                    viewing-current-list: form rejoin [pick chatlist/GET-ROW 4 "-list"] 
                    if none? newlist: select all-lists viewing-current-list [
                        repend all-lists copy/deep [viewing-current-list [] 0] 
                        newlist: first back back tail all-lists
                    ] 
                    chat-list: copy newlist 
                    offset: first next next find all-lists viewing-current-list 
                    resize-layout 
                    slide-chatpane offset 
                    f-sld/data: offset show f-sld
                ] 
                pstatus/text: join "Private chat with " pick chatlist/GET-ROW 4 
                f-0/pane/offset/x: 0 
                show f-0
            ] 
            alt-list-action: [
                popup-chat-user chatlist/GET-ROW wait 0.1 
                chatlist/sel-cnt: none show chatlist
            ]
        ] 110x255 
        grouplist: list-view with [
            DATA-COLUMNS: [Group Status] 
            HEADER-COLUMNS: ["Room" "?"] 
            data: [(get-groups)] 
            SCROLLER-WIDTH: 12 
            widths: [85 13] 
            colors: reduce [snow snow gold snow] 
            fonts: [
                [size: 11 align: 'left style: 'bold] 
                make object! [size: 11 style: 'bold color: red align: 'left]
            ] 
            row-height: 15 
            list-action: [chatlist/sel-cnt: none show chatlist 
                use [newlist offset] [
                    change next next find all-lists viewing-current-list f-sld/data 
                    viewing-current-list: join first grouplist/GET-ROW "-list" 
                    if none? newlist: select all-lists viewing-current-list [
                        repend all-lists copy/deep [viewing-current-list [] 0] 
                        newlist: first back back tail all-lists
                    ] 
                    chat-list: copy newlist 
                    offset: first next next find all-lists viewing-current-list 
                    grouplist/change-row reduce [first grouplist/GET-ROW ""] 
                    resize-layout 
                    slide-chatpane offset 
                    pstatus/text: join "Channel " copy/part grouplist/GET-ROW 1 
                    f-0/pane/offset/x: 0 
                    show f-0 
                    f-sld/data: offset show f-sld
                ]
            ] 
            alt-list-action: [
                use [result] [
                    if found? result: request-text/title "New Group Name?" [
                        either any [result = "chat" non-unique-group? result] [
                            alert "Group name exists or can't use 'chat'"
                        ] [
                            grouplist/append-row/values reduce [result ""] 
                            grouplist/update
                        ]
                    ]
                ]
            ]
        ] 110x150 
        space 0x4 pad 5 
        across 
        cttog: tog "active" "away" [
            post-msg1 ft-chat mold/all reduce [
                'cmd reduce ['status first exclude copy face/texts reduce [face/text]]
            ]
        ] with [tooltip: "change online status"] 
        pad 5 
        cttxt: tog "Enter" "Ctrl-S" [
            synapse-config/enter: f-chatbox/keycode: either face/state [[#"^S"]] [[#"^M"]] 
            show f-chatbox 
            save-synapse-config
        ] with [tooltip: "Key used to send text"] 
        space 0x0 
        return 
        cstatus: text "" white bold 120x12 font [size: 10] with [color: none] 
        at 120x35 
        guide across 
        f-chat: box 650x350 edge [size: 2x2 color: 150.150.150 effect: 'ibevel] with [
            append init [pane: layout/tight/size [] size]
        ] 
        f-sld: scroller 16x350 [slide-chatpane value] space 0x0 return 
        here: at 
        f-0: box 650x28 163.214.144 [face/pane/offset/y: 0 show f-0] 
        return 
        f-chatbox: area 650x60 wrap keycode [#"^M"] [
            send-chat face
        ] 
        return 
        do [setup-links]
    ] 
    f-chatbox/keycode: synapse-config/enter 
    if synapse-config/enter <> [#"^M"] [
        cttxt/state: true 
        show cttxt
    ] 
    if viewDLL? [
        cbd/effect: [gradient 1x1 100.100.100 150.150.180]
    ] 
    button-layout: layout/tight compose [
        size 750x28 
        across space 0x0 backdrop 163.214.144 
        pstatus: text (either synapse-config/enter = [#"^M"] ["Enter Active"] ["Ctrl-S sends"]) 100x40 wrap font [size: 11] bold red [f-0/pane/offset/x: -100 show f-0] 
        pad 5 f-1: btn edit.png editdown.png buttonsize [
            attempt [
                use [url] [
                    url: load f-chatbox/text 
                    case [
                        any [url! = type? url file! = type? url] [editor url] 
                        none? url [] 
                        empty? url [editor ""] 
                        true [do url]
                    ]
                ]
            ]
        ] with [tooltip: "Editor or Execute"] 
        pad 5 btn lastmessage.png lastmessagedown.png buttonsize [if not empty? chat-history [f-chatbox/text: copy last chat-history] focus f-chatbox] 
        with [tooltip: "Last message"] 
        pad 5 btn clear.png cleardown.png buttonsize [f-chatbox/line-list: none f-chatbox/text: copy "" focus f-chatbox show f-chatbox] 
        with [tooltip: "Clear chatbox"] 
        pad 10 
        f-2: btn handlecolour.png handlecolourdown.png buttonsize [select-color 'user-color] 
        with [tooltip: "Change nick colour"] 
        pad 5 
        f-3: btn textcolour.png textcolour.png buttonsize [select-color 'font-color] 
        with [tooltip: "Set text colour"] 
        pad 5 
        f-4: btn bgcolour.png bgcolourdown.png buttonsize [select-color 'bgd-color] 
        with [tooltip: "Set text background colour"] 
        pad 10 
        f-5: tog italicsoff.png italics.png buttonsize [chat-config/italics: face/data 
            if none? f-chatbox/font/style [f-chatbox/style: copy []] 
            either chat-config/italics: face/data [
                set-font f-chatbox 'style 'italic
            ] [
                if find f-chatbox/font/style 'italic [
                    remove find f-chatbox/font/style 'italic
                ]
            ] 
            show f-chatbox
        ] with [tooltip: "Set text italics"] 
        pad 5 
        f-6: tog boldoff.png bold.png buttonsize [
            if none? f-chatbox/font/style [f-chatbox/font/style: copy []] 
            either chat-config/bold: face/data [
                set-font f-chatbox 'style 'bold
            ] [
                if find f-chatbox/font/style 'bold [
                    remove find f-chatbox/font/style 'bold
                ]
            ] 
            show f-chatbox
        ] 
        with [tooltip: "Set text bold"] 
        pad 5 
        f-9: tog fontsize.png fontsizeplus.png buttonsize [
            set-font f-chatbox 'size 
            chat-config/fontsize: either face/data [13] [11] 
            show f-chatbox
        ] 
        with [tooltip: "Set text size"] 
        pad 10 
        f-7: btn textclear.png textclear.png buttonsize [set chat-config reduce [chat-config/user-color black snow false false 11]] 
        with [tooltip: "Remove text colours"] 
        pad 10 
        f-8: btn send.png senddown.png 50x25 [send-chat f-chatbox] 
        with [tooltip: "Send text"] 
        pad 10 
        f-10: tog filteroff.png filteron.png buttonsize [noeliza: face/data] 
        with [tooltip: "Filter out Eliza"] 
        pad 10 
        sdf: field 50 [pattern-ctx/seed-it focus face] 
        with [tooltip: "Seed pattern generator"] 
        pad 5 
        f-11: btn arrowleft.png arrowleftdown.png 35x25 [attempt [pattern-ctx/prev-pattern patch-cbd]] 
        with [tooltip: "Previous pattern"] 
        pad 2 
        f-12: btn arrowright.png arrowrightdown.png 35x25 [pattern-ctx/next-pattern patch-cbd] 
        with [tooltip: "New background pattern"] 
        pad 10 
        f-13: btn save.png savedown.png buttonsize [save-chat] 
        with [tooltip: "Save the chat"] 
        pad 5 
        f-14: btn load.png loaddown.png buttonsize [load-chat] 
        with [tooltip: "Load saved chat file"] 
        pad 10 
        f-15: tog help.png helpoff.png buttonsize [
            synapse-config/popups: not face/data 
            save-synapse-config 
            sy-announce: either face/data [none] [:announce]
        ] 
        with [tooltip: "Toggle popups"]
    ] 
    f-0/pane: button-layout 
    if none? get 'sy-announce [
        f-15/state: true 
        show f-15
    ] 
    cttog/saved-area: true 
    for i 1 15 1 [
        set in do to-word join "f-" i 'saved-area true
    ] 
    grouplist/sel-cnt: 1 
    send-chat: func [face] [
        if empty? trim copy face/text [return] 
        append/only chat-history face/text 
        case [
            find/part face/text "/cmd show groups" 16 [
                post-msg1 ft-chat mold/all reduce [
                    'cmd 
                    [show groups]
                ]
            ] 
            find/part face/text "/cmd get groups" 15 [
                post-msg1 ft-chat mold/all reduce [
                    'cmd 
                    [get groups]
                ]
            ] 
            find/part face/text "/cmd city " 10 [
                synapse-config/city: copy skip face/text 10 
                save-synapse-config 
                post-msg1 ft-chat mold/all reduce [
                    'cmd 
                    reduce ['city synapse-config/city]
                ]
            ] 
            find/part face/text "/cmd language " 14 [
                synapse-config/language: copy skip face/text 14 
                save-synapse-config 
                post-msg1 ft-chat mold/all reduce [
                    'cmd 
                    reduce ['language synapse-config/language]
                ]
            ] 
            find/part face/text "/cmd email " 11 [
                synapse-config/email: copy skip face/text 11 
                save-synapse-config 
                post-msg1 ft-chat mold/all reduce [
                    'cmd 
                    reduce ['email synapse-config/email]
                ]
            ] 
            find/part face/text "/cmd timezone " 14 [
                synapse-config/tz: copy skip face/text 14 
                save-synapse-config 
                post-msg1 ft-chat mold/all reduce [
                    'cmd 
                    reduce ['timezone synapse-config/tz]
                ]
            ] 
            find/part face/text "/cmd " 5 [
                case [
                    find/part face/text "/cmd new " 9 [
                        use [from-dt err2] [
                            if error? set/any 'err2 try [
                                newcmd: to-block load skip face/text 9 
                                from-dt: newcmd/1 
                                switch type?/word from-dt [
                                    date! [] 
                                    word! [
                                        case [
                                            from-dt = 'today [from-dt: now - now/time] 
                                            from-dt = 'yesterday [from-dt: to-date rejoin [now/date - 1 "/00:00+" now/zone]]
                                        ]
                                    ] 
                                    integer! [
                                        from-dt: to-date rejoin [now/date - from-dt "/00:00+" now/zone]
                                    ] 
                                    time! [
                                        from-dt: now - from-dt
                                    ]
                                ] 
                                newcmd/1: from-dt 
                                post-msg1 ft-chat mold/all reduce [
                                    'cmd 
                                    append copy [new] newcmd
                                ]
                            ] [
                                err2: mold disarm err2 
                                f-chatbox/text: rejoin [f-chatbox/text newline err2] 
                                show f-chatbox
                            ]
                        ]
                    ] 
                    true [
                        use [user-cmd tmp] [
                            attempt [
                                parse/all face/text [thru "/cmd " copy user-cmd to end (trim user-cmd)] 
                                if not empty? user-cmd [
                                    user-cmd: load user-cmd 
                                    case [
                                        parse user-cmd ['status set tmp word! end] [
                                            post-msg1 ft-chat mold/all reduce [
                                                'cmd 
                                                reduce ['status form tmp]
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ] 
            found? grouplist/sel-cnt [
                post-msg1 ft-chat mold/all 
                reduce ['gchat 
                    reduce [first grouplist/GET-ROW] 
                    reduce [synapse-config/username chat-config/user-color face/text chat-config/font-color chat-config/bgd-color get-chat-font]
                ]
            ] 
            found? chatlist/sel-cnt [
                use [usr ip-port] [
                    if found? usr: chatlist/GET-ROW [
                        post-msg1 ft-chat mold/all 
                        reduce ['pchat 
                            reduce [usr/4] 
                            reduce [synapse-config/username chat-config/user-color face/text chat-config/font-color chat-config/bgd-color get-chat-font]
                        ]
                    ]
                ]
            ] 
            true [
                alert "Need to select a channel/person" 
                return
            ]
        ] 
        face/line-list: none 
        face/para/scroll: 0x0 
        face/text: copy "" 
        focus f-chatbox 
        show face
    ] 
    max-y: 0 
    deflag-face f-chatbox tabbed 
    deflag-face f-chatbox 'on-unfocus 
    resize-layout: func [] [
        chat-list: copy select all-lists viewing-current-list 
        f-chat/size: chat-lay/size - edgesize - to-pair reduce [chatlist/size/x 0] 
        if chat-lay/size/x > 150 [
            f-sld/offset: to-pair reduce [f-chat/size/x + chatlist/size/x + 9 f-chat/offset/y - 1]
        ] 
        f-sld/resize to-pair reduce [15 f-chat/size/y] 
        f-chatbox/size: to-pair reduce [f-chat/size/x 55] 
        f-chatbox/offset: to-pair reduce [chatlist/size/x + 10 chat-lay/size/y - 63] 
        cbd/size: chat-lay/size 
        f-0/size/x: f-chatbox/size/x 
        patch-cbd 
        f-0/offset/y: f-chatbox/offset/y - 32 
        max-y: 0 lng: length? chat-list 
        f-chat/pane/pane: copy [] 
        f-chat/pane/size/x: f-chatbox/size/x 
        foreach line chat-list [
            max-y: append-msg line max-y
        ] 
        f-chat/pane/size/y: max-y 
        f-sld/redrag f-chat/size/y / max 1 max-y 
        f-sld/step: 1 / max 1 lng 
        chatlist/size/y: chat-lay/size/y - 238 
        grouplist/offset/y: chat-lay/size/y - 201 
        cttxt/offset/y: cttog/offset/y: chat-lay/size/y - 46 
        chatlist/SCROLLER-WIDTH: grouplist/SCROLLER-WIDTH: 12 
        chatlist/update grouplist/update 
        cstatus/offset/y: chat-lay/size/y - 20 
        show chat-lay 
        synapse-config/position/last-offset: chat-lay/offset 
        synapse-config/position/last-size: chat-lay/size 
        save-synapse-config
    ] 
    append-msg: func [line max-y] [
        append f-chat/pane/pane sub: make-msg-line line max-y 
        max-y: max-y + 1 + sub/1/size/y
    ] 
    foreach line chat-list [
        max-y: append-msg line max-y
    ] 
    f-chat/pane/size/y: max-y 
    f-sld/redrag f-chat/size/y / max 1 max-y 
    f-sld/step: 1 / max 1 lng 
    view/new/title/options center-face chat-lay join system/script/header/title [" - Server : " servername] [resize] 
    if pair? synapse-config/position/large-size [
        chat-lay/size: synapse-config/position/large-size
    ] 
    if pair? synapse-config/position/large-offset [
        chat-lay/offset: synapse-config/position/large-offset - 4x30
    ] 
    update-chatlist 
    scroll-feel-lay chat-lay 
    show chat-lay 
    resize-layout
] 
non-unique-group?: func [name [string!]] [
    result: false 
    foreach gp grouplist/data [
        if gp/1 = name [
            result: true 
            break
        ]
    ] 
    return result
] 
add-new-groups: func [names] [
    foreach gp names [
        if not non-unique-group? gp [
            grouplist/append-row/values/no-select reduce [gp ""]
        ]
    ] 
    grouplist/update
] 
nudge: func [face [object!] /local xy] [
    xy: face/offset 
    loop 10 [
        face/offset: xy - to-pair reduce [((random 30) - 15) ((random 30) - 15)] 
        show face 
        wait (random 10) / 100 
        face/offset: xy 
        wait (random 10) / 100 
        show face
    ]
] 
update-room-status: func [room] [
    foreach rm grouplist/data [
        if rm/1 = room [
            rm/2: copy "<<" 
            break
        ]
    ] 
    grouplist/update 
    f-0/pane/offset/x: 0 
    pstatus/text: join "New message in " room 
    show pstatus 
    show f-0
] 
send-action: func [usr [block!] user-action [string!]] [
    post-msg1 ft-chat mold/all reduce [
        'action 
        reduce [rejoin [usr/1 ":" usr/2]] 
        reduce [user-action]
    ]
] 
send-directory: func [usr [block!] data [block!]] [
    post-msg1 ft-chat mold/all reduce [
        'action 
        reduce [usr/1] 
        reduce ["directory" mold/all data]
    ]
] 
revise-message: func [msgno txt /local redisplay] [
    redisplay: false 
    foreach [name list offset] all-lists [
        foreach msg list [
            if msgno = msg/8 [
                msg/3: txt 
                if viewing-current-list = name [
                    redisplay: true
                ]
            ]
        ]
    ] 
    if redisplay [resize-layout]
] 
geolocate: func [ip /local port data whole country city latitude longitude guessed map flag] [
    whole: copy "" 
    port: open/binary/custom atcp://api.hostip.info:80 [
        awake [
            foreach event port/locals/events [
                either error? event [
                    close port 
                    return true
                ] [
                    switch/default event [
                        dns-failure [
                            close port 
                            return true
                        ] 
                        dns [
                        ] 
                        max-retry [
                            close port 
                            return true
                        ] 
                        connect [
                            insert port rejoin ["GET /rough.php?ip=" ip "&position=true HTTP/1.0" "^M^/" "Host: api.hostip.info" {^M
^M
}]
                        ] 
                        read [
                            data: copy port 
                            append whole data
                        ] 
                        write [
                        ] 
                        close [
                            close port 
                            parse/all whole [thru "Country:" copy country to "Country code:" (trim/head/tail country) thru "City:" copy city to "Latitude" (trim city)] 
                            parse/all whole [thru "Latitude:" copy latitude to "Longitude:" (trim/head/tail latitude) thru "Longitude:" copy longitude to "Guessed:" 
                                (trim longitude) thru "Guessed:" copy guessed to end (trim guessed)
                            ] 
                            polo-country/text: form country 
                            polo-city/text: form city 
                            polo-guess/text: form guessed 
                            polo-country/data: form latitude 
                            polo-city/data: form longitude 
                            show [polo-country polo-city polo-guess] 
                            return true
                        ]
                    ] [
                        close port 
                        return true
                    ]
                ]
            ] 
            false
        ]
    ] 
    wait port
] 
geomap: func [ip /local port data whole] [
    whole: copy "" 
    port: open/binary/custom atcp://api.hostip.info:80 [
        awake [
            foreach event port/locals/events [
                either error? event [
                    close port 
                    return true
                ] [
                    switch/default event [
                        dns-failure [
                            close port 
                            return true
                        ] 
                        dns [
                        ] 
                        max-retry [
                            close port 
                            return true
                        ] 
                        connect [
                            insert port rejoin ["GET /flag.php?ip=" ip " HTTP/1.0" "^M^/" "Host: api.hostip.info" {^M
^M
}]
                        ] 
                        read [
                            data: copy port 
                            append whole data
                        ] 
                        write [
                        ] 
                        close [
                            close port 
                            data: to binary! find/tail whole {^M
^M
} 
                            flag/image: attempt [load data] 
                            flag/text: "" 
                            show flag 
                            return true
                        ]
                    ] [
                        close port 
                        return true
                    ]
                ]
            ] 
            false
        ]
    ] 
    wait port
] 
getIpInfo: func [ip /local page country city latitude longitude map flag] [
    returnvar: array/initial 6 "" 
    if error? try [
        page: read rejoin [http://api.hostip.info/get_html.php?ip= ip "&position=true"] 
        parse/all page [thru "Country:" copy country to "City:" (trim/tail country) thru "City:" copy city to "Latitude"] 
        parse/all page [thru "Latitude:" copy latitude to "Longitude:" (trim/tail latitude) thru "Longitude:" copy longitude to end] 
        flag: load read/binary join http://api.hostip.info/flag.php?ip= ip 
        country: form country 
        city: form city 
        latitude: form latitude 
        longitude: form longitude 
        either not empty? latitude [
            map: [browse rejoin [
                    http://www.mapquest.com/maps/map.adp?searchtype=address&formtype=address&latlongtype=decimal&latitude= latitude "&longitude=" longitude
                ]
            ]
        ] [map: ""] 
        return reduce [(country) (city) (latitude) (longitude) (flag) (map)]
    ] [
        return returnvar
    ]
] 
popup-chat-user: func [data [block!] /local obj time err] [
    obj: data/3 
    if error? set/any 'err try [
        time: now/time - now/zone + (to-time obj/tz) 
        if time > 24:00 [
            time: time - 24:00
        ] 
        if time < 0:00 [
            time: time + 24:00
        ]
    ] [
        time: none
    ] 
    polo: layout compose/deep [
        size 270x390 
        origin 20x5 
        style lab text bold right 80 
        across space 2x1 backdrop 163.214.130 
        lab "User name: " polo-user: text (data/4) return 
        lab "IP Address: " [browse http://visualiptrace.visualware.com/] text (form data/1) [write clipboard:// face/text] return 
        lab "Port: " text (form data/2) return 
        lab "City: " polo-owncity: field (form obj/city) 145x20 font [] return 
        lab "Longitude: " polo-long: field (form obj/longitude) 60x20 font [] 
        btn "Googlemaps" [browse rejoin [http://maps.google.com/maps?q= polo-latt/text "%2C" polo-long/text "&t=k"]] return 
        lab "Latitude: " polo-latt: field (form obj/latitude) 60x20 font [] btn-help [attempt [browse http://www.maporama.com]] return 
        lab "Email: " polo-email: field (form obj/email) as-is 145x20 font [] return 
        lab "Time: " text (form time) return 
        space 2x2 
        bar 230x3 return 
        lab "Country: " polo-country: text "Fetching" 160 as-is font [] return 
        lab "City: " polo-city: text "Fetching" 160 as-is font [] [] return 
        lab "Guessed?: " polo-guess: text "" 100 return 
        space 5 pad 60 flag: box 110x55 [
            browse rejoin [
                http://maps.google.com/maps?q= polo-country/data "%2C" polo-city/data "&t=k"
            ]
        ] [
            browse rejoin [
                http://www.mapquest.com/maps/map.adp?searchtype=address&formtype=address&latlongtype=decimal&latitude= polo-country/data "&longitude=" polo-city/data
            ]
        ] 
        return 
        bar 230x3 return 
        pad 35 
        space 2x2 
        btn 80 "Nudge" [send-action [(data/1) (data/2)] "nudge" hide-popup] 
        feel [
            over: func [face act pos] [cstatus/text: either act ["Send a nudge"] [""] show cstatus]
        ] 
        btn 80 "Bells" [send-action [(data/1) (data/2)] "ring-bell" hide-popup] 
        feel [
            over: func [face act pos] [cstatus/text: either act ["Send audio alert"] [""] show cstatus]
        ] return 
        pad 35 
        btn 80 "Background" [send-background [(data/1) (data/2)] hide-popup] 
        feel [
            over: func [face act pos] [cstatus/text: either act ["Send your background"] [""] show cstatus]
        ] 
        btn 80 "Files" red [send-action [(data/1) (data/2)] "get-dir" hide-popup] return 
        pad 35 
        btn-cancel 80 "Update" [update-self] btn 80 "Cancel" keycode #"^[" [unview/only face/parent-face]
    ] 
    view/new polo 
    geolocate data/1 
    geomap data/1
] 
update-self: has [city long latt email] [
    if polo-user/text <> synapse-config/username [return] 
    attempt [
        long: load polo-long/text 
        if not empty? polo-long/text [
            if not any [decimal! = type? long integer! = type? long] [
                alert "Need a decimal or integer value for longitude!" 
                focus polo-long 
                return
            ]
        ]
    ] 
    attempt [
        latt: load polo-latt/text 
        if not empty? polo-latt/text [
            if not any [decimal! = type? latt integer! = type? latt] [
                alert "Need a decimal or integer value for lattitude!" 
                focus polo-latt 
                return
            ]
        ]
    ] 
    attempt [
        if not empty? polo-email/text [
            email: load polo-email/text 
            if email! <> type? email [
                alert "Need an email value here!" 
                focus polo-email 
                return
            ]
        ]
    ] 
    city: polo-owncity/text 
    if any [empty? polo-owncity/text empty? polo-long/text empty? polo-latt/text empty? polo-email/text] [
        alert "Need to fill in all fields" 
        return
    ] 
    post-msg1 ft-chat mold/all reduce [
        'cmd 
        reduce ['update-self email city latt long]
    ]
] 
send-background: func [bl [block!]] [
    if empty? dr-block [return] 
    send-action bl join "change-background" mold/all dr-block
] 
update-private-status: func [nick /local bl] [
    bl: chatlist/data 
    forall bl [
        if all [bl/1/4 = nick] [
            either none? bl/1/6 [
                insert tail bl/1 copy "<<"
            ] [
                bl/1/6: copy "<<"
            ] 
            chatlist/update 
            pstatus/text: copy join "Private message from " bl/1/4 
            f-0/pane/offset/x: 0 
            show f-0 
            either viewed? chat-lay [
                sy-announce join "New private message from " bl/1/4 []
            ] [
                announce join "New private message from " bl/1/4 []
            ] 
            break
        ]
    ]
] 
new-arrival: func [nick] [
    if nick <> synapse-config/username [
        sy-announce join nick " has arrived" [browse http://www.rebol.com]
    ]
] 
web: stylize [
    link: txt leaf 400x20 font-size 11 with [
        para: [wrap?: false] 
        action: [
            either url? self/data [
                either find/part self/data "lib://" 6 [
                    attempt [
                        browse join http://www.rebol.org/cgi-bin/cgiwrap/rebol/view-script.r?script= find/tail self/data "lib://"
                    ]
                ] [
                    error? try [browse self/data]
                ]
            ] [
                either issue? self/data [
                    error? try [browse join http://www.rebol.net/cgi-bin/rambo.r?id= next form self/text]
                ] [
                    switch self/text [
                        "do" [error? try [do self/data]] 
                        "effect" [self/parent-face/effect: copy first next self/data show self/parent-face] 
                        "layout" [
                            error? try [
                                view/new layout first next self/data
                            ]
                        ]
                    ]
                ]
            ]
        ] 
        alt-action: [write clipboard:// mold self/data cstatus/text: "Link copied" show cstatus]
    ]
] 
make-link: func [
    offset "Offset to place link" 
    url "url to perform action on" 
    txt "display text" 
    col "set a color for this link" 
    /font fnt "font object for size, effect etc" 
    /local f
] [
    f: make-face web/link 
    if font [f/font: make fnt []] 
    f/data: url 
    f/text: txt 
    f/offset: offset - 2x2 
    f/size/x: first size-text f 
    if col [set-font f 'color col set-font f 'colors reduce [col f/font/colors/2]] 
    f/saved-area: true 
    f
] 
add-hyperlinks: none 
parser: context [
    link-col-url: leaf 
    link-col-code: crimson 
    non-white-space: complement white-space: charset reduce [#" " newline tab cr #"<" #">"] 
    to-space: [some non-white-space | end] 
    skip-to-next-word: [some non-white-space some white-space | some white-space] 
    msg-face: none 
    match-pattern: func [pattern url color] [
        compose [
            mark: 
            (pattern) (either string? pattern [[to-space end-mark:]] []) 
            (to-paren compose [
                    text: copy/part mark end-mark 
                    offset: caret-to-offset msg-face mark 
                    insert tail msg-face/pane 
                    make-link/font offset (either url [url] [[load text]]) text (color) msg-face/font
                ]) 
            any white-space
        ]
    ] 
    link-rule: clear [] 
    foreach [pattern url color] reduce [
        "lib://" none link-col-url 
        "http://" none link-col-url 
        "https://" none link-col-url 
        "www." [join http:// text] link-col-url 
        "ftp://" none link-col-url 
        "#" none link-col-url 
        "ftp." [join ftp:// text] link-col-url 
        "do http://" none link-col-code 
        "do %" none link-col-code 
        ["do [" (end-mark: second load/next skip mark 3) :end-mark] 
        [first reduce [load text text: copy/part text 2]] 
        link-col-code 
        ["effect [" (end-mark: second load/next skip mark 7) :end-mark] 
        [first reduce [load text text: copy/part text 6]] 
        link-col-code 
        ["layout [" (end-mark: second load/next skip mark 7) :end-mark] 
        [first reduce [load text text: copy/part text 6]] 
        link-col-code
    ] [
        insert insert tail link-rule match-pattern pattern url color '|
    ] 
    insert tail link-rule 'skip-to-next-word 
    use [mark end-mark text offset] [bind link-rule 'mark] 
    set 'add-hyperlinks func [face] [
        msg-face: face 
        error? try [parse/all face/text [any link-rule]]
    ]
] 
polo: layout [] 
kill-active: func [face event] [
    if face = polo [face/changes: []]
] 
administer: func [] [
    refresh-users: func [] [
        send-service server-lns-channel "basic services" compose/deep [
            [service maintenance] 
            [show-users]
        ] func [channel result] [
            comment {
result: [error [command-failed]
    fail [show-users {make object! [
    code: 800
    type: 'user
    id: 'message
    arg1: "insuficient rights"
    arg2: none
    arg3: none
    near: [make error! "insuficient rights"]
    where: none
]}]
]} 
            either all [
                parse result ['done skip 'ok set result block! end] 
                parse result ['show-users set result block! end]
            ] [
                case [
                    parse result [integer! string! end] [alert result/2 quit] 
                    true [
                        admin-list/data: copy/deep result 
                        admin-list/update
                    ]
                ]
            ] [
                either 
                parse result ['error skip 'fail to end] [
                    alert "You don't have sufficient rights"
                ] [
                    alert mold/all result
                ]
            ]
        ]
    ] 
    delete-user: func [bl [block!] /local uid userid ans] [
        if empty? bl [return] 
        uid: bl/1 
        userid: bl/2 
        ans: request/confirm join "Delete userid: " userid 
        if any [none? ans not ans] [return] 
        send-service server-lns-channel "basic services" compose/deep [
            [service maintenance] 
            [delete-user (uid)]
        ] func [channel result] [
            either all [
                parse result ['done skip 'ok set result block! end] 
                parse result ['delete-user skip set result logic! end]
            ] [
                if result [
                    adminstatus/text: join userid " deleted" 
                    show adminstatus
                ]
            ] [
                either 
                parse result ['error skip 'fail to end] [
                    alert "You don't have sufficient rights"
                ] [
                    alert mold/all result
                ]
            ]
        ]
    ] 
    disable-user: func [bl [block!] /local uid userid ans] [
        if empty? bl [return] 
        uid: bl/1 
        userid: bl/2 
        ans: request/confirm join "Disable userid: " userid 
        if any [none? ans not ans] [return] 
        send-service server-lns-channel "basic services" compose/deep [
            [service maintenance] 
            [disable-user (uid)]
        ] func [channel result] [
            either all [
                parse result ['done skip 'ok set result block! end] 
                parse result ['disable-user skip set result logic! end]
            ] [
                if result [
                    adminstatus/text: join userid " disabled" 
                    show adminstatus
                ]
            ] [
                either 
                parse result ['error skip 'fail to end] [
                    alert "You don't have sufficient rights"
                ] [
                    alert mold/all result
                ]
            ]
        ]
    ] 
    enable-user: func [bl [block!] /local uid userid ans] [
        if empty? bl [return] 
        uid: bl/1 
        userid: bl/2 
        ans: request/confirm join "Enable userid: " userid 
        if any [none? ans not ans] [return] 
        send-service server-lns-channel "basic services" compose/deep [
            [service maintenance] 
            [enable-user (uid)]
        ] func [channel result] [
            either all [
                parse result ['done skip 'ok set result block! end] 
                parse result ['enable-user skip set result logic! end]
            ] [
                if result [
                    adminstatus/text: join userid " enabled" 
                    show adminstatus
                ]
            ] [
                either 
                parse result ['error skip 'fail to end] [
                    alert "You don't have sufficient rights"
                ] [
                    alert mold/all result
                ]
            ]
        ]
    ] 
    restart-server: func [/local ans] [
        ans: request/confirm "Restart Server?" 
        if any [none? ans not ans] [return] 
        send-service server-lns-channel "basic services" compose/deep [
            [service maintenance] 
            [restart-server]
        ] func [channel result] [
            either all [
                parse result ['done skip 'ok set result block! end] 
                parse result ['restart-server skip set result logic! end]
            ] [
                if result [
                    adminstatus/text: "server restarted" 
                    show adminstatus
                ]
            ] [
                either 
                parse result ['error skip 'fail to end] [
                    alert "You don't have sufficient rights"
                ] [
                    alert mold/all result
                ]
            ]
        ]
    ] 
    rebuild-users: func [] [
        send-service server-lns-channel "basic services" compose/deep [
            [service maintenance] 
            [rebuild-users]
        ] func [channel result] [
            either all [
                parse result ['done skip 'ok set result block! end] 
                parse result ['rebuild-users set result logic! end]
            ] [
                if result [
                    adminstatus/text: "users reloaded" 
                    show adminstatus
                ]
            ] [
                either 
                parse result ['error skip 'fail to end] [
                    alert "You don't have sufficient rights"
                ] [
                    alert mold/all result
                ]
            ]
        ]
    ] 
    admin-lo: layout [
        across 
        vh2 "Admin Screen" keycode [#"^["] [unview] return 
        admin-list: list-view with [
            data-columns: [UID Userid FName Surname Email Activ] 
            widths: [0.1 0.15 0.2 0.2 0.25 0.1] 
            data: [["" "" "" "" ""]] 
            list-action: [
                adminstatus/text: pick admin-list/get-row 5 
                show adminstatus
            ]
        ] 640x300 return 
        btn "refresh" [attempt [refresh-users]] 
        btn "delete" [attempt [delete-user admin-list/get-row]] 
        btn "enable" [attempt [enable-user admin-list/get-row]] 
        btn "disable" [attempt [disable-user admin-list/get-row]] 
        btn "reload users" [attempt [rebuild-users]] 
        btn "restart" [attempt [restart-server]] 
        btn "mailto" [] 
        adminstatus: field
    ] 
    view/new admin-lo
] 
share-files: has [upfiles rootdir tmp] [
    update-sftstatus: func [txt 
        /timestamp 
        /local stamp
    ] [
        stamp: either timestamp [join " " now/time] [copy ""] 
        sftstate/text: rejoin [sftstate/text txt stamp] 
        reset-tface sftstate s2
    ] 
    get-dir: func [dir [file!]] [
        update-sftstatus "^/fetching directory" 
        sftdir/text: form dir 
        sftname/text: copy "" 
        sftsize/text: copy "" 
        sftdate/text: copy "" 
        show [sftdir sftname sftsize sftdate] 
        send-service server-lns-channel "basic services" compose/deep [
            [service maintenance] 
            [get-dir (dir)]
        ] func [channel result] [
            either all [
                parse result ['done skip 'ok set result block! end] 
                parse result ['get-dir skip set result block! end]
            ] [
                clear sft-list/data 
                insert sft-list/data copy result 
                sft-list/data: copy result 
                sft-list/update 
                update-sftstatus " - done."
            ] [
                either 
                parse result ['error skip 'fail to end] [
                    alert "You don't have sufficient rights"
                ] [
                    alert mold/all result
                ]
            ]
        ]
    ] 
    delete-file: func [filename] [
        update-sftstatus join "^/deleting " filename 
        send-service server-lns-channel "basic services" compose/deep [
            [service maintenance] 
            [delete-file (filename)]
        ] func [channel result] [
            either all [
                parse result ['done skip 'ok set result block! end] 
                parse result ['delete-file skip set result string! end]
            ] [
                update-sftstatus join "^/" result 
                get-dir dirize to-file sftdir/text
            ] [
                either 
                parse result ['error skip 'fail to end] [
                    update-sftstatus "^/You don't have sufficient rights"
                ] [
                    update-sftstatus join "^/" mold/all result
                ]
            ]
        ]
    ] 
    post-callback-handler: [
        switch action [
            init [
                sftdprog/data: 0 
                show sftdprog 
                update-sftstatus/timestamp "^/Sending file at"
            ] 
            read [
                sftdprog/data: 
                either data/5 = 0 [1
                ] [
                    sftdprog/data + (data/6 / data/5)
                ] 
                show sftdprog
            ] 
            write [
                if value? 'update-sftstatus [
                    update-sftstatus/timestamp "^/File sent at"
                ] 
                get-dir dirize to-file sftdir/text
            ] 
            error []
        ]
    ] 
    callback-handler: [
        switch action [
            init [
                update-sftstatus/timestamp "^/Fetching file at " 
                sftprog/data: 0 
                show sftprog
            ] 
            read [
                sftprog/data: 
                either data/5 = 0 [1
                ] [
                    sftprog/data + (data/6 / data/5)
                ] 
                show sftprog
            ] 
            write [
                new-name: second split-path data/3 
                if exists? join data/7 new-name [
                    nr: 0 
                    until [
                        nr: nr + 1 
                        either find tmp-name: copy new-name "." [
                            insert find/reverse tail tmp-name "." rejoin ["[" nr "]"]
                        ] [
                            insert tail tmp-name rejoin ["[" nr "]"]
                        ] 
                        tmp-name: replace/all tmp-name "/" "" 
                        not exists? join data/7 tmp-name
                    ] 
                    new-name: tmp-name
                ] 
                rename join data/7 data/1 new-name 
                update-sftstatus/timestamp "^/File downloaded at "
            ] 
            error []
        ]
    ] 
    view/new layout compose [
        across 
        vh2 "Server Files" keycode [#"^["] [unview] return 
        sft-list: list-view 360x200 with [
            follow?: false 
            data-columns: [Name Size Date] 
            widths: [0.5 0.15 0.35] 
            fonts: [[style: 'bold] [align: 'right] [align: 'left]] 
            data: ["" "" ""] 
            list-action: [
                sfinf: sft-list/get-row 
                either #"/" = last sfinf/1 [
                    get-dir to-file sfinf/1
                ] [
                    sftname/text: sfinf/1 
                    sftsize/text: sfinf/2 
                    sftdate/text: sfinf/3 
                    show [sftname sftsize sftdate]
                ]
            ]
        ] return space 5x1 
        arrow left [get-dir %./] 
        text bold "Directory: " sftdir: text "./" 160 return 
        text bold "Name:" sftname: text 260x40 black wrap return 
        text bold "Size:" sftsize: text 80 text bold "Date:" sftdate: text 130 return 
        space 1x2 
        text bold "D" sftprog: progress 158 
        text bold "U" sftdprog: progress 158 return space 0x0 
        sftstate: text green black font-name font-fixed wrap 340x90 "Ready ..." s2: scroller 15x90 [scroll-tface sftstate s2] 
        return 
        space 5x5 pad 0x5 
        btn "Refresh" [get-dir dirize to-file sftdir/text] 
        btn "Download" [
            if empty? sftname/text [return] 
            if not none? sft-list/sel-cnt [
                either sftdir/text = "./" [
                    get-file/dst-dir server-ft-get reduce [to-file first sft-list/get-row] callback-handler synapse-config/download-dir
                ] [
                    get-file/dst-dir server-ft-get reduce [to-file join sftdir/text first sft-list/get-row] callback-handler synapse-config/download-dir
                ]
            ]
        ] 
        btn "View" [] 
        btn "Upload" [
            if none? upfiles: request-file/keep/path [return] 
            if not empty? upfiles [
                tmp: copy [] 
                rootdir: first upfiles 
                remove upfiles 
                foreach file upfiles [
                    append tmp join rootdir file
                ] 
                post-file server-ft-post tmp post-callback-handler
            ]
        ] 
        btn "Delete" [
            if not none? sft-list/sel-cnt [
                if request/confirm join "Delete file: " sftname/text [
                    either sftdir/text = "%./" 
                    [
                        delete-file sftname/text
                    ] [
                        delete-file join sftdir/text sftname/text
                    ]
                ]
            ]
        ] 
        btn "Clear" [sftstate/text: copy "" show sftstate] 
        return
    ] 
    get-dir dirize to-file sftdir/text
] 
trayHelp: join system/script/header/title [" - " servername] 
set-tray: does [
    If all [not viewdll? equal? system/version/4 3] [
        set-modes system/ports/system [
            tray: compose/deep [
                add main [
                    help: (trayHelp) 
                    menu: [
                        desktop: "Maximize" 
                        reduce: "To Tray" 
                        bar 
                        quit: "Quit"
                    ]
                ]
            ]
        ]
    ]
] 
system-awake: func [port /local r] [
    if all [r: pick port 1 (r/1 = 'tray)] [
        if any [(r/3 = 'activate) all [(r/3 = 'menu) (r/4 = 'desktop)]] [
            set-tray 
            view chat-lay
        ] 
        if all [(r/3 = 'menu) (r/4 = 'reduce)] [unview/all set-tray] 
        if all [(r/3 = 'menu) (r/4 = 'quit)] [quit]
    ] 
    return false
] 
init-tray: does [
    If all [not viewdll? equal? system/version/4 3] [
        system/ports/system: open [scheme: 'system] 
        append system/ports/wait-list system/ports/system 
        system/ports/system/awake: :system-awake 
        set-tray 
        do-events
    ]
] 
init-tray 
do-events
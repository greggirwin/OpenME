REBOL []

    log-error: none 
    debug-on: false 
    no-of-links: 5 
    if not exists? %synapse-buttons.r [
        fl: flash "Downloading images" 
        write %synapse-buttons.r read http://www.compkarori.com/reb/buttons.r 
        unview/only fl
    ] 
    if not exists? %beer.r [
        fl: flash "Download beer library" 
        write %beer.r read http://www.compkarori.com/reb/beer.r 
        unview/only fl
    ] 
    if exists? http://www.compkarori.com/reb/pluginchat77.r [
        request-download/to http://www.compkarori.com/reb/pluginchat78.r %pluginchat.r 
        do %pluginchat.r
    ] 
    synapse-config: make object! [
        username: "" 
        usercolour: 128.128.128 
        lastmessage: now - 3:00 
        popups: false 
        enter: [#"^M"] 
        links: [
            "View" [[call "d:\rebol\rebgui\rebcmdview.exe"] 255.0.0] 
            "Qtask" [[browse http://www.qtask.com/home.cgi]] 
            "Carl" [[browse http://www.rebol.net/cgi-bin/blog.r]] 
            "EMR" [[browse http://compkarori.com/emr/]] 
            "GMail" [[browse http://mail.google.com/mail/] 0.0.255]
        ] 
        email: none 
        city: none 
        tz: now/zone 
        language: "EN"
    ] 
    save-links: has [bt links] [
        links: copy [] 
        for i 1 no-of-links 1 [
            bt: do join "b" i 
            append links bt/text 
            repend links [reduce [bt/data bt/effect/2]]
        ] 
        synapse-config/links: copy/deep links 
        save/all join home-dir %synapse-config.r synapse-config
    ] 
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
    home-dir: switch/default system/version/4 [
        2 [%~/Library/Application%20Support/Synapse%20Chat/] 
        3 [%/c/rebol/synapse%20chat/] 
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
    if exists? join home-dir %synapse-config.r [
        synapse-config: load join home-dir %synapse-config.r
    ] 
    if not find first synapse-config 'popups [
        tmp-synapse-config: make synapse-config [popups: 3 >= system/version/4] 
        synapse-config: make tmp-synapse-config []
    ] 
    if not find first synapse-config 'links [
        tmp-synapse-config: make synapse-config [links: [
                'IREBOL [[call "d:\rebol\rebgui\rebcmdview.exe"] red] 
                'Qtask [[browse http://www.qtask.com/home.cgi]] 
                'Carl [[browse http://www.rebol.net/cgi-bin/blog.r]] 
                'EMR [[browse http://compkarori.com/emr/]] 
                'GMail [[browse http://mail.google.com/mail/] blue]
            ]] 
        synapse-config: make tmp-synapse-config []
    ] 
    if not find first synapse-config 'enter [
        tmp-synapse-config: make synapse-config [email: city: tz: none language: "EN" enter: #"^M"] 
        synapse-config: make tmp-synapse-config []
    ] 
    if not find first synapse-config 'tz [
        tmp-synapse-config: make synapse-config [tz: now/zone] 
        synapse-config: make tmp-synapse-config []
    ] 
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
            twho: text "" 100x35 center wrap 
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
            pop-up-text msg action
        ]
    ] 
    sy-announce: either synapse-config/popups [:announce] [none] 
    buttonsize: 25x25 
    either viewDLL?: 'oldviewDLL = system/product 
    [dr-block: []] 
    [dr-block: 
        [pen none fill-pen diagonal -176x-99 0 122 125 5 3 38.58.108.153 80.108.142.167 0.48.0.168 255.0.255.179 255.164.200.192 72.72.16.174 128.0.0.136 178.34.34.179 255.0.0.180 250.240.230.128 178.34.34.144 128.0.0.177 0.255.255.180 220.20.60.165 44.80.132.147 240.240.240.191 0.0.0.151 box 0x0 1024x768 pen none fill-pen radial -30x-288 0 171 117 8 8 76.26.0.181 0.255.255.144 255.205.40.181 255.150.10.187 160.180.160.129 40.100.130.156 255.255.0.193 255.0.0.129 255.0.255.138 0.255.0.153 255.255.240.140 160.82.45.175 40.100.130.133 0.255.255.184 142.128.110.161 box 0x0 1024x768]
    ] 
    dr-block: [] 
    server: http://www.compkarori.co.nz:8011 set [user pass] ["Guest" "Guest"] 
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
            ping: copy #{} 
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
            data: #{}
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
            flags: [field tabbed return on-unfocus input] 
            feel: make ctx-text/edit bind [
                redraw: func [face act pos] [
                    if all [in face 'colors block? face/colors] [
                        face/color: pick face/colors face <> focal-face
                    ]
                ] 
                detect: none 
                over: none 
                engage: func [face act event] [
                    lv: get in f: face/parent-face/parent-face 'parent-face 
                    switch act [
                        down [
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
                                either equal? 
                                index? find face/parent-face/pane face 
                                length? face/parent-face/pane [
                                    do f/edt-lst-act
                                ] [
                                    do f/edt-fld-act
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
            pane: none 
            feel: make feel [
                over: func [face ovr /local f lv pos] [
                    lv: get in f: face/parent-face/parent-face 'parent-face 
                    do lv/lst-ovr-act 
                    if face/truncated? [
                    ] 
                    either all [
                        ovr lv/ovr-cnt <> face/data
                    ] [
                        lv/ovr: true 
                        f/parent-face/ovr-cnt: face/data
                    ] [lv/ovr: none]
                ] 
                engage: func [face act evt /local f lv p1 p2 r fd] [
                    lv: get in f: face/parent-face/parent-face 'parent-face 
                    if all [
                        lv/lock-list = false 
                        any [act = 'down act = 'alt-down] 
                        face
                    ] [
                        if lv/editable? [lv/hide-edit] 
                        if fd: face/data [
                            pos: as-pair index? find face/parent-face/pane face face/data 
                            either all [
                                evt/shift 
                                any [lv/select-mode = 'multi lv/select-mode = 'multi-row] 
                                lv/sel-cnt 
                                lv/selected-column
                            ] [
                                lv/range: copy reduce switch lv/select-mode [
                                    multi [[
                                            as-pair 
                                            index? find lv/viewed-columns lv/selected-column lv/sel-cnt 
                                            pos
                                        ]] 
                                    multi-row [[
                                            as-pair 1 lv/sel-cnt as-pair 
                                            length? lv/viewed-columns 
                                            face/data
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
                                lv/old-sel-cnt: lv/sel-cnt 
                                lv/sel-cnt: face/data
                            ] 
                            attempt [switch act [
                                    down [do lv/lst-act] 
                                    alt-down [do lv/alt-lst-act]
                                ]] 
                            show f
                        ] 
                        if act = 'up [row: face/row] 
                        if evt/double-click [
                            if lv/lock-list = false [do lv/dbl-lst-act] 
                            if all [fd lv/editable?] [lv/show-edit]
                        ]
                    ]
                ]
            ] 
            data: 0 
            row: 0
        ] 
        list-view: FACE with [
            hdr: hdr-btn: hdr-fill-btn: hdr-corner-btn: lst: lst-fld: scr: edt: none 
            size: 300x200 
            dirty?: fill: true 
            click: none 
            edge: make edge [size: 0x0 color: 140.140.140 effect: 'ibevel] 
            colors: [240.240.240 220.230.220 180.200.180 140.140.140] 
            color: does [either fill [first colors] [last colors]] 
            spacing-color: third colors 
            old-data-columns: copy data-columns: copy indices: copy conditions: [] 
            old-viewed-columns: viewed-columns: header-columns: none 
            old-widths: widths: px-widths: none 
            old-fonts: fonts: none 
            types: none 
            truncate: false 
            drag: false 
            fit: true 
            scroller-width: row-height: 20 
            col-widths: h-fill: 0 
            spacing: 0x0 
            range: copy data: [] 
            resize-column: selected-column: sort-column: none 
            editable?: false 
            last-edit: none 
            h-scroll: false 
            sort-index: [] 
            sort-modes: [asc desc nosort] 
            select-modes: [single multi row multi-row column] 
            select-mode: third select-modes 
            drag-modes: [drag-select drag-move] 
            drag-mode: first drag-modes 
            sort-direction: first sort-modes 
            tri-state-sort: true 
            paint-columns: false 
            ovr-cnt: old-sel-cnt: sel-cnt: none 
            cnt: ovr: 0 
            idx: 1 
            lock-list: false 
            follow?: true 
            row-face: none 
            standard-font: make system/standard/face/font [
                size: 11 shadow: none style: none align: 'left color: black
            ] 
            acquire-func: [] 
            import: func [data [object!]] [
            ] 
            export: does [
                make object! third self
            ] 
            list-size: value-size: 0 
            resize: func [sz] [size: sz update] 
            follow: does [either follow? [scroll-here] [show lst]] 
            lst-act: lst-ovr-act: alt-lst-act: dbl-lst-act: 
            edt-lst-act: edt-fld-act: none 
            block-data?: does [not all [not empty? data not block? first data]] 
            first-cnt: does [
                either empty? filter-string [sel-cnt: 1] [
                    all [sel-cnt sel-cnt: sort-index/1]
                ] follow
            ] 
            prev-page-cnt: does [prev-cnt/skip-size list-size] 
            prev-cnt: func [/skip-size size /local sz] [
                sz: either skip-size [size] [1] 
                all [sel-cnt sel-cnt: 
                    either empty? filter-string [
                        max 1 sel-cnt - sz
                    ] [first skip find sort-index sel-cnt negate list-size]
                ] follow
            ] 
            next-cnt: func [/skip-size size /local sz] [
                sz: either skip-size [size] [1] 
                all [sel-cnt sel-cnt: 
                    either empty? filter-string [
                        min length? sort-index sel-cnt + sz
                    ] [
                        either tail? skip find sort-index sel-cnt sz [
                            last sort-index
                        ] [
                            first skip find sort-index sel-cnt sz
                        ]
                    ]
                ] follow
            ] 
            next-page-cnt: does [next-cnt/skip-size list-size] 
            last-cnt: does [
                either empty? sort-index [sel-cnt: none] [
                    sel-cnt: either empty? filter-string [
                        length? sort-index
                    ] [
                        last sort-index
                    ] follow
                ]
            ] 
            limit-sel-cnt: does [
                if all [sel-cnt not found? find sort-index sel-cnt] [last-cnt]
            ] 
            selected?: does [not none? sel-cnt] 
            old-filter-string: copy filter-string: copy "" 
            filter-pos: func [pos] [attempt [index? find sort-index pos]] 
            filter-sel-cnt: does [all [sel-cnt filter-pos sel-cnt]] 
            filter-index: copy sort-index: copy [] 
            filter: has [default-i i w string result g-length] [
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
            ] 
            scrolling?: none 
            list-sort: has [i vals] [
                sort-index: either not empty? data [
                    head repeat i length? data [insert tail [] i]
                ] [copy []] 
                vals: copy [] 
                either sort-column [
                    i: index? find data-columns sort-column 
                    repeat j length? data [
                        insert tail vals reduce [data/:j/:i j copy data/:j]
                    ] 
                    sort-index: extract/index either sort-direction = 'asc [
                        sort/skip vals 3
                    ] [
                        sort/skip/reverse vals 3
                    ] 3 2
                ] [sort-index]
            ] 
            reset-sort: does [
                sort-column: none 
                sort-direction: 'nosort 
                list-sort 
                foreach p hdr/pane [if p/style = 'hdr-btn [p/effect: none]] 
                update 
                follow
            ] 
            filter-list: has [/no-show] [
                sort-index: either empty? filter [
                    either any [dirty? empty? filter-string] [dirty?: false list-sort] [[]]
                ] [
                    if any [dirty? old-filter-string <> filter-string] [
                        cnt: 0 
                        old-filter-string: copy filter-string 
                        list-sort
                    ] 
                    intersect sort-index filter-index
                ] 
                if not no-show [set-scr]
            ] 
            set-filter: func [string] [
                filter-string: copy string 
                update
            ] 
            reset-filter: does [
                old-filter-string: copy filter-string: copy "" 
                update
            ] 
            scroll-here: has [sl] [
                if all [
                    sel-cnt 
                    not empty? sort-index 
                    select-mode <> 'column 
                    select-mode <> 'multi 
                    select-mode <> 'multi-row
                ] [
                    limit-sel-cnt 
                    sl: index? find sort-index sel-cnt 
                    cnt: min sl - 1 cnt 
                    cnt: (max sl cnt + list-size) - list-size 
                    if list-size < length? sort-index [
                        cnt: (min cnt + list-size value-size) - list-size
                    ] 
                    set-scr
                ]
            ] 
            set-scr: does [
                scr/redrag list-size / max 1 value-size 
                scr/data: either value-size = list-size [0] [
                    cnt / (value-size - list-size)
                ] 
                show self
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
            get-row: func [/here pos /raw rpos /keys /local id] [
                id: get-id pos rpos here raw 
                if all [id select-mode <> 'multi select-mode <> 'multi-row] [
                    either keys [
                        obj: make row [] set obj pick data id obj
                    ] [pick data id]
                ]
            ] 
            find-row: func [value /col colname /local i fnd?] [
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
                        until [
                            i: i + 1 
                            any [
                                all [i = length? data value <> pick data i] 
                                all [value = pick data i fnd?: true]
                            ]
                        ]
                    ] 
                    either fnd? [sel-cnt: i follow get-row] [none]
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
            unique-values: func [column [word!]] [get-block as-pair col-idx column 0] 
            unkey: func [vals] [
                copy/deep either all [block? vals find vals set-word!] [
                    extract/index vals 2 2
                ] [vals]
            ] 
            col-idx: func [word] [index? find data-columns word] 
            clear: does [data: copy [] dirty?: true filter-list] 
            insert-row: func [
                /here pos [integer!] /raw rpos [integer!] /values vals /local id
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
                get-row/raw id
            ] 
            insert-block: func [pos [integer!] vals] [
                all [pos data/:pos insert at data pos vals filter-list]
            ] 
            append-row: func [/values vals /no-select] [
                insert/only tail data either values [unkey vals] [make-row] 
                dirty?: true 
                filter-list/no-show if not no-select [last-cnt] show lst 
                get-row/raw length? data
            ] 
            append-block: func [vals] [
                insert tail data vals 
                dirty?: true 
                filter-list/no-show last-cnt show lst
            ] 
            remove-row: func [/here pos [integer!] /raw rpos [integer!] /local id] [
                id: get-id pos rpos here raw 
                all [id data/:id remove at data id dirty?: true filter-list]
            ] 
            remove-block: func [pos range] [
                for i pos range 1 [remove at data pick sort-index i] 
                dirty?: true 
                filter-list
            ] 
            remove-block-here: func [range] [remove-block range filter-sel-cnt] 
            change-row: func [
                vals /here pos [integer!] /raw rpos [integer!] /top /local id tmp
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
            change-cell: func [
                col val /here pos [integer!] /raw rpos [integer!] /top /local id tmp
            ] [
                id: get-id pos rpos here raw 
                if all [id data/:id] [
                    change at pick data id col-idx col val filter-list 
                    if top [
                        tmp: copy data/:id 
                        remove at data id 
                        data/1: tmp
                    ] 
                    get-row/raw id
                ]
            ] 
            make-row: does [
                either block-data? [array/initial length? data-columns copy ""] [copy ""]
            ] 
            acquire: does [
                if not empty? acquire-func [append-row/values do acquire-func]
            ] 
            show-edit: func [/column col /local vals] [
                if sel-cnt [
                    edt/offset/y: 
                    (lst/subface/size/y) * filter-sel-cnt 
                    vals: get-row 
                    repeat i length? viewed-columns [
                        edt/pane/:i/text: edt/pane/:i/data: pick vals indices/:i
                    ] 
                    show edt 
                    if not selected-column [selected-column: first viewed-columns] 
                    focus pick edt/pane index? find viewed-columns 
                    either column [col] [selected-column]
                ]
            ] 
            hide-edit: has [vals] [
                last-edit: either edt/show? [
                    vals: copy get-row 
                    repeat i length? edt/pane [
                        change/only at vals indices/:i get in pick edt/pane i 'text
                    ] 
                    change-row vals 
                    hide edt 
                    get-row
                ] [none]
            ] 
            init-code: has [o-set e-size val resize-column-index no-header-columns] [
                if none? data [data: copy []] 
                if empty? data-columns [
                    data-columns: either empty? data [
                        copy [column1]
                    ] [
                        either block-data? [
                            foreach d first data [
                                append [] either attempt [to-integer d] ['Number] [to-word d]
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
                hdr: make face [
                    edge: none 
                    size: 0x20 
                    pane: copy []
                ] 
                hdr-fill-btn: make face [
                    style: hdr-fill-btn 
                    color: 120.120.120 
                    var: none 
                    edge: make edge [size: 0x1 color: 140.140.140 effect: 'bevel]
                ] 
                hdr-btn: make face [
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
                            face/effect: switch sort-direction [
                                asc [head insert tail copy eff-blk 1x1] 
                                desc [head insert tail copy eff-blk 1x0]
                            ] [none]
                        ]
                    ] 
                    corner: none 
                    font: make font [align: 'left shadow: 0x1 color: white] 
                    feel: make feel [
                        engage: func [face act evt] [
                            if editable? [hide-edit] 
                            switch act [
                                down [
                                    foreach h hdr/pane [all [h/style = 'hdr-btn h/effect: none]] 
                                    either face/corner [sort-column: none] [
                                        sort-column: face/var 
                                        either tri-state-sort [
                                            sort-modes: either tail? next sort-modes [
                                                head sort-modes
                                            ] [next sort-modes] 
                                            if 'nosort = sort-direction: first sort-modes [
                                                sort-column: none
                                            ] 
                                            show-sort-hdr face
                                        ] [
                                            sort-direction: 
                                            either sort-direction = 'asc ['desc] ['asc] 
                                            face/effect: head insert tail copy eff-blk 
                                            either sort-direction = 'asc [1x1] [1x0]
                                        ]
                                    ]
                                ] 
                                alt-down [
                                    foreach h hdr/pane [all [h/style = 'hdr-btn h/effect: none]] 
                                    sort-column: none
                                ]
                            ] 
                            either any [act = 'down act = 'alt-down] [
                                face/edge/effect: 'ibevel 
                                list-sort 
                                if not empty? filter [
                                    sort-index: intersect sort-index filter-index
                                ] 
                                follow
                            ] [face/edge/effect: 'bevel] 
                            show face/parent-face/parent-face
                        ]
                    ]
                ] 
                hdr-corner-btn: make face [
                    edge: none 
                    style: 'hdr-corner-btn 
                    size: 20x20 
                    color: 140.140.140 
                    effect: none 
                    var: none 
                    feel: make feel [
                        engage: func [face act evt] [
                            if editable? [hide-edit] 
                            either any [act = 'down act = 'alt-down] [
                                face/edge/effect: 'ibevel 
                                repeat i subtract length? hdr/pane 1 [hdr/pane/:i/effect: none] 
                                sort-column: none 
                                sort-direction: 'nosort 
                                list-sort 
                                follow
                            ] [face/edge/effect: 'bevel] 
                            show face/parent-face/parent-face
                        ]
                    ]
                ] 
                lst: make face [
                    edge: none 
                    size: 100x100 
                    subface: none 
                    feel: make feel [
                        over: func [face ovr /local f lv] [
                        ]
                    ]
                ] 
                scr: make-face get-style 'scroller 
                hscr: make-face get-style 'scroller 
                edt: make face [
                    edge: none 
                    text: "" 
                    pane: none 
                    show?: false
                ] 
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
                            px-widths/:i: to-integer widths/:i * (size/x - scr/size/x)
                        ]
                    ] 
                    if any [
                        none? fonts 
                        all [old-fonts old-fonts <> fonts]
                    ] [
                        fonts: array/initial length? viewed-columns make standard-font []
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
                    if resize-column-index [px-widths/:resize-column-index: sz]
                ] [
                    if col-widths < lst/size/x [h-fill: lst/size/x - col-widths]
                ] 
                lst-lo: has [lo edt-lo f sp] [
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
                        repeat i length? lst/subface/pane [
                            f: either i > length? fonts [last fonts] [fonts/:i] 
                            lst/subface/pane/:i/font: make standard-font f
                        ]
                    ] 
                    lst/subface/color: spacing-color
                ] 
                if not empty? viewed-columns [lst-lo] 
                pane: reduce [hdr lst scr edt hscr] 
                lst/subface/size/x: lst/size/x 
                list-size: does [
                    to-integer lst/size/y / lst/subface/size/y
                ] 
                value-size: does [
                    length? either empty? filter-string [data] [
                        either empty? filter-index [[]] [sort-index]
                    ]
                ] 
                scr/action: has [value] [
                    scrolling?: true 
                    value: to-integer scr/data * max 0 value-size - list-size 
                    if all [cnt <> value] [
                        cnt: value 
                        show lst
                    ]
                ] 
                hscr/action: has [value] [
                    scrolling?: true 
                    value: do replace/all trim/with mold px-widths "[]" " " " + " 
                    hdr/offset/x: lst/offset/x: negate (value - lst/size/x) * hscr/data 
                    show self
                ] 
                edt/pane: get in layout/tight either row-face [row-face] [
                    edt-lo: copy [across space 0] 
                    repeat i length? viewed-columns [
                        insert tail edt-lo compose [
                            list-field (lst/subface/pane/:i/size - 0x1)
                        ] 
                        insert/only tail edt-lo 
                        either i = length? viewed-columns [[hide-edit]] [[]] 
                        insert tail edt-lo reduce ['pad spacing/x]
                    ] edt-lo
                ] 'pane 
                foreach e edt/pane [e/font: make standard-font []] 
                edt/size: lst/subface/size 
                set-scr 
                filter-list 
                cell?: [] 
                row?: [] 
                lst/color: either fill [
                    either even? list-size [second colors] [first colors]
                ] [last colors] 
                lst/pane: func [face index /local c-index j k s o-set t col sp] [
                    col: attempt [index? find viewed-columns selected-column] 
                    either integer? index [
                        c-index: index + cnt 
                        if all [index <= list-size any [fill sort-index/:c-index]] [
                            o-set: k: 0 
                            repeat i length? lst/subface/pane [
                                sp: either i = length? lst/subface/pane [0] [spacing/x] 
                                s: lst/subface 
                                j: s/pane/:i 
                                s/offset/y: (index - 1 * s/size/y) - spacing/y 
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
                                            sel-cnt = sort-index/:c-index 
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
                                ] [third colors] [pick colors c-index // 2 + 1] 
                                if all [not row-face h-fill > 0 i = length? lst/subface/pane] [
                                    j/color: j/color * 0.9
                                ] 
                                if flag-face? j 'text [
                                    k: k + 1 
                                    j/data: sort-index/:c-index 
                                    j/row: index 
                                    j/text: attempt [either block-data? [
                                            pick pick data sort-index/:c-index indices/:k
                                        ] [
                                            pick data sort-index/:c-index
                                        ]] 
                                    either image? j/text [
                                        j/effect: compose/deep [
                                            draw [
                                                translate ((j/size - j/text/size) / 2) 
                                                image (j/text)
                                            ]
                                        ] 
                                        j/text: none
                                    ] [
                                        j/effect: none 
                                        either all [
                                            j/text 
                                            truncate 
                                            not empty? j/text 
                                            (t: index? offset-to-caret j as-pair j/size/x 15) <= 
                                            length? to-string j/text
                                        ] [
                                            j/truncated?: true 
                                            j/text: join copy/part to-string j/text t - 3 "..."
                                        ] [j/truncated?: false]
                                    ]
                                ]
                            ] 
                            s/size/y: row-height + spacing/y + 
                            either index = list-size [spacing/y] [0] 
                            return s
                        ]
                    ] [return to-integer index/y / lst/subface/size/y + 1]
                ] 
                if not empty? header-columns [
                    o-set: o-size: 0 
                    repeat i min length? header-columns length? viewed-columns [
                        insert tail hdr/pane make hdr-btn compose [
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
                        insert tail hdr/pane make hdr-fill-btn compose [
                            size: (as-pair h-fill hdr/size/y) 
                            offset: (as-pair o-set 0)
                        ] o-set: o-set + h-fill
                    ] 
                    glyph-scale: (min scroller-width hdr/size/y) / 3 
                    glyph-adjust: as-pair 
                    scroller-width / 2 - 1 
                    hdr/size/y / 2 - 1 
                    insert tail hdr/pane make hdr-corner-btn compose/deep [
                        offset: (as-pair o-set 0) 
                        color: 140.140.140 
                        edge: (make edge [size: 1x1 color: 140.140.140 effect: 'bevel]) 
                        size: (as-pair scr/size/x hdr/size/y) 
                        effect: [
                            draw [
                                anti-alias off 
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
            update: func [/force] [
                scrolling?: false 
                either force [init-code] [
                    either size <> old-size [init-code] [filter-list]
                ] 
                if all [self/parent-face show?] [show self]
            ]
        ]
    ] 
    do %beer.r 
    chatroom-peers: make block! [] 
    chat-list: copy [] 
    chat-users: copy [] 
    noeliza: false 
    all-lists: copy [] 
    chat-debug: false 
    update-chatlist: func [/local oldstate ndx newstate] [
        if value? 'chatlist [
            oldstate: copy/deep chatlist/data 
            chatlist/data: copy [] 
            foreach [user state ipaddress port prefsobj] chat-users [
                newstate: copy "" 
                attempt [ipaddress: to-tuple ipaddress] 
                port: to-integer port 
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
                if chat-debug [
                    print "raw message" probe clientmsg
                ] 
                if error? set/any 'err try [
                    case [
                        parse clientmsg ['cmd set usercmd block!] [
                            case [
                                parse usercmd ['set-userstate set chat-users block!] [
                                    update-chatlist
                                ] 
                                parse usercmd ['arrived set arrivee string!] [
                                    new-arrival arrivee
                                ] 
                                parse usercmd ['downloading 'started end] [
                                    dfl: flash "Downloading Messages"
                                ] 
                                parse usercmd ['downloading 'finished end] [
                                    unview/only dfl 
                                    post-msg1 ft-chat mold/all reduce [
                                        'cmd reduce ['status "active"]
                                    ]
                                ]
                            ]
                        ] 
                        parse clientmsg ['action set cmdblock block!] [
                            case [
                                cmdblock/1 = "nudge" [nudge chat-lay] 
                                cmdblock/1 = "ring-bell" [ring-bells] 
                                (copy/part cmdblock/1 17) = "change-background" [
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
                                        grouplist/append-row/values reduce [groupblock/1 "New"] 
                                        grouplist/first-cnt
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
    if debug-on [chat-debug: true] 
    if none? synapse-config/username: request-text/title/default join system/script/header/Version " Enter user name" synapse-config/username [
        quit
    ] 
    if empty? synapse-config/username [synapse-config/username: copy "Anon"] 
    do save-synapse-config: does [
        save/all join home-dir %synapse-config.r synapse-config
    ] 
    all-lists: ["lobby-list" [] 0] 
    if exists? todays-chat: to-file rejoin [home-dir now/date "-chat.r"] [
        if request "Load today's chat?" [
            if error? try [
                all-lists: load todays-chat
            ] [alert "Error loading today's chat"]
        ]
    ] 
    vid-request-color: :request-color 
    connected?: false 
    do reconnect: does [
        do open-session server func [port] [
            if connected? [return] 
            unview/all 
            either port? port [
                peer: port 
                do-login
            ] [
                print port
            ]
        ]
    ] 
    do-login: does [
        login aa/get peer/user-data/channels 0 user pass func [result] [
            either result [
                open-chat
            ] [
                print "login unsuccessful"
            ]
        ]
    ] 
    chat-list: copy [] 
    display: func [msg] [
        if error? set/any 'err try [
            payload: load msg 
            insert tail payload now 
            repend/only chat-list msgline: copy payload 
            either viewed? chat-lay [
                f-chat/pane/size/y: append-msg reduce msgline f-chat/pane/size/y 
                f-sld/redrag f-chat/size/y / max 1 f-chat/pane/size/y 
                f-sld/step: 1 / max 1 (length? chat-list) 
                if f-sld/data = 1 [
                    slide-chatpane 1
                ] 
                show [f-chat f-sld]
            ] [
                display-chat/new 10x10
            ]
        ] [
            probe disarm err
        ]
    ] 
    chat-lay: layout [] 
    open-chat: does [
        open-channel peer 'PUBTALK-ETIQUETTE 1.0.0 func [channel] [
            either channel [
                ft-chat: channel 
                post-msg1 ft-chat mold/all reduce [
                    'cmd reduce ['login synapse-config/username]
                ] 
                post-msg1 ft-chat mold/all reduce [
                    'cmd reduce ['email synapse-config/email]
                ] 
                post-msg1 ft-chat mold/all reduce [
                    'cmd reduce ['timezone now/zone]
                ] 
                post-msg1 ft-chat mold/all reduce [
                    'cmd reduce ['city synapse-config/city]
                ] 
                post-msg1 ft-chat mold/all reduce [
                    'cmd reduce ['language synapse-config/language]
                ] 
                post-msg1 ft-chat mold/all reduce [
                    'cmd reduce ['new synapse-config/lastmessage]
                ] 
                display-chat 
                connected?: true 
                true
            ] [print "didn't succeed to open insecure chat channel"]
        ]
    ] 
    debug: none 
    min-size: 250x0 
    edgesize: 30x135 
    go: 0 
    dest-file: %"" 
    display-chat: func [/new offset /local flh] [
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
        make-msg-line: func [line [block!] vert-offset [integer!] /local lay t1 t2 t3] [
            lay: layout/tight compose [
                space 0x0 across 
                style tx text font-size (chat-config/fontsize) with [color: snow] 
                t1: tx 100 font [color: line/2] right bold (join line/1 ":") 
                t2: tx (f-chat/size/x - 200) as-is font [color: line/4 style: line/6] line/3 
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
            t1/size/y: t3/size/y: max t1/size/y t2/size/y 
            t1/offset/y: t2/offset/y: t3/offset/y: vert-offset 
            lay/pane
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
                save/all join home-dir filename chat-list
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
        get-groups: has [data] [
            data: copy/deep [["lobby" ""]] 
            foreach [name chat offset] all-lists [
                if name <> "lobby-list" [
                    if error? try [
                        name: copy/part name find/last name "-list" 
                        if not parse name ip-rule [
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
        chat-history: [] 
        set-button: func [f [object!] /local action colour] [
            action: form f/data 
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
                    f/data: to-block copy c3/text 
                    show f 
                    hide-popup 
                    save-links
                ] pad 5 
                btn "Cancel" keycode [#"^["] [hide-popup]
            ]
        ] 
        chat-lay: layout/offset compose/deep [
            style link-btn btn white "Empty" 60 [attempt [do bind face/data 'self]] [set-button face] 
            across origin 8x8 space 0x4 
            cbd: backdrop 163.214.144 
            vh2 "Synapse Chat " gold [
                f-chatbox/text: rejoin [mold chatlist/data newline chatlist/GET-ROW] show f-chatbox
            ] text form system/script/header/Version bold 
            pad 20 
            pad 10 b1: link-btn 
            pad 10 b2: link-btn 
            pad 10 b3: link-btn 
            pad 10 b4: link-btn 
            pad 10 b5: link-btn 
            at 700x8 htmlbtn: btn print.png printdown.png 50x25 [export-html] feel [
                over: func [face act pos] [cstatus/text: either act ["Output chat to html file"] [""] show cstatus]
            ] 
            below space 0x0 
            chatlist: list-view with [
                DATA-COLUMNS: [IPAddress Port Obj User State ?] 
                VIEWED-COLUMNS: [User State ?] 
                HEADER-COLUMNS: ["User" "State" "?"] 
                data: [] 
                SCROLLER-WIDTH: 12 
                colors: reduce [snow snow gold snow] 
                widths: [45 40 13] 
                fonts: [
                    [size: 11 align: 'left style: 'bold] 
                    [size: 11 align: 'left] 
                    make object! [size: 11 style: 'bold color: red align: 'center]
                ] 
                row-height: 15 
                fit: false 
                lst-act: [
                    grouplist/sel-cnt: none show grouplist 
                    use [newlist offset] [
                        chatlist/change-row copy/part chatlist/GET-ROW 5 
                        change next next find all-lists viewing-current-list f-sld/data 
                        viewing-current-list: form rejoin [first chatlist/GET-ROW ":" second chatlist/GET-ROW "-list"] 
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
                alt-lst-act: [
                    popup-chat-user chatlist/GET-ROW wait 0.1 
                    chatlist/sel-cnt: none show chatlist
                ]
            ] 110x255 
            grouplist: list-view with [
                DATA-COLUMNS: [Group Status] 
                HEADER-COLUMNS: ["Group" "?"] 
                data: [(get-groups)] 
                SCROLLER-WIDTH: 12 
                widths: [85 13] 
                colors: reduce [snow snow gold snow] 
                fonts: [
                    [size: 11 align: 'left style: 'bold] 
                    make object! [size: 11 style: 'bold color: red align: 'left]
                ] 
                row-height: 15 
                lst-act: [chatlist/sel-cnt: none show chatlist 
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
                alt-lst-act: [
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
            ] 
            feel [
                over: func [face act pos] [cstatus/text: either act ["change online status"] [""] show cstatus]
            ] 
            pad 5 
            cttxt: tog "Enter" "Ctrl-S" [
                synapse-config/enter: f-chatbox/keycode: either face/state [[#"^S"]] [[#"^M"]] 
                show f-chatbox 
                save-synapse-config
            ] feel [
                over: func [face act pos] [cstatus/text: either act ["To send text"] [""] show cstatus]
            ] 
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
        ] offset 
        f-chatbox/keycode: synapse-config/enter 
        if synapse-config/enter <> [#"^M"] [
            cttxt/state: true 
            show cttxt
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
            ] 
            feel [
                over: func [face act pos] [cstatus/text: either act ["Editor or Execute"] [""] show cstatus]
            ] 
            pad 5 btn lastmessage.png lastmessagedown.png buttonsize [if not empty? chat-history [f-chatbox/text: copy last chat-history] focus f-chatbox] feel [
                over: func [face act pos] [cstatus/text: either act ["Last message"] [""] show cstatus]
            ] 
            pad 5 btn clear.png cleardown.png buttonsize [f-chatbox/line-list: none f-chatbox/text: copy "" focus f-chatbox show f-chatbox] feel [
                over: func [face act pos] [cstatus/text: either act ["Clear chatbox"] [""] show cstatus]
            ] 
            pad 10 
            f-2: btn handlecolour.png handlecolourdown.png buttonsize [select-color 'user-color] feel [
                over: func [face act pos] [cstatus/text: either act ["change nick colour"] [""] show cstatus]
            ] 
            pad 5 
            f-3: btn textcolour.png textcolour.png buttonsize [select-color 'font-color] feel [
                over: func [face act pos] [cstatus/text: either act ["set text colour"] [""] show cstatus]
            ] 
            pad 5 
            f-4: btn bgcolour.png bgcolourdown.png buttonsize [select-color 'bgd-color] feel [
                over: func [face act pos] [cstatus/text: either act ["set text background colour"] [""] show cstatus]
            ] 
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
            ] feel [
                over: func [face act pos] [cstatus/text: either act ["set text italics"] [""] show cstatus]
            ] 
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
            ] feel [
                over: func [face act pos] [cstatus/text: either act ["set text bold"] [""] show cstatus]
            ] 
            pad 5 
            f-9: tog fontsize.png fontsizeplus.png buttonsize [
                set-font f-chatbox 'size 
                chat-config/fontsize: either face/data [13] [11] 
                show f-chatbox
            ] feel [
                over: func [face act pos] [cstatus/text: either act ["set text size"] [""] show cstatus]
            ] 
            pad 10 
            f-7: btn textclear.png textclear.png buttonsize [set chat-config reduce [chat-config/user-color black snow false false 11]] feel [
                over: func [face act pos] [cstatus/text: either act ["remove text colours"] [""] show cstatus]
            ] 
            pad 10 
            f-8: btn send.png senddown.png 50x25 [send-chat f-chatbox] feel [
                over: func [face act pos] [cstatus/text: either act ["send text"] [""] show cstatus]
            ] 
            pad 10 
            f-10: tog filteroff.png filteron.png buttonsize [noeliza: face/data] feel [
                over: func [face act pos] [cstatus/text: either act ["Filter out Eliza"] [""] show cstatus]
            ] 
            pad 10 
            sdf: field 50 [if viewDLL? [alert "Needs AGG" return] pattern-ctx/seed-it focus face] feel [
                over: func [face act pos] [cstatus/text: either act ["Seed pattern generator"] [""] show cstatus]
            ] 
            pad 5 
            f-11: btn arrowleft.png arrowleftdown.png 35x25 [if viewDLL? [alert "Needs AGG" return] attempt [pattern-ctx/prev-pattern patch-cbd]] feel [
                over: func [face act pos] [cstatus/text: either act ["Previous pattern"] [""] show cstatus]
            ] 
            pad 2 
            f-12: btn arrowright.png arrowrightdown.png 35x25 [if viewDLL? [alert "Needs AGG" return] pattern-ctx/next-pattern patch-cbd] feel [
                over: func [face act pos] [cstatus/text: either act ["New background pattern"] [""] show cstatus]
            ] 
            pad 10 
            f-13: btn save.png savedown.png buttonsize [save-chat] feel [
                over: func [face act pos] [cstatus/text: either act ["Save the chat"] [""] show cstatus]
            ] 
            pad 5 
            f-14: btn load.png loaddown.png buttonsize [load-chat] feel [
                over: func [face act pos] [cstatus/text: either act ["Load saved chat file"] [""] show cstatus]
            ] 
            pad 10 
            f-15: tog help.png helpoff.png buttonsize [
                synapse-config/popups: not face/data 
                save-synapse-config 
                sy-announce: either face/data [none] [:announce]
            ] feel [
                over: func [face act pos] [cstatus/text: either act ["Toggle popups"] [""] show cstatus]
            ]
        ] 
        f-0/pane: button-layout 
        if none? get 'sy-announce [
            f-15/state: true 
            show f-15
        ] 
        if viewDLL? [
            cbd/effect: [gradient 1x1 100.100.100 150.150.180]
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
                            ip-port: form rejoin [usr/1 ":" usr/2] 
                            post-msg1 ft-chat mold/all 
                            reduce ['pchat 
                                reduce [ip-port] 
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
            f-chat/size: chat-lay/size - edgesize - to-pair reduce [chatlist/size/x 0] 
            htmlbtn/offset: to-pair reduce [chat-lay/size/x - 90 9] 
            f-sld/resize to-pair reduce [15 f-chat/size/y] 
            f-sld/offset: to-pair reduce [f-chat/size/x + chatlist/size/x + 9 f-chat/offset/y - 1] 
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
        view/new/options center-face chat-lay [resize] 
        update-chatlist 
        scroll-feel-lay chat-lay
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
            probe disarm err 
            time: none
        ] 
        polo: layout compose/deep [size 220x360 
            origin 20x5 
            style lab text bold right 80 
            across space 2x1 backdrop 163.214.130 
            lab "User name: " text (data/4) return 
            lab "IP Address: " text (form data/1) [write clipboard:// face/text] return 
            lab "Port: " text (form data/2) return 
            lab "City: " polo-owncity: text (form obj/city) return 
            lab "Email: " text (form obj/email) as-is return 
            lab "Time: " text (form time) return 
            space 2x2 
            bar 180x3 return 
            lab "Country: " polo-country: text "Fetching" 160 as-is font [] return 
            lab "City: " polo-city: text "Fetching" 160 as-is font [] [] return 
            lab "Guessed?: " polo-guess: text "" 100 return 
            space 5 pad 30 flag: box 110x55 [
                browse rejoin [
                    http://www.mapquest.com/maps/map.adp?searchtype=address&formtype=address&latlongtype=decimal&latitude= polo-country/data "&longitude=" polo-city/data
                ]
            ] return 
            bar 180x3 return 
            pad 10 
            space 2x2 
            btn 80 "Nudge" [send-action chatlist/GET-ROW "nudge" hide-popup] feel [
                over: func [face act pos] [cstatus/text: either act ["Send a nudge"] [""] show cstatus]
            ] 
            btn 80 "Bells" [send-action chatlist/GET-ROW "ring-bell" hide-popup] feel [
                over: func [face act pos] [cstatus/text: either act ["Send audio alert"] [""] show cstatus]
            ] return 
            pad 10 
            btn 80 "Background" [send-background hide-popup] feel [
                over: func [face act pos] [cstatus/text: either act ["Send your background"] [""] show cstatus]
            ] 
            btn 80 "Alert" red [alert "not done yet" hide-popup] return 
            pad 55x5 btn 80 "Cancel" keycode #"^[" [hide-popup]
        ] 
        geolocate data/1 
        geomap data/1 
        inform polo
    ] 
    send-background: does [
        if empty? dr-block [return] 
        send-action chatlist/GET-ROW join "change-background" mold/all dr-block
    ] 
    update-private-status: func [ip-port /local bl] [
        ip-port: parse/all form ip-port ":" 
        attempt [ip-port/1: to-tuple ip-port/1] 
        ip-port/2: to-integer ip-port/2 
        bl: chatlist/data 
        forall bl [
            if all [bl/1/1 = ip-port/1 bl/1/2 = ip-port/2] [
                either none? bl/1/6 [
                    insert tail bl/1 copy "<<"
                ] [
                    bl/1/6: copy "<<"
                ] 
                chatlist/update 
                pstatus/text: copy join "Private message from " bl/1/4 
                f-0/pane/offset/x: 0 
                show f-0 
                sy-announce join "New private message from " bl/1/4 [] 
                break
            ]
        ]
    ] 
    new-arrival: func [nick] [
        sy-announce join nick " has arrived" [browse http://www.rebol.com]
    ] 
    web: stylize [
        link: txt leaf 400x20 font-size 11 with [
            para: [wrap?: false] 
            action: [
                either url? self/data [
                    error? try [browse self/data]
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
            alt-action: [write clipboard:// mold self/data cstatus/text: "Link copied" show cstatus]
        ]
    ] 
    make-link: func [
        offset "Offset to place link" 
        url "url to perform action on" 
        txt "display text" 
        col "set a color for this link" 
        /local f
    ] [
        f: make-face web/link 
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
        non-white-space: complement white-space: charset reduce [#" " newline tab cr #"<" #">"] 
        to-space: [some non-white-space | end] 
        skip-to-next-word: [some non-white-space some white-space] 
        msg-face: none 
        match-pattern: func [pattern url color] [
            compose [
                mark: 
                (pattern) (either string? pattern [[to-space end-mark:]] []) 
                (to-paren compose [
                        text: copy/part mark end-mark 
                        offset: caret-to-offset msg-face mark 
                        insert tail msg-face/pane 
                        make-link offset (either url [url] [[load text]]) text (color)
                    ]) 
                any white-space
            ]
        ] 
        link-rule: clear [] 
        foreach [pattern url color] reduce [
            "http://" none none 
            "www." [join http:// text] none 
            "ftp://" none none 
            "ftp." [join ftp:// text] none 
            "do http://" none crimson 
            "do %" none crimson 
            ["do [" (end-mark: second load/next skip mark 3) :end-mark] 
            [first reduce [load text text: copy/part text 2]] 
            crimson 
            ["effect [" (end-mark: second load/next skip mark 7) :end-mark] 
            [first reduce [load text text: copy/part text 6]] 
            crimson 
            ["layout [" (end-mark: second load/next skip mark 7) :end-mark] 
            [first reduce [load text text: copy/part text 6]] 
            crimson
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
    if 'viewDLL = system/product [
        view/new layout [title "Graham's chat"]
    ] 
    polo: layout [] 
    kill-active: func [face event] [
        if face = polo [face/changes: []]
    ] 
    do-events


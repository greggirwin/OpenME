Rebol [
    Title: "Default"
    Date: 9-Aug-2005/16:04:47+2:00
    File: %default.r
    Author: [{Ladislav Mecir} {Gabriele Santilli}]
    Web: http://www.fm.vslib.cz/~ladislav/rebol
    Purpose: {Error handling functions}
    Category: [General]
]

comment [; Usage:

    ex1: function [[catch]] [r] [
        set/any 'r throw-on-error a
        do b
    ]

    ex2: function [[catch]] [r] [
        if none? set/any 'r attempt a [
            throw make error! "error"
        ]
        do b
    ]

    ex3: function [[catch]] [r] [
        set/any 'r default a [throw error]
        do b
    ]

    a: [return "OK"]
    b: ["KO"]
    
    ex1 ; == "KO"
    ex2 ; == "KO"
    ex3 ; == "OK"
    
    a: [()]
    b: ["OK"]
    
    ex1 ; ERROR
    ex2 ; "OK"
    ex3 ; "OK"
    
    a: [none]
    b: ["OK"]
    
    ex1 ; "OK"
    ex2 ; ERROR
    ex3 ; "OK"
]

default: func [
    {Execute code. If error occurs, execute fault.}
    [throw]
    code [block!] {Code to execute}
    fault [block!] {Error handler}
] [
    either error? set/any 'code try code [
        fault: make function! [[throw] error [error!]] fault
		fault code
    ] [get/any 'code]
]

get-e: func [
    {get an error attribute}
    error [error!]
    attribute [word!]
] [
    get in disarm error attribute
]

set-e: func [
    {set an error attribute}
    error [error!]
    attribute [word!]
    value
] [
    set in disarm error attribute value
]

comment [; improved Throw-on-error:
    throw-on-error: func [
        {Evaluates a block. If it results in an error, throws the error.}
        [throw]
        blk [block!]
    ][
        if error? set/any 'blk try blk [throw blk]
        get/any 'blk
    ]
]

comment [; more complicated alternative, largely untested

    default2: tfunc [
        code [block!]
        fault [block!]
        /good pass [block!]
        /local result error code2
    ] [
        transp-while [not tail? code] [
            if error? error: try [
                code2: second do/next compose [
                    error? set/any 'result (code)
                ]
                code: skip code (index? code2) - 3
            ] [code: tail code]
        ]
        either error? error [
            fault: func [[throw] error [error!]] fault
            fault error
        ] [
            do any [pass [local-return get/any 'result]]
        ]
    ]

]

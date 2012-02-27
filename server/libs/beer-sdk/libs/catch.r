Rebol [
    Title: "Catch"
    File: %catch.r
    Date: 4/Mar/2005/17:12
    Author: "Ladislav Mecir"
    Purpose: {
    	Catches local throw'
    	Ignores non-local throws
    	Works with Parse
    }
]

    ; Evaluation of the following global functions is an error
    return': func [[catch]] [throw make error! [throw not-local]]
    exit': func [[catch]] [throw make error! [throw not-local]]
    throw': func [[catch]] [throw make error! [throw not-local]]
    
    ; Error definition
    system/error/throw: make system/error/throw [
        not-local: "Global return', exit' or throw' evaluated"
    ]

	catch': func [
        {Catches a throw' from a block and returns the value.}
        block [block!] "Block to evaluate"
        /local throw' result1 result2 result1?
	] [
		; "localize" 'throw' in the block
		set [throw' block] use [throw'] reduce [
			reduce ['throw' copy/deep block]
		]
		set throw' func [value [any-type!]] [
			error? set/any 'result1 get/any 'value
			result1?: true
			make error! ""
		]
		either error? set/any 'result2 try block [
			either result1? [return get/any 'result1] [result2]
		] [return get/any 'result2]
	]

comment [
	; Usage:
	catch' [parse "ssss" [(throw' "OK")]]
]

REBOL []
misc.r: true	;-- already loaded 

*func*: :func

dump-word: func [
	word [word!]
	/local type value
][
	value: switch/default type: type?/word value: get/any word [
		unset!	['unset!]
		object! [third :value]
		function! [third :value]
	][:value]
	if block? :value [new-line/all :value off] ;-- this, because mold/flat does not remove LF
	ajoin [
		mold to-set-word word
		tab type tab
		copy/part mold/flat :value 50
	]
]

dump-params: func [
	ctx [object!] 
	/with-locals	; dump also locals
	/local type out fields value
][
	out: make string! 50
	if 'self = pick fields: bind first ctx ctx 1 [remove ctx]	;-- remove 'self if any
	unless with-locals [clear find fields [/local]]	;-- remove locals
	foreach word fields [
		append out reduce ["--" tab dump-word to-word word lf]
	]
	head remove back tail out	;-- remove last lf
]

;-- create a tracable function
fun: func [
	param body
][
	unless find param /local [param: append copy param /local]
	use [*name*][
		*name*: none
		*func* param compose/deep [
			*name*: any [*name* form get in disarm try [1 / 0] 'where] ;-- trick to get the function name
			use [res ctx err name][
				ctx: bind? 'local
				print [*name* "->" lf dump-params ctx]
				if error? set/any 'res try [do make function! [] bind/copy [(body)] ctx][
					error? err: :res
					res: error!
				]
				print [*name* "<-" find/tail dump-word 'res tab]
				either :res = error! [:err][get/any 'res]
			]
		]
	]
]

trace-func: func [body /local save][
	save: :func
	func: :fun
	do body
	func: :save
]

resolve: func [		;-- optimized for objects
	{modify target using source (if fields intersect)}
	target [object!] source [object!]
][ 
	set/any
		bind 
			bind
				copy next first source		
				source 
			target
		get/any source
	target
]

;- set words to false if not already defined.
defined?: func [words [block!]][
	foreach word words [
		unless value? word [set word false]
	]
]

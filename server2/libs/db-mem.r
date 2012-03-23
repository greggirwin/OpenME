db-mem Module.
Memory cached database handler.

rebol []
db-mem.r: true

db-mem: context [	; module

proto: [
	table-name: none	; string!
	index: none			; object! of hashs (one per key)
	data: copy []		; data container (block of blocks)
	schema: none		; object! describing the data schema 
	syntax: none		; parsing rule used to check syntax
	fields: none		; object! with current field values
	position: false 	; current position (integer! or false)

	;-- Automatically reconstructed to handle associated indexes
	append-fields: func[][
		insert/only tail data get fields
	]

	append-record: func [
		{Append a block}
		record [block!]
	][
			set-fields record
			check-syntax
			append-fields
	]
	
	set-fields: func [rec [block!]][set fields rec]

	update-fields: func [
		{update current position with fields object!}
		/local hash
	][
		assert [integer? position position <= length? data]
		check-syntax
		foreach key next first index [;-- update indexes
			poke index/:key position fields/:key
		]
		poke data position get fields
		fields
	]
	
	where: func [
		{Get position based on an indexed key}
		key [word!] value
		/local pos
	][
		all [
			integer? position
			position > 0
			position <= length? data
			all [pos: find at index/:key position :value index? pos]
		]
	]
	
	fetch: func [
		{Fetch a position. returns fields or false}
		with [integer! block! none!] 
	][
		;-- A block contains several WHERE clauses.
		;   the clause which returns the minimal position is taken.
		with: either block? with [any sort reduce with][with]
		all [
			integer? with
			with > 0
			with <= length? data
			set fields pick data with
			fields
		]
	]

	check-syntax: func [[catch]][
		unless parse get fields syntax [
				print-syntax schema fields
				throw make error! reform ["Invalid syntax in table" table-name]
		]
		true
	]

	bound: func [body [block!]][bind bind body fields self]

	indexed-by: func [
		keys [object!] 
		/local code
	][
		unprotect [index]
		index: keys
		protect [index]
		code: rebuild-index self
		;-- reconstruct append-fields (makes the code faster)
		append-fields: func[] append code [
			insert/only tail data get fields
		]	
	]
]

rebuild-index: func [
	proto [object!]
	/local code key-list
][
	key-list: bind copy next first proto/index proto/index

	;-- construct code to insert data in indexes
	code: make block! 31
	foreach key key-list [
		set key make block! length? proto/data ;-- currently block! not hash! (append is faster)
		append code compose [
			insert tail (key) (in proto/fields key)
		]	
	]
	;-- populate indexes with data
	foreach rec proto/data proto/bound [
		set-fields rec
		;-- no syntax checking: Makes the code faster, but one does not detect corrupted database, worth it ?
		;check-syntax	;WARNING
		do code
	]
	;-- convert blocks to hashs
	foreach key key-list [
		set key make hash! get key
	]
	recycle	; trying to free temp blocks, worth it ?
	code 	; return code block (used to modify the function append-fields)
]

new: func [
	table-name [string!] schema [block!]
	/local ctx
][
	ctx: context proto
	schema: context bind schema ctx 
	ctx/table-name: table-name
	ctx/schema: schema
	ctx/syntax: get/any schema
	ctx/fields: make ctx/schema [] 
	set ctx/fields none
	ctx/index: none
	protect bind [schema syntax fields index] ctx
	ctx
]

print-syntax: func [schema fields /local raw rule rules value][
	raw: get fields
	rules: bind copy next first schema schema
	foreach word rules [
		rule: get/any word
		either parse raw [set value rule raw: to end][
			print ["** (ok)" form word "[" mold rule "] :" mold/flat :value]
		][
			print ["** (KO)" form word "is not [" mold rule "] :" mold/flat raw]
			exit
		]
	]
]
] ;end module

;--------------
;- test
;--------------
'do [	
	test: db-mem/new "test" [
		nom: string!
		age: integer!
	]
	do test/bound [

		indexed-by construct [nom: age:]

		foreach rec [
			["toto" 15]
			["tata" 30]
		][
			append-record rec
		]
		
		attempt [append-record ["wrong age-->" Fuuuuuuu]]

		probe fetch 1
		probe fetch 2
		
		position: 1
		probe fetch where 'nom "toto"
		
		position: 1
		probe fetch where 'age 30
	]
	halt
]
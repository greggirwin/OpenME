Rebol [
    Title: "Associative array"
    Purpose: {An implementation of associative array}
    Date: 16/Mar/2005/16:38
    Author: "Ladislav Mecir"
]

comment {
    (By Joel Neely)
    Suppose one has a collection of small numbers (such as test scores
    ranging from 1 to 100'000) and one wants to know how many occurrences
    of each distinct number there are.
    
    How would one implement the solution using associative arrays in Rebol?
    
    This is my old trial using Rebol hash!, block! and object! datatypes,
    which looks acceptable in new betas

; create random scores for testing purposes
scores: copy []
loop 300'000 [insert tail scores random 100'000]

; start the clock
start: now/time/precise

; this is how to process the scores
tallies: aa/make 100'000
foreach score scores [aa/set tallies score (aa/get/default tallies score 0) + 1]

; stop the clock
stop: now/time/precise

; check the results
sum: 0
foreach score tallies/keys [sum: sum + aa/get tallies score]
print ["sum:" sum "time:" stop - start]

}

; Associative array implementation (-: easy exercise for the reader :-)

use [rm mk len? clr] [
    ; to be able to redefine 'make,  'remove and 'length?
    rm: :remove
    mk: :make
    len?: :length?
    clr: :clear
    aa: make object! [
	    make: func [
    	    {Create an associative array}
        	size [integer!]
	    ] [
    	    mk object! [
        	    keys: mk hash! size
            	values: mk block! size
	        ]
    	]
	    get: func [
    	    {Get a value associated with a key}
        	aa [object!]
	        key
    	    /default
        	on-fault
	        /local pos
    	] [
        	either pos: find aa/keys key [pick aa/values index? pos] [do on-fault]
	    ]
    	set: func [
        	{Associate a value with a key}
	        aa [object!]
    	    key
        	value
	        /local pos
    	] [
        	either pos: find aa/keys key [poke aa/values index? pos value] [
        		insert tail aa/keys key
	            insert/only tail aa/values :value
    	    ]
	    ]
    	remove: func [
        	{Remove an association}
	        aa [object!]
    	    key
        	/local pos
	    ] [
    	    if pos: find aa/keys key [rm at aa/values index? pos rm pos]
	    ]
    	length?: func [
        	{Get the length of the associative array}
	        aa [object!]
    	] [len? aa/values]
	    empty?: func [
    	    {Is the associative array empty?}
        	aa [object!]
	    ] [tail? aa/values]
	    clear: func [
	    	{clear the associative array}
	    	aa [object!]
	    ] [
	    	clr aa/keys
	    	clr aa/values
		]
	]
]

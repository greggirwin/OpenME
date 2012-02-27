REBOL [
	; File information
	title:      "Stripped-down version of moliad utility functions library."
	file:       %utils.r
	version:    1.0.2
	date:       2012-02-21
	author:     "Maxim Oliver-Adlhoch"
	purpose:    "Collection of re-useable generic functions used in most projects"
	web:        http://www.moliad.net
	source-encoding: "Windows-1252"
	note:		"Steel Library Manager (SLiM) is Required to use this module."

	; SLiM - Steel Library Manager, minimal requirements
	slim-name:    'utils
	slim-version: 1.0.1
	slim-prefix:  none


	; Licensing details
	copyright:  "Copyright © 2006-2012 Maxim Oliver-Adlhoch"
	license-type: 'MIT
	license:    {Copyright © 2006-2012 Maxim Olivier-Adlhoch.

		Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
		and associated documentation files (the "Software"), to deal in the Software without restriction, 
		including without limitation the rights to use, copy, modify, merge, publish, distribute, 
		sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
		is furnished to do so, subject to the following conditions:
		
		The above copyright notice and this permission notice shall be included in all copies or 
		substantial portions of the Software.}
		
	disclaimer: {THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
		INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
		PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
		FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ]
		ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
		THE SOFTWARE.}
]



slim/register [
	

	;-----------------------------------------------------------------------
	;- SCRIPT ENVIRONMENT CONTROL.
	;-----------------------------------------------------------------------
	
	;-----------------
	;-     get-application-title()
	;-----------------
	get-application-title: func [
		/local script parent
	][
		parent: system/script
		until [
			;print parent/header
			script: parent
			parent: script/parent
			any [
				none? parent
				none? parent/header
			]
		]
		script/title
	]	
	
	;-  
	;-----------------------------------------------------------------------
	;- WORDS
	;-----------------------------------------------------------------------
	;-----------------
	;-     swap-values()
	;
	; given two words, it will swap the values these words reference or contain.
	;-----------------
	swap-values: func [
		'a 'b 
		/local c
	][c: get a set a get b set b  c]
	
		
	
	
	
	;--------------------------
	;-     extract-set-words()
	;--------------------------
	; purpose:  finds set-words within a block of code, hierarchically.
	;
	; inputs:   block!
	;
	; returns:  the list of words in set or normal word notation
	;
	; notes:    none-transparent
	;
	; tests:    [  
	;				probe extract-set-words/only [ t: rr x: 5]  
	;			]
	;--------------------------
	extract-set-words: func [
		blk [block! none!]
		/only "returns values as set-words, not ordinary words.  Useful for creating object specs."
		/local words rule word
	][
		vin "extract-set-words()"
		words: make block! 12
		parse blk =rule=: [any [
			set word set-word! (append words either only [ word][to-word word]) |
			hash! | into =rule= | skip
		]]

		vout
		words
	]
	
	
	
	;-  
	;-----------------------------------------------------------------------
	;- DATES
	;-----------------------------------------------------------------------
	
	;--------------------
	;-    date-time()
	;--------------------
	; use this to prevent having to supply a spec all the time.
	; the /default option of date-time sets this.
	default-date-time-spec: "YYYY-MM-DD"
	;---
	date-time: func [
		""
		/with spec ; specify
		/using thedate [string! date! time!] ; specify an explicit date instead of now()
		/default ; set the default to /with spec
		/local str date-rules thetime
	][
		;vin ["date-time()"]
		
		str: copy ""
		
		
		either spec [
			if default [
				default-date-time-spec: spec
			]
		][
			spec: default-date-time-spec
		]
		
		unless thedate [
			thedate: now/precise
		]
		
		;probe thedate
		either time? thedate [
			thetime: thedate
			thedate: none
			
			
		][
			if thedate/time [
				thetime: thedate/time
				thedate/time: none
			]
		]
		
		filler: complement charset "YMDHhmspP"
		;error: spec
		itime: true
		
		
		unless parse/case spec [
			some [
				here:
				(error: here)
				; padded dates
				["YYYY" (append str thedate/year)] | 
				["YY" (append str copy/part at to-string thedate/year 3 2)] | 
				["MM" (append str zfill thedate/month 2)] |
				["DD" (append str zfill thedate/day 2)] |
				["M" (append str thedate/month)] |
				["D" (append str thedate/day)] |
				
				; padded time
				["hh" (append str zfill thetime/hour 2)] |
				["mm" (append str zfill thetime/minute 2)] |
				["ss" (append str zfill to-integer thetime/second 2)] |
				
				; am/pm indicator
				["P" (append str "#@#@#@#")] | 
				["p" (append str "-@-@-@-")] | 
				
				; american style 12hour format
				["H" (
					itime: remainder thetime/hour 12
					if 0 = itime [ itime: 12]
					append str itime
					itime: either thetime/hour >= 12 ["PM"]["AM"]
					)
				] |
				
				; non padded time
				["h" (append str thetime/hour)] |
				["m" (append str thetime/minute)] |
				["s" (append str to-integer thetime/second)] |
				["^^" copy val skip (append str val)] |
				
				[copy val some filler (append str val)]
				
			]
			(replace str "#@#@#@#" any [to-string itime ""])
			(replace str "-@-@-@-" lowercase any [to-string itime ""])
		][
			to-error rejoin [
				"date-time() DATE FORMAT ERROR: " spec newline
				"  starting at: "  error newline
				"  valid so far: " str newline
			]
		]
		;vout 
		str
	]
	

	;-  
	;-----------------------------------------------------------------------
	;- PAIRS
	;-----------------------------------------------------------------------
	;-----------------
	;-     ydiff()
	;-----------------
	ydiff: func [
		a [pair!] b [pair!]
	][
		;a/y - b/y
		second a - b ; this is twice as fast as above line
	]
	
	
	;-----------------
	;-     xdiff()
	;-----------------
	xdiff: func [
		a [pair!] b [pair!]
	][
		;a/x - b/x
		first a - b ; this is twice as fast as above line
	]
	

	
	
	
	;-  
	;-----------------------------------------------------------------------
	;- SERIES
	;-----------------------------------------------------------------------
	;-----------------
	;-     remove-duplicates()
	;
	; like unique, but in-place
	; removes items from end
	;-----------------
	remove-duplicates: func [
		series
		/local dup item
	][
		;vin [{remove-duplicates()}]
		
		until [
			item: first series
			if dup: find next series item [
				remove dup
			]
			
			tail? series: next series
		]
		
		;vout
		series
	]
	
	;-----------------
	;-     text-to-lines()
	;-----------------
	text-to-lines: func [
		str [string!]
	][
		either empty? str [
			copy ""
		][
			parse/all str "^/"
		]
	]
	
	;-----------------
	;-     shorter?/longer?/shortest/longest()
	;-----------------
	shorter?: func [a [series!] b [series!]][
		lesser? length? a length? b
	]
	
	longer?: func [a [series!] b [series!]][
		greater? length? a length? b
	]
	
	shortest: func [a [series!] b [series!]] [
		either shorter? a b  [a][b]
	]
	
	longest: func [a [series!] b [series!]] [
		either longer? a b  [a][b]
	]	
	
	
	;-----------------
	;-     shorten()
	; returns series truncated to length of shortest of both series.
	;-----------------
	shorten: func [
		a [series!] b [series!]
	][
		head either shorter? a b [
			clear at b 1 + length? a
		][
			clear at a 1 + length? b
		]
	]
	
	;-----------------
	;-     elongate()
	; returns series elongated to longest of both series.
	;-----------------
	elongate: func [
		a [series!] b [series!]
	][
		either longer? a b [
			append b copy at a 1 + length? b
		][
			append a copy at b 1 + length? a
		]
	]
		
	;-----------------
	;-     include()
	;
	; will only add an item if its not already in the series
	;-----------------
	include: func [
		series [series!]
		data
	][
		;vin [{include()}]
		unless find series data [
			append series data
		]
		;vout
	]


	
	;--------------------------
	;-     extract-tags()
	;--------------------------
	; purpose:  extracts tag-pair of data within a block.  Using /all will return all of the tags in the list.
	;
	; inputs:   a flat block  and the tag pair key to match (see tests for examples)
	; 
	; returns:  a block with both the tag and its data 
	;
	; notes:    
	;
	; tests:    [ 
	;               extract-tags 'b [ a 1  b 2  a 1 ]       returns  [b 2]
	;               extract-tags/all 'a [ a 1  b 2  a 1 ]   returns  [a 1 a 1]
	;           ]
	;--------------------------
	extract-tags: funcl [
		tag [word!]
		blk [any-block!]
		/all "return all tags, not just the first one"
	][
		vin "extract-tags()"
		
		either all [
			if result: find blk tag [
				found: result
				result: copy []
				
				until [
					append result copy/part found 2
					found: find blk tag
				]
			]
		][
			if result:  find blk tag [
				result: copy/part result 2
			]
		]
		
		vout
		result
	]
	
	

	;-----------------
	;-     find-same()
	;
	; like find but will only match the exact same series within a block.  mere equivalence is not enough.
	;
	; beware, this can be very slow for blocks, as it does a deep compare!
	;-----------------
	find-same: func [
		series [block!]
		item [series! none! ]
		/local s 
	][
		unless none? item [
			while [s: find series item] [
				if same? first s item [return  s]
				series: next s
			]
		]
		none
	]




	
	;-  
	;-----------------------------------------------------------------------
	;- BLOCK
	;-----------------------------------------------------------------------
	
	;-----------------
	;-     include-different()
	;-----------------
	include-different: func [
		blk [block!]
		data [series!]
	][
		;vin [{include-different()}]
		unless find-same blk data [
			append blk data
		]
		;vout
	]

	
	
	;-  
	;-----------------------------------------------------------------------
	;- STRING
	;-----------------------------------------------------------------------
	;--------------------
	;-    zfill()
	;--------------------
	zfill: func [
		"left fills the supplied string with zeros to amount size."
		string [string! integer! decimal!]
		length [integer!]
	][
		if integer? string [
			string: to-string string
		]
		
		if (length? string) < length [
			head insert/dup string "0" (length - length? string)
		]
		head string
	]


	;--------------------
	;-    fill()
	;--------------------
	fill: func [
		"Fills a series to a fixed length"
		data "series to fill, any non series is converted to string!"
		len [integer!] "length of resulting string"
		/with val "replace default space char"
		/right "right justify fill"
		/truncate "will truncate input data if its larger than len"
		/local buffer
	][
		unless series? data [
			data: to-string data
		]
		val: any [
			val " " ; default value
		]
		buffer: head insert/dup make type? data none val len
		either right [
			reverse data
			change buffer data
			reverse buffer
		][
			change buffer data
		]
		if truncate [
			clear next at buffer len
		]
		buffer
	]
	
	
	;-  
	;-----------------------------------------------------------------------
	;- FILES
	;-----------------------------------------------------------------------

	
	;-------------------
	;-    as-file()
	;
	; universal path fixup method, allows any combination of file! string! types written as 
	; rebol or os filepaths.
	;
	; also cleans up // path items (doesnt fix /// though).
	;
	; NOTE: this function cannot support url-encoded strings, since there
	;   is a bug in path notation which doesn't properly convert string! to/from path!.
	; 
	;   for example the space (%20), when it is the first character of the string, will stick as "%20" 
	;   (and become impossible to decipher when probing the path)
	;   instead of becoming a space character.
	; 
	;   so we take for granted that the '%' prefix, is a path prefix and simply remove it.
	;-----
	as-file: func  [
		path [string! file!]
	][
		to-rebol-file replace/all any [
			all [
				path/1 = #"%"
				next path
			]
			path
		] "//" "/"
	]
	
	
	
	;-   
	;-----------------------------------------------------------------------
	;- MATH
	;-----------------------------------------------------------------------
	;-----------------
	;-     atan2()
	;-----------------
	atan2: func [
		v [pair!]
	][
		any [
			all [v/y > 0  v/x > 0  arctangent v/y / v/x]
			all [v/y >= 0 v/x < 0 180 + arctangent v/y / v/x]
			all [v/y < 0  v/x < 0 180 + arctangent v/y / v/x]
			all [v/y >  0 v/x = 0 90 ]
			all [v/y <  0 v/x = 0 270]
			all [v/y < 0  v/x >= 0 360 + arctangent v/y / v/x]
			0
		]
	]
	
	;-----------------
	;-     hypothenuse()
	;-----------------
	hypothenuse: func [
		width
		height
	][
		square-root (width * width) + (height * height)
	]
	
	
	
	

	
	
]
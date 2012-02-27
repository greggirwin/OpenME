Rebol [
    Title: "Include"
    File: %include.r
    Date: 15-May-2007/8:39:27+2:00
    Author: "Ladislav Mecir"
    Purpose: {
        A module manager.
		See http://www.fm.tul.cz/~ladislav/rebol/include.html
        
        INCLUDE CAN:
        
        - do scripts
        
        	- no special properties required, any Rebol script can be included
        	- INCLUDE-PATH is used to search for the files
		        - include-path can contain directories or URL's
        	- INCLUDE/CHECK can be used to prevent multiple include of a script
        	- scripts may contain preprocessing instructions:
				#include
				#include-check ; include if not included before
				#do
				#either
				#if
				#include-string
				#include-binary
				#include-files
			- official Rebol preprocessor compatible
			
        - build scripts using INCLUDE/LINK
        
        	- using the preprocessing instructions as above
        	- it is possible to include smaller parts than scripts, e.g.:
        		- binary data
        		- images
        		- strings
        	- context encapsulation available:
        	    make object! [#include %somefile.r]
    }
]

comment [
    ; Usage
    
    ; to find and do a file %myfile.r:
    include %myfile.r
    
    ; to append a URL or a directory to the search path:
    append include-path url-or-directory
    
    ; to find out, how the include-path looks:
    print include-path
    
    ; if you want to start using a totally new include-path:
    include-path: [%/my-search-dir/ %/etc/ http://www.myserv.dom/]
    
    ; to include %somefile.r if not included before:
    include/check %somefile.r
    
    ; to obtain a linked file:
    include/link %somefile.r %outfile.r

	; to obtain a Rebol block:
	include/only %somefile.r    
]
	
unless value? 'include [

	make object! [
	
		split-path: function [
		    {
		        Splits a file or URL. Returns a block containing path and target.
		        
		        Overcomes some limitations of the Rebol/Core 2.2 split-path,
		        like strange results for:
		
		            split-path %file.r
		            split-path %""
		
		        The following equality holds:
		
		            file = append first split-path file second split-path file
		
		    }
		    file [file! url!]
		] [target] [
		    target: tail file
		    if (pick target -1) = #"/" [target: back target]
		    target: find/reverse target #"/"
		    target: either target [next target] [file]
		    reduce [copy/part file target to file! target]
		]
	
	    findpfile: function [
	    	{Find a file using the given search path}
	        path [block!]
	        file [file! url!]
	    ] [dir found] [
	        while [not empty? path] [
	            if exists? found: append dirize copy dir: first :path :file [
					return found
				]
	            path: next :path
	        ]
	        throw make error! reform ["Include error: file" file "not found"]
	    ]
	    
	    find-file: func [
	    	{Find a file using an appropriate search path}
			file [file! url!]
			/local dir target
		] [
	        set [dir target] split-path file
	    	findpfile either empty? :dir [include-path] [reduce [:dir]] target
	    ]	
	
	    ; include-path is initialized to contain the %. directory
	    ; and the directory, where the %include.r was run from
	    
	    set 'include-path reduce [%. system/script/path]
	
	    ; to prevent multiple includes
	    included-files: []
	    
	    set 'include func [
	        {A module manager}
	        [catch]
	        file [file! url!]
	        /check {include the script only if it hasn't been included before}
	        /link {create a linked file}
	        output [file!]
	        /only {create a Rebol block}
	        /local included include-script include-block tme
		] [				
			tme: func [msg [string!] near [block!]] [
				throw make error! rejoin [
					msg newline
					"in file:" file newline
					"near:" copy/part mold/only/all near 40
				]
			]
			
		    include-block: func [
		    	linked [block! paren!]
		    	block [block! paren!]
		    	/local value value2 value3
		    ] [
		    	parse block [
		    		any [
			    		set value [block! | paren!] (
			    			insert/only tail linked include-block make value 0 value
			    		) | #include-check block: (
			    			set/any [value value2] do/next block
			    			any [
			    				file? get/any 'value
			    				url? get/any 'value
			    				tme "#include expected file or URL" block
							]
			    			include-script linked value true true
			    		) :value2 | #include block: (
			    			set/any [value value2] do/next block
			    			any [
			    				file? get/any 'value
			    				url? get/any 'value
			    				tme "#include expected file or URL" block
							]
			    			include-script linked value none
			    		) :value2 | #do set value [
							block! |
							(tme "#do expected a block" block)
						] (insert tail linked do value) | #if set value [
							block! |
		    				(tme "#if expected a condition block" block)
		    			] set value2 [
		    				block! |
		    				(tme "#if expected a then-block" block)
		    			] (
							any [
								not unset? set/any 'value do value
								tme "#if condition must not yield unset!" block
							]
							any [not :value include-block linked value2]
						) | #either set value [
							block! |
							(tme "#either expected a condition block" block)
						] set value2 [
							block! |
							(tme "#either expected a then-block" block)
						] set value3 [
							block! |
							(tme "#either expected an else-block" block)
						] (
							any [
								not unset? set/any 'value do value
								tme "#either condition must not yield unset!" block
							]
							include-block linked either :value [value2] [value3]
						) | #include-string block: (
			    			set/any [value value2] do/next block
			    			any [
			    				file? get/any 'value
			    				url? get/any 'value
			    				tme "#include-string expected a file or URL" block
			    			]
			    			insert tail linked read find-file value
			    		) :value2 | #include-binary block: (
			    			set/any [value value2] do/next block
			    			any [
			    				file? get/any 'value
			    				url? get/any 'value
			    				tme "#include-binary expected a file or URL" block
			    			]
			    			insert tail linked read/binary find-file value
			    		) :value2 | #include-files set value [
			    			path! |
			    			(tme "#include-files expected a path" block)
			    		] set value2 [
			    			block! |
			    			(tme "#include-files expected a path and a block" block)
			    		] (
			    			value3: make block! length? value2
			    			foreach file value2 [
			    				insert tail value3 file
								insert tail value3 read/binary value/:file
							]
			    			insert/only tail linked value3
			    		) | set value skip (
							insert/only tail linked get/any 'value
						)
					]
		    	]
		    	linked
		    ]
	
		    include-script: func [
		    	{Include a script file}
		    	linked [block!]
				file [file! url!]
		    	check [none! logic!]
				/header
		    	link [none! logic!]
				/local included? result binary-base found target dir
			] [
	            set [dir target] split-path file
	            ; prevent multiple includes
	            unless all [included?: find/only :included :target check] [
	            	found: find-file file
	                unless included? [insert tail :included :target]
	                set [result target] split-path found
	                ; remember the current dir before change
	                dir: system/script/path
	                if error? found: try [
						load/all either file? result [
							change-dir result
							target
						] [found]
					] [
						throw make error! reform [
							"Load error, file" file mold disarm found
						]
					]
	                if header [
		                unless parse found ['rebol block! to end] [
		                	throw make error! reform [
								"Include error, file" file "missing a header"
							]
		                ]
						either link [insert tail linked copy/part found 2] [
							system/script/header: make object! found/2
						]
					]
					if found/1 = 'rebol [found: skip found 2]
	                include-block linked found
	                result: linked
	                if all [header not link not only] [
						set/any 'result do linked
					]
					; return to the "original" dir
					system/script/path: dir
	                ; finish the job
	                if all [header link] [
			        	binary-base: system/options/binary-base
			        	system/options/binary-base: 64
						write output mold/only/all linked
						system/options/binary-base: binary-base
					]
					get/any 'result
	            ]
			]
	
	        included: either any [only link] [copy []] [included-files]
	        include-script/header copy [] file check link
	    ]	    
	]
]

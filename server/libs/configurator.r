rebol [
	; -- basic rebol header --
	title: "config manager"
	version: 1.0.1
	date: 2012-02-27
	
	copyright: "© 2008-2012, Maxim Olivier-Adlhoch"
	authors: [
		MOA "Maxim Olivier-Adlhoch" ; refactorisation into slim and some fixes
	]
	
	;-- Slim requirements --
	slim-name: 'configurator
	slim-version: 1.0.1
	slim-prefix: none
	
	;-- Licensing details --
	license-type: 'MIT
	license:      {Copyright © 2008-2012 Maxim Olivier-Adlhoch.

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
		FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
		ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
		THE SOFTWARE.}

	history: {
		0.1.0 - 2008-09-11 - MOA
			-created
			-basic set(), get(), apply() methods
			-added space-filled
			-clone(), copy()
			-added protection
			-probe()
			-added concealment
			-added docs
			-help()
			-specific version adapted to QuickShot...
		
		a few version go by... many features added
		
		v1.0.0 - 2012-02-17 - MOA
			-added the configure stub  which takes a spec and returns a !config object.
			
		v1.0.1 - 2012-02-27 - MOA
			-added /required to from-disk() function
			-wrapped from-disk within a try block and added /ignore-failed to suppress errors if we don't really care if the file is valid.
			-added a default storage-path value.
	}
	

]

slim/register [
	;print "... DISTRO CONFIGURATOR LOADED"
	utils: slim/open 'utils none
	
	*copy: get in system/words 'copy
	*mold: get in system/words 'mold
	*get: get in system/words 'get
	*probe: get in system/words 'probe
	
	whitespace: charset "^/^- "

	;- !CONFIG []
	; note that tags surrounded by '--' (--tag--) aren't meant to be substituted within the apply command.
	!config: context [
		!config?: true 
	
		;- INTERNALS
		
		;-    store-path:
		; we now specify a default file just to make it uber easy for those who don't care
		; (this is useful when evaluation for example)
		store-path: %app-setup.cfg

		
		;-    app-label:
		; use this in output related strings like when storing to disk
		app-label: none
		
		
		
		;-------------------------------
		;-    -- object-based internals
		;-------------------------------
		
		;-    tags:
		; a context of values 
		tags: none
		
		
		;-    save-point:
		; a save point of tags which can be restored later
		; NOTE: saves only the tags (on purpose).
		save-point: none
		
		
		;-    dynamic:
		; this is a list of tags which are only use when apply is called, they are in fact driven
		; by a function, cannot be set, but can be get.  are not part of any other aspect of configurator
		; like disk, copy, backup, etc.
		;
		; clone will duplicate the dynamic tags to the new !config
		dynamic: none
		
		
		
		;-    defaults:
		; a save point which can only every be set once, includes concealed tags.
		; use snapshot-defaults() to set defaults.
		; use reset() to go back to these values
		;
		; NOTE: saves only the tags (on purpose).
		defaults: none
		
		;-    docs:
		; any tags in this list can be called upon for documentation
		;
		; various functions may include these help strings (mold, probe, etc)
		docs: none
		
		;-    types:
		; some tags might require to be bound to specific datatypes.
		; this is useful for storage and reloading... enforcing integrity of disk-loaded configs.
		;
		; <TO DO> still work in progress.
		types: none
		
		
		;-------------------------------
		;-    -- block-based internals
		;-    protected:
		; tags which cannot be overidden.
		protected: none
		
		
		;-    concealed:
		; tags which aren't probed, saved or loaded
		concealed: none
		
		
		
		;-    space-filled:
		; tags which cannot *EVER* contain whitespaces.
		space-filled: none
		
		
		
		;-  
		;- METHODS
		
		;-----------------
		;-    protect()
		;-----------------
		protect: func [
			tags [word! block!]
			/local tag
		][
			vin [{!config/protect()}]
			
			tags: compose [(tags)]
			foreach tag tags [
				vprint join "protecting: " tag
				; only append if its not already there
				any [
					find protected tag
					append protected tag
				]
			]
			tags: tag: none
			vout
		]
		
		
		;-----------------
		;-    protected?()
		;-----------------
		protected?: func [
			tag [word!]
		][
			vin [{!config/protected?()}]
			vprobe tag
			vout/return
			vprobe found? find protected tag
		]
		
		
		;-----------------
		;-    conceal()
		;-----------------
		conceal: func [
			tags [word! block!]
			/local tag
		][
			vin [{!config/conceal()}]
			
			tags: compose [(tags)]
			foreach tag tags [
				vprint rejoin ["concealing: " tag]
				; only append if its not already there
				any [
					find concealed tag
					append concealed tag
				]
			]
			tags: tag: none
			vout
		]
		
		
		;-----------------
		;-    concealed?()
		;-----------------
		concealed?: func [
			tag [word!]
		][
			vin [{!config/concealed?()}]
			vprobe tag
			vout/return
			vprobe found? find self/concealed tag
		]
		
		
		;-----------------
		;-    cast()
		;-----------------
		; force !config to fit tags within specific datatype
		;-----------------
		cast: func [
			tag [word!]
			type [word! block!] "note these are pseudo types, starting with the ! (ex !state) not actual datatype! "
		][
			vin [{!config/cast()}]
			unless set? tag [
				to-error rejoin ["!config/cast(): tag '" tag " doesn't exist in config, cannot cast it to a datatype"]
			]
			type: compose [(type)]
			types: make types reduce [to-lit-word tag type]
			vout
		]
		
		
		
		;-----------------
		;-    typed?()
		;-----------------
		; is this tag currently type cast?
		;-----------------
		typed?: func [
			tag [word!]
		][
			vin [{!config/typed?()}]
			found? in types tag
			vout
		]
		
		
		;-----------------
		;-    proper-type?()
		;-----------------
		; if tag currently typed?, verify it.  Otherwise return true.
		;-----------------
		proper-type?: func [
			tag [word!]
			/value val
		][
			vin [{!config/proper-type?()}]
			val: either value [val][get tag]
			any [
				all [typed? tag find types type?/word val ]
				true
			]
			vout
		]
		
		
		
		
		;-----------------
		;-    fill-spaces()
		;-----------------
		; prevent this tag from ever containing any whitespaces.
		;-----------------
		fill-spaces: func [
			tag [word!]
		][
			vin [{!config/fill-spaces()}]
			unless find space-filled tag [
				append space-filled tag
				; its possible to call this before even adding tag to config
				if set? tag [
					set tag tags/:tag ; this will enfore fill-space right now
				]
			]
			vout
		]
		
		;-----------------
		;-    space-filled?()
		;-----------------
		space-filled?: func [
			tag [word!]
		][
			vin [{!config/space-filled?()}]
			vprint tag
			vprobe tag: found? find space-filled tag
			vout
			tag
		]
		
		
		
		;-----------------
		;-    set()
		;
		; set a tag value, add the tag if its not yet there.
		;
		; ignored if the tag is protected.
		;-----------------
		set: func [
			tag [word!]
			value
			/type types [word! block!] "immediately cast the tag to some type"
			/doc docstr [string!] "immediately set the help for this tag"
			/overide "ignores protection, only for use within distrobot... code using the !config should not have acces to this."
			/conceal "immediately call conceal on the tag"
			/protect "immediately call protect on the tag"
			/local here
		][
			vin [{!config/set()}]
			vprobe tag
			
			
			either all [not overide protected? tag] [
				; <TODO> REPORT ERROR
				vprint/error rejoin ["CANNOT SET CONFIG: <" tag "> IS protected"]
			][
				either function? :value [
					; this is a dynamic tag, its evaluated, not stored.
					dynamic: make dynamic reduce [to-set-word tag none ]
					dynamic/:tag: :value
				][
					any [
						in tags tag
						;tags: make tags reduce [load rejoin ["[ " tag ": none ]"]
						tags: make tags reduce [to-set-word tag none ]
					]
					if space-filled? tag [
						value: to-string value
						parse/all value [any [ [here: whitespace ( change here "-")] | skip ] ]
					]
					
					;v?? tags
					tags/:tag: :value
				]
			]
			if conceal [
				self/conceal tag
			]
			
			if protect [
				self/protect tag
			]
			
			if doc [
				document tag docstr
			]
			
			if type [
				cast tag types
			]
			
			vout
			value
		]
		
		
		;-----------------
		;-    set?()
		;-----------------
		set?: func [
			tag [word!]
		][
			vin [{!config/set?()}]
			vprobe tag
			vout
			found? in tags tag
		]
		
		
		;-----------------
		;-    document()
		;-----------------
		document: func [
			tag [word!]
			doc [string!]
		][
			vin [{!config/document()}]
			vprobe tag
			unless set? tag [
				to-error rejoin ["!config/document(): tag '" tag " doesn't exist in config, cannot set its document string"]
			]
			docs: make docs reduce [to-set-word tag doc]
			vout
		]
		
		
		;-----------------
		;-    help()
		;-----------------
		help: func [
			tag [word!]
		][
			vin [{!config/help()}]
			vprobe tag
			vout
			*get in docs tag
		]
		
		
		
		
		;-----------------
		;-    get()
		;-----------------
		get: func [
			tag [word!]
		][
			vin [{!config/get()}]
			vprobe tag
			vout
			either (in dynamic tag) [
				dynamic/:tag
			][
				*get in tags tag
			]
		]
		
		
		
		
		;-----------------
		;-    apply()
		;
		; given a source string, will replace all tags which match some config items with their config values
		; so given: "bla <tag> bla"  and a config named tag with value "poo" will become "bla poo bla"
		;
		; <TODO> make function recursive
		;-----------------
		apply: func [
			data [string! file! word!] ; eventually support other types?
			/only this [word! block!] "only apply one or a set of specific configs"
			/reduce "Applies config to some config item"
			/file "corrects applied data so that file paths are corrected"
			/local tag lbl tmp
		][
			vin [{!config/apply()}]

			; loads the tag, if reduce is specified, or uses the data directly
			data: any [all [reduce tags/:data] data]
			
			v?? data
			
			this: any [
				all [
					only 
					compose [(this)]
				]
				self/list/dynamic
			]
			
			foreach tag this [
				lbl: to-string tag
				; don't apply the tag to itself, if reduce is used!
				unless all [reduce tag = data][
					; skip internal configs
					unless all [lbl/1 = #"-" lbl/2 = #"-"] [
						tmp: get tag
						;print "#####"
						;?? tmp
						;print ""
						replace/all data rejoin ["<" lbl ">"] to-string tmp
					]
				]
			]
			vout
			if file [
				tmp: utils/as-file *copy data
				clear head data
				append data tmp
			]
			data
		]
		
		
		;-----------------
		;-    copy()
		;-----------------
		; create or resets a tag out of another
		;-----------------
		copy: func [
			from [word!]
			to [word!]
		][
			vin [{!config/copy()}]
			set to get from
			vout
		]
		
		
		;-----------------
		;-    as-file()
		;-----------------
		; convert a tag to a rebol file! type
		;
		; OS or rebol type paths, as well as string or file are valid as current tag data.
		;-----------------
		as-file: func [
			tag [word!]
			/local value
		][
			vin [{as-file()}]
			set tag value: utils/as-file get tag
			vout
			value
		]
		
		
		
		
		;-----------------
		;-    clone()
		;-----------------
		; take a !config and create a deep copy of it
		;-----------------
		clone: func [][
			vin [{!config/clone()}]
			vout
			make self [
				tags: make tags []
				types: make types []
				docs: make docs []
				dynamic: make dynamic []
				
				if defaults [
					defaults: make defaults []
				]
				
				if save-point [
					save-point: make save-point []
				]
				
				; series copying is intrinsic to make object. 
				;----
				; protected:
				; concealed:
				; space-filled:

			]
		]
		
		
		;--------------------------
		;-         import()
		;--------------------------
		; purpose:  takes a given config and calls set for each of its tags.
		;
		; inputs:   
		;
		; returns:  
		;
		; notes:    - <TO DO> support advanced capabilities like concealed, types and such.
		;           - we currently only merge the visible, unprotected and non-dynamic tags.
		;
		; tests:    
		;--------------------------
		import: funcl [
			cfg
		][
			vin "import()"
			foreach tag cfg/list-tags [
				set tag cfg/get tag
			]
			vout
		]
		
		
		
		;-----------------
		;-    backup()
		;-----------------
		; puts a copy of current tags info in store-point.
		;-----------------
		backup: func [
		][
			vin [{!config/backup()}]
			save-point: make tags []
			vout
		]
		
		
		
		;-----------------
		;-    restore()
		;-----------------
		; restore the tags to an earlier or default state 
		;
		; not
		;
		; NB: -the tags are copied from the reference state... the tags object
		;      itself is NOT replaced.
		;     -if a ref-tags is used and it has new unknown tags, they are ignored
		;
		; WARNING: when called, we LOOSE current tags data
		;
		; <TODO>: enforce types?.  In the meanwhile, we silently use the ref-tags directly.
		;-----------------
		restore: func [
			/visible "do not restore concealed values."
			/safe "do not restore protected values."
			/reset "restore to defaults instead of save-point,  WARNING!!: also clears save-point."
			/using ref-tags [object!] "Manually supply a set of tags to use... mutually exclusive to /reset, this one has more strength."
			/create "new tags should be created from ref-tags."
			/keep-unrefered "Any tags which are missing in ref-tags, default or save point are not cleared."
			/local tag tag-list val ref-words
		][
			vin [{!config/restore()}]
			
			tag-list: list/opt reduce [either visible ['visible][] either safe ['safe][]]
			v?? tag-list
			ref-tags: any[
				ref-tags
				either reset [
					save-point: none
					self/defaults
				][
					save-point
				]
			]
			vprint "restoring to:"
			vprobe ref-tags
			if ref-tags [
				foreach tag any [
					all [create next first ref-tags]
					tag-list
				][
					if any [
						not keep-unrefered
						in ref-tags tag
						create
					][
						set/overide tag *get (in ref-tags tag)
					]
				]
			]
			vout
		]
		
		
		
		
		;-----------------
		;-    delete()
		; remote a tag from configs
		;-----------------
		; <TODO> also remove from other internals: protected, concealed, etc.
		; <TODO> later features might needed to be better reflected in this function
		;-----------------
		delete: func [
			tag [word!]
			/local spec
		][
			vin [{!config/delete()}]
			spec: third tags
			
			if spec: find spec to-set-word tag [
				remove/part  spec 2
				tags: context head spec
			]
			vout
		]
		
		
		;-----------------
		;-    probe()
		;-----------------
		; print a status of the config in console...usefull for debugging
		;-----------------
		probe: func [
			/unsorted
			/full "include document strings in probe"
			/local pt tag v
		][
			vin [{!config/probe()}]
			v: verbose
			verbose: no
			foreach tag any [all [unsorted next first tags] sort next first tags] [
				unless concealed? tag [ 
					either full [
						vprint/always         "+-----------------" 
						vprint/always rejoin ["| " tag ":"]
						vprint/always         "|"
						vprint/always rejoin ["|     " head replace/all any [help tag ""]  "^/" "^/|     "]
						vprint/always         "|"
						vprint/always rejoin ["|     "  *copy/part  replace/all replace/all *mold/all tags/:tag "^/" " " "^-" " " 80]
						vprint/always         "+-----------------" 
					][
						vprint/always rejoin [ utils/fill/with to-string tag 22 "_" ": " *copy/part  replace/all replace/all *mold/all tags/:tag "^/" " " "^-" " " 80]
					]
				]
				;vprint ""
			]
			pt: form protected
			either empty? pt [
				vprint/always ["+------------------" utils/fill/with "" (1 + (length? pt)) "-" "+"]
				vprint/always ["| No Protected tags |"]
				vprint/always ["+------------------" utils/fill/with "" (1 + (length? pt)) "-" "+"]
			][
				vprint/always ["+-----------------" utils/fill/with "" (1 + (length? pt)) "-" "+"]
				vprint/always ["| Protected tags: " pt " |"]
				vprint/always ["+-----------------" utils/fill/with "" (1 + (length? pt)) "-" "+"]
			]
			verbose: v
			vout
		]
		
		
		;-----------------
		;-    list()
		;-----------------
		; list tags reflecting options.
		;
		; <DEPRECATED> The interface of list is meant to be used internally and the refinements are the opposite 
		;              of what they mean, so the use of this function is highly ambiguous in code.
		;
		;              until it is completely refurbished and its new incarnation applied in the code,
		;              we should use the  list-tags function instead.
		;-----------------
		list: func [
			/opt options "supply folowing args using block of options"
			/safe "don't list protected"
			/visible "don't list concealed"
			/dynamic "Also list dynamic"
			/local ignore list
		][
			vin [{!config/list()}]
			
			ignore: clear [] ; reuse the same block everytime.
			
			
			options: any [options []]
			
			if any [
				visible
				find options 'visible
			][
				append ignore concealed
			]
			
			if any [
				safe
				find options 'safe
			][
				append ignore protected
			]
			list: words-of tags
			if dynamic [
				append list next first self/dynamic
			]
			vout
			exclude sort list ignore
		]
		
		
		;-----------------
		;-    list-tags()
		;-----------------
		; list tags reflecting options.
		;-----------------
		list-tags: funcl [
			/opt options "supply folowing args using block of options"
			/protected "Also list protected tags"
			/concealed "don't list concealed"
			/dynamic "Also list dynamic"
			;/local ignore list
		][
			vin [{!config/list-tags()}]
			
			ignore: clear [] ; reuse the same block everytime.
			
			
			options: any [options []]
			
			if any [
				not protected
				not find options 'protected
			][
				append ignore self/protected
			]
			
			if any [
				concealed
				not find options 'concealed
			][
				append ignore self/concealed
			]
			list: words-of tags
			if dynamic [
				append list words-of self/dynamic
			]
			vout
			exclude sort list ignore
			
			
		]
		
		
		;-----------------
		;-    mold()
		;-----------------
		; coverts the tags to a reloadable string, excluding any kind of evaluatable code.
		;
		; concealed tags are not part of mold
		;
		; <TODO> make invalid-type recursive in blocks and when /relax is set
		;-----------------
		mold: func [
			/relax "allow dangerous types in mold"
			/using mold-method [function!] "special mold method, we give [tag data] pair to hook, and save out returned data or ignore tag if none is returned"
			/local tag invalid-types val output
		][
			vin [{!config/mold()}]
			output: *copy ""
			invalid-types: any [
				all [relax []]
				[function! object!]
			]
			
			; we don't accumulate concealed tags
			foreach tag list/visible [
				val: get tag
				append output either using [
					vprobe tag
					vprobe mold-method tag val
				][
					
					if find invalid-types type?/word val [
						to-error "!config/mold(): Dangerous datatype not allowed in mold, use /relax if needed"
					]
					rejoin [
						";-----------------------^/"
						"; " head replace/all any [help tag ""]  "^/" "^/; "
						"^/;-----------------------^/"
						tag ": " *mold/all val "^/"
						"^/^/"
					]
				]
			]
			vout
			output
		]
		
		
		
		
		;-----------------
		;-    to-disk()
		;-----------------
		
		to-disk: func [
			/to path [file!]
			/relax
			/only hook [function!] "only same out some of the data, will apply mold-hook, relax MUST also be specified"
			/local tag
		][
			vin [{!config/to-disk()}]
			either path: any [
				path
				store-path
			][
				
				app-label: any [app-label ""]
				
				data: trim rejoin [
					";---------------------------------" newline
					"; " app-label " configuration file" newline
					"; saved: " now/date newline
					"; version: " system/script/header/version newline
					";---------------------------------" newline
					newline
					any [
						all [only relax mold/relax/using :hook]
						all [relax mold/relax]
						mold
					]
				]
					
				
				;vprobe/always data
				
				;v?? path
				
				write path data
			][
				to-error "!CONFIGURATOR/to-disk(): STORE-PATH not set"
			
			]
			vout
		]
		
		
		
		
		;-----------------
		;-    from-disk()
		;-----------------
		; note: any missing tags in disk prefs are filled-in with current values.
		;-----------------
		from-disk: func [
			/using path [file!]
			/create "Create tags comming from disk, dangerous, but useful when config is used as controlled storage."
			/required "Disk file is required, generate an error when it doesn't"
			/ignore-failed "If disk file wasn't readable, just ignore it without raising errors."
			/local err data
		][
			vin [{!config/from-disk()}]
			
			either path: any [
				path
				store-path
			][
				; silently ignore missing file
				either exists? path [
					either error? err: try [
						data: construct load path
					][
						;----
						; loading failed
						err: disarm err
						unless ignore-failed [
							print err: rejoin ["------------------------^/" app-label " Error!^/------------------------^/Configuration file isn't loadable (syntax error): " to-local-file clean-path path "^/" err]
							to-error "CONFIGURATOR/from-disk()"
						]
					][
						;----
						; loading succeeded
						either create [
							restore/using/keep-unrefered/create data
						][
							restore/using/keep-unrefered data
						]
					]
				][
					if required [
						to-error rejoin [ "CONFIGURATOR/from-disk(): required configuration file doesn't exist:" to-local-file path]
					]
				]
			][
				to-error "CONFIGURATOR/from-disk(): STORE-PATH not set"
			]
			
			; remember filename
			if using [
				store-path: path
			]
			
			vout
		]
		
		
		;-----------------
		;-    snapshot-defaults()
		;-----------------
		; captures current tags as the defaults.  
		; by default can only be called once.
		;
		; NB: series are NOT shared between tags... so you must NOT rely on config to be the 
		;     exact same? serie, but only an identical one (same value, but different reference).
		;-----------------
		snapshot-defaults: func [
			/overide "allows you to overide defaults if there are any... an unusual procedure"
		][
			vin [{snapshot-defaults()}]
			if any [
				overide
				none? defaults
			][
				defaults: make tags []
			]
			vout
		]
		
		
		;-----------------
		;-    init()
		;-----------------
		init: func [
		][
			vin [{!config/init()}]
			tags: context []
			save-point: none
			defaults: none
			types: context []
			docs: context []
			concealed: *copy []
			protected: *copy []
			space-filled: *copy []
			dynamic: context []
			vout
		]
		
	]
	
	
	;-------------------------------------------------------------------------------------------------------------------------
	;
	;- API
	;
	;-------------------------------------------------------------------------------------------------------------------------
	
	;--------------------------
	;-    configure()
	;--------------------------
	; purpose:  create a !config item from scratch using a simple spec, similar to objects
	;
	; inputs:   a block or none!, if you want an empty config.
	;
	; returns:  the new config.
	;
	; notes:    -raises an error if the spec is invalid.
	;           -automatically causes a snapshot-default before returning it.
	;
	; tests:    [   
	;               configure [version: 0.0.0 "current version"    date: 2012-02-20  "last changes"    private: #HHGEJJ29R88S   ]   ; note last item (private) isn't documented
	;           ]
	;--------------------------
	configure: funcl [
		spec [block! none!]
		/no-snapshot
	][
		vin "configure()"
		cfg: make !config []
		
		cfg/init
		
		item: none
		doc: none
		value: none
		
		if all [
			spec
			not empty? spec
		][
			reduce spec
			
			parse spec [
				some [
					here:
					;(print "==============================")
					;(probe copy/part here 3) 
					[
						set item set-word! 
						set value skip
						set doc opt string! 
						(
							item: to-word item
							cfg/set item value
							if doc [
								cfg/document item doc
							]
						)
					] 
				]
					
				| [
					(to-error probe {CONFIGURATOR.R/configure() invalid spec... ^/must be a flat block of  [word: value  "documentation" ...]^/    documentation is optional.})
					to end
				]
			]
			unless no-snapshot [
				cfg/snapshot-defaults
			]
		]
		
		vout
		cfg
	]
	

]
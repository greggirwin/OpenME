rebol [
	; -- basic rebol header --
	title: "Generic Database connection and query wrapping functions.  Replace to support other databases or storage engines."
	version: 1.0.0
	date: 2012-02-24
	
	copyright: "© 2012, Maxim Olivier-Adlhoch"
	authors: [
		MOA "Maxim Olivier-Adlhoch" ; design and coding of this (relatively) generic DB interface for the OpenME chat server.
		GC "Graham Chiu"            ; wrote the parts of the software which this file replaces (and reuses to some extent)
	]
	

	;-- Slim requirements --
	slim-name: 'OpenME-db
	slim-version: 1.0.1
	slim-prefix: none

	;-- Licensing details --
	license-type: 'MIT
	license:      {Copyright © 2012 Maxim Olivier-Adlhoch.

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


	notes: "This is an ODBC implementation of the OpenME server DB library. (Default)"

	documentation: {
		ALL functions which begin with   DB-   are meant to be generic and exposed in the OpenME
		server.  other functions are private and are not used by OpenME.
		
		Note that the use of DB- as a prefix is temporary and will be replaced at some point.
		it just makes it easy to identify data & storage related functions in the code, for now.
		
		When a DB function is irrelevent in your implementation, just return a value which is 
		consistent across your implementation which won't cause the server to fail on bootup or setup.
		
		This library expects a global variable to be already setup called 'CONFIG. it will 
		expect a minimal set of configuations which will allow it to determine if this is the
		first ever run of this application.
	}
]

slim/register [
	;----------------------------------------------------------------------------------------------
	;
	;- GLOBAL VALUES
	;
	;----------------------------------------------------------------------------------------------
	DB-CFG: none
	DB-URL: none 
	DB-PORT: none
	DBASE: none
	DB-ERR: none ; when the database generates an error, its disarmed or generated error is stored here.
	
	
	
	
	;----------------------------------------------------------------------------------------------
	;
	;- LOAD Resources
	;
	;----------------------------------------------------------------------------------------------
	;-     images
	odbc.png:    load %images/odbc.png
	running.jpg: load %images/running.jpg
	select.jpg:  load %images/select.jpg
	driver.jpg:  load %images/driver.jpg
	admin.jpg:   load %images/admin.jpg
	
	

	;----------------------------------------------------------------------------------------------
	;
	;- FUNCTIONS ( LOW-LEVEL  )
	;
	;----------------------------------------------------------------------------------------------
	
	
	;--------------------------
	;-     db-connect()
	;--------------------------
	; purpose:  using the current config, try to connect to it immediately.
	;
	; returns:  the port on success, none on failure
	;
	; notes:    doesn't cause any errors, they are trapped and silenced.
	;--------------------------
	db-connect: func [
		/with spec
	][
		vin "db-connect()"
		db-stop
		
		spec: any [ spec DB-CFG/get 'db-url ]
		
		; just make sure we are configured before connection
		;unless db-configured? [
		;	vprint "ERROR: OpenME server ODCB connection is not configured, cannot connect."
		;	return none
		;]
		
		spec: attempt [
			DBASE: open spec
			DB-PORT: first DBASE
		]	
		
		vout
		
		spec
	]
	
	
	
	;--------------------------
	;-     db-connected?()
	;--------------------------
	; purpose:  detect if we currently have a connection to the database.
	;
	; inputs:   nothing
	;
	; returns:  true/false
	;
	; notes:    if we do have a port, we do a simple query, just to see if it works.
	;--------------------------
	db-connected?: funcl [][
		vin "db-connected?()"
		success?: all [
			DBASE
			DB-PORT
		] 
		vout
		success?
	]
	
	
	
	;--------------------------
	;-     db-stop()
	;
	; purpose:  low-level db connection close with error protection.
	;
	; returns:  true when it closed the port without error, false otherwise.
	;--------------------------
	db-stop: does [
		vin "db-stop()"
		val: true? attempt [
			close DB-PORT
			close DBASE
			true
		]
		vout
		val
	]
	
	

	
	
	
	
	;--------------------------
	;-     db-get()
	;--------------------------
	; purpose:  low-level db-query which expects a return value and returns it directly.
	;
	; inputs:   query which returns data (SELECT)
	;
	; returns:  query results as a block!  or none! when an error occured!  
	;
	; notes:    usually, we would use a higher level db function within the server, abstracted
	;           so we do not rely on a specific storage model like SQL.
	;
	;           for now, it is being used directly by OpenME server since this is just the first
	;           refactoring.
	;
	; tests:    [ probe db-get {SELECT * FROM table}
	;--------------------------
	db-get: funcl [
		query [string! block!]
	][
		vin "db-get()"
		result: none ; make sure the result isn't return the static value of the previous call.
		
		if db-do query [
			; protect against using db-get on queries which return no data.
			result: attempt [
				copy DB-PORT
			]
		]
		vout
		result
	]
	
	
	
	
	;--------------------------
	;-     db-do()
	;--------------------------
	; purpose:  The most basic "Send a query to the server" function
	;
	; inputs:   The query.
	;
	; returns:  true if the query DID NOT cause an error, false on error.
	;
	; notes:    This doesn't return db data from a select.  use db-get() for this.
	;
	; tests:    if db-do "select * from table" [ print "select was successful" ]
	;--------------------------
	db-do: funcl [
		query [string! block!]
		/extern DB-ERR
	][
		vin "db-do()"
		if block? query [
			new-line/all query true
		]
		vprobe query
		
		error: if error? error: try [
			insert DB-PORT query
			
			; no error to report
			false
		][
			; store the error for future reference (if required)
			error: mold disarm error
			DB-ERR: error
			
			vprint error
			
			; an error occured
			true
		]
		
		vout
		not error
	]
	
	
	
	;--------------------------
	;-     db-error?()
	;--------------------------
	; purpose:  returns the DB-ERR value, allowing us to bind the value in other modules and the main source.
	;
	; returns:  Error string or none!  (can be used as a truthy value )
	;
	; notes:    Multiple calls to this func with return the same error. 
	;           If you recover from the error, you must call db-reset-error() in your recovery.
	;
	; tests:    if err: db-error? [ print err ]
	;--------------------------
	db-error?: funcl [
	][
		DB-ERR
	]
	
	
	
	;--------------------------
	;-     db-reset-error()
	;--------------------------
	; purpose:  clear the error so you can start using the error as a truthy value for error detection.
	;
	; returns:  nothing
	;
	; notes:    use this when you recover from an error.
	;
	; tests:    
	;--------------------------
	db-reset-error: funcl [
	][
		vin "db-reset-error()"
		DB-ERR: none
		vout
	]
	


	;----------------------------------------------------------------------------------------------
	;
	;- FUNCTIONS ( high-level data interactions )
	;
	;
	; These are all abstracted functions which should be re-implemented for each data storage engine.
	;
	; They have a minimal set of generic inputs which you can translate to your model.
	;----------------------------------------------------------------------------------------------
	
	
	;--------------------------
	;-     db-get-user-count()
	;--------------------------
	; purpose:  get the number of users in the system.
	;
	; returns:  an integer! (0 on error)
	;
	; notes:    implementation is pretty rough but error tolerant
	;--------------------------
	db-get-user-count: funcl [
	][
		vin "db-get-user-count()"
		
		result: any [
			attempt [
				pick pick db-get {select count('uid') from users} 1 1
			]
			0
		]
		
		vout
		
		result
	]
	


	
	
	;----------------------------------------------------------------------------------------------
	;
	;- FUNCTIONS ( configuration )
	;
	;
	; these functions are meant to provide a high-level interface to configuring the server.
	; they are as generalized as possible to prevent tying down the server to a specific kind
	; of storage solution.
	;
	; note that none of them have an input a part for the set-config which uses a standardized
	; !config object.
	;
	; in a further release, even the config items themselves will be virtualized thru the
	; this module so that the actual configurations themselves are storage model specific.
	; This is already supported by the !config engine, it just needs to be added (I just didn't have time yet).
	;----------------------------------------------------------------------------------------------
	
	;--------------------------
	;-     db-set-config()
	;--------------------------
	; purpose:  sets the configuration which is used by the database.
	;
	; inputs:   a !config object
	;
	; returns:  true if the given configuration is sufficient (though it may be invalid)
	;--------------------------
	db-set-config: funcl [
		cfg [object!]
		/extern DB-CFG
	][
		vin "db-set-config()"
		cfg: if all [
			cfg/set? 'db-server
			cfg/set? 'db-user
			cfg/set? 'db-passwd
			cfg/set? 'db-url
		][
			DB-CFG: cfg
			true
		]
		
		vout
		cfg
	]
	
	

	;--------------------------
	;-     db-configured?()
	;--------------------------
	; purpose:  quickly tells us if the ODBC configuration has been configured successfully at least once.
	;           this allows us to attempt a connection right away without asking for user intervention.
	;
	; inputs:   none
	;
	; returns:  true/false
	;
	; notes:   -we use the DB-CFG value, so you must have called db-set-config() first.
	;          -although we have a configuration which was once valid, in may, in the next connection attempt
	;           be invalid.
	;--------------------------
	db-configured?: func [
	][
		true? all [
			object? DB-CFG
			true == get in DB-CFG '!config?
			found? DB-CFG/get 'db-url
		]
	]

	
	
	
	;--------------------------
	;-     db-reset-configuration()
	;--------------------------
	; purpose:  The current configuration is invalid or should be attempted again, reset it so
	;           other functions can react and ask user for new data or simply fail if unattended.
	;
	; inputs:   none
	;
	; returns:  nothing
	;
	; notes:    In ODBC, we only clear the db-url value, since we may want to present the user 
	;           with his old db-user/db-server values when we open up a dialog.
	;--------------------------
	db-reset-configuration: funcl [
	][
		vin "db-reset-configuration()"
		if DB-CFG [
			DB-CFG/set 'db-url none
		]
		vout
	]
	
	
	;----------------------------------------------------------------------------------------------
	;
	;- FUNCTIONS ( user setup )
	;
	;
	; when OpenME chat server isn't able to start its netorking, it might call setup 
	; functions which expect some kind of user interaction.
	;
	; you can disable user interaction and go directly to failure by setting 
	;
	;    stand-alone-install?: true 
	;
	; in the config file.
	;----------------------------------------------------------------------------------------------
	
	
	
	;--------------------------
	;-     db-interactive-setup()
	;--------------------------
	; purpose:  pops up a gui helping the user to setup the DATABASE.
	;
	; returns:  success as a true/false value.
	;
	; notes:    -if server is running unattended this is never called.
	;           -we rely on DB-CFG to have already been setup.
	;--------------------------
	db-interactive-setup: funcl [][
		success?: false
		
		vin "db-interactive-setup()"

		gui: layout [
			style text text 70
			backdrop white
			across
			
			origin 0x0
			banner
			
			origin 10x10
			pad 0x90
			
			info left wrap 580x200  edge none ;[color: 220.220.220 size: 1x1 effect: none] 
			( rejoin [
				"This version of OpenME/server is setup to use FireBird DB engine over ODBC in 32 bits"
				LINES
				{If you do not have Firebird installed on your system, press the "Setup FireBird..." button below to get help and links to its web site and downloads.}
				LINES
				{Once you have Installed Firebird, you must then setup an ODBC Data Source Name Server for it.  Press the "Setup Windows ODBC..." button below for help and instructions.}
				LINES
				{When all that is done, press the "Setup OpenME ODBC..." button to setup ODBC within the OpenME/server itself.}
				LINES
				{The Start Server button will only function once you've got the networking setup and are able to connect to it.}
			] )
			return
			
			pad 40x10
			btn 160 "1. Setup FireBird..." 70     [ block-face gui download-Firebird-dialog unblock-face gui ]
			btn 160 "2. Setup Windows ODBC..." 70 [ block-face gui ODBC-OS-DSN-dialog unblock-face gui ]
			btn 160 "3. Setup OpenME ODBC..." 70  [ block-face gui ODBC-connection-dialog unblock-face gui ]
			return

			pad 215x30
			btn "Launch" 70 [
				either db-connected? [
					unview/all
				][ 
					either db-connect [
						unview/all
					][
						alert "DB connection failed"
					]
				] 
			]
			btn "Quit" 70 [	quit ]
			
			origin 0x20
		]
		
		view center-face gui
		success?: DB-CFG/get 'db-url
		
		vout
		
		success?
	]
	
	
	
	;--------------------------
	;-     block-face()
	;--------------------------
	; purpose:  
	;
	; inputs:   
	;
	; returns:  
	;
	; notes:    
	;
	; tests:    
	;--------------------------
	block-face: funcl [
		fc [object!]
	][
		vin "block-face()"
		
		;probe type? face/pane
		;probe fc/size
		append fc/pane make face compose/deep [
			size: (fc/size)
			offset: 0x0
			color: none
			effect: [merge blur blur blur contrast -10 ]
		]
		show fc
		vout
	]
	
	
	
	
	;--------------------------
	;-     unblock-face()
	;--------------------------
	; purpose:  
	;
	; inputs:   
	;
	; returns:  
	;
	; notes:    
	;
	; tests:    
	;--------------------------
	unblock-face: funcl [
		face
	][
		vin "unblock-face()"
		remove back tail face/pane
		show face
		vout
	]
	


	
	ODBC-configuration-dialog: funcl [][
		vin "ODBC-configuration-dialog()"
		
		
		
		vout
	]
	


	
	;--------------------------
	;-     download-Firebird-dialog()
	;--------------------------
	download-Firebird-dialog: funct [][
		vin "download-Firebird-dialog()"
		
		gui: layout [
			backdrop white
			across
			
			origin 0x0
			banner 450
			
			origin 10x10
			pad 0x90
			
			h2 "FireBird DB Installation" 
			return

			text as-is left wrap 430  edge none ;[color: 220.220.220 size: 1x1 effect: none] 
			( rejoin [
				"You must download and install the 32-bit Firebird RDBMS.  As of 2012-02-24, the stable download is v.2.5.1*, and is dated  2011-10-04.  When you run the install program, you should choose the SuperServer install."
				LINES
				"You must download and install the 32-bit Firebird OBDC driver.  The latest stable release is version 2.0 dated 2011-04-04.  Choose the Windows full install."
				LINES
				"You must note where you put the database download. You will need to reference this location when you create the ODBC connector.  The file should be in a directory you can easily backup."
				LINES
				"We shall assume that you will put it within the %DB/ subdirectory, relative to your server script.  But you can put it wherever you want on your server."
				LINES
				{The buttons below will take you to the download pages. }
			] )
			return
			
			pad 30x15
			text red 350 230.230.230 wrap "Note that the OpenME server already has the blank DB within its distribution within the %DB/ subdir."
			return
			pad 0x10
			btn "Firebird RDBMS (6.5 Mb)" [ browse http://www.firebirdsql.org/en/server-packages/ ] 
			btn "Firebird ODBC (973 kb)" [ browse http://www.firebirdsql.org/en/odbc-driver/ ] 
			btn "Empty Database (636 kb)" [ browse http://www.compkarori.com/reb/CHAT.FDB ]  ; this path should be changed for the one on OpenME server
			return

			pad 190x20
			btn "Done" orange [hide-popup]
			
			origin 0x20 ; this just adjusts the end lower-right padding around the interface.
		]
		
		show-popup center-face gui
		do-events ; block the gui while the popup is opened.

		vout
	]
	


	
	;--------------------------
	;-     ODBC-OS-DSN-dialog()
	;--------------------------
	ODBC-OS-DSN-dialog: funct [][
		continue?: false


		gui: layout [
			backdrop white
			across
			
			origin 0x0
			banner 800
			
			origin 10x10
			pad 0x90
			
			h2 "Creating the ODBC connection" 
			return

			text as-is left wrap 780  edge none ;[color: 220.220.220 size: 1x1 effect: none] 
			( rejoin [
			;	"Now that you have sucessfully installed the Firebird SuperServer, and the Firebird ODBC driver, you now need to create the ODBC connection that will allow OpenME Chat to talk to the database."
			;	LINES
			;	"The following assumes that you have saved the database file ^"CHAT.FDB^" into the directory C:\chat\, but if you have not, substitute your own path."
			;	LINES
				"You now need to open up the ^"Data Sources (ODBC)^". In Windows XP, this is reached from the Control Panel, and then ^"Administrative Tools^".  In Windows 2003 Server, ^"Administrative Tools^" is available from the Start Menu.  Note that on 64 bits systems, the ODBC Adminstrator which opens from the OS is the 64 bit one, which will not work with this software.  In all cases, use the button below to open the proper ODBC manager (32bit)."
			] )
			return
			
			btn "Open ODBC Administrator" [ open-ODBC-Manager ]
			return
				
			text as-is left wrap 780  edge none ;[color: 220.220.220 size: 1x1 effect: none] 
			( rejoin [
				"With the ^"Data Sources (ODBC) Administrator^" open, you should see the ^"Firebird/Interbase(r) driver^" listed in the drivers tab (Screenshot 1).  If not, then you need to reinstall the Firebird ODBC driver."
				LINES
				"Select the ^"System DSN^" tab (DSN = Data source name), and then click on the ^"Add^" button.  Select the ^"Firebird/Interbase(r) driver^" (Screenshot 2) and then the ^"Finish^" button."
				LINES
				{(Screenshot 3) In the ^"Data Source Name (DSN)^" field, enter ^"OpenME^".  In the ^"Database^" field, enter ^"C:\chat\CHAT.FDB^" or the appropriate path.  You can use the ^"Browse^" button to put the file into the field.  Leave the ^"Client^" field empty.  Enter "SYSDBA" in the "Database Account" field, and "masterkey" in the "Password" field.  Try the "Test Connection" button to check if it is working.  If it is, then click on "OK" to save it.}
				LINES		
				"NB: if you cannot see the Firebird/Interbase(r) driver in your list, maybe you installed the 64 bit version by mistake, or that you opened the 64 bit version of the ODBC Manager!"

			] )
			return
			
			pad 30x15
			btn "Screenshot 1" [ show-popup layout [ across image driver.jpg return btn "Close" keycode [#"^["] [hide-popup]]  do-events]
			btn "Screenshot 2" [ show-popup layout [ across image select.jpg return btn "Close" keycode [#"^["] [hide-popup]]  do-events]
			btn "Screenshot 3" [ show-popup layout [ across image odbc.png return btn "Close" keycode [#"^["] [hide-popup]]   do-events ] 
			
			;return

			pad 400x0
			btn "Done" orange  [hide-popup]
			
			origin 0x20 ; this just adjusts the end lower-right padding around the interface.
		]
		
		show-popup center-face gui
		do-events ; block the gui while the popup is opened.





	]




	;--------------------------
	;-     ODBC-connection-dialog()
	;--------------------------
	; purpose:  a popup which allows you to setup your OpenME ODBC data source
	;
	; inputs:   none
	;
	; returns:  true/false depending on if they canceled or set up the connection
	;
	; notes:    this GUI allows the user to browse to other windows for help
	;--------------------------
	ODBC-connection-dialog: funcl [
	][
		vin "ODBC-connection-dialog()"
		
		update-ODBC-URL: func [][
			url-lbl/text:  rejoin [ "ODBC://" user-fld/text ":" pwd-fld/text "@" dsn-fld/text ]
			show url-lbl
		]
		
		
		;-------------------------------------------
		gui: layout [
			style text text right 70
		
			backdrop white
			across
			
			origin 0x0
			banner 400
			
			origin 10x10
			pad 0x90
			
			h2 "Configure OpenME ODBC" 
			return

			text as-is left wrap 380  edge none ;[color: 220.220.220 size: 1x1 effect: none] 
			( rejoin [
				"Since the ODBC DSN is available in the OS we have to assign it properly within OpenME server."
				LINES
				"USe the fields below to setup the database (it should be OK by default)."
				LINES
				"NB: You need to make sure that your firewall is blocking TCP port 3050 so that no-one outside your network can access your Firebird server."
			] )
			return
			
			
			pad 40 text "ODBC DSN" 
			dsn-fld: field (DB-CFG/get 'db-server)  [ update-ODBC-URL ]
			return
			
			pad 40 text "Username" 
			user-fld: field (DB-CFG/get 'db-user) [ update-ODBC-URL ]
			return
			
			pad 40 text "Password" 
			pwd-fld: field (DB-CFG/get 'db-passwd) [ update-ODBC-URL ]
			return
			
			pad 40 
			;text "Result URL" 
			url-lbl: text left 300 black (white * .9) edge [color: 200.200.200 effect: none size: 1x1] 
			return
			pad 40 test-lbl: text left  bold 300 font [size: 14] ""
			return

		
			pad 30x15
			;btn "Screenshot 1" [ show-popup layout [ across image admin.jpg return btn "Close" keycode [#"^["] [hide-popup]]   do-events]
			;btn "Screenshot 1" [ show-popup layout [ across image admin.jpg return btn "Close" keycode [#"^["] [hide-popup]]   do-events]

			;btn "Screenshot 2" [ show-popup layout [ across image running.jpg return btn "Close" keycode [#"^["] [hide-popup]] do-events]
			
			;return

			pad 100x0
			btn "Test Connection" [
				print "!"
				attempt [
					print ">"
					either db-connect/with to-url url-lbl/text [
						print "success"
						test-lbl/text: "Success!" 
						test-lbl/font/color: 0.200.0
						DB-CFG/set 'db-url to-url url-lbl/text
						show test-lbl
					][
						print "error"
						test-lbl/text: "Error"
						test-lbl/font/color: red
						show test-lbl
					] 
				]
			]
			btn "Done" orange  [hide-popup]
			
			origin 0x20 ; this just adjusts the end lower-right padding around the interface.
		]
		
		
		show-popup center-face gui
		update-ODBC-URL
		do-events ; block the gui while the popup is opened.
		
		vout
	]



	
	
	;----------------------------------------------------------------------------------------------
	;
	;- FUNCTIONS ( OS stuff )
	;
	;----------------------------------------------------------------------------------------------
	
	;--------------------------
	;-     Open-ODBC-Manager()
	;--------------------------
	; purpose:  opens up the 32 bit ODBC connection wizard on 64 AND 32 bit machines.
	;           REBOL uses the 32 bit interface to ODBC.
	;
	; notes:    automatically detects OS and starts the proper wizard.
	;
	;--------------------------
	open-ODBC-Manager: func [][
		either is64BitWindows? [
			call rejoin [get-env "%windir%" "\SysWOW64\odbcad32.exe"]
		][
			call rejoin [get-env "%windir%" "\system32\odbcad32.exe"]
		]
	]
	
	
	
]
Rebol [
    title: "EMR Chat Server"
    author: "Graham Chiu"
    rights: "GPL Copyright 2005"
    date: 3-Mar-2006
    version: 0.0.2
    encap: [ title "Synapse Chat Server v 0.0.3 " quiet secure none]
    changes: {
        30-Dec-2005 added chat server functions.
        3-Oct-2005 specialty
        2-Oct-2005 gps
        25-Sep-2005 appts
        23-Sep-2005 delete problem, tickler
        22-Sep-2005 add-problem, add-tickler, add-diagnosis
        21-Sep-2005 add-consult
    }
]

server-version: 0.0.3
expiry_date: 28-Apr-2006
; make sure in the correct directory
change-dir first split-path system/options/boot     

calcMD5: func [ binData ] [
    return enbase/base checksum/method binData 'md5 16
]

#include %/d/sdk2.6/source/prot.r
#include %/d/sdk2.6/source/view.r

odbc.jpg: load #include-binary %odbc.jpg
running.jpg: load #include-binary %running.jpg
select.jpg: load #include-binary %select.jpg
driver.jpg: load #include-binary %driver.jpg
admin.jpg: load #include-binary %admin.jpg
display: func[v][
 print ["display:" mold v]
]

#include  %/d/rebol/rebgui/beer2/libs/aa.r
#include  %/d/rebol/rebgui/beer2/libs/catch.r
#include  %/d/rebol/rebgui/beer2/libs/iatcp-protocol.r


#include  %/d/rebol/rebgui/beer2/beer/channel.r
#include  %/d/rebol/rebgui/beer2/beer/frameparser.r
#include  %/d/rebol/rebgui/beer2/beer/frameread.r
#include  %/d/rebol/rebgui/beer2/beer/framesend.r
#include  %/d/rebol/rebgui/beer2/beer/session-handler.r
#include  %/d/rebol/rebgui/beer2/beer/authenticate.r
#include  %/d/rebol/rebgui/beer2/beer/profiles.r
encoding-salt: #{D75B94668DC29BE2B2695781AE1732F7EC89C61D}
;; #include  %/d/rebol/rebgui/beer/examples/encoding-salt.r
#include  %/d/rebol/rebgui/beer/examples/echo-profile.r
#include  %/d/rebol/rebgui/beer2/beer/initiator.r
#include  %/d/rebol/rebgui/beer2/beer/listener.r
#include  %/d/rebol/rebgui/beer2/beer/profiles/rpc-profile.r

;; ft-profile is custom profile to upload from %chat-uploads/
#include  %/d/rebol/rebgui/beer2/beer/profiles/ft-server-profile.r
#include  %/e/rebol/BEER-SDK/beer/profiles/pubtalk-profile-new.r


;set path for received files

ft-profile: profile-registry/filetransfer
if ft-profile/destination-dir: %chat-uploads/ [make-dir ft-profile/destination-dir]


file-list: copy []
file-keys: make hash! []

debug: :none

;set callback handler for POST on server
ft-profile/post-handler: [
    switch action [
        init [
        ]
        read [
        ]
        write [
            ;renaming/filexists? routine
            if not exists? join data/7 channel/port/user-data/username [
                attempt [
                    make-dir/deep join data/7 channel/port/user-data/username
                ]
            ]

                    new-name: second split-path data/3
            either  exists? to-file rejoin [ data/7 channel/port/user-data/username "/" new-name ][
                print "file exists! changing name..."
                nr: 0
                until [
                    nr: nr + 1
                    either find tmp-name: copy new-name "." [
                        insert find/reverse tail tmp-name "." rejoin ["[" nr "]"]
                    ][
                        insert tail tmp-name rejoin ["[" nr "]"]
                    ]
                    tmp-name: replace/all tmp-name "/" ""
                    not exists? to-file rejoin [ data/7 channel/port/user-data/username "/" tmp-name ]
                ]
                new-name: to-file rejoin [ channel/port/user-data/username "/" tmp-name ]
            ][
                new-name: to-file rejoin [ channel/port/user-data/username "/" new-name ]
            ]

            print ["rename" join data/7 data/1 "to" new-name ]
            if error? set/any 'err try [
                change-dir data/7
                ; PROBE (to-file DATA/1)
                ; PROBE  NEW-NAME
                rename (to-file data/1) new-name
                change-dir %../
            ][
                print "Renaming failed"
                probe mold disarm err
            ]

            msg-to-all mold/all reduce [
                'gchat
                ["Files"]
                reduce ["Hal4000" red
                rejoin [ form last split-path new-name " has just been uploaded by " channel/port/user-data/username]
                black white [] now
                ]
            ]
            attempt [
                probe channel/port/user-data/username
            ]

;; save into database
        ]
        error []
    ]
]
ft-profile/get-handler: func [channel action data][
        switch action [
            init [
 ;               print ["start sending file" data/3 "of size" data/5 "to listener."]
            ]
            read [
 ;               print ["sending datachunk of file" data/3 "of size" data/6 "bytes"]
            ]
            write [
                print ["file" data/3 "has been completely sent to initiator"]
            ]
        ]
    ]

#include  %/e/rebol/BEER-SDK/beer/authenticate.r
#include  %/d/rebol/rebgui/beer/examples/encoding-salt.r

if now/date > expiry_date [
    view center-face layout [
        info "This beta server version is too old! Check the website for a more recent version of chat-server.exe" red wrap 200x60
        btn "Website Downloads" [ browse http://www.compkarori.com/reb/chat-server.exe ]
    ]
    quit
]

do OpenODBC: does [
    if error? set/any 'err try [
        dbase: open odbc://SYSDBA:masterkey@chat
        db-port: first dbase
    ][
        ; probe mold disarm err
        ; print "Fatal error - unable to open odbc connection to remr database"
        ; halt
        view center-face layout [
            across
            h1 "Synapse Chat Server" red return
            h2 "First Time Install?" return
            info  
{This screen has appeared as we can not open a connection to the database.

This could be because another copy of the program is running, or you have yet to install the Synapse Chat Server.

If the latter is correct, you need to download the Firebird Database software, the Firebird ODBC connector, and the chat database.
} 350x160 wrap return
            pad 250 btn "Proceed" [ unview ] btn "Quit" [ quit ]

        ]
        view center-face layout [
        across
        h1 "Installation Instructions" red return
        info
{You must download and install the Firebird RDBMS.  As of 26-Feb-2006, the stable download is v.1.5.3*, and is dated 24-Jan-2006.  When you run the install program, you should choose the SuperServer install.

You must download and install the Firebird OBDC driver.  The latest stable release is version 1.2 dated 26-Aug-2004.  Choose the Windows full install.

You must note where you put the database download. You will need to reference this location when you create the ODBC connector.  The file should be in a directory you can easily backup.

We shall assume that you will put in into c:\chat\

The buttons below will take you to the download pages. Click on the "Proceed" button after you have download all files, and installed both Firebird packages.  
}  450x270 wrap

return
        btn "Firebird RDBMS (2.7 Mb)" [ browse http://www.firebirdsql.org/index.php?op=files&id=engine ] 
        text "Firebird-1.5.2.4731-Win32.exe" bold
        return
        btn "Firebird ODBC (596 kbs)" [ browse http://www.firebirdsql.org/index.php?op=files&id=odbc ] 
        text "Firebird_ODBC_1.2.0.69-Win32.exe" bold
        return
        btn "Empty Database (636 kbs)" [ browse http://www.compkarori.com/reb/CHAT.FDB ]
        text "CHAT.FDB" bold 
        pad 120 btn "Proceed" [ Unview ] btn "Quit" [ quit]
        ]        

        view center-face layout [
            across
            h1 "Creating the ODBC connection" red return
            info 
{Now that you have sucessfully installed the Firebird SuperServer, and the Firebird ODBC driver, you now need to create the ODBC connection that will allow Synapse Chat to talk to the database.

The following assumes that you have saved the database file "CHAT.FDB" into the directory C:\chat\, but if you have not, substitute your own path.

You now need to open up the "Data Sources (ODBC)". In Windows XP, this is reached from the Control Panel, and then "Administrative Tools".  In Windows 2003 Server, "Administrative Tools" is available from the Start Menu.

With the "Data Sources (ODBC) Administrator" open, you should see the "Firebird/Interbase(r) driver" listed in the drivers tab (Screenshot 1).  If not, then you need to reinstall the Firebird ODBC driver.

Select the "System DSN" tab (DSN = Data source name), and then click on the "Add" button.  Select the "Firebird/Interbase(r) driver" (Screenshot 2) and then the "Finish" button.

(Screenshot 3) In the "Data Source Name (DSN)" field, enter "chat".  In the "Database" field, enter "C:\chat\CHAT.FDB" or the appropriate path.  You can use the "Browse" button to put the file into the field.  Leave the "Client" field empty.  Enter "SYSDBA" in the "Database Account" field, and "masterkey" in the "Password" field.  Try the "Test Connection" button to check if it is working.  If it is, then click on "OK" to save it.  You are now ready to proceed further to a restart.  If the same install screens appear, then you have not successfully completed the preceding steps.

With luck, you will see a screen to add the admin user (Screenshot 4), and once that is done, you should be up and running (Screenshot 5).

NB: You need to make sure that your firewall is blocking TCP port 3050 so that no-one outside your network can access your Firebird server.
}  600x450 wrap return
btn "Screenshot 1" [ view/new layout [ across image driver.jpg return btn "Close" keycode [#"^["] [unview]]]
btn "Screenshot 2" [ view/new layout [ across image select.jpg return btn "Close" keycode [#"^["] [unview]]]
btn "Screenshot 3" [ view/new layout [ across image odbc.jpg return btn "Close" keycode [#"^["] [unview]]] 
btn "Screenshot 4" [ view/new layout [ across image admin.jpg return btn "Close" keycode [#"^["] [unview]]]
btn "Screenshot 5" [ view/new layout [ across image running.jpg return btn "Close" keycode [#"^["] [unview]]]
pad 60 btn "Proceed" [ launch/quit ""] btn "Quit" [quit]
        ]
    quit
    ]
]

stopODBC: does [
    close db-port
    close dbase
]	 

restartODBC: has [ err ] [
    if error? set/any 'err try [
        attempt [ stopODBC ]
        recycle
        openODBC
        return "Restarted ODBC"
    ][ print mold disarm err return "Error on restarting ODBC" ]
]

insert db-port {select count('uid') from users}
no_of_staff: pick db-port 1
no_of_staff: pick no_of_staff 1

if no_of_staff = 0 [
    view center-face layout [
        across
        title "Set Up Admin User" red return space 1x1
        text "Username" bold 80 adminfld: field 80x20 font [size: 11] return
        text "Password" bold 80 passfld: field 80x20 font [size: 11] text {(minimum 8 characters)} return
        text "Given Name" bold 80 fnamefld: field 160x20 font [size: 11] return
        text "SurName" bold 80 snamefld: field 160x20 font [size: 11] return space 5x5
        text "Gender" bold 80 genderfld: field "M" 20x20 font [size: 11] return
        text "Email" bold 80 emailfld: field 200x20 font [size: 11] return
        text "Secret Question" bold 80 secretfld: field 200x20 font [size: 11] return
        text "Answer" bold 80 answerfld: field 200x20 font [size: 11] return
        pad 100 btn "Create" [
            either all [ not empty? adminfld/text not empty? passfld/text not empty? fnamefld/text not empty? snamefld/text not empty? genderfld/text not empty? secretfld/text not empty? answerfld/text (length? passfld/text) > 7 ][

                insert db-port [{insert into USERS (userid, rights, fname, surname, reminder, answer, email, gender, pass, activ ) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)} adminfld/text 5 fnamefld/text snamefld/text secretfld/text answerfld/text emailfld/text genderfld/text form encode-pass passfld/text encoding-salt "T"]
              unview
            ][
                alert "All fields need to be filled in and password is 8 characters or more"
            ]
        ] 
        btn "Quit" [ quit ] 
        do [ focus adminfld ]
    ]
]

    add-user: [
        across
        title "Set Up User" red return space 1x1
        text "Username" bold 80 adminfld: field 80x20 font [size: 11] return
        text "Password" bold 80 passfld: field 80x20 font [size: 11] text {(minimum 8 characters)} return
        text "Given Name" bold 80 fnamefld: field 160x20 font [size: 11] return
        text "SurName" bold 80 snamefld: field 160x20 font [size: 11] return space 5x5
        text "Gender" bold 80 genderfld: field "M" 20x20 font [size: 11] text "(Email used for password recovery)" return
        text "Email" bold 80 emailfld: field 200x20 font [size: 11] return
        text "Secret Question" bold 80 secretfld: field 200x20 font [size: 11] return
        text "Answer" bold 80 answerfld: field 200x20 font [size: 11] return
        pad 100 btn "Create" [
            either all [ not empty? adminfld/text not empty? passfld/text not empty? fnamefld/text not empty? snamefld/text not empty? genderfld/text not empty? secretfld/text not empty? answerfld/text (length? passfld/text) > 7 ][

                if error? set/any 'err try [
                    insert db-port [{insert into USERS (userid, rights, fname, surname, reminder, answer, email, gender, pass, pwd ) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)} adminfld/text 0 fnamefld/text snamefld/text  secretfld/text answerfld/text emailfld/text genderfld/text form encode-pass passfld/text encoding-salt passfld/text]
                    unview
                ][
                    probe mold err: disarm err

                    if find err/arg2 "violation of PRIMARY or UNIQUE KEY" [
                        print "This username is already in use"
                    ]
                    print "A sql error occurred - see console for explanation"
                ]              
            ][
                print "Fill in all fields according to criteria and password length"
            ]
        ] 
        btn "Close" keycode [ #"^["] [ unview ] 
        do [ focus adminfld ]
    ]

groups: load [
root [
    echo []
    filetransfer []
    rpc []
    PUBTALK-ETIQUETTE []
]

admin [
    echo []
]

chatuser [
    echo []
    filetransfer []
    rpc [register-user get-dir file-exists?]
    PUBTALK-ETIQUETTE []
]

anonymous [
    echo []
    rpc [register-user]
    PUBTALK-ETIQUETTE []    
]
]

do build-userfile: has [ security ][
    users: load {"anonymous" #{} nologin [anonymous]
    "listener" #{} nologin [monitor]
    "root" #{F71C2F645E81504EB9CC7AFC35C7777993957B4D} login [root]
    }

    insert db-port {select userid, pass, rights from users where activ = 'T'}

    foreach record copy db-port [

        switch/default record/3 [
            0 [ security: to-word "anonymous" ]
            1 [ security: to-word "chatuser" ]
            5 [ security: to-word "root" ]
        ][ security: to-word "root" ]
        repend users compose/deep [ record/1 load record/2 'login [ (security) ]  ]

    ]
]

attempt [
view/new layout [
    across
    h1 "Synapse Chat control panel" red return
    btn "Shut down" [ stopODBC quit ] btn "Add User" [ view/new center-face layout add-user ]
    btn "Reload Users" [build-userfile] 
    return
    info {Be sure to use the "Shut down" button in this control panel to avoid database corruption.  Closing this window, or the console, in any other way may have unpredictable effects on the database.  Both will shut the server down.} 250x100 wrap
]
]



#include %/d/rebol/rebgui/shrink.r
case: func [[throw catch]
    {
        Polymorphic If
        lazy evaluation
        no default (use True guard instead)
        If/Either compatibility:
            guard checking (unset not allowed)
            non-logic guards allowed
            block checking (after a guard only a block allowed)
            computed blocks allowed
            Return working
            Exit working
            Break working
    }
    args [block!] /local res
] [
    either unset? first res: do/next args [
        if not empty? args [
            ; invalid guard
            throw  make error! [script no-arg case condition]
        ]
    ] [
        either first res [
            either block? first res: do/next second res [
                do first res
            ] [
                ; not a block
                throw make error! [
                    script expect-arg case block [block!]
                ]
            ]
        ] [
            case second do/next second res
        ]
    ]
]



; sessions: copy []
timeout: 00:20:00 ; 20 mins
ftimeout: 00:05:00 ; 5 mins
invalid-session: "Logged out due to inactivity"

fileCache: copy []

session-object: make object! [ sessionid: userid: timestamp: ipaddress: security: lastmsg:  none ]

default-user: make object! [
    name: "Portal Administrator"
    email: no-one@nowhere.com
    smtp: none
    timezone: now/zone
    port: 8012
]

userobj: default-user

print [ "Synapse Chat Server " server-version " serving .... on port " userobj/port ]
; enterLog "Restart" "Admin" "Normal start"

basic-service: make-service [
    info: [
        name: "basic services"
    ]
    services: [time info registration maintenance]
    data: [
        info [
            service-names: func []	[
                services
            ]
        ]
        time [
            get-time: func []	[
                    now/time
            ]
        ]
        registration [
            register-user: func [ userid pass fname sname gender email secret answer 
                /local err result 
            ][
                print [ userid pass fname sname gender email secret answer  ]
                if error? set/any 'err try [
                    pwd: form encode-pass pass encoding-salt
                    activ: "F"
                    insert db-port [{insert into USERS (userid, rights, fname, surname, reminder, answer, email, gender, pass, activ, pwd ) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)} userid 1 fname sname secret answer email gender pwd  "F" pass]
                    attempt [
                            send compkarori@gmail.com join "New user registration on Synapse Chat: " userid
                    ]
                    attempt [
                        send/subject to-email email 
                            rejoin [ "You registered with the chat server as follows - user: " userid " password: " pass "^/both if which are case sensitive. ^/You will be contacted once your account is enabled." ] {Chat registration details}
                    ]
                    return reduce [ true ]
                ][ 
                    probe mold err: disarm err

                    if find err/arg2 "violation of PRIMARY or UNIQUE KEY" [
                        return [ -1 "This username is in use" ]
                    ]
                    return [ -1 "sql error in add-user" ]
                ]
            ]

        ]

        maintenance [
            show-users: func [/local result][
                result: copy []
                insert db-port {select uid, userid, fname, surname, email, activ from users}
                foreach record copy db-port [
                    append/only result record
                ]
                return result
            ]

            delete-user: func [ uid [integer!] ][
                insert db-port [{delete from users where uid = (?)} uid ]
                return true
            ]
            disable-user: func [ uid [integer!] ][
                insert db-port [{update users set activ = 'F' where uid = (?)} uid ]
                return true
            ]
            enable-user: func [ uid [integer!] ][
                insert db-port [{update users set activ = 'T' where uid = (?)} uid ]
                return true
            ]
            update-password: func [ uid password ][
                insert db-port [{update users set pass = (?), pwd = (?) where uid = (?)} encode-pass password encoding-salt password uid ]
                return true
            ]
            rebuild-users: does [
                build-userfile
                return true
            ]

            restart-server: does [
                print "Client requesting a server restart"
                close db-port
                close dbase
                ; call {rebcmdview.exe -s chat-server.r}
                ; quit
                launch/quit ""
            ]
            get-dir: func [ dir [file!] /local files filedata][
                probe dir
                either dir = %./
                [ files: read dir: ft-profile/destination-dir]
                [
                    if error? try [
                        probe  join ft-profile/destination-dir second split-path clean-path dir
                        files: read dir: join ft-profile/destination-dir second split-path clean-path dir
                    ][
                        files: copy []
                    ]
                ]
                filedata: copy []
                foreach file files [
                    inf: info? join dir  file
                    repend/only filedata [file inf/size inf/date]
                ]
                return filedata
            ]
            file-exists?: func [ file ][
                return either exists? to-file join %chat-uploads/ file [ true ] [ false ]
            ]
            delete-file: func [filename][
                either exists? join %chat-uploads/ filename [
                     if error? try [
                        delete join %chat-uploads/ filename
                        return "File deleted"
                     ][
                        return "Unable to delete file"
                     ]

                ][
                    return "File does not exist"
                ]
            ]
        ]
    ]
]

publish-service basic-service

; This is for the 'L side:

; chat-users: copy []

open-listener/callback userobj/port func [peer] [
    use [remote-ip remote-port peer-port ip-port] [

        print ["New mate on the bar" peer/sub-port/remote-ip peer/sub-port/remote-port]
        peer-port: :peer
        peer/user-data/on-close: func [msg /local channel] [
            print ["Mate left" peer-port/user-data/username peer-port/user-data/remote-ip peer-port/user-data/remote-port "reason:" msg]
            ; clean up by removing disconnected clients
            msg-to-all mold/all reduce ['gchat
                                        ["lobby"]
                                        reduce
                                        ["Hal4000" red rejoin [peer-port/user-data/username " has just left the building"] black white [] now]
                                    ]
            if error? set/any 'err try [                       
                insert db-port [ {update USERS set laston = 'NOW' where userid = (?)} peer-port/user-data/username ]            
            ][
                probe mold disarm err
            ]            
            print ["before removal users: " length? chatroom-peers]
                use [chat-users temp-table] [
                ; first remove disconnected clients 
                forall chatroom-peers [
                    if chatroom-peers/1/port/locals/peer-close [
                        remove chatroom-peers
                    ]
                ]
                rebuild-user-table
            ]
        ]
    ]
]

do-events







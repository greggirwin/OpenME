
Rebol [
	title: "Password encoding encryption key, aka an Encoding Salt"
	date: 2012-02-24
	version: 1.0.0
	authors: [MOA "Maxim Olivier-Adlhoch"]
	Comment: {
		This is an example password encoding salt.
		it should be changed on any new installation of a synapse server...

		It has been changed from the original synapse chat distribution
		
		----------------------------------------------------------------
		use by the server:
		----------------------------------------------------------------
		The server will use this binary string to encrypt (destructively) the plaintext passwords.
		
		Only the salted passwords are ever stored in the DB, thus even the admins cannot
		know what the user passwords are, nor can anyone hacking into the server.
		
		Salted passwords cannot be reversed back into their plaintext version, even via brute force.
		
		
		
		----------------------------------------------------------------
		to generate your own salt from a human readable string:
		----------------------------------------------------------------
		do the following in a REBOL Console:
		
			checksum/secure "XXXXXXX"
			
		where you replace "XXXXXXX" by any string you want and can remember.
		
		As usual, the larger the original string, the greater entropy in the result,
		and the better (more secure) the salt will be.
		
	}
	
	
	NOTES:  {
		- DO NOT push back salt changes to this file back into the Github repository 
		  (only improvements to the header are fair to upload).
		- The salt below is NOT generated with "XXXXXXX" so don't use that as a default,
		  thinking you can just hack into the server, when its setup was left as-is.
	}
] 
encoding-salt: #{25E448E316AC620F933E93CDBEA4FA7DBAE37BA3}

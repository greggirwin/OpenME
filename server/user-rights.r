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

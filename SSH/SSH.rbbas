#tag Module
Protected Module SSH
	#tag Method, Flags = &h1
		Protected Function IsAvailable() As Boolean
		  Static avail As Boolean
		  If Not avail Then avail = System.IsFunctionAvailable("libssh2_session_init", "libssh2")
		  Return avail
		End Function
	#tag EndMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_open_ex Lib "libssh2" (Session As Ptr, ChannelType As Ptr, ChannelTypeLength As UInt32, WindowSize As UInt32, PacketSize As UInt32, Message As Ptr, MessageLength As UInt32) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_open_session Lib "libssh2" (Session As Ptr) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Sub libssh2_exit Lib "libssh2" ()
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Sub libssh2_free Lib "libssh2" (Session As Ptr, BaseAddress As Ptr)
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_hostkey_hash Lib "libssh2" (Session As Ptr, HashType As Integer) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_init Lib "libssh2" (Flags As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_banner_get Lib "libssh2" (Session As Ptr) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_banner_set Lib "libssh2" (Session As Ptr, Banner As CString) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_block_directions Lib "libssh2" (Session As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_callback_set Lib "libssh2" (Session As Ptr, Type As Integer, Callback As Ptr) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_disconnect_ex Lib "libssh2" (Session As Ptr, Reason As Integer, Description As CString, Language As CString) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_flag Lib "libssh2" (Session As Ptr, Flag As Integer, Value As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_free Lib "libssh2" (Session As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_get_blocking Lib "libssh2" (Session As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_get_timeout Lib "libssh2" (Session As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_handshake Lib "libssh2" (Session As Ptr, Socket As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_hostkey Lib "libssh2" (Session As Ptr, ByRef Length As Integer, ByRef Type As Integer) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_init Lib "libssh2" () As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_last_errno Lib "libssh2" (Session As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_last_error Lib "libssh2" (Session As Ptr, ErrorMsg As Ptr, ByRef ErrorMsgLength As Integer, TakeOwnership As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_methods Lib "libssh2" (Session As Ptr, MethodType As Integer) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_method_pref Lib "libssh2" (Session As Ptr, MethodType As Integer, Prefs As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Sub libssh2_session_set_blocking Lib "libssh2" (Session As Ptr, Blocking As Integer)
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_set_last_error Lib "libssh2" (Session As Ptr, ErrorCode As Integer, ErrorMsg As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Sub libssh2_session_set_timeout Lib "libssh2" (Session As Ptr, Timeout As Integer)
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_supported_algs Lib "libssh2" (Session As Ptr, MethodType As Integer, ByRef Algs As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_userauth_keyboard_interactive_ex Lib "libssh2" (Session As Ptr, Username As Ptr, UsernameLength As UInt32, ResponseCallback As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_userauth_list Lib "libssh2" (Session As Ptr, Username As Ptr, UsernameLength As Integer) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_userauth_password_ex Lib "libssh2" (Session As Ptr, Username As Ptr, UsernameLength As UInt32, Password As Ptr, PasswordLength As UInt32, ChangePasswdCallback As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_userauth_publickey_fromfile_ex Lib "libssh2" (Session As Ptr, Username As Ptr, UsernameLength As UInt32, PublicKey As Ptr, PrivateKey As Ptr, Passphrase As Ptr) As Integer
	#tag EndExternalMethod


	#tag Constant, Name = LIBSSH2_ERROR_EAGAIN, Type = Double, Dynamic = False, Default = \"-37", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_HOSTKEY_HASH_MD5, Type = Double, Dynamic = False, Default = \"1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_HOSTKEY_HASH_SHA1, Type = Double, Dynamic = False, Default = \"2", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_HOSTKEY_HASH_SHA256, Type = Double, Dynamic = False, Default = \"3", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_HOSTKEY_TYPE_DSS, Type = Double, Dynamic = False, Default = \"2", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_HOSTKEY_TYPE_ECDSA_256, Type = Double, Dynamic = False, Default = \"3", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_HOSTKEY_TYPE_ECDSA_384, Type = Double, Dynamic = False, Default = \"4", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_HOSTKEY_TYPE_ECDSA_521, Type = Double, Dynamic = False, Default = \"5", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_HOSTKEY_TYPE_RSA, Type = Double, Dynamic = False, Default = \"1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SESSION_BLOCK_INBOUND, Type = Double, Dynamic = False, Default = \"&h0001", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SESSION_BLOCK_OUTBOUND, Type = Double, Dynamic = False, Default = \"&h0002", Scope = Private
	#tag EndConstant

	#tag Constant, Name = SSH_DISCONNECT_AUTH_CANCELLED_BY_USER, Type = Double, Dynamic = False, Default = \"13", Scope = Private
	#tag EndConstant

	#tag Constant, Name = SSH_DISCONNECT_BY_APPLICATION, Type = Double, Dynamic = False, Default = \"11", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = SSH_DISCONNECT_COMPRESSION_ERROR, Type = Double, Dynamic = False, Default = \"6", Scope = Private
	#tag EndConstant

	#tag Constant, Name = SSH_DISCONNECT_CONNECTION_LOST, Type = Double, Dynamic = False, Default = \"10", Scope = Private
	#tag EndConstant

	#tag Constant, Name = SSH_DISCONNECT_HOST_KEY_NOT_VERIFIABLE, Type = Double, Dynamic = False, Default = \"9", Scope = Private
	#tag EndConstant

	#tag Constant, Name = SSH_DISCONNECT_HOST_NOT_ALLOWED_TO_CONNECT, Type = Double, Dynamic = False, Default = \"1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = SSH_DISCONNECT_ILLEGAL_USER_NAME, Type = Double, Dynamic = False, Default = \"15", Scope = Private
	#tag EndConstant

	#tag Constant, Name = SSH_DISCONNECT_KEY_EXCHANGE_FAILED, Type = Double, Dynamic = False, Default = \"3", Scope = Private
	#tag EndConstant

	#tag Constant, Name = SSH_DISCONNECT_MAC_ERROR, Type = Double, Dynamic = False, Default = \"5", Scope = Private
	#tag EndConstant

	#tag Constant, Name = SSH_DISCONNECT_NO_MORE_AUTH_METHODS_AVAILABLE, Type = Double, Dynamic = False, Default = \"14", Scope = Private
	#tag EndConstant

	#tag Constant, Name = SSH_DISCONNECT_PROTOCOL_ERROR, Type = Double, Dynamic = False, Default = \"2", Scope = Private
	#tag EndConstant

	#tag Constant, Name = SSH_DISCONNECT_PROTOCOL_VERSION_NOT_SUPPORTED, Type = Double, Dynamic = False, Default = \"8", Scope = Private
	#tag EndConstant

	#tag Constant, Name = SSH_DISCONNECT_RESERVED, Type = Double, Dynamic = False, Default = \"4", Scope = Private
	#tag EndConstant

	#tag Constant, Name = SSH_DISCONNECT_SERVICE_NOT_AVAILABLE, Type = Double, Dynamic = False, Default = \"7", Scope = Private
	#tag EndConstant

	#tag Constant, Name = SSH_DISCONNECT_TOO_MANY_CONNECTIONS, Type = Double, Dynamic = False, Default = \"12", Scope = Private
	#tag EndConstant


	#tag ViewBehavior
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="Object"
		#tag EndViewProperty
	#tag EndViewBehavior
End Module
#tag EndModule

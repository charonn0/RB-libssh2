#tag Module
Protected Module SSH
	#tag Method, Flags = &h1
		Protected Function CreateSession(Address As String, Port As Integer, Username As String, PublicKeyFile As FolderItem, PrivateKeyFile As FolderItem, PrivateKeyFilePassword As String, KnownHostList As FolderItem = Nil, AddHost As Boolean = False) As SSH.Session
		  Dim sess As New SSH.Session()
		  sess.Blocking = True
		  Dim err As Integer = sess.Connect(Address, Port, KnownHostList, AddHost)
		  If err <> 0 Then Raise New SSHException(err)
		  sess.SetCredentials(Username, PublicKeyFile, PrivateKeyFile, PrivateKeyFilePassword)
		  Return sess
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function CreateSession(Address As String, Port As Integer, Username As String, Password As String, KnownHostList As FolderItem = Nil, AddHost As Boolean = False) As SSH.Session
		  Dim sess As New SSH.Session()
		  sess.Blocking = True
		  Dim err As Integer = sess.Connect(Address, Port, KnownHostList, AddHost)
		  If err <> 0 Then Raise New SSHException(err)
		  sess.SetCredentials(Username, Password)
		  Return sess
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function ErrorName(ErrorNumber As Integer) As String
		  Select Case ErrorNumber
		  Case 0
		    Return "LIBSSH2_ERROR_NONE"
		  Case -1
		    Return "LIBSSH2_ERROR_SOCKET_NONE"
		  Case -2
		    Return "LIBSSH2_ERROR_BANNER_NONE"
		  Case -3
		    Return "LIBSSH2_ERROR_BANNER_SEND"
		  Case -4
		    Return "LIBSSH2_ERROR_INVALID_MAC"
		  Case -5
		    Return "LIBSSH2_ERROR_KEX_FAILURE"
		  Case -6
		    Return "LIBSSH2_ERROR_ALLOC"
		  Case -7
		    Return "LIBSSH2_ERROR_SOCKET_SEND"
		  Case -8
		    Return "LIBSSH2_ERROR_KEY_EXCHANGE_FAILURE"
		  Case -9
		    Return "LIBSSH2_ERROR_TIMEOUT"
		  Case -10
		    Return "LIBSSH2_ERROR_HOSTKEY_INIT"
		  Case -11
		    Return "LIBSSH2_ERROR_HOSTKEY_SIGN"
		  Case -12
		    Return "LIBSSH2_ERROR_DECRYPT"
		  Case -13
		    Return "LIBSSH2_ERROR_SOCKET_DISCONNECT"
		  Case -14
		    Return "LIBSSH2_ERROR_PROTO"
		  Case -15
		    Return "LIBSSH2_ERROR_PASSWORD_EXPIRED"
		  Case -16
		    Return "LIBSSH2_ERROR_FILE"
		  Case -17
		    Return "LIBSSH2_ERROR_METHOD_NONE"
		  Case -18
		    Return "LIBSSH2_ERROR_PUBLICKEY_UNRECOGNIZED"
		  Case -19
		    Return "LIBSSH2_ERROR_PUBLICKEY_UNVERIFIED"
		  Case -20
		    Return "LIBSSH2_ERROR_CHANNEL_OUTOFORDER"
		  Case -21
		    Return "LIBSSH2_ERROR_CHANNEL_FAILURE"
		  Case -22
		    Return "LIBSSH2_ERROR_CHANNEL_REQUEST_DENIED"
		  Case -23
		    Return "LIBSSH2_ERROR_CHANNEL_UNKNOWN"
		  Case -24
		    Return "LIBSSH2_ERROR_CHANNEL_WINDOW_EXCEEDED"
		  Case -25
		    Return "LIBSSH2_ERROR_CHANNEL_PACKET_EXCEEDED"
		  Case -26
		    Return "LIBSSH2_ERROR_CHANNEL_CLOSED"
		  Case -27
		    Return "LIBSSH2_ERROR_CHANNEL_EOF_SENT"
		  Case -28
		    Return "LIBSSH2_ERROR_SCP_PROTOCOL"
		  Case -29
		    Return "LIBSSH2_ERROR_ZLIB"
		  Case -30
		    Return "LIBSSH2_ERROR_SOCKET_TIMEOUT"
		  Case -31
		    Return "LIBSSH2_ERROR_SFTP_PROTOCOL"
		  Case -32
		    Return "LIBSSH2_ERROR_REQUEST_DENIED"
		  Case -33
		    Return "LIBSSH2_ERROR_METHOD_NOT_SUPPORTED"
		  Case -34
		    Return "LIBSSH2_ERROR_INVAL"
		  Case -35
		    Return "LIBSSH2_ERROR_INVALID_POLL_TYPE"
		  Case -36
		    Return "LIBSSH2_ERROR_PUBLICKEY_PROTOCOL"
		  Case -37
		    Return "LIBSSH2_ERROR_EAGAIN"
		  Else
		    Return "Unknown error number."
		    
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function IsAvailable() As Boolean
		  Static avail As Boolean
		  If Not avail Then avail = (Version <> "")
		  Return avail
		End Function
	#tag EndMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_agent_connect Lib "libssh2" (Agent As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_agent_disconnect Lib "libssh2" (Agent As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Sub libssh2_agent_free Lib "libssh2" (Agent As Ptr)
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_agent_get_identity Lib "libssh2" (Agent As Ptr, ByRef Store As Ptr, Previous As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_agent_init Lib "libssh2" (Session As Ptr) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_agent_list_identities Lib "libssh2" (Agent As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_agent_userauth Lib "libssh2" (Agent As Ptr, Username As CString, Identity As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_close Lib "libssh2" (Channel As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_direct_tcpip_ex Lib "libssh2" (Session As Ptr, RemoteHost As CString, RemotePort As Integer, LocalHost As CString, LocalPort As Integer) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_eof Lib "libssh2" (Channel As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_exec Lib "libssh2" (Session As Ptr, Command As CString) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_flush_ex Lib "libssh2" (Channel As Ptr, StreamID As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_free Lib "libssh2" (Channel As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_get_exit_status Lib "libssh2" (Channel As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_open_ex Lib "libssh2" (Session As Ptr, ChannelType As Ptr, ChannelTypeLength As UInt32, WindowSize As UInt32, PacketSize As UInt32, Message As Ptr, MessageLength As UInt32) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_open_session Lib "libssh2" (Session As Ptr) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_process_startup Lib "libssh2" (Channel As Ptr, Request As Ptr, RequestLength As UInt32, Message As Ptr, MessageLength As UInt32) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_read_ex Lib "libssh2" (Channel As Ptr, StreamID As Integer, Buffer As Ptr, BufferLength As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_request_pty_ex Lib "libssh2" (Channel As Ptr, Terminal As CString, TerminalLength As Integer, Modes As Ptr, ModesLength As Integer, Width As Integer, Height As Integer, PixHeight As Integer, PixWidth As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_send_eof Lib "libssh2" (Channel As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_setenv_ex Lib "libssh2" (Channel As Ptr, VarName As CString, VarNameLength As UInt32, Value As CString, ValueLength As UInt32) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_wait_closed Lib "libssh2" (Channel As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_write_ex Lib "libssh2" (Channel As Ptr, StreamID As Integer, Buffer As Ptr, BufferLength As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Sub libssh2_exit Lib "libssh2" ()
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Sub libssh2_free Lib "libssh2" (Session As Ptr, BaseAddress As Ptr)
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_hostkey_hash Lib "libssh2" (Session As Ptr, HashType As SSH . HashType) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_init Lib "libssh2" (Flags As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Sub libssh2_keepalive_config Lib "libssh2" (Session As Ptr, WantReply As Integer, Timeout As UInt32)
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_keepalive_send Lib "libssh2" (Session As Ptr, ByRef SecondsToNext As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_knownhost_addc Lib "libssh2" (KnownHosts As Ptr, Host As CString, Salt As Ptr, Key As Ptr, KeyLength As Integer, Comment As Ptr, CommentLength As Integer, TypeMask As Integer, ByRef Store As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_knownhost_check Lib "libssh2" (KnownHosts As Ptr, Host As CString, Key As Ptr, KeyLength As Integer, TypeMask As Integer, ByRef Store As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_knownhost_checkp Lib "libssh2" (KnownHosts As Ptr, Host As CString, Port As Integer, Key As Ptr, KeyLength As Integer, TypeMask As Integer, ByRef Store As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_knownhost_del Lib "libssh2" (KnownHosts As Ptr, Entry As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Sub libssh2_knownhost_free Lib "libssh2" (KnownHosts As Ptr)
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_knownhost_get Lib "libssh2" (KnownHosts As Ptr, ByRef Store As Ptr, Prev As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_knownhost_init Lib "libssh2" (Session As Ptr) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_knownhost_readfile Lib "libssh2" (KnownHosts As Ptr, Filename As CString, Type As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_knownhost_readline Lib "libssh2" (KnownHosts As Ptr, Line As Ptr, LineLength As Integer, Type As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_knownhost_writefile Lib "libssh2" (KnownHosts As Ptr, SaveTo As CString, Type As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_knownhost_writeline Lib "libssh2" (KnownHosts As Ptr, Host As Ptr, Buffer As Ptr, BufferLength As Integer, ByRef LengthWritten As Integer, Type As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_publickey_init Lib "libssh2" (Session As Ptr) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_scp_recv2 Lib "libssh2" (Session As Ptr, Path As CString, stat As Ptr) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_scp_send_ex Lib "libssh2" (Session As Ptr, Path As CString, Mode As Integer, StreamLength As UInt32, mTime As Integer, aTime As Integer) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_abstract Lib "libssh2" (Session As Ptr) As Ptr
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
		Private Soft Declare Function libssh2_session_disconnect_ex Lib "libssh2" (Session As Ptr, Reason As DisconnectReason, Description As CString, Language As CString) As Integer
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
		Private Soft Declare Function libssh2_session_init_ex Lib "libssh2" (MyAlloc As Ptr, MyFree As Ptr, MyRealloc As Ptr, Abstract As Integer) As Ptr
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
		Private Soft Declare Function libssh2_sftp_close_handle Lib "libssh2" (SFTP As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_fsync Lib "libssh2" (SFTP As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_get_channel Lib "libssh2" (SFTP As Ptr) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_init Lib "libssh2" (Session As Ptr) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_last_error Lib "libssh2" (SFTP As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_mkdir_ex Lib "libssh2" (SFTP As Ptr, DirectoryName As Ptr, DirectoryNameLength As UInt32, Mode As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_open_ex Lib "libssh2" (SFTP As Ptr, Filename As Ptr, FilenameLength As UInt32, Flags As UInt32, Mode As Integer, Type As Integer) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_read Lib "libssh2" (SFTP As Ptr, Buffer As Ptr, BufferLength As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_readdir_ex Lib "libssh2" (SFTP As Ptr, Buffer As Ptr, BufferLength As Integer, LongEntry As Ptr, LongEntryLength As Integer, ByRef Attribs As LIBSSH2_SFTP_ATTRIBUTES) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_rename_ex Lib "libssh2" (SFTP As Ptr, SourceName As Ptr, SourceLength As UInt32, DestinationName As Ptr, DestinationLength As UInt32, Flags As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_rmdir_ex Lib "libssh2" (SFTP As Ptr, Path As Ptr, PathLength As UInt32) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Sub libssh2_sftp_seek64 Lib "libssh2" (SFTP As Ptr, Offset As UInt64)
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_shutdown Lib "libssh2" (SFTP As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_tell64 Lib "libssh2" (SFTP As Ptr) As UInt64
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_unlink_ex Lib "libssh2" (SFTP As Ptr, FileName As Ptr, FileNameLength As UInt32) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_write Lib "libssh2" (SFTP As Ptr, Buffer As Ptr, BufferLength As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_userauth_authenticated Lib "libssh2" (Session As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_userauth_keyboard_interactive_ex Lib "libssh2" (Session As Ptr, Username As Ptr, UsernameLength As UInt32, ResponseCallback As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_userauth_list Lib "libssh2" (Session As Ptr, Username As Ptr, UsernameLength As Integer) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_userauth_password_ex Lib "libssh2" (Session As Ptr, Username As CString, UsernameLength As UInt32, Password As CString, PasswordLength As UInt32, ChangePasswdCallback As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_userauth_publickey_fromfile_ex Lib "libssh2" (Session As Ptr, Username As CString, UsernameLength As UInt32, PublicKey As CString, PrivateKey As CString, Passphrase As CString) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_userauth_publickey_frommemory Lib "libssh2" (Session As Ptr, Username As CString, UsernameLength As Integer, PublicKey As Ptr, PublicKeyLength As Integer, PrivateKey As Ptr, PrivateKeyLength As Integer, Passphrase As CString) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_version Lib "libssh2" (RequiredVersion As Integer) As CString
	#tag EndExternalMethod

	#tag Method, Flags = &h1
		Protected Function OpenChannel(Session As SSH.Session, Type As String = "session", WindowSize As UInt32 = LIBSSH2_CHANNEL_WINDOW_DEFAULT, PacketSize As UInt32 = LIBSSH2_CHANNEL_PACKET_DEFAULT, Message As String = "") As SSH.Channel
		  Return Channel.Open(Session, Type, WindowSize, PacketSize, Message)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Version() As String
		  If System.IsFunctionAvailable("libssh2_version", "libssh2") Then Return libssh2_version(MIMIMUM_VERSION)
		End Function
	#tag EndMethod


	#tag Constant, Name = ERR_INIT_FAILED, Type = Double, Dynamic = False, Default = \"-500", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_CHANNEL_FLUSH_ALL, Type = Double, Dynamic = False, Default = \"-2", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_CHANNEL_FLUSH_EXTENDED_DATA, Type = Double, Dynamic = False, Default = \"-1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_CHANNEL_MINADJUST, Type = Double, Dynamic = False, Default = \"1024", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_CHANNEL_PACKET_DEFAULT, Type = Double, Dynamic = False, Default = \"16384", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_CHANNEL_WINDOW_DEFAULT, Type = Double, Dynamic = False, Default = \"65536", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_ALLOC, Type = Double, Dynamic = False, Default = \"-6", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_BANNER_NONE, Type = Double, Dynamic = False, Default = \"-2", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_BANNER_SEND, Type = Double, Dynamic = False, Default = \"-3", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_CHANNEL_CLOSED, Type = Double, Dynamic = False, Default = \"-26", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_CHANNEL_EOF_SENT, Type = Double, Dynamic = False, Default = \"-27", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_CHANNEL_FAILURE, Type = Double, Dynamic = False, Default = \"-21", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_CHANNEL_OUTOFORDER, Type = Double, Dynamic = False, Default = \"-20", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_CHANNEL_PACKET_EXCEEDED, Type = Double, Dynamic = False, Default = \"-25", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_CHANNEL_REQUEST_DENIED, Type = Double, Dynamic = False, Default = \"-22", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_CHANNEL_UNKNOWN, Type = Double, Dynamic = False, Default = \"-23", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_CHANNEL_WINDOW_EXCEEDED, Type = Double, Dynamic = False, Default = \"-24", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_DECRYPT, Type = Double, Dynamic = False, Default = \"-12", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_EAGAIN, Type = Double, Dynamic = False, Default = \"-37", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_FILE, Type = Double, Dynamic = False, Default = \"-16", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_HOSTKEY_INIT, Type = Double, Dynamic = False, Default = \"-10", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_HOSTKEY_SIGN, Type = Double, Dynamic = False, Default = \"-11", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_INVAL, Type = Double, Dynamic = False, Default = \"-34", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_INVALID_MAC, Type = Double, Dynamic = False, Default = \"-4", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_INVALID_POLL_TYPE, Type = Double, Dynamic = False, Default = \"-35", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_KEX_FAILURE, Type = Double, Dynamic = False, Default = \"-5", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_KEY_EXCHANGE_FAILURE, Type = Double, Dynamic = False, Default = \"-8", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_METHOD_NONE, Type = Double, Dynamic = False, Default = \"-17", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_METHOD_NOT_SUPPORTED, Type = Double, Dynamic = False, Default = \"-33", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_NONE, Type = Double, Dynamic = False, Default = \"0", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_PASSWORD_EXPIRED, Type = Double, Dynamic = False, Default = \"-15", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_PROTO, Type = Double, Dynamic = False, Default = \"-14", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_PUBLICKEY_PROTOCOL, Type = Double, Dynamic = False, Default = \"-36", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_PUBLICKEY_UNRECOGNIZED, Type = Double, Dynamic = False, Default = \"-18", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_PUBLICKEY_UNVERIFIED, Type = Double, Dynamic = False, Default = \"-19", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_REQUEST_DENIED, Type = Double, Dynamic = False, Default = \"-32", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_SCP_PROTOCOL, Type = Double, Dynamic = False, Default = \"-28", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_SFTP_PROTOCOL, Type = Double, Dynamic = False, Default = \"-31", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_SOCKET_DISCONNECT, Type = Double, Dynamic = False, Default = \"-13", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_SOCKET_NONE, Type = Double, Dynamic = False, Default = \"-1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_SOCKET_SEND, Type = Double, Dynamic = False, Default = \"-7", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_SOCKET_TIMEOUT, Type = Double, Dynamic = False, Default = \"-30", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_TIMEOUT, Type = Double, Dynamic = False, Default = \"-9", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_ZLIB, Type = Double, Dynamic = False, Default = \"-29", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SESSION_BLOCK_INBOUND, Type = Double, Dynamic = False, Default = \"&h0001", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SESSION_BLOCK_OUTBOUND, Type = Double, Dynamic = False, Default = \"&h0002", Scope = Private
	#tag EndConstant

	#tag Constant, Name = MIMIMUM_VERSION, Type = Double, Dynamic = False, Default = \"&h00010700", Scope = Private
	#tag EndConstant

	#tag Constant, Name = SSH_DISCONNECT_PROTOCOL_VERSION_NOT_SUPPORTED, Type = Double, Dynamic = False, Default = \"8", Scope = Private
	#tag EndConstant


	#tag Structure, Name = LIBSSH2_SFTP_ATTRIBUTES, Flags = &h21
		Flags As UInt32
		  FileSize As UInt64
		  UID As UInt32
		  GID As UInt32
		  Perms As UInt32
		  ATime As UInt32
		MTime As UInt32
	#tag EndStructure


	#tag Enum, Name = DisconnectReason, Type = Integer, Flags = &h1
		HostNotAllowed=1
		  ProtocolError=2
		  KeyExchangeFailed=3
		  Reserved=4
		  MACError=5
		  CompressionError=6
		  ServiceNotAvailable=7
		  ProtocolVersionNotSupported=8
		  HostKeyNotVerifiable=9
		  ConnectionLost=10
		  AppRequested=11
		  TooManyConnections=12
		  AuthCanceledByUser=13
		  NoMoreAuthMethodsAvailable=14
		IllegalUsername=15
	#tag EndEnum

	#tag Enum, Name = HashType, Type = Integer, Flags = &h1
		MD5=1
		  SHA1=2
		SHA256=3
	#tag EndEnum

	#tag Enum, Name = HostKeyType, Type = Integer, Flags = &h1
		RSA=1
		  DSS=2
		  ECDSA_256=3
		  ECDSA_384=4
		ECDSA_521=5
	#tag EndEnum


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

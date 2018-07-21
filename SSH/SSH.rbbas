#tag Module
Protected Module SSH
	#tag Method, Flags = &h1
		Protected Function Connect(URL As String, KnownHostList As FolderItem = Nil, AddHost As Boolean = False) As SSH.Session
		  ' Attemt a new SSH connection to the server specified by the Address and Port parameters.
		  ' Authenticate to the server with the Username and Password.
		  ' If KnownHostList is specified then the server's fingerprint will be compared to it. If
		  ' AddHost is False and the fingerprint is not in the KnownHostList then an exception will
		  ' be raised; if AddHost is True then the fingerprint is added to KnownHostList.
		  
		  Dim d As Dictionary = ParseURL(URL)
		  Dim host As String = d.Value("host")
		  Dim port As Integer = d.Lookup("port", 22)
		  Dim user As String = d.Lookup("username", "")
		  Dim pass As String = d.Lookup("password", "")
		  Return Connect(host, port, user, pass, KnownHostList, AddHost)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Connect(Address As String, Port As Integer, Username As String, PublicKeyFile As FolderItem, PrivateKeyFile As FolderItem, PrivateKeyFilePassword As String, KnownHostList As FolderItem = Nil, AddHost As Boolean = False) As SSH.Session
		  ' Attemt a new SSH connection to the server specified by the Address and Port parameters.
		  ' Authenticate to the server as Username with the PublicKeyFile and PrivateKeyFile FolderItems.
		  ' If KnownHostList is specified then the server's fingerprint will be compared to it. If
		  ' AddHost is False and the fingerprint is not in the KnownHostList then an exception will
		  ' be raised; if AddHost is True then the fingerprint is added to KnownHostList.
		  
		  Dim sess As New SSH.Session()
		  sess.Blocking = True
		  If KnownHostList <> Nil Then sess.KnownHosts = New SSH.KnownHosts(sess, KnownHostList)
		  
		  If sess.Connect(Address, Port, AddHost) Then
		    Call sess.SetCredentials(Username, PublicKeyFile, PrivateKeyFile, PrivateKeyFilePassword)
		  End If
		  Return sess
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Connect(Address As String, Port As Integer, Username As String, PublicKey As MemoryBlock, PrivateKey As MemoryBlock, PrivateKeyPassword As String, KnownHostList As FolderItem = Nil, AddHost As Boolean = False) As SSH.Session
		  ' Attemt a new SSH connection to the server specified by the Address and Port parameters.
		  ' Authenticate to the server as Username with the PublicKey and PrivateKey MemoryBlocks.
		  ' If KnownHostList is specified then the server's fingerprint will be compared to it. If 
		  ' AddHost is False and the fingerprint is not in the KnownHostList then an exception will
		  ' be raised; if AddHost is True then the fingerprint is added to KnownHostList.
		  
		  Dim sess As New SSH.Session()
		  sess.Blocking = True
		  If KnownHostList <> Nil Then sess.KnownHosts = New SSH.KnownHosts(sess, KnownHostList)
		  If sess.Connect(Address, Port, AddHost) Then
		    Call sess.SetCredentials(Username, PublicKey, PrivateKey, PrivateKeyPassword)
		  End If
		  Return sess
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Connect(Address As String, Port As Integer, Username As String, Password As String, KnownHostList As FolderItem = Nil, AddHost As Boolean = False) As SSH.Session
		  ' Attemt a new SSH connection to the server specified by the Address and Port parameters.
		  ' Authenticate to the server with the Username and Password.
		  ' If KnownHostList is specified then the server's fingerprint will be compared to it. If
		  ' AddHost is False and the fingerprint is not in the KnownHostList then an exception will
		  ' be raised; if AddHost is True then the fingerprint is added to KnownHostList.
		  
		  Dim sess As New SSH.Session()
		  sess.Blocking = True
		  If KnownHostList <> Nil Then sess.KnownHosts = New SSH.KnownHosts(sess, KnownHostList)
		  If sess.Connect(Address, Port, AddHost) Then
		    Call sess.SetCredentials(Username, Password)
		  End If
		  Return sess
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Execute(Optional Session As SSH.Session, Command As String) As SSH.SSHStream
		  If Session = Nil Then 
		    Dim d As Dictionary = ParseURL(Command)
		    Dim host As String = d.Value("host")
		    Dim port As Integer = d.Lookup("port", 22)
		    Dim user As String = d.Lookup("username", "")
		    Dim pass As String = d.Lookup("password", "")
		    Session = Connect(host, port, user, pass)
		    Command = Replace(d.Value("path"), "/", "")
		  End If
		  Dim sh As Channel = OpenChannel(Session)
		  If Command <> "" Then
		    If Not sh.Execute(Command) Then Raise New SSHException(sh.LastError)
		  End If
		  Return sh
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Get(Optional Session As SSH.Session, URL As String) As SSH.SSHStream
		  Dim d As Dictionary = ParseURL(URL)
		  Dim host, user, pass, scheme, path As String
		  host = d.Lookup("host", "")
		  user = d.Lookup("username", "")
		  pass = d.Lookup("password", "")
		  scheme = d.Lookup("scheme", "").Lowercase
		  path = d.Lookup("path", "")
		  Dim port As Integer = d.Lookup("port", 22)
		  
		  If Session = Nil Then Session = Connect(host, port, user, pass)
		  Select Case scheme
		  Case "scp"
		    Return Channel.OpenSCP(Session, path)
		  Case "sftp"
		    Dim sftp As New SFTPSession(Session)
		    Return sftp.Get(path)
		  Else
		    Raise New RuntimeException
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function IsAvailable() As Boolean
		  Static avail As Boolean
		  If Not avail Then avail = System.IsFunctionAvailable("libssh2_session_init_ex", libssh2)
		  Return avail
		End Function
	#tag EndMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_agent_connect Lib libssh2 (Agent As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_agent_disconnect Lib libssh2 (Agent As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Sub libssh2_agent_free Lib libssh2 (Agent As Ptr)
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_agent_get_identity Lib libssh2 (Agent As Ptr, ByRef Store As Ptr, Previous As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_agent_init Lib libssh2 (Session As Ptr) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_agent_list_identities Lib libssh2 (Agent As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_agent_userauth Lib libssh2 (Agent As Ptr, Username As CString, Identity As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_close Lib libssh2 (Channel As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_direct_tcpip_ex Lib libssh2 (Session As Ptr, RemoteHost As CString, RemotePort As Integer, LocalHost As CString, LocalPort As Integer) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_eof Lib libssh2 (Channel As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_exec Lib libssh2 (Session As Ptr, Command As CString) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_flush_ex Lib libssh2 (Channel As Ptr, StreamID As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_free Lib libssh2 (Channel As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_get_exit_status Lib libssh2 (Channel As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_open_ex Lib libssh2 (Session As Ptr, ChannelType As Ptr, ChannelTypeLength As UInt32, WindowSize As UInt32, PacketSize As UInt32, Message As Ptr, MessageLength As UInt32) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_open_session Lib libssh2 (Session As Ptr) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_process_startup Lib libssh2 (Channel As Ptr, Request As Ptr, RequestLength As UInt32, Message As Ptr, MessageLength As UInt32) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_read_ex Lib libssh2 (Channel As Ptr, StreamID As Integer, Buffer As Ptr, BufferLength As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_request_pty_ex Lib libssh2 (Channel As Ptr, Terminal As CString, TerminalLength As Integer, Modes As Ptr, ModesLength As Integer, Width As Integer, Height As Integer, PixHeight As Integer, PixWidth As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_send_eof Lib libssh2 (Channel As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_setenv_ex Lib libssh2 (Channel As Ptr, VarName As CString, VarNameLength As UInt32, Value As CString, ValueLength As UInt32) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_wait_closed Lib libssh2 (Channel As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_window_read_ex Lib libssh2 (Channel As Ptr, ByRef ReadAvail As UInt32, ByRef InitialSize As UInt32) As UInt32
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_window_write_ex Lib libssh2 (Channel As Ptr, ByRef InitialSize As UInt32) As UInt32
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_channel_write_ex Lib libssh2 (Channel As Ptr, StreamID As Integer, Buffer As Ptr, BufferLength As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Sub libssh2_exit Lib libssh2 ()
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Sub libssh2_free Lib libssh2 (Session As Ptr, BaseAddress As Ptr)
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_hostkey_hash Lib libssh2 (Session As Ptr, HashType As SSH . HashType) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_init Lib libssh2 (Flags As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Sub libssh2_keepalive_config Lib libssh2 (Session As Ptr, WantReply As Integer, Timeout As UInt32)
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_keepalive_send Lib libssh2 (Session As Ptr, ByRef SecondsToNext As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_knownhost_addc Lib libssh2 (KnownHosts As Ptr, Host As CString, Salt As Ptr, Key As Ptr, KeyLength As UInt32, Comment As Ptr, CommentLength As UInt32, TypeMask As Integer, ByRef Store As libssh2_knownhost) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_knownhost_check Lib libssh2 (KnownHosts As Ptr, Host As CString, Key As Ptr, KeyLength As Integer, TypeMask As Integer, ByRef Store As libssh2_knownhost) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_knownhost_checkp Lib libssh2 (KnownHosts As Ptr, Host As CString, Port As Integer, Key As Ptr, KeyLength As Integer, TypeMask As Integer, ByRef Store As libssh2_knownhost) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_knownhost_del Lib libssh2 (KnownHosts As Ptr, Entry As libssh2_knownhost) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Sub libssh2_knownhost_free Lib libssh2 (KnownHosts As Ptr)
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_knownhost_get Lib libssh2 (KnownHosts As Ptr, ByRef Store As Ptr, Prev As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_knownhost_init Lib libssh2 (Session As Ptr) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_knownhost_readfile Lib libssh2 (KnownHosts As Ptr, Filename As CString, Type As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_knownhost_readline Lib libssh2 (KnownHosts As Ptr, Line As Ptr, LineLength As Integer, Type As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_knownhost_writefile Lib libssh2 (KnownHosts As Ptr, SaveTo As CString, Type As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_knownhost_writeline Lib libssh2 (KnownHosts As Ptr, Host As Ptr, Buffer As Ptr, BufferLength As Integer, ByRef LengthWritten As Integer, Type As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_poll Lib libssh2 (Descriptors As Ptr, NumDescriptors As UInt32, TimeOut As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_poll_channel_read Lib libssh2 (Channel As Ptr, Extended As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_publickey_init Lib libssh2 (Session As Ptr) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_scp_recv2 Lib libssh2 (Session As Ptr, Path As CString, stat As Ptr) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_scp_send_ex Lib libssh2 (Session As Ptr, Path As CString, Mode As Integer, StreamLength As UInt32, mTime As Integer, aTime As Integer) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_abstract Lib libssh2 (Session As Ptr) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_banner_get Lib libssh2 (Session As Ptr) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_banner_set Lib libssh2 (Session As Ptr, Banner As CString) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_block_directions Lib libssh2 (Session As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_callback_set Lib libssh2 (Session As Ptr, Type As Integer, Callback As Ptr) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_disconnect_ex Lib libssh2 (Session As Ptr, Reason As DisconnectReason, Description As CString, Language As CString) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_flag Lib libssh2 (Session As Ptr, Flag As Integer, Value As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_free Lib libssh2 (Session As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_get_blocking Lib libssh2 (Session As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_get_timeout Lib libssh2 (Session As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_handshake Lib libssh2 (Session As Ptr, Socket As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_hostkey Lib libssh2 (Session As Ptr, ByRef Length As Integer, ByRef Type As Integer) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_init_ex Lib libssh2 (MyAlloc As Ptr, MyFree As Ptr, MyRealloc As Ptr, Abstract As Integer) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_last_errno Lib libssh2 (Session As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_last_error Lib libssh2 (Session As Ptr, ErrorMsg As Ptr, ByRef ErrorMsgLength As Integer, TakeOwnership As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_methods Lib libssh2 (Session As Ptr, MethodType As Integer) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_method_pref Lib libssh2 (Session As Ptr, MethodType As Integer, Prefs As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Sub libssh2_session_set_blocking Lib libssh2 (Session As Ptr, Blocking As Integer)
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_set_last_error Lib libssh2 (Session As Ptr, ErrorCode As Integer, ErrorMsg As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Sub libssh2_session_set_timeout Lib libssh2 (Session As Ptr, Timeout As Integer)
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_supported_algs Lib libssh2 (Session As Ptr, MethodType As Integer, ByRef Algs As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_close_handle Lib libssh2 (SFTP As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_fsync Lib libssh2 (SFTP As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_get_channel Lib libssh2 (SFTP As Ptr) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_init Lib libssh2 (Session As Ptr) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_last_error Lib libssh2 (SFTP As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_mkdir_ex Lib libssh2 (SFTP As Ptr, DirectoryName As Ptr, DirectoryNameLength As UInt32, Mode As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_open_ex Lib libssh2 (SFTP As Ptr, Filename As Ptr, FilenameLength As UInt32, Flags As UInt32, Mode As Integer, Type As Integer) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_read Lib libssh2 (SFTP As Ptr, Buffer As Ptr, BufferLength As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_readdir_ex Lib libssh2 (SFTP As Ptr, Buffer As Ptr, BufferLength As Integer, LongEntry As Ptr, LongEntryLength As Integer, ByRef Attribs As LIBSSH2_SFTP_ATTRIBUTES) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_rename_ex Lib libssh2 (SFTP As Ptr, SourceName As Ptr, SourceLength As UInt32, DestinationName As Ptr, DestinationLength As UInt32, Flags As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_rmdir_ex Lib libssh2 (SFTP As Ptr, Path As Ptr, PathLength As UInt32) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Sub libssh2_sftp_seek64 Lib libssh2 (SFTP As Ptr, Offset As UInt64)
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_shutdown Lib libssh2 (SFTP As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_tell64 Lib libssh2 (SFTP As Ptr) As UInt64
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_unlink_ex Lib libssh2 (SFTP As Ptr, FileName As Ptr, FileNameLength As UInt32) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_write Lib libssh2 (SFTP As Ptr, Buffer As Ptr, BufferLength As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_userauth_authenticated Lib libssh2 (Session As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_userauth_keyboard_interactive_ex Lib libssh2 (Session As Ptr, Username As Ptr, UsernameLength As UInt32, ResponseCallback As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_userauth_list Lib libssh2 (Session As Ptr, Username As Ptr, UsernameLength As Integer) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_userauth_password_ex Lib libssh2 (Session As Ptr, Username As CString, UsernameLength As UInt32, Password As CString, PasswordLength As UInt32, ChangePasswdCallback As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_userauth_publickey_fromfile_ex Lib libssh2 (Session As Ptr, Username As CString, UsernameLength As UInt32, PublicKey As CString, PrivateKey As CString, Passphrase As CString) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_userauth_publickey_frommemory Lib libssh2 (Session As Ptr, Username As CString, UsernameLength As Integer, PublicKey As Ptr, PublicKeyLength As Integer, PrivateKey As Ptr, PrivateKeyLength As Integer, Passphrase As CString) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_version Lib libssh2 (RequiredVersion As Integer) As CString
	#tag EndExternalMethod

	#tag Method, Flags = &h1
		Protected Function OpenChannel(Session As SSH.Session, Type As String = "session", WindowSize As UInt32 = LIBSSH2_CHANNEL_WINDOW_DEFAULT, PacketSize As UInt32 = LIBSSH2_CHANNEL_PACKET_DEFAULT, Message As String = "") As SSH.Channel
		  Return Channel.Open(Session, Type, WindowSize, PacketSize, Message)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function OpenChannel(URL As String, KnownHostList As FolderItem = Nil, AddHost As Boolean = False) As SSH.Channel
		  Dim d As Dictionary = ParseURL(URL)
		  Dim host, user, pass, scheme, path As String
		  host = d.Lookup("host", "")
		  user = d.Lookup("username", "")
		  pass = d.Lookup("password", "")
		  scheme = d.Lookup("scheme", "").Lowercase
		  path = d.Lookup("path", "")
		  Dim port As Integer = d.Lookup("port", 22)
		  
		  If scheme <> "ssh" Then Raise New RuntimeException
		  Dim Session As SSH.Session = Connect(host, port, user, pass, KnownHostList, AddHost)
		  If Not Session.IsConnected Or Not Session.IsAuthenticated Then Raise New SSHException(Session.LastError)
		  Return OpenChannel(Session)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function OpenShell(URL As String, KnownHostList As FolderItem = Nil, AddHost As Boolean = False) As SSH.Channel
		  Dim channel As SSH.Channel = OpenChannel(URL, KnownHostList, AddHost)
		  channel.RequestShell
		  channel.Session.Blocking = False
		  Return channel
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ParseURL(URL As String) As Dictionary
		  ' Pass a URI string to parse. e.g. http://user:password@www.example.com:8080/?foo=bar&bat=baz#Top
		  
		  Dim parsed As New Dictionary
		  Dim isIPv6 As Boolean
		  
		  If InStr(URL, "://") > 0 Then
		    Dim scheme As String = NthField(URL, "://", 1)
		    Parsed.Value("scheme") = URLDecode(scheme)
		    URL = URL.Replace(scheme + "://", "")
		  End If
		  
		  Dim auth As Integer = Instr(URL, "/")
		  Dim authority As String = URL
		  If auth > 0 Then authority = Left(URL, auth - 1)
		  If InStr(authority, "@") > 0 Then //  USER:PASS@Domain
		    Dim userinfo As String = NthField(authority, "@", 1)
		    authority = authority.Replace(userinfo + "@", "")
		    Dim u, p As String
		    u = NthField(userinfo, ":", 1)
		    p = NthField(userinfo, ":", 2)
		    parsed.Value("username") = URLDecode(u)
		    parsed.Value("password") = URLDecode(p)
		    URL = URL.Replace(userinfo + "@", "")
		  End If
		  
		  If Instr(URL, ":") > 0 And Left(URL, 1) <> "[" Then //  Domain:Port
		    Dim s As String = NthField(URL, ":", 2)
		    s = NthField(s, "?", 1)
		    If InStr(s, "/") > InStr(s, "?") Then
		      s = NthField(s, "?", 1)
		    Else
		      s = NthField(s, "/", 1)
		    End If
		    If Val(s) > 0 Then
		      Dim p As Integer = Val(s)
		      parsed.Value("port") = p
		      URL = URL.Replace(":" + Format(p, "######"), "")
		    End If
		  ElseIf Left(URL, 1) = "[" And InStr(URL, "]:") > 0 Then ' ipv6 with port
		    isIPv6 = True
		    Dim s As String = NthField(URL, "]:", 2)
		    s = NthField(s, "?", 1)
		    Dim p As Integer = Val(s)
		    parsed.Value("port") = p
		    URL = URL.Replace("]:" + Format(p, "######"), "]")
		  ElseIf Left(URL, 1) = "[" And InStr(URL, "]/") > 0 Then ' ipv6 with path
		    isIPv6 = True
		    'URL = URL.Replace("]/", "]")
		  End If
		  
		  If Instr(URL, "#") > 0 Then
		    Dim f As String = NthField(URL, "#", 2)  //    #fragment
		    parsed.Value("fragment") = f
		    URL = URL.Replace("#" + f, "")
		  End If
		  
		  Dim h As String = NthField(URL, "/", 1)  //  [sub.]domain.tld
		  parsed.Value("host") = URLDecode(h)
		  URL = URL.Replace(h, "")
		  
		  If InStr(URL, "?") > 0 Then
		    Dim p As String = NthField(URL, "?", 1) //    /foo/bar.php
		    parsed.Value("path") = URLDecode(p)
		    URL = URL.Replace(p + "?", "")
		    parsed.Value("arguments") = URL
		  Else
		    Dim p As String = URL.Trim
		    parsed.Value("path") = URLDecode(p)
		    URL = Replace(URL, p, "")
		    parsed.Value("arguments") = ""
		  End If
		  
		  Return parsed
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Poll(Extends Stream As SSH.SSHStream, Timeout As Integer = 1000) As Boolean
		  Dim descriptor As Ptr
		  Select Case Stream
		  Case IsA Channel
		    descriptor = Channel(Stream).Handle
		  Case IsA SFTPStream
		    descriptor = SFTPStream(Stream).Handle
		  Else
		    Raise New RuntimeException
		  End Select
		  Dim i As Integer = libssh2_poll(descriptor, 1, Timeout)
		  Return i > 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Put(Optional Session As SSH.Session, URL As String, Length As Integer, Mode As Integer, Overwrite As Boolean, KnownHostList As FolderItem = Nil, AddHost As Boolean = False) As SSH.SSHStream
		  Dim d As Dictionary = ParseURL(URL)
		  Dim host, user, pass, scheme, path As String
		  host = d.Lookup("host", "")
		  user = d.Lookup("username", "")
		  pass = d.Lookup("password", "")
		  scheme = d.Lookup("scheme", "").Lowercase
		  path = d.Lookup("path", "")
		  Dim port As Integer = d.Lookup("port", 22)
		  
		  If Session = Nil Then Session = Connect(host, port, user, pass)
		  Select Case scheme
		  Case "scp"
		    Return Channel.CreateSCP(Session, path, Mode, Length, 0, 0)
		  Case "sftp"
		    Dim sftp As New SFTPSession(Session)
		    Return sftp.Put(path, Overwrite, Mode)
		  Else
		    Raise New RuntimeException
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function URLDecode(Data As MemoryBlock) As String
		  Dim bs As New BinaryStream(Data)
		  Dim decoded As New MemoryBlock(0)
		  Dim dcbs As New BinaryStream(decoded)
		  Do Until bs.EOF
		    Dim char As String = bs.Read(1)
		    If AscB(char) = 37 Then ' %
		      dcbs.Write(ChrB(Val("&h" + bs.Read(2))))
		    Else
		      dcbs.Write(char)
		    End If
		  Loop
		  dcbs.Close
		  Return DefineEncoding(decoded, Encodings.UTF8)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Version() As String
		  If System.IsFunctionAvailable("libssh2_version", libssh2) Then Return libssh2_version(MIMIMUM_VERSION)
		End Function
	#tag EndMethod


	#tag Constant, Name = CHUNK_SIZE, Type = Double, Dynamic = False, Default = \"LIBSSH2_CHANNEL_PACKET_DEFAULT", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_CONNECTION_REFUSED, Type = Double, Dynamic = False, Default = \"-502", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_HOSTKEY_FAIL, Type = Double, Dynamic = False, Default = \"-510", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_HOSTKEY_MISMATCH, Type = Double, Dynamic = False, Default = \"-509", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_HOSTKEY_NOTFOUND, Type = Double, Dynamic = False, Default = \"-508", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_ILLEGAL_OPERATION, Type = Double, Dynamic = False, Default = \"-505", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_INIT_FAILED, Type = Double, Dynamic = False, Default = \"-500", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_INVALID_PORT, Type = Double, Dynamic = False, Default = \"-506", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_INVALID_SCHEME, Type = Double, Dynamic = False, Default = \"-511", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_LENGTH_REQUIRED, Type = Double, Dynamic = False, Default = \"-512", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_PORT_IN_USE, Type = Double, Dynamic = False, Default = \"-504", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_RESOLVE, Type = Double, Dynamic = False, Default = \"-503", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_SOCKET, Type = Double, Dynamic = False, Default = \"-507", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = libssh2, Type = String, Dynamic = False, Default = \"libssh2.so.1", Scope = Private
		#Tag Instance, Platform = Windows, Language = Default, Definition  = \"libssh2.dll"
		#Tag Instance, Platform = Linux, Language = Default, Definition  = \"libssh2.so.1"
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_CHANNEL_FLUSH_ALL, Type = Double, Dynamic = False, Default = \"-2", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_CHANNEL_FLUSH_EXTENDED_DATA, Type = Double, Dynamic = False, Default = \"-1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_CHANNEL_MINADJUST, Type = Double, Dynamic = False, Default = \"1024", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_CHANNEL_PACKET_DEFAULT, Type = Double, Dynamic = False, Default = \"16384", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_CHANNEL_WINDOW_DEFAULT, Type = Double, Dynamic = False, Default = \"262144", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_AGENT_PROTOCOL, Type = Double, Dynamic = False, Default = \" -42", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_ALLOC, Type = Double, Dynamic = False, Default = \"-6", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_BAD_SOCKET, Type = Double, Dynamic = False, Default = \" -45", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_BAD_USE, Type = Double, Dynamic = False, Default = \" -39", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_BANNER_NONE, Type = Double, Dynamic = False, Default = \"-2", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_BANNER_SEND, Type = Double, Dynamic = False, Default = \"-3", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_BUFFER_TOO_SMALL, Type = Double, Dynamic = False, Default = \"-38", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_CHANNEL_CLOSED, Type = Double, Dynamic = False, Default = \"-26", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_CHANNEL_EOF_SENT, Type = Double, Dynamic = False, Default = \"-27", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_CHANNEL_FAILURE, Type = Double, Dynamic = False, Default = \"-21", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_CHANNEL_OUTOFORDER, Type = Double, Dynamic = False, Default = \"-20", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_CHANNEL_PACKET_EXCEEDED, Type = Double, Dynamic = False, Default = \"-25", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_CHANNEL_REQUEST_DENIED, Type = Double, Dynamic = False, Default = \"-22", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_CHANNEL_UNKNOWN, Type = Double, Dynamic = False, Default = \"-23", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_CHANNEL_WINDOW_EXCEEDED, Type = Double, Dynamic = False, Default = \"-24", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_CHANNEL_WINDOW_FULL, Type = Double, Dynamic = False, Default = \" -47", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_COMPRESS, Type = Double, Dynamic = False, Default = \" -40", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_DECRYPT, Type = Double, Dynamic = False, Default = \"-12", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_EAGAIN, Type = Double, Dynamic = False, Default = \"-37", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_ENCRYPT, Type = Double, Dynamic = False, Default = \" -44", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_FILE, Type = Double, Dynamic = False, Default = \"-16", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_HOSTKEY_INIT, Type = Double, Dynamic = False, Default = \"-10", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_HOSTKEY_SIGN, Type = Double, Dynamic = False, Default = \"-11", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_INVAL, Type = Double, Dynamic = False, Default = \"-34", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_INVALID_MAC, Type = Double, Dynamic = False, Default = \"-4", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_INVALID_POLL_TYPE, Type = Double, Dynamic = False, Default = \"-35", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_KEX_FAILURE, Type = Double, Dynamic = False, Default = \"-5", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_KEY_EXCHANGE_FAILURE, Type = Double, Dynamic = False, Default = \"-8", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_KNOWN_HOSTS, Type = Double, Dynamic = False, Default = \" -46", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_METHOD_NONE, Type = Double, Dynamic = False, Default = \"-17", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_METHOD_NOT_SUPPORTED, Type = Double, Dynamic = False, Default = \"-33", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_NONE, Type = Double, Dynamic = False, Default = \"0", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_OUT_OF_BOUNDARY, Type = Double, Dynamic = False, Default = \" -41", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_PASSWORD_EXPIRED, Type = Double, Dynamic = False, Default = \"-15", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_PROTO, Type = Double, Dynamic = False, Default = \"-14", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_PUBLICKEY_PROTOCOL, Type = Double, Dynamic = False, Default = \"-36", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_PUBLICKEY_UNRECOGNIZED, Type = Double, Dynamic = False, Default = \"-18", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_PUBLICKEY_UNVERIFIED, Type = Double, Dynamic = False, Default = \"-19", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_REQUEST_DENIED, Type = Double, Dynamic = False, Default = \"-32", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_SCP_PROTOCOL, Type = Double, Dynamic = False, Default = \"-28", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_SFTP_PROTOCOL, Type = Double, Dynamic = False, Default = \"-31", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_SOCKET_DISCONNECT, Type = Double, Dynamic = False, Default = \"-13", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_SOCKET_NONE, Type = Double, Dynamic = False, Default = \"-1", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_SOCKET_RECV, Type = Double, Dynamic = False, Default = \" -43", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_SOCKET_SEND, Type = Double, Dynamic = False, Default = \"-7", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_SOCKET_TIMEOUT, Type = Double, Dynamic = False, Default = \"-30", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_TIMEOUT, Type = Double, Dynamic = False, Default = \"-9", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_ERROR_ZLIB, Type = Double, Dynamic = False, Default = \"-29", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_HOSTKEY_TYPE_DSS, Type = Double, Dynamic = False, Default = \"2", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_HOSTKEY_TYPE_RSA, Type = Double, Dynamic = False, Default = \"1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_HOSTKEY_TYPE_UNKNOWN, Type = Double, Dynamic = False, Default = \"0", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_KNOWNHOST_CHECK_FAILURE, Type = Double, Dynamic = False, Default = \"3", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_KNOWNHOST_CHECK_MATCH, Type = Double, Dynamic = False, Default = \"0", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_KNOWNHOST_CHECK_MISMATCH, Type = Double, Dynamic = False, Default = \"1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_KNOWNHOST_CHECK_NOTFOUND, Type = Double, Dynamic = False, Default = \"2", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SESSION_BLOCK_INBOUND, Type = Double, Dynamic = False, Default = \"&h0001", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SESSION_BLOCK_OUTBOUND, Type = Double, Dynamic = False, Default = \"&h0002", Scope = Private
	#tag EndConstant

	#tag Constant, Name = MIMIMUM_VERSION, Type = Double, Dynamic = False, Default = \"&h00010700", Scope = Private
	#tag EndConstant

	#tag Constant, Name = SSH_DISCONNECT_PROTOCOL_VERSION_NOT_SUPPORTED, Type = Double, Dynamic = False, Default = \"8", Scope = Private
	#tag EndConstant


	#tag Structure, Name = libssh2_agent_publickey, Flags = &h21
		Magic As UInt32
		  Node As Ptr
		  Blob As Ptr
		  BlobLength As UInt32
		Comment As Ptr
	#tag EndStructure

	#tag Structure, Name = libssh2_knownhost, Flags = &h21
		Magic As UInt32
		  Node As Ptr
		  Name As Ptr
		  Key As Ptr
		TypeMask As Integer
	#tag EndStructure

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

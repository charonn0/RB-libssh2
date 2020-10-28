#tag Module
Protected Module SSH
	#tag Method, Flags = &h21
		Private Function AbsolutePath_(Extends f As FolderItem) As String
		  #If RBVersion > 2019 Then
		    Return f.NativePath
		  #Else
		    Return f.AbsolutePath
		  #endif
		End Function
	#tag EndMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function channel_receive_window_adjust2 Lib libssh2 (Channel As Ptr, Adjustment As UInt32, Force As UInt8, ByRef Window As UInt32) As Int32
	#tag EndExternalMethod

	#tag Method, Flags = &h1
		Protected Function Connect(URL As String, KnownHostList As FolderItem = Nil, AddHost As Boolean = False) As SSH.Session
		  ' Attempts a new SSH connection to the server specified by the URL. Authenticates to the server
		  ' with the Username and Password also encoded in the URL.
		  ' If KnownHostList is specified then the server's fingerprint will be compared to it. If
		  ' AddHost is False and the fingerprint is not in the KnownHostList then the connection will
		  ' be aborted; if AddHost is True then the fingerprint is added to KnownHostList.
		  
		  Dim d As Dictionary = ParseURL(URL)
		  Dim host As String = d.Value("host")
		  Dim port As Integer = d.Lookup("port", 22)
		  Dim user As String = d.Lookup("username", "")
		  Dim pass As String = d.Lookup("password", "")
		  Return Connect(host, port, user, pass, KnownHostList, AddHost)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Connect(Address As String, Port As Integer, Username As String, KnownHostList As FolderItem = Nil, AddHost As Boolean = False) As SSH.Session
		  ' Attempts a new SSH connection to the server specified by the Address and Port parameters.
		  ' Authenticates to the server with the Username and a key managed by a local SSH Agent.
		  ' If KnownHostList is specified then the server's fingerprint will be compared to it. If
		  ' AddHost is False and the fingerprint is not in the KnownHostList then the connection will
		  ' be aborted; if AddHost is True then the fingerprint is added to KnownHostList.
		  
		  If Username = "" Then Raise New SSHException(ERR_USERNAME_REQUIRED)
		  
		  Dim session As New SSH.Session
		  If Not session.Connect(Address, Port) Then Return session
		  
		  If KnownHostList <> Nil Then
		    Dim kh As New KnownHosts(session, KnownHostList)
		    If Not session.CheckHost(kh, AddHost) Then Return session
		    If AddHost Then kh.Save(KnownHostList)
		  End If
		  
		  Dim agent As New SSH.Agent(session)
		  If Not agent.Connect() Then Return session
		  If Not agent.Refresh() Then Return session
		  Dim c As Integer = agent.Count - 1
		  For i As Integer = 0 To c
		    If session.SendCredentials(Username, agent, i) Then Exit For
		  Next
		  agent.Disconnect()
		  Return session
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Connect(Address As String, Port As Integer, Username As String, PublicKeyFile As FolderItem, PrivateKeyFile As FolderItem, PrivateKeyFilePassword As String, KnownHostList As FolderItem = Nil, AddHost As Boolean = False) As SSH.Session
		  ' Attempts a new SSH connection to the server specified by the Address and Port parameters.
		  ' Authenticates to the server as Username with the PublicKeyFile and PrivateKeyFile FolderItems.
		  ' If KnownHostList is specified then the server's fingerprint will be compared to it. If
		  ' AddHost is False and the fingerprint is not in the KnownHostList then the connection will
		  ' be aborted; if AddHost is True then the fingerprint is added to KnownHostList.
		  
		  If Username = "" Then Raise New SSHException(ERR_USERNAME_REQUIRED)
		  
		  Dim sess As New SSH.Session()
		  sess.Blocking = True
		  
		  If sess.Connect(Address, Port) Then
		    If KnownHostList <> Nil Then
		      Dim kh As New SSH.KnownHosts(sess, KnownHostList)
		      If Not sess.CheckHost(kh, AddHost) Then Return sess
		      If AddHost Then kh.Save(KnownHostList)
		    End If
		    Call sess.SendCredentials(Username, PublicKeyFile, PrivateKeyFile, PrivateKeyFilePassword)
		  End If
		  Return sess
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Connect(Address As String, Port As Integer, Username As String, PublicKey As MemoryBlock, PrivateKey As MemoryBlock, PrivateKeyPassword As String, KnownHostList As FolderItem = Nil, AddHost As Boolean = False) As SSH.Session
		  ' Attempts a new SSH connection to the server specified by the Address and Port parameters.
		  ' Authenticates to the server as Username with the PublicKey and PrivateKey MemoryBlocks.
		  ' If KnownHostList is specified then the server's fingerprint will be compared to it. If
		  ' AddHost is False and the fingerprint is not in the KnownHostList then the connection will
		  ' be aborted; if AddHost is True then the fingerprint is added to KnownHostList.
		  
		  If Username = "" Then Raise New SSHException(ERR_USERNAME_REQUIRED)
		  
		  Dim sess As New SSH.Session()
		  sess.Blocking = True
		  If sess.Connect(Address, Port) Then
		    If KnownHostList <> Nil Then
		      Dim kh As New SSH.KnownHosts(sess, KnownHostList)
		      If Not sess.CheckHost(kh, AddHost) Then Return sess
		      If AddHost Then kh.Save(KnownHostList)
		    End If
		    Call sess.SendCredentials(Username, PublicKey, PrivateKey, PrivateKeyPassword)
		  End If
		  Return sess
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Connect(Address As String, Port As Integer, Username As String, Password As String, KnownHostList As FolderItem = Nil, AddHost As Boolean = False) As SSH.Session
		  ' Attempts a new SSH connection to the server specified by the Address and Port parameters.
		  ' Authenticates to the server with the Username and Password.
		  ' If KnownHostList is specified then the server's fingerprint will be compared to it. If
		  ' AddHost is False and the fingerprint is not in the KnownHostList then the connection will
		  ' be aborted; if AddHost is True then the fingerprint is added to KnownHostList.
		  
		  If Username = "" Then Raise New SSHException(ERR_USERNAME_REQUIRED)
		  
		  Dim sess As New SSH.Session()
		  sess.Blocking = True
		  If sess.Connect(Address, Port) Then
		    If KnownHostList <> Nil Then
		      Dim kh As New SSH.KnownHosts(sess, KnownHostList)
		      If Not sess.CheckHost(kh, AddHost) Then Return sess
		      If AddHost Then kh.Save(KnownHostList)
		    End If
		    If Password = "" Then
		      ' in the unlikely event that the server allows the user to log on with no password, calling
		      ' GetAuthenticationMethods() will actually authenticate the user.
		      Call sess.GetAuthenticationMethods(Username)
		    Else
		      Call sess.SendCredentials(Username, Password)
		    End If
		  End If
		  Return sess
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function ErrorName(ErrorNumber As Integer) As String
		  ' Returns the name for the code returned from libssh2
		  
		  Select Case ErrorNumber
		  Case LIBSSH2_ERROR_NONE
		    Return "LIBSSH2_ERROR_NONE"
		  Case LIBSSH2_ERROR_SOCKET_NONE
		    Return "LIBSSH2_ERROR_SOCKET_NONE"
		  Case LIBSSH2_ERROR_BANNER_NONE
		    Return "LIBSSH2_ERROR_BANNER_NONE"
		  Case LIBSSH2_ERROR_BANNER_SEND
		    Return "LIBSSH2_ERROR_BANNER_SEND"
		  Case LIBSSH2_ERROR_INVALID_MAC
		    Return "LIBSSH2_ERROR_INVALID_MAC"
		  Case LIBSSH2_ERROR_KEX_FAILURE
		    Return "LIBSSH2_ERROR_KEX_FAILURE"
		  Case LIBSSH2_ERROR_ALLOC
		    Return "LIBSSH2_ERROR_ALLOC"
		  Case LIBSSH2_ERROR_SOCKET_SEND
		    Return "LIBSSH2_ERROR_SOCKET_SEND"
		  Case LIBSSH2_ERROR_KEY_EXCHANGE_FAILURE
		    Return "LIBSSH2_ERROR_KEY_EXCHANGE_FAILURE"
		  Case LIBSSH2_ERROR_TIMEOUT
		    Return "LIBSSH2_ERROR_TIMEOUT"
		  Case LIBSSH2_ERROR_HOSTKEY_INIT
		    Return "LIBSSH2_ERROR_HOSTKEY_INIT"
		  Case LIBSSH2_ERROR_HOSTKEY_SIGN
		    Return "LIBSSH2_ERROR_HOSTKEY_SIGN"
		  Case LIBSSH2_ERROR_DECRYPT
		    Return "LIBSSH2_ERROR_DECRYPT"
		  Case LIBSSH2_ERROR_SOCKET_DISCONNECT
		    Return "LIBSSH2_ERROR_SOCKET_DISCONNECT"
		  Case LIBSSH2_ERROR_PROTO
		    Return "LIBSSH2_ERROR_PROTO"
		  Case LIBSSH2_ERROR_PASSWORD_EXPIRED
		    Return "LIBSSH2_ERROR_PASSWORD_EXPIRED"
		  Case LIBSSH2_ERROR_FILE
		    Return "LIBSSH2_ERROR_FILE"
		  Case LIBSSH2_ERROR_METHOD_NONE
		    Return "LIBSSH2_ERROR_METHOD_NONE"
		  Case LIBSSH2_ERROR_PUBLICKEY_UNRECOGNIZED
		    Return "LIBSSH2_ERROR_PUBLICKEY_UNRECOGNIZED"
		  Case LIBSSH2_ERROR_PUBLICKEY_UNVERIFIED
		    Return "LIBSSH2_ERROR_PUBLICKEY_UNVERIFIED"
		  Case LIBSSH2_ERROR_CHANNEL_OUTOFORDER
		    Return "LIBSSH2_ERROR_CHANNEL_OUTOFORDER"
		  Case LIBSSH2_ERROR_CHANNEL_FAILURE
		    Return "LIBSSH2_ERROR_CHANNEL_FAILURE"
		  Case LIBSSH2_ERROR_CHANNEL_REQUEST_DENIED
		    Return "LIBSSH2_ERROR_CHANNEL_REQUEST_DENIED"
		  Case LIBSSH2_ERROR_CHANNEL_UNKNOWN
		    Return "LIBSSH2_ERROR_CHANNEL_UNKNOWN"
		  Case LIBSSH2_ERROR_CHANNEL_WINDOW_EXCEEDED
		    Return "LIBSSH2_ERROR_CHANNEL_WINDOW_EXCEEDED"
		  Case LIBSSH2_ERROR_CHANNEL_PACKET_EXCEEDED
		    Return "LIBSSH2_ERROR_CHANNEL_PACKET_EXCEEDED"
		  Case LIBSSH2_ERROR_CHANNEL_CLOSED
		    Return "LIBSSH2_ERROR_CHANNEL_CLOSED"
		  Case LIBSSH2_ERROR_CHANNEL_EOF_SENT
		    Return "LIBSSH2_ERROR_CHANNEL_EOF_SENT"
		  Case LIBSSH2_ERROR_SCP_PROTOCOL
		    Return "LIBSSH2_ERROR_SCP_PROTOCOL"
		  Case LIBSSH2_ERROR_ZLIB
		    Return "LIBSSH2_ERROR_ZLIB"
		  Case LIBSSH2_ERROR_SOCKET_TIMEOUT
		    Return "LIBSSH2_ERROR_SOCKET_TIMEOUT"
		  Case LIBSSH2_ERROR_SFTP_PROTOCOL
		    Return "LIBSSH2_ERROR_SFTP_PROTOCOL"
		  Case LIBSSH2_ERROR_REQUEST_DENIED
		    Return "LIBSSH2_ERROR_REQUEST_DENIED"
		  Case LIBSSH2_ERROR_METHOD_NOT_SUPPORTED
		    Return "LIBSSH2_ERROR_METHOD_NOT_SUPPORTED"
		  Case LIBSSH2_ERROR_INVAL
		    Return "LIBSSH2_ERROR_INVAL"
		  Case LIBSSH2_ERROR_INVALID_POLL_TYPE
		    Return "LIBSSH2_ERROR_INVALID_POLL_TYPE"
		  Case LIBSSH2_ERROR_PUBLICKEY_PROTOCOL
		    Return "LIBSSH2_ERROR_PUBLICKEY_PROTOCOL"
		  Case LIBSSH2_ERROR_EAGAIN
		    Return "LIBSSH2_ERROR_EAGAIN"
		  Case ERR_CONNECTION_REFUSED
		    Return "ERR_CONNECTION_REFUSED"
		  Case LIBSSH2_ERROR_BUFFER_TOO_SMALL
		    Return "LIBSSH2_ERROR_BUFFER_TOO_SMALL"
		  Case LIBSSH2_ERROR_BUFFER_TOO_SMALL
		    Return "LIBSSH2_ERROR_BUFFER_TOO_SMALL"
		  Case LIBSSH2_ERROR_BAD_USE
		    Return "LIBSSH2_ERROR_BAD_USE"
		  Case LIBSSH2_ERROR_COMPRESS
		    Return "LIBSSH2_ERROR_COMPRESS"
		  Case LIBSSH2_ERROR_OUT_OF_BOUNDARY
		    Return "LIBSSH2_ERROR_OUT_OF_BOUNDARY"
		  Case LIBSSH2_ERROR_AGENT_PROTOCOL
		    Return "LIBSSH2_ERROR_AGENT_PROTOCOL"
		  Case LIBSSH2_ERROR_SOCKET_RECV
		    Return "LIBSSH2_ERROR_SOCKET_RECV"
		  Case LIBSSH2_ERROR_ENCRYPT
		    Return "LIBSSH2_ERROR_ENCRYPT"
		  Case LIBSSH2_ERROR_BAD_SOCKET
		    Return "LIBSSH2_ERROR_BAD_SOCKET"
		  Case LIBSSH2_ERROR_KNOWN_HOSTS
		    Return "LIBSSH2_ERROR_KNOWN_HOSTS"
		  Case LIBSSH2_ERROR_CHANNEL_WINDOW_FULL
		    Return "LIBSSH2_ERROR_CHANNEL_WINDOW_FULL"
		  Case ERR_ILLEGAL_OPERATION
		    Return "ERR_ILLEGAL_OPERATION"
		  Case ERR_INVALID_PORT
		    Return "ERR_INVALID_PORT"
		  Case ERR_PORT_IN_USE
		    Return "ERR_PORT_IN_USE"
		  Case ERR_RESOLVE
		    Return "ERR_RESOLVE"
		  Case ERR_SOCKET
		    Return "ERR_SOCKET"
		  Case ERR_HOSTKEY_NOTFOUND
		    Return "ERR_HOSTKEY_NOTFOUND"
		  Case ERR_HOSTKEY_MISMATCH
		    Return "ERR_HOSTKEY_MISMATCH"
		  Case ERR_HOSTKEY_NOTFOUND
		    Return "ERR_HOSTKEY_NOTFOUND"
		  Case ERR_INVALID_SCHEME
		    Return "ERR_INVALID_SCHEME"
		  Case ERR_LENGTH_REQUIRED
		    Return "ERR_LENGTH_REQUIRED"
		  Case ERR_SESSION_MISMATCH
		    Return "ERR_SESSION_MISMATCH"
		  Case ERR_INVALID_INDEX
		    Return "ERR_INVALID_INDEX"
		  Case ERR_USERNAME_REQUIRED
		    Return "ERR_USERNAME_REQUIRED"
		  Case ERR_TIMEOUT_ELAPSED
		    Return "ERR_TIMEOUT_ELAPSED"
		  Case ERR_NOT_AUTHENTICATED
		    Return "ERR_NOT_AUTHENTICATED"
		  Case ERR_TOO_MANY_TRANSFERS
		    Return "ERR_TOO_MANY_TRANSFERS"
		  Else
		    Return "Unknown error number."
		    
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Execute(Optional Session As SSH.Session, Command As String) As SSH.SSHStream
		  ' Executes a shell command on the remote machine. Returns a SSHStream from which you
		  ' Read() the standard output stream of the executing command.
		  
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
		  ' Prepares a file download over SCP or SFTP. Returns a SSHStream that you
		  ' Read() the download from.
		  
		  Dim d As Dictionary = ParseURL(URL)
		  Dim host, user, pass, scheme, path As String
		  host = d.Lookup("host", "")
		  user = d.Lookup("username", "")
		  pass = d.Lookup("password", "")
		  scheme = d.Lookup("scheme", "")
		  path = d.Lookup("path", "")
		  Dim port As Integer = d.Lookup("port", 22)
		  
		  If Session = Nil Then Session = Connect(host, port, user, pass)
		  Select Case scheme
		  Case "scp"
		    Return New SCPStream(Session, path)
		  Case "sftp"
		    Dim sftp As New SFTPSession(Session)
		    Return sftp.Get(path)
		  Else
		    Raise New SSHException(ERR_INVALID_SCHEME)
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function IsAvailable() As Boolean
		  ' Returns True if libssh2 is available at runtime.
		  
		  Static avail As Boolean
		  If Not avail Then avail = System.IsFunctionAvailable("libssh2_session_init_ex", libssh2)
		  Return avail
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function IsCompressionAvailable() As Boolean
		  ' Returns True if zlib is available at runtime.
		  
		  #If TargetWin32
		    Const zlib1 = "zlib1.dll"
		  #ElseIf TargetMacOS
		    Const zlib1 = "/usr/lib/libz.dylib"
		  #Else
		    Const zlib1 = "libz.so.1"
		  #endif
		  
		  Static avail As Boolean = System.IsFunctionAvailable("zlibVersion", libssh2) Or System.IsFunctionAvailable("zlibVersion", zlib1)
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
		Private Soft Declare Function libssh2_agent_get_identity_path Lib libssh2 (Agent As Ptr) As CString
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_agent_init Lib libssh2 (Session As Ptr) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_agent_list_identities Lib libssh2 (Agent As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Sub libssh2_agent_set_identity_path Lib libssh2 (Agent As Ptr, Path As CString)
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
		Private Soft Declare Function libssh2_channel_handle_extended_data2 Lib libssh2 (Channel As Ptr, IgnoreMode As Integer) As Integer
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
		Private Soft Declare Function libssh2_channel_request_auth_agent Lib libssh2 (Channel As Ptr) As Int32
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
		Private Soft Declare Function libssh2_channel_wait_eof Lib libssh2 (Channel As Ptr) As Integer
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
		Private Soft Declare Function libssh2_poll Lib libssh2 (ByRef Descriptor As LIBSSH2_POLLFD, NumDescriptors As UInt32, TimeOut As Integer) As Integer
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
		Private Soft Declare Function libssh2_session_methods Lib libssh2 (Session As Ptr, Type As Int32) As CString
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_session_method_pref Lib libssh2 (Session As Ptr, MethodType As Int32, Prefs As Ptr) As Int32
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
		Private Soft Declare Function libssh2_session_supported_algs Lib libssh2 (Session As Ptr, MethodType As Int32, ByRef Algs As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_close_handle Lib libssh2 (SFTP As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_fstat_ex Lib libssh2 (Session As Ptr, ByRef Attribs As LIBSSH2_SFTP_ATTRIBUTES, SetStat As Int32) As Int32
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
		Private Soft Declare Function libssh2_sftp_stat_ex Lib libssh2 (Session As Ptr, Path As Ptr, PathLength As Int32, StatType As Int32, ByRef Attribs As LIBSSH2_SFTP_ATTRIBUTES) As Int32
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_sftp_symlink_ex Lib libssh2 (SFTP As Ptr, Path As Ptr, PathLength As UInt32, Target As Ptr, TargetLength As UInt32, LinkType As Integer) As Int32
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
		Private Soft Declare Sub libssh2_trace Lib libssh2 (Session As Ptr, Bitmask As Int32)
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_trace_sethandler Lib libssh2 (Session As Ptr, Context As Integer, TraceHandler As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_userauth_authenticated Lib libssh2 (Session As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function libssh2_userauth_keyboard_interactive_ex Lib libssh2 (Session As Ptr, Username As CString, UsernameLength As UInt32, ResponseCallback As Ptr) As Integer
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
		  ' Opens a new SSH.Channel over the specified SSH.Session.
		  
		  Return Channel.Open(Session, Type, WindowSize, PacketSize, Message)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function OpenChannel(URL As String, KnownHostList As FolderItem = Nil, AddHost As Boolean = False) As SSH.Channel
		  ' Opens a new SSH.Channel to the server specified by the URL parameter.
		  ' e.g. "ssh://user:pass@ssh.example.com:2222/"
		  
		  Dim d As Dictionary = ParseURL(URL)
		  Dim host, user, pass, scheme, path As String
		  host = d.Lookup("host", "")
		  user = d.Lookup("username", "")
		  pass = d.Lookup("password", "")
		  scheme = d.Lookup("scheme", "")
		  path = d.Lookup("path", "")
		  Dim port As Integer = d.Lookup("port", 22)
		  
		  If scheme <> "ssh" Then Raise New SSHException(ERR_INVALID_SCHEME)
		  Dim Session As SSH.Session = Connect(host, port, user, pass, KnownHostList, AddHost)
		  If Not Session.IsConnected Or Not Session.IsAuthenticated Then Raise New SSHException(Session.LastError)
		  Return OpenChannel(Session)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ParseURL(URL As String) As Dictionary
		  ' Pass a URI string to parse. e.g. http://user:password@www.example.com:8080/?foo=bar&bat=baz#Top
		  
		  Dim parsed As New Dictionary
		  Dim tmp As String
		  Dim pos As Integer
		  
		  If InStr(URL, "://") > 0 Then
		    tmp = NthField(URL, "://", 1)
		    Parsed.Value("scheme") = URLDecode(tmp).Lowercase
		    URL = URL.Replace(tmp + "://", "")
		  End If
		  
		  pos = Instr(URL, "/")
		  If pos > 0 Then tmp = Left(URL, pos - 1)
		  If InStr(tmp, "@") > 0 Then //  USER:PASS@Domain
		    Dim userinfo As String = NthField(tmp, "@", 1)
		    Dim u, p As String
		    u = NthField(userinfo, ":", 1)
		    p = NthField(userinfo, ":", 2)
		    parsed.Value("username") = URLDecode(u)
		    parsed.Value("password") = URLDecode(p)
		    URL = URL.Replace(userinfo + "@", "")
		  End If
		  
		  If Instr(URL, ":") > 0 And Left(URL, 1) <> "[" Then //  Domain:Port
		    tmp = NthField(URL, ":", 2)
		    tmp = NthField(tmp, "?", 1)
		    If InStr(tmp, "/") > InStr(tmp, "?") Then
		      tmp = NthField(tmp, "?", 1)
		    Else
		      tmp = NthField(tmp, "/", 1)
		    End If
		    If Val(tmp) > 0 Then
		      Dim p As Integer = Val(tmp)
		      parsed.Value("port") = p
		      URL = URL.Replace(":" + Format(p, "######"), "")
		    End If
		  ElseIf Left(URL, 1) = "[" And InStr(URL, "]:") > 0 Then ' ipv6 with port
		    tmp = NthField(URL, "]:", 2)
		    tmp = NthField(tmp, "?", 1)
		    Dim p As Integer = Val(tmp)
		    parsed.Value("port") = p
		    URL = URL.Replace("]:" + Format(p, "######"), "]")
		  End If
		  
		  If Instr(URL, "#") > 0 Then
		    tmp = NthField(URL, "#", 2)  //    #fragment
		    parsed.Value("fragment") = tmp
		    URL = URL.Replace("#" + tmp, "")
		  End If
		  
		  tmp = NthField(URL, "/", 1)  //  [sub.]domain.tld
		  parsed.Value("host") = URLDecode(tmp)
		  URL = URL.Replace(tmp, "")
		  
		  If InStr(URL, "?") > 0 Then
		    tmp = NthField(URL, "?", 1) //    /foo/bar.php
		    parsed.Value("path") = URLDecode(tmp)
		    URL = URL.Replace(tmp + "?", "")
		    parsed.Value("arguments") = URL
		  Else
		    tmp = URL.Trim
		    parsed.Value("path") = URLDecode(tmp)
		    URL = Replace(URL, tmp, "")
		    parsed.Value("arguments") = ""
		  End If
		  
		  Return parsed
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function PermissionsToMode(p As Permissions) As UInt32
		  Const TGEXEC = &o00010
		  Const TGREAD = &o00040
		  Const TGWRITE = &o00020
		  Const TOEXEC = &o00001
		  Const TOREAD = &o00004
		  Const TOWRITE = &o00002
		  Const TSGID = &o02000
		  Const TSUID = &o04000
		  Const TSVTX = &o01000
		  Const TUEXEC = &o00100
		  Const TUREAD = &o00400
		  Const TUWRITE = &o00200
		  
		  Dim mask As UInt32
		  If p.GroupExecute Then mask = mask Or TGEXEC
		  If p.GroupRead Then mask = mask Or TGREAD
		  If p.GroupWrite Then mask = mask Or TGWRITE
		  
		  If p.OwnerExecute Then mask = mask Or TUEXEC
		  If p.OwnerRead Then mask = mask Or TUREAD
		  If p.OwnerWrite Then mask = mask Or TUWRITE
		  
		  If p.OthersExecute Then mask = mask Or TOEXEC
		  If p.OthersRead Then mask = mask Or TOREAD
		  If p.OthersWrite Then mask = mask Or TOWRITE
		  
		  Return mask
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Put(Optional Session As SSH.Session, URL As String, Length As UInt32 = 0, Overwrite As Boolean = False) As SSH.SSHStream
		  ' Prepares a file upload over SCP or SFTP. Returns a SSHStream that you
		  ' Write() the upload to.
		  
		  Dim d As Dictionary = ParseURL(URL)
		  Dim host, user, pass, scheme, path As String
		  host = d.Lookup("host", "")
		  user = d.Lookup("username", "")
		  pass = d.Lookup("password", "")
		  scheme = d.Lookup("scheme", "")
		  path = d.Lookup("path", "")
		  Dim port As Integer = d.Lookup("port", 22)
		  
		  If Session = Nil Then Session = Connect(host, port, user, pass)
		  Select Case scheme
		  Case "scp"
		    If Length <= 0 Then Raise New SSHException(ERR_LENGTH_REQUIRED)
		    Return New SCPStream(Session, path, &o644, Length, 0, 0)
		  Case "sftp"
		    Dim sftp As New SFTPSession(Session)
		    Return sftp.Put(path, Overwrite, &o644)
		  Else
		    Raise New SSHException(ERR_INVALID_SCHEME)
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function SFTPErrorName(SFTPStatusCode As Int32) As String
		  ' Returns the name for the code returned from SFTPSession.LastStatusCode
		  
		  Select Case SFTPStatusCode
		  Case LIBSSH2_FX_BAD_MESSAGE
		    Return "LIBSSH2_FX_BAD_MESSAGE"
		  Case LIBSSH2_FX_CONNECTION_LOST
		    Return "LIBSSH2_FX_CONNECTION_LOST"
		  Case LIBSSH2_FX_DIR_NOT_EMPTY
		    Return "LIBSSH2_FX_DIR_NOT_EMPTY"
		  Case LIBSSH2_FX_EOF
		    Return "LIBSSH2_FX_EOF"
		  Case LIBSSH2_FX_FAILURE
		    Return "LIBSSH2_FX_FAILURE"
		  Case LIBSSH2_FX_FILE_ALREADY_EXISTS
		    Return "LIBSSH2_FX_FILE_ALREADY_EXISTS"
		  Case LIBSSH2_FX_INVALID_FILENAME
		    Return "LIBSSH2_FX_INVALID_FILENAME"
		  Case LIBSSH2_FX_INVALID_HANDLE
		    Return "LIBSSH2_FX_INVALID_HANDLE"
		  Case LIBSSH2_FX_LINK_LOOP
		    Return "LIBSSH2_FX_LINK_LOOP"
		  Case LIBSSH2_FX_LOCK_CONFLICT
		    Return "LIBSSH2_FX_LOCK_CONFLICT"
		  Case LIBSSH2_FX_NOT_A_DIRECTORY
		    Return "LIBSSH2_FX_NOT_A_DIRECTORY"
		  Case LIBSSH2_FX_NO_CONNECTION
		    Return "LIBSSH2_FX_NO_CONNECTION"
		  Case LIBSSH2_FX_NO_MEDIA
		    Return "LIBSSH2_FX_NO_MEDIA"
		  Case LIBSSH2_FX_NO_SPACE_ON_FILESYSTEM
		    Return "LIBSSH2_FX_NO_SPACE_ON_FILESYSTEM"
		  Case LIBSSH2_FX_NO_SUCH_FILE
		    Return "LIBSSH2_FX_NO_SUCH_FILE"
		  Case LIBSSH2_FX_NO_SUCH_PATH
		    Return "LIBSSH2_FX_NO_SUCH_PATH"
		  Case LIBSSH2_FX_OK
		    Return "LIBSSH2_FX_OK"
		  Case LIBSSH2_FX_OP_UNSUPPORTED
		    Return "LIBSSH2_FX_OP_UNSUPPORTED"
		  Case LIBSSH2_FX_PERMISSION_DENIED
		    Return "LIBSSH2_FX_PERMISSION_DENIED"
		  Case LIBSSH2_FX_QUOTA_EXCEEDED
		    Return "LIBSSH2_FX_QUOTA_EXCEEDED"
		  Case LIBSSH2_FX_UNKNOWN_PRINCIPAL
		    Return "LIBSSH2_FX_UNKNOWN_PRINCIPAL"
		  Case LIBSSH2_FX_WRITE_PROTECT
		    Return "LIBSSH2_FX_WRITE_PROTECT"
		  Else
		    Return "Unknown SFTP error code: " + Str(SFTPStatusCode)
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function time_t(d As Date) As Integer
		  Dim epoch As New Date(1970, 1, 1, 0, 0, 0, 0.0) 'UNIX epoch
		  Return d.TotalSeconds - epoch.TotalSeconds
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function time_t(Count As Integer) As Date
		  Dim d As New Date(1970, 1, 1, 0, 0, 0, 0.0) 'UNIX epoch
		  d.TotalSeconds = d.TotalSeconds + Count
		  Return d
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
		  ' Returns a string containing the version number, for example "1.9.0".
		  
		  If System.IsFunctionAvailable("libssh2_version", libssh2) Then Return libssh2_version(0)
		End Function
	#tag EndMethod


	#tag Constant, Name = CHUNK_SIZE, Type = Double, Dynamic = False, Default = \"LIBSSH2_CHANNEL_PACKET_DEFAULT", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_CONNECTION_REFUSED, Type = Double, Dynamic = False, Default = \"-102", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_HOSTKEY_MISMATCH, Type = Double, Dynamic = False, Default = \"-503", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_HOSTKEY_NOTFOUND, Type = Double, Dynamic = False, Default = \"-502", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_ILLEGAL_OPERATION, Type = Double, Dynamic = False, Default = \"-106", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_INIT_FAILED, Type = Double, Dynamic = False, Default = \"-500", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_INVALID_INDEX, Type = Double, Dynamic = False, Default = \"-507", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_INVALID_PORT, Type = Double, Dynamic = False, Default = \"-107", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_INVALID_SCHEME, Type = Double, Dynamic = False, Default = \"-504", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_LENGTH_REQUIRED, Type = Double, Dynamic = False, Default = \"-505", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_NOT_AUTHENTICATED, Type = Double, Dynamic = False, Default = \"-510", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_PORT_IN_USE, Type = Double, Dynamic = False, Default = \"-105", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_RESOLVE, Type = Double, Dynamic = False, Default = \"-103", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_SESSION_MISMATCH, Type = Double, Dynamic = False, Default = \"-506", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_SOCKET, Type = Double, Dynamic = False, Default = \"-501", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_TIMEOUT_ELAPSED, Type = Double, Dynamic = False, Default = \"-509", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_TOO_MANY_TRANSFERS, Type = Double, Dynamic = False, Default = \"-511", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_USERNAME_REQUIRED, Type = Double, Dynamic = False, Default = \"-508", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = libssh2, Type = String, Dynamic = False, Default = \"libssh2.so.1", Scope = Private
		#Tag Instance, Platform = Windows, Language = Default, Definition  = \"libssh2.dll"
		#Tag Instance, Platform = Linux, Language = Default, Definition  = \"libssh2.so.1"
		#Tag Instance, Platform = Mac OS, Language = Default, Definition  = \"@executable_path/../Frameworks/libssh2.1.dylib"
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

	#tag Constant, Name = LIBSSH2_FXF_APPEND, Type = Double, Dynamic = False, Default = \"&h00000004", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FXF_CREAT, Type = Double, Dynamic = False, Default = \"&h00000008", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FXF_EXCL, Type = Double, Dynamic = False, Default = \"&h00000020", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FXF_READ, Type = Double, Dynamic = False, Default = \"&h00000001", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FXF_TRUNC, Type = Double, Dynamic = False, Default = \"&h00000010", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FXF_WRITE, Type = Double, Dynamic = False, Default = \"&h00000002", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_BAD_MESSAGE, Type = Double, Dynamic = False, Default = \"5", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_CONNECTION_LOST, Type = Double, Dynamic = False, Default = \"7", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_DIR_NOT_EMPTY, Type = Double, Dynamic = False, Default = \"18", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_EOF, Type = Double, Dynamic = False, Default = \"1", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_FAILURE, Type = Double, Dynamic = False, Default = \"4", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_FILE_ALREADY_EXISTS, Type = Double, Dynamic = False, Default = \"11", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_INVALID_FILENAME, Type = Double, Dynamic = False, Default = \"20", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_INVALID_HANDLE, Type = Double, Dynamic = False, Default = \"9", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_LINK_LOOP, Type = Double, Dynamic = False, Default = \"21", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_LOCK_CONFLICT, Type = Double, Dynamic = False, Default = \"17", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_NOT_A_DIRECTORY, Type = Double, Dynamic = False, Default = \"19", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_NO_CONNECTION, Type = Double, Dynamic = False, Default = \"6", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_NO_MEDIA, Type = Double, Dynamic = False, Default = \"13", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_NO_SPACE_ON_FILESYSTEM, Type = Double, Dynamic = False, Default = \"14", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_NO_SUCH_FILE, Type = Double, Dynamic = False, Default = \"2", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_NO_SUCH_PATH, Type = Double, Dynamic = False, Default = \"10", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_OK, Type = Double, Dynamic = False, Default = \"0", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_OP_UNSUPPORTED, Type = Double, Dynamic = False, Default = \"8", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_PERMISSION_DENIED, Type = Double, Dynamic = False, Default = \"3", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_QUOTA_EXCEEDED, Type = Double, Dynamic = False, Default = \"15", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_UNKNOWN_PRINCIPAL, Type = Double, Dynamic = False, Default = \"16", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_WRITE_PROTECT, Type = Double, Dynamic = False, Default = \"12", Scope = Protected
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

	#tag Constant, Name = LIBSSH2_POLLFD_CHANNEL, Type = Double, Dynamic = False, Default = \"2", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_POLLFD_CHANNEL_CLOSED, Type = Double, Dynamic = False, Default = \"&h0080", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_POLLFD_LISTENER, Type = Double, Dynamic = False, Default = \"3", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_POLLFD_LISTENER_CLOSED, Type = Double, Dynamic = False, Default = \"&h0080", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_POLLFD_POLLERR, Type = Double, Dynamic = False, Default = \"&h0008", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_POLLFD_POLLEX, Type = Double, Dynamic = False, Default = \"&h0040", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_POLLFD_POLLEXT, Type = Double, Dynamic = False, Default = \"&h0002", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_POLLFD_POLLHUP, Type = Double, Dynamic = False, Default = \"&h0010", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_POLLFD_POLLIN, Type = Double, Dynamic = False, Default = \"&h0001", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_POLLFD_POLLNVAL, Type = Double, Dynamic = False, Default = \"&h0020", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_POLLFD_POLLOUT, Type = Double, Dynamic = False, Default = \"&h0004", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_POLLFD_POLLPRI, Type = Double, Dynamic = False, Default = \"&h0002", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_POLLFD_SESSION_CLOSED, Type = Double, Dynamic = False, Default = \"&h0010", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_POLLFD_SOCKET, Type = Double, Dynamic = False, Default = \"1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SESSION_BLOCK_INBOUND, Type = Double, Dynamic = False, Default = \"&h0001", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SESSION_BLOCK_OUTBOUND, Type = Double, Dynamic = False, Default = \"&h0002", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_ATTR_ACMODTIME, Type = Double, Dynamic = False, Default = \"8", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_ATTR_EXTENDED, Type = Double, Dynamic = False, Default = \"&h80000000", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_ATTR_PERMISSIONS, Type = Double, Dynamic = False, Default = \"4", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_ATTR_SIZE, Type = Double, Dynamic = False, Default = \"1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_ATTR_UIDGID, Type = Double, Dynamic = False, Default = \"2", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_OPENDIR, Type = Double, Dynamic = False, Default = \"1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_OPENFILE, Type = Double, Dynamic = False, Default = \"0", Scope = Private
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

	#tag Structure, Name = LIBSSH2_POLLFD, Flags = &h21, Attributes = \"StructureAlignment \x3D 8"
		Type As UInt8
		  Descriptor As Ptr
		  Events As UInt32
		REvents As UInt32
	#tag EndStructure

	#tag Structure, Name = LIBSSH2_SFTP_ATTRIBUTES, Flags = &h21, Attributes = \"StructureAlignment \x3D 8"
		Flags As UInt32
		  FileSize As UInt64
		  UID As UInt32
		  GID As UInt32
		  Perms As UInt32
		  ATime As UInt32
		MTime As UInt32
	#tag EndStructure


	#tag Enum, Name = AlgorithmType, Flags = &h1
		KeyExchange=0
		  PublicKey=1
		  ClientSideCipher=2
		  ServerSideCipher=3
		  ClientSideMAC=4
		  ServerSideMAC=5
		  ClientSideCompression=6
		  ServerSideCompression=7
		  ClientLanguage=8
		ServerLanguage=9
	#tag EndEnum

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

	#tag Enum, Name = SFTPEntryType, Type = Integer, Flags = &h1
		File
		  Directory
		  Symlink
		  Socket
		  BlockSpecial
		  CharacterSpecial
		  Pipe
		Unknown
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

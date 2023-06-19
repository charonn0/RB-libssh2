#tag Class
Protected Class Session
Implements ErrorSetter
	#tag Method, Flags = &h0
		Function BlockInbound() As Boolean
		  ' Returns True if reading from the the session (via Channel, SFTPStream, etc.) would block
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.BlockInbound
		  
		  Return Mask(libssh2_session_block_directions(mSession), LIBSSH2_SESSION_BLOCK_INBOUND)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function BlockOutbound() As Boolean
		  ' Returns True if writing to the the session (via Channel, SFTPStream, etc.) would block
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.BlockOutbound
		  
		  Return Mask(libssh2_session_block_directions(mSession), LIBSSH2_SESSION_BLOCK_OUTBOUND)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function CheckHost(Hosts As SSH.KnownHosts, AddHost As Boolean) As Boolean
		  ' Compares the current session to a list of known host+key combinations.
		  ' If AddHost=True then the current session's host+key will be added to the list.
		  ' If AddHost=False and the host+key of the current session were found in the list
		  ' this method returns True. Check Session.LastError if it returns False.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.CheckHost
		  
		  Dim host As String = Me.RemoteHost
		  Dim port As Integer = Me.RemotePort
		  Dim key As MemoryBlock = Me.HostKey
		  Dim type As Integer = Hosts.LIBSSH2_KNOWNHOST_TYPE_PLAIN Or Hosts.LIBSSH2_KNOWNHOST_KEYENC_RAW
		  
		  If Hosts.Lookup(host, port, key, type) Then
		    Return True ' the server is known and its fingerprint is valid
		  End If
		  
		  mLastError = Hosts.LastError
		  If mLastError = ERR_HOSTKEY_MISMATCH Then
		    ' the server is known but its fingerprint has changed!
		    ' If, and *only* if, this change was expected then remove the old fingerprint and try again.
		    Return False
		  End If
		  
		  If Not AddHost Then Return False ' the server is unknown
		  
		  If mLastError = ERR_HOSTKEY_NOTFOUND Then
		    Hosts.AddHost(Me)
		    Return True ' the server's fingerprint was added
		  End If
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Close(Description As String = "The session has ended.", Reason As SSH.DisconnectReason = SSH.DisconnectReason.AppRequested, Language As String = "")
		  ' Ends the SSH session and closes the socket.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.Close
		  
		  If mSession <> Nil Then
		    Do
		      mLastError = libssh2_session_disconnect_ex(mSession, Reason, Description, Language)
		    Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  End If
		  If mSocket <> Nil Then mSocket.Close()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Connect(Address As String, Port As Integer, TimeOut As UInt32 = 0) As Boolean
		  ' Opens a TCP connection to the Address:Port and then performs the SSH handshake.
		  ' If TimeOut is specified then the connection attempt will be abandoned after the TimeOut
		  ' period elapses. The TimeOut period is measured in milliseconds.
		  ' Returns True on success. Check Session.LastError if it returns False.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.Connect
		  
		  Dim sock As New TCPSocket
		  sock.Address = Address
		  sock.Port = Port
		  Return Me.Connect(sock, TimeOut)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Connect(Socket As TCPSocket, TimeOut As UInt32 = 0) As Boolean
		  ' Opens a TCP connection using the specified Socket and then performs the SSH handshake.
		  ' If TimeOut is specified then the connection attempt will be abandoned after the TimeOut
		  ' period elapses. The TimeOut period is measured in milliseconds.
		  ' Returns True on success. Check Session.LastError if it returns False.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.Connect
		  
		  If IsConnected Then
		    mLastError = ERR_TOO_LATE
		    Return Socket.Address = mOriginalRemoteHost
		  End If
		  
		  mSocket = Socket
		  mRemotePort = mSocket.Port
		  mOriginalRemoteHost = mSocket.Address
		  
		  Dim timestart As UInt32 = Microseconds / 1000
		  
		  If Not mSocket.IsConnected Then
		    If mNetworkInterface <> Nil Then mSocket.NetworkInterface = mNetworkInterface
		    mSocket.Connect()
		    
		    Do Until mSocket.LastErrorCode <> 0
		      If TimeOut > 0 And (Microseconds / 1000) - timestart >= TimeOut Then
		        mSocket.Close()
		        mLastError = ERR_TIMEOUT_ELAPSED
		        Return False
		      End If
		      mSocket.Poll()
		    Loop Until mSocket.IsConnected
		    
		    If Not mSocket.IsConnected Then
		      mLastError = -mSocket.LastErrorCode ' make negative like libssh2 errors
		      Return False
		    End If
		  End If
		  
		  Do
		    mLastError = libssh2_session_handshake(mSession, mSocket.Handle)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then mSocket.Close()
		  
		  Return IsConnected
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor()
		  ' Creates a new instance of Session.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.Constructor
		  
		  mInit = SSHInit.GetInstance()
		  Static abstract As Integer
		  abstract = abstract + 1
		  mSession = libssh2_session_init_ex(Nil, Nil, Nil, abstract)
		  If mSession = Nil Then Raise New SSHException(ERR_INIT_FAILED)
		  mAbstract = abstract
		  If IsCompressionAvailable Then Me.UseCompression = True
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If Me.IsConnected Then Me.Close()
		  If mSession <> Nil Then
		    mLastError = libssh2_session_free(mSession)
		    mSession = Nil
		    If mLastError <> 0 Then Raise New SSHException(Me)
		  End If
		  mSocket = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetActualAlgorithm(Type As SSH.AlgorithmType) As String
		  ' Once connected to a server, this method returns the negotiated algorithm
		  ' for the specified AlgorithmType.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.GetActualAlgorithm
		  
		  Dim item As CString
		  If Not IsConnected Then
		    mLastError = ERR_TOO_EARLY
		    item = ""
		  Else
		    item = libssh2_session_methods(mSession, Type)
		  End If
		  Return item
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetAuthenticationMethods(Username As String) As String()
		  ' Query the remote server for a list of authentication methods that the Username is eligible
		  ' to use. Note that most server implementations do not permit attempting authentication with
		  ' different usernames between requests. Therefore this must be the same username you will use
		  ' on later SendCredentials() calls.
		  ' In the unlikely event that the server allows the user to log on *without* authenticating, calling
		  ' this method will successfully log the user on and the returned list will be empty. Consequently,
		  ' an empty return value is not necessarily an error. You can check the IsAuthenticated property to
		  ' determine whether you're actually authenticated.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.GetAuthenticationMethods
		  
		  Dim auth() As String
		  If Not IsConnected Then
		    mLastError = ERR_TOO_EARLY
		  ElseIf IsAuthenticated Then
		    mLastError = ERR_TOO_LATE
		  Else
		    Dim mb As MemoryBlock = Username
		    Dim lst As Ptr
		    Do
		      lst = libssh2_userauth_list(mSession, mb, mb.Size)
		      If lst = Nil Then
		        mLastError = GetLastError()
		      Else
		        mb = lst
		        auth = Split(mb.CString(0), ",")
		        mLastError = 0
		      End If
		    Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  End If
		  Return auth
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetAvailableAlgorithms(Type As SSH.AlgorithmType) As String()
		  ' Returns an array of available algorithms for the specified AlgorithmType.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.GetAvailableAlgorithms
		  
		  Dim ret() As String
		  If mSession = Nil Then Return ret
		  
		  Dim lst As Ptr
		  mLastError = libssh2_session_supported_algs(mSession, Type, lst)
		  If mLastError >= 0 Then ' err is the number of algs
		    Try
		      Dim item As MemoryBlock = lst.Ptr(0)
		      For i As Integer = 0 To mLastError
		        ret.Append(item.CString(0))
		        #If Target32Bit Then
		          item = lst.Ptr(i * 4)
		        #Else
		          item = lst.Ptr(i * 8)
		        #EndIf
		      Next
		    Finally
		      If lst <> Nil Then libssh2_free(mSession, lst)
		    End Try
		  End If
		  
		  Return ret
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetLastError() As Int32
		  ' Queries the most recent error code known to libshh2.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.GetLastError
		  
		  If mSession = Nil Then Return 0
		  Return libssh2_session_last_errno(mSession)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetRemoteBanner() As String
		  ' After Connect() returns successfully, you may call this method to read the
		  ' server's welcome banner, if it has one.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.GetRemoteBanner
		  
		  If Not IsConnected Then
		    mLastError = ERR_TOO_EARLY
		    Return ""
		  End If
		  Dim mb As MemoryBlock = libssh2_session_banner_get(mSession)
		  If mb <> Nil Then Return mb.CString(0)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function HostKeyHash(Type As SSH.HashType) As MemoryBlock
		  ' Returns the computed digest of the remote system's hostkey. The size of the returned
		  ' MemoryBlock is HashType specific (16 bytes for MD5, 20 bytes for SHA1, 32 bytes for SHA256).
		  ' Returns Nil if the session has not yet been started up or the requested hash algorithm was
		  ' not available.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.HostKeyHash
		  
		  If Not IsConnected Then
		    mLastError = ERR_TOO_EARLY
		    Return Nil
		  End If
		  Dim sz As Integer
		  Select Case Type
		  Case HashType.MD5
		    sz = 16
		  Case HashType.SHA1
		    sz = 20
		  Case HashType.SHA256
		    sz = 32
		  End Select
		  Dim mb As MemoryBlock = libssh2_hostkey_hash(mSession, Type)
		  If mb <> Nil Then Return mb.StringValue(0, sz) Else mLastError = GetLastError()
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function KeepAlive() As Integer
		  ' Send a keepalive message if needed. The return value indicates how many
		  ' seconds you can sleep after this call before you need to call it again.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.KeepAlive
		  
		  Dim nxt As Integer
		  If Not IsConnected Then
		    mLastError = ERR_TOO_EARLY
		  Else
		    mLastError = libssh2_keepalive_send(mSession, nxt)
		  End If
		  If mLastError = 0 Then Return nxt
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub LastError(Assigns err As Int32)
		  // Part of the ErrorSetter interface.
		  
		  mLastError = err
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Operator_Compare(OtherSession As SSH.Session) As Integer
		  If OtherSession Is Nil Then Return 1
		  Return Sign(Integer(Me.Handle) - Integer(OtherSession.Handle))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Poll(Timeout As Integer = 1000, EventMask As Integer = 0) As Boolean
		  ' Polls the underlying TCP connection for activity. If this method returns True then
		  ' Session.LastError will contain a bitmask of LIBSSH2_POLLFD_* constants indicating
		  ' which streams are ready. If it returns False because of an error condition then the
		  ' LastError will contain the error code, otherwise (that is, no errors and no activity)
		  ' the LastError will be zero.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.Poll
		  
		  If Not IsConnected Then
		    mLastError = ERR_TOO_EARLY
		    Return False
		  End If
		  If EventMask = 0 Then EventMask = LIBSSH2_POLLFD_POLLIN Or LIBSSH2_POLLFD_POLLOUT
		  Dim pollfd As LIBSSH2_POLLFD
		  pollfd.Type = LIBSSH2_POLLFD_SOCKET
		  pollfd.Descriptor = Ptr(mSocket.Handle)
		  pollfd.Events = EventMask
		  If libssh2_poll(pollfd, 1, Timeout) <> 1 Then
		    mLastError = 0
		    Return False
		  End If
		  mLastError = pollfd.REvents
		  Select Case True
		  Case Mask(mLastError, LIBSSH2_POLLFD_POLLIN), _
		    Mask(mLastError, LIBSSH2_POLLFD_POLLOUT), _
		    Mask(mLastError, LIBSSH2_POLLFD_POLLEXT)
		    Return True
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SendCredentials(Username As String, PublicKey As FolderItem, PrivateKey As FolderItem, PrivateKeyPassword As String) As Boolean
		  ' Authenticate as the specified user with keys stored in files.
		  ' PublicKey MAY be Nil if libssh2 was built against OpenSSL.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.SendCredentials
		  ' https://www.libssh2.org/libssh2_userauth_publickey_fromfile_ex.html
		  
		  If IsAuthenticated Then
		    mLastError = ERR_TOO_LATE
		    Return Username = mUsername
		  ElseIf Not IsConnected Then
		    mLastError = ERR_TOO_EARLY
		    Return False
		  End If
		  
		  Do
		    If PublicKey <> Nil Then
		      mLastError = libssh2_userauth_publickey_fromfile_ex(mSession, Username, Username.Len, PublicKey.AbsolutePath_, PrivateKey.AbsolutePath_, PrivateKeyPassword)
		    Else
		      mLastError = libssh2_userauth_publickey_fromfile_ex(mSession, Username, Username.Len, Nil, PrivateKey.AbsolutePath_, PrivateKeyPassword)
		    End If
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  mUsername = Username
		  Return mLastError = 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SendCredentials(Username As String, PublicKey As MemoryBlock, PrivateKey As MemoryBlock, PrivateKeyPassword As String) As Boolean
		  ' Authenticate as the specified user with keys from memory.
		  ' PublicKey MAY be Nil if libssh2 was built against OpenSSL.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.SendCredentials
		  ' https://www.libssh2.org/libssh2_userauth_publickey_frommemory.html
		  
		  If IsAuthenticated Then
		    mLastError = ERR_TOO_LATE
		    Return Username = mUsername
		  ElseIf Not IsConnected Then
		    mLastError = ERR_TOO_EARLY
		    Return False
		  End If
		  
		  Do
		    If PublicKey <> Nil Then
		      mLastError = libssh2_userauth_publickey_frommemory(mSession, Username, Username.Len, PublicKey, PublicKey.Size, PrivateKey, PrivateKey.Size, PrivateKeyPassword)
		    Else
		      mLastError = libssh2_userauth_publickey_frommemory(mSession, Username, Username.Len, Nil, 0, PrivateKey, PrivateKey.Size, PrivateKeyPassword)
		    End If
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  mUsername = Username
		  Return mLastError = 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SendCredentials(Username As String, Agent As SSH.Agent, KeyIndex As Integer) As Boolean
		  ' Authenticate as the specified user with the key at the specified
		  ' index in the Agent's list of keys.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.SendCredentials
		  
		  If IsAuthenticated Then
		    mLastError = ERR_TOO_LATE
		    Return Username = mUsername
		  ElseIf Not IsConnected Then
		    mLastError = ERR_TOO_EARLY
		    Return False
		  End If
		  
		  If Agent = Nil Or Not (Agent.Session Is Me) Then
		    mLastError = ERR_SESSION_MISMATCH
		    Return False
		  End If
		  
		  mUsername = Username
		  Dim cleanup As Boolean
		  If Not Agent.IsConnected Then
		    If Not Agent.Connect() Then Return False
		    If Not Agent.Refresh() Then Return False
		    cleanup = True
		  End If
		  
		  Dim ok As Boolean
		  Try
		    ok = Agent.Authenticate(Username, KeyIndex)
		  Finally
		    If cleanup Then Agent.Disconnect()
		  End Try
		  Return ok
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SendCredentials(Username As String, Key As SSH.AgentKey) As Boolean
		  ' Authenticate as the specified user with the specified key from the Agent's list of keys.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.SendCredentials
		  
		  Return SendCredentials(Username, Key.Owner, Key.Index)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SendCredentials(Username As String, Password As String) As Boolean
		  ' Authenticate as the specified user with a password.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.SendCredentials
		  
		  If IsAuthenticated Then
		    mLastError = ERR_TOO_LATE
		    Return Username = mUsername
		  ElseIf Not IsConnected Then
		    mLastError = ERR_TOO_EARLY
		    Return False
		  End If
		  
		  Do
		    mLastError = libssh2_userauth_password_ex(mSession, Username, Username.Len, Password, Password.Len, Nil)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  mUsername = Username
		  Return mLastError = 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetFlag(Flag As Integer, Value As Integer)
		  ' Sets various options for the session.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.SetFlag
		  ' https://www.libssh2.org/libssh2_session_flag.html
		  
		  mLastError = libssh2_session_flag(mSession, Flag, Value)
		  If mLastError <> 0 Then Raise New SSHException(Me)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetLocalBanner(BannerText As String)
		  ' Before calling Connect(), you may call this method to set the local welcome banner.
		  ' This is optional; a banner corresponding to the protocol and libssh2 version will be
		  ' sent by default.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.SetLocalBanner
		  
		  If IsConnected Then
		    mLastError = ERR_TOO_LATE
		  Else
		    mLastError = libssh2_session_banner_set(mSession, BannerText)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetPreferredAlgorithms(Type As SSH.AlgorithmType, Preferred() As String)
		  ' Prior to calling Session.Connect(), you may use this method to specify a list of
		  ' acceptable algorithms for the specified AlgorithmType.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.SetPreferredAlgorithms
		  
		  If IsConnected Then
		    mLastError = ERR_TOO_LATE
		    Return
		  End If
		  Dim lst As MemoryBlock = Join(Preferred, ",") + Chr(0)
		  mLastError = libssh2_session_method_pref(mSession, Type, lst)
		End Sub
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Gets whether libssh2 calls are blocking.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.Blocking
			  
			  If mSession = Nil Then Return False
			  Return libssh2_session_get_blocking(mSession) = 1
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' Sets whether libssh2 calls are blocking.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.Blocking
			  
			  If mSession = Nil Then Return
			  If value Then
			    libssh2_session_set_blocking(mSession, 1)
			  Else
			    libssh2_session_set_blocking(mSession, 0)
			  End If
			End Set
		#tag EndSetter
		Blocking As Boolean
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Gets the TCP socket handle for the session.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.Descriptor
			  
			  If mSocket <> Nil Then Return mSocket.Handle
			End Get
		#tag EndGetter
		Descriptor As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' The internal handle reference of the object.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.Handle
			  
			  Return mSession
			End Get
		#tag EndGetter
		Handle As Ptr
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Gets the remote host's raw binary key.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.HostKey
			  
			  If mSession = Nil Then Return Nil
			  Dim sz, typ As Integer
			  Dim mb As MemoryBlock = libssh2_session_hostkey(mSession, sz, typ)
			  If mb <> Nil Then Return mb.StringValue(0, sz)
			End Get
		#tag EndGetter
		HostKey As MemoryBlock
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Gets a bitmask describing the type of the HostKey.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.HostKeyType
			  
			  If mSession = Nil Then Return 0
			  Dim sz, typ As Integer
			  Dim mb As MemoryBlock = libssh2_session_hostkey(mSession, sz, typ)
			  If mb <> Nil Then Return typ
			End Get
		#tag EndGetter
		HostKeyType As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' This property is True if the session is currently connected and the user is authenticated.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.IsAuthenticated
			  
			  If mSession <> Nil Then Return libssh2_userauth_authenticated(mSession) = 1
			End Get
		#tag EndGetter
		IsAuthenticated As Boolean
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' This property is True if the session is currently connected.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.IsConnected
			  
			  Return mSocket <> Nil And mSocket.IsConnected
			End Get
		#tag EndGetter
		IsConnected As Boolean
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Gets how often keepalive messages should be sent, in seconds.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.KeepAlivePeriod
			  
			  return mKeepAlivePeriod
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' Sets how often keepalive messages should be sent, in seconds.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.KeepAlivePeriod
			  
			  If value > 0 Then
			    libssh2_keepalive_config(mSession, 1, value)
			  Else
			    libssh2_keepalive_config(mSession, 0, value)
			  End If
			  mKeepAlivePeriod = value
			End Set
		#tag EndSetter
		KeepAlivePeriod As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns the most recent error code returned from a libssh2 function call. If the last
			  ' recorded error is zero then calls GetLastError()
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.LastError
			  
			  If mLastError <> 0 Then Return mLastError Else Return GetLastError()
			End Get
		#tag EndGetter
		LastError As Int32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns a human readable error message for the most recent error.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.LastErrorMsg
			  
			  If mSession = Nil Then Return ""
			  Dim mb As New MemoryBlock(1024)
			  Dim sz As Integer
			  Call libssh2_session_last_error(mSession, mb, sz, mb.Size)
			  If mb.Ptr(0) <> Nil Then mb = mb.Ptr(0)
			  Return mb.StringValue(0, sz)
			  
			End Get
		#tag EndGetter
		LastErrorMsg As String
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mAbstract As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mInit As SSHInit
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mKeepAlivePeriod As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastError As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mNetworkInterface As NetworkInterface
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mOriginalRemoteHost As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mRemotePort As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSession As Ptr
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSocket As TCPSocket
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mUseCompression As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mUsername As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mVerbose As Boolean
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Gets the local NetworkInterface being used.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.NetworkInterface
			  
			  If mSocket = Nil Then
			    If mNetworkInterface <> Nil Then Return mNetworkInterface
			    Return Nil
			  End If
			  If mSocket.NetworkInterface <> Nil Then Return mSocket.NetworkInterface
			  If IsConnected Then
			    For i As Integer = 0 To System.NetworkInterfaceCount - 1
			      Dim net As NetworkInterface = System.GetNetworkInterface(i)
			      If net.IPAddress = mSocket.LocalAddress Then Return net
			    Next
			  End If
			  
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' Sets the local NetworkInterface to be used; if left unspecified then the system will select one for
			  ' you. Must be set before calling the Connect() method. If you pass a connected TCP socket to the
			  ' Connect() method then this property is ignored.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.NetworkInterface
			  
			  If IsConnected Then
			    mLastError = ERR_TOO_LATE
			    Raise New SSHException(Me)
			  End If
			  mNetworkInterface = value
			End Set
		#tag EndSetter
		NetworkInterface As NetworkInterface
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Gets the hostname or IP address of the remote server.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.RemoteHost
			  
			  If IsConnected Then Return mSocket.RemoteAddress
			  Return mOriginalRemoteHost
			  
			End Get
		#tag EndGetter
		RemoteHost As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Gets the port of the remote server.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.RemotePort
			  
			  return mRemotePort
			End Get
		#tag EndGetter
		RemotePort As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Gets how long (in milliseconds) a blocking function call may wait until it considers
			  ' the situation an error.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.TimeOut
			  
			  If mSession = Nil Then Return 0
			  Return libssh2_session_get_timeout(mSession)
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' Sets how long (in milliseconds) a blocking function call may wait until it considers
			  ' the situation an error.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.TimeOut
			  
			  If mSession = Nil Then Return
			  libssh2_session_set_timeout(mSession, value)
			End Set
		#tag EndSetter
		Timeout As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Gets whether the session will request compression. Defaults to True if compression is available
			  ' on the client side. Changing this property's value has no effect once the session is connected.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.UseCompression
			  
			  return mUseCompression
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' Sets whether the session will request compression. Defaults to True if compression is available
			  ' on the client side. Changing this property's value has no effect once the session is connected.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.UseCompression
			  
			  If value Then
			    Me.SetFlag(LIBSSH2_FLAG_COMPRESS, 1)
			  Else
			    Me.SetFlag(LIBSSH2_FLAG_COMPRESS, 0)
			  End If
			  mUseCompression = value
			End Set
		#tag EndSetter
		UseCompression As Boolean
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Gets the username that was used to authenticate to the server.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.Username
			  
			  return mUsername
			End Get
		#tag EndGetter
		Username As String
	#tag EndComputedProperty


	#tag Constant, Name = LIBSSH2_FLAG_COMPRESS, Type = Double, Dynamic = False, Default = \"2", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FLAG_SIGPIPE, Type = Double, Dynamic = False, Default = \"1", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SESSION_BLOCK_INBOUND, Type = Double, Dynamic = False, Default = \"1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SESSION_BLOCK_OUTBOUND, Type = Double, Dynamic = False, Default = \"2", Scope = Private
	#tag EndConstant


	#tag ViewBehavior
		#tag ViewProperty
			Name="Blocking"
			Group="Behavior"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="HostKeyType"
			Group="Behavior"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="IsAuthenticated"
			Group="Behavior"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="IsConnected"
			Group="Behavior"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="KeepAlivePeriod"
			Group="Behavior"
			Type="Integer"
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
			Name="Password"
			Group="Behavior"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="RemoteHost"
			Group="Behavior"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="RemotePort"
			Group="Behavior"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Timeout"
			Group="Behavior"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="UseCompression"
			Group="Behavior"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="UserName"
			Group="Behavior"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Verbose"
			Group="Behavior"
			Type="Boolean"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass

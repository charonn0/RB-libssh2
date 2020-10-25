#tag Class
Protected Class Session
Implements ChannelParent
	#tag Method, Flags = &h0
		Function BlockInbound() As Boolean
		  ' Returns True if reading from the the session (via Channel, SFTPStream, etc.) would block
		  
		  Return BitAnd(libssh2_session_block_directions(mSession), LIBSSH2_SESSION_BLOCK_INBOUND) = LIBSSH2_SESSION_BLOCK_INBOUND
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function BlockOutbound() As Boolean
		  ' Returns True if writing to the the session (via Channel, SFTPStream, etc.) would block
		  
		  Return BitAnd(libssh2_session_block_directions(mSession), LIBSSH2_SESSION_BLOCK_OUTBOUND) = LIBSSH2_SESSION_BLOCK_OUTBOUND
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function CheckHost(Hosts As SSH.KnownHosts, AddHost As Boolean) As Boolean
		  ' Compares the current session to a list of known host+key combinations.
		  ' If AddHost=True then the current session's host+key will be added to the list.
		  ' If AddHost=False and the host+key of the current session were found in the list
		  ' this method returns True. Check Session.LastError if it returns False.
		  
		  If Hosts.Lookup(Me) Then Return True
		  mLastError = Hosts.LastError
		  If Not AddHost Then Return False
		  Hosts.AddHost(Me)
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Close(Description As String = "The session has ended.", Reason As SSH.DisconnectReason = SSH.DisconnectReason.AppRequested, Language As String = "")
		  ' Ends the SSH session and closes the socket.
		  
		  If mSession <> Nil Then
		    Do
		      mLastError = libssh2_session_disconnect_ex(mSession, Reason, Description, Language)
		    Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		    RaiseEvent Disconnected(Reason, Description, Language)
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
		  
		  mSocket = Socket
		  mRemotePort = mSocket.Port
		  
		  Dim timestart As UInt32 = Microseconds / 1000
		  
		  If Not mSocket.IsConnected Then
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
		  mInit = SSHInit.GetInstance()
		  Static abstract As Integer
		  If Sessions = Nil Then Sessions = New Dictionary
		  Do
		    abstract = abstract + 1
		  Loop Until Not Sessions.HasKey(abstract)
		  mSession = libssh2_session_init_ex(Nil, Nil, Nil, abstract)
		  If mSession = Nil Then Raise New RuntimeException
		  mAbstract = abstract
		  Sessions.Value(abstract) = New WeakRef(Me)
		  Me.SetCallback(CB_Disconnect, AddressOf DisconnectHandler)
		  Me.SetCallback(CB_Ignore, AddressOf IgnoreHandler)
		  Me.SetCallback(CB_MACError, AddressOf MACErrorHandler)
		  Me.SetCallback(CB_X11Open, AddressOf X11OpenHandler)
		  
		  #If TargetWin32
		    Const zlib1 = "zlib1.dll"
		  #ElseIf TargetMacOS
		    Const zlib1 = "/usr/lib/libz.dylib"
		  #Else
		    Const zlib1 = "libz.so.1"
		  #endif
		  If System.IsFunctionAvailable("zlibVersion", zlib1) Then Me.UseCompression = True
		End Sub
	#tag EndMethod

	#tag DelegateDeclaration, Flags = &h21
		Private Delegate Sub DebugCallback(Session As Ptr, AlwaysDisplay As Integer, Message As Ptr, MessageLength As Integer, Language As Ptr, ByRef Abstract As Integer)
	#tag EndDelegateDeclaration

	#tag Method, Flags = &h21
		Private Shared Sub DebugHandler(Session As Ptr, AlwaysDisplay As Integer, Message As Ptr, MessageLength As Integer, Language As Ptr, ByRef Abstract As Integer)
		  #pragma Unused Session
		  If Sessions = Nil Then Return
		  Dim w As WeakRef = Sessions.Lookup(Abstract, Nil)
		  If w = Nil Or w.Value = Nil Then Return
		  SSH.Session(w.Value).Sess_Debug(AlwaysDisplay, Message, MessageLength, Language)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If Me.IsConnected Then Me.Close()
		  If mSession <> Nil Then
		    mLastError = libssh2_session_free(mSession)
		    mSession = Nil
		    If mLastError <> 0 Then Raise New SSHException(mLastError)
		  End If
		  mChannels = Nil
		  mSocket = Nil
		  If Sessions <> Nil And Sessions.HasKey(mAbstract) Then
		    Sessions.Remove(mAbstract)
		    If Sessions.Count = 0 Then Sessions = Nil
		  End If
		End Sub
	#tag EndMethod

	#tag DelegateDeclaration, Flags = &h21
		Private Delegate Sub DisconnectCallback(Session As Ptr, Reason As Integer, Message As Ptr, MessageLength As Integer, Language As Ptr, LanguageLength As Integer, ByRef Abstract As Integer)
	#tag EndDelegateDeclaration

	#tag Method, Flags = &h21
		Private Shared Sub DisconnectHandler(Session As Ptr, Reason As Integer, Message As Ptr, MessageLength As Integer, Language As Ptr, LanguageLength As Integer, ByRef Abstract As Integer)
		  #pragma Unused Session
		  If Sessions = Nil Then Return
		  Dim w As WeakRef = Sessions.Lookup(Abstract, Nil)
		  If w = Nil Or w.Value = Nil Then Return
		  SSH.Session(w.Value).Sess_Disconnect(Reason, Message, MessageLength, Language, LanguageLength)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetAuthenticationMethods(Username As String) As String()
		  Dim mb As MemoryBlock = Username
		  Dim lst As Ptr = libssh2_userauth_list(mSession, mb, mb.Size)
		  If lst <> Nil Then
		    mb = lst
		    Return Split(mb.CString(0), ",")
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetLastError() As Int32
		  ' Returns the most recent error code known to libshh2
		  
		  If mSession = Nil Then Return 0
		  Return libssh2_session_last_errno(mSession)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetRemoteBanner() As String
		  Dim mb As MemoryBlock = libssh2_session_banner_get(mSession)
		  If mb <> Nil Then Return mb.CString(0)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Handle() As Ptr
		  Return mSession
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function HostKeyHash(Type As SSH.HashType) As MemoryBlock
		  If mSession = Nil Then Return Nil
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
		  If mb <> Nil Then Return mb.StringValue(0, sz)
		End Function
	#tag EndMethod

	#tag DelegateDeclaration, Flags = &h21
		Private Delegate Sub IgnoreCallback(Session As Ptr, Message As Ptr, MessageLength As Integer, ByRef Abstract As Integer)
	#tag EndDelegateDeclaration

	#tag Method, Flags = &h21
		Private Shared Sub IgnoreHandler(Session As Ptr, Message As Ptr, MessageLength As Integer, ByRef Abstract As Integer)
		  #pragma Unused Session
		  If Sessions = Nil Then Return
		  Dim w As WeakRef = Sessions.Lookup(Abstract, Nil)
		  If w = Nil Or w.Value = Nil Then Return
		  SSH.Session(w.Value).Sess_Ignore(Message, MessageLength)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function KeepAlive() As Integer
		  Dim nxt As Integer
		  mLastError = libssh2_keepalive_send(mSession, nxt)
		  If mLastError = 0 Then Return nxt
		End Function
	#tag EndMethod

	#tag DelegateDeclaration, Flags = &h21
		Private Delegate Sub KeyboardAuthCallback(Name As Ptr, NameLength As Integer, Instruction As Ptr, InstructionLength As Integer, PromptCount As Integer, Prompts As Ptr, Responses As Ptr, ByRef Abstract As Integer)
	#tag EndDelegateDeclaration

	#tag Method, Flags = &h21
		Private Shared Sub KeyboardAuthHandler(Name As Ptr, NameLength As Integer, Instruction As Ptr, InstructionLength As Integer, PromptCount As Integer, Prompts As Ptr, Responses As Ptr, ByRef Abstract As Integer)
		  If Sessions = Nil Then Return
		  Dim w As WeakRef = Sessions.Lookup(Abstract, Nil)
		  If w = Nil Or w.Value = Nil Then Return
		  SSH.Session(w.Value).Sess_KeyboardAuth(Name, NameLength, Instruction, InstructionLength, PromptCount, Prompts, Responses)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Int32
		  ' Returns the most recent error code returned from a libssh2 function call. If the last
		  ' recorded error is zero then calls GetLastError()
		  
		  If mLastError <> 0 Then Return mLastError Else Return GetLastError()
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastErrorMsg() As String
		  ' Returns a human readable error message for the most recent error.
		  
		  If mSession = Nil Then Return ""
		  Dim mb As New MemoryBlock(1024)
		  Dim sz As Integer
		  Call libssh2_session_last_error(mSession, mb, sz, mb.Size)
		  If mb.Ptr(0) <> Nil Then mb = mb.Ptr(0)
		  Return mb.StringValue(0, sz)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Listen(Socket As TCPSocket)
		  If mSession = Nil Then Raise New RuntimeException
		  mSocket = Socket
		  Do
		    mLastError = libssh2_session_handshake(mSession, mSocket.Handle)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function LookupChannel(Ref As Ptr) As Channel
		  Dim w As WeakRef = mChannels.Lookup(Ref, Nil)
		  If w <> Nil And w.Value <> Nil And w.Value IsA Channel Then Return Channel(w.Value)
		End Function
	#tag EndMethod

	#tag DelegateDeclaration, Flags = &h21
		Private Delegate Function MACErrorCallback(Session As Ptr, Packet As Ptr, PacketLength As Integer, ByRef Abstract As Integer) As Integer
	#tag EndDelegateDeclaration

	#tag Method, Flags = &h21
		Private Shared Function MACErrorHandler(Session As Ptr, Packet As Ptr, PacketLength As Integer, ByRef Abstract As Integer) As Integer
		  #pragma Unused Session
		  If Sessions = Nil Then Return 1
		  Dim w As WeakRef = Sessions.Lookup(Abstract, Nil)
		  If w = Nil Or w.Value = Nil Then Return 1
		  Return SSH.Session(w.Value).Sess_MACError(Packet, PacketLength)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Operator_Compare(OtherSession As SSH.Session) As Integer
		  If OtherSession Is Nil Then Return 1
		  Return Sign(Integer(Me.Handle) - Integer(OtherSession.Handle))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Sub PasswordChangeReqCallback(Session As Ptr, PasswdBuffer As Ptr, ByRef PasswdBufferLength As Integer, ByRef Abstract As Integer)
		  #pragma Unused Session
		  If Sessions = Nil Then Return
		  Dim w As WeakRef = Sessions.Lookup(Abstract, Nil)
		  If w = Nil Or w.Value = Nil Then Return
		  SSH.Session(w.Value).Sess_PasswordChange(PasswdBuffer, PasswdBufferLength)
		End Sub
	#tag EndMethod

	#tag DelegateDeclaration, Flags = &h21
		Private Delegate Sub PasswordChangeRequestCallback(Session As Ptr, PasswdBuffer As Ptr, ByRef PasswdBufferLength As Integer, ByRef Abstract As Integer)
	#tag EndDelegateDeclaration

	#tag Method, Flags = &h0
		Function Poll(Timeout As Integer = 1000, EventMask As Integer = 0) As Boolean
		  If Not IsConnected Then Return False
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
		  Case BitAnd(mLastError, LIBSSH2_POLLFD_POLLIN) = LIBSSH2_POLLFD_POLLIN, _
		    BitAnd(mLastError, LIBSSH2_POLLFD_POLLOUT) = LIBSSH2_POLLFD_POLLOUT, _
		    BitAnd(mLastError, LIBSSH2_POLLFD_POLLEXT) = LIBSSH2_POLLFD_POLLEXT
		    Return True
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub RegisterChannel(Chan As Channel)
		  mChannels = New Dictionary
		  If Chan.Session <> Me Then Raise New RuntimeException
		  mChannels.Value(Chan.Handle) = New WeakRef(Chan)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SendCredentials(Username As String) As Boolean
		  Do
		    mLastError = libssh2_userauth_keyboard_interactive_ex(mSession, Username, Username.Len, AddressOf KeyboardAuthHandler)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  Return mLastError = 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SendCredentials(Username As String, PublicKey As FolderItem, PrivateKey As FolderItem, PrivateKeyPassword As String) As Boolean
		  Dim pub, priv As MemoryBlock
		  pub = PublicKey.AbsolutePath_
		  priv = PrivateKey.AbsolutePath_
		  Do
		    mLastError = libssh2_userauth_publickey_fromfile_ex(mSession, Username, Username.Len, pub, priv, PrivateKeyPassword)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  Return mLastError = 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SendCredentials(Username As String, PublicKey As MemoryBlock, PrivateKey As MemoryBlock, PrivateKeyPassword As String) As Boolean
		  ' Authenticate to the server with a key from memory.
		  ' https://www.libssh2.org/libssh2_userauth_publickey_frommemory.html
		  
		  Do
		    mLastError = libssh2_userauth_publickey_frommemory(mSession, Username, Username.Len, PublicKey, PublicKey.Size, PrivateKey, PrivateKey.Size, PrivateKeyPassword)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  Return mLastError = 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SendCredentials(Username As String, Agent As SSH.Agent, KeyIndex As Integer) As Boolean
		  If Agent = Nil Or Not (Agent.Session Is Me) Then
		    mLastError = ERR_SESSION_MISMATCH
		    Return False
		  End If
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
		Function SendCredentials(Username As String, Password As String) As Boolean
		  Do
		    mLastError = libssh2_userauth_password_ex(mSession, Username, Username.Len, Password, Password.Len, AddressOf PasswordChangeReqCallback)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  Return mLastError = 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Sess_Debug(AlwaysDisplay As Integer, Message As MemoryBlock, MessageLength As Integer, Language As MemoryBlock)
		  Dim m As String = Message.StringValue(0, MessageLength)
		  Dim l As String = Language.CString(0)
		  RaiseEvent DebugMessage(AlwaysDisplay = 1, m, l)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Sess_Disconnect(Reason As Integer, Message As MemoryBlock, MessageLength As Integer, Language As MemoryBlock, LanguageLength As Integer)
		  If MessageLength = 0 Then Return
		  Dim m As String = Message.StringValue(0, MessageLength)
		  Dim l As String = Language.StringValue(0, LanguageLength)
		  RaiseEvent Disconnected(DisconnectReason(Reason), m, l)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Sess_Ignore(Message As MemoryBlock, MessageLength As Integer)
		  Dim m As String = Message.StringValue(0, MessageLength)
		  RaiseEvent IgnoreMessage(m)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Sess_KeyboardAuth(Name As MemoryBlock, NameLength As Integer, Instruction As MemoryBlock, InstructionLength As Integer, PromptCount As Integer, Prompts As Ptr, Responses As Ptr)
		  Dim nm, ins As String
		  If NameLength > 0 Then nm = Name.StringValue(0, NameLength)
		  If InstructionLength > 0 Then ins = Instruction.StringValue(0, InstructionLength)
		  
		  For i As Integer = 0 To PromptCount - 1
		    Dim p As Ptr = Prompts.Ptr(i * 4)
		    Dim r As Ptr = Responses.Ptr(i * 4)
		    Dim prmt As LIBSSH2_USERAUTH_KBDINT_PROMPT = p.LIBSSH2_USERAUTH_KBDINT_PROMPT
		    Dim mb As MemoryBlock = prmt.Text
		    mb = mb.StringValue(0, prmt.Length)
		    Dim response As String
		    If Not RaiseEvent Authenticate(nm, ins, mb, response) Then Return
		    Dim rsp As LIBSSH2_USERAUTH_KBDINT_RESPONSE = r.LIBSSH2_USERAUTH_KBDINT_RESPONSE
		    mb = response
		    Dim txt As MemoryBlock = rsp.Text
		    txt.StringValue(0, mb.Size) = mb
		    rsp.Length = mb.Size
		  Next
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function Sess_MACError(Packet As MemoryBlock, PacketLength As Integer) As Integer
		  If RaiseEvent MACError(Packet, PacketLength) Then Return 0 ' ignore!
		  Return 1
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Sess_PasswordChange(NewPW As MemoryBlock, ByRef NewPWLength As Integer)
		  Dim pw As String
		  If RaiseEvent PasswordChangeRequest(pw) Then
		    NewPW.StringValue(0, pw.LenB) = pw
		    NewPWLength = pw.LenB
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Sess_X11Open(Channel As Ptr, Host As MemoryBlock, Port As Integer)
		  Dim ch As Channel = Me.LookupChannel(Channel)
		  If ch <> Nil Then RaiseEvent X11Open(ch, Host.CString(0), Port)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SetCallback(Type As Integer, Handler As Variant)
		  Select Case True
		  Case Type = CB_Ignore And Handler IsA IgnoreCallback
		    Dim d As IgnoreCallback = Handler
		    Call libssh2_session_callback_set(mSession, Type, d)
		    
		  Case Type = CB_Debug And Handler IsA DebugCallback
		    Dim d As DebugCallback = Handler
		    Call libssh2_session_callback_set(mSession, Type, d)
		    
		  Case Type = CB_Disconnect And Handler IsA DisconnectCallback
		    Dim d As DisconnectCallback = Handler
		    Call libssh2_session_callback_set(mSession, Type, d)
		    
		  Case Type = CB_MACError And Handler IsA MACErrorCallback
		    Dim d As MACErrorCallback = Handler
		    Call libssh2_session_callback_set(mSession, Type, d)
		    
		  Case Type = CB_X11Open And Handler IsA X11OpenCallback
		    Dim d As X11OpenCallback = Handler
		    Call libssh2_session_callback_set(mSession, Type, d)
		    
		  Case Handler Is Nil
		    Call libssh2_session_callback_set(mSession, Type, Nil)
		    
		  Else
		    Raise New RuntimeException
		  End Select
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetFlag(Flag As Integer, Value As Integer)
		  Dim err As Integer = libssh2_session_flag(mSession, Flag, Value)
		  If err <> 0 Then Raise New SSHException(err)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetLocalBanner(BannerText As String)
		  Dim err As Integer = libssh2_session_banner_set(mSession, BannerText)
		  If err <> 0 Then Raise New SSHException(err)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub UnregisterChannel(Chan As Channel)
		  If mChannels = Nil Then Return
		  If mChannels.HasKey(Chan.Handle) Then mChannels.Remove(Chan.Handle)
		  If mChannels.Count = 0 Then mChannels = Nil
		End Sub
	#tag EndMethod

	#tag DelegateDeclaration, Flags = &h21
		Private Delegate Sub X11OpenCallback(Session As Ptr, Channel As Ptr, Host As Ptr, Port As Integer, ByRef Abstract As Integer)
	#tag EndDelegateDeclaration

	#tag Method, Flags = &h21
		Private Shared Sub X11OpenHandler(Session As Ptr, Channel As Ptr, Host As Ptr, Port As Integer, ByRef Abstract As Integer)
		  #pragma Unused Session
		  If Sessions = Nil Then Return
		  Dim w As WeakRef = Sessions.Lookup(Abstract, Nil)
		  If w = Nil Or w.Value = Nil Then Return
		  SSH.Session(w.Value).Sess_X11Open(Channel, Host, Port)
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event Authenticate(Name As String, Instruction As String, Prompt As String, ByRef Response As String) As Boolean
	#tag EndHook

	#tag Hook, Flags = &h0
		Event DebugMessage(AlwaysDisplay As Boolean, Message As String, Language As String)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Disconnected(Reason As SSH.DisconnectReason, Message As String, Language As String)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event IgnoreMessage(Message As String)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event MACError(Packet As MemoryBlock, PacketLength As Integer) As Boolean
	#tag EndHook

	#tag Hook, Flags = &h0
		Event PasswordChangeRequest(ByRef NewPassword As String) As Boolean
	#tag EndHook

	#tag Hook, Flags = &h0
		Event X11Open(Channel As Channel, Host As String, Port As Integer)
	#tag EndHook


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mSession = Nil Then Return False
			  Return libssh2_session_get_blocking(mSession) = 1
			End Get
		#tag EndGetter
		#tag Setter
			Set
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
			  If mSocket <> Nil Then Return mSocket.Handle
			End Get
		#tag EndGetter
		Descriptor As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
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
			  If mSession <> Nil Then Return libssh2_userauth_authenticated(mSession) = 1
			End Get
		#tag EndGetter
		IsAuthenticated As Boolean
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mSocket <> Nil And mSocket.IsConnected()
			End Get
		#tag EndGetter
		IsConnected As Boolean
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mKeepAlivePeriod
			End Get
		#tag EndGetter
		#tag Setter
			Set
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

	#tag Property, Flags = &h21
		Private mAbstract As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mChannels As Dictionary
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
		Private mVerbose As Boolean
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mSocket <> Nil Then Return mSocket.RemoteAddress
			End Get
		#tag EndGetter
		RemoteHost As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mRemotePort
			End Get
		#tag EndGetter
		RemotePort As Integer
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private Shared Sessions As Dictionary
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mSession = Nil Then Return 0
			  Return libssh2_session_get_timeout(mSession)
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If mSession = Nil Then Return
			  libssh2_session_set_timeout(mSession, value)
			End Set
		#tag EndSetter
		Timeout As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mUseCompression
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If value Then
			    Me.SetFlag(LIBSSH2_FLAG_COMPRESS , 1)
			  Else
			    Me.SetFlag(LIBSSH2_FLAG_COMPRESS , 0)
			  End If
			  mUseCompression = value
			End Set
		#tag EndSetter
		UseCompression As Boolean
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mVerbose
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If value Then
			    Me.SetCallback(CB_Debug, AddressOf DebugHandler)
			  Else
			    Me.SetCallback(CB_Debug, Nil)
			  End If
			  mVerbose = value
			End Set
		#tag EndSetter
		Verbose As Boolean
	#tag EndComputedProperty


	#tag Constant, Name = CB_Debug, Type = Double, Dynamic = False, Default = \"1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = CB_Disconnect, Type = Double, Dynamic = False, Default = \"2", Scope = Private
	#tag EndConstant

	#tag Constant, Name = CB_Ignore, Type = Double, Dynamic = False, Default = \"0", Scope = Private
	#tag EndConstant

	#tag Constant, Name = CB_MACError, Type = Double, Dynamic = False, Default = \"3", Scope = Private
	#tag EndConstant

	#tag Constant, Name = CB_X11Open, Type = Double, Dynamic = False, Default = \"4", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FLAG_COMPRESS, Type = Double, Dynamic = False, Default = \"2", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FLAG_SIGPIPE, Type = Double, Dynamic = False, Default = \"1", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SESSION_BLOCK_INBOUND, Type = Double, Dynamic = False, Default = \"1", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SESSION_BLOCK_OUTBOUND, Type = Double, Dynamic = False, Default = \"2", Scope = Protected
	#tag EndConstant


	#tag Structure, Name = LIBSSH2_USERAUTH_KBDINT_PROMPT, Flags = &h21
		Text As Ptr
		  Length As UInt32
		Echo As Ptr
	#tag EndStructure

	#tag Structure, Name = LIBSSH2_USERAUTH_KBDINT_RESPONSE, Flags = &h21
		Text As Ptr
		Length As UInt32
	#tag EndStructure


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

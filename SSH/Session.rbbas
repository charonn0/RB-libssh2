#tag Class
Protected Class Session
Implements ChannelParent
	#tag Method, Flags = &h0
		Function Connect(Address As String, Port As Integer, Optional Hosts As FolderItem, AddHost As Boolean = False) As Boolean
		  mRemoteHost = Address
		  mRemotePort = Port
		  mSocket = New TCPSocket
		  mSocket.Address = Address
		  mSocket.Port = Port
		  mSocket.Connect()
		  
		  Do Until mSocket.LastErrorCode <> 0
		    mSocket.Poll
		  Loop Until mSocket.IsConnected
		  If Not mSocket.IsConnected Then
		    Select Case mSocket.LastErrorCode
		    Case 102
		      mLastError = ERR_CONNECTION_REFUSED
		    Case 103
		      mLastError = ERR_RESOLVE
		    Case 105
		      mLastError = ERR_PORT_IN_USE
		    Case 106
		      mLastError = ERR_ILLEGAL_OPERATION
		    Case 107
		      mLastError = ERR_INVALID_PORT
		    Else
		      mLastError = ERR_SOCKET
		    End Select
		    Return False
		  End If
		  
		  Do
		    mLastError = libssh2_session_handshake(mSession, mSocket.Handle)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then
		    mSocket.Close
		    Return False
		  End If
		  
		  If Hosts <> Nil And Hosts.Exists Then
		    Dim kh As New SSH.KnownHosts(Me)
		    Call kh.Load(Hosts)
		    If Not kh.Check(mSocket.RemoteAddress, 22, Me.HostKey, Me.HostKeyType) Then
		      If Not AddHost Then
		        mSocket.Close
		        mLastError = ERR_UNKNOWN_HOST
		        Raise New SSHException(mLastError)
		      End If
		      kh.AddHost(Address, Port, Me.HostKey, Nil, Nil, Me.HostKeyType)
		      kh.Save(Hosts)
		    End If
		  End If
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
		  Sessions.Value(abstract) = New WeakRef(Me)
		  mSession = libssh2_session_init_ex(Nil, Nil, Nil, abstract)
		  If mSession = Nil Then Raise New RuntimeException
		  Me.SetCallback(CB_Disconnect, AddressOf DisconnectHandler)
		  Me.SetCallback(CB_Ignore, AddressOf IgnoreHandler)
		  Me.SetCallback(CB_MACError, AddressOf MACErrorHandler)
		  Me.SetCallback(CB_X11Open, AddressOf X11OpenHandler)
		End Sub
	#tag EndMethod

	#tag DelegateDeclaration, Flags = &h21
		Private Delegate Sub DebugCallback(Session As Ptr, AlwaysDisplay As Integer, Message As Ptr, MessageLength As Integer, Language As Ptr, Abstract As Integer)
	#tag EndDelegateDeclaration

	#tag Method, Flags = &h21
		Private Shared Sub DebugHandler(Session As Ptr, AlwaysDisplay As Integer, Message As Ptr, MessageLength As Integer, Language As Ptr, Abstract As Integer)
		  #pragma Unused Session
		  If Sessions = Nil Then Return
		  Dim w As WeakRef = Sessions.Lookup(Abstract, Nil)
		  If w = Nil Or w.Value = Nil Then Return
		  SSH.Session(w.Value).Sess_Debug(AlwaysDisplay, Message, MessageLength, Language)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If mSession <> Nil Then
		    mLastError = libssh2_session_free(mSession)
		    mSession = Nil
		    If mLastError <> 0 Then Raise New SSHException(mLastError)
		  End If
		  If mSocket <> Nil Then mSocket.Close
		  mChannels = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Disconnect(Description As String, Reason As SSH.DisconnectReason = SSH.DisconnectReason.AppRequested)
		  If mSession = Nil Then Return
		  Do
		    mLastError = libssh2_session_disconnect_ex(mSession, Reason, Description, "")
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  mSocket.Disconnect()
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
		End Sub
	#tag EndMethod

	#tag DelegateDeclaration, Flags = &h21
		Private Delegate Sub DisconnectCallback(Session As Ptr, Reason As Integer, Message As Ptr, MessageLength As Integer, Language As Ptr, LanguageLength As Integer, Abstract As Integer)
	#tag EndDelegateDeclaration

	#tag Method, Flags = &h21
		Private Shared Sub DisconnectHandler(Session As Ptr, Reason As Integer, Message As Ptr, MessageLength As Integer, Language As Ptr, LanguageLength As Integer, Abstract As Integer)
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
		Function GetLastError() As Integer
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
		Private Delegate Sub IgnoreCallback(Session As Ptr, Message As Ptr, MessageLength As Integer, Abstract As Integer)
	#tag EndDelegateDeclaration

	#tag Method, Flags = &h21
		Private Shared Sub IgnoreHandler(Session As Ptr, Message As Ptr, MessageLength As Integer, Abstract As Integer)
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

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  If mLastError <> 0 Then Return mLastError Else Return GetLastError() 
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastErrorMsg() As String
		  If mSession = Nil Then Return ""
		  Dim mb As New MemoryBlock(1024)
		  Dim sz As Integer
		  Call libssh2_session_last_error(mSession, mb, sz, mb.Size)
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
		Private Delegate Function MACErrorCallback(Session As Ptr, Packet As Ptr, PacketLength As Integer, Abstract As Integer) As Integer
	#tag EndDelegateDeclaration

	#tag Method, Flags = &h21
		Private Shared Function MACErrorHandler(Session As Ptr, Packet As Ptr, PacketLength As Integer, Abstract As Integer) As Integer
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
		Private Shared Sub PasswordChangeReqCallback(Session As Ptr, PasswdBuffer As Ptr, ByRef PasswdBufferLength As Integer, Abstract As Integer)
		  #pragma Unused Session
		  If Sessions = Nil Then Return
		  Dim w As WeakRef = Sessions.Lookup(Abstract, Nil)
		  If w = Nil Or w.Value = Nil Then Return
		  SSH.Session(w.Value).Sess_PasswordChange(PasswdBuffer, PasswdBufferLength)
		End Sub
	#tag EndMethod

	#tag DelegateDeclaration, Flags = &h21
		Private Delegate Sub PasswordChangeRequestCallback(Session As Ptr, PasswdBuffer As Ptr, ByRef PasswdBufferLength As Integer, Abstract As Integer)
	#tag EndDelegateDeclaration

	#tag Method, Flags = &h21
		Private Sub RegisterChannel(Chan As Channel)
		  mChannels = New Dictionary
		  If Chan.Session <> Me Then Raise New RuntimeException
		  mChannels.Value(Chan.Handle) = New WeakRef(Chan)
		End Sub
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
		  Dim m As String = Message.StringValue(0, MessageLength)
		  Dim l As String = Language.StringValue(0, LanguageLength)
		  RaiseEvent Disconnect(DisconnectReason(Reason), m, l)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Sess_Ignore(Message As MemoryBlock, MessageLength As Integer)
		  Dim m As String = Message.StringValue(0, MessageLength)
		  RaiseEvent IgnoreMessage(m)
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
		Sub SetCredentials(Username As String, PublicKey As FolderItem, PrivateKey As FolderItem, PrivateKeyPassword As String)
		  Dim pub, priv As MemoryBlock
		  pub = PublicKey.AbsolutePath
		  priv = PrivateKey.AbsolutePath
		  Do
		    mLastError = libssh2_userauth_publickey_fromfile_ex(mSession, Username, Username.Len, pub, priv, PrivateKeyPassword)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetCredentials(Username As String, PublicKey As MemoryBlock, PrivateKey As MemoryBlock, PrivateKeyPassword As String)
		  Do
		    mLastError = libssh2_userauth_publickey_frommemory(mSession, Username, Username.Len, PublicKey, PublicKey.Size, PrivateKey, PrivateKey.Size, PrivateKeyPassword)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetCredentials(Username As String, Password As String)
		  Do
		    mLastError = libssh2_userauth_password_ex(mSession, Username, Username.Len, Password, Password.Len, AddressOf PasswordChangeReqCallback)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
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
		  mChannels = New Dictionary
		  If mChannels.HasKey(Chan.Handle) Then mChannels.Remove(Chan.Handle)
		  If mChannels.Count = 0 Then mChannels = Nil
		End Sub
	#tag EndMethod

	#tag DelegateDeclaration, Flags = &h21
		Private Delegate Sub X11OpenCallback(Session As Ptr, Channel As Ptr, Host As Ptr, Port As Integer, Abstract As Integer)
	#tag EndDelegateDeclaration

	#tag Method, Flags = &h21
		Private Shared Sub X11OpenHandler(Session As Ptr, Channel As Ptr, Host As Ptr, Port As Integer, Abstract As Integer)
		  #pragma Unused Session
		  If Sessions = Nil Then Return
		  Dim w As WeakRef = Sessions.Lookup(Abstract, Nil)
		  If w = Nil Or w.Value = Nil Then Return
		  SSH.Session(w.Value).Sess_X11Open(Channel, Host, Port)
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event DebugMessage(AlwaysDisplay As Boolean, Message As String, Language As String)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Disconnect(Reason As SSH.DisconnectReason, Message As String, Language As String)
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
			  Return libssh2_userauth_authenticated(mSession) = 1
			End Get
		#tag EndGetter
		IsAuthenticated As Boolean
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
		Private mRemoteHost As String
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
			  return mRemoteHost
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
			Name="Verbose"
			Group="Behavior"
			Type="Boolean"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass

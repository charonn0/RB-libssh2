#tag Class
Protected Class Session
	#tag Method, Flags = &h0
		Function Connect(Address As String, Port As Integer, Optional Hosts As FolderItem, AddHost As Boolean = False) As Integer
		  mSocket = New TCPSocket
		  mSocket.Address = Address
		  mSocket.Port = Port
		  mSocket.Connect()
		  
		  Do Until mSocket.IsConnected
		    mSocket.Poll
		  Loop Until mSocket.LastErrorCode <> 0
		  If Not mSocket.IsConnected Then
		    Select Case mSocket.LastErrorCode
		    Case 102
		      Return ERR_CONNECTION_REFUSED
		    Case 103
		      Return ERR_RESOLVE
		    Case 105
		      Return ERR_PORT_IN_USE
		    Case 106
		      Return ERR_ILLEGAL_OPERATION
		    Case 107
		      Return ERR_INVALID_PORT
		    Else
		      Return ERR_SOCKET
		    End Select
		  End If
		  
		  Do
		    mLastError = libssh2_session_handshake(mSession, mSocket.Handle)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then 
		    mSocket.Close
		    Return mLastError
		  End If
		  
		  If Hosts <> Nil And Hosts.Exists Then
		    Dim kh As New SSH.KnownHosts(Me)
		    Call kh.Load(Hosts)
		    If Not kh.Check(mSocket.RemoteAddress, 22, Me.HostKey, Me.HostKeyType) Then 
		      If Not AddHost Then 
		        mSocket.Close
		        Return ERR_UNKNOWN_HOST
		      End If
		      kh.AddHost(Address, Port, Me.HostKey, Nil, Nil, Me.HostKeyType)
		      kh.Save(Hosts)
		    End If
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor()
		  mInit = SSHInit.GetInstance()
		  mSession = libssh2_session_init_ex(Nil, Nil, Nil, Nil)
		  If mSession = Nil Then Raise New RuntimeException
		End Sub
	#tag EndMethod

	#tag DelegateDeclaration, Flags = &h21
		Private Delegate Sub DebugCallback(Session As Ptr, AlwaysDisplay As Integer, Message As Ptr, MessageLength As Integer, Language As Ptr, Abstract As Ptr)
	#tag EndDelegateDeclaration

	#tag Method, Flags = &h21
		Private Shared Sub DebugHandler(Session As Ptr, AlwaysDisplay As Integer, Message As Ptr, MessageLength As Integer, Language As Ptr, Abstract As Ptr)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If mSession <> Nil Then
		    Dim err As Integer = libssh2_session_free(mSession)
		    mSession = Nil
		    If err <> 0 Then Raise New SSHException(err)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Disconnect(Description As String, Reason As SSH.DisconnectReason = SSH.DisconnectReason.AppRequested)
		  If mSession = Nil Then Return
		  Dim err As Integer = libssh2_session_disconnect_ex(mSession, Reason, Description, "")
		  If err <> 0 Then Raise New SSHException(err)
		End Sub
	#tag EndMethod

	#tag DelegateDeclaration, Flags = &h21
		Private Delegate Sub DisconnectCallback(Session As Ptr, Reason As Integer, Message As Ptr, MessageLength As Integer, Language As Ptr, LanguageLength As Integer, Abstract As Ptr)
	#tag EndDelegateDeclaration

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
		Private Delegate Sub IgnoreCallback(Session As Ptr, Message As Ptr, MessageLength As Integer, Abstract As Ptr)
	#tag EndDelegateDeclaration

	#tag Method, Flags = &h0
		Function KeepAlive() As Integer
		  Dim nxt As Integer
		  mLastError = libssh2_keepalive_send(mSession, nxt)
		  If mLastError = 0 Then Return nxt
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  If mSession = Nil Then Return 0
		  Return libssh2_session_last_errno(mSession)
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

	#tag DelegateDeclaration, Flags = &h21
		Private Delegate Function MACErrorCallback(Session As Ptr, Packet As Ptr, PacketLength As Integer, Abstract As Ptr) As Integer
	#tag EndDelegateDeclaration

	#tag Method, Flags = &h21
		Private Shared Sub PasswordChangeReqCallback(Session As Ptr, PasswdBuffer As Ptr, ByRef PasswdBufferLength As Integer, Abstract As Ptr)
		  
		End Sub
	#tag EndMethod

	#tag DelegateDeclaration, Flags = &h21
		Private Delegate Sub PasswordChangeRequestCallback(Session As Ptr, PasswdBuffer As Ptr, ByRef PasswdBufferLength As Integer, Abstract As Ptr)
	#tag EndDelegateDeclaration

	#tag Method, Flags = &h21
		Private Sub SetCallback(Type As CallbackType, Handler As Variant)
		  Select Case True
		  Case Type = CallbackType.Ignore And Handler IsA IgnoreCallback
		    Dim d As IgnoreCallback = Handler
		    Call libssh2_session_callback_set(mSession, Type, d)
		    
		  Case Type = CallbackType.Debug And Handler IsA DebugCallback
		    Dim d As DebugCallback = Handler
		    Call libssh2_session_callback_set(mSession, Type, d)
		    
		  Case Type = CallbackType.Disconnect And Handler IsA DisconnectCallback
		    Dim d As DisconnectCallback = Handler
		    Call libssh2_session_callback_set(mSession, Type, d)
		    
		  Case Type = CallbackType.MACError And Handler IsA MACErrorCallback
		    Dim d As MACErrorCallback = Handler
		    Call libssh2_session_callback_set(mSession, Type, d)
		    
		  Case Type = CallbackType.X11 And Handler IsA X11OpenCallback
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

	#tag DelegateDeclaration, Flags = &h21
		Private Delegate Sub X11OpenCallback(Session As Ptr, Channel As Ptr, Host As Ptr, Port As Integer, Abstract As Ptr)
	#tag EndDelegateDeclaration


	#tag Hook, Flags = &h0
		Event Authenticate(ByRef Signature As String, ByRef Data As String) As Boolean
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
		Event MACError(Packet As Ptr, PacketLength As Integer) As Boolean
	#tag EndHook

	#tag Hook, Flags = &h0
		Event PasswordChangeRequest(ByRef NewPassword As String) As Boolean
	#tag EndHook

	#tag Hook, Flags = &h0
		Event X11Open(Channel As SSH.Channel, Host As String, Port As Integer)
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

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mKnownHosts = Nil Then mKnownHosts = New SSH.KnownHosts(Me)
			  Return mKnownHosts
			End Get
		#tag EndGetter
		KnownHosts As SSH.KnownHosts
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mInit As SSHInit
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mKeepAlivePeriod As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mKnownHosts As SSH.KnownHosts
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastError As Integer
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
			    Me.SetCallback(CallbackType.Debug, AddressOf DebugHandler)
			  Else
			    Me.SetCallback(CallbackType.Debug, Nil)
			  End If
			  mVerbose = value
			End Set
		#tag EndSetter
		Verbose As Boolean
	#tag EndComputedProperty


	#tag Constant, Name = LIBSSH2_FLAG_COMPRESS , Type = Double, Dynamic = False, Default = \"2", Scope = Protected
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

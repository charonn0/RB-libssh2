#tag Class
Protected Class Session
	#tag Method, Flags = &h0
		Sub Connect()
		  If mSession = Nil Then Raise New RuntimeException
		  Dim err As Integer
		  Do
		    err = libssh2_session_handshake(mSession, mSocket.Handle)
		  Loop Until err <> LIBSSH2_ERROR_EAGAIN
		  If err <> 0 Then Raise New RuntimeException
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(Socket As TCPSocket)
		  mInit = SSHInit.Init()
		  mSession = libssh2_session_init()
		  If mSession = Nil Then Raise New RuntimeException
		  mSocket = Socket
		  
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
		    If err <> 0 Then Raise New RuntimeException
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Disconnect(Description As String, Reason As SSH.DisconnectReason = SSH.DisconnectReason.AppRequested)
		  If mSession = Nil Then Return
		  Dim err As Integer = libssh2_session_disconnect_ex(mSession, Reason, Description, "")
		  If err <> 0 Then Raise New RuntimeException
		End Sub
	#tag EndMethod

	#tag DelegateDeclaration, Flags = &h21
		Private Delegate Sub DisconnectCallback(Session As Ptr, Reason As Integer, Message As Ptr, MessageLength As Integer, Language As Ptr, LanguageLength As Integer, Abstract As Ptr)
	#tag EndDelegateDeclaration

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

	#tag DelegateDeclaration, Flags = &h21
		Private Delegate Sub IgnoreCallback(Session As Ptr, Message As Ptr, MessageLength As Integer, Abstract As Ptr)
	#tag EndDelegateDeclaration

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  If mSession = Nil Then Return 0
		  Return libssh2_session_last_errno(mSession)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Listen()
		  If mSession = Nil Then Raise New RuntimeException
		  Dim err As Integer
		  Do
		    err = libssh2_session_handshake(mSession, mSocket.Handle)
		  Loop Until err <> LIBSSH2_ERROR_EAGAIN
		  If err <> 0 Then Raise New RuntimeException
		  
		End Sub
	#tag EndMethod

	#tag DelegateDeclaration, Flags = &h21
		Private Delegate Function MACErrorCallback(Session As Ptr, Packet As Ptr, PacketLength As Integer, Abstract As Ptr) As Integer
	#tag EndDelegateDeclaration

	#tag DelegateDeclaration, Flags = &h21
		Private Delegate Sub PasswordChangeRequestCallback(Session As Ptr, PasswdBuffer As Ptr, ByRef PasswdBufferLength As Integer, Abstract As Ptr)
	#tag EndDelegateDeclaration

	#tag Method, Flags = &h21
		Private Sub SetCallback(Type As CallbackType, Handler As Variant)
		  If (Type = CallbackType.Ignore And Handler IsA IgnoreCallback) Or _
		    (Type = CallbackType.Debug And Handler IsA DebugCallback) Or _
		    (Type = CallbackType.Disconnect And Handler IsA DisconnectCallback) Or _
		    (Type = CallbackType.MACError And Handler IsA MACErrorCallback) Or _
		    (Type = CallbackType.X11 And Handler IsA X11OpenCallback) Then
		    
		    Call libssh2_session_callback_set(mSession, Type, Handler.PtrValue)
		    
		  ElseIf Handler Is Nil Then
		    Call libssh2_session_callback_set(mSession, Type, Nil)
		    
		  Else
		    Raise New RuntimeException
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetFlag(Flag As Integer, Value As Integer)
		  Dim err As Integer = libssh2_session_flag(mSession, Flag, Value)
		  If err <> 0 Then Raise New RuntimeException
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetLocalBanner(BannerText As String)
		  Dim err As Integer = libssh2_session_banner_set(mSession, BannerText)
		  If err <> 0 Then Raise New RuntimeException
		End Sub
	#tag EndMethod

	#tag DelegateDeclaration, Flags = &h21
		Private Delegate Sub X11OpenCallback(Session As Ptr, Channel As Ptr, Host As Ptr, Port As Integer, Abstract As Ptr)
	#tag EndDelegateDeclaration


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

	#tag Property, Flags = &h21
		Private mInit As SSHInit
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSession As Ptr
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSocket As TCPSocket
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
	#tag EndViewBehavior
End Class
#tag EndClass

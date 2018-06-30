#tag Class
Protected Class Session
Implements Readable, Writeable
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
		  mSession = libssh2_session_init()
		  If mSession = Nil Then Raise New RuntimeException
		  mSocket = Socket
		  mInit = SSHInit.Init()
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
		Sub Disconnect(Description As String, Reason As Integer = SSH_DISCONNECT_BY_APPLICATION)
		  If mSession = Nil Then Return
		  Dim err As Integer = libssh2_session_disconnect_ex(mSession, Reason, Description, "")
		  If err <> 0 Then Raise New RuntimeException
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function EOF() As Boolean
		  // Part of the Readable interface.
		  #error  // (don't forget to implement this method!)
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Execute(CommandLine As String)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Flush()
		  // Part of the Writeable interface.
		  #error  // (don't forget to implement this method!)
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetRemoteBanner() As String
		  Dim mb As MemoryBlock = libssh2_session_banner_get(mSession)
		  If mb <> Nil Then Return mb.CString(0)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Handle() As Ptr
		  Return mSession
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  If mSession = Nil Then Return 0
		  Return libssh2_session_last_errno(mSession)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Read(Count As Integer, encoding As TextEncoding = Nil) As String
		  // Part of the Readable interface.
		  #error  // (don't forget to implement this method!)
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadError() As Boolean
		  // Part of the Readable interface.
		  #error  // (don't forget to implement this method!)
		  
		  
		End Function
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

	#tag Method, Flags = &h0
		Sub Write(text As String)
		  // Part of the Writeable interface.
		  #error  // (don't forget to implement this method!)
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function WriteError() As Boolean
		  // Part of the Writeable interface.
		  #error  // (don't forget to implement this method!)
		  
		  
		End Function
	#tag EndMethod


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
End Class
#tag EndClass

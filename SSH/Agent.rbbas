#tag Class
Protected Class Agent
	#tag Method, Flags = &h0
		Function Authenticate(Username As String, KeyIndex As Integer) As Boolean
		  Dim identity As Ptr = GetIdentity(KeyIndex)
		  mLastError = libssh2_agent_userauth(mAgent, Username, identity)
		  Return mLastError = 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Comment(Index As Integer) As String
		  Dim struct As libssh2_agent_publickey = Me.GetIdentity(Index).libssh2_agent_publickey
		  Dim mb As MemoryBlock = struct.Comment
		  If mb <> Nil Then Return mb.CString(0)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Connect() As Boolean
		  Do
		    mLastError = libssh2_agent_connect(mAgent)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then Return False
		  mConnected = True
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(Session As SSH.Session)
		  mInit = SSHInit.GetInstance()
		  mAgent = libssh2_agent_init(Session.Handle)
		  If mAgent = Nil Then Raise New SSHException(ERR_INIT_FAILED)
		  mSession = Session
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Count() As Integer
		  Dim c As Integer
		  Dim prev As Ptr
		  Do
		    Dim id As Ptr
		    mLastError = libssh2_agent_get_identity(mAgent, id, prev)
		    If mLastError < 0 Then Raise New SSHException(mLastError)
		    If mLastError = 1 Then Return c
		    c = c + 1
		    prev = id
		  Loop
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If Me.IsConnected Then Me.Disconnect()
		  If mAgent <> Nil Then libssh2_agent_free(mAgent)
		  mAgent = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Disconnect()
		  If mAgent = Nil Or Not mConnected Then Return
		  Do
		    mLastError = libssh2_agent_disconnect(mAgent)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
		  mConnected = False
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GetIdentity(Index As Integer) As Ptr
		  Dim prev As Ptr
		  Dim c As Integer
		  Do
		    Dim this As Ptr
		    mLastError = libssh2_agent_get_identity(mAgent, this, prev)
		    If mLastError <> 0 Then Raise New SSHException(mLastError)
		    If c = Index Then Return this
		    c = c + 1
		    prev = this
		  Loop Until mLastError <> 0
		  If mLastError = 1 Then Raise New OutOfBoundsException
		  Raise New SSHException(mLastError)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Handle() As Ptr
		  Return mAgent
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function PublicKey(Index As Integer) As MemoryBlock
		  Dim struct As libssh2_agent_publickey = Me.GetIdentity(Index).libssh2_agent_publickey
		  Dim mb As MemoryBlock = struct.Blob
		  Return mb.StringValue(0, struct.BlobLength)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Refresh() As Boolean
		  mLastError = libssh2_agent_list_identities(mAgent)
		  Return mLastError = 0
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mConnected
			End Get
		#tag EndGetter
		IsConnected As Boolean
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mAgent As Ptr
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mConnected As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mInit As SSHInit
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastError As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSession As SSH.Session
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mSession
			End Get
		#tag EndGetter
		Session As SSH.Session
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

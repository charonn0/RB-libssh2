#tag Class
Protected Class Agent
	#tag Method, Flags = &h0
		Function Authenticate(Username As String, KeyIndex As Integer) As Boolean
		  ' Authenticate the current Session with the specified Username
		  ' using the key at KeyIndex in the Agent's list of keys.
		  
		  Dim identity As Ptr = GetIdentity(KeyIndex)
		  mLastError = libssh2_agent_userauth(mAgent, Username, identity)
		  Return mLastError = 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Comment(Index As Integer) As String
		  ' Returns the comment (if any) for the key at Index in the Agent's list of keys.
		  
		  Dim struct As libssh2_agent_publickey = Me.GetIdentity(Index).libssh2_agent_publickey
		  Dim mb As MemoryBlock = struct.Comment
		  If mb <> Nil Then Return mb.CString(0)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Connect() As Boolean
		  ' Connect to the local key management service.
		  
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
		  ' Creates a new instance of Agent which can be used for authenticating
		  ' the specified Session.
		  
		  mSession = Session
		  mAgent = libssh2_agent_init(Session.Handle)
		  If mAgent = Nil Then
		    mLastError = ERR_INIT_FAILED
		    Raise New SSHException(Me)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Count() As Integer
		  ' Returns the number of keys in the Agent's list. The index of the last key is Count-1.
		  ' Be sure to call Connect() and then Refresh() before asking for the Count.
		  
		  Dim c As Integer
		  Dim prev As Ptr
		  Do
		    Dim id As Ptr
		    mLastError = libssh2_agent_get_identity(mAgent, id, prev)
		    If mLastError < 0 Then Raise New SSHException(Me)
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
		  ' Disconnect from the local key management service. Called automatically by
		  ' the Destructor method.
		  
		  If mAgent = Nil Or Not mConnected Then Return
		  Do
		    mLastError = libssh2_agent_disconnect(mAgent)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then Raise New SSHException(Me)
		  mConnected = False
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GetIdentity(Index As Integer) As Ptr
		  ' Returns a Ptr to the libssh2_agent_publickey structure at Index.
		  
		  Dim prev As Ptr
		  Dim c As Integer
		  Do
		    Dim this As Ptr
		    mLastError = libssh2_agent_get_identity(mAgent, this, prev)
		    If mLastError <> 0 Then Exit Do
		    If c = Index Then Return this
		    c = c + 1
		    prev = this
		  Loop Until mLastError <> 0
		  If mLastError = 1 Then mLastError = ERR_INVALID_INDEX
		  Raise New SSHException(Me)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Handle() As Ptr
		  Return mAgent
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function PublicKey(Index As Integer) As MemoryBlock
		  ' Returns a copy of the PublicKey at Index in the Agent's list of keys.
		  
		  Dim struct As libssh2_agent_publickey = Me.GetIdentity(Index).libssh2_agent_publickey
		  Dim mb As MemoryBlock = struct.Blob
		  Return mb.StringValue(0, struct.BlobLength)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Refresh() As Boolean
		  ' Requests the Agent's list of keys. Must be called after Connect().
		  
		  mLastError = libssh2_agent_list_identities(mAgent)
		  Return mLastError = 0
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns True if we're connected to the local Agent service.
			  
			  return mConnected
			End Get
		#tag EndGetter
		IsConnected As Boolean
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns the most recent libssh2 error code for this instance
			  
			  Return mLastError
			End Get
		#tag EndGetter
		LastError As Int32
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mAgent As Ptr
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mConnected As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastError As Int32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSession As SSH.Session
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mAgent <> Nil Then Return libssh2_agent_get_identity_path(mAgent)
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If mAgent <> Nil And value <> "" Then libssh2_agent_set_identity_path(mAgent, value)
			End Set
		#tag EndSetter
		Path As String
	#tag EndComputedProperty

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

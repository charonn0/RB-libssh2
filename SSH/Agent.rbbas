#tag Class
Protected Class Agent
	#tag Method, Flags = &h0
		Sub Authenticate(Username As String, Identity As Ptr)
		  mLastError = libssh2_agent_userauth(mAgent, Username, Identity)
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Connect()
		  Do
		    mLastError = libssh2_agent_connect(mAgent)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(Session As SSH.Session)
		  mAgent = libssh2_agent_init(Session.Handle)
		  If mAgent = Nil Then Raise New SSHException(0)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If mAgent <> Nil Then libssh2_agent_free(mAgent)
		  mAgent = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Disconnect()
		  Do
		    mLastError = libssh2_agent_disconnect(mAgent)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Identity(Index As Integer) As Ptr
		  Dim c As Integer
		  Dim prev As Ptr
		  Do
		    Dim id As Ptr
		    mLastError = libssh2_agent_get_identity(mAgent, id, prev)
		    If mLastError < 0 Then Raise New SSHException(mLastError)
		    If c = Index Then Return id
		    If mLastError = 1 Then Raise New OutOfBoundsException
		    c = c + 1
		    prev = id
		  Loop
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub ListIdentities()
		  mLastError = libssh2_agent_list_identities(mAgent)
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mAgent As Ptr
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastError As Integer
	#tag EndProperty


End Class
#tag EndClass

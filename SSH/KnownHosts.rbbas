#tag Class
Protected Class KnownHosts
	#tag Method, Flags = &h0
		Sub AddHost(ActiveSession As SSH.Session, Comment As String = "")
		  ' Add the ActiveSession's host+key to the list of known hosts.
		  
		  Dim fingerprint As MemoryBlock = ActiveSession.HostKey
		  Dim type As Integer
		  If ActiveSession.HostKeyType = LIBSSH2_HOSTKEY_TYPE_RSA Then
		    type = LIBSSH2_KNOWNHOST_KEY_SSHRSA
		  Else
		    type = LIBSSH2_KNOWNHOST_KEY_SSHDSS
		  End If
		  type = type Or LIBSSH2_KNOWNHOST_TYPE_PLAIN Or LIBSSH2_KNOWNHOST_KEYENC_RAW
		  AddHost(ActiveSession.RemoteHost, ActiveSession.RemotePort, fingerprint, Comment, type)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AddHost(Host As String, Port As Integer = 0, Key As MemoryBlock, Comment As MemoryBlock, Type As Integer)
		  ' Add the Host+Key to the list of known hosts.
		  
		  If Port > 0 And Port <> 22 Then Host = "[" + Host + "]:" + Str(Port, "####0")
		  Dim store As libssh2_knownhost
		  If Comment = Nil Then
		    mLastError = libssh2_knownhost_addc(mKnownHosts, Host, Nil, Key, Key.Size, Nil, 0, Type, store)
		  Else
		    mLastError = libssh2_knownhost_addc(mKnownHosts, Host, Nil, Key, Key.Size, Comment, Comment.Size, Type, store)
		  End If
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(Session As SSH.Session)
		  mInit = SSHInit.GetInstance()
		  mKnownHosts = libssh2_knownhost_init(Session.Handle)
		  If mKnownHosts = Nil Then Raise New SSHException(Session.GetLastError)
		  mSession = Session
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(Session As SSH.Session, KnownHostsFile As FolderItem)
		  Me.Constructor(Session)
		  #If Not DebugBuild Then
		    Call Me.Load(KnownHostsFile)
		  #Else
		    Dim c As Integer = Me.Load(KnownHostsFile)
		    If c <> Me.Count Then Break
		  #EndIf
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Count() As Integer
		  ' Returns the number of hosts in the list.
		  
		  Dim this, prev As Ptr
		  Dim c As Integer
		  Do
		    mLastError = libssh2_knownhost_get(mKnownHosts, this, prev)
		    If mLastError <> 0 Then Return c
		    c = c + 1
		    prev = this
		  Loop Until prev = Nil
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub DeleteHost(Index As Integer)
		  ' Delete the host at Index from the list
		  
		  Dim this As libssh2_knownhost = Me.GetEntry(Index).libssh2_knownhost
		  DeleteHost(this)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub DeleteHost(Host As libssh2_knownhost)
		  ' Delete the Host from the list
		  
		  mLastError = libssh2_knownhost_del(mKnownHosts, Host)
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub DeleteHost(ActiveSession As SSH.Session)
		  ' Delete the ActiveSession's host+key from the list
		  
		  Dim fingerprint As MemoryBlock = ActiveSession.HostKey
		  Dim type As Integer
		  If ActiveSession.HostKeyType = LIBSSH2_HOSTKEY_TYPE_RSA Then
		    type = LIBSSH2_KNOWNHOST_KEY_SSHRSA
		  Else
		    type = LIBSSH2_KNOWNHOST_KEY_SSHDSS
		  End If
		  type = type Or LIBSSH2_KNOWNHOST_TYPE_PLAIN Or LIBSSH2_KNOWNHOST_KEYENC_RAW
		  DeleteHost(ActiveSession.RemoteHost, ActiveSession.RemotePort, fingerprint, type)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub DeleteHost(Host As String, Port As Integer = 0, Key As MemoryBlock, Type As Integer)
		  ' Delete the Host+Key from the list
		  
		  Dim this As libssh2_knownhost
		  If Me.Lookup(Host, Port, Key, Type, this) Then
		    DeleteHost(this)
		  Else
		    Raise New KeyNotFoundException
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If mKnownHosts <> Nil Then libssh2_knownhost_free(mKnownHosts)
		  mKnownHosts = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GetEntry(Index As Integer) As Ptr
		  Dim prev As Ptr
		  Dim c As Integer
		  Do
		    Dim this As Ptr
		    mLastError = libssh2_knownhost_get(mKnownHosts, this, prev)
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
		  Return mKnownHosts
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Key(Index As Integer) As MemoryBlock
		  ' Returns the key of the fingerprint at Index
		  
		  Dim struct As libssh2_knownhost = Me.GetEntry(Index).libssh2_knownhost
		  Dim mb As MemoryBlock = struct.Key
		  Return mb.CString(0)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Load(KnownHostsFile As FolderItem) As Integer
		  ' Load a list of known hosts from a file.
		  
		  Return libssh2_knownhost_readfile(mKnownHosts, KnownHostsFile.AbsolutePath, LIBSSH2_KNOWNHOST_FILE_OPENSSH)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Load(KnownHostLine As String) As Boolean
		  ' Load from a known host line
		  
		  Dim mb As MemoryBlock = KnownHostLine
		  mLastError = libssh2_knownhost_readline(mKnownHosts, mb, mb.Size, LIBSSH2_KNOWNHOST_FILE_OPENSSH)
		  Return mLastError = 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Lookup(Session As SSH.Session) As Boolean
		  ' Returns True if the Session's host+key was found
		  
		  Dim host As String = Session.RemoteHost
		  Dim port As Integer = Session.RemotePort
		  Dim key As MemoryBlock = Session.HostKey
		  Dim type As Integer = LIBSSH2_KNOWNHOST_TYPE_PLAIN Or LIBSSH2_KNOWNHOST_KEYENC_RAW
		  Return Me.Lookup(host, port, key, type)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Lookup(Host As String, Port As Integer = 0, Key As MemoryBlock, Type As Integer) As Boolean
		  ' Returns True if the host+key was found
		  
		  Dim Store As libssh2_knownhost
		  Return Lookup(Host, Port, Key, Type, Store)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Lookup(Host As String, Port As Integer, Key As MemoryBlock, Type As Integer, ByRef Store As libssh2_knownhost) As Boolean
		  ' Returns True and populates the Store parameter if the host+key was found.
		  ' Check LastError if this method returns False.
		  
		  If Key = Nil Then Return False
		  If Port = 0 Then
		    mLastError = libssh2_knownhost_check(mKnownHosts, Host, Key, Key.Size, Type, Store)
		  Else
		    mLastError = libssh2_knownhost_checkp(mKnownHosts, Host, Port, Key, Key.Size, Type, Store)
		  End If
		  ' libssh2_knownhost_check doesn't return a standard error code
		  Select Case mLastError
		  Case 0 ' host was found and keys match
		    Return True
		  Case LIBSSH2_KNOWNHOST_CHECK_MISMATCH ' host was found but keys don't match!
		    mLastError = ERR_HOSTKEY_MISMATCH
		  Case LIBSSH2_KNOWNHOST_CHECK_NOTFOUND ' host not found
		    mLastError = ERR_HOSTKEY_NOTFOUND
		  Else
		    Raise New SSHException(mLastError)
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Name(Index As Integer) As MemoryBlock
		  ' Returns the host name of the fingerprint at Index
		  
		  Dim struct As libssh2_knownhost = Me.GetEntry(Index).libssh2_knownhost
		  Dim mb As MemoryBlock = struct.Name
		  Return mb.CString(0)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Save(KnownHostsFile As FolderItem)
		  ' Save the list of known hosts to a file
		  
		  mLastError = libssh2_knownhost_writefile(mKnownHosts, KnownHostsFile.AbsolutePath, LIBSSH2_KNOWNHOST_FILE_OPENSSH)
		  If mLastError <> 0 Then Raise New IOException
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function StringValue(Index As Integer) As String
		  ' Export the Host+Key at Index as a known host line
		  
		  Dim tmp As Ptr = Me.GetEntry(Index)
		  Dim sz As Integer
		  Call libssh2_knownhost_writeline(mKnownHosts, tmp, Nil, 0, sz, LIBSSH2_KNOWNHOST_FILE_OPENSSH)
		  If sz > 0 Then
		    Dim buffer As New MemoryBlock(sz + 1)
		    mLastError = libssh2_knownhost_writeline(mKnownHosts, tmp, buffer, buffer.Size, sz, LIBSSH2_KNOWNHOST_FILE_OPENSSH)
		    If mLastError = 0 Then Return buffer.StringValue(0, sz)
		  End If
		  
		End Function
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mInit As SSHInit
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mKnownHosts As Ptr
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


	#tag Constant, Name = LIBSSH2_KNOWNHOST_FILE_OPENSSH, Type = Double, Dynamic = False, Default = \"1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_KNOWNHOST_KEYENC_BASE64, Type = Double, Dynamic = False, Default = \"&h00020000", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_KNOWNHOST_KEYENC_MASK, Type = Double, Dynamic = False, Default = \"&h00030000", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_KNOWNHOST_KEYENC_RAW, Type = Double, Dynamic = False, Default = \"&h00010000", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_KNOWNHOST_KEY_MASK, Type = Double, Dynamic = False, Default = \"&h000C0000", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_KNOWNHOST_KEY_RSA1, Type = Double, Dynamic = False, Default = \"&h00040000", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_KNOWNHOST_KEY_SHIFT, Type = Double, Dynamic = False, Default = \"&h00000012", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_KNOWNHOST_KEY_SSHDSS, Type = Double, Dynamic = False, Default = \"&h000C0000", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_KNOWNHOST_KEY_SSHRSA, Type = Double, Dynamic = False, Default = \"&h00080000", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_KNOWNHOST_TYPE_PLAIN, Type = Double, Dynamic = False, Default = \"1", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_KNOWNHOST_TYPE_SHA1, Type = Double, Dynamic = False, Default = \"2", Scope = Public
	#tag EndConstant


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

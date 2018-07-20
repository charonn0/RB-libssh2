#tag Class
Protected Class KnownHosts
	#tag Method, Flags = &h0
		Sub AddHost(ActiveSession As SSH.Session, Comment As String = "")
		  Dim fingerprint As MemoryBlock = ActiveSession.HostKey
		  Dim type As Integer
		  If ActiveSession.HostKeyType = LIBSSH2_HOSTKEY_TYPE_RSA Then
		    type = LIBSSH2_KNOWNHOST_KEY_SSHRSA
		  Else
		    type = LIBSSH2_KNOWNHOST_KEY_SSHDSS
		  End If
		  AddHost(ActiveSession.RemoteHost, ActiveSession.RemotePort, fingerprint, Comment, type)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AddHost(Host As String, Port As Integer = 0, Key As MemoryBlock, Comment As MemoryBlock, Type As Integer)
		  If Port > 0 And Port <> 22 Then Host = "[" + Host + "]:" + Str(Port, "####0")
		  Dim store As libssh2_knownhost
		  Type = Type Or LIBSSH2_KNOWNHOST_TYPE_PLAIN Or LIBSSH2_KNOWNHOST_KEYENC_RAW
		  If Comment = Nil Then
		    mLastError = libssh2_knownhost_addc(mKnownHosts, Host, Nil, Key, Key.Size, Nil, 0, Type, store)
		  Else
		    mLastError = libssh2_knownhost_addc(mKnownHosts, Host, Nil, Key, Key.Size, Comment, Comment.Size, Type, store)
		  End If
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Check(Session As SSH.Session) As Boolean
		  Dim host As String = Session.RemoteHost
		  Dim port As Integer = Session.RemotePort
		  Dim key As MemoryBlock = Session.HostKey
		  Dim type As Integer = LIBSSH2_KNOWNHOST_TYPE_PLAIN Or LIBSSH2_KNOWNHOST_KEYENC_RAW
		  Return Me.Lookup(host, port, key, type)
		End Function
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
		Function Count() As Integer
		  Dim this, prev As libssh2_knownhost
		  Dim c As Integer
		  Do
		    mLastError = libssh2_knownhost_get(mKnownHosts, this, prev)
		    c = c + 1
		    prev = this
		  Loop Until mLastError <> 0
		  Return c
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub DeleteHost(Index As Integer)
		  Dim tmp As libssh2_knownhost = Me.Operator_Subscript(Index)
		  mLastError = libssh2_knownhost_del(mKnownHosts, tmp)
		  If mLastError <> 0 Then Raise New RuntimeException
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub DeleteHost(Host As String, Port As Integer = 0, Key As MemoryBlock, Type As Integer)
		  Dim tmp As libssh2_knownhost
		  If Me.Lookup(Host, Port, Key, Type, tmp) Then
		    mLastError = libssh2_knownhost_del(mKnownHosts, tmp)
		    If mLastError <> 0 Then Raise New RuntimeException
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

	#tag Method, Flags = &h0
		Function Handle() As Ptr
		  Return mKnownHosts
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Item(Index As Integer) As libssh2_knownhost
		  Return Me.Operator_Subscript(Index)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Load(KnownHostsFile As FolderItem) As Integer
		  Return libssh2_knownhost_readfile(mKnownHosts, KnownHostsFile.AbsolutePath, LIBSSH2_KNOWNHOST_FILE_OPENSSH)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Load(KnownHostLine As String) As Boolean
		  Dim mb As MemoryBlock = KnownHostLine
		  mLastError = libssh2_knownhost_readline(mKnownHosts, mb, mb.Size, LIBSSH2_KNOWNHOST_FILE_OPENSSH)
		  Return mLastError = 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Lookup(Host As String, Port As Integer = 0, Key As MemoryBlock, Type As Integer) As Boolean
		  Dim Store As libssh2_knownhost
		  Return Lookup(Host, Port, Key, Type, Store)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Lookup(Host As String, Port As Integer, Key As MemoryBlock, Type As Integer, ByRef Store As libssh2_knownhost) As Boolean
		  If Port = 0 Then
		    mLastError = libssh2_knownhost_check(mKnownHosts, Host, Key, Key.Size, Type, Store)
		  Else
		    mLastError = libssh2_knownhost_checkp(mKnownHosts, Host, Port, Key, Key.Size, Type, Store)
		  End If
		  Return mLastError = 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Operator_Subscript(Index As Integer) As libssh2_knownhost
		  Dim prev As libssh2_knownhost
		  Dim c As Integer
		  Do
		    Dim this As libssh2_knownhost
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
		Sub Save(KnownHostsFile As FolderItem)
		  mLastError = libssh2_knownhost_writefile(mKnownHosts, KnownHostsFile.AbsolutePath, LIBSSH2_KNOWNHOST_FILE_OPENSSH)
		  If mLastError <> 0 Then Raise New IOException
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function StringValue(Index As Integer) As String
		  Dim tmp As libssh2_knownhost = Me.Operator_Subscript(Index)
		  Dim sz As Integer
		  Call libssh2_knownhost_writeline(mKnownHosts, tmp, Nil, 0, sz, LIBSSH2_KNOWNHOST_FILE_OPENSSH)
		  If sz > 0 Then
		    Dim buffer As New MemoryBlock(sz)
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

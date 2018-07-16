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
		  Dim tmp As Ptr
		  Type = LIBSSH2_KNOWNHOST_TYPE_PLAIN Or LIBSSH2_KNOWNHOST_KEYENC_RAW
		  If Comment = Nil Then Comment = Chr(0)
		  mLastError = libssh2_knownhost_addc(mKnownHosts, Host, Nil, Key, Key.Size, Comment, Comment.Size, Type, tmp)
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Check(Host As String, Port As Integer = 0, Key As MemoryBlock, Type As Integer) As Boolean
		  Return Me.GetEntry(Host, Port, Key, Type) <> Nil
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(Session As SSH.Session)
		  mInit = SSHInit.GetInstance()
		  mKnownHosts = libssh2_knownhost_init(Session.Handle)
		  If mKnownHosts = Nil Then Raise New RuntimeException
		  mSession = Session
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Count() As Integer
		  Dim this, prev As Ptr
		  Dim c As Integer
		  Do
		    mLastError = libssh2_knownhost_get(mKnownHosts, this, prev)
		    If this <> Nil Then c = c + 1
		    prev = this
		    this = Nil
		  Loop Until prev = Nil
		  Return c
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub DeleteHost(Index As Integer)
		  Dim tmp As Ptr = Me.Operator_Subscript(Index)
		  mLastError = libssh2_knownhost_del(mKnownHosts, tmp)
		  If mLastError <> 0 Then Raise New RuntimeException
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub DeleteHost(Host As String, Port As Integer = 0, Key As MemoryBlock, Type As Integer)
		  Dim tmp As Ptr = Me.GetEntry(Host, Port, Key, Type)
		  If tmp = Nil Then Raise New KeyNotFoundException
		  mLastError = libssh2_knownhost_del(mKnownHosts, tmp)
		  If mLastError <> 0 Then Raise New RuntimeException
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If mKnownHosts <> Nil Then libssh2_knownhost_free(mKnownHosts)
		  mKnownHosts = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GetEntry(Host As String, Port As Integer = 0, Key As MemoryBlock, Type As Integer) As Ptr
		  Dim tmp As Ptr
		  If Port = 0 Then
		    mLastError = libssh2_knownhost_check(mKnownHosts, Host, Key, Key.Size, Type, tmp)
		  Else
		    mLastError = libssh2_knownhost_checkp(mKnownHosts, Host, Port, Key, Key.Size, Type, tmp)
		  End If
		  If mLastError = 0 Then Return tmp
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Handle() As Ptr
		  Return mKnownHosts
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Item(Index As Integer) As Ptr
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
		Function Operator_Subscript(Index As Integer) As Ptr
		  Dim this, prev As Ptr
		  Dim c As Integer
		  Do
		    mLastError = libssh2_knownhost_get(mKnownHosts, this, prev)
		    If c = Index Then Return this
		    If this <> Nil Then c = c + 1
		    prev = this
		    this = Nil
		  Loop Until prev = Nil
		  Raise New OutOfBoundsException
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
		  Dim tmp As Ptr = Me.Operator_Subscript(Index)
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

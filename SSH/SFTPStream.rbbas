#tag Class
Protected Class SFTPStream
Implements SSHStream
	#tag Method, Flags = &h0
		Sub Close()
		  // Part of the SSHStream interface.
		  If mStream <> Nil Then
		    Do
		      mLastError = libssh2_sftp_close_handle(mStream)
		    Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  End If
		  mStream = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Constructor(Session As SSH.SFTPSession, RemoteName As String, Flags As Integer, Mode As Integer, Directory As Boolean = False)
		  mInit = SSHInit.GetInstance()
		  Dim fn As MemoryBlock = RemoteName
		  If Not Directory Then
		    mStream = libssh2_sftp_open_ex(Session.Handle, fn, fn.Size, Flags, Mode, LIBSSH2_SFTP_OPENFILE)
		  Else
		    mStream = libssh2_sftp_open_ex(Session.Handle, fn, fn.Size, Flags, Mode, LIBSSH2_SFTP_OPENDIR)
		  End If
		  If mStream = Nil Then
		    Dim err As New SSHException(Session)
		    err.Message = err.Message + EndOfLine + SSH.SFTPErrorName(Session.LastStatusCode)
		    Raise err
		  End If
		  
		  mSession = Session
		  mDirectory = Directory
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  Me.Close()
		  mStream = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function EndOfFile() As Boolean
		  // Part of the Readable interface.
		  Return EOF()
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function EOF() As Boolean
		  // Part of the Readable interface.
		  Return mEOF
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Flush()
		  // Part of the Writeable interface.
		  ' Not all servers support this. If that's the case then LastError will be LIBSSH2_ERROR_SFTP_PROTOCOL
		  If mDirectory Then Raise New IOException
		  Do
		    mLastError = libssh2_sftp_fsync(mStream)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 And mLastError <> LIBSSH2_ERROR_SFTP_PROTOCOL Then Raise New SSHException(mLastError)
		  
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Handle() As Ptr
		  Return mStream
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Int32
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function PermissionsToMode(p As Permissions) As UInt32
		  Const TGEXEC = &o00010
		  Const TGREAD = &o00040
		  Const TGWRITE = &o00020
		  Const TOEXEC = &o00001
		  Const TOREAD = &o00004
		  Const TOWRITE = &o00002
		  Const TSGID = &o02000
		  Const TSUID = &o04000
		  Const TSVTX = &o01000
		  Const TUEXEC = &o00100
		  Const TUREAD = &o00400
		  Const TUWRITE = &o00200
		  
		  Dim mask As UInt32
		  If p.GroupExecute Then mask = mask Or TGEXEC
		  If p.GroupRead Then mask = mask Or TGREAD
		  If p.GroupWrite Then mask = mask Or TGWRITE
		  
		  If p.OwnerExecute Then mask = mask Or TUEXEC
		  If p.OwnerRead Then mask = mask Or TUREAD
		  If p.OwnerWrite Then mask = mask Or TUWRITE
		  
		  If p.OthersExecute Then mask = mask Or TOEXEC
		  If p.OthersRead Then mask = mask Or TOREAD
		  If p.OthersWrite Then mask = mask Or TOWRITE
		  
		  Return mask
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Read(Count As Integer, encoding As TextEncoding = Nil) As String
		  // Part of the Readable interface.
		  If mDirectory Then ' read directory listing
		    Dim longentry As MemoryBlock
		    Dim attribs As LIBSSH2_SFTP_ATTRIBUTES
		    Return ReadDirectoryEntry(attribs, longentry, encoding)
		  End If
		  
		  Dim buffer As New MemoryBlock(Count)
		  Do
		    mLastError = libssh2_sftp_read(mStream, buffer, buffer.Size)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  
		  If mLastError > 0 Then ' error is the size
		    buffer.Size = mLastError
		    Return DefineEncoding(buffer, encoding)
		  ElseIf mLastError = 0 Then
		    mEOF = True
		  Else
		    Raise New SSHException(mLastError)
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function ReadDirectoryEntry(ByRef SFTPAttributes As LIBSSH2_SFTP_ATTRIBUTES, ByRef LongEntry As MemoryBlock, Encoding As TextEncoding = Nil) As String
		  If Not mDirectory Then Return ""
		  Dim buffer As New MemoryBlock(1024 * 16)
		  LongEntry = New MemoryBlock(512)
		  
		  Do
		    mLastError = libssh2_sftp_readdir_ex(mStream, buffer, buffer.Size, LongEntry, LongEntry.Size, SFTPAttributes)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  
		  If mLastError > 0 Then ' error is the size
		    buffer.Size = mLastError
		    Return DefineEncoding(buffer, Encoding)
		  ElseIf mLastError = 0 Then
		    mEOF = True
		  Else
		    Raise New SSHException(mLastError)
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadError() As Boolean
		  // Part of the Readable interface.
		  
		  Return mLastError <> 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Write(text As String)
		  // Part of the Writeable interface.
		  ' Waits for the sent data to be ack'd before sending the rest
		  
		  If mDirectory Then Raise New IOException
		  Dim buffer As MemoryBlock = text
		  Dim size As Integer = buffer.Size
		  Do
		    mLastError = libssh2_sftp_write(mStream, buffer, size)
		    Select Case mLastError
		    Case 0, LIBSSH2_ERROR_EAGAIN ' nothing ack'd yet
		      Continue
		      
		    Case Is > 0 ' the amount ack'd
		      If mLastError = size Then
		        Exit Do ' done
		      Else
		        ' update the size and call libssh2_sftp_write() again
		        size = size - mLastError
		        Continue
		      End If
		      
		    Case Is < 0 ' error
		      Exit Do
		    End Select
		  Loop
		  If mLastError < 0 Then Raise New SSHException(mLastError)
		  mLastError = 0
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function WriteError() As Boolean
		  // Part of the Writeable interface.
		  Return mLastError <> 0
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Dim attribs As LIBSSH2_SFTP_ATTRIBUTES
			  Do
			    mLastError = libssh2_sftp_fstat_ex(mStream, attribs, 0)
			  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
			  
			  If BitAnd(attribs.Flags, LIBSSH2_SFTP_ATTR_ACMODTIME) = LIBSSH2_SFTP_ATTR_ACMODTIME Then 
			    Dim d As New Date(1970, 1, 1, 0, 0, 0, 0.0) 'UNIX epoch
			    d.TotalSeconds = d.TotalSeconds + attribs.ATime
			    Return d
			  End If
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  Dim attribs As LIBSSH2_SFTP_ATTRIBUTES
			  Do
			    mLastError = libssh2_sftp_fstat_ex(mStream, attribs, 0)
			  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
			  
			  If BitAnd(attribs.Flags, LIBSSH2_SFTP_ATTR_SIZE) <> LIBSSH2_SFTP_ATTR_SIZE Then Return ' atime not settable
			  
			  If BitAnd(attribs.Flags, LIBSSH2_SFTP_ATTR_ACMODTIME) = LIBSSH2_SFTP_ATTR_ACMODTIME Then
			    Dim d As New Date(1970, 1, 1, 0, 0, 0, 0.0) 'UNIX epoch
			    attribs.ATime = value.TotalSeconds - d.TotalSeconds
			  End If
			  
			  
			  Do
			    mLastError = libssh2_sftp_fstat_ex(mStream, attribs, 1)
			  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
			End Set
		#tag EndSetter
		AccessTime As Date
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Dim attribs As LIBSSH2_SFTP_ATTRIBUTES
			  Do
			    mLastError = libssh2_sftp_fstat_ex(mStream, attribs, 0)
			  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
			  
			  If BitAnd(attribs.Flags, LIBSSH2_SFTP_ATTR_SIZE) = LIBSSH2_SFTP_ATTR_SIZE Then 
			    Return attribs.FileSize
			  End If
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  Dim attribs As LIBSSH2_SFTP_ATTRIBUTES
			  Do
			    mLastError = libssh2_sftp_fstat_ex(mStream, attribs, 0)
			  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
			  
			  If BitAnd(attribs.Flags, LIBSSH2_SFTP_ATTR_SIZE) <> LIBSSH2_SFTP_ATTR_SIZE Then Return ' size not settable
			  attribs.FileSize = value
			  
			  Do
			    mLastError = libssh2_sftp_fstat_ex(mStream, attribs, 1)
			  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
			End Set
		#tag EndSetter
		Length As UInt64
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mDirectory As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mEOF As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mInit As SSHInit
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastError As Int32
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Dim attribs As LIBSSH2_SFTP_ATTRIBUTES
			  Do
			    mLastError = libssh2_sftp_fstat_ex(mStream, attribs, 0)
			  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
			  
			  If BitAnd(attribs.Flags, LIBSSH2_SFTP_ATTR_PERMISSIONS) = LIBSSH2_SFTP_ATTR_PERMISSIONS Then 
			    Return New Permissions(attribs.Perms)
			  End If
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  Dim attribs As LIBSSH2_SFTP_ATTRIBUTES
			  Do
			    mLastError = libssh2_sftp_fstat_ex(mStream, attribs, 0)
			  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
			  
			  If BitAnd(attribs.Flags, LIBSSH2_SFTP_ATTR_PERMISSIONS) <> LIBSSH2_SFTP_ATTR_PERMISSIONS Then Return ' perms not settable
			  attribs.Perms = PermissionsToMode(value)
			  
			  Do
			    mLastError = libssh2_sftp_fstat_ex(mStream, attribs, 1)
			  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
			End Set
		#tag EndSetter
		Mode As Permissions
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Dim attribs As LIBSSH2_SFTP_ATTRIBUTES
			  Do
			    mLastError = libssh2_sftp_fstat_ex(mStream, attribs, 0)
			  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
			  
			  If BitAnd(attribs.Flags, LIBSSH2_SFTP_ATTR_ACMODTIME) = LIBSSH2_SFTP_ATTR_ACMODTIME Then 
			    Dim d As New Date(1970, 1, 1, 0, 0, 0, 0.0) 'UNIX epoch
			    d.TotalSeconds = d.TotalSeconds + attribs.MTime
			    Return d
			  End If
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  Dim attribs As LIBSSH2_SFTP_ATTRIBUTES
			  Do
			    mLastError = libssh2_sftp_fstat_ex(mStream, attribs, 0)
			  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
			  
			  If BitAnd(attribs.Flags, LIBSSH2_SFTP_ATTR_SIZE) <> LIBSSH2_SFTP_ATTR_SIZE Then Return ' atime not settable
			  
			  If BitAnd(attribs.Flags, LIBSSH2_SFTP_ATTR_ACMODTIME) = LIBSSH2_SFTP_ATTR_ACMODTIME Then
			    Dim d As New Date(1970, 1, 1, 0, 0, 0, 0.0) 'UNIX epoch
			    attribs.MTime = value.TotalSeconds - d.TotalSeconds
			  End If
			  
			  
			  Do
			    mLastError = libssh2_sftp_fstat_ex(mStream, attribs, 1)
			  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
			End Set
		#tag EndSetter
		ModifyTime As Date
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mSession As SSH.SFTPSession
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mStream As Ptr
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return libssh2_sftp_tell64(mStream)
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  libssh2_sftp_seek64(mStream, value)
			End Set
		#tag EndSetter
		Position As UInt64
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mSession
			End Get
		#tag EndGetter
		Session As SSH.SFTPSession
	#tag EndComputedProperty


	#tag Constant, Name = LIBSSH2_FX_BAD_MESSAGE, Type = Double, Dynamic = False, Default = \"5", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_CONNECTION_LOST, Type = Double, Dynamic = False, Default = \"7", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_DIR_NOT_EMPTY, Type = Double, Dynamic = False, Default = \"18", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_EOF, Type = Double, Dynamic = False, Default = \"1", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_FAILURE, Type = Double, Dynamic = False, Default = \"4", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_FILE_ALREADY_EXISTS, Type = Double, Dynamic = False, Default = \"11", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_INVALID_FILENAME, Type = Double, Dynamic = False, Default = \"20", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_INVALID_HANDLE, Type = Double, Dynamic = False, Default = \"9", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_LINK_LOOP, Type = Double, Dynamic = False, Default = \"21", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_LOCK_CONFLICT, Type = Double, Dynamic = False, Default = \"17", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_NOT_A_DIRECTORY, Type = Double, Dynamic = False, Default = \"19", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_NO_CONNECTION, Type = Double, Dynamic = False, Default = \"6", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_NO_MEDIA, Type = Double, Dynamic = False, Default = \"13", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_NO_SPACE_ON_FILESYSTEM, Type = Double, Dynamic = False, Default = \"14", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_NO_SUCH_FILE, Type = Double, Dynamic = False, Default = \"2", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_NO_SUCH_PATH, Type = Double, Dynamic = False, Default = \"10", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_OK, Type = Double, Dynamic = False, Default = \"0", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_OP_UNSUPPORTED, Type = Double, Dynamic = False, Default = \"8", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_PERMISSION_DENIED, Type = Double, Dynamic = False, Default = \"3", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_QUOTA_EXCEEDED, Type = Double, Dynamic = False, Default = \"15", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_UNKNOWN_PRINCIPAL, Type = Double, Dynamic = False, Default = \"16", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FX_WRITE_PROTECT, Type = Double, Dynamic = False, Default = \"12", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_ATTR_ACMODTIME, Type = Double, Dynamic = False, Default = \"8", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_ATTR_EXTENDED, Type = Double, Dynamic = False, Default = \"&h80000000", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_ATTR_PERMISSIONS, Type = Double, Dynamic = False, Default = \"4", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_ATTR_SIZE, Type = Double, Dynamic = False, Default = \"1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_ATTR_UIDGID, Type = Double, Dynamic = False, Default = \"2", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_OPENDIR, Type = Double, Dynamic = False, Default = \"1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_OPENFILE, Type = Double, Dynamic = False, Default = \"0", Scope = Private
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

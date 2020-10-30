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
		  mSession = Session
		  mDirectory = Directory
		  mFilename = RemoteName
		  
		  If Not mSession.Session.IsAuthenticated Then
		    mLastError = ERR_NOT_AUTHENTICATED
		    Raise New SSHException(Me)
		  End If
		  
		  Dim fn As MemoryBlock = RemoteName
		  If Not Directory Then
		    mStream = libssh2_sftp_open_ex(mSession.Handle, fn, fn.Size, Flags, Mode, LIBSSH2_SFTP_OPENFILE)
		  Else
		    mStream = libssh2_sftp_open_ex(mSession.Handle, fn, fn.Size, Flags, Mode, LIBSSH2_SFTP_OPENDIR)
		  End If
		  If mStream = Nil Then 
		    mLastError = mSession.Session.LastError ' -31
		    Raise New SSHException(Me)
		  End If
		  
		  
		  mAppendOnly = (BitAnd(Flags, LIBSSH2_FXF_APPEND) = LIBSSH2_FXF_APPEND)
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
		  If mLastError <> 0 And mLastError <> LIBSSH2_ERROR_SFTP_PROTOCOL Then Raise New SSHException(Me)
		  
		  
		  
		End Sub
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
		    Raise New SSHException(Me)
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
		    Raise New SSHException(Me)
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
		  If text.LenB = 0 Then Return
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
		  If mLastError < 0 Then Raise New SSHException(Me)
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
			  If mStream = Nil Then Return Nil
			  Dim attribs As LIBSSH2_SFTP_ATTRIBUTES
			  Do
			    mLastError = libssh2_sftp_fstat_ex(mStream, attribs, 0)
			  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
			  
			  If BitAnd(attribs.Flags, LIBSSH2_SFTP_ATTR_ACMODTIME) = LIBSSH2_SFTP_ATTR_ACMODTIME Then
			    Return time_t(attribs.ATime)
			  End If
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If mStream = Nil Then Return
			  Dim attribs As LIBSSH2_SFTP_ATTRIBUTES
			  Do
			    mLastError = libssh2_sftp_fstat_ex(mStream, attribs, 0)
			  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
			  
			  If BitAnd(attribs.Flags, LIBSSH2_SFTP_ATTR_SIZE) <> LIBSSH2_SFTP_ATTR_SIZE Then Return ' atime not settable
			  
			  If BitAnd(attribs.Flags, LIBSSH2_SFTP_ATTR_ACMODTIME) = LIBSSH2_SFTP_ATTR_ACMODTIME Then
			    attribs.ATime = time_t(value)
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
			  return mDirectory
			End Get
		#tag EndGetter
		Directory As Boolean
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mFilename
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  mSession.Rename(Me.FullPath, value)
			  If mSession.LastStatusCode = 0 Then
			    mFilename = value
			  End If
			  
			End Set
		#tag EndSetter
		FullPath As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mStream
			End Get
		#tag EndGetter
		Handle As Ptr
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' This is an error code returned from the libssh2 API. If the last error was
			  ' LIBSSH2_ERROR_SFTP_PROTOCOL(-31) then refer to the LastStatusCode property
			  ' of the SFTPSession that owns this stream for the SFTP status code (which will
			  ' be one of the LIBSSH2_FX_* constants.)
			  
			  Return mLastError
			End Get
		#tag EndGetter
		LastError As Int32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mStream = Nil Then Return 0
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
			  If mStream = Nil Then Return
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
		Private mAppendOnly As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDirectory As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mEOF As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mFilename As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastError As Int32
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mStream = Nil Then Return Nil
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
			  If mStream = Nil Then Return
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
			  If mStream = Nil Then Return Nil
			  Dim attribs As LIBSSH2_SFTP_ATTRIBUTES
			  Do
			    mLastError = libssh2_sftp_fstat_ex(mStream, attribs, 0)
			  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
			  
			  If BitAnd(attribs.Flags, LIBSSH2_SFTP_ATTR_ACMODTIME) = LIBSSH2_SFTP_ATTR_ACMODTIME Then
			    Return time_t(attribs.MTime)
			  End If
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If mStream = Nil Then Return
			  Dim attribs As LIBSSH2_SFTP_ATTRIBUTES
			  Do
			    mLastError = libssh2_sftp_fstat_ex(mStream, attribs, 0)
			  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
			  
			  If BitAnd(attribs.Flags, LIBSSH2_SFTP_ATTR_SIZE) <> LIBSSH2_SFTP_ATTR_SIZE Then Return ' atime not settable
			  
			  If BitAnd(attribs.Flags, LIBSSH2_SFTP_ATTR_ACMODTIME) = LIBSSH2_SFTP_ATTR_ACMODTIME Then
			    attribs.MTime = time_t(value)
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
			  If Right(FullPath, 1) = "/" Then
			    return NthField(FullPath, "/", CountFields(FullPath, "/") - 1)
			  Else
			    return NthField(FullPath, "/", CountFields(FullPath, "/"))
			  End If
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  Dim p As SFTPDirectory = Me.Parent()
			  mSession.Rename(Me.FullPath, p.FullPath + value)
			  If mSession.LastStatusCode = 0 Then
			    mFilename = p.FullPath + value
			  End If
			  
			End Set
		#tag EndSetter
		Name As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Dim nm() As String = Split(mFilename.Trim, "/")
			  For i As Integer = UBound(nm) DownTo 0
			    If nm(i).Trim = "" Then nm.Remove(i)
			  Next
			  If UBound(nm) = -1 Then
			    mLastError = LIBSSH2_FX_INVALID_FILENAME
			    Return Nil
			  End If
			  nm.Remove(nm.Ubound)
			  Return mSession.ListDirectory("/" + Join(nm, "/") + "/")
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  Me.FullPath = value.FullPath + Me.Name
			End Set
		#tag EndSetter
		Parent As SSH.SFTPDirectory
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mStream <> Nil Then Return libssh2_sftp_tell64(mStream)
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If mStream <> Nil Then
			    If mAppendOnly Then 
			      mLastError = ERR_APPEND_ONLY
			      Return
			    End If
			    libssh2_sftp_seek64(mStream, value)
			  End If
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

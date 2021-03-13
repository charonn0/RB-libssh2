#tag Class
Protected Class SFTPStream
Implements SSHStream
	#tag Method, Flags = &h0
		Sub Close()
		  // Part of the SSHStream interface.
		  ' Closes the stream. No further data may be sent or received after
		  ' calling this method. Called automatically by the Destructor().
		  
		  If mStream <> Nil Then
		    Do
		      mLastError = libssh2_sftp_close_handle(mStream)
		    Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		    SFTPStreamParent(Session).UnregisterStream(Me)
		  End If
		  mStream = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Constructor(Session As SSH.SFTPSession, RemoteName As String, Flags As Integer, Mode As Integer, Directory As Boolean = False)
		  ' Constructs a new instance of SFTPStream for the file or directory indicated
		  ' by the parameters. The RemoteName is the full remote path of the item. The
		  ' Flags parameter is any reasonable combination of the LIBSSH2_FXF_* constants, 
		  ' and indicates what operations(s) are to be performed on the item. If the operation
		  ' will create a remote file or directory then the Mode parameter indicates its initial
		  ' permissions. This Constructor cannot be called from outside the SFTPStream class; 
		  ' refer to the SFTSession.CreateStream method for equivalent functionality.
		  
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
		  
		  SFTPStreamParent(Session).RegisterStream(Me)
		  mAppendOnly = Mask(Flags, LIBSSH2_FXF_APPEND)
		  mIsWriteable = mAppendOnly Or Mask(Flags, LIBSSH2_FXF_WRITE)
		  mIsReadable = Mask(Flags, LIBSSH2_FXF_READ)
		  ReadAttributes()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If mStream <> Nil Then Me.Close()
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
		  ' Returns True if the last call to Read() resulted in an EOF
		  
		  Return mEOF
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Flush()
		  // Part of the Writeable interface.
		  ' Not all servers support this. If that's the case then LastError
		  ' will be LIBSSH2_ERROR_SFTP_PROTOCOL and Session.LastStatusCode
		  ' will be LIBSSH2_FX_OP_UNSUPPORTED, but no exception will be raised.
		  
		  If mDirectory Then Raise New IOException
		  Do
		    mLastError = libssh2_sftp_fsync(mStream)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  Dim unsupported As Boolean = (mSession.LastStatusCode = LIBSSH2_FX_OP_UNSUPPORTED)
		  If mLastError <> 0 And Not unsupported Then Raise New SSHException(Me)
		  
		  
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function HasAttribute(AttributeID As Int32) As Boolean
		  ' Returns True if the file/directory has the specified AttributeID.
		  ' AttributeID is one of the LIBSSH2_SFTP_ATTR_* constants.
		  
		  Return Mask(mAttribs.Flags, AttributeID)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Read(Count As Integer, encoding As TextEncoding = Nil) As String
		  // Part of the Readable interface.
		  ' If the stream represents a file opened for reading then this method
		  ' reads from the file. If the stream represents a directory then this
		  ' method returns the next file name in the listing.
		  
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

	#tag Method, Flags = &h21
		Private Sub ReadAttributes()
		  ' Refreshes the mAttribs property.
		  
		  If mStream = Nil Then Return
		  Do
		    mLastError = libssh2_sftp_fstat_ex(mStream, mAttribs, 0)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadBuffer(Count As Integer) As MemoryBlock
		  ' This method is the same as Read() except it returns a MemoryBlock instead of a String.
		  
		  Dim buffer As New MemoryBlock(Count)
		  Do
		    mLastError = libssh2_sftp_read(mStream, buffer, buffer.Size)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  
		  If mLastError > 0 Then ' error is the size
		    buffer.Size = mLastError
		    Return buffer
		  ElseIf mLastError = 0 Then
		    mEOF = True
		  Else
		    Raise New SSHException(Me)
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function ReadDirectoryEntry(ByRef SFTPAttributes As LIBSSH2_SFTP_ATTRIBUTES, ByRef LongEntry As MemoryBlock, Encoding As TextEncoding = Nil) As String
		  ' If the stream represents a directory then this method returns then
		  ' next filename in the listing. Called by Read() if appropriate.
		  
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
		  ' This method writes the text to the stream as part of an upload operation. 
		  ' The text may be any size that can fit into memory. It is sent as a series
		  ' of sftp packets, each of which may be up to 32KB long. Since each sftp packet
		  ' must be individually acknowledged by the server the ideal size of the text
		  ' parameter is a multiple of the maximum packet size. This minimizes the number
		  ' of packets, and hence maximizes the throughput of the stream.
		  
		  WriteBuffer(text) ' copy the string data into a MemoryBlock and call WriteBuffer()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub WriteAttributes()
		  ' If the stream is writeable then this method updates its attributes with the
		  ' values stored in the mAttribs property. If the stream is not writeable then
		  ' this method resets the mAttribs property and sets mLastError to LIBSSH2_FX_PERMISSION_DENIED
		  
		  If mStream = Nil Then Return
		  If Not IsWriteable Then
		    ReadAttributes() ' reset values
		    mLastError = LIBSSH2_FX_PERMISSION_DENIED
		    Return
		  End If
		  
		  Do
		    mLastError = libssh2_sftp_fstat_ex(mStream, mAttribs, 1)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub WriteBuffer(Data As MemoryBlock)
		  ' This method is the same as Write() except it takes a MemoryBlock instead of a String.
		  ' This allows us to point to the Data directly instead of copying it.
		  
		  If mDirectory Then Raise New IOException
		  If Data = Nil Then Return
		  Dim size As Integer = Data.Size
		  If size = 0 Then Return
		  If size < 0 Then Raise New SSHException(ERR_SIZE_REQUIRED) ' MemoryBlock.Size must be known!
		  Dim p As Ptr = Data
		  
		  Do
		    ' write the next packet, or continue writing a previous packet that hasn't finished
		    mLastError = libssh2_sftp_write(mStream, p, size)
		    Select Case mLastError
		    Case 0, LIBSSH2_ERROR_EAGAIN ' nothing ack'd yet
		      ' call libssh2_sftp_write() again with the same params
		      Continue
		      
		    Case Is > 0 ' the amount ack'd
		      If mLastError = size Then
		        Exit Do ' done
		      End If
		      ' update the size and ptr and call libssh2_sftp_write() again
		      size = size - mLastError
		      p = Ptr(Integer(p) + mLastError)
		      Continue
		      
		    Case Is < 0 ' error
		      Raise New SSHException(Me)
		    End Select
		  Loop
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
			  ' Reads the last access time attribute.
			  
			  If mStream = Nil Then Return Nil
			  If HasAttribute(LIBSSH2_SFTP_ATTR_ACMODTIME) Then Return time_t(mAttribs.ATime)
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' Modifies the last access time attribute, if the stream is writeable.
			  
			  If mStream = Nil Then Return
			  ReadAttributes() ' refresh
			  If Not HasAttribute(LIBSSH2_SFTP_ATTR_ACMODTIME) Then Return ' atime not settable
			  mAttribs.ATime = time_t(value)
			  WriteAttributes()
			End Set
		#tag EndSetter
		AccessTime As Date
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns True if the stream represents a directory
			  
			  return mDirectory
			End Get
		#tag EndGetter
		Directory As Boolean
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Gets the full remote path
			  
			  Return mFilename
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' Sets a new full path, effectively moving or renaming the file/directory
			  
			  value = mSession.Rename(Me.FullPath, value)
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
			  return mIsReadable
			End Get
		#tag EndGetter
		IsReadable As Boolean
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mIsWriteable
			End Get
		#tag EndGetter
		IsWriteable As Boolean
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
			  ' Gets the total size of the file.
			  
			  If mStream = Nil Then Return 0
			  If HasAttribute(LIBSSH2_SFTP_ATTR_SIZE) Then Return mAttribs.FileSize
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' Extends or truncates the file to the specified size if the stream is writeable.
			  
			  If mStream = Nil Then Return
			  ReadAttributes() ' refresh
			  If Not HasAttribute(LIBSSH2_SFTP_ATTR_SIZE) Then Return ' size not settable
			  mAttribs.FileSize = value
			  WriteAttributes()
			End Set
		#tag EndSetter
		Length As UInt64
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mAppendOnly As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mAttribs As LIBSSH2_SFTP_ATTRIBUTES
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
		Private mIsReadable As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mIsWriteable As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastError As Int32
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Reads the Unix-style permission of the file/directory, if the server supports them.
			  
			  If mStream = Nil Then Return Nil
			  If HasAttribute(LIBSSH2_SFTP_ATTR_PERMISSIONS) Then Return New Permissions(mAttribs.Perms)
			  
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' Updates the Unix-style permission of the file/directory if the stream is writeable
			  ' and the server supports them.
			  
			  If mStream = Nil Then Return
			  ReadAttributes() ' refresh
			  If Not HasAttribute(LIBSSH2_SFTP_ATTR_PERMISSIONS) Then Return ' perms not settable
			  mAttribs.Perms = PermissionsToMode(value)
			  WriteAttributes()
			End Set
		#tag EndSetter
		Mode As Permissions
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Reads the last modified time of the file/directory.
			  
			  If mStream = Nil Then Return Nil
			  If HasAttribute(LIBSSH2_SFTP_ATTR_ACMODTIME) Then Return time_t(mAttribs.MTime)
			  
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' Modifies the last access time attribute, if the stream is writeable.
			  
			  If mStream = Nil Then Return
			  ReadAttributes() ' refresh
			  If Not HasAttribute(LIBSSH2_SFTP_ATTR_ACMODTIME) Then Return ' mtime not settable
			  mAttribs.MTime = time_t(value)
			  WriteAttributes()
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
			  ' Returns the name of the file/directory without any path.
			  
			  If Right(FullPath, 1) = "/" Then
			    return NthField(FullPath, "/", CountFields(FullPath, "/") - 1)
			  Else
			    return NthField(FullPath, "/", CountFields(FullPath, "/"))
			  End If
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' Renames the file/directory, if the server allows it.
			  
			  Dim p As SFTPDirectory = Me.Parent()
			  value = mSession.Rename(Me.FullPath, p.FullPath + value)
			  If mSession.LastStatusCode = 0 Then
			    mFilename = value
			  End If
			  
			End Set
		#tag EndSetter
		Name As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Creates a SFTPDirectory for the parent directory of this stream.
			  
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
			  ' Sets a new parent directlry, effectively moving the file/directory
			  
			  Me.FullPath = value.FullPath + Me.Name
			End Set
		#tag EndSetter
		Parent As SSH.SFTPDirectory
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns the current position of the file pointer in the stream.
			  
			  If mStream <> Nil Then Return libssh2_sftp_tell64(mStream)
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' Moves the file pointer to the offset indicated. If the stream was opened
			  ' in AppendOnly mode then this will fail. If the new offset is equal to the 
			  ' old offset then the attributes will also be refreshed.
			  
			  If mStream <> Nil Then
			    If value = Me.Position Then ReadAttributes() ' refresh
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

#tag Class
Protected Class SFTPStream
Implements SSHStream
	#tag Method, Flags = &h1
		Protected Function Channel() As Ptr
		  If mStream <> Nil Then Return libssh2_sftp_get_channel(mStream)
		End Function
	#tag EndMethod

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
		  If mStream = Nil Then Raise New SSHException(Session)
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

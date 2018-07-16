#tag Class
Private Class SFTPStream
Implements  SSHStream
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

	#tag Method, Flags = &h0
		Sub Constructor(Session As SSH.SFTPSession, RemoteName As String, Flags As Integer, Mode As Integer, Directory As Boolean = False)
		  mInit = SSHInit.GetInstance()
		  Dim fn As MemoryBlock = RemoteName
		  If Not Directory Then
		    mStream = libssh2_sftp_open_ex(Session.Handle, fn, fn.Size, Flags, Mode, LIBSSH2_SFTP_OPENFILE)
		  Else
		    mStream = libssh2_sftp_open_ex(Session.Handle, fn, fn.Size, Flags, Mode, LIBSSH2_SFTP_OPENDIR)
		  End If
		  If mStream = Nil Then Raise New SSHException(0)
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
		Function Read(Count As Integer, encoding As TextEncoding = Nil) As String
		  // Part of the Readable interface.
		  Dim buffer As New MemoryBlock(Count)
		  If Not mDirectory Then  ' read a file
		    Do
		      mLastError = libssh2_sftp_read(mStream, buffer, buffer.Size)
		    Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		    
		  Else ' read directory listing
		    Dim longentry As New MemoryBlock(512)
		    Dim attribs As LIBSSH2_SFTP_ATTRIBUTES
		    Do
		      mLastError = libssh2_sftp_readdir_ex(mStream, buffer, buffer.Size, longentry, longentry.Size, attribs)
		    Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  End If
		  
		  If mLastError > 0 Then ' error is the size
		    Return DefineEncoding(buffer.StringValue(0, mLastError), encoding)
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
		  If mDirectory Then Raise New IOException
		  Dim mb As MemoryBlock = text
		  Do
		    mLastError = libssh2_sftp_write(mStream, mb, mb.Size)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
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
		Private mLastError As Integer
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

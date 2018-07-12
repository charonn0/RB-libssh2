#tag Class
Protected Class SFTPStream
Implements Readable,Writeable
	#tag Method, Flags = &h0
		Sub Constructor(Session As SSH.SFTPSession, RemoteName As String, Flags As Integer, Mode As Integer, Directory As Boolean = False)
		  mInit = SSHInit.GetInstance()
		  Dim fn As MemoryBlock = RemoteName
		  If Not Directory Then
		    mStream = libssh2_sftp_open_ex(Session.Handle, fn, fn.Size, Flags, Mode, LIBSSH2_SFTP_OPENFILE)
		  Else
		    mStream = libssh2_sftp_open_ex(Session.Handle, fn, fn.Size, Flags, Mode, LIBSSH2_SFTP_OPENDIR)
		  End If
		  If mStream = Nil Then Raise New SSHException(Session.LastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If mStream <> Nil Then
		    mLastError = libssh2_sftp_shutdown(mStream)
		    If mLastError <> 0 Then Raise New SSHException(mLastError)
		  End If
		  mStream = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function EOF() As Boolean
		  // Part of the Readable interface.
		  #pragma Warning "Untested."
		  Return libssh2_channel_eof(mStream) = 1
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Flush()
		  // Part of the Writeable interface.
		  
		  Do
		    mLastError = libssh2_sftp_fsync(mStream)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
		  
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Read(Count As Integer, StreamID As Integer, encoding As TextEncoding = Nil) As String
		  Dim buffer As New MemoryBlock(Count)
		  Dim sz As Integer = libssh2_channel_read_ex(mStream, StreamID, buffer, buffer.Size)
		  Return buffer.StringValue(0, sz)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function Read(Count As Integer, encoding As TextEncoding = Nil) As String Implements Readable.Read
		  // Part of the Readable interface.
		  Return Me.Read(Count, 0, encoding)
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
		Private mInit As SSHInit
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastError As Integer
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

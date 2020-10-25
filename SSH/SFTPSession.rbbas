#tag Class
Protected Class SFTPSession
	#tag Method, Flags = &h0
		Sub Constructor(Session As SSH.Session)
		  If Not Session.IsAuthenticated Then 
		    mLastError = ERR_NOT_AUTHENTICATED
		    Raise New SSHException(Me)
		  End If
		  
		  mInit = SSHInit.GetInstance()
		  mSFTP = libssh2_sftp_init(Session.Handle)
		  If mSFTP = Nil Then Raise New SSHException(Session)
		  mSession = Session
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function CreateStream(FileName As String, Flags As Integer, Mode As Integer, Directory As Boolean) As SSH.SFTPStream
		  Return New SFTPStreamPtr(Me, FileName, Flags, Mode, Directory)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If mSFTP <> Nil Then
		    Do
		      mLastError = libssh2_sftp_shutdown(mSFTP)
		    Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  End If
		  mSFTP = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Get(FileName As String) As SSH.SFTPStream
		  Return CreateStream(FileName, LIBSSH2_FXF_READ, 0, False)
		  
		Exception err As SSHException
		  mLastError = err.ErrorNumber
		  If mLastError = 0 Then mLastError = LastStatusCode()
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Get(FileName As String, WriteTo As Writeable) As Boolean
		  Dim stream As SSHStream = Me.Get(FileName)
		  Do Until stream.EOF
		    WriteTo.Write(stream.Read(LIBSSH2_CHANNEL_PACKET_DEFAULT))
		  Loop
		  stream.Close
		  Return True
		  
		Exception
		  Return False
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Handle() As Ptr
		  Return mSFTP
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Int32
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastStatusCode() As Integer
		  ' Returns the last SFTP status code, which will be one of the LIBSSH2_FX_* constants.
		  ' Check this value if SFTPStream.LastError or SFTPDirectory.LastError = LIBSSH2_ERROR_SFTP_PROTOCOL(-31)
		  
		  If mSFTP = Nil Then Return 0
		  Return libssh2_sftp_last_error(mSFTP)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ListDirectory(DirectoryName As String) As SSH.SFTPDirectory
		  Return New SFTPDirectory(Me, DirectoryName)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub MakeDirectory(DirectoryName As String, Mode As Integer = &o744)
		  Dim dn As MemoryBlock = DirectoryName
		  Do
		    mLastError = libssh2_sftp_mkdir_ex(mSFTP, dn, dn.Size, Mode)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then Raise New SSHException(Me)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Put(FileName As String, Overwrite As Boolean = False, Mode As Integer = &o744) As SSH.SFTPStream
		  Dim flags As Integer = LIBSSH2_FXF_CREAT Or LIBSSH2_FXF_WRITE
		  If Overwrite Then flags = flags Or LIBSSH2_FXF_TRUNC Else flags = flags Or LIBSSH2_FXF_EXCL
		  Return CreateStream(FileName, flags, Mode, False)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Put(FileName As String, Upload As Readable, Overwrite As Boolean = False, Mode As Integer = &o744) As Boolean
		  Dim sftp As SSHStream = Me.Put(FileName, Overwrite, Mode)
		  
		  Do Until Upload.EOF
		    sftp.Write(Upload.Read(LIBSSH2_CHANNEL_PACKET_DEFAULT))
		  Loop
		  sftp.Close
		  Return True
		  
		Exception
		  Return False
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RemoveDirectory(DirectoryName As String)
		  Dim dn As MemoryBlock = DirectoryName
		  Do
		    mLastError = libssh2_sftp_rmdir_ex(mSFTP, dn, dn.Size)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then Raise New SSHException(Me)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RemoveFile(FileName As String)
		  Dim fn As MemoryBlock = FileName
		  Do
		    mLastError = libssh2_sftp_unlink_ex(mSFTP, fn, fn.Size)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then Raise New SSHException(Me)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Rename(SourceName As String, DestinationName As String, Overwrite As Boolean = False)
		  Dim sn As MemoryBlock = SourceName
		  Dim dn As MemoryBlock = DestinationName
		  Dim flag As Integer
		  If Overwrite Then flag = LIBSSH2_SFTP_RENAME_OVERWRITE
		  Do
		    mLastError = libssh2_sftp_rename_ex(mSFTP, sn, sn.Size, dn, dn.Size, flag)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then Raise New SSHException(Me)
		End Sub
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mChannel = Nil And mSFTP <> Nil Then
			    Dim ch As Ptr = libssh2_sftp_get_channel(mSFTP)
			    If ch <> Nil Then mChannel = New ChannelPtr(Session, ch)
			  End If
			  Return mChannel
			End Get
		#tag EndGetter
		Channel As SSH.Channel
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mChannel As SSH.Channel
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mInit As SSHInit
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastError As Int32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSession As SSH.Session
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSFTP As Ptr
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mSession
			End Get
		#tag EndGetter
		Session As SSH.Session
	#tag EndComputedProperty


	#tag Constant, Name = LIBSSH2_SFTP_RENAME_ATOMIC, Type = Double, Dynamic = False, Default = \"&h00000002", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_RENAME_NATIVE, Type = Double, Dynamic = False, Default = \"&h00000004", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_RENAME_OVERWRITE, Type = Double, Dynamic = False, Default = \"&h00000001", Scope = Public
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

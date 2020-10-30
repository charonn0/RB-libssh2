#tag Class
Protected Class SFTPSession
	#tag Method, Flags = &h0
		Function Append(FileName As String, CreateIfMissing As Boolean = False, Mode As Integer = 0) As SSH.SFTPStream
		  ' Returns an SFTPStream to which the file data can be appended.
		  
		  If Mode = 0 Then
		    Dim meta As SFTPStream
		    If PathExists(FileName) Then meta = CreateStream(FileName, LIBSSH2_FXF_READ, 0, False)
		    If meta <> Nil Then
		      Mode = PermissionsToMode(meta.Mode)
		      meta.Close
		    ElseIf CreateIfMissing Then
		      Mode = &o644
		    End If
		  End If
		  
		  Dim flags As Integer = LIBSSH2_FXF_WRITE Or LIBSSH2_FXF_APPEND
		  If CreateIfMissing Then flags = flags Or LIBSSH2_FXF_CREAT
		  Dim stream As SFTPStream = CreateStream(FileName, flags, Mode, False)
		  If stream <> Nil Then stream.Position = stream.Length
		  Return stream
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(Session As SSH.Session)
		  ' Create a new SFTP session over the specified SSH session.
		  
		  mSession = Session
		  If Not mSession.IsAuthenticated Then
		    mLastError = ERR_NOT_AUTHENTICATED
		    Raise New SSHException(Me)
		  End If
		  
		  mSFTP = libssh2_sftp_init(mSession.Handle)
		  If mSFTP = Nil Then Raise New SSHException(mSession)
		  If PathExists("/home/" + mSession.Username + "/") Then WorkingDirectory = "/home/" + mSession.Username + "/"
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function CreateStream(FileName As String, Flags As Integer, Mode As Integer, Directory As Boolean) As SSH.SFTPStream
		  ' This method opens a SFTPStream according to the parameters. It is a more generic
		  ' version of the Get(), Put(), and ListDirectory() methods, allowing custom functionality.
		  ' See https://www.libssh2.org/libssh2_sftp_open_ex.html for a description of the parameters.
		  
		  Return New SFTPStreamPtr(Me, NormalizePath(FileName, Directory, Not Directory), Flags, Mode, Directory)
		  
		Exception err As SSHException
		  mLastError = err.ErrorNumber
		  If mLastError = 0 Then mLastError = LastStatusCode()
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function CreateSymbolicLink(Path As String, Link As String) As Boolean
		  ' This method creates a new symlink on the server from the Path to the Link.
		  ' If the Path is a directory then it must end with "/", however the Link must not.
		  
		  Dim src As MemoryBlock = NormalizePath(Path, False, False)
		  Dim dst As MemoryBlock = NormalizePath(Link, False, True)
		  mLastError = libssh2_sftp_symlink_ex(mSFTP, src, src.Size, dst, dst.Size, LIBSSH2_SFTP_SYMLINK)
		  Return mLastError = 0
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
		  ' Returns an SFTPStream from which the file data can be read.
		  
		  Return CreateStream(FileName, LIBSSH2_FXF_READ, 0, False)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Get(FileName As String, WriteTo As Writeable) As Boolean
		  ' Downloads the FileName to WriteTo.
		  
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
		Function IsSymbolicLink(LinkPath As String) As Boolean
		  ' This method returns True if the LinkPath is actually a symlink.
		  ' Use ReadSymbolicLink to get the target path.
		  
		  Return ReadSymbolicLink(LinkPath) <> ""
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ListDirectory(DirectoryName As String) As SSH.SFTPDirectory
		  ' Returns an instance of SFTPDirectory with which you can iterate over
		  ' all the items in the remote directory.
		  
		  Return New SFTPDirectoryPtr(Me, NormalizePath(DirectoryName, True, False))
		  
		Exception err As SSHException
		  mLastError = err.ErrorNumber
		  If mLastError = 0 Then mLastError = LastStatusCode()
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub MakeDirectory(DirectoryName As String, Mode As Integer = &o744)
		  ' Creates the specified directory on the server. 
		  
		  Dim dn As MemoryBlock = NormalizePath(DirectoryName, True, False)
		  Do
		    mLastError = libssh2_sftp_mkdir_ex(mSFTP, dn, dn.Size, Mode)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function NormalizePath(Path As String, IsDirectory As Boolean, IsFile As Boolean) As String
		  Do Until InStr(Path, "//") = 0
		    Path = ReplaceAll(Path, "//", "/")
		  Loop
		  
		  If IsDirectory And Right(Path, 1) <> "/" Then Path = Path + "/"
		  If IsFile And Right(Path, 1) = "/" Then Path = Left(Path, Path.Len - 1)
		  
		  If Left(Path, 1) = "/" Then Return Path ' absolute path
		  Return mWorkingDirectory + Path
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function PathExists(Path As String) As Boolean
		  ' Returns True if the specified Path exists on the server. Paths ending in "/" are interpreted
		  ' as directories; some servers will fail the query if it's omitted.
		  
		  If Not mSession.IsAuthenticated Then Return False
		  Dim fn As MemoryBlock = NormalizePath(Path, False, False)
		  Dim p As Ptr
		  Dim flag As Integer
		  If Right(Path, 1) = "/" Then flag = LIBSSH2_SFTP_OPENDIR Else flag = LIBSSH2_SFTP_OPENFILE
		  Try
		    p = libssh2_sftp_open_ex(mSFTP, fn, fn.Size, 0, 0, flag)
		  Catch
		    p = Nil
		  Finally
		    If p <> Nil Then
		      Do
		        mLastError = libssh2_sftp_close_handle(p)
		      Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		    End If
		  End Try
		  
		  Return p <> Nil
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Put(FileName As String, Overwrite As Boolean = False, Mode As Integer = &o744) As SSH.SFTPStream
		  ' Returns an SFTPStream to which the file data can be written.
		  
		  Dim flags As Integer = LIBSSH2_FXF_CREAT Or LIBSSH2_FXF_WRITE
		  If Overwrite Then flags = flags Or LIBSSH2_FXF_TRUNC Else flags = flags Or LIBSSH2_FXF_EXCL
		  Return CreateStream(FileName, flags, Mode, False)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Put(FileName As String, Upload As Readable, Overwrite As Boolean = False, Mode As Integer = &o744) As Boolean
		  ' Writes the Upload stream to FileName.
		  
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
		Function ReadSymbolicLink(LinkPath As String, FollowAll As Boolean = False) As String
		  ' This method reads the symbolic link specified by LinkPath and returns the path of the linked
		  ' file/directory. If the linked file/directory is itself a symlink and FollowAll=True then
		  ' that (and all subsequent) symlinks are followed until we reach the final target.
		  ' If the LinkPath is not actually a symlink then this method returns the empty string.
		  
		  Dim src As MemoryBlock = NormalizePath(LinkPath, False, False)
		  Dim dst As New MemoryBlock(1024 * 64)
		  Dim mode As Integer = LIBSSH2_SFTP_READLINK ' read one level of symlinks
		  If FollowAll Then mode = LIBSSH2_SFTP_REALPATH ' follow all subsequent links until we reach the real file.
		  mLastError = libssh2_sftp_symlink_ex(mSFTP, src, src.Size, dst, dst.Size, mode)
		  If mLastError > 0 Then
		    dst.Size = mLastError
		    Return dst
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RemoveDirectory(DirectoryName As String)
		  ' Deletes the specified directory on the server. The directory must already be empty.
		  
		  Dim dn As MemoryBlock = NormalizePath(DirectoryName, True, False)
		  Do
		    mLastError = libssh2_sftp_rmdir_ex(mSFTP, dn, dn.Size)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RemoveFile(FileName As String)
		  ' Deletes the specified file on the server.
		  
		  Dim fn As MemoryBlock = NormalizePath(FileName, False, True)
		  Do
		    mLastError = libssh2_sftp_unlink_ex(mSFTP, fn, fn.Size)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Rename(SourceName As String, DestinationName As String, Overwrite As Boolean = False)
		  ' Renames the SourceName file. If DestinationName already exists
		  ' and Overwrite=False then the operation will fail.
		  
		  Dim sn As MemoryBlock = NormalizePath(SourceName, False, False)
		  Dim dn As MemoryBlock = NormalizePath(DestinationName, False, False)
		  Dim flag As Integer
		  If Overwrite Then flag = LIBSSH2_SFTP_RENAME_OVERWRITE
		  Do
		    mLastError = libssh2_sftp_rename_ex(mSFTP, sn, sn.Size, dn, dn.Size, flag)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  
		End Sub
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns a reference to the Channel over which the SFTPStream is opened.
			  ' It's generally not useful to interact with this object.
			  
			  If mChannel = Nil And mSFTP <> Nil Then
			    Dim ch As Ptr = libssh2_sftp_get_channel(mSFTP)
			    If ch <> Nil Then mChannel = New ChannelPtr(Session, ch)
			  End If
			  Return mChannel
			End Get
		#tag EndGetter
		Channel As SSH.Channel
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mSFTP
			End Get
		#tag EndGetter
		Handle As Ptr
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns the most recent error code returned from libssh2.
			  
			  Return mLastError
			End Get
		#tag EndGetter
		LastError As Int32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns the last SFTP status code, which will be one of the LIBSSH2_FX_* constants.
			  ' Check this value if SFTPStream.LastError or SFTPDirectory.LastError = LIBSSH2_ERROR_SFTP_PROTOCOL(-31)
			  
			  If mSFTP = Nil Then Return 0
			  Return libssh2_sftp_last_error(mSFTP)
			End Get
		#tag EndGetter
		LastStatusCode As Int32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns the name of last SFTP status code
			  
			  Return SFTPErrorName(LastStatusCode)
			End Get
		#tag EndGetter
		LastStatusName As String
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mChannel As SSH.Channel
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

	#tag Property, Flags = &h21
		Private mWorkingDirectory As String = "/"
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mSession
			End Get
		#tag EndGetter
		Session As SSH.Session
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mWorkingDirectory
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If value.Trim = "." Or value = mWorkingDirectory Then Return
			  Dim p() AS String = Split(mWorkingDirectory, "/")
			  If value.Trim = ".." Then
			    If mWorkingDirectory = "/" Then Return ' meh
			    If p(UBound(p)) = "" Then Call p.Pop()
			    Call p.Pop
			    mWorkingDirectory = NormalizePath(Join(p, "/"), True, False)
			    Return
			  End If
			  
			  Dim d As SFTPDirectory
			  If Left(value, 1) = "/" Then 'absolute
			    d = ListDirectory(NormalizePath(value, True, False))
			  Else ' relative
			    d = ListDirectory(NormalizePath(mWorkingDirectory + "/" + value, True, False))
			  End If
			  If d <> Nil Then mWorkingDirectory = d.FullPath
			End Set
		#tag EndSetter
		WorkingDirectory As String
	#tag EndComputedProperty


	#tag Constant, Name = LIBSSH2_SFTP_READLINK, Type = Double, Dynamic = False, Default = \"1", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_REALPATH, Type = Double, Dynamic = False, Default = \"2", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_RENAME_ATOMIC, Type = Double, Dynamic = False, Default = \"&h00000002", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_RENAME_NATIVE, Type = Double, Dynamic = False, Default = \"&h00000004", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_RENAME_OVERWRITE, Type = Double, Dynamic = False, Default = \"&h00000001", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_SYMLINK, Type = Double, Dynamic = False, Default = \"0", Scope = Protected
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

#tag Class
Protected Class SFTPSession
	#tag Method, Flags = &h0
		Sub Constructor(Session As SSH.Session)
		  mInit = SSHInit.GetInstance()
		  mSFTP = libssh2_sftp_init(Session.Handle)
		  If mSFTP = Nil Then Raise New SSHException(Session.LastError)
		  mSession = Session
		End Sub
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
		  Return New SFTPStream(Me, FileName, LIBSSH2_FXF_READ, 0)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Handle() As Ptr
		  Return mSFTP
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  If mSFTP = Nil Then Return 0
		  Return libssh2_sftp_last_error(mSFTP)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RemoveDirectory(DirectoryName As String)
		  Dim dn As MemoryBlock = DirectoryName
		  Do
		    mLastError = libssh2_sftp_rmdir_ex(mSFTP, dn, dn.Size)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
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
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mInit As SSHInit
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastError As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSession As SSH.Session
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSFTP As Ptr
	#tag EndProperty


	#tag Constant, Name = LIBSSH2_FXF_APPEND, Type = Double, Dynamic = False, Default = \"&h00000004", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FXF_CREAT, Type = Double, Dynamic = False, Default = \"&h00000008", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FXF_EXCL, Type = Double, Dynamic = False, Default = \"&h00000020", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FXF_READ, Type = Double, Dynamic = False, Default = \"&h00000001", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FXF_TRUNC, Type = Double, Dynamic = False, Default = \"&h00000010", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_FXF_WRITE, Type = Double, Dynamic = False, Default = \"&h00000002", Scope = Private
	#tag EndConstant

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

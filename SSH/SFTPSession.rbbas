#tag Class
Protected Class SFTPSession
	#tag Method, Flags = &h0
		Sub Constructor(Session As SSH.Session)
		  mInit = SSHInit.GetInstance()
		  mSFTP = libssh2_sftp_init(Session.Handle)
		  If mSFTP = Nil Then Raise New SSHException(Session.LastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If mSFTP <> Nil Then
		    mLastError = libssh2_sftp_shutdown(mSFTP)
		    If mLastError <> 0 Then Raise New SSHException(mLastError)
		  End If
		  mSFTP = Nil
		End Sub
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
		  mLastError = libssh2_sftp_rmdir_ex(mSFTP, dn, dn.Size)
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Rename(SourceName As String, DestinationName As String, Flags As Integer)
		  Dim sn As MemoryBlock = SourceName
		  Dim dn As MemoryBlock = DestinationName
		  Dim err As Integer = libssh2_sftp_rename_ex(mSFTP, sn, sn.Size, dn, dn.Size, Flags)
		  If err <> 0 Then Raise New SSHException(err)
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mInit As SSHInit
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastError As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSFTP As Ptr
	#tag EndProperty


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

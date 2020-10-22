#tag Class
Protected Class SFTPDirectory
	#tag Method, Flags = &h0
		Sub Close()
		  If mStream <> Nil Then mStream.Close()
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(Session As SSH.SFTPSession, RemoteName As String)
		  mInit = SSHInit.GetInstance()
		  mStream = New SFTPStreamPtr(Session, RemoteName, 0, 0, True)
		  mIndex = -1
		  If Not ReadNextEntry() Then Raise New SSHException(Session.GetLastError)
		  mName = RemoteName
		  mSession = Session
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If mStream <> Nil Then Me.Close()
		  mStream = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Int32
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function OpenFile(Optional FileName As String) As SSH.SFTPStream
		  If FileName = "" Then ' get the current file
		    If CurrentName <> "" And CurrentType = EntryType.File Then 
		      FileName = CurrentName
		    Else
		      Return Nil
		    End If
		  End If
		  
		  FileName = mName + "/" + FileName
		  
		  Return New SFTPStreamPtr(Me.Session, FileName, LIBSSH2_FXF_READ, 0, False)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function OpenSubdirectory(Optional DirectoryName As String) As SSH.SFTPDirectory
		  If DirectoryName = "" Then ' get the current directory
		    If CurrentName <> "" And CurrentType = EntryType.Directory Then
		      DirectoryName = CurrentName
		    Else
		      Return Nil
		    End If
		  End If
		  
		  DirectoryName = mName + "/" + DirectoryName
		  
		  Return New SFTPDirectory(Me.Session, DirectoryName)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Parent() As SSH.SFTPDirectory
		  If mName = "/" Or mName = "" Then Return Nil
		  Dim nm As String = Left(mName, mName.Len - Name.Len)
		  If Right(nm, 1) = "/" And nm <> "/" Then nm = Left(nm, nm.Len - 1)
		  Return New SFTPDirectory(Me.Session, nm)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadNextEntry() As Boolean
		  If mStream = Nil Then Return False
		  mCurrentLongEntry = New MemoryBlock(512)
		  Dim name As New MemoryBlock(1024 * 16)
		  Do
		    mLastError = libssh2_sftp_readdir_ex(mStream.Handle, name, name.Size, mCurrentLongEntry, mCurrentLongEntry.Size, mCurrentAttribs)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  
		  If mLastError > 0 Then ' error is the size
		    name.Size = mLastError
		    mCurrentName = name
		  ElseIf mLastError = 0 Then
		    Return False
		  Else
		    Raise New SSHException(mLastError)
		  End If
		  
		  If mCurrentName.Trim <> "" Then
		    mIndex = mIndex + 1
		    Return True
		  End If
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mStream = Nil Then Return Nil
			  If BitAnd(mCurrentAttribs.Flags, LIBSSH2_SFTP_ATTR_ACMODTIME) = LIBSSH2_SFTP_ATTR_ACMODTIME Then
			    Dim d As New Date(1970, 1, 1, 0, 0, 0, 0.0) 'UNIX epoch
			    d.TotalSeconds = d.TotalSeconds + mCurrentAttribs.ATime
			    Return d
			  End If
			End Get
		#tag EndGetter
		CurrentAccessTime As Date
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mIndex
			End Get
		#tag EndGetter
		CurrentIndex As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If BitAnd(mCurrentAttribs.Flags, LIBSSH2_SFTP_ATTR_SIZE) = LIBSSH2_SFTP_ATTR_SIZE Then
			    Return mCurrentAttribs.FileSize
			  End If
			End Get
		#tag EndGetter
		CurrentLength As UInt64
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mStream = Nil Then Return Nil
			  If BitAnd(mCurrentAttribs.Flags, LIBSSH2_SFTP_ATTR_PERMISSIONS) = LIBSSH2_SFTP_ATTR_PERMISSIONS Then
			    Return New Permissions(mCurrentAttribs.Perms)
			  End If
			End Get
		#tag EndGetter
		CurrentMode As Permissions
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mStream = Nil Then Return Nil
			  If BitAnd(mCurrentAttribs.Flags, LIBSSH2_SFTP_ATTR_ACMODTIME) = LIBSSH2_SFTP_ATTR_ACMODTIME Then
			    Dim d As New Date(1970, 1, 1, 0, 0, 0, 0.0) 'UNIX epoch
			    d.TotalSeconds = d.TotalSeconds + mCurrentAttribs.MTime
			    Return d
			  End If
			End Get
		#tag EndGetter
		CurrentModifyTime As Date
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mCurrentName
			End Get
		#tag EndGetter
		CurrentName As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mStream = Nil Then Return EntryType.Unknown
			  If BitAnd(mCurrentAttribs.Flags, LIBSSH2_SFTP_ATTR_PERMISSIONS) = LIBSSH2_SFTP_ATTR_PERMISSIONS Then
			    Select Case BitAnd(mCurrentAttribs.Perms, LIBSSH2_SFTP_S_IFMT)
			    Case LIBSSH2_SFTP_S_IFDIR
			      Return EntryType.Directory
			    Case LIBSSH2_SFTP_S_IFREG
			      Return EntryType.File
			    Case LIBSSH2_SFTP_S_IFBLK
			      Return EntryType.BlockSpecial
			    Case LIBSSH2_SFTP_S_IFCHR
			      Return EntryType.CharacterSpecial
			    Case LIBSSH2_SFTP_S_IFIFO
			      Return EntryType.Pipe
			    Case LIBSSH2_SFTP_S_IFLNK
			      Return EntryType.Symlink
			    Case LIBSSH2_SFTP_S_IFSOCK
			      Return EntryType.Socket
			    Else
			      Return EntryType.File
			    End Select
			  End If
			End Get
		#tag EndGetter
		CurrentType As SSH.SFTPDirectory.EntryType
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mCurrentAttribs As LIBSSH2_SFTP_ATTRIBUTES
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentLongEntry As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentName As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mIndex As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mInit As SSHInit
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastError As Int32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mName As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSession As SSH.SFTPSession
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mStream As SFTPStream
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return NthField(mName, "/", CountFields(mName, "/"))
			End Get
		#tag EndGetter
		Name As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mSession
			End Get
		#tag EndGetter
		Session As SSH.SFTPSession
	#tag EndComputedProperty


	#tag Constant, Name = LIBSSH2_SFTP_S_IFBLK, Type = Double, Dynamic = False, Default = \"&o060000", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_S_IFCHR, Type = Double, Dynamic = False, Default = \"&o020000", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_S_IFDIR, Type = Double, Dynamic = False, Default = \"&o040000", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_S_IFIFO, Type = Double, Dynamic = False, Default = \"&o010000", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_S_IFLNK, Type = Double, Dynamic = False, Default = \"&o120000", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_S_IFMT, Type = Double, Dynamic = False, Default = \"&o170000", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_S_IFREG, Type = Double, Dynamic = False, Default = \"&o100000", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_S_IFSOCK, Type = Double, Dynamic = False, Default = \"&o140000", Scope = Protected
	#tag EndConstant


	#tag Enum, Name = EntryType, Type = Integer, Flags = &h0
		File
		  Directory
		  Symlink
		  Socket
		  BlockSpecial
		  CharacterSpecial
		  Pipe
		Unknown
	#tag EndEnum


	#tag ViewBehavior
		#tag ViewProperty
			Name="CurrentIndex"
			Group="Behavior"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="CurrentName"
			Group="Behavior"
			Type="String"
		#tag EndViewProperty
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

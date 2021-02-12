#tag Class
Protected Class SFTPDirectory
	#tag Method, Flags = &h0
		Sub Close()
		  ' Ends the directory listing.
		  
		  If mStream <> Nil Then mStream.Close()
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Constructor(Session As SSH.SFTPSession, RemoteName As String)
		  mSession = Session
		  If Not mSession.Session.IsAuthenticated Then
		    mLastError = ERR_NOT_AUTHENTICATED
		    Raise New SSHException(Me)
		  End If
		  
		  mStream = New SFTPStreamPtr(mSession, RemoteName, 0, 0, True)
		  AddHandler mStream.Closed, WeakAddressOf StreamClosedHandler
		  mIndex = -1
		  mName = RemoteName
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Count() As Integer
		  Dim thisdir As New SFTPDirectory(Session, FullPath)
		  Dim c As Integer
		  Do
		    c = c + 1
		  Loop Until Not thisdir.ReadNextEntry()
		  Return c
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function CurrentHasAttribute(AttributeID As Int32) As Boolean
		  Return Mask(mCurrentAttribs.Flags, AttributeID)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  Me.Close()
		  mStream = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function OpenFile(Index As Integer) As SSH.SFTPStream
		  Dim thisdir As New SFTPDirectory(Session, FullPath)
		  Do Until thisdir.CurrentIndex = Index
		    If Not thisdir.ReadNextEntry() Then
		      mLastError = ERR_INVALID_INDEX
		      Return Nil
		    End If
		  Loop
		  Return thisdir.OpenFile("")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function OpenFile(Optional FileName As String, TruePath As Boolean = False) As SSH.SFTPStream
		  If FileName = "" Then ' get the current file
		    Select Case True
		    Case CurrentName <> "" And CurrentType <> SFTPEntryType.Directory
		      FileName = CurrentName
		    Case CurrentName = ""
		      mLastError = LIBSSH2_FX_INVALID_FILENAME
		      Return Nil
		    Else
		      mLastError = LIBSSH2_FX_NOT_A_DIRECTORY
		      Return Nil
		    End Select
		  End If
		  
		  FileName = mName + "/" + FileName
		  Do Until InStr(FileName, "//") = 0
		    FileName = ReplaceAll(FileName, "//", "/")
		  Loop
		  
		  If TruePath And CurrentType = SFTPEntryType.Symlink Then
		    FileName = mSession.ReadSymbolicLink(FileName, True)
		  End If
		  
		  Return mSession.Get(FileName)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function OpenSubdirectory(Index As Integer) As SSH.SFTPDirectory
		  Dim thisdir As New SFTPDirectory(Session, FullPath)
		  Do Until thisdir.CurrentIndex = Index
		    If Not thisdir.ReadNextEntry() Then
		      mLastError = ERR_INVALID_INDEX
		      Return Nil
		    End If
		  Loop
		  Return thisdir.OpenSubdirectory("")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function OpenSubdirectory(Optional DirectoryName As String, TruePath As Boolean = False) As SSH.SFTPDirectory
		  If DirectoryName = "" Then ' get the current directory
		    Select Case True
		    Case CurrentName <> "" And CurrentType = SFTPEntryType.Directory
		      DirectoryName = CurrentName
		    Case CurrentName = ""
		      mLastError = LIBSSH2_FX_INVALID_FILENAME
		      Return Nil
		    Else
		      mLastError = LIBSSH2_FX_NOT_A_DIRECTORY
		      Return Nil
		    End Select
		  End If
		  
		  DirectoryName = mName + "/" + DirectoryName
		  Do Until InStr(DirectoryName, "//") = 0
		    DirectoryName = ReplaceAll(DirectoryName, "//", "/")
		  Loop
		  
		  If TruePath And CurrentType = SFTPEntryType.Symlink Then
		    DirectoryName = mSession.ReadSymbolicLink(DirectoryName, True)
		  End If
		  
		  Dim subdir As SFTPDirectory = mSession.ListDirectory(DirectoryName)
		  subdir.SuppressVirtualEntries = SuppressVirtualEntries
		  Return subdir
		  
		Exception err As SSHException
		  mLastError = err.ErrorNumber
		  If mLastError = 0 Then mLastError = mSession.LastStatusCode()
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function ReadDirectoryAttributes(ByRef Attribs As LIBSSH2_SFTP_ATTRIBUTES, NoDereference As Boolean = False) As Boolean
		  Dim name As MemoryBlock = FullPath
		  Dim type As Integer = LIBSSH2_SFTP_STAT
		  If NoDereference Then type = LIBSSH2_SFTP_LSTAT
		  Do
		    mLastError = libssh2_sftp_stat_ex(mSession.Handle, name, name.Size, type, Attribs)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  Return mLastError >= 0
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
		  Else
		    Return False
		  End If
		  
		  If mCurrentName.Trim <> "" Then
		    If SuppressVirtualEntries And (mCurrentName = "." Or mCurrentName = "..") Then
		      Return ReadNextEntry()
		    End If
		    mIndex = mIndex + 1
		    Return True
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub StreamClosedHandler(Sender As SFTPStreamPtr)
		  ' This event notifies the SFTPDirectory that the underlying SFTPStreamPtr has been closed,
		  ' either by the SFTPDirectory itelf or by the SFTPSession.Close() method.
		  
		  #pragma Unused Sender
		  mStream = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function WriteDirectoryAttributes(Attribs As LIBSSH2_SFTP_ATTRIBUTES) As Boolean
		  Dim name As MemoryBlock = FullPath
		  Do
		    mLastError = libssh2_sftp_stat_ex(mSession.Handle, name, name.Size, LIBSSH2_SFTP_SETSTAT, Attribs)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  Return mLastError >= 0
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Note
			The last access time of this directory
		#tag EndNote
		#tag Getter
			Get
			  Dim attrib As LIBSSH2_SFTP_ATTRIBUTES
			  If ReadDirectoryAttributes(attrib) Then Return time_t(attrib.ATime)
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  Dim attrib As LIBSSH2_SFTP_ATTRIBUTES
			  If Not ReadDirectoryAttributes(attrib) Then Return
			  attrib.ATime = time_t(value)
			  Call WriteDirectoryAttributes(attrib)
			End Set
		#tag EndSetter
		AccessTime As Date
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mStream = Nil Then Return Nil
			  If mIndex = -1 And Not ReadNextEntry() Then Return Nil
			  If CurrentHasAttribute(LIBSSH2_SFTP_ATTR_ACMODTIME) Then
			    Return time_t(mCurrentAttribs.ATime)
			  End If
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If mStream = Nil Then Return
			  If mIndex = -1 And Not ReadNextEntry() Then Return
			  Dim metadata As SFTPStream = mSession.CreateStream(Me.FullPath + CurrentName, LIBSSH2_FXF_READ Or LIBSSH2_FXF_WRITE, 0, False)
			  If metadata <> Nil Then
			    metadata.AccessTime = value
			    metadata.Close()
			  End If
			  
			End Set
		#tag EndSetter
		CurrentAccessTime As Date
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mStream = Nil Then Return -1
			  If mIndex = -1 Then Call ReadNextEntry()
			  return mIndex
			End Get
		#tag EndGetter
		CurrentIndex As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mIndex = -1 And Not ReadNextEntry() Then Return 0
			  If CurrentType = SFTPEntryType.Directory Then Return 0
			  If CurrentHasAttribute(LIBSSH2_SFTP_ATTR_SIZE) Then
			    Return mCurrentAttribs.FileSize
			  End If
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If mStream = Nil Then Return
			  If mIndex = -1 And Not ReadNextEntry() Then Return
			  Dim metadata As SFTPStream = mSession.CreateStream(Me.FullPath + CurrentName, LIBSSH2_FXF_READ Or LIBSSH2_FXF_WRITE, 0, False)
			  If metadata <> Nil Then
			    metadata.Length = value
			    metadata.Close()
			  End If
			  
			End Set
		#tag EndSetter
		CurrentLength As UInt64
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mStream = Nil Then Return Nil
			  If mIndex = -1 And Not ReadNextEntry() Then Return Nil
			  If CurrentHasAttribute(LIBSSH2_SFTP_ATTR_PERMISSIONS) Then
			    Return New Permissions(mCurrentAttribs.Perms)
			  End If
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If mStream = Nil Then Return
			  If mIndex = -1 And Not ReadNextEntry() Then Return
			  Dim metadata As SFTPStream = mSession.CreateStream(Me.FullPath + CurrentName, 0, 0, False)
			  If metadata <> Nil Then
			    metadata.Mode = value
			    metadata.Close()
			  End If
			  
			End Set
		#tag EndSetter
		CurrentMode As Permissions
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mStream = Nil Then Return Nil
			  If mIndex = -1 And Not ReadNextEntry() Then Return Nil
			  If CurrentHasAttribute(LIBSSH2_SFTP_ATTR_ACMODTIME) Then
			    Return time_t(mCurrentAttribs.MTime)
			  End If
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If mStream = Nil Then Return
			  If mIndex = -1 And Not ReadNextEntry() Then Return
			  Dim metadata As SFTPStream = mSession.CreateStream(Me.FullPath + CurrentName, LIBSSH2_FXF_READ Or LIBSSH2_FXF_WRITE, 0, False)
			  If metadata <> Nil Then
			    metadata.ModifyTime = value
			    metadata.Close()
			  End If
			  
			End Set
		#tag EndSetter
		CurrentModifyTime As Date
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mIndex = -1 And Not ReadNextEntry() Then Return ""
			  return mCurrentName
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  Dim p As SFTPDirectory = Me.Parent()
			  value = mSession.Rename(Me.FullPath + CurrentName, p.FullPath + value)
			  If mSession.LastStatusCode = 0 Then
			    mCurrentName = value
			  End If
			  
			End Set
		#tag EndSetter
		CurrentName As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mStream = Nil Then Return SFTPEntryType.Unknown
			  If mIndex = -1 Then Call ReadNextEntry()
			  If mIndex = -1 Then Return SFTPEntryType.Unknown
			  
			  If CurrentHasAttribute(LIBSSH2_SFTP_ATTR_PERMISSIONS) Then
			    Select Case BitAnd(mCurrentAttribs.Perms, LIBSSH2_SFTP_S_IFMT)
			    Case LIBSSH2_SFTP_S_IFDIR
			      Return SFTPEntryType.Directory
			    Case LIBSSH2_SFTP_S_IFREG
			      Return SFTPEntryType.File
			    Case LIBSSH2_SFTP_S_IFBLK
			      Return SFTPEntryType.BlockSpecial
			    Case LIBSSH2_SFTP_S_IFCHR
			      Return SFTPEntryType.CharacterSpecial
			    Case LIBSSH2_SFTP_S_IFIFO
			      Return SFTPEntryType.Pipe
			    Case LIBSSH2_SFTP_S_IFLNK
			      Return SFTPEntryType.Symlink
			    Case LIBSSH2_SFTP_S_IFSOCK
			      Return SFTPEntryType.Socket
			    Else
			      If Right(FullPath, 1) = "/" Then ' probably a directory
			        Return SFTPEntryType.Directory
			      Else
			        Return SFTPEntryType.File ' some kind of filesystem object
			      End If
			    End Select
			  End If
			End Get
		#tag EndGetter
		CurrentType As SSH.SFTPEntryType
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Note
			The full remote path of this directory.
		#tag EndNote
		#tag Getter
			Get
			  ' Gets the full remote path of the directory being listed.
			  
			  Dim nm As String = mName
			  Do Until InStr(nm, "//") = 0
			    nm = ReplaceAll(nm, "//", "/")
			  Loop
			  Return nm
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' Sets the full remote path of the directory being listed. If the server allows/supports the operation
			  ' then the directory is moved/renamed.
			  
			  value = mSession.Rename(Me.FullPath, value)
			  If mSession.LastStatusCode = 0 Then
			    mName = value
			  End If
			  
			End Set
		#tag EndSetter
		FullPath As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns the most recent libssh2 error code for this instance of SFTPDirectory
			  
			  Return mLastError
			End Get
		#tag EndGetter
		LastError As Int32
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
		Private mIndex As Integer = -1
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastError As Int32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mName As String
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Note
			The Unix style permissions of this directory
		#tag EndNote
		#tag Getter
			Get
			  Dim attrib As LIBSSH2_SFTP_ATTRIBUTES
			  If ReadDirectoryAttributes(attrib) Then Return New Permissions(attrib.Perms)
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  Dim attrib As LIBSSH2_SFTP_ATTRIBUTES
			  If Not ReadDirectoryAttributes(attrib) Then Return
			  attrib.Perms = PermissionsToMode(value)
			  Call WriteDirectoryAttributes(attrib)
			End Set
		#tag EndSetter
		Mode As Permissions
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Note
			The last modified time of this directory
		#tag EndNote
		#tag Getter
			Get
			  Dim attrib As LIBSSH2_SFTP_ATTRIBUTES
			  If ReadDirectoryAttributes(attrib) Then Return time_t(attrib.MTime)
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  Dim attrib As LIBSSH2_SFTP_ATTRIBUTES
			  If Not ReadDirectoryAttributes(attrib) Then Return
			  attrib.MTime = time_t(value)
			  Call WriteDirectoryAttributes(attrib)
			End Set
		#tag EndSetter
		ModifyTime As Date
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mSession As SSH.SFTPSession
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mStream As SFTPStreamPtr
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If Right(mName, 1) = "/" Then
			    return NthField(mName, "/", CountFields(mName, "/") - 1)
			  Else
			    return NthField(mName, "/", CountFields(mName, "/"))
			  End If
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  Dim p As SFTPDirectory = Me.Parent()
			  value = mSession.Rename(Me.FullPath, p.FullPath + value)
			  If mSession.LastStatusCode = 0 Then
			    mName = value
			  End If
			  
			End Set
		#tag EndSetter
		Name As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mName = "/" Or mName = "" Then
			    mLastError = LIBSSH2_FX_NOT_A_DIRECTORY
			    Return Nil
			  End If
			  Dim nm() As String = Split(mName, "/")
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
			  return mSession
			End Get
		#tag EndGetter
		Session As SSH.SFTPSession
	#tag EndComputedProperty

	#tag Property, Flags = &h0
		#tag Note
			When True, the self(.) and parent(..) virtual directory references are skipped.
		#tag EndNote
		SuppressVirtualEntries As Boolean = True
	#tag EndProperty


	#tag Constant, Name = LIBSSH2_SFTP_LSTAT, Type = Double, Dynamic = False, Default = \"1", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_SETSTAT, Type = Double, Dynamic = False, Default = \"2", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_SFTP_STAT, Type = Double, Dynamic = False, Default = \"0", Scope = Protected
	#tag EndConstant

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
			EditorType="MultiLineEditor"
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

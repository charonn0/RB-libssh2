#tag Class
Protected Class PublicKeyList
	#tag Method, Flags = &h0
		Function AddKey(Name As String, Key As MemoryBlock) As Boolean
		  Dim n As MemoryBlock = Name + Chr(0)
		  mLastError = libssh2_publickey_add_ex(mKey, n, n.Size, Key, Key.Size, Nil, 0, Nil)
		  Return mLastError = 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Close()
		  If mList <> Nil Then libssh2_publickey_list_free(mKey, mList)
		  mList = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(Session As SSH.Session)
		  mInit = SSHInit.GetInstance()
		  mSession = Session
		  
		  mKey = libssh2_publickey_init(Session.Handle)
		  If mKey = Nil Then Raise New SSHException(Session.GetLastError)
		  
		  Me.Refresh()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Count() As UInt32
		  Return mCount
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  Me.Close
		  If mKey <> Nil Then
		    mLastError = libssh2_publickey_shutdown(mKey)
		    mKey = Nil
		    If mLastError <> 0 Then Raise New SSHException(mLastError)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GetEntry(Index As Integer) As Ptr
		  Dim this As Ptr = mList
		  Dim c As Integer
		  Do
		    If c = Index Then Return this
		    c = c + 1
		    this = this.Ptr(4)
		  Loop Until this = Nil
		  Raise New OutOfBoundsException
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Handle() As Ptr
		  Return mKey
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Item(Index As Integer) As Dictionary
		  Dim list As libssh2_publickey_list = Me.GetEntry(Index).libssh2_publickey_list
		  Dim d As New Dictionary
		  Dim tmp As MemoryBlock = list.Name
		  d.Value("name") = tmp.StringValue(0, list.NameLength)
		  tmp = list.Blob
		  d.Value("blob") = tmp.StringValue(0, list.BlobLength)
		  d.Value("attribs") = list.Attribs
		  d.Value("attribscount") = list.NumAttribs
		  
		  Return d
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Refresh()
		  Me.Close()
		  mLastError = libssh2_publickey_list_fetch(mKey, mCount, mList)
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function RemoveKey(Name As String, Key As MemoryBlock) As Boolean
		  Dim n As MemoryBlock = Name + Chr(0)
		  mLastError = libssh2_publickey_remove_ex(mKey, n, n.Size, Key, Key.Size)
		  Return mLastError = 0
		End Function
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mCount As UInt32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mInit As SSHInit
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mKey As Ptr
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastError As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mList As Ptr
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSession As SSH.Session
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mSession
			End Get
		#tag EndGetter
		Session As SSH.Session
	#tag EndComputedProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="ExitStatus"
			Group="Behavior"
			Type="Integer"
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

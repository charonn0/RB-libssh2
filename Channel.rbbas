#tag Class
Protected Class Channel
Implements Readable, Writeable
	#tag Method, Flags = &h0
		Sub Close()
		  Dim err As Integer = libssh2_channel_close(mChannel)
		  If err <> 0 Then Raise New RuntimeException
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(Session As SSH.Session, RemoteHost As String, RemotePort As Integer, LocalHost As String, LocalPort As Integer)
		  mInit = SSHInit.Init()
		  mChannel = libssh2_channel_direct_tcpip_ex(Session.Handle, RemoteHost, RemotePort, LocalHost, LocalPort)
		  If mChannel = Nil Then Raise New RuntimeException
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If mChannel <> Nil Then
		    Dim err As Integer = libssh2_channel_free(mChannel)
		    If err <> 0 Then Raise New RuntimeException
		  End If
		  mChannel = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function EOF() As Boolean
		  // Part of the Readable interface.
		  #error  // (don't forget to implement this method!)
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Flush()
		  // Part of the Writeable interface.
		  #error  // (don't forget to implement this method!)
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Read(Count As Integer, encoding As TextEncoding = Nil) As String
		  // Part of the Readable interface.
		  #error  // (don't forget to implement this method!)
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadError() As Boolean
		  // Part of the Readable interface.
		  #error  // (don't forget to implement this method!)
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Write(text As String)
		  // Part of the Writeable interface.
		  #error  // (don't forget to implement this method!)
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function WriteError() As Boolean
		  // Part of the Writeable interface.
		  #error  // (don't forget to implement this method!)
		  
		  
		End Function
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mChannel As Ptr
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mInit As SSHInit
	#tag EndProperty


End Class
#tag EndClass

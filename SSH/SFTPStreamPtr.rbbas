#tag Class
Private Class SFTPStreamPtr
Inherits SSH.SFTPStream
	#tag Method, Flags = &h0
		Sub Close()
		  Super.Close()
		  RaiseEvent Closed()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(Session As SSH.SFTPSession, RemoteName As String, Flags As Integer, Mode As Integer, Directory As Boolean = False)
		  ' This class exists solely to protect the superclass constructor from being called from outside
		  ' the SSH module.
		  
		  Super.Constructor(Session, RemoteName, Flags, Mode, Directory)
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event Closed()
	#tag EndHook

End Class
#tag EndClass

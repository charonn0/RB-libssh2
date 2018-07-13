#tag Class
Protected Class SCPSession
	#tag Method, Flags = &h1
		Protected Sub Constructor(Session As SSH.Session, ChannelPtr As Ptr)
		  mInit = SSHInit.GetInstance()
		  mChannel = ChannelPtr
		  mSession = Session
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Open(Session As SSH.Session) As SSH.SCPSession
		  
		End Function
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mChannel As Ptr
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mInit As SSHInit
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastError As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSession As SSH.Session
	#tag EndProperty


End Class
#tag EndClass

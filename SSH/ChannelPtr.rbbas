#tag Class
Private Class ChannelPtr
Inherits SSH.Channel
	#tag Method, Flags = &h1000
		Sub Constructor(Session As SSH.Session, ChannelPtr As Ptr)
		  // Calling the overridden superclass constructor.
		  // Constructor(SSH.Session, Ptr) -- from SSH.Channel
		  mFreeable = False
		  Super.Constructor(Session, ChannelPtr)
		End Sub
	#tag EndMethod


End Class
#tag EndClass

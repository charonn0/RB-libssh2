#tag Class
Private Class AgentKeyPtr
Inherits SSH.AgentKey
	#tag Method, Flags = &h1000
		Sub Constructor(Owner As SSH.Agent, KeyStruct As Ptr, Index As Integer)
		  // Calling the overridden superclass constructor.
		  Super.Constructor(Owner, KeyStruct, Index)
		End Sub
	#tag EndMethod


End Class
#tag EndClass

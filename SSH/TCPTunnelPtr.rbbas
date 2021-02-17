#tag Class
Private Class TCPTunnelPtr
Inherits SSH.TCPTunnel
	#tag Method, Flags = &h1000
		Sub Constructor(Session As SSH.Session, ChannelPtr As Ptr)
		  ' This class exists solely to protect the superclass constructor from being called from outside
		  ' the SSH module.
		  
		  // Calling the overridden superclass constructor.
		  // Constructor(Session As SSH.Session, ChannelPtr As Ptr) -- From Channel
		  Super.Constructor(Session, ChannelPtr)
		  
		End Sub
	#tag EndMethod


	#tag ViewBehavior
		#tag ViewProperty
			Name="ExitStatus"
			Group="Behavior"
			Type="Integer"
			InheritedFrom="SSH.Channel"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			Type="Integer"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="IsOpen"
			Group="Behavior"
			Type="Boolean"
			InheritedFrom="SSH.Channel"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="LocalPort"
			Group="Behavior"
			Type="Integer"
			InheritedFrom="SSH.TCPTunnel"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="RemoteAddress"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
			InheritedFrom="SSH.TCPTunnel"
		#tag EndViewProperty
		#tag ViewProperty
			Name="RemotePort"
			Group="Behavior"
			Type="Integer"
			InheritedFrom="SSH.TCPTunnel"
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

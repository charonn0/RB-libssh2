#tag Class
Private Class SFTPDirectoryPtr
Inherits SSH.SFTPDirectory
	#tag Method, Flags = &h1000
		Sub Constructor(Session As SSH.SFTPSession, RemoteName As String)
		  ' This class exists solely to protect the superclass constructor from being called from outside
		  ' the SSH module.
		  
		  Super.Constructor(Session, RemoteName)
		End Sub
	#tag EndMethod


	#tag ViewBehavior
		#tag ViewProperty
			Name="CurrentIndex"
			Group="Behavior"
			Type="Integer"
			InheritedFrom="SSH.SFTPDirectory"
		#tag EndViewProperty
		#tag ViewProperty
			Name="CurrentName"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
			InheritedFrom="SSH.SFTPDirectory"
		#tag EndViewProperty
		#tag ViewProperty
			Name="FullPath"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
			InheritedFrom="SSH.SFTPDirectory"
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
			Name="SuppressVirtualEntries"
			Group="Behavior"
			InitialValue="True"
			Type="Boolean"
			InheritedFrom="SSH.SFTPDirectory"
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

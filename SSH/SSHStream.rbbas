#tag Interface
Interface SSHStream
Implements Readable,Writeable
	#tag Method, Flags = &h0
		Sub Close()
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Length() As UInt64
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Length(Assigns NewLength As UInt64)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Position() As UInt64
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Position(Assigns NewPosition As UInt64)
		  
		End Sub
	#tag EndMethod


	#tag ViewBehavior
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
End Interface
#tag EndInterface

#tag Class
Protected Class AgentKey
	#tag Method, Flags = &h1
		Protected Sub Constructor(Owner As SSH.Agent, KeyStruct As Ptr, Index As Integer)
		  mAgent = Owner
		  #If Target32Bit Then
		    mStruct = KeyStruct.libssh2_agent_publickey
		  #Else
		    mStruct64 = KeyStruct.libssh2_agent_publickey_64
		  #EndIf
		  mIndex = Index
		End Sub
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns the comment (if any) for the key
			  
			  Dim mb As MemoryBlock
			  #If Target32Bit Then
			    mb = mStruct.Comment
			  #Else
			    mb = mStruct64.Comment
			  #EndIf
			  
			  If mb <> Nil Then Return mb.CString(0)
			End Get
		#tag EndGetter
		Comment As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mIndex
			End Get
		#tag EndGetter
		Index As Integer
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mAgent As SSH.Agent
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mIndex As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mStruct As libssh2_agent_publickey
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mStruct64 As libssh2_agent_publickey_64
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mAgent
			End Get
		#tag EndGetter
		Owner As SSH.Agent
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns a copy of the PublicKey at Index in the Agent's list of keys.
			  
			  Dim mb As MemoryBlock
			  Dim sz As UInt32
			  #If Target32Bit Then
			    mb = mStruct.Blob
			    sz = mStruct.BlobLength
			  #Else
			    mb = mStruct64.Blob
			    sz = mStruct64.BlobLength
			  #EndIf
			  Return mb.StringValue(0, sz)
			End Get
		#tag EndGetter
		PublicKey As MemoryBlock
	#tag EndComputedProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="IsConnected"
			Group="Behavior"
			Type="Boolean"
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
			Name="Path"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
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

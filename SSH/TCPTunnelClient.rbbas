#tag Class
Protected Class TCPTunnelClient
Inherits SSH.Channel
	#tag Method, Flags = &h1000
		Sub Constructor(Session As SSH.Session, RemoteInterface As String, RemotePort As Integer, LocalAddress As NetworkInterface, LocalPort As Integer)
		  Dim p As Ptr
		  Dim localIP As String = LocalAddress.IPAddress
		  p = libssh2_channel_direct_tcpip_ex(Session.Handle, RemoteInterface, RemotePort, localIP, LocalPort)
		  If p <> Nil Then
		    Super.Constructor(Session, p)
		  Else
		    Raise New SSHException(Session)
		  End If
		  
		  mSession = Session
		  mRemoteInterface = RemoteInteface
		  mRemotePort = RemotePort
		  mLocalInterface = LocalAddress
		  mLocalPort = LocalPort
		End Sub
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mLocalInterface
			End Get
		#tag EndGetter
		LocalInterface As NetworkInterface
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mLocalPort
			End Get
		#tag EndGetter
		LocalPort As Integer
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mLocalInterface As NetworkInterface
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLocalPort As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mRemoteInterface As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mRemotePort As Integer
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mRemoteInterface
			End Get
		#tag EndGetter
		RemoteInteface As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mRemotePort
			End Get
		#tag EndGetter
		RemotePort As Integer
	#tag EndComputedProperty


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
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="RemoteInteface"
			Group="Behavior"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="RemotePort"
			Group="Behavior"
			Type="Integer"
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

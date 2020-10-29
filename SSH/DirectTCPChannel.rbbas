#tag Class
Protected Class DirectTCPChannel
Inherits TCPSocket
	#tag Event
		Sub DataAvailable()
		  Me.Poll()
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h0
		Sub Close()
		  If mForwarder <> Nil Then mForwarder.Close()
		  mForwarder = Nil
		  Super.Close()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1000
		Sub Constructor(Session As SSH.Session, RemoteAddress As String, RemotePort As Integer)
		  mSession = Session
		  mForwardAddress = RemoteAddress
		  mForwardPort = RemotePort
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ExchangeStreams()
		  If mForwarder.BytesLeft > 0 And Me.BytesAvailable > 0 Then
		    Dim sz As Integer = Min(Me.BytesAvailable, mForwarder.BytesLeft)
		    mForwarder.Write(Me.Read(sz), 0)
		  End If
		  If mForwarder.BytesAvailable > 0 Then
		    Me.Write(mForwarder.Read(mForwarder.BytesAvailable, 0))
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ForwardDataAvailable(Sender As SSH.Channel, ExtendedData As Boolean)
		  #pragma Unused Sender
		  #pragma Unused ExtendedData
		  ExchangeStreams()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ForwardDisconnected(Sender As SSH.Channel)
		  #pragma Unused Sender
		  Me.Close()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ForwardError(Sender As SSH.Channel, Reasons As Int32)
		  #pragma Unused Sender
		  RaiseEvent SSHError(Reasons)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Listen()
		  Dim p As Ptr = libssh2_channel_direct_tcpip_ex(mSession.Handle, mForwardAddress, mForwardPort, Me.NetworkInterface.IPAddress, Me.Port)
		  If p <> Nil Then
		    mForwarder = New ChannelPtr(mSession, p)
		    AddHandler mForwarder.DataAvailable, WeakAddressOf ForwardDataAvailable
		    AddHandler mForwarder.Error, WeakAddressOf ForwardError
		    AddHandler mForwarder.Disconnected, WeakAddressOf ForwardDisconnected
		    Super.Listen()
		    
		  Else
		    RaiseEvent SSHError(mSession.LastError)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Poll()
		  If mForwarder <> Nil And mForwarder.IsOpen Then Call mForwarder.Poll(1)
		  Super.Poll()
		  ExchangeStreams()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function Read(Count As Integer, encoding As TextEncoding = Nil) As String
		  Return Super.Read(Count, encoding)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ReadAll(encoding As TextEncoding = Nil) As String
		  Return Super.ReadAll(encoding)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Write(text As String)
		  Super.Write(text)
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event SSHError(ErrorCode As Int32)
	#tag EndHook


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mForwardPort
			End Get
		#tag EndGetter
		ForwardPort As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mForwardAddress
			End Get
		#tag EndGetter
		FowardAddress As String
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mForwardAddress As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mForwarder As SSH.Channel
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mForwardPort As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSession As SSH.Session
	#tag EndProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="Address"
			Visible=true
			Group="Behavior"
			Type="String"
			InheritedFrom="TCPSocket"
		#tag EndViewProperty
		#tag ViewProperty
			Name="ForwardPort"
			Group="Behavior"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="FowardAddress"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
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
			Name="Port"
			Visible=true
			Group="Behavior"
			InitialValue="0"
			Type="Integer"
			InheritedFrom="TCPSocket"
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

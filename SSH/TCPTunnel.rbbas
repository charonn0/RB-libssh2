#tag Class
Protected Class TCPTunnel
Inherits SSH.Channel
	#tag Event
		Sub DataAvailable(ExtendedStream As Boolean)
		  #pragma Unused ExtendedStream
		  RaiseEvent DataAvailable()
		End Sub
	#tag EndEvent

	#tag Event
		Sub Error(Reasons As Integer)
		  RaiseEvent Error(Reasons)
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h0
		Sub Close()
		  ' Frees the listener if necessary then calls Channel.Close()
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.Channel.Close
		  
		  If mListener <> Nil Then mListener.StopListening()
		  mListener = Nil
		  Super.Close()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1000
		Function Connect() As Boolean
		  ' Initiates an outbound TCP connection to the third party, as indicated by the RemoteAddress
		  ' and RemotePort properties, using the SSH server as an intermediary. If the connection was
		  ' successful then the Connected() event will be raised and this method returns True. Otherwise,
		  ' the Error() event will be raised. Once connected you may read from and write to the tunnel
		  ' like any other Channel.
		  '
		  ' If the tunnel is forwarding an actual TCPSocket then the LocalInterface and LocalPort properties
		  ' should reflect the corresponding properties of the socket being forwarded.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPTunnel.Connect
		  
		  If Me.IsConnected Or Me.IsListening Then
		    mLastError = ERR_TOO_LATE
		    Return False
		  End If
		  If Not Session.IsAuthenticated Then 
		    mLastError = ERR_NOT_AUTHENTICATED
		    Return False
		  End If
		  
		  Dim p As Ptr = libssh2_channel_direct_tcpip_ex(Session.Handle, RemoteAddress, RemotePort, LocalInterface.IPAddress, LocalPort)
		  If p <> Nil Then
		    // Calling the superclass constructor.
		    // Constructor(SSH.Session, Ptr) -- From SSH.Channel
		    Super.Constructor(mSession, p)
		    RaiseEvent Connected()
		    Return True
		  Else
		    mLastError = Session.LastError
		    RaiseEvent Error(mLastError)
		  End If
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1000
		Sub Constructor(Session As SSH.Session)
		  ' Construct a new unconnected tunnel.
		  ' The Session need not yet be connected or authenticated.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPTunnel.Constructor
		  
		  mSession = Session
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function EOF() As Boolean
		  ' Returns True if the tunnel is neither connected nor listening.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPTunnel.EOF
		  
		  If mListener <> Nil And mListener.IsListening Then Return False
		  Return Super.EOF()
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Flush()
		  ' Flushes the stream.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPTunnel.Flush
		  
		  Super.Flush(0)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Listen()
		  ' Instructs the SSH server to begin listening on its local network interface(s), identified
		  ' by RemoteAddress, for an inbound connection to RemotePort. If RemoteAddress="" then the
		  ' server will listen on all of its local interfaces. If RemotePort<=0 then the server will
		  ' select a random ephemeral port to listen on, and the RemotePort property will be updated
		  ' accordingly.
		  '
		  ' You must periodically call the Poll() method to poll the listener for activity. If a
		  ' connection is received then the Connected() event will be raised. If an error occurs then
		  ' the Error() event will be raised. Once connected you may read from and write to the tunnel
		  ' like any other Channel.
		  '
		  ' This method listens for exactly one inbound connection and accepts the first one that arrives.
		  ' To accept more than one inbound connection on the remote port refer to the TCPListener class.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPTunnel.Listen
		  
		  If Me.IsConnected Or Me.IsListening Then
		    mLastError = ERR_TOO_LATE
		    Return
		  End If
		  If Not Session.IsAuthenticated Then Raise New SSHException(ERR_NOT_AUTHENTICATED)
		  
		  mListener = New TCPListener(Me.Session)
		  AddHandler mListener.ConnectionReceived, WeakAddressOf ListenerConnectionReceivedHandler
		  AddHandler mListener.Error, WeakAddressOf ListenerErrorHandler
		  mListener.RemoteInterface = Me.RemoteAddress
		  mListener.RemotePort = Me.RemotePort
		  mListener.MaxConnections = 1
		  mListener.StartListening()
		  If mListener <> Nil And mListener.IsListening Then mRemotePort = mListener.RemotePort
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ListenerConnectionReceivedHandler(Sender As SSH.TCPListener, Connection As SSH.TCPTunnel)
		  ' free the listener
		  Sender.StopListening()
		  
		  ' we're taking ownership of the Connection's channel so tell it not to clean up
		  Connection.mFreeable = False
		  Connection.mOpen = False
		  Connection.mSession = Nil
		  
		  // Calling the superclass constructor.
		  // Constructor(SSH.Session, Ptr) -- From SSH.Channel
		  Super.Constructor(Me.Session, Connection.Handle)
		  RaiseEvent Connected()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ListenerErrorHandler(Sender As SSH.TCPListener, Reasons As Integer)
		  #pragma Unused Sender
		  mLastError = Reasons
		  RaiseEvent Error(Reasons)
		  Me.Close()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Poll(Timeout As Integer = 1000, EventMask As Integer = - 1) As Boolean
		  ' If already connected then this method calls the superclass
		  ' Poll() method. If listening but not connected, calls TCPListener.Poll()
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPTunnel.Poll
		  
		  If Me.IsConnected Then
		    Return Super.Poll(Timeout, EventMask)
		  End If
		  
		  If Me.IsListening Then
		    mListener.Poll(Timeout)
		    Return Me.IsConnected
		  End If
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Read(Count As Integer, encoding As TextEncoding = Nil) As String
		  ' Reads bytes from a tunnel if there is data available.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPTunnel.Read
		  
		  Return Super.Read(Count, 0, encoding)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Write(text As String)
		  ' Writes data to the tunnel.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPTunnel.Write
		  
		  Super.Write(text, 0)
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event Connected()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event DataAvailable()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Error(Reasons As Integer)
	#tag EndHook


	#tag Note, Name = About this class
		This class is for initiating or accepting a TCP tunnel from the client to a third party, using the SSH server as an intermediary.
		
		For example, this forwards an HTTP request through the SSH server to google.com:
		
		  Dim tunnel As New SSH.TCPTunnel(Session)
		  tunnel.RemoteAddress = "www.google.com"
		  tunnel.RemotePort = 80
		  If Not tunnel.Connect() Then
		    MsgBox("Unable to open tunnel.")
		  End If
		
		  // write to the tunnel
		  Dim crlf As String = EndOfLine.Windows
		  tunnel.Write( _
		     "GET / HTTP/1.0" + crlf + _
		     "Host: www.google.com" + crlf + _
		     "Connection: close" + crlf + crlf)
		  
		  // read from the tunnel
		  Dim output As String
		  Do Until tunnel.EOF
		    If tunnel.PollReadable() Then
		      output = output + tunnel.Read(tunnel.BytesReadable)
		    End If
		  Loop
	#tag EndNote


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns True if the tunnel is connected. Equivalent to Channel.IsOpen.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPTunnel.IsConnected
			  
			  Return IsOpen
			End Get
		#tag EndGetter
		IsConnected As Boolean
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns True if the tunnel is listening for a connection.
			  ' Check TCPTunnel.IsConnected to determine whether a connection
			  ' has been received.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPTunnel.IsListening
			  
			  Return mListener <> Nil
			End Get
		#tag EndGetter
		IsListening As Boolean
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns a reference to the TCPListener that is actually doing the listening
			  ' if the tunnel is in listen mode, or Nil if not.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPTunnel.Listener
			  
			  return mListener
			End Get
		#tag EndGetter
		Listener As SSH.TCPListener
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Note
			The local NetworkInterface that is initiating the outbound connection. 
			If this property is not set to a custom value then Session.NetworkInterface
			is used. The LocalInterface need not refer to the same interface that the 
			SSH session is using.
		#tag EndNote
		#tag Getter
			Get
			  ' Returns the local NetworkInterface that is initiating the outbound connection. If this
			  ' property is not set to a custom value then Session.NetworkInterface is used. The
			  ' LocalInterface need not refer to the same interface that the SSH session is using.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPTunnel.LocalInterface
			  
			  If mLocalInterface = Nil Then mLocalInterface = mSession.NetworkInterface
			  return mLocalInterface
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' Specifies the local NetworkInterface that is initiating the outbound connection. If this
			  ' property is not set to a custom value then Session.NetworkInterface is used. The
			  ' LocalInterface need not refer to the same interface that the SSH session is using.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPTunnel.LocalInterface
			  
			  If IsOpen Then
			    mLastError = ERR_TOO_LATE
			    Return
			  End If
			  mLocalInterface = value
			End Set
		#tag EndSetter
		LocalInterface As NetworkInterface
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' The local port number that is initiating the outbound connection. If this property is
			  ' not set to a custom value then a random ephemeral port is used. The local port number
			  ' need not actually be available.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPTunnel.LocalPort
			  
			  If mLocalPort <= 0 Then
			    Dim r As New Random
			    mLocalPort = r.InRange(4096, 65534)
			  End If
			  return mLocalPort
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' The local port number that is initiating the outbound connection. If this property is
			  ' not set to a custom value then a random ephemeral port is used. The local port number
			  ' need not actually be available.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPTunnel.LocalPort
			  
			  If IsOpen Then
			    mLastError = ERR_TOO_LATE
			    Return
			  End If
			  mLocalPort = value
			End Set
		#tag EndSetter
		LocalPort As Integer
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mListener As SSH.TCPListener
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLocalInterface As NetworkInterface
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLocalPort As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mRemoteAddress As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mRemotePort As Integer
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' The hostname or IP address of the third-party server we want the SSH server to open a
			  ' connection to. If a hostname is provided then the SSH server will resolve it to an IP
			  ' according to its own DNS configuration.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPTunnel.RemoteAddress
			  
			  return mRemoteAddress
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' The hostname or IP address of the third-party server we want the SSH server to open a
			  ' connection to. If a hostname is provided then the SSH server will resolve it to an IP
			  ' according to its own DNS configuration.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPTunnel.RemoteAddress
			  
			  If IsOpen Then
			    mLastError = ERR_TOO_LATE
			    Return
			  End If
			  mRemoteAddress = value
			End Set
		#tag EndSetter
		RemoteAddress As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' The port number on the third-party server we want the SSH server to open a connection to.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPTunnel.RemotePort
			  
			  return mRemotePort
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' The port number on the third-party server we want the SSH server to open a connection to.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPTunnel.RemotePort
			  
			  If IsOpen Then
			    mLastError = ERR_TOO_LATE
			    Return
			  End If
			  mRemotePort = value
			End Set
		#tag EndSetter
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
			Name="RemoteAddress"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
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

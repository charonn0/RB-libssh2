#tag Class
Protected Class TCPListener
Implements ErrorSetter
	#tag Method, Flags = &h1
		Protected Function AcceptNextConnection() As TCPTunnel
		  If mListener = Nil Then Return Nil
		  Dim ch As Ptr = libssh2_channel_forward_accept(mListener)
		  If ch <> Nil Then
		    Return New TCPTunnelPtr(mSession, ch)
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(Session As SSH.Session)
		  ' Creates a listener for inbound TCP connections to the SSH server.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPListener.Constructor
		  
		  mSession = Session
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If mListener <> Nil Then Me.StopListening()
		  mListener = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub LastError(Assigns err As Int32)
		  // Part of the ErrorSetter interface.
		  If err > 0 Then ' poll results
		    Select Case True
		    Case Mask(err, LIBSSH2_POLLFD_POLLIN)
		      RaiseEvent ConnectionReceived(AcceptNextConnection())
		      
		    Case Mask(err, LIBSSH2_POLLFD_POLLERR), Mask(err, LIBSSH2_POLLFD_POLLHUP), Mask(err, LIBSSH2_POLLFD_POLLNVAL), _
		      Mask(err, LIBSSH2_POLLFD_POLLEX), Mask(err, LIBSSH2_POLLFD_SESSION_CLOSED), Mask(err, LIBSSH2_POLLFD_CHANNEL_CLOSED)
		      If Mask(err, LIBSSH2_POLLFD_SESSION_CLOSED) Or Mask(err, LIBSSH2_POLLFD_CHANNEL_CLOSED) Then
		        err = Session.LastError()
		      End If
		      RaiseEvent Error(err)
		      StopListening()
		    End Select
		  End If
		  mLastError = err
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Poll(Timeout As Integer = 1000)
		  ' Polls the listener and raises the appropriate events if there is activity.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPListener.Poll
		  
		  If Not IsListening Then Return
		  Dim pollfd As LIBSSH2_POLLFD
		  pollfd.Type = LIBSSH2_POLLFD_LISTENER
		  pollfd.Descriptor = Me.Handle
		  pollfd.Events = LIBSSH2_POLLFD_POLLIN Or LIBSSH2_POLLFD_POLLEXT Or LIBSSH2_POLLFD_POLLOUT
		  If libssh2_poll(pollfd, 1, Timeout) = 1 Then
		    Me.LastError = pollfd.REvents
		  Else
		    Me.LastError = Session.LastError
		  End If
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub StartListening()
		  ' Instruct the SSH server to begin listening on its local network interface(s), identified
		  ' by RemoteInterface, for inbound connections to RemotePort. If RemoteInterface="" then the
		  ' server will listen on all of its local interfaces. If RemotePort<=0 then the server will
		  ' select a random ephemeral port to listen on, and the RemotePort property will be updated
		  ' accordingly.
		  '
		  ' You must periodically call the Poll() method to poll the listener for activity. If a
		  ' connection is received then the ConnectionReceived() event will be raised. If an error
		  ' occurs then the Error() event will be raised. 
		  '
		  ' libssh2 will enqueue at most MaxConnections before refusing to accept new ones. Once a
		  ' connection is passed to the ConnectionReceived() event it is no longer counted against
		  ' MaxConnections.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPListener.StartListening
		  
		  If mListener <> Nil Then Return
		  Do Until mListener <> Nil
		    If RemoteInterface = "" Then
		      mListener = libssh2_channel_forward_listen_ex(mSession.Handle, Nil, mRemotePort, mRemotePort, mMaxConnections)
		    Else
		      mListener = libssh2_channel_forward_listen_ex(mSession.Handle, RemoteInterface, mRemotePort, mRemotePort, mMaxConnections)
		    End If
		  Loop Until mSession.LastError <> LIBSSH2_ERROR_EAGAIN
		  
		  If mListener = Nil Then
		    mLastError = Session.LastError
		    RaiseEvent Error(mLastError)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub StopListening()
		  ' Instruct the server to stop accepting TCP connections. Existing connections will
		  ' continue to exist until they are explicitly closed. Connections that were already
		  ' received by the server but not yet accepted by us will be dropped.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPListener.StopListening
		  
		  If mListener <> Nil Then
		    Do
		      mLastError = libssh2_channel_forward_cancel(mListener)
		    Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  End If
		  mListener = Nil
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event ConnectionReceived(Connection As SSH.TCPTunnel)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Error(Reasons As Integer)
	#tag EndHook


	#tag Note, Name = About this class
		This class instructs the SSH server to begin listening for inbound TCP connections
		of the RemoteInterface and RemotePort. If RemoteInterface is the empty string then
		the server will listen on all local interfaces. If RemotePort is zero then the 
		server will select a random port which you can determine by reading the RemotePort
		after StartListening() finishes successfully.
	#tag EndNote


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' The internal handle reference of the object.
			  ' 
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPListener.Handle
			  
			  return mListener
			End Get
		#tag EndGetter
		Handle As Ptr
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns True if the listener is active.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPListener.IsListening
			  
			  return mListener <> Nil
			End Get
		#tag EndGetter
		IsListening As Boolean
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns the most recent libssh2 error code for this instance of TCPListener.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPListener.LastError
			  
			  return mLastError
			End Get
		#tag EndGetter
		LastError As Int32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Gets the maximum number of pending connections to queue before rejecting further attempts.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPListener.MaxConnections
			  
			  return mMaxConnections
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' Sets maximum number of pending connections to queue before rejecting further attempts. 
			  ' This cannot be changed while listening.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPListener.MaxConnections
			  
			  If IsListening Then
			    mLastError = ERR_TOO_LATE
			    Return
			  End If
			  mMaxConnections = value
			End Set
		#tag EndSetter
		MaxConnections As Integer
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mLastError As Int32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mListener As Ptr
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mMaxConnections As Integer = 10
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mRemoteInterface As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mRemotePort As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSession As SSH.Session
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' The IP address of the network interface on the server on which to accept connections. If
			  ' this property is the empty string then the server will listen on all of its interfaces.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPListener.RemoteInterface
			  
			  return mRemoteInterface
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' The IP address of the network interface on the server on which to accept connections. If
			  ' this property is the empty string then the server will listen on all of its interfaces.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPListener.RemoteInterface
			  
			  If IsListening Then
			    mLastError = ERR_TOO_LATE
			    Return
			  End If
			  mRemoteInterface = value
			End Set
		#tag EndSetter
		RemoteInterface As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' The port number on which to accept connections.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPListener.RemotePort
			  
			  return mRemotePort
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' The port number on which to accept connections.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPListener.RemotePort
			  
			  If IsListening Then
			    mLastError = ERR_TOO_LATE
			    Return
			  End If
			  mRemotePort = value
			End Set
		#tag EndSetter
		RemotePort As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns a reference to the Session that owns the listener.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPListener.Session
			  
			  return mSession
			End Get
		#tag EndGetter
		Session As SSH.Session
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
			Name="IsListening"
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
			Name="RemoteInterface"
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

#tag Class
Protected Class Channel
Implements SSHStream
	#tag Method, Flags = &h0
		Sub Close()
		  // Part of the SSHStream interface.
		  ' Sends the SSH2 channel close message to the server.
		  
		  If mChannel = Nil Or Not mOpen Then Return
		  
		  Do
		    mLastError = libssh2_channel_close(mChannel)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  
		  mOpen = False
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Constructor(Session As SSH.Session, ChannelPtr As Ptr)
		  ' Take ownership of an already initialized libssh2 channel reference.
		  ' ChannelPtr must refer to a valid channel opened over the specified Session.
		  
		  mSession = Session
		  mChannel = ChannelPtr
		  mOpen = (ChannelPtr <> Nil)
		  ChannelParent(Session).RegisterChannel(Me)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Attributes( deprecated = "SSH.SCPStream.Constructor" )  Shared Function CreateSCP(Session As SSH.Session, Path As String, Mode As Integer, Length As UInt64, ModTime As Integer, AccessTime As Integer) As SSH.Channel
		  ' Creates a new channel over the session for uploading over SCP. Perform the upload by writing to the returned
		  ' Channel object. Make sure to call Channel.Close() when finished.
		  ' Session is an existing SSH session. Path is the full remote path to save the upload to.
		  ' Mode is the Unix-style permissions of the remote file. Length is the total size in bytes
		  ' of the file being uploaded. ModTime and AccessTime may be zero, in which case the current 
		  ' date and time are used.
		  
		  Dim c As Ptr
		  Do
		    c = libssh2_scp_send64(Session.Handle, Path, Mode, Length, ModTime, AccessTime)
		    If c = Nil Then
		      Dim e As Integer = Session.GetLastError
		      If e = LIBSSH2_ERROR_EAGAIN Then Continue
		      Raise New SSHException(e)
		    End If
		  Loop Until c <> Nil
		  Return New Channel(Session, c)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function CreateTunnel(Session As SSH.Session, RemoteHost As String, RemotePort As Integer, LocalHost As String, LocalPort As Integer) As SSH.Channel
		  ' Creates a new channel over the Session which tunnels a TCP/IP connection via the remote host to a third party.
		  ' Communication from the client to the SSH server remains encrypted, communication from the
		  ' server to the 3rd party host travels in cleartext.
		  
		  Dim p As Ptr = libssh2_channel_direct_tcpip_ex(Session.Handle, RemoteHost, RemotePort, LocalHost, LocalPort)
		  If p <> Nil Then Return New Channel(Session, p)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If mChannel <> Nil Then
		    Me.Close
		    If mFreeable Then
		      mLastError = libssh2_channel_free(mChannel)
		      If mLastError <> 0 Then Raise New SSHException(Me)
		    End If
		  End If
		  If mSession <> Nil Then ChannelParent(Me.Session).UnregisterChannel(Me)
		  mChannel = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function EndOfFile() As Boolean
		  // Part of the Readable interface.
		  Return EOF()
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function EOF() As Boolean
		  // Part of the Readable interface.
		  ' Returns True if the server has indicated that no further data will be sent over the channel.
		  
		  Do Until Not mOpen
		    mLastError = libssh2_channel_eof(mChannel)
		    Select Case mLastError
		    Case Is >= 0
		      Return mLastError = 1
		      
		    Case LIBSSH2_ERROR_EAGAIN
		      Continue
		      
		    Else
		      Raise New SSHException(Me)
		    End Select
		  Loop
		  
		  Return Not mOpen
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub EOF(Assigns b As Boolean)
		  ' Informs the server that no further data will be sent over the channel.
		  ' You may only assign True; assigning False does nothing.
		  
		  If Not b Then Return
		  Do
		    mLastError = libssh2_channel_send_eof(mChannel)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then Raise New SSHException(Me)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Execute(Command As String) As Boolean
		  ' Execute a command on the server and attach its stdin, stdout, and stderr streams to this channel.
		  
		  Return ProcessStart("exec", Command)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Flush() Implements Writeable.Flush
		  // Part of the Writeable interface.
		  Me.Flush(LIBSSH2_CHANNEL_FLUSH_ALL)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Flush(StreamID As Integer)
		  ' Flush pending output to the stream specified by StreamID.
		  ' StreamID may be an actual stream ID number or the one of LIBSSH2_CHANNEL_FLUSH_* constants.
		  
		  Do
		    mLastError = libssh2_channel_flush_ex(mChannel, StreamID)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then Raise New SSHException(Me)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Attributes( deprecated = "SSH.OpenChannel" )  Shared Function Open(Session As SSH.Session) As SSH.Channel
		  ' Creates a new channel over the Session of type "session". This is the most commonly used channel type.
		  
		  Return Open(Session, "session", LIBSSH2_CHANNEL_WINDOW_DEFAULT, LIBSSH2_CHANNEL_PACKET_DEFAULT, "")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Open(Session As SSH.Session, Type As String, WindowSize As UInt32, PacketSize As UInt32, Message As String) As SSH.Channel
		  ' Creates a new channel over the Session.
		  ' Type is typically either "session", "direct-tcpip", or "tcpip-forward".
		  ' WindowSize is the maximum amount of unacknowledged data remote host is allowed to send
		  ' before receiving an SSH_MSG_CHANNEL_WINDOW_ADJUST packet.
		  ' PacketSize is the maximum number of bytes remote host is allowed to send in a single packet.
		  ' Message contains additional data as required by the selected channel Type.
		  
		  If Not Session.IsAuthenticated Then Raise New SSHException(ERR_NOT_AUTHENTICATED)
		  Dim typ As MemoryBlock = Type + Chr(0)
		  Dim msg As MemoryBlock = Message + Chr(0)
		  Do
		    Dim c As Ptr = libssh2_channel_open_ex(Session.Handle, typ, typ.Size - 1, WindowSize, PacketSize, msg, msg.Size - 1)
		    If c = Nil Then
		      If Session.GetLastError = LIBSSH2_ERROR_EAGAIN Then Continue
		      Return Nil
		    End If
		    Return New Channel(Session, c)
		  Loop
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Attributes( deprecated = "SSH.SCPStream.Constructor" )  Shared Function OpenSCP(Session As SSH.Session, Path As String) As SSH.Channel
		  ' Creates a new channel over the session for downloading over SCP. Perform the download by
		  ' reading from the returned Channel object until Channel.EOF returns True.
		  ' Session is an existing SSH session. Path is the full remote path of the file being downloaded.
		  
		  Dim c As Ptr
		  Do
		    c = libssh2_scp_recv2(Session.Handle, Path, Nil)
		    If c = Nil Then
		      If Session.GetLastError = LIBSSH2_ERROR_EAGAIN Then Continue
		      Return Nil
		    End If
		  Loop Until c <> Nil
		  Return New Channel(Session, c)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Poll(Timeout As Integer = 1000, EventMask As Integer = - 1) As Boolean
		  ' Polls all streams and returns True if any of them signal readiness. A bitmask of
		  ' LIBSSH2_POLLFD_* constants is stored in Channel.LastError indicating which stream(s)
		  ' are ready.
		  
		  If Not mOpen Then Return False
		  If EventMask = -1 Then EventMask = LIBSSH2_POLLFD_POLLIN Or LIBSSH2_POLLFD_POLLEXT Or LIBSSH2_POLLFD_POLLOUT
		  
		  Dim pollfd As LIBSSH2_POLLFD
		  pollfd.Type = LIBSSH2_POLLFD_CHANNEL
		  pollfd.Descriptor = Me.Handle
		  pollfd.Events = EventMask
		  If libssh2_poll(pollfd, 1, Timeout) <> 1 Then
		    mLastError = Session.LastError
		    Return False
		  End If
		  mLastError = pollfd.REvents
		  
		  Dim canRead, canWrite, canReadErr, pollErr, hupErr, closedErr, invalErr, exErr As Boolean
		  canRead = BitAnd(mLastError, LIBSSH2_POLLFD_POLLIN) = LIBSSH2_POLLFD_POLLIN
		  canWrite = BitAnd(mLastError, LIBSSH2_POLLFD_POLLOUT) = LIBSSH2_POLLFD_POLLOUT
		  canReadErr = BitAnd(mLastError, LIBSSH2_POLLFD_POLLEXT) = LIBSSH2_POLLFD_POLLEXT
		  pollErr = BitAnd(mLastError, LIBSSH2_POLLFD_POLLERR) = LIBSSH2_POLLFD_POLLERR
		  hupErr = BitAnd(mLastError, LIBSSH2_POLLFD_POLLHUP) = LIBSSH2_POLLFD_POLLHUP
		  closedErr = BitAnd(mLastError, LIBSSH2_POLLFD_SESSION_CLOSED) = LIBSSH2_POLLFD_SESSION_CLOSED Or BitAnd(mLastError, LIBSSH2_POLLFD_CHANNEL_CLOSED) = LIBSSH2_POLLFD_CHANNEL_CLOSED
		  invalErr = BitAnd(mLastError, LIBSSH2_POLLFD_POLLNVAL) = LIBSSH2_POLLFD_POLLNVAL
		  exErr = BitAnd(mLastError, LIBSSH2_POLLFD_POLLEX) = LIBSSH2_POLLFD_POLLEX
		  
		  If canRead Then RaiseEvent DataAvailable(False)
		  If canReadErr Then RaiseEvent DataAvailable(True)
		  If pollErr Or hupErr Or invalErr Or exErr Then
		    RaiseEvent Error(mLastError)
		    mOpen = False
		  ElseIf closedErr Then
		    mLastError = Session.LastError()
		    RaiseEvent Disconnected()
		    mOpen = False
		  End If
		  Return canRead Or canWrite Or canReadErr
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function PollReadable(Timeout As Integer = 1000, PollStdErr As Boolean = False) As Boolean
		  ' Polls the Channel for readability. Returns True if you may Read() from the
		  ' Channel without blocking. Check Channel.BytesAvailable to learn how much
		  ' may be read.
		  
		  If Not mOpen Then Return False
		  If Not PollStdErr Then
		    Return Poll(Timeout, LIBSSH2_POLLFD_POLLIN)
		  Else
		    Return Poll(Timeout, LIBSSH2_POLLFD_POLLEXT)
		  End If
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function PollWriteable(Timeout As Integer = 1000) As Boolean
		  ' Polls the Channel for writeability. Returns True if you may Write() to the
		  ' Channel without blocking. Check Channel.BytesLeft to learn how much
		  ' may be written.
		  
		  If Not mOpen Then Return False
		  Return Poll(Timeout, LIBSSH2_POLLFD_POLLOUT)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ProcessStart(Request As String, Message As String) As Boolean
		  ' Runs the requested command, executable, or subsystem indicated by the Request parameter.
		  ' Defined requests are "exec", "shell", or "subsystem". The Message parameter contains 
		  ' request-specific data to pass to the process. Once the process is started you can read/write
		  ' from its StdIn/Out/Err with the Read and Write methods.
		  '
		  ' See: https://tools.ietf.org/html/rfc4254#section-6.5
		  
		  Dim req As MemoryBlock = Request
		  Dim msg As MemoryBlock = Message
		  Do
		    mLastError = libssh2_channel_process_startup(mChannel, req, req.Size, msg, msg.Size)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  Return mLastError = 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Read(Count As Integer, StreamID As Integer, encoding As TextEncoding = Nil) As String
		  ' Attempts to read up to the specified number of bytes from the specified StreamID.
		  
		  Dim buffer As New MemoryBlock(Count)
		  Do
		    mLastError = libssh2_channel_read_ex(mChannel, StreamID, buffer, buffer.Size)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError < 0 Then Raise New SSHException(Me)
		  If mLastError <> buffer.Size Then buffer.Size = mLastError
		  Return DefineEncoding(buffer, encoding)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function Read(Count As Integer, encoding As TextEncoding = Nil) As String Implements Readable.Read
		  // Part of the Readable interface.
		  Return Me.Read(Count, 0, encoding)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadError() As Boolean
		  // Part of the Readable interface.
		  Return False
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RequestShell()
		  ' Requests that the user's default shell be started at the other end.
		  
		  Call Me.ProcessStart("shell", "")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RequestTerminal(Terminal As String, Width As Integer, Height As Integer, Modes As MemoryBlock, PixelDimensions As Boolean = False)
		  ' Requests a pseudoterminal (PTY). Note that this does not make sense for all channel types
		  ' and may be ignored by the server despite returning success.
		  
		  Dim pw, ph, cw, ch As Integer
		  If PixelDimensions Then
		    pw = Width
		    ph = Height
		  Else
		    cw = Width
		    ch = Height
		  End If
		  Do
		    If Modes <> Nil Then
		      mLastError = libssh2_channel_request_pty_ex(mChannel, Terminal, Terminal.Len, Modes, Modes.Size, cw, ch, pw, ph)
		    Else
		      mLastError = libssh2_channel_request_pty_ex(mChannel, Terminal, Terminal.Len, Nil, 0, cw, ch, pw, ph)
		    End If
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then Raise New SSHException(Me)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetEnvironmentVariable(Name As String, Value As String)
		  ' Set an environment variable in the remote process space. Note that this does not make sense for all
		  ' channel types and may be ignored by the server despite returning success. 
		  
		  Do
		    mLastError = libssh2_channel_setenv_ex(mChannel, Name, Name.Len, Value, Value.Len)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then Raise New SSHException(Me)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub WaitClose()
		  ' Enter a temporary blocking state until the remote host closes the channel.
		  ' Typically sent after calling Close() in order to examine the exit status. 
		  
		  If mChannel = Nil Or Not mOpen Then Return
		  Do
		    mLastError = libssh2_channel_wait_closed(mChannel)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then Raise New SSHException(Me)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub WaitEOF()
		  ' Wait for the server to indicate that no further data will be sent over the channel.
		  
		  If mChannel = Nil Or Not mOpen Then Return
		  
		  Do
		    mLastError = libssh2_channel_wait_eof(mChannel)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Write(text As String) Implements Writeable.Write
		  // Part of the Writeable interface.
		  Me.Write(text, 0)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Write(text As String, StreamID As Integer)
		  ' Writes the text to the specified StreamID.
		  ' Waits for the sent data to be ack'd before sending the rest
		  
		  Dim buffer As MemoryBlock = text
		  Dim size As Integer = buffer.Size
		  If size = 0 Then Return
		  Do
		    mLastError = libssh2_channel_write_ex(mChannel, StreamID, buffer, size)
		    Select Case mLastError
		    Case 0, LIBSSH2_ERROR_EAGAIN ' nothing ack'd yet
		      Continue
		      
		    Case Is > 0 ' the amount ack'd
		      If mLastError = size Then
		        Exit Do ' done
		      Else
		        ' update the size and call libssh2_channel_write_ex() again
		        size = size - mLastError
		        Continue
		      End If
		      
		    Case Is < 0 ' error
		      Exit Do
		    End Select
		  Loop
		  If mLastError < 0 Then Raise New SSHException(Me)
		  mLastError = 0
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function WriteError() As Boolean
		  // Part of the Writeable interface.
		  Return False
		End Function
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event DataAvailable(ExtendedStream As Boolean)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Disconnected()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Error(Reasons As Integer)
	#tag EndHook


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return BytesReadable
			End Get
		#tag EndGetter
		Attributes( deprecated = "SSH.Channel.BytesReadable" ) BytesAvailable As UInt32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return BytesWriteable
			End Get
		#tag EndGetter
		Attributes( deprecated = "SSH.Channel.BytesWriteable" ) BytesLeft As UInt32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns the number of bytes actually available to be read.
			  
			  Dim avail, initial As UInt32
			  If mChannel <> Nil Then Call libssh2_channel_window_read_ex(mChannel, avail,  initial)
			  Return avail
			End Get
		#tag EndGetter
		BytesReadable As UInt32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns the number of bytes which can be written to the channel without blocking.
			  
			  Dim initial As UInt32
			  If mChannel <> Nil Then Return libssh2_channel_window_write_ex(mChannel,  initial)
			End Get
		#tag EndGetter
		BytesWriteable As UInt32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mDataMode
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If mChannel = Nil Then Return
			  
			  Do
			    mLastError = libssh2_channel_handle_extended_data2(mChannel, CType(value, Integer))
			  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
			  
			  If mLastError < 0 Then Raise New SSHException(Me)
			End Set
		#tag EndSetter
		DataMode As SSH.ExtendedDataMode
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns the exit code of the process running on the server. Note that the exit status may
			  ' not be available if the remote end has not yet set its status to closed. Call Close() to
			  ' set the local status to closed, and then WaitClose() to wait for the server to change its
			  ' status too.
			  
			  If mChannel <> Nil Then Return libssh2_channel_get_exit_status(mChannel)
			End Get
		#tag EndGetter
		ExitStatus As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mChannel
			End Get
		#tag EndGetter
		Handle As Ptr
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mOpen
			End Get
		#tag EndGetter
		IsOpen As Boolean
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns the most recent libssh2 error code for this instance of Channel
			  
			  Return mLastError
			End Get
		#tag EndGetter
		LastError As Int32
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mChannel As Ptr
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDataMode As SSH.ExtendedDataMode
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mFreeable As Boolean = True
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mLastError As Int32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mOpen As Boolean
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mSession As SSH.Session
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns the window size as defined when the channel was created.
			  
			  Dim avail, initial As UInt32
			  If mChannel <> Nil Then Call libssh2_channel_window_read_ex(mChannel, avail,  initial)
			  Return initial
			End Get
		#tag EndGetter
		ReadWindow As UInt32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns the number of bytes which the remote end may send without overflowing the window.
			  
			  Dim avail, initial As UInt32
			  If mChannel <> Nil Then Return libssh2_channel_window_read_ex(mChannel, avail,  initial)
			End Get
		#tag EndGetter
		RemoteBytesWriteable As UInt32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mSession
			End Get
		#tag EndGetter
		Session As SSH.Session
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns the window size as defined when the channel was created.
			  
			  Dim initial As UInt32
			  If mChannel <> Nil Then Call libssh2_channel_window_write_ex(mChannel,  initial)
			  Return initial
			End Get
		#tag EndGetter
		WriteWindow As UInt32
	#tag EndComputedProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="ExitStatus"
			Group="Behavior"
			Type="Integer"
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
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="Object"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass

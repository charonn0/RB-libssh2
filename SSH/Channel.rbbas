#tag Class
Protected Class Channel
Implements SSHStream
	#tag Method, Flags = &h0
		Sub Close()
		  // Part of the SSHStream interface.
		  If mChannel = Nil Or Not mOpen Then Return
		  
		  Do
		    mLastError = libssh2_channel_close(mChannel)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  
		  mOpen = False
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Constructor(Session As SSH.Session, ChannelPtr As Ptr)
		  mInit = SSHInit.GetInstance()
		  mChannel = ChannelPtr
		  mSession = Session
		  mOpen = True
		  ChannelParent(Session).RegisterChannel(Me)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function CreateSCP(Session As SSH.Session, Path As String, Mode As Integer, Length As UInt32, ModTime As Integer, AccessTime As Integer) As SSH.Channel
		  Dim c As Ptr
		  Do
		    c = libssh2_scp_send_ex(Session.Handle, Path, Mode, Length, ModTime, AccessTime)
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
		  Dim p As Ptr = libssh2_channel_direct_tcpip_ex(Session.Handle, RemoteHost, RemotePort, LocalHost, LocalPort)
		  If p = Nil Then Raise New SSHException(ERR_INIT_FAILED)
		  Return New Channel(Session, p)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If mChannel <> Nil Then
		    Me.Close
		    mLastError = libssh2_channel_free(mChannel)
		    If mLastError <> 0 Then Raise New SSHException(mLastError)
		  End If
		  ChannelParent(Me.Session).UnregisterChannel(Me)
		  mChannel = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function EOF() As Boolean
		  // Part of the Readable interface.
		  Do
		    mLastError = libssh2_channel_eof(mChannel)
		    Select Case mLastError
		    Case Is >= 0
		      Return mLastError = 1
		      
		    Case LIBSSH2_ERROR_EAGAIN
		      Continue
		      
		    Else
		      Raise New SSHException(mLastError)
		    End Select
		  Loop
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub EOF(Assigns b As Boolean)
		  If Not b Then Return
		  Do
		    mLastError = libssh2_channel_send_eof(mChannel)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Execute(Command As String) As Boolean
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
		  Do
		    mLastError = libssh2_channel_flush_ex(mChannel, StreamID)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Handle() As Ptr
		  Return mChannel
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Open(Session As SSH.Session) As SSH.Channel
		  Return Open(Session, "session", LIBSSH2_CHANNEL_WINDOW_DEFAULT, LIBSSH2_CHANNEL_PACKET_DEFAULT, "")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Open(Session As SSH.Session, Type As String, WindowSize As UInt32, PacketSize As UInt32, Message As String) As SSH.Channel
		  Dim typ As MemoryBlock = Type + Chr(0)
		  Dim msg As MemoryBlock = Message + Chr(0)
		  Do
		    Dim c As Ptr = libssh2_channel_open_ex(Session.Handle, typ, typ.Size - 1, WindowSize, PacketSize, msg, msg.Size - 1)
		    If c = Nil Then
		      Dim e As Integer = Session.GetLastError
		      If e = LIBSSH2_ERROR_EAGAIN Then Continue
		      If e <> 0 Then Raise New SSHException(e)
		    End If
		    Return New Channel(Session, c)
		  Loop
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function OpenSCP(Session As SSH.Session, Path As String) As SSH.Channel
		  Dim c As Ptr
		  Do
		    c = libssh2_scp_recv2(Session.Handle, Path, Nil)
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
		Function Poll() As Boolean
		  If mChannel <> Nil Then Return (libssh2_poll_channel_read(mChannel, 0) <> 0)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ProcessStart(Request As String, Message As String) As Boolean
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
		  Dim buffer As New MemoryBlock(Count)
		  Do
		    mLastError = libssh2_channel_read_ex(mChannel, StreamID, buffer, buffer.Size)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError < 0 Then Raise New SSHException(mLastError)
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
		  Call Me.ProcessStart("shell", "")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RequestTerminal(Terminal As String, Width As Integer, Height As Integer, Modes As MemoryBlock, PixelDimensions As Boolean = False)
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
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Session() As SSH.Session
		  Return mSession
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetEnvironmentVariable(Name As String, Value As String)
		  Do
		    mLastError = libssh2_channel_setenv_ex(mChannel, Name, Name.Len, Value, Value.Len)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub WaitClose()
		  If mChannel = Nil Or Not mOpen Then Return
		  Do
		    mLastError = libssh2_channel_wait_closed(mChannel)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
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
		  Dim buffer As New BinaryStream(text)
		  Do Until buffer.EOF
		    Dim packet As MemoryBlock = buffer.Read(WriteWindow)
		    If packet = Nil Or packet.Size = 0 Then Exit Do
		    Do
		      mLastError = libssh2_channel_write_ex(mChannel, StreamID, packet, packet.Size)
		    Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  Loop
		  If mLastError < 0 Then Raise New SSHException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function WriteError() As Boolean
		  // Part of the Writeable interface.
		  Return False
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Dim avail, initial As UInt32
			  If mChannel <> Nil Then Call libssh2_channel_window_read_ex(mChannel, avail,  initial)
			  Return avail
			End Get
		#tag EndGetter
		BytesAvailable As UInt32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Dim avail, initial As UInt32
			  If mChannel <> Nil Then Return libssh2_channel_window_read_ex(mChannel, avail,  initial)
			End Get
		#tag EndGetter
		BytesLeft As UInt32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mChannel <> Nil Then Return libssh2_channel_get_exit_status(mChannel)
			End Get
		#tag EndGetter
		ExitStatus As Integer
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mChannel As Ptr
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mInit As SSHInit
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastError As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mOpen As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSession As SSH.Session
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
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
			  Dim initial As UInt32
			  If mChannel <> Nil Then Return libssh2_channel_window_write_ex(mChannel,  initial)
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

#tag Class
Protected Class Channel
Implements Readable,Writeable
	#tag Method, Flags = &h0
		Sub Close()
		  mLastError = libssh2_channel_close(mChannel)
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Constructor(ChannelPtr As Ptr)
		  mInit = SSHInit.Init()
		  mChannel = ChannelPtr
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function CreateTunnel(Session As SSH.Session, RemoteHost As String, RemotePort As Integer, LocalHost As String, LocalPort As Integer) As SSH.Channel
		  Dim p As Ptr = libssh2_channel_direct_tcpip_ex(Session.Handle, RemoteHost, RemotePort, LocalHost, LocalPort)
		  If p = Nil Then Raise New RuntimeException
		  Return New Channel(p)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If mChannel <> Nil Then
		    mLastError = libssh2_channel_free(mChannel)
		    If mLastError <> 0 Then Raise New SSHException(mLastError)
		  End If
		  mChannel = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function EOF() As Boolean
		  // Part of the Readable interface.
		  Return libssh2_channel_eof(mChannel) = 1
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Execute(Message As String) As Boolean
		  Dim err As Integer
		  Dim req As MemoryBlock = "exec"
		  Dim msg As MemoryBlock = Message
		  Do
		    err = libssh2_channel_process_startup(mChannel, req, req.Size, msg, msg.Size)
		  Loop Until err <> LIBSSH2_ERROR_EAGAIN
		  Return err = 0
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
		  // Part of the Writeable interface.
		  Do
		    mLastError = libssh2_channel_flush_ex(mChannel, StreamID)
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If mLastError <> 0 Then Raise New SSHException(mLastError)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Open(Session As SSH.Session, Type As String, WindowSize As UInt32, PacketSize As UInt32, Message As String) As SSH.Channel
		  Dim typ As MemoryBlock = Type
		  Dim msg As MemoryBlock = Message
		  Dim c As Ptr = libssh2_channel_open_ex(Session.Handle, typ, typ.Size, WindowSize, PacketSize, msg, msg.Size)
		  If c = Nil Then
		    Dim err As New RuntimeException
		    err.ErrorNumber = Session.LastError
		    Raise err
		  End If
		  Return New Channel(c)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Read(Count As Integer, StreamID As Integer, encoding As TextEncoding = Nil) As String
		  // Part of the Readable interface.
		  Dim buffer As New MemoryBlock(Count)
		  If libssh2_channel_read_ex(mChannel, StreamID, buffer, buffer.Size) <> Count Then Raise New RuntimeException
		  Return buffer
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

	#tag Method, Flags = &h21
		Private Sub Write(text As String) Implements Writeable.Write
		  // Part of the Writeable interface.
		  Me.Write(text, 0)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Write(text As String, StreamID As Integer)
		  // Part of the Writeable interface.
		  Dim buffer As MemoryBlock = text
		  If libssh2_channel_write_ex(mChannel, StreamID, buffer, buffer.Size) <> buffer.Size Then Raise New RuntimeException
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function WriteError() As Boolean
		  // Part of the Writeable interface.
		  Return False
		End Function
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mChannel As Ptr
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mInit As SSHInit
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastError As Integer
	#tag EndProperty


End Class
#tag EndClass

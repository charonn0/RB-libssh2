#tag Class
Protected Class SCPStream
Inherits SSH.Channel
	#tag Method, Flags = &h1000
		Sub Constructor(Session As SSH.Session, Path As String)
		  ' Creates a new channel over the session for downloading over SCP. Perform the download by
		  ' reading from this object until EOF() returns True. Session is an existing SSH session.
		  ' Path is the full remote path of the file being downloaded.
		  ' 
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.SCPStream.Constructor
		  
		  mSession = Session
		  If Not mSession.IsAuthenticated Then
		    mLastError = ERR_NOT_AUTHENTICATED
		    Raise New SSHException(Me)
		  End If
		  
		  Dim scp As Ptr
		  Dim stat As New MemoryBlock(64)
		  
		  Do Until scp <> Nil
		    scp = libssh2_scp_recv2(mSession.Handle, Path, stat)
		    mLastError = mSession.GetLastError()
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If scp = Nil Then Raise New SSHException(Me)
		  
		  mLength = stat.UInt64Value(24)
		  mPosition = 0
		  If stat.Int16Value(6) <> 0 Then
		    mMode = New Permissions(stat.Int16Value(6))
		  End If
		  
		  // Calling the overridden superclass constructor.
		  // Constructor(SSH.Session, Ptr) -- from SSH.Channel
		  Super.Constructor(mSession, scp)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1000
		Sub Constructor(Session As SSH.Session, Path As String, Mode As Integer, Length As UInt64, ModTime As Integer, AccessTime As Integer)
		  ' Creates a new channel over the session for uploading over SCP. Perform the upload by writing to
		  ' this object. Make sure to call Channel.Close() when finished.
		  ' Session is an existing SSH session. Path is the full remote path to save the upload to.
		  ' Mode is the Unix-style permissions of the remote file. Length is the total size in bytes
		  ' of the file being uploaded. ModTime and AccessTime may be zero, in which case the current
		  ' date and time are used.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.SCPStream.Constructor
		  
		  mSession = Session
		  Dim scp As Ptr
		  Do Until scp <> Nil
		    scp = libssh2_scp_send64(mSession.Handle, Path, Mode, Length, ModTime, AccessTime)
		    mLastError = mSession.GetLastError()
		  Loop Until mLastError <> LIBSSH2_ERROR_EAGAIN
		  If scp = Nil Then Raise New SSHException(Me)
		  
		  mLength = Length
		  mPosition = 0
		  mMode = New Permissions(Mode)
		  
		  // Calling the overridden superclass constructor.
		  // Constructor(SSH.Session, Ptr) -- from SSH.Channel
		  Super.Constructor(mSession, scp)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function EOF() As Boolean Implements Readable.EOF
		  ' Returns True if the end-of-file has been signaled.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.SCPStream.EOF
		  
		  Return Super.EOF() Or Position >= Length
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GetLength() As UInt64
		  // Part of the SSHStream interface.
		  // Implements SSHStream.Length() As UInt64
		  // Overrides Channel.GetLength() As UInt64
		  Return Me.Length
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GetPosition() As UInt64
		  // Part of the SSHStream interface.
		  // Implements SSHStream.Position() As UInt64
		  // Overrides Channel.GetPosition() As UInt64
		  Return Me.Position
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Read(Count As Integer, StreamID As Integer, encoding As TextEncoding = Nil) As String
		  ' Returns a String containing the data that was read. If the number of bytes read exceeds the
		  ' purported Length of the file then the extraneous bytes will be truncated.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.SCPStream.Read
		  
		  Dim s As String = Me.ReadBuffer(Count, StreamID)
		  Return DefineEncoding(s, encoding)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Read(Count As Integer, encoding As TextEncoding = Nil) As String
		  ' Returns a String containing the data that was read. If the number of bytes read exceeds the
		  ' purported Length of the file then the extraneous bytes will be truncated.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.SCPStream.Read
		  
		  Dim s As String = Me.ReadBuffer(Count, 0)
		  Return DefineEncoding(s, encoding)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadBuffer(Count As Integer, StreamID As Integer) As MemoryBlock
		  ' Returns a MemoryBlock containing the data that was read. If the number of bytes read exceeds the
		  ' purported Length of the file then the extraneous bytes will be truncated.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.SCPStream.ReadBuffer
		  
		  Dim s As MemoryBlock = Super.ReadBuffer(Count, StreamID)
		  If mPosition + s.Size > mLength Then
		    ' this is a kludge to detect the extra null byte that we always
		    ' seem to get over SCP.
		    s.Size = mLength - mPosition
		  End If
		  mPosition = mPosition + s.Size
		  Return s
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Write(text As String)
		  ' Write (upload) to the stream. If writing the Text would cause the Position to exceed
		  ' the pre-defined Length then an exception will be raised.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.SCPStream.Write
		  
		  Me.WriteBuffer(text, 0)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Write(text As String, StreamID As Integer)
		  ' Write (upload) to the stream. If writing the Text would cause the Position to exceed
		  ' the pre-defined Length then an exception will be raised.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.SCPStream.Write
		  
		  Me.WriteBuffer(text, StreamID)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub WriteBuffer(Data As MemoryBlock, StreamID As Integer)
		  ' Write (upload) to the stream. If writing the Data would cause the Position to exceed
		  ' the pre-defined Length then an exception will be raised.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.SCPStream.WriteBuffer
		  
		  If mPosition + Data.Size > mLength Then Raise New SSHException(ERR_SCP_LENGTH_EXCEEDED)
		  Super.WriteBuffer(Data, StreamID)
		  mPosition = mPosition + Data.Size
		End Sub
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns the length of the file being transferred. This value is set in the Constructor
			  ' and cannot be changed thereafter. When uploading, this value is provided by you; when 
			  ' downloading, this value is provided by the server.
			  ' Reading beyond the Length will return an empty string; writing beyond the Length will
			  ' raise an exception.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.SCPStream.Length
			  
			  return mLength
			End Get
		#tag EndGetter
		Length As UInt64
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mLength As UInt64
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mMode As Permissions
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Gets the Unix-style permissions of the file.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.SCPStream.Mode
			  
			  If mMode = Nil Then mMode = New Permissions(&o0644)
			  Return mMode
			End Get
		#tag EndGetter
		Mode As Permissions
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mPosition As UInt64
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns the current position within the stream. This value is updated when
			  ' you read from or write to the stream.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.SCPStream.Position
			  
			  return mPosition
			End Get
		#tag EndGetter
		Position As UInt64
	#tag EndComputedProperty


End Class
#tag EndClass

#tag Class
Protected Class SCPStream
Inherits SSH.Channel
	#tag Method, Flags = &h1000
		Sub Constructor(Session As SSH.Session, Path As String)
		  ' Creates a new channel over the session for downloading over SCP. Perform the download by
		  ' reading from this object until EOF() returns True. Session is an existing SSH session.
		  ' Path is the full remote path of the file being downloaded.
		  
		  mSession = Session
		  If Not mSession.IsAuthenticated Then
		    mLastError = ERR_NOT_AUTHENTICATED
		    Raise New SSHException(Me)
		  End If
		  
		  Dim c As Ptr
		  Dim stat As New MemoryBlock(64)
		  Do
		    c = libssh2_scp_recv2(mSession.Handle, Path, stat)
		    If c = Nil Then
		      If mSession.GetLastError = LIBSSH2_ERROR_EAGAIN Then Continue
		      Raise New SSHException(Session)
		    End If
		  Loop Until c <> Nil
		  
		  mLength = stat.UInt64Value(24)
		  mPosition = 0
		  If stat.Int16Value(6) <> 0 Then
		    mMode = New Permissions(stat.Int16Value(6))
		  End If
		  
		  // Calling the overridden superclass constructor.
		  // Constructor(SSH.Session, Ptr) -- from SSH.Channel
		  Super.Constructor(mSession, c)
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
		  
		  mSession = Session
		  Dim c As Ptr
		  Do
		    c = libssh2_scp_send64(mSession.Handle, Path, Mode, Length, ModTime, AccessTime)
		    If c = Nil Then
		      mLastError = mSession.GetLastError
		      If mLastError = LIBSSH2_ERROR_EAGAIN Then Continue
		      Raise New SSHException(Me)
		    End If
		  Loop Until c <> Nil
		  
		  mLength = Length
		  mPosition = 0
		  mMode = New Permissions(Mode)
		  
		  // Calling the overridden superclass constructor.
		  // Constructor(SSH.Session, Ptr) -- from SSH.Channel
		  Super.Constructor(mSession, c)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function EOF() As Boolean Implements Readable.EOF
		  Return Super.EOF() Or Position >= Length
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Read(Count As Integer, encoding As TextEncoding = Nil) As String
		  Dim s As MemoryBlock = Super.Read(Count, 0, encoding)
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
		  If mPosition + text.LenB > mLength Then Raise New SSHException(ERR_SCP_LENGTH_EXCEEDED)
		  Super.Write(text, 0)
		  mPosition = mPosition + text.LenB
		End Sub
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
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
			  return mPosition
			End Get
		#tag EndGetter
		Position As UInt64
	#tag EndComputedProperty


End Class
#tag EndClass

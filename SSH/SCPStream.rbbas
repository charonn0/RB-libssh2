#tag Class
Protected Class SCPStream
Inherits SSH.Channel
	#tag Method, Flags = &h1000
		Sub Constructor(Session As SSH.Session, Path As String)
		  ' Creates a new channel over the session for downloading over SCP. Perform the download by
		  ' reading from this object until Channel.EOF returns True. Session is an existing SSH session.
		  ' Path is the full remote path of the file being downloaded.
		  
		  If Not Session.IsAuthenticated Then
		    mLastError = ERR_NOT_AUTHENTICATED
		    Raise New SSHException(Me)
		  End If
		  
		  Dim c As Ptr
		  Dim stat As New MemoryBlock(64)
		  Do
		    c = libssh2_scp_recv2(Session.Handle, Path, stat)
		    If c = Nil Then
		      If Session.GetLastError = LIBSSH2_ERROR_EAGAIN Then Continue
		      Raise New SSHException(Session)
		    End If
		  Loop Until c <> Nil
		  
		  mLength = stat.UInt64Value(24)
		  mPosition = 0
		  
		  // Calling the overridden superclass constructor.
		  // Constructor(SSH.Session, Ptr) -- from SSH.Channel
		  Super.Constructor(Session, c)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1000
		Sub Constructor(Session As SSH.Session, Path As String, Mode As Integer, Length As UInt32, ModTime As Integer, AccessTime As Integer)
		  ' Creates a new channel over the session for uploading over SCP. Perform the upload by writing to
		  ' this object. Make sure to call Channel.Close() when finished.
		  ' Session is an existing SSH session. Path is the full remote path to save the upload to.
		  ' Mode is the Unix-style permissions of the remote file. Length is the total size in bytes
		  ' of the file being uploaded. ModTime and AccessTime may be zero, in which case the current
		  ' date and time are used.
		  
		  Dim c As Ptr
		  Do
		    c = libssh2_scp_send_ex(Session.Handle, Path, Mode, Length, ModTime, AccessTime)
		    If c = Nil Then
		      mLastError = Session.GetLastError
		      If mLastError = LIBSSH2_ERROR_EAGAIN Then Continue
		      Raise New SSHException(Me)
		    End If
		  Loop Until c <> Nil
		  
		  mLength = Length
		  mPosition = 0
		  
		  // Calling the overridden superclass constructor.
		  // Constructor(SSH.Session, Ptr) -- from SSH.Channel
		  Super.Constructor(Session, c)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function EOF() As Boolean
		  Return Super.EOF() Or Position >= Length
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Read(Count As Integer, StreamID As Integer, encoding As TextEncoding = Nil) As String
		  Dim s As MemoryBlock = Super.Read(Count, StreamID, encoding)
		  mPosition = mPosition + s.Size
		  Return s
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Write(text As String, StreamID As Integer)
		  Super.Write(text, StreamID)
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

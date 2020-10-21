#tag Class
Protected Class SCPStream
Inherits SSH.Channel
	#tag Method, Flags = &h1000
		Sub Constructor(Session As SSH.Session, Path As String)
		  ' Creates a new channel over the session for downloading over SCP. Perform the download by
		  ' reading from this object until Channel.EOF returns True. Session is an existing SSH session.
		  ' Path is the full remote path of the file being downloaded.
		  
		  Dim c As Ptr
		  Do
		    c = libssh2_scp_recv2(Session.Handle, Path, Nil)
		    If c = Nil Then
		      If Session.GetLastError = LIBSSH2_ERROR_EAGAIN Then Continue
		      Raise New SSHException(Session)
		    End If
		  Loop Until c <> Nil
		  
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
		      Dim e As Integer = Session.GetLastError
		      If e = LIBSSH2_ERROR_EAGAIN Then Continue
		      Raise New SSHException(e)
		    End If
		  Loop Until c <> Nil
		  
		  // Calling the overridden superclass constructor.
		  // Constructor(SSH.Session, Ptr) -- from SSH.Channel
		  Super.Constructor(Session, c)
		End Sub
	#tag EndMethod


End Class
#tag EndClass

#tag Class
Protected Class SSHException
Inherits RuntimeException
	#tag Method, Flags = &h1000
		Sub Constructor(ErrorCode As Integer)
		  Me.ErrorNumber = ErrorCode
		  Me.Message = ErrorName(ErrorCode)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1000
		Sub Constructor(Agent As SSH.Agent)
		  Me.Constructor(Agent.LastError)
		  Me.Message = Me.Message + EndOfLine + Agent.Session.LastErrorMsg
		  Me.Message = Me.Message.Trim
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1000
		Sub Constructor(Stream As SSH.Channel)
		  Me.Constructor(Stream.LastError)
		  Me.Message = Me.Message + EndOfLine + Stream.Session.LastErrorMsg
		  Me.Message = Me.Message.Trim
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1000
		Sub Constructor(Known As SSH.KnownHosts)
		  Me.Constructor(Known.LastError)
		  Me.Message = Me.Message + EndOfLine + Known.Session.LastErrorMsg
		  Me.Message = Me.Message.Trim
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1000
		Sub Constructor(Session As SSH.Session)
		  Me.Constructor(Session.LastError)
		  Me.Message = Me.Message + EndOfLine + Session.LastErrorMsg
		  Me.Message = Me.Message.Trim
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1000
		Sub Constructor(Stream As SSH.SFTPDirectory)
		  Me.Constructor(Stream.LastError)
		  Me.Message = Me.Message + EndOfLine + SFTPErrorName(Stream.Session.LastStatusCode) + EndOfLine + Stream.Session.Session.LastErrorMsg
		  Me.Message = Me.Message.Trim
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1000
		Sub Constructor(Session As SSH.SFTPSession)
		  Me.Constructor(Session.LastError)
		  Me.Message = Me.Message + EndOfLine + SFTPErrorName(Session.LastStatusCode) + EndOfLine + Session.Session.LastErrorMsg
		  Me.Message = Me.Message.Trim
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1000
		Sub Constructor(Stream As SSH.SFTPStream)
		  Me.Constructor(Stream.LastError)
		  Me.Message = Me.Message + EndOfLine + SFTPErrorName(Stream.Session.LastStatusCode) + EndOfLine + Stream.Session.Session.LastErrorMsg
		  Me.Message = Me.Message.Trim
		End Sub
	#tag EndMethod


End Class
#tag EndClass

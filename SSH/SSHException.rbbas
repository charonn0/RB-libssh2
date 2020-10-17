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
		Sub Constructor(Session As SSH.Session)
		  Me.Constructor(Session.LastError)
		  Dim s As String = Session.LastErrorMsg
		  If s.Trim <> "" Then Me.Message = s
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1000
		Sub Constructor(Session As SSH.SFTPSession)
		  Me.Constructor(Session.LastError)
		  Dim s As String = Session.Session.LastErrorMsg
		  If s.Trim <> "" Then Me.Message = s
		End Sub
	#tag EndMethod


End Class
#tag EndClass

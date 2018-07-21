#tag Class
Protected Class App
Inherits Application
	#tag Event
		Sub Open()
		  Dim privf As FolderItem = SpecialFolder.Desktop.Child("openssh.ppk")
		  Dim pubf As FolderItem = SpecialFolder.Desktop.Child("Incoming").Child("andrewkey")
		  Dim hosts As FolderItem = SpecialFolder.Desktop.Child("known_hosts")
		  Dim sess As SSH.Session = SSH.Connect("192.168.1.4", 22, "andrewkey", pubf, privf, "seekrit", hosts, True)
		  Dim s As String = sess.GetRemoteBanner
		  If Not sess.IsConnected Or Not sess.IsAuthenticated Then Raise New SSH.SSHException(sess.LastError)
		  Dim sh As SSH.Channel = SSH.OpenChannel(sess)
		  Call sh.Execute("uptime")
		  Dim h As String
		  Do Until sh.EOF
		    s = s + sh.Read(64, 0)
		  Loop
		  sh.Close
		  Break
		  'Dim d As Dictionary = ParseURL("scp://andrew:seekrit@192.168.1.4:22/Curl_lib1.7z")
		  'Break
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h21
		Private Sub ConnectedHandler(Sender As SSH.Session, Banner As String)
		  #pragma Unused Sender
		  If Banner <> "" Then MsgBox(Banner)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DebugHandler(Sender As SSH.Session, AlwaysDisplay As Boolean, Message As String, Language As String)
		  Break
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DisconnectedHandler(Sender As SSH.Session, Reason As SSH.DisconnectReason, Message As String, Language As String)
		  Break
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SocketErrorHandler(Sender As SSH.Session, ErrorCode As Integer)
		  Break
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function URLEncode(Data As MemoryBlock) As String
		  Dim bs As New BinaryStream(Data)
		  Dim encoded As New MemoryBlock(0)
		  Dim enbs As New BinaryStream(encoded)
		  
		  Do Until bs.EOF
		    Dim char As Byte = bs.ReadByte
		    Select Case char
		    Case &h30 To &h39, &h41 To &h5A, &h61 To &h7A, &h2D, &h2E, &h5F
		      enbs.WriteByte(char)
		    Else
		      enbs.Write("%" + Right("0" + Hex(char), 2))
		    End Select
		  Loop
		  enbs.Close
		  Return DefineEncoding(encoded, Encodings.ASCII)
		End Function
	#tag EndMethod


	#tag Constant, Name = kEditClear, Type = String, Dynamic = False, Default = \"&Delete", Scope = Public
		#Tag Instance, Platform = Windows, Language = Default, Definition  = \"&Delete"
		#Tag Instance, Platform = Linux, Language = Default, Definition  = \"&Delete"
	#tag EndConstant

	#tag Constant, Name = kFileQuit, Type = String, Dynamic = False, Default = \"&Quit", Scope = Public
		#Tag Instance, Platform = Windows, Language = Default, Definition  = \"E&xit"
	#tag EndConstant

	#tag Constant, Name = kFileQuitShortcut, Type = String, Dynamic = False, Default = \"", Scope = Public
		#Tag Instance, Platform = Mac OS, Language = Default, Definition  = \"Cmd+Q"
		#Tag Instance, Platform = Linux, Language = Default, Definition  = \"Ctrl+Q"
	#tag EndConstant


	#tag ViewBehavior
	#tag EndViewBehavior
End Class
#tag EndClass

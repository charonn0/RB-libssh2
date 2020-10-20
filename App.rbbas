#tag Class
Protected Class App
Inherits Application
	#tag Event
		Sub Open()
		  Declare Function SetDllDirectoryW Lib "Kernel32" (PathName As WString) As Boolean
		  #If Target32Bit Then
		    #If RBVersion > 2019 Then
		      Call SetDllDirectoryW(App.ExecutableFile.Parent.Parent.Child("_x86dlls").NativePath)
		    #else
		      Call SetDllDirectoryW(App.ExecutableFile.Parent.Child("_x86dlls").AbsolutePath)
		    #endif
		  #else
		    Call SetDllDirectoryW(App.ExecutableFile.Parent.Parent.Child("_x64dlls").NativePath)
		  #endif
		  
		  Dim session As New SSH.Session()
		  If Not session.Connect("ftp.boredomsoft.org", 22) Then MsgBox("Unable to connect!")
		  
		  Dim known As New SSH.KnownHosts(session)
		  Dim f As FolderItem = SpecialFolder.UserHome.Child(".ssh")
		  If f.Exists Then f = f.Child("known_hosts")
		  If f.Exists And known.Load(f) > 0 Then
		    If Not known.Lookup(session) Then
		      If MsgBox("Add this host's fingerprint?", 4 + 48, "Fingerprint not known!") <> 6 Then Return
		      known.AddHost(session)
		      known.Save(f)
		    End If
		  End If
		  
		  If Not session.SendCredentials("andlam9", "7C61BDC483EDB1B9DCA0262FEC094CCa") Then
		    MsgBox("Invalid user/pass!")
		    Return
		  End If
		  
		  Dim sftp As New SSH.SFTPSession(session)
		  Dim ch As SSH.SFTPStream = sftp.Get("/public_html/Files/bin/VTHashSetup.exe")
		  Dim bs As BinaryStream = BinaryStream.Create(SpecialFolder.Desktop.Child("VTHashSetup.exe"))
		  Do Until ch.EOF
		    bs.Write(ch.Read(1024))
		  Loop
		  bs.Close
		  ch.Close
		  Break
		End Sub
	#tag EndEvent


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

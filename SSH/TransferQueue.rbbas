#tag Class
Protected Class TransferQueue
	#tag Method, Flags = &h0
		Sub AddDownload(Source As SSH.SSHStream, Destination As Writeable)
		  System.DebugLog(CurrentMethodName)
		  If mStreams.HasKey(Source) Then Raise New RuntimeException
		  mStreams.Value(Source) = DIRECTION_DOWN:Destination
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AddUpload(Destination As SSH.SSHStream, Source As Readable)
		  If mStreams.HasKey(Destination) Then Raise New RuntimeException
		  mStreams.Value(Destination) = DIRECTION_UP:Source
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor()
		  mStreams = New Dictionary
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Count() As Integer
		  Return mStreams.Count
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetDownStream(Stream As SSH.SSHStream) As Writeable
		  Dim vl As Pair = mStreams.Value(Stream)
		  If vl.Left = DIRECTION_UP Then ' writer is the ssh channel
		    Return Stream
		  Else ' writer is a local stream
		    Return vl.Right
		  End If
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetUpStream(Stream As SSH.SSHStream) As Readable
		  Dim vl As Pair = mStreams.Value(Stream)
		  If vl.Left = DIRECTION_UP Then ' reader is a local stream
		    Return vl.Right
		  Else ' writer is the ssh channel
		    Return Stream
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function HasTransfer(Stream As SSH.SSHStream) As Boolean
		  Return mStreams <> Nil And mStreams.HasKey(Stream)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsDownload(Stream As SSH.SSHStream) As Boolean
		  Return (GetUpStream(Stream) Is Stream)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsUpload(Stream As SSH.SSHStream) As Boolean
		  Return (GetDownStream(Stream) Is Stream)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Perform()
		  If mPerformTimer = Nil Then
		    mPerformTimer = New Timer
		    mPerformTimer.Period = 100
		    AddHandler mPerformTimer.Action, WeakAddressOf PerformTimerHandler
		  End If
		  mPerformTimer.Mode = Timer.ModeMultiple
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function PerformOnce() As Boolean
		  System.DebugLog(CurrentMethodName + "(" + Str(Count) + ")")
		  Dim done() As SSHStream
		  For Each chan As Object In mStreams.Keys
		    Dim sh As SSHStream = SSHStream(chan)
		    Dim reader As Readable = GetUpStream(sh)
		    Dim writer As Writeable = GetDownStream(sh)
		    writer.Write(reader.Read(1024 * 32))
		    If reader.EOF Then done.Append(sh)
		  Next
		  
		  If UBound(done) > -1 Then System.DebugLog(CurrentMethodName + "(disposed of " + Str(UBound(done) + 1) + ")")
		  For i As Integer = 0 To UBound(done)
		    Dim sh As SSHStream = done(i)
		    RaiseEvent TransferComplete(sh)
		    RemoveTransfer(sh)
		  Next
		  
		  Return mStreams.Count > 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub PerformTimerHandler(Sender As Timer)
		  If Not PerformOnce() Then Sender.Mode = Timer.ModeOff
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RemoveTransfer(Source As SSH.SSHStream)
		  If mStreams.HasKey(Source) Then mStreams.Remove(Source)
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event TransferComplete(Stream As SSH.SSHStream)
	#tag EndHook


	#tag Property, Flags = &h21
		Private mPerformTimer As Timer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mStreams As Dictionary
	#tag EndProperty


	#tag Constant, Name = DIRECTION_DOWN, Type = Double, Dynamic = False, Default = \"1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = DIRECTION_UP, Type = Double, Dynamic = False, Default = \"0", Scope = Private
	#tag EndConstant


	#tag ViewBehavior
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

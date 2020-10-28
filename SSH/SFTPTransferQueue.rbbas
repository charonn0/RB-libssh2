#tag Class
Protected Class SFTPTransferQueue
	#tag Method, Flags = &h0
		Sub AddDownload(Source As SSH.SFTPStream, Destination As Writeable)
		  If Count >= MaxCount Then Raise New SSHException(ERR_TOO_MANY_TRANSFERS)
		  If mStreams.HasKey(Source) Then Raise New RuntimeException
		  mStreams.Value(Source) = DIRECTION_DOWN:Destination
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AddUpload(Destination As SSH.SFTPStream, Source As Readable)
		  If Count >= MaxCount Then Raise New SSHException(ERR_TOO_MANY_TRANSFERS)
		  Do Until mLock.TrySignal()
		    App.YieldToNextThread
		  Loop
		  Try
		    mStreams.Value(Destination) = DIRECTION_UP:Source
		  Finally
		    mLock.Release()
		  End Try
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor()
		  mLock = New Semaphore
		  mStreams = New Dictionary
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Count() As Integer
		  Return mStreams.Count
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetDownStream(Stream As SSH.SFTPStream) As Writeable
		  Dim vl As Pair = mStreams.Value(Stream)
		  If vl.Left = DIRECTION_UP Then ' writer is the ssh channel
		    Return Stream
		  Else ' writer is a local stream
		    Return vl.Right
		  End If
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetUpStream(Stream As SSH.SFTPStream) As Readable
		  Dim vl As Pair = mStreams.Value(Stream)
		  If vl.Left = DIRECTION_UP Then ' reader is a local stream
		    Return vl.Right
		  Else ' writer is the ssh channel
		    Return Stream
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function HasTransfer(Stream As SSH.SFTPStream) As Boolean
		  Return mStreams <> Nil And mStreams.HasKey(Stream)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsDownload(Stream As SSH.SFTPStream) As Boolean
		  Return (GetUpStream(Stream) Is Stream)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsUpload(Stream As SSH.SFTPStream) As Boolean
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
		  Dim done() As SFTPStream
		  Do Until mLock.TrySignal()
		    App.YieldToNextThread
		  Loop
		  Try
		    For Each chan As Object In mStreams.Keys
		      Dim stream As SFTPStream = SFTPStream(chan)
		      Dim reader As Readable = GetUpStream(stream)
		      Dim writer As Writeable = GetDownStream(stream)
		      Try
		        Dim total, now As UInt64
		        If IsDownload(stream) Then
		          total = stream.Length
		          now = stream.Position
		        ElseIf reader IsA BinaryStream Then
		          total = total + BinaryStream(reader).Length
		          now = now + BinaryStream(reader).Position
		        End If
		        If reader.EOF Or RaiseEvent Progress(Stream, total, now) Then
		          done.Append(stream)
		          Continue
		        End If
		        
		        writer.Write(reader.Read(1024 * 32))
		        
		      Catch
		        done.Append(stream)
		      End Try
		    Next
		    
		    For i As Integer = 0 To UBound(done)
		      Dim stream As SFTPStream = done(i)
		      RaiseEvent TransferComplete(stream)
		      RemoveTransfer(stream)
		    Next
		  Finally
		    mLock.Release()
		  End Try
		  
		  Return mStreams.Count > 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub PerformTimerHandler(Sender As Timer)
		  If Not PerformOnce() Then Sender.Mode = Timer.ModeOff
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RemoveTransfer(Source As SSH.SFTPStream)
		  Do Until mLock.TrySignal()
		    App.YieldToNextThread
		  Loop
		  Try
		    If mStreams.HasKey(Source) Then mStreams.Remove(Source)
		  Finally
		    mLock.Release()
		  End Try
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event Progress(Transfer As SSH.SFTPStream, Total As UInt64, Now As UInt64) As Boolean
	#tag EndHook

	#tag Hook, Flags = &h0
		Event TransferComplete(Stream As SSH.SFTPStream)
	#tag EndHook


	#tag Property, Flags = &h0
		#tag Note
			AddUpload and AddDownload will raise an exception if this limit would be exceeded.
		#tag EndNote
		MaxCount As Integer = 256
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLock As Semaphore
	#tag EndProperty

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

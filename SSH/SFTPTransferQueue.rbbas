#tag Class
Protected Class SFTPTransferQueue
	#tag Method, Flags = &h0
		Sub AddDownload(Source As SSH.SFTPStream, Destination As BinaryStream)
		  ' Adds a new download transfer to the queue.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.SFTPTransferQueue.AddDownload
		  
		  If Count >= MaxCount Then Raise New SSHException(ERR_TOO_MANY_TRANSFERS)
		  If mStreams.HasKey(Source) Then Raise New RuntimeException
		  Do Until mLock.TrySignal()
		    #If RBVersion > 2020 Then
		      Thread.YieldToNext()
		    #Else
		      App.YieldToNextThread()
		    #EndIf
		  Loop
		  Try
		    mStreams.Value(Source) = DIRECTION_DOWN:Destination
		  Finally
		    mLock.Release()
		  End Try
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AddUpload(Destination As SSH.SFTPStream, Source As BinaryStream)
		  ' Adds a new upload transfer to the queue.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.SFTPTransferQueue.AddDownload
		  
		  If Count >= MaxCount Then Raise New SSHException(ERR_TOO_MANY_TRANSFERS)
		  If mStreams.HasKey(Destination) Then Raise New RuntimeException
		  Do Until mLock.TrySignal()
		    #If RBVersion > 2020 Then
		      Thread.YieldToNext()
		    #Else
		      App.YieldToNextThread()
		    #EndIf
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
		  ' Creates a new empty queue.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.SFTPTransferQueue.Constructor
		  
		  mLock = New Semaphore
		  mStreams = New Dictionary
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Count() As Integer
		  ' Returns the number of transfers in the queue.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.SFTPTransferQueue.Count
		  
		  Return mStreams.Count
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GetDownStream(Stream As SSH.SFTPStream) As Writeable
		  Dim vl As Pair = mStreams.Value(Stream)
		  If vl.Left = DIRECTION_UP Then ' writer is the ssh channel
		    Return Stream
		  Else ' writer is a local stream
		    Return vl.Right
		  End If
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GetFileStream(Stream As SSH.SFTPStream) As BinaryStream
		  If IsDownload(Stream) Then
		    Return BinaryStream(GetDownStream(Stream))
		  Else
		    Return BinaryStream(GetUpStream(Stream))
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GetNetworkStream(Stream As BinaryStream) As SSH.SFTPStream
		  If mStreams = Nil Then Return Nil
		  For Each netstream As SFTPStream In mStreams.Keys
		    If GetUpStream(netstream) Is Stream Then Return SFTPStream(GetDownStream(netstream))
		    If GetDownStream(netstream) Is Stream Then Return SFTPStream(GetUpStream(netstream))
		  Next
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GetUpStream(Stream As SSH.SFTPStream) As Readable
		  Dim vl As Pair = mStreams.Value(Stream)
		  If vl.Left = DIRECTION_UP Then ' reader is a local stream
		    Return vl.Right
		  Else ' writer is the ssh channel
		    Return Stream
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function HasTransfer(Stream As BinaryStream) As Boolean
		  ' Returns True if the Stream is in the queue.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.SFTPTransferQueue.HasTransfer
		  
		  If mStreams = Nil Then Return False
		  For Each netstream As SFTPStream In mStreams.Keys
		    If GetUpStream(netstream) Is Stream Or GetDownStream(netstream) Is Stream Then Return True
		  Next
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function HasTransfer(Stream As SSH.SFTPStream) As Boolean
		  ' Returns True if the Stream is in the queue.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.SFTPTransferQueue.HasTransfer
		  
		  Return mStreams <> Nil And mStreams.HasKey(Stream)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsDownload(Stream As BinaryStream) As Boolean
		  ' Returns True if the Stream represents a download.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.SFTPTransferQueue.IsDownload
		  
		  If mStreams = Nil Then Return False
		  For Each netstream As SFTPStream In mStreams.Keys
		    Return GetDownStream(netstream) Is Stream
		  Next
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsDownload(Stream As SSH.SFTPStream) As Boolean
		  ' Returns True if the Stream represents a download.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.SFTPTransferQueue.IsDownload
		  
		  Return (GetUpStream(Stream) Is Stream)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsUpload(Stream As BinaryStream) As Boolean
		  ' Returns True if the Stream represents an upload.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.SFTPTransferQueue.IsUpload
		  
		  If mStreams = Nil Then Return False
		  For Each netstream As SFTPStream In mStreams.Keys
		    Return GetUpStream(netstream) Is Stream
		  Next
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsUpload(Stream As SSH.SFTPStream) As Boolean
		  ' Returns True if the Stream represents an upload.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.SFTPTransferQueue.IsUpload
		  
		  Return (GetDownStream(Stream) Is Stream)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Perform()
		  ' Triggers a Timer that calls PerformOnce() repeatedly until all transfers have completed.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.SFTPTransferQueue.Perform
		  
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
		  ' Returns True if there are still transfers in the queue. Call PerformOnce() again until
		  ' it returns False.
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.SFTPTransferQueue.PerformOnce
		  
		  Do Until mLock.TrySignal()
		    #If RBVersion > 2020 Then
		      Thread.YieldToNext()
		    #Else
		      App.YieldToNextThread()
		    #EndIf
		  Loop
		  
		  Dim done() As SFTPStream
		  
		  Try
		    For Each netstream As SFTPStream In mStreams.Keys
		      Dim reader As Readable = GetUpStream(netstream)
		      Dim writer As Writeable = GetDownStream(netstream)
		      Try
		        If reader.EOF Or RaiseEvent Progress(netstream, GetFileStream(netstream)) Then
		          done.Append(netstream)
		          Continue
		        End If
		        
		        writer.Write(reader.Read(PacketCount * SFTP_MAX_PACKET_SIZE))
		        If reader.EOF Then done.Append(netstream)
		        
		      Catch
		        done.Append(netstream)
		      End Try
		    Next
		    
		    For i As Integer = 0 To UBound(done)
		      Dim netstream As SFTPStream = done(i)
		      Dim filestream As BinaryStream = GetFileStream(netstream)
		      RaiseEvent TransferComplete(netstream, filestream)
		      mStreams.Remove(netstream)
		      If AutoClose Then
		        filestream.Close
		        netstream.Close
		      End If
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
		Sub RemoveTransfer(Stream As BinaryStream)
		  ' Removes the transfer from the queue.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.SFTPTransferQueue.RemoveTransfer
		  
		  RemoveTransfer(GetNetworkStream(Stream))
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RemoveTransfer(Stream As SSH.SFTPStream)
		  ' Removes the transfer from the queue.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libssh2/wiki/SSH.SFTPTransferQueue.RemoveTransfer
		  
		  Do Until mLock.TrySignal()
		    #If RBVersion > 2020 Then
		      Thread.YieldToNext()
		    #Else
		      App.YieldToNextThread()
		    #EndIf
		  Loop
		  Try
		    If mStreams.HasKey(Stream) Then mStreams.Remove(Stream)
		  Finally
		    mLock.Release()
		  End Try
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event Progress(NetworkStream As SSH.SFTPStream, FileStream As BinaryStream) As Boolean
	#tag EndHook

	#tag Hook, Flags = &h0
		Event TransferComplete(NetworkStream As SSH.SFTPStream, FileStream As BinaryStream)
	#tag EndHook


	#tag Property, Flags = &h0
		#tag Note
			If True (the default) then both the remote SFTPStream and the local BinaryStream will have their
			Close() methods called automatically. If False then you must be sure to close the streams yourself
			at some point, typically in the TransferComplete() event.
			
			See:
			https://github.com/charonn0/RB-libssh2/wiki/SSH.SFTPTransferQueue.AutoClose
		#tag EndNote
		AutoClose As Boolean = True
	#tag EndProperty

	#tag Property, Flags = &h0
		#tag Note
			AddUpload and AddDownload will raise an exception if this limit would be exceeded.
			
			See:
			https://github.com/charonn0/RB-libssh2/wiki/SSH.SFTPTransferQueue.MaxCount
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

	#tag Property, Flags = &h0
		#tag Note
			The number of SFTP packets to exchange per transfer in a call to PerformOnce()
			Packets are SFTP_MAX_PACKET_SIZE(32KB) bytes long.
			
			See:
			https://github.com/charonn0/RB-libssh2/wiki/SSH.SFTPTransferQueue.PacketCount
		#tag EndNote
		PacketCount As Integer = 1
	#tag EndProperty


	#tag Constant, Name = DIRECTION_DOWN, Type = Double, Dynamic = False, Default = \"1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = DIRECTION_UP, Type = Double, Dynamic = False, Default = \"0", Scope = Private
	#tag EndConstant

	#tag Constant, Name = SFTP_MAX_PACKET_SIZE, Type = Double, Dynamic = False, Default = \"32768", Scope = Private
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

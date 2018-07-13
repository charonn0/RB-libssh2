#tag Class
Protected Class ScreenBuffer
	#tag Method, Flags = &h0
		Sub Constructor(Width As Integer, Height As Integer, Type As String = "vt100")
		  mType = Type
		  ReDim mChars(Width - 1, Height - 1)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub ProcessSequence(Sequence As MemoryBlock)
		  
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mChars(-1,-1) As Byte
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mType As String
	#tag EndProperty


End Class
#tag EndClass

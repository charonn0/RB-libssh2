#tag Class
Private Class SSHInit
	#tag Method, Flags = &h1
		Protected Sub Constructor(NoCrypto As Boolean = False)
		  If Not SSH.IsAvailable Then Raise New RuntimeException
		  Const LIBSSH2_INIT_NO_CRYPTO = &h0001
		  Dim err As Integer
		  If NoCrypto Then
		    err = libssh2_init(LIBSSH2_INIT_NO_CRYPTO)
		  Else
		    err = libssh2_init(0)
		  End If
		  If err <> 0 Then Raise New SSHException(err)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If SSH.IsAvailable Then libssh2_exit()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function GetInstance() As SSHInit
		  Static instance As WeakRef
		  Dim init As SSHInit
		  If instance = Nil Then
		    init = New SSHInit
		    instance = New WeakRef(init)
		  Else
		    init = SSHInit(instance.Value)
		  End If
		  Return init
		End Function
	#tag EndMethod


End Class
#tag EndClass

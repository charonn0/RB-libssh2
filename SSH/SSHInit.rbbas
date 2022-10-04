#tag Class
Private Class SSHInit
	#tag Method, Flags = &h1
		Protected Sub Constructor(NoCrypto As Boolean = LIBSSH2_INIT_NO_CRYPTO_DEFAULT)
		  If Not SSH.IsAvailable Then Raise New PlatformNotSupportedException
		  Dim err As Integer
		  If Not NoCrypto Then
		    ' Normal initialization.
		    err = libssh2_init(0)
		  Else
		    ' Do not to initialize the crypto library (ie. OPENSSL_add_cipher_algoritms() for OpenSSL).
		    ' This is not generally useful.
		    err = libssh2_init(LIBSSH2_INIT_NO_CRYPTO)
		  End If
		  If err <> 0 Then Raise New SSHException(err)
		  mInit = True
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If mInit Then libssh2_exit()
		  mInit = False
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function GetInstance() As SSHInit
		  Static instance As WeakRef
		  Dim init As SSHInit
		  If instance = Nil Or instance.Value = Nil Then
		    init = New SSHInit
		    instance = New WeakRef(init)
		  Else
		    init = SSHInit(instance.Value)
		  End If
		  Return init
		End Function
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mInit As Boolean
	#tag EndProperty


	#tag Constant, Name = LIBSSH2_INIT_NO_CRYPTO, Type = Double, Dynamic = False, Default = \"&h0001", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LIBSSH2_INIT_NO_CRYPTO_DEFAULT, Type = Boolean, Dynamic = False, Default = \"False", Scope = Protected
	#tag EndConstant

End Class
#tag EndClass

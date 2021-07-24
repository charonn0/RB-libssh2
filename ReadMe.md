## Introduction
[libssh2](https://www.libssh2.org/) is a cross-platform library implementing the SSH2 protocol. **RB-libssh2** is a libssh2 [binding](http://en.wikipedia.org/wiki/Language_binding) for Realbasic and Xojo ("classic" framework) projects. 

The minimum supported libssh2 version is 1.7.0. The minimum supported Xojo version is RS2010R4.

## Example
This example starts a command ("uptime") on the remote machine and reads from its StdOut stream ([**More examples**](https://github.com/charonn0/RB-libssh2/wiki#examples)): 

```xojo
  Dim sh As SSH.Channel = SSH.OpenChannel("ssh://user:password@public.example.com/")
  Call sh.Execute("uptime")
  Dim result As String
  Do Until sh.EOF
    If sh.PollReadable() Then
      result = result + sh.Read(sh.BytesReadable, 0)
    End If
  Loop
  sh.Close
```
## Hilights
* Password, public-key, agent, and interactive<sup>1</sup> [authentication](https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.SendCredentials).
* [Known host](https://github.com/charonn0/RB-libssh2/wiki/SSH.KnownHosts) key verification
* Download and upload using [SFTP](https://github.com/charonn0/RB-libssh2/wiki/SFTP-Examples) or [SCP](https://github.com/charonn0/RB-libssh2/wiki/SCP-Examples).
* Manage files and directories over SFTP.
* [Execute commands](https://github.com/charonn0/RB-libssh2/wiki/Process-Start-Example) on the server and read the results.
* [TCP forwarding and tunneling](https://github.com/charonn0/RB-libssh2/wiki/TCP-Tunneling)
* [Stream-oriented](https://github.com/charonn0/RB-libssh2/wiki/SSH.SSHStream), using Xojo's built-in [Readable](http://docs.xojo.com/index.php/Readable) and [Writeable](http://docs.xojo.com/index.php/Writeable) interfaces. 
* A consistent, high-level API over the full range of libssh2's features.
* Interact directly with libssh2 using idiomatic RB/Xojo objects, methods, and events; no shell or plugins required.

<sup>1</sup> Not fully implemented or currently broken

## Synopsis

***
It is strongly recommended that you familiarize yourself with [libssh2](https://www.libssh2.org/docs.html), as this project preserves the semantics of libssh2's API in an object-oriented, Xojo-flavored wrapper. 

For more thorough documentation of individual classes and methods refer to the [wiki](https://github.com/charonn0/RB-libssh2/wiki).

***

The SSH2 protocol permits an arbitrary number (up to 2<sup>32</sup>-1) of simultaneous [full-duplex](https://en.wikipedia.org/wiki/Duplex_(telecommunications)) binary data streams to be efficiently and securely [multiplexed](https://en.wikipedia.org/wiki/Multiplexing) over a single TCP connection. A data stream can be an upload or download using SFTP or SCP, the input/output of a program being executed on the server, a TCP connection to a third party forwarded through the SSH server, or your own custom protocol.

For simple, one-off operations you can usually use the [Get](https://github.com/charonn0/RB-libssh2/wiki/SSH.Get), [Put](https://github.com/charonn0/RB-libssh2/wiki/SSH.Put), [Execute](https://github.com/charonn0/RB-libssh2/wiki/SSH.Execute), or [OpenChannel](https://github.com/charonn0/RB-libssh2/wiki/SSH.OpenChannel) convenience methods in the SSH module. See also the [Connect](https://github.com/charonn0/RB-libssh2/wiki/SSH.Connect) convenience method if you want to perform several such operations on the same connection.

For more complex operations you will need to dig into the libssh2 API a bit more. libssh2 exposes its API through a number of different [handle](https://en.wikipedia.org/wiki/Handle_%28computing%29) types. Each libssh2 handle or handle equivalent corresponds to an object class implemented in the binding.

|Object Class|Comment|
|-----------|-------|
|[`Session`](https://github.com/charonn0/RB-libssh2/wiki/SSH.Session)|A secure connection to the server over which one or more data streams can be multiplexed.| 
|[`Channel`](https://github.com/charonn0/RB-libssh2/wiki/SSH.Channel)|A data stream that is multiplexed over a Session.|
|[`KnownHosts`](https://github.com/charonn0/RB-libssh2/wiki/SSH.KnownHosts)|A list of known hosts and their associated key fingerprints.|
|[`Agent`](https://github.com/charonn0/RB-libssh2/wiki/SSH.Agent)|A local key management agent.|
|[`SFTPSession`](https://github.com/charonn0/RB-libssh2/wiki/SSH.SFTPSession)|A SFTP session that is multiplexed over a Session.|
|[`SFTPStream`](https://github.com/charonn0/RB-libssh2/wiki/SSH.SFTPStream)|A SFTP upload, download, or other operation that is performed over a SFTPSession.|
|[`SFTPDirectory`](https://github.com/charonn0/RB-libssh2/wiki/SSH.SFTPDirectory)|A SFTP directory listing that is performed over a SFTPSession.|
|[`SCPStream`](https://github.com/charonn0/RB-libssh2/wiki/SSH.SCPStream)|A SCP upload or download that is multiplexed over a Session.|
|[`SSHStream`](https://github.com/charonn0/RB-libssh2/wiki/SSH.SSHStream)|An interface which aggregates the Readable and Writeable interfaces, representing a channel or other stream.|
|[`TCPListener`](https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPListener)|A listener for accepting forwarded TCP connections from the server.|
|[`TCPTunnel`](https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPTunnel)|A Channel over which a TCP connection is forwarded.|

The general order of operations is something like this:

1. Create a new instance of the `Session` class.
1. Call [Session.Connect](https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.Connect) with the address and port of the server, or a Xojo `TCPSocket` which is already connected to the server.
1. Optionally use the `KnownHosts` class to [load a list of acceptable server fingerprints](https://github.com/charonn0/RB-libssh2/wiki/SSH.KnownHosts.Load), and then [compare the newly connected session's fingerprint to that list](https://github.com/charonn0/RB-libssh2/wiki/SSH.KnownHosts.Lookup).
1. Call [Session.SendCredentials](https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.SendCredentials) to send the user's credentials to the server.
1. Check the [Session.IsAuthenticated](https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.IsAuthenticated) property to see if the credentials were accepted.
1. Create data streams over the session, for example the `Channel` or `SFTPSession` classes.
1. Interact with the created data streams through their [Read](https://github.com/charonn0/RB-libssh2/wiki/SSH.Channel.Read), [Write](https://github.com/charonn0/RB-libssh2/wiki/SSH.Channel.Write), etc. methods.
1. When finished with a data stream call its [Close](https://github.com/charonn0/RB-libssh2/wiki/SSH.Channel.Close) method.
1. After all data streams are finished and closed, call [Session.Close](https://github.com/charonn0/RB-libssh2/wiki/SSH.Session.Close) to end the connection.

### A note on threading
In many cases it will be advantageous to run SSH and SFTP operations on background thread, and it's safe to do so with one caveat.

Each instance of `SSH.Session` and all subsequent objects created with it (Channels, SFTP objects, etc.; collectively "the session") are a single resource for threading purposes; they all use the single TCP connection owned by the `SSH.Session` instance, and _that_ is the resource that threads must contend for.

If the session will be accessed from more than one thread then the entire session should be protected by a single synchronization object, such as a `Semaphore` or `CriticalSection`, so that only one thread can access the session at a time. "Access" is pretty much all-inclusive, since even reading the value of a property will in many cases send and receive data on the connection.

## How to incorporate libssh2 into your Realbasic/Xojo project
### Import the SSH module
1. Download the RB-libssh2 project either in [ZIP archive format](https://github.com/charonn0/RB-libssh2/archive/master.zip) or by cloning the repository with your Git client.
2. Open the RB-libssh2 project in REALstudio or Xojo. Open your project in a separate window.
3. Copy the `SSH` module into your project and save.

### Ensure the libssh2 shared library is installed
libssh2 is not installed by default on most systems, and will need to be installed separately (or shipped with your app). Pre-built binaries for Windows can be [downloaded from the libcurl project](https://curl.haxx.se/windows/dl-7.72.0_5/libssh2-1.9.0_5-win32-mingw.zip). You will also need `libcrypto-1_1.dll` from the OpenSSL project, also [available from libcurl](https://curl.haxx.se/windows/dl-7.72.0_5/openssl-1.1.1h_5-win32-mingw.zip).

RB-libssh2 will raise a PlatformNotSupportedException when used if all required DLLs/SOs/DyLibs are not available at runtime. 

## [Examples](https://github.com/charonn0/RB-libssh2/wiki/Examples)
* [SSH](https://github.com/charonn0/RB-libssh2/wiki/SSH-Examples)
  * [Establishing a connection](https://github.com/charonn0/RB-libssh2/wiki/SSH-Examples#creating-a-session-and-establishing-a-connection)
  * [Checking the server's fingerprint](https://github.com/charonn0/RB-libssh2/wiki/SSH-Examples#checking-the-servers-fingerprint)
  * [Authenticating to the server](https://github.com/charonn0/RB-libssh2/wiki/SSH-Examples#authenticating-to-the-server)
  * [Execute a command line](https://github.com/charonn0/RB-libssh2/wiki/Process-Start-Example)
* [SFTP](https://github.com/charonn0/RB-libssh2/wiki/SFTP-Examples)
  * [Download](https://github.com/charonn0/RB-libssh2/wiki/SFTP-Examples#download)
  * [Recursive download](https://github.com/charonn0/RB-libssh2/wiki/SFTP-Examples#recursive-download)
  * [Upload](https://github.com/charonn0/RB-libssh2/wiki/SFTP-Examples#upload)
  * [Recursive upload](https://github.com/charonn0/RB-libssh2/wiki/SFTP-Examples#recursive-upload)
  * [Directory listing](https://github.com/charonn0/RB-libssh2/wiki/SFTP-Examples#list-directory)
* [TCP tunneling](https://github.com/charonn0/RB-libssh2/wiki/TCP-Tunneling)
  * [Connect](https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPTunnel#connect-example)
  * [Listen (single connection)](https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPTunnel#listen-example)
  * [Listen (multiple connections)](https://github.com/charonn0/RB-libssh2/wiki/SSH.TCPListener#example)
* [SCP](https://github.com/charonn0/RB-libssh2/wiki/SCP-Examples)
  * [Download](https://github.com/charonn0/RB-libssh2/wiki/SCP-Examples#download)
  * [Upload](https://github.com/charonn0/RB-libssh2/wiki/SCP-Examples#upload)

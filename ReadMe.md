## Introduction
[libssh2](https://www.libssh2.org/) is a cross-platform library implementing the SSH2 protocol. **RB-libssh2** is a libssh2 [binding](http://en.wikipedia.org/wiki/Language_binding) for Realbasic and Xojo ("classic" framework) projects. 

The minimum supported libssh2 version is 1.7.0. The minimum supported Xojo version is RS2010R4.

## Example
This example starts a command ("uptime") on the remote machine and reads from its StdOut stream: 

```vbnet
  Dim sh As SSH.Channel = SSH.OpenChannel("ssh://user:password@public.example.com/")
  Call sh.Execute("uptime")
  Dim result As String
  Do Until sh.EOF
    result = result + sh.Read(1024, 0)
  Loop
  sh.Close
```
## Hilights
* Password, public-key, agent, and interactive authentication.
* Known host key verification
* Download and upload using SFTP or SCP.
* Execute commands on the server and read the results.
* TCP forwarding and tunneling
* [Stream-oriented](https://github.com/charonn0/RB-libssh2/wiki/SSH.SSHStream), using Xojo's built-in [Readable](http://docs.xojo.com/index.php/Readable) and [Writeable](http://docs.xojo.com/index.php/Writeable) interfaces. 
* A consistent, high-level API over the full range of libssh2's features.
* Interact directly with libssh2 using idiomatic RB/Xojo objects, methods, and events; no shell or plugins required.

## Synopsis

***
It is strongly recommended that you familiarize yourself with [libssh2](https://www.libssh2.org/docs.html), as this project preserves the semantics of libssh2's API in an object-oriented, Xojo-flavored wrapper. 

For more thorough documentation of individual classes and methods refer to the [wiki](https://github.com/charonn0/RB-libssh2/wiki).

***

Each libssh2 [handle](https://en.wikipedia.org/wiki/Handle_%28computing%29) or handle equivalent is managed by an object class. 

libssh2 uses several different handle types or equivalents:

|Handle Type|Comment|
|-----------|-------|
|[`Session`](https://github.com/charonn0/RB-libssh2/wiki/SSH.Session)|A secure connection to the server over which one or more channels can be multiplexed.| 
|[`Channel`](https://github.com/charonn0/RB-libssh2/wiki/SSH.Channel)|A data stream that is multiplexed over a Session.|
|[`KnownHosts`](https://github.com/charonn0/RB-libssh2/wiki/SSH.KnownHosts)|A list of known hosts and their associated key fingerprints.|
|[`Agent`](https://github.com/charonn0/RB-libssh2/wiki/SSH.Agent)|A local key management agent.|
|[`SFTPSession`](https://github.com/charonn0/RB-libssh2/wiki/SSH.SFTPSession)|A SFTP session that is multiplexed over a Session`.|
|[`SSHStream`](https://github.com/charonn0/RB-libssh2/wiki/SSH.SSHStream)|An interface which aggregates the Readable and Writeable interfaces, representing a channel or other stream.|


## How to incorporate libssh2 into your Realbasic/Xojo project
### Import the SSH module
1. Download the RB-libssh2 project either in [ZIP archive format](https://github.com/charonn0/RB-libssh2/archive/master.zip) or by cloning the repository with your Git client.
2. Open the RB-libssh2 project in REALstudio or Xojo. Open your project in a separate window.
3. Copy the `SSH` module into your project and save.

### Ensure the libssh2 shared library is installed
libssh2 is not installed by default on most systems, and will need to be installed separately (or shipped with your app). Pre-built binaries for Windows can be [downloaded from the libcurl project](https://curl.haxx.se/windows/dl-7.72.0_5/libssh2-1.9.0_5-win32-mingw.zip).

RB-libssh2 will raise a PlatformNotSupportedException when used if all required DLLs/SOs/DyLibs are not available at runtime. 

## Examples
* [SFTP download](https://github.com/charonn0/RB-libssh2/wiki/SFTP-Examples#download)
* [SFTP upload](https://github.com/charonn0/RB-libssh2/wiki/SFTP-Examples#upload)
* [SFTP directory listing](https://github.com/charonn0/RB-libssh2/wiki/SFTP-Examples#list-directory)
* [Execute command](https://github.com/charonn0/RB-libssh2/wiki/Process-Start-Example)
* [Forward a local port to the server](https://github.com/charonn0/RB-libssh2/wiki/TCP-Listener-Example)
* [Forward a server port to a local port](https://github.com/charonn0/RB-libssh2/wiki/TCP-Tunnel-Example)

## Introduction
[libssh2](https://www.libssh2.org/) is a cross-platform library implementing the SSH2 protocol. **RB-libssh2** is a libssh2 [binding](http://en.wikipedia.org/wiki/Language_binding) for Realbasic and Xojo ("classic" framework) projects. 

The minimum supported libssh2 version is 1.7.0; the recommended minimum version is 2.0.0. The minimum supported Xojo version is RS2010R4.

## Example
This example downloads a file over SFTP (SSH File Transfer Protocol.) [**More examples**](https://github.com/charonn0/RB-libssh2/wiki#examples).
```vbnet
  Dim reader As SSHStream = SSH.Get("sftp://user:password@public.example.com/bin/file.txt")
  Dim writer As BinaryStream = BinaryStream.Create(SpecialFolder.Desktop.Child("file.txt"))
  Do Until reader.EOF
    writer.Write(reader.Read(1024))
  Loop
  reader.Close
  writer.Close
```
## Hilights
* Download and upload using SFTP or SCP.
* Execute commands on the server and read the results.
* TCP forwarding and tunnelling
* [Stream-oriented](https://github.com/charonn0/RB-libssh2/wiki/SSH.SSHStream), using Xojo's built-in [Readable](http://docs.xojo.com/index.php/Readable) and [Writeable](http://docs.xojo.com/index.php/Writeable) interfaces. 
* A consistent, high-level API over the full range of libssh2's features.
* Interact directly with libssh2 using idiomatic RB/Xojo objects, methods, and events; no shell or plugins required.

## Synopsis

***
It is strongly recommended that you familiarize yourself with version [libssh2](https://www.libssh2.org/docs.html), as this project preserves the semantics of libssh2's API in an object-oriented, Xojo-flavored wrapper. 

For more thorough documentation of individual classes and methods refer to the [wiki](https://github.com/charonn0/RB-libssh2/wiki).

***

Each libssh2 [handle](https://en.wikipedia.org/wiki/Handle_%28computing%29) or handle equivalent is managed by an object class. 

libssh2 uses several different handle types or equivalents:

## How to incorporate libssh2 into your Realbasic/Xojo project
### Import the SSH module
1. Download the RB-libssh2 project either in [ZIP archive format](https://github.com/charonn0/RB-libssh2/archive/master.zip) or by cloning the repository with your Git client.
2. Open the RB-libssh2 project in REALstudio or Xojo. Open your project in a separate window.
3. Copy the `SSH` module into your project and save.

### Ensure the libssh2 shared library is installed
libssh2 is not installed by default on most systems, and will need to be installed separately (or shipped with your app).

RB-libssh2 will raise a PlatformNotSupportedException when used if all required DLLs/SOs/DyLibs are not available at runtime. 

## Examples
* [SFTP download](https://github.com/charonn0/RB-libssh2/wiki/SFTP-GET-Example)
* [SFTP upload](https://github.com/charonn0/RB-libssh2/wiki/SFTP-PUT-Example)
* [Execute command](https://github.com/charonn0/RB-libssh2/wiki/Process-Start-Example)
* [Forward a local port to the server](https://github.com/charonn0/RB-libssh2/wiki/TCP-Listener-Example)
* [Forward a server port to a local port](https://github.com/charonn0/RB-libssh2/wiki/TCP-Tunnel-Example)

# SMBClient

[![Test](https://github.com/kishikawakatsumi/SMBClient/actions/workflows/test.yml/badge.svg)](https://github.com/kishikawakatsumi/SMBClient/actions/workflows/test.yml)

Swift SMB client library and iOS/macOS file browser applications. This library provides a high-level interface to the SMB protocol and allows you to access files on remote SMB servers. Written in Swift, no dependencies on external libraries.

## Usage

`SMBClient` class hides the low-layer SMB protocol and provides a higher-layer interface suitable for common use cases. The following example demonstrates how to list files in a share drive on a remote SMB server.

```swift
import SMBClient

let client = SMBClient(host: "198.51.100.50")

try await client.login(username: "alice", password: "secret")
try await client.connectShare("Public")

let files = try await client.listDirectory("")
print(files.map { $0.fileName })

try await client.disconnectShare()
try await client.logoff()
```

If you want to use the low-layer SMB protocol directly, you can use the `Session` class. `Session` class provides a set of functions that correspond to SMB messages. You can get more fine-grained control over the SMB protocol.

```swift
import SMBClient

let session = Session(host: "198.51.100.50")

try await session.connect()
try await session.negotiate()

try await session.sessionSetup(username: "alice", password: "secret")
try await session.treeConnect(path: "Public")

let files = try await session.queryDirectory(path: "", pattern: "*")
print(files.map { $0.fileName })

try await session.treeDisconnect()
try await session.logoff()
```

### Log in to the remote SMB server

```swift
let client = SMBClient(host: "198.51.100.50")
try await client.login(username: "alice", password: "secret")
```

### List share drives

```swift
let shares = try await client.listShares()
print(shares.map { $0.name })
```

### Connect to a share drive

```swift
try await client.connectShare("Public")
```

### List files in a directory

```swift
let files = try await client.listDirectory("Documents/Presentations")
print(files.map { $0.fileName })
```

### Download a file

```swift
let data = try await client.download(path: "Pictures/IMG_0001.jpg")
```

### Upload a file/directory

```swift
try await client.upload(data: data, path: "Documents/Presentations/Keynote.key")
```

## Example Applications

### Network File Browser for macOS

<img width="1200" src="https://github.com/user-attachments/assets/5573ab34-645a-404e-b28f-182935b0badd" alt="macOS File Browser App">

### Network File Browser for iOS

<img width="393" src="https://github.com/user-attachments/assets/34c2a682-ea46-4997-8652-fea8a51fc371" alt="iOS File Browser App"> <img width="393" src="https://github.com/user-attachments/assets/84bc9692-d200-40c7-bc4d-305a0603e8ba" alt="iOS File Browser App">

### Network File Browser for visionOS

<img width="1200" alt="visionOS File Browser App" src="https://github.com/user-attachments/assets/2b202a99-9bc5-494c-8dd1-7d1155990e3a">

## Installation

Add the following line to the dependencies in your `Package.swift` file:

```swift
dependencies: [
  .package(url: "https://github.com/kishikawakatsumi/SMBClient.git", .upToNextMajor(from: "0.1.0"))
]
```

## Supported Platforms

- macOS 10.15 or later
- iOS 13.0 or later

## Supported Protocol Version

SMB 2.0 (aka `SMB2`) is supported. See [Header](Sources/SMBClient/Messages/Header.swift) for protocol support, which follows [SMB2 Packet Header open specification](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-smb2/fb188936-5050-48d3-b350-dc43059638a4).

### Supported SMB Messages

- [x] NEGOTIATE
- [x] SESSION_SETUP
- [x] LOGOFF
- [x] TREE_CONNECT
- [x] TREE_DISCONNECT
- [x] CREATE
- [x] CLOSE
- [ ] FLUSH
- [x] READ
- [x] WRITE
- [ ] LOCK
- [x] ECHO
- [ ] CANCEL
- [x] IOCTL
- [x] QUERY_DIRECTORY
- [ ] CHANGE_NOTIFY
- [x] QUERY_INFO
- [x] SET_INFO

## FAQ

### How to connedct to macOS file sharing?

To connect to macOS file sharing, you need to enable "Windows File Sharing" in the "Sharing" sytem settings in "File Sharing" section. This will enable NTLM v2 authentication on your macOS.

<img width="600" src="https://github.com/user-attachments/assets/9d521df6-b899-4f10-ac8e-0dbbe371e5c2" alt="macOS File Sharing settings">

### Compatibility with SMB1 and AFP

This library does not support `SMB1` and will not support SMB 1.0 in the near future, this is due to SMB1 and SMB2 are not compatible, with completely different packet structures.

Relatedly, connecting to macOS servers using pre-SMB, Apple Filing Protocol ([AFP](https://en.wikipedia.org/wiki/Apple_Filing_Protocol)) is not supported. 

`OS X 10.9 Mavericks` and later supports SMB as the primary file sharing protocol.

## Supporters & Sponsors

Open source projects thrive on the generosity and support of people like you. If you find this project valuable, please consider extending your support. Contributing to the project not only sustains its growth, but also helps drive innovation and improve its features.

To support this project, you can become a sponsor through [GitHub Sponsors](https://github.com/sponsors/kishikawakatsumi). Your contribution will be greatly appreciated and will help keep the project alive and thriving. Thanks for your consideration! :heart:

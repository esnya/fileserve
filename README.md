# fileserve
Simple file server and client program.

# Server (send) mode

```
fileserve --server [OPTIONS] <files...>
```

## OPTIONS
--server / -s
:    Server mode

-h
:    Bind address

--port / -p
:    Bind port

# Client (receive) mode

```
$ fileserve -h <server address> -p <server port>
```

## OPTIONS
-h
:    Server address

--port / -p
:    Server port

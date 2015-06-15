import std.algorithm;
import std.getopt;
import std.parallelism;
import std.range;
import std.socket;
import std.stdio;
import std.traits;
    import std.file;

void emit(Socket socket, in void[] array) {
    ulong length = array.length;
    socket.send([length]);
    socket.send(array);
}

void sendFiles(R)(Socket client, R files) if (isInputRange!R && isSomeString!(ElementType!R)) {
    writeln("Client connected: ", client.remoteAddress);

    foreach (file; files) {
        writeln("Sending file: ", file);
        client.emit(file);
        client.emit(file.read());
    }
    client.close();
}

void server(R)(Address address, R files) if (isInputRange!R && isSomeString!(ElementType!R)) {
    auto server = new TcpSocket;
    server.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
    server.bind(address);
    server.listen(1);

    writeln("Server started on: ", server.localAddress);

    while (1) {
        server.accept()
            .task!sendFiles(files)
            .executeInNewThread();
    }
}

T[] getArray(T = void)(Socket socket) {
    ulong length;

    auto ret = socket.receive((&length)[0 .. 1]);
    if (ret <= 0) return null;

    T[] data;
    ulong received = 0;
    auto buf = new T[length];
    do {
        auto ret_ = socket.receive(buf[0 .. cast(size_t)(length - received)]);
        if (ret_ <= 0) return null;

        data ~= buf[0 .. ret_];
        received += ret_;
    } while (received < length);

    return data;
}

void client(Address address) {
    writeln("Connecting to: ", address);

    auto socket = new TcpSocket(address);

    writeln("Connected to: ", socket.remoteAddress);

    while (socket.isAlive()) {
        import std.file;
        import std.path;

        auto filename = socket.getArray!char();
        if (!filename) break;

        auto localname = filename.baseName();
        writeln("Receiving file: ", filename, " -> ", localname);

        localname.write(socket.getArray());
    }
}

void main(string[] args)
{
    auto addr = "0.0.0.0";
    auto port = InternetAddress.PORT_ANY;
    bool isServer = false;

    args.getopt("h", &addr, "port|p", &port, "server|s", &isServer);

    auto address = new InternetAddress(addr, port);
    if (isServer) {
        server(address, args.drop(1));
    } else {
        client(address);
    }
}

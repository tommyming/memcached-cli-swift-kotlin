// memcached cli client, swift version

import Foundation
import NIO

import Foundation
import NIO

class MemcachedClient {
    private let host: String
    private let port: Int
    private let group: MultiThreadedEventLoopGroup
    private var channel: Channel?

    init(host: String, port: Int) {
        self.host = host
        self.port = port
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    }

    func connect() -> EventLoopFuture<Void> {
        let bootstrap = ClientBootstrap(group: group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                channel.pipeline.addHandler(StringDelimiterCodec(delimiter: "\r\n"))
            }
        
        return bootstrap.connect(host: host, port: port).map { channel in
            self.channel = channel
            print("Connected to Memcached server at \(self.host):\(self.port)")
        }
    }

    func set(_ key: String, _ value: String) -> EventLoopFuture<Void> {
        guard let channel = channel else {
            return group.next().makeFailedFuture(MemcachedError.notConnected)
        }
        let command = "set \(key) 0 0 \(value.count)\r\n\(value)\r\n"
        return channel.writeAndFlush(command).map { _ in
            print("Set \(key) = \(value)")
        }
    }

    func get(_ key: String) -> EventLoopFuture<String?> {
        guard let channel = channel else {
            return group.next().makeFailedFuture(MemcachedError.notConnected)
        }
        let command = "get \(key)\r\n"
        return channel.writeAndFlush(command).flatMap { _ in
            channel.readInbound().map { response in
                if let response = response as? String, response.hasPrefix("VALUE") {
                    let parts = response.split(separator: "\r\n")
                    if parts.count >= 2 {
                        print("Got \(key) = \(parts[1])")
                        return String(parts[1])
                    }
                }
                print("Key \(key) not found")
                return nil
            }
        }
    }

    func close() -> EventLoopFuture<Void> {
        guard let channel = channel else {
            return group.next().makeSucceededFuture(())
        }
        return channel.close()
    }
}

enum MemcachedError: Error {
    case notConnected
}

// Main CLI loop
let client = MemcachedClient(host: "localhost", port: 11211)

client.connect().whenComplete { result in
    switch result {
    case .success:
        print("Enter commands (set key value, get key, or quit):")
        while let input = readLine() {
            let parts = input.split(separator: " ")
            switch parts[0] {
            case "set":
                if parts.count >= 3 {
                    let key = String(parts[1])
                    let value = parts[2...].joined(separator: " ")
                    _ = client.set(key, value)
                } else {
                    print("Usage: set key value")
                }
            case "get":
                if parts.count == 2 {
                    _ = client.get(String(parts[1]))
                } else {
                    print("Usage: get key")
                }
            case "quit":
                _ = client.close()
                exit(0)
            default:
                print("Unknown command")
            }
        }
    case .failure(let error):
        print("Failed to connect: \(error)")
    }
}

RunLoop.main.run()
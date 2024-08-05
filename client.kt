import java.net.Socket
import java.io.BufferedReader
import java.io.PrintWriter

class MemcachedClient(private val host: String, private val port: Int) {
    private lateinit var socket: Socket
    private lateinit var reader: BufferedReader
    private lateinit var writer: PrintWriter

    fun connect() {
        socket = Socket(host, port)
        reader = socket.getInputStream().bufferedReader()
        writer = PrintWriter(socket.getOutputStream(), true)
        println("Connected to Memcached server at $host:$port")
    }

    fun set(key: String, value: String) {
        val command = "set $key 0 0 ${value.length}\r\n$value\r\n"
        writer.print(command)
        writer.flush()
        val response = reader.readLine()
        println("Set $key = $value")
        println("Server response: $response")
    }

    fun get(key: String) {
        val command = "get $key\r\n"
        writer.print(command)
        writer.flush()
        val response = reader.readLine()
        if (response.startsWith("VALUE")) {
            val value = reader.readLine()
            println("Got $key = $value")
            reader.readLine() // Read the END line
        } else {
            println("Key $key not found")
        }
    }

    fun close() {
        socket.close()
    }
}

fun main() {
    val client = MemcachedClient("localhost", 11211)
    client.connect()

    println("Enter commands (set key value, get key, or quit):")
    while (true) {
        val input = readLine() ?: break
        val parts = input.split(" ")
        when (parts[0]) {
            "set" -> {
                if (parts.size >= 3) {
                    val key = parts[1]
                    val value = parts.subList(2, parts.size).joinToString(" ")
                    client.set(key, value)
                } else {
                    println("Usage: set key value")
                }
            }
            "get" -> {
                if (parts.size == 2) {
                    client.get(parts[1])
                } else {
                    println("Usage: get key")
                }
            }
            "quit" -> {
                client.close()
                return
            }
            else -> println("Unknown command")
        }
    }
}
// Davide Costantini
// Server, multi-threaded, accepting several simultaneous clients.

import java.io.*;
import java.net.Socket;
import java.net.ServerSocket;
import java.net.SocketAddress;
import java.util.concurrent.*;

class EchoServer implements Runnable {

	private final static int PORT = 8000;
	private final static int MAX_CLIENTS = 5;
	private final static Executor receivers = Executors.newFixedThreadPool(MAX_CLIENTS);
	private final static Executor senders = Executors.newFixedThreadPool(MAX_CLIENTS);
	private static final CopyOnWriteArrayList<EchoServer> clients = new CopyOnWriteArrayList<>();
	private final static BlockingQueue<String> messageQueue = new LinkedBlockingQueue<>();

	private final Socket clientSocket;
	private final SocketAddress remoteSocketAddress;
	private String clientName = "";
	private PrintWriter socketWriter = null;

	private EchoServer(Socket clientSocket) {

		this.clientSocket = clientSocket;
		this.remoteSocketAddress = clientSocket.getRemoteSocketAddress();
	}

	public void run() {

		SocketAddress localSocketAddress = clientSocket.getLocalSocketAddress();
		System.out.println("Accepted client " + remoteSocketAddress + " (" + localSocketAddress + ").");

		BufferedReader socketReader = null;
		try {
			socketWriter = new PrintWriter(clientSocket.getOutputStream(), true);
            socketReader = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));

			String threadInfo = " (" + Thread.currentThread().getName() + ").";
            String inputLine = socketReader.readLine();
				
			// First message is client name.
			System.out.println("Received client name \"" + inputLine + "\" from " + remoteSocketAddress + threadInfo);
			clientName = inputLine;

			do {
				inputLine = socketReader.readLine();
				System.out.println("Received: \"" + inputLine + "\" from " + clientName + " " + remoteSocketAddress + threadInfo);
				messageQueue.add(this.clientName + ": " + inputLine);
			} while (inputLine != null);

			System.out.println("Closing connection " + remoteSocketAddress + " (" + localSocketAddress + ").");
			clients.remove(this);
		} catch (Exception exception) {
            System.out.println(exception);
        } finally {
			try {
				if (socketWriter != null) {
					socketWriter.close();
					socketWriter = null;
				}
				if (socketReader != null)
					socketReader.close();
				if (clientSocket != null)
					clientSocket.close();
			}
			catch (Exception exception) {
				System.out.println(exception);
			}
		}
	}

    public static void main(String[] args) {

		System.out.println("EchoServer started.");
		ServerSocket serverSocket = null;
		Socket clientSocket = null;
		try {
            serverSocket = new ServerSocket(PORT);
			SocketAddress serverSocketAddress = serverSocket.getLocalSocketAddress();
			waitForMessages();
			System.out.println("Listening (" + serverSocketAddress + ").");

			while (true) {
				clientSocket = serverSocket.accept();
				EchoServer echoServer = new EchoServer(clientSocket);
				receivers.execute(echoServer);
				clients.add(echoServer);
			}
        } catch (Exception exception) {
            System.out.println(exception);
        } finally {
			try {
				if (serverSocket != null)
					serverSocket.close();
			}
			catch (Exception exception) {
				System.out.println(exception);
			}
		}
    }

	public static void waitForMessages() {

		new Thread(() -> {
			while (true) {
				try {
					String message = messageQueue.take();
					for (EchoServer client : clients)
						senders.execute(new Thread(() -> client.sendToClient(message)));
				} catch (InterruptedException e) {
					System.err.println("Interrupted.");
					e.printStackTrace();
				}
			}
		}).start();
	}

	public void sendToClient(String message) {

		if (socketWriter == null)
			return;

		String threadInfo = " (" + Thread.currentThread().getName() + ").";
		socketWriter.println(message);
		System.out.println("Sent: \"" + message + "\" to " + clientName + " " + remoteSocketAddress + threadInfo);
	}
}

import Foundation
import Combine

final class WebSocketManager: NSObject, ObservableObject, URLSessionWebSocketDelegate {
    static let shared = WebSocketManager()

    @Published var latestEvent: WSCheckinData?
    @Published var isConnected = false

    private var task: URLSessionWebSocketTask?
    private var session: URLSession?
    private var sessionId: Int?

    override private init() {
        super.init()
    }

    func connect(sessionId: Int) {
        if self.sessionId == sessionId, task != nil {
            return
        }

        if task != nil || session != nil {
            disconnect()
        }

        self.sessionId = sessionId
        guard let url = URL(string: Constants.WebSocket.sessionURL(sessionId)) else { return }
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["ngrok-skip-browser-warning": "true"]
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        task = session?.webSocketTask(with: url)
        task?.resume()
        receive()
        DispatchQueue.main.async { self.isConnected = true }
    }

    func disconnect() {
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
        session = nil
        sessionId = nil
        DispatchQueue.main.async { self.isConnected = false }
    }

    private func receive() {
        task?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                self.receive()
            case .failure:
                DispatchQueue.main.async { self.isConnected = false }
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        let decoder = JSONDecoder()
        if let event = try? decoder.decode(WSCheckinEvent.self, from: data),
           event.type == "checkin" {
            DispatchQueue.main.async {
                self.latestEvent = event.data
            }
        }
    }

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        DispatchQueue.main.async { self.isConnected = true }
    }

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        DispatchQueue.main.async { self.isConnected = false }
    }
}

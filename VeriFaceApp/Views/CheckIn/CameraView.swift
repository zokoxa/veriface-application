import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> CameraViewController {
        let vc = CameraViewController()
        vc.onCapture = { image in
            DispatchQueue.main.async { onCapture(image) }
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

final class CameraViewController: UIViewController {
    var onCapture: ((UIImage) -> Void)?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(label: "veriface.video", qos: .userInitiated)
    private var captureTimer: Timer?
    private lazy var ciContext = CIContext()
    // Only convert frames when the timer is ready to consume one, avoiding
    // ~30 CIImage→CGImage→UIImage conversions per second at idle.
    private var needsNextFrame = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.global(qos: .background).async {
            if !self.session.isRunning { self.session.startRunning() }
        }
        startTimer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureTimer?.invalidate()
        captureTimer = nil
        DispatchQueue.global(qos: .background).async {
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    private func setupCamera() {
        session.sessionPreset = .high

        let position: AVCaptureDevice.Position = .front
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
                ?? AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)

        // Use a standard BGRA buffer so CI/CoreGraphics produce consistent frames.
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        guard session.canAddOutput(videoOutput) else { return }
        session.addOutput(videoOutput)

        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = false
            }
        }

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(layer, at: 0)
        previewLayer = layer
        if let previewConnection = layer.connection {
            if previewConnection.isVideoMirroringSupported {
                previewConnection.automaticallyAdjustsVideoMirroring = false
                previewConnection.isVideoMirrored = true
            }
        }
    }

    private func setupUI() {
        // Oval face guide
        let guideView = UIView()
        guideView.translatesAutoresizingMaskIntoConstraints = false
        guideView.backgroundColor = .clear
        guideView.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
        guideView.layer.borderWidth = 2
        view.addSubview(guideView)

        NSLayoutConstraint.activate([
            guideView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            guideView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            guideView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.55),
            guideView.heightAnchor.constraint(equalTo: guideView.widthAnchor, multiplier: 1.3),
        ])
        guideView.layoutIfNeeded()
        guideView.layer.cornerRadius = guideView.bounds.width / 2

        // Status label
        let hint = UILabel()
        hint.text = "Position face in oval"
        hint.textColor = .white
        hint.font = .systemFont(ofSize: 14, weight: .medium)
        hint.textAlignment = .center
        hint.numberOfLines = 0
        hint.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hint)

        NSLayoutConstraint.activate([
            hint.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hint.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            hint.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            hint.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }

    private func startTimer() {
        captureTimer?.invalidate()
        // Signal immediately so the first scan doesn't wait 2 seconds.
        videoQueue.async { self.needsNextFrame = true }
        captureTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.videoQueue.async { self?.needsNextFrame = true }
        }
    }
}

// MARK: - UIImage orientation normalization

private extension UIImage {
    /// Redraws the image so its pixel data matches its orientation metadata (imageOrientation = .up).
    func normalized() -> UIImage {
        guard imageOrientation != .up else { return self }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: size)) }
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        // Only do the expensive conversion when the timer needs a frame.
        guard needsNextFrame else { return }
        needsNextFrame = false
        // Convert immediately while the buffer is valid — never store CMSampleBuffer long-term
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }
        // The front-camera sample buffer arrives as landscape; rotate only the
        // uploaded frame to portrait while leaving the preview orientation alone.
        let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .right).normalized()
        DispatchQueue.main.async { self.onCapture?(image) }
    }
}

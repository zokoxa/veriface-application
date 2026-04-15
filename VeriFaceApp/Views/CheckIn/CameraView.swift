import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?

    func makeUIViewController(context: Context) -> CameraViewController {
        let vc = CameraViewController()
        vc.onCapture = { image in
            DispatchQueue.main.async { capturedImage = image }
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
    private var latestBuffer: CMSampleBuffer?
    private var captureTimer: Timer?

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
        session.sessionPreset = .medium

        let position: AVCaptureDevice.Position = .front
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
                ?? AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        guard session.canAddOutput(videoOutput) else { return }
        session.addOutput(videoOutput)

        // Mirror front camera preview
        if let connection = videoOutput.connection(with: .video), connection.isVideoMirroringSupported {
            connection.isVideoMirrored = true
        }

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(layer, at: 0)
        previewLayer = layer
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
        hint.text = "Scanning every 2 seconds — position face in oval"
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
        captureTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.captureFrame()
        }
    }

    private func captureFrame() {
        videoQueue.async { [weak self] in
            guard let self, let buffer = self.latestBuffer else { return }
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else { return }
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
            let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .upMirrored)
            DispatchQueue.main.async { self.onCapture?(image) }
        }
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        latestBuffer = sampleBuffer
    }
}

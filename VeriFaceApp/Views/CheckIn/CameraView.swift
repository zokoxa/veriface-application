import SwiftUI
import AVFoundation

/// UIViewControllerRepresentable that shows a live camera preview and exposes a capture action.
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
    private let output = AVCapturePhotoOutput()
    private var captureButton: UIButton!

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
        if !session.isRunning {
            DispatchQueue.global(qos: .background).async { self.session.startRunning() }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning {
            DispatchQueue.global(qos: .background).async { self.session.stopRunning() }
        }
    }

    private func setupCamera() {
        session.sessionPreset = .photo

        // Prefer front camera for check-in
        let position: AVCaptureDevice.Position = .front
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                    for: .video,
                                                    position: position) ??
              AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }

        session.addInput(input)

        guard session.canAddOutput(output) else { return }
        session.addOutput(output)

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(layer, at: 0)
        previewLayer = layer

        DispatchQueue.global(qos: .background).async { self.session.startRunning() }
    }

    private func setupUI() {
        // Oval face guide overlay
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

        // Hint label
        let hint = UILabel()
        hint.text = "Position face in oval, then tap Capture"
        hint.textColor = .white
        hint.font = .systemFont(ofSize: 14, weight: .medium)
        hint.textAlignment = .center
        hint.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hint)

        // Capture button
        captureButton = UIButton(type: .custom)
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 36
        captureButton.layer.borderWidth = 4
        captureButton.layer.borderColor = UIColor.systemBlue.cgColor
        captureButton.setImage(UIImage(systemName: "camera.fill",
                                       withConfiguration: UIImage.SymbolConfiguration(pointSize: 28)),
                               for: .normal)
        captureButton.tintColor = .systemBlue
        captureButton.addTarget(self, action: #selector(didTapCapture), for: .touchUpInside)
        view.addSubview(captureButton)

        NSLayoutConstraint.activate([
            hint.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hint.bottomAnchor.constraint(equalTo: captureButton.topAnchor, constant: -16),

            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            captureButton.widthAnchor.constraint(equalToConstant: 72),
            captureButton.heightAnchor.constraint(equalToConstant: 72),
        ])
    }

    @objc private func didTapCapture() {
        captureButton.isEnabled = false
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        captureButton.isEnabled = true
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        onCapture?(image)
    }
}

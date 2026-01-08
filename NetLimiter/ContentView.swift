import SwiftUI

struct ContentView: View {
    @StateObject private var limiter = NetworkLimiter()
    @State private var downloadValue: Double = 100000
    @State private var uploadValue: Double = 100000
    @State private var downloadInput: String = "100000"
    @State private var uploadInput: String = "100000"
    @State private var advancedMode: Bool = false
    @State private var activeDownload: Double? = nil
    @State private var activeUpload: Double? = nil

    private let presets: [(String, Double)] = [
        ("512K", 512),
        ("1M", 1000),
        ("10M", 10000),
        ("100M", 100000),
        ("500M", 500000),
        ("1G", 1000000)
    ]

    var body: some View {
        VStack(spacing: 16) {
            // Status & Toggle
            HStack {
                Toggle(isOn: Binding(
                    get: { limiter.isEnabled },
                    set: { newValue in
                        if newValue {
                            limiter.downloadKbps = downloadValue
                            limiter.uploadKbps = uploadValue
                            limiter.enable()
                            activeDownload = downloadValue
                            activeUpload = uploadValue
                        } else {
                            limiter.disable()
                            activeDownload = nil
                            activeUpload = nil
                        }
                    }
                )) {
                    Text(limiter.isEnabled ? "ON" : "OFF")
                        .font(.headline)
                        .foregroundColor(limiter.isEnabled ? .green : .secondary)
                }
                .toggleStyle(.switch)

                Spacer()

                Toggle("Split Up/Down", isOn: $advancedMode)
                    .toggleStyle(.checkbox)
                    .font(.caption)
            }

            // Current active limit indicator
            if limiter.isEnabled {
                HStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    if advancedMode, let dl = activeDownload, let ul = activeUpload {
                        Text("Down: \(formatSpeed(dl)) | Up: \(formatSpeed(ul))")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    } else if let dl = activeDownload {
                        Text("Active: \(formatSpeed(dl))")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }

            Divider()

            if advancedMode {
                // Advanced mode - separate controls
                VStack(spacing: 12) {
                    // Download
                    VStack(spacing: 4) {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(.blue)
                            Text("Download")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            TextField("Kbps", text: $downloadInput)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 70)
                                .onSubmit { applyDownloadFromInput() }
                            Text("Kbps")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $downloadValue, in: 100...1000000, step: 100)
                            .onChange(of: downloadValue) { newValue in
                                downloadInput = String(Int(newValue))
                            }
                        Text(formatSpeed(downloadValue))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Upload
                    VStack(spacing: 4) {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(.orange)
                            Text("Upload")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            TextField("Kbps", text: $uploadInput)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 70)
                                .onSubmit { applyUploadFromInput() }
                            Text("Kbps")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $uploadValue, in: 100...1000000, step: 100)
                            .onChange(of: uploadValue) { newValue in
                                uploadInput = String(Int(newValue))
                            }
                        Text(formatSpeed(uploadValue))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Button("Apply") {
                    applyBoth()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!limiter.isEnabled)

            } else {
                // Simple mode - single control
                HStack(spacing: 8) {
                    TextField("Kbps", text: $downloadInput)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .onSubmit { applySimpleFromInput() }

                    Text("Kbps")
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Apply") {
                        applySimple()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!limiter.isEnabled)
                }

                VStack(spacing: 4) {
                    Slider(value: $downloadValue, in: 100...1000000, step: 100)
                        .onChange(of: downloadValue) { newValue in
                            downloadInput = String(Int(newValue))
                            uploadValue = newValue
                            uploadInput = String(Int(newValue))
                        }

                    HStack {
                        Text("100 Kbps")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatSpeed(downloadValue))
                            .font(.caption)
                            .fontWeight(.medium)
                            .monospacedDigit()
                        Spacer()
                        Text("1 Gbps")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Presets
                HStack(spacing: 8) {
                    ForEach(presets, id: \.0) { preset in
                        Button(preset.0) {
                            downloadValue = preset.1
                            uploadValue = preset.1
                            downloadInput = String(Int(preset.1))
                            uploadInput = String(Int(preset.1))
                        }
                        .buttonStyle(.bordered)
                        .tint(abs(downloadValue - preset.1) < 1 ? .blue : .secondary)
                        .controlSize(.small)
                    }
                }
            }

            if let error = limiter.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .lineLimit(2)
            }

            Divider()

            HStack(spacing: 4) {
                Text("by")
                    .foregroundColor(.secondary)
                Link("Dima Goltsman", destination: URL(string: "https://github.com/dimagoltsman")!)
            }
            .font(.caption)
        }
        .padding(20)
        .frame(width: 340)
    }

    // Simple mode
    private func applySimpleFromInput() {
        if let value = Double(downloadInput), value >= 100 {
            downloadValue = min(value, 1000000)
            uploadValue = downloadValue
            uploadInput = downloadInput
            applySimple()
        }
    }

    private func applySimple() {
        guard limiter.isEnabled else { return }
        limiter.downloadKbps = downloadValue
        limiter.uploadKbps = downloadValue
        limiter.updateBoth()
        activeDownload = downloadValue
        activeUpload = downloadValue
    }

    // Advanced mode
    private func applyDownloadFromInput() {
        if let value = Double(downloadInput), value >= 100 {
            downloadValue = min(value, 1000000)
        }
    }

    private func applyUploadFromInput() {
        if let value = Double(uploadInput), value >= 100 {
            uploadValue = min(value, 1000000)
        }
    }

    private func applyBoth() {
        guard limiter.isEnabled else { return }
        limiter.downloadKbps = downloadValue
        limiter.uploadKbps = uploadValue
        limiter.updateBoth()
        activeDownload = downloadValue
        activeUpload = uploadValue
    }

    private func formatSpeed(_ kbps: Double) -> String {
        if kbps >= 1000000 {
            return String(format: "%.2f Gbps", kbps / 1000000)
        } else if kbps >= 1000 {
            return String(format: "%.1f Mbps", kbps / 1000)
        }
        return String(format: "%.0f Kbps", kbps)
    }
}

#Preview {
    ContentView()
}

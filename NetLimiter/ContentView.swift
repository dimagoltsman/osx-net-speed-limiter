import SwiftUI

struct ContentView: View {
    @StateObject private var limiter = NetworkLimiter()
    @State private var sliderValue: Double = 1000
    @State private var manualInput: String = "1000"
    @State private var activeLimit: Double? = nil

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
                            limiter.bandwidthKbps = sliderValue
                            limiter.enable()
                            activeLimit = sliderValue
                        } else {
                            limiter.disable()
                            activeLimit = nil
                        }
                    }
                )) {
                    Text(limiter.isEnabled ? "ON" : "OFF")
                        .font(.headline)
                        .foregroundColor(limiter.isEnabled ? .green : .secondary)
                }
                .toggleStyle(.switch)
            }

            // Current active limit indicator
            if limiter.isEnabled, let limit = activeLimit {
                HStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text("Active: \(formatSpeed(limit))")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }

            Divider()

            // Manual input + Apply
            HStack(spacing: 8) {
                TextField("Kbps", text: $manualInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .onSubmit { applyFromInput() }

                Text("Kbps")
                    .foregroundColor(.secondary)

                Spacer()

                Button("Apply") {
                    applySpeed()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!limiter.isEnabled)
            }

            // Slider
            VStack(spacing: 4) {
                Slider(value: $sliderValue, in: 100...1000000, step: 100)
                    .onChange(of: sliderValue) { newValue in
                        manualInput = String(Int(newValue))
                    }

                HStack {
                    Text("100 Kbps")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatSpeed(sliderValue))
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
                        sliderValue = preset.1
                        manualInput = String(Int(preset.1))
                    }
                    .buttonStyle(.bordered)
                    .tint(abs(sliderValue - preset.1) < 1 ? .blue : .secondary)
                    .controlSize(.small)
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

    private func applyFromInput() {
        if let value = Double(manualInput), value >= 100 {
            sliderValue = min(value, 1000000)
            applySpeed()
        }
    }

    private func applySpeed() {
        guard limiter.isEnabled else { return }
        limiter.bandwidthKbps = sliderValue
        limiter.updateBandwidth()
        activeLimit = sliderValue
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

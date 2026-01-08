import Foundation

class NetworkLimiter: ObservableObject {
    @Published var isEnabled = false
    @Published var bandwidthKbps: Double = 1000
    @Published var lastError: String?

    private let pipeNumber = 1
    private var helperProcess: Process?
    private let cmdFile = "/tmp/netlimiter_cmd"
    private let pidFile = "/tmp/netlimiter_pid"

    func enable() {
        let bwString = formatBandwidth(Int(bandwidthKbps))

        // Clean up any previous state
        try? FileManager.default.removeItem(atPath: cmdFile)
        try? FileManager.default.removeItem(atPath: pidFile)

        // Create empty command file
        FileManager.default.createFile(atPath: cmdFile, contents: nil)

        // Shell script that sets up rules then polls for commands
        let helperScript = """
        /usr/sbin/dnctl pipe \(pipeNumber) config bw \(bwString)
        echo 'dummynet in proto { tcp, udp } from any to any pipe \(pipeNumber)
        dummynet out proto { tcp, udp } from any to any pipe \(pipeNumber)' | /sbin/pfctl -f -
        /sbin/pfctl -e 2>/dev/null || true
        echo $$ > \(pidFile)
        while true; do
            if [ -s \(cmdFile) ]; then
                cmd=$(cat \(cmdFile))
                > \(cmdFile)
                if [ \\"$cmd\\" = \\"EXIT\\" ]; then
                    /sbin/pfctl -f /etc/pf.conf 2>/dev/null || true
                    /usr/sbin/dnctl -q flush
                    rm -f \(cmdFile) \(pidFile)
                    exit 0
                fi
                eval \\"$cmd\\" 2>/dev/null
            fi
            sleep 0.2
        done
        """

        let appleScript = """
        do shell script "\(helperScript)" with administrator privileges
        """

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", appleScript]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice

            do {
                try process.run()
                self.helperProcess = process

                // Wait for helper to write its PID (indicates success)
                var attempts = 0
                while attempts < 20 {
                    Thread.sleep(forTimeInterval: 0.1)
                    if FileManager.default.fileExists(atPath: self.pidFile) {
                        DispatchQueue.main.async {
                            self.isEnabled = true
                            self.lastError = nil
                        }
                        return
                    }
                    attempts += 1
                }

                // If we get here, user likely cancelled the auth dialog
                DispatchQueue.main.async {
                    self.lastError = "Authentication cancelled"
                }
            } catch {
                DispatchQueue.main.async {
                    self.lastError = error.localizedDescription
                }
            }
        }
    }

    func disable() {
        sendCommand("EXIT")

        // Give it time to clean up, then force kill
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.helperProcess?.terminate()
            self?.helperProcess = nil
        }

        isEnabled = false
    }

    func updateBandwidth() {
        guard isEnabled else { return }

        let bwString = formatBandwidth(Int(bandwidthKbps))
        sendCommand("/usr/sbin/dnctl pipe \(pipeNumber) config bw \(bwString)")
    }

    private func sendCommand(_ command: String) {
        try? command.write(toFile: cmdFile, atomically: true, encoding: .utf8)
    }

    private func formatBandwidth(_ kbps: Int) -> String {
        if kbps >= 1000 {
            return "\(kbps / 1000)Mbit/s"
        }
        return "\(kbps)Kbit/s"
    }

    deinit {
        if isEnabled {
            sendCommand("EXIT")
            helperProcess?.terminate()
        }
    }
}

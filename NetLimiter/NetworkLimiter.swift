import Foundation

class NetworkLimiter: ObservableObject {
    @Published var isEnabled = false
    @Published var downloadKbps: Double = 100000
    @Published var uploadKbps: Double = 100000
    @Published var lastError: String?

    private var helperProcess: Process?
    private let cmdFile = "/tmp/netlimiter_cmd"
    private let pidFile = "/tmp/netlimiter_pid"

    func enable() {
        let downloadBw = formatBandwidth(Int(downloadKbps))
        let uploadBw = formatBandwidth(Int(uploadKbps))

        // Clean up any previous state
        try? FileManager.default.removeItem(atPath: cmdFile)
        try? FileManager.default.removeItem(atPath: pidFile)

        // Create empty command file
        FileManager.default.createFile(atPath: cmdFile, contents: nil)

        // Shell script that sets up rules then polls for commands
        // Pipe 1 = download (in), Pipe 2 = upload (out)
        let helperScript = """
        /usr/sbin/dnctl pipe 1 config bw \(downloadBw)
        /usr/sbin/dnctl pipe 2 config bw \(uploadBw)
        echo 'dummynet in proto { tcp, udp } from any to any pipe 1
        dummynet out proto { tcp, udp } from any to any pipe 2' | /sbin/pfctl -f -
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

    func updateDownload() {
        guard isEnabled else { return }
        let bw = formatBandwidth(Int(downloadKbps))
        sendCommand("/usr/sbin/dnctl pipe 1 config bw \(bw)")
    }

    func updateUpload() {
        guard isEnabled else { return }
        let bw = formatBandwidth(Int(uploadKbps))
        sendCommand("/usr/sbin/dnctl pipe 2 config bw \(bw)")
    }

    func updateBoth() {
        guard isEnabled else { return }
        let dlBw = formatBandwidth(Int(downloadKbps))
        let ulBw = formatBandwidth(Int(uploadKbps))
        sendCommand("/usr/sbin/dnctl pipe 1 config bw \(dlBw); /usr/sbin/dnctl pipe 2 config bw \(ulBw)")
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

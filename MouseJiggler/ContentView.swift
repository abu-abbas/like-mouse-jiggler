import SwiftUI
import AppKit
import CoreGraphics
import Observation

@MainActor
@Observable
final class JigglerModel {
    var isRunning = false
    var interval = 10.0
    var distance = 25.0

    private var jiggleTask: Task<Void, Never>?

    func toggle() {
        isRunning ? stop() : start()
    }

    func stop() {
        jiggleTask?.cancel()
        jiggleTask = nil
        isRunning = false
    }

    private func start() {
        if !CGPreflightPostEventAccess() {
            _ = CGRequestPostEventAccess()
        }

        isRunning = true
        jiggleTask = Task { [weak self] in
            await self?.jiggleUntilStopped()
        }
    }

    private func jiggleUntilStopped() async {
        var offset: CGFloat = 1

        while !Task.isCancelled {
            if let currentEvent = CGEvent(source: nil) {
                let currentLocation = currentEvent.location
                let nextLocation = CGPoint(
                    x: currentLocation.x + (offset * distance),
                    y: currentLocation.y
                )

                _ = CGWarpMouseCursorPosition(nextLocation)

                CGEvent(
                    mouseEventSource: nil,
                    mouseType: .mouseMoved,
                    mouseCursorPosition: nextLocation,
                    mouseButton: .left
                )?.post(tap: .cghidEventTap)

                offset *= -1
            }

            do {
                try await Task.sleep(for: .seconds(interval))
            } catch {
                return
            }
        }
    }
}

struct ContentView: View {
    @Bindable var model: JigglerModel

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: model.isRunning ? "cursorarrow.motionlines" : "cursorarrow")
                .font(.system(size: 44))
                .foregroundStyle(model.isRunning ? .green : .secondary)
                .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text(model.isRunning ? "Mouse Jiggler Aktif" : "Mouse Jiggler Berhenti")
                    .font(.title2.bold())

                Text(model.isRunning
                     ? "Pointer digerakkan sedikit setiap \(model.interval.formatted()) detik."
                     : "Aktifkan untuk menjaga sesi tetap berjalan.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Picker("Interval", selection: $model.interval) {
                Text("10 detik").tag(10.0)
                Text("30 detik").tag(30.0)
                Text("60 detik").tag(60.0)
            }
            .pickerStyle(.segmented)
            .disabled(model.isRunning)

            HStack {
                Text("Jarak gerak: \(model.distance.formatted()) px")
                MouseWheelStepper(
                    value: $model.distance,
                    isEnabled: !model.isRunning
                )
            }
            .help("Klik tombol panah atau gunakan scroll wheel.")

            Button(model.isRunning ? "Stop" : "Start") {
                model.toggle()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(model.isRunning ? .red : .accentColor)

            Divider()

            Button("Keluar") {
                model.stop()
                DispatchQueue.main.async {
                    NSApplication.shared.terminate(nil)
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 360)
    }
}

private struct MouseWheelStepper: NSViewRepresentable {
    @Binding var value: Double
    let isEnabled: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(value: $value)
    }

    func makeNSView(context: Context) -> WheelEnabledStepper {
        let stepper = WheelEnabledStepper()
        stepper.minValue = 1
        stepper.maxValue = 50
        stepper.increment = 1
        stepper.target = context.coordinator
        stepper.action = #selector(Coordinator.valueChanged(_:))
        return stepper
    }

    func updateNSView(_ stepper: WheelEnabledStepper, context: Context) {
        context.coordinator.value = $value
        stepper.doubleValue = value
        stepper.isEnabled = isEnabled
    }

    final class Coordinator: NSObject {
        var value: Binding<Double>

        init(value: Binding<Double>) {
            self.value = value
        }

        @objc func valueChanged(_ sender: NSStepper) {
            value.wrappedValue = sender.doubleValue
        }
    }
}

private final class WheelEnabledStepper: NSStepper {
    override func scrollWheel(with event: NSEvent) {
        guard isEnabled, event.scrollingDeltaY != 0 else { return }

        let change = event.scrollingDeltaY > 0 ? increment : -increment
        doubleValue = min(maxValue, max(minValue, doubleValue + change))
        sendAction(action, to: target)
    }
}

#Preview {
    ContentView(model: JigglerModel())
}

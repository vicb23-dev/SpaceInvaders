
import Foundation
import SwiftUI
import Combine
import CoreMotion

@MainActor
final class GameModel: ObservableObject {
    @Published var shipX: CGFloat = 0.5
    @Published var bullet: CGPoint?
    @Published var alive = Array(repeating: true, count: 5)
    @Published var score = 0
    @Published var paused = false
    @Published var useTilt = false
    @Published var sensorAvailable = false
    @Published var audioWarning: String?

    private let motion = CMMotionManager()
    private let sound = SoundPlayer()
    private var active = false
    private var lastTime: Date?

    // Lectura del giroscopio
    private var gyroAvailable = false
    private var lastRotation = CMRotationRate(x: 0, y: 0, z: 0)

    var won: Bool {
        alive.allSatisfy { !$0 }
    }

    func enemyX(_ index: Int) -> CGFloat {
        0.15 + CGFloat(index) * 0.175
    }

    func start() {
        do {
            try sound.prepare()
            audioWarning = nil
        } catch {
            audioWarning = error.localizedDescription
        }

        active = true
        lastTime = nil

        // Iniciar acelerómetro
        if motion.isAccelerometerAvailable {
            motion.accelerometerUpdateInterval = 1.0 / 60.0

            if !motion.isAccelerometerActive {
                motion.startAccelerometerUpdates()
            }

            sensorAvailable = true
        } else {
            sensorAvailable = false
            useTilt = false
        }

        // Iniciar giroscopio
        if motion.isGyroAvailable {
            motion.gyroUpdateInterval = 1.0 / 60.0

            if !motion.isGyroActive {
                motion.startGyroUpdates(to: .main) { [weak self] data, error in
                    guard let self = self,
                          let data = data,
                          error == nil else {
                        return
                    }

                    Task { @MainActor in
                        self.lastRotation = data.rotationRate
                    }
                }
            }

            gyroAvailable = true
        } else {
            gyroAvailable = false
        }
    }

    func stop() {
        active = false
        lastTime = nil

        motion.stopAccelerometerUpdates()
        motion.stopGyroUpdates()

        sound.stop()
    }

    func move(to x: CGFloat) {
        guard active, !paused, !won else { return }

        shipX = min(0.94, max(0.06, x))
    }

    func fire() {
        guard active, !paused, !won, bullet == nil else { return }

        bullet = CGPoint(x: shipX, y: 0.84)
        sound.play(.shot)
    }

    func reset() {
        shipX = 0.5
        bullet = nilgit push
        alive = Array(repeating: true, count: 5)
        score = 0
        paused = false
        lastTime = nil
    }

    func togglePause() {
        paused.toggle()
        lastTime = nil
    }

    /*
     Actualización del juego:
     - Movimiento de la nave.
     - Movimiento de la bala.
     - Detección de impactos.
     - Lectura del acelerómetro y giroscopio.
    */

    func tick(_ now: Date) {
        guard active, !paused, !won else {
            lastTime = nil
            return
        }

        let elapsed = now.timeIntervalSince(lastTime ?? now)
        let dt = CGFloat(min(0.05, max(0, elapsed)))
        lastTime = now

        // Control de la nave con acelerómetro
        if useTilt, sensorAvailable,
   let data = motion.accelerometerData {

    let sensitivity: CGFloat = 0.65
    let targetX = 0.5 + CGFloat(data.acceleration.x) * sensitivity

    let smoothFactor: CGFloat = 0.08

    let newX = shipX + (targetX - shipX) * smoothFactor

    move(to: newX)
}

        // Lectura del giroscopio
        if gyroAvailable {
            let rotationX = lastRotation.x
            let rotationY = lastRotation.y
            let rotationZ = lastRotation.z

            _ = rotationX
            _ = rotationY
            _ = rotationZ
        }

        guard var point = bullet else { return }

        let oldY = point.y
        point.y -= 0.9 * dt

        let path = CGRect(
            x: point.x - 0.01,
            y: min(point.y, oldY) - 0.02,
            width: 0.02,
            height: abs(oldY - point.y) + 0.04
        )

        for i in alive.indices where alive[i] {
            let target = CGRect(
                x: enemyX(i) - 0.05,
                y: 0.105,
                width: 0.10,
                height: 0.07
            )

            if path.intersects(target) {
                alive[i] = false
                score += 10
                bullet = nil
                sound.play(.explosion)
                return
            }
        }

        bullet = point.y < -0.02 ? nil : point
    }
}

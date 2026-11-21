
import Foundation
import AVFoundation

final class SoundPlayer {

    enum Effect {
        case shot
        case explosion
    }

    private var shotPlayer: AVAudioPlayer?
    private var explosionPlayer: AVAudioPlayer?

    func prepare() throws {

        let session = AVAudioSession.sharedInstance()

        // Configurar audio para que se escuche incluso
        // cuando el iPhone está en modo silencio.
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)

        if shotPlayer == nil {
            shotPlayer = try load("disparo", ext: "wav")
        }

        if explosionPlayer == nil {
            explosionPlayer = try load("explosion", ext: "mp3")
        }
    }

    private func load(
        _ name: String,
        ext: String
    ) throws -> AVAudioPlayer {

        guard let url = Bundle.main.url(
            forResource: name,
            withExtension: ext
        ) else {
            throw NSError(
                domain: "SpaceInvadersAudio",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "No se encontró \(name).\(ext) en la aplicación."
                ]
            )
        }

        let player = try AVAudioPlayer(contentsOf: url)
        player.volume = 1.0
        player.prepareToPlay()

        return player
    }

    func play(_ effect: Effect) {

        let player: AVAudioPlayer?

        switch effect {
        case .shot:
            player = shotPlayer

        case .explosion:
            player = explosionPlayer
        }

        guard let player = player else {
            return
        }

        player.stop()
        player.currentTime = 0
        player.play()
    }

    func stop() {
        shotPlayer?.stop()
        explosionPlayer?.stop()
    }
}
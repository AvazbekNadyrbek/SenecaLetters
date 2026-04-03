//
//  AudioService.swift
//  SenecaLetters
//
//  Created by Авазбек Надырбек уулу on 3/17/26.
//

import Foundation
import AVFoundation

// MARK: - AudioService — управляет аудиоплеером
// @Observable — View автоматически обновляется при изменении состояния
@MainActor
@Observable
class AudioService {
    
    // MARK: - Состояние плеера (View читает эти свойства)
    
    var isPlaying = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var playbackRate: Float = 1.0
    var currentLetterTitle: String = ""
    var currentLetterSubtitle: String = ""
    var isPlayerActive: Bool = false  // true после первого нажатия Play
    
    // Прогресс от 0.0 до 1.0 — для progress bar
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
    
    // Форматированное время "2:14"
    var currentTimeFormatted: String {
        formatTime(currentTime)
    }
    
    var durationFormatted: String {
        formatTime(duration)
    }
    
    // MARK: - Приватные свойства

    private var player: AVPlayer?
    private var timeObserver: Any?       // Следит за позицией каждую секунду

    init() {
        // Without .playback category, audio is silenced by the ringer/mute switch
        // and won't continue when the screen locks.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    // MARK: - Загрузить аудио
    // Вызывается когда юзер открывает письмо
    func load(urlString: String, localURL: URL? = nil, title: String, subtitle: String = "") {
        stop()
        currentLetterTitle = title
        currentLetterSubtitle = subtitle
        isPlayerActive = true

        // Use a locally downloaded file when available, otherwise stream from network.
        let url: URL
        if let local = localURL, FileManager.default.fileExists(atPath: local.path()) {
            url = local
        } else {
            let fullURLString = urlString.hasPrefix("http")
                ? urlString
                : Constants.baseURL + urlString
            guard let remote = URL(string: fullURLString) else { return }
            url = remote
        }
        
        // Создаём плеер
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        
        // Следим за позицией каждые 0.5 секунды
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self, weak item] time in
            guard let self, let item else { return }
            // queue: .main guarantees main-thread delivery; assumeIsolated encodes
            // that contract without spawning a new Task on every tick.
            MainActor.assumeIsolated {
                self.currentTime = time.seconds
                self.duration = item.duration.seconds.isNaN
                    ? 0
                    : item.duration.seconds
            }
        }
    }
    
    // MARK: - Play / Pause
    func togglePlayPause() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
        } else {
            player.rate = playbackRate
        }
        isPlaying.toggle()
    }
    
    // MARK: - Сменить скорость
    func cycleSpeed() {
        let speeds: [Float] = [0.75, 1.0, 1.25, 1.5, 2.0]
        
        // Находим следующую скорость
        if let index = speeds.firstIndex(of: playbackRate) {
            let next = (index + 1) % speeds.count
            playbackRate = speeds[next]
        } else {
            playbackRate = 1.0
        }
        
        // Если играет — применяем сразу
        if isPlaying {
            player?.rate = playbackRate
        }
    }
    
    // MARK: - Перемотка
    func seek(to progress: Double) {
        guard let player = player, duration > 0 else { return }
        let time = CMTime(seconds: progress * duration, preferredTimescale: 600)
        player.seek(to: time)
    }
    
    // MARK: - Стоп
    func stop() {
        player?.pause()
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        player = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        currentLetterTitle = ""
        currentLetterSubtitle = ""
    }
    
    // MARK: - Time formatting
    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite && time >= 0 else { return "0:00" }
        return Duration.seconds(time).formatted(.time(pattern: .minuteSecond))
    }
}

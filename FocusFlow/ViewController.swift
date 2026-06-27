//
//  ViewController.swift
//  FocusFlow
//
//  Created by Nguyễn Vạn An Phúc on 25/6/26.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    // IBOutlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var durationSlider: UISlider!
    @IBOutlet weak var soundSelector: UISegmentedControl!
    @IBOutlet weak var volumeLabel: UILabel!
    @IBOutlet weak var volumeSlider: UISlider!
    
    // IBActions
    @IBAction func startTapped(_ sender: UIButton) {
        if isRunning {
            return
        }
        if remainingSeconds == 0 {
            remainingSeconds = totalSeconds
            progressBar.progress = 0
            updateTimerLabel()
        }
        isRunning = true
        statusLabel.text = "Focusing"
        durationSlider.isEnabled = false
        
        playSelectedSound()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.handleTimerTick()
        }
        
    }
    @IBAction func pauseTapped(_ sender: UIButton) {
        if !isRunning {
            return
        }
        
        timer?.invalidate()
        timer = nil
        isRunning = false
        statusLabel.text = "Paused"
        durationSlider.isEnabled = false
        ambientPlayer?.pause()
    }
    @IBAction func resetTapped(_ sender: UIButton) {
        timer?.invalidate()
        timer = nil
        isRunning = false
        
        let selectedMinutes = Int(durationSlider.value)
        totalSeconds = selectedMinutes * 60
        remainingSeconds = totalSeconds
        progressBar.progress = 0
        statusLabel.text = "Ready"
        durationSlider.isEnabled = true
        updateTimerLabel()
        stopAmbientSound()
    }
    @IBAction func durationChanged(_ sender: UISlider) {
        let selectedMinutes = Int(sender.value)
        durationLabel.text = "Duration: \(selectedMinutes) min"
        totalSeconds = selectedMinutes * 60
        remainingSeconds = totalSeconds
        progressBar.progress = 0
        updateTimerLabel()
    }
    @IBAction func soundChanged(_ sender: UISegmentedControl) {
        if isRunning {
            playSelectedSound()
        } else {
            return
        }
    }
    @IBAction func volumeChanged(_ sender: UISlider) {
        updateVolume()
    }
    
    // Properties
    var timer: Timer?
    var totalSeconds = 25 * 60
    var remainingSeconds = 25 * 60
    var isRunning = false
    var ambientPlayer: AVAudioPlayer?
    
    // Initial UI setup
    
    private func setupInitialUI() {
        durationSlider.value = 25
        volumeSlider.value = 0.5
        let selectedMinutes = Int(durationSlider.value)
        totalSeconds = selectedMinutes * 60
        remainingSeconds = totalSeconds
        progressBar.progress = 0
        durationLabel.text = "Duration: \(selectedMinutes) min"
        statusLabel.text = "Ready"
        soundSelector.selectedSegmentIndex = 0
        updateTimerLabel()
    }
    
    private func updateTimerLabel() {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        timerLabel.text =  String(format: "%02d:%02d", minutes, seconds)
    }
    
    // startTapped helper
    private func handleTimerTick() {
        if remainingSeconds > 0 {
            remainingSeconds = remainingSeconds - 1
            updateTimerLabel()
            let elapsedSeconds = totalSeconds - remainingSeconds
            let progress = Float(elapsedSeconds) / Float(totalSeconds)
            progressBar.progress = progress
            
            if remainingSeconds == 0 {
                finishTimer()
            }
        } else {
            finishTimer()
        }
    }
    
    private func finishTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        statusLabel.text = "Complete"
        durationSlider.isEnabled = true
        progressBar.progress = 1
        stopAmbientSound()
    }
    
    // ambient sound helpers
    private func playSelectedSound() {
        let soundIndex = soundSelector.selectedSegmentIndex

        switch soundIndex {
        case 0:
            stopAmbientSound()
            return
        case 1, 2, 3:
            break
        default:
            print("Cannot find the requested audio")
            stopAmbientSound()
            return
        }

        let fileName: String
        switch soundIndex {
        case 1:
            fileName = "rain"
        case 2:
            fileName = "cafe"
        case 3:
            fileName = "white"
        default:
            // This path won't be hit due to the early return above, but keep for safety
            print("Invalid sound index")
            return
        }
        
        stopAmbientSound()

        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("Audio file not found: \(fileName).mp3")
            return
        }

        do {
            ambientPlayer = try AVAudioPlayer(contentsOf: url)
            ambientPlayer?.numberOfLoops = -1
            ambientPlayer?.volume = volumeSlider.value
            ambientPlayer?.play()
        } catch {
            print("Failed to play sound: \(error)")
        }
    }
    private func stopAmbientSound() {
        ambientPlayer?.stop()
        ambientPlayer = nil
    }
    private func updateVolume() {
        ambientPlayer?.volume = volumeSlider.value
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialUI()
        // Do any additional setup after loading the view.
    }


}

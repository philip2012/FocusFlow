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
        isPaused = false
        updateButtonStates()
        statusLabel.text = "Focusing"
        
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
        isPaused = true
        updateButtonStates()
        statusLabel.text = "Paused"
        ambientPlayer?.pause()
    }
    @IBAction func resetTapped(_ sender: UIButton) {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        updateButtonStates()
        
        let selectedMinutes = Int(durationSlider.value)
        totalSeconds = selectedMinutes * 60
        remainingSeconds = totalSeconds
        progressBar.progress = 0
        statusLabel.text = "Ready"
        updateTimerLabel()
        stopAmbientSound()
    }
    @IBAction func durationChanged(_ sender: UISlider) {
        let roundedValue = sender.value.rounded()
        sender.value = roundedValue
        let selectedMinutes = Int(roundedValue)
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
    var isPaused = false
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
        updateButtonStates()
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
        isPaused = false
        remainingSeconds = 0
        updateButtonStates()
        statusLabel.text = "Complete"
        progressBar.progress = 1
        stopAmbientSound()
        showCompletionAlert()
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
    
    // button state helper
    private func updateButtonStates() {
        if isRunning == true {
            startButton.isEnabled = false
            pauseButton.isEnabled = true
            resetButton.isEnabled = true
            durationSlider.isEnabled = false
        } else {
            startButton.isEnabled = true
            pauseButton.isEnabled = false
            resetButton.isEnabled = true
            
            if isPaused == true {
                durationSlider.isEnabled = false
            } else {
                durationSlider.isEnabled = true
            }
        }
    }
    
    // alert functionality
    private func showCompletionAlert() {
        if presentedViewController != nil {
            return
        }
        
        let alert = UIAlertController(title: "Focus session has ended", message: "Nice work. Take a break!", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    // style ui
    private func stylizeUI() {
        view.backgroundColor = .systemBackground // Supports light and dark mode
        
        // Typography & Label Styling
        titleLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold) // Adjusted to standard iOS Large Title size
        titleLabel.textColor = .label
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        
        statusLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        statusLabel.textColor = .secondaryLabel
        
        // Monospaced digits prevent the timer numbers from shifting layout as they change
        timerLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 76, weight: .semibold)
        timerLabel.textColor = .label
        
        // Progress Bar Styling
        progressBar.layer.cornerRadius = 4 // Subtler radius fits the progress bar width much better than 12
        progressBar.clipsToBounds = true
        progressBar.subviews.forEach { subview in
            subview.layer.cornerRadius = 4
            subview.clipsToBounds = true
        }
        
        // Button styling
        let controls: [(button: UIButton?, title: String, color: UIColor)] = [
            (startButton, "Start", .systemBlue),
            (pauseButton, "Pause", .systemOrange),
            (resetButton, "Reset", .systemGray)
        ]
        
        for case let (button?, title, themeColor) in controls {
            button.configuration = nil
            button.setTitle(title, for: .normal)
            button.layer.cornerRadius = 12
            button.clipsToBounds = true
            button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
            button.backgroundColor = themeColor
            button.setTitleColor(.white, for: .normal)
            button.setTitleColor(.systemGray3, for: .disabled)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialUI()
        stylizeUI()
        updateButtonStates()
        // Do any additional setup after loading the view.
    }


}

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
    @IBOutlet weak var mainVerticalStack: UIStackView!
    @IBOutlet weak var buttonRowStack: UIStackView!
    
    // Support UserDefaults
    // UsrDefault keys
    let durationKey = "durationKey"
    let soundKey = "selectedSoundIndex"
    let volumeKey = "volumeKey"
    
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
        saveSettings()
    }
    @IBAction func soundChanged(_ sender: UISegmentedControl) {
        saveSettings()
        if isRunning {
            playSelectedSound()
        }
    }
    @IBAction func volumeChanged(_ sender: UISlider) {
        updateVolume()
        saveSettings()
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
        loadSettings()
        statusLabel.text = "Ready"
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
        
        updateButtonAppearance()
    }
    
    private func updateButtonAppearance() {
        if startButton.isEnabled == true {
            startButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(1)
        } else {
            startButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
        }
        if pauseButton.isEnabled == true {
            pauseButton.backgroundColor = UIColor.systemOrange.withAlphaComponent(1)
        } else {
            pauseButton.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.8)
        }
        if resetButton.isEnabled == true {
            resetButton.backgroundColor = UIColor.systemGray.withAlphaComponent(1)
        } else {
            resetButton.backgroundColor = UIColor.systemGray.withAlphaComponent(0.8)
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
            button.setTitleColor(.white, for: .disabled)
        }
    }
    
    // This function will setup autolayout
    private func setupConstraints() {
        mainVerticalStack.axis = .vertical
        mainVerticalStack.alignment = .fill
        mainVerticalStack.distribution = .fill
        mainVerticalStack.spacing = 15
        mainVerticalStack.translatesAutoresizingMaskIntoConstraints = false
        
        buttonRowStack.axis = .horizontal
        buttonRowStack.alignment = .fill
        buttonRowStack.distribution = .fillEqually
        buttonRowStack.spacing = 14
        
        let labels = [
            titleLabel,
            statusLabel,
            timerLabel,
            durationLabel,
            volumeLabel,
        ]
        
        for label in labels {
            label?.textAlignment = .center
            label?.numberOfLines = 1
            label?.adjustsFontSizeToFitWidth = true
        }
        
        NSLayoutConstraint.activate([
            // layout for main vert stack
            mainVerticalStack.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            mainVerticalStack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            mainVerticalStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 32),
            mainVerticalStack.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -32),
            mainVerticalStack.widthAnchor.constraint(lessThanOrEqualToConstant: 390),
        ])
    }
    
    // Helper for UserDefaults
    private func saveSettings() {
        UserDefaults.standard.set(Int(durationSlider.value), forKey: durationKey)
        UserDefaults.standard.set(soundSelector.selectedSegmentIndex, forKey: soundKey)
        UserDefaults.standard.set(volumeSlider.value, forKey: volumeKey)
    }
    
    private func loadSettings() {
        var durationValue = UserDefaults.standard.integer(forKey: durationKey)
        
        if durationValue == 0 {
            durationValue = 25
        }
        let soundSelectedIndex = UserDefaults.standard.integer(forKey: soundKey)
        var volumeValue = UserDefaults.standard.float(forKey: volumeKey)
        
        if UserDefaults.standard.object(forKey: volumeKey) == nil {
            volumeValue = 0.5
        }
        
        totalSeconds = durationValue * 60
        remainingSeconds = totalSeconds
        durationLabel.text = "Duration: \(durationValue) min"
        progressBar.progress = 0
        volumeSlider.value = volumeValue
        durationSlider.value = Float(durationValue)
        soundSelector.selectedSegmentIndex = soundSelectedIndex
        updateTimerLabel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialUI()
        stylizeUI()
        setupConstraints()
        updateButtonStates()
        // Do any additional setup after loading the view.
    }


}

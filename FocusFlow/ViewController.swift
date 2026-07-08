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
    @IBOutlet weak var sessionsLabel: UILabel!
    @IBOutlet weak var resetSessionsButton: UIButton!
    @IBOutlet weak var contentCardView: UIView!
    @IBOutlet weak var sessionLengthLabel: UILabel!
    @IBOutlet weak var ambientSoundLabel: UILabel!
    
    // Support UserDefaults
    // UsrDefault keys
    let durationKey = "durationKey"
    let soundKey = "selectedSoundIndex"
    let volumeKey = "volumeKey"
    let completedSessionsKey = "completedSessions"
    
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
        
        completionPlayer?.stop()
        completionPlayer = nil
        
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
        
        completionPlayer?.stop()
        completionPlayer = nil
        
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = true
        updateButtonStates()
        statusLabel.text = "Paused"
        ambientPlayer?.pause()
    }
    @IBAction func resetTapped(_ sender: UIButton) {
        completionPlayer?.stop()
        completionPlayer = nil
        
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
    
    @IBAction func resetSessionsTapped(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "⚠️ Reset completed sessions?",
            message: "This will set your completed sessions back to 0.",
            preferredStyle: .alert
        )

        let resetAction = UIAlertAction(title: "Reset", style: .destructive) { (action) in
            self.completedSessions = 0
            UserDefaults.standard.set(0, forKey: self.completedSessionsKey)
            self.updateSessionsLabel()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alert.addAction(resetAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true)
    }
    
    // Properties
    var timer: Timer?
    var totalSeconds = 25 * 60
    var remainingSeconds = 25 * 60
    var isRunning = false
    var isPaused = false
    var ambientPlayer: AVAudioPlayer?
    var completionPlayer: AVAudioPlayer?
    var completedSessions = 0
    
    // Initial UI setup
    
    private func setupInitialUI() {
        loadSettings()
        loadCompletedSessions()
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
        playCompleteSound()
        incrementCompletedSessions()
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
    private func styleUI() {
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
        
        // separate resetSessionsButton styling
        resetSessionsButton.configuration = nil
        resetSessionsButton.setTitle("Reset Sessions", for: .normal)
        resetSessionsButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        resetSessionsButton.setTitleColor(.secondaryLabel, for: .normal)
        resetSessionsButton.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.65)
        resetSessionsButton.layer.cornerRadius = 10
        resetSessionsButton.clipsToBounds = true
        
        // content card styling
        contentCardView.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.66)
        contentCardView.layer.cornerRadius = 28
        contentCardView.layer.shadowColor = UIColor.black.cgColor
        contentCardView.layer.shadowOpacity = 0.08
        contentCardView.layer.shadowRadius = 20
        contentCardView.layer.shadowOffset = CGSize(width: 0, height: 10)
    }
    
    // Add gradient to FocusFlow app
    private var backgroundGradientLayer: CAGradientLayer?
    
    private func setupBackgroundGradient() {
        backgroundGradientLayer?.removeFromSuperlayer()

        let gradient = CAGradientLayer()
        // Using a Conic (angular) style creates beautiful sweep variances
        gradient.type = .conic
        
        gradient.colors = [
            UIColor.systemBackground.cgColor,
            UIColor.systemTeal.withAlphaComponent(0.12).cgColor,
            UIColor.systemBlue.withAlphaComponent(0.08).cgColor,
            UIColor.systemBackground.cgColor
        ]
        
        // Setting locations tightly creates defined but smooth shifts
        gradient.locations = [0.0, 0.35, 0.7, 1.0]
        
        // Move the center point off-canvas slightly to create a swept aura effect
        gradient.startPoint = CGPoint(x: 0.2, y: 0.2)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        
        gradient.frame = view.bounds

        view.layer.insertSublayer(gradient, at: 0)
        backgroundGradientLayer = gradient
    }
    
    // This function will setup autolayout
    private func setupConstraints() {
        mainVerticalStack.axis = .vertical
        mainVerticalStack.alignment = .fill
        mainVerticalStack.distribution = .fill
        mainVerticalStack.spacing = 12
        mainVerticalStack.translatesAutoresizingMaskIntoConstraints = false
        contentCardView.translatesAutoresizingMaskIntoConstraints = false
        
        mainVerticalStack.setCustomSpacing(24, after: timerLabel)
        mainVerticalStack.setCustomSpacing(22, after: buttonRowStack)
        mainVerticalStack.setCustomSpacing(18, after: volumeSlider)
        
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
            sessionsLabel,
            sessionLengthLabel,
            ambientSoundLabel,
        ]

        for label in labels {
            label?.textAlignment = .center
            label?.numberOfLines = 1
            label?.adjustsFontSizeToFitWidth = true
        }
        
        let sectionLabels = [
            sessionLengthLabel,
            ambientSoundLabel,
        ]

        for label in sectionLabels {
            label?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            label?.textColor = .secondaryLabel
        }
        
        NSLayoutConstraint.activate([
            // layout for main vert stack
            mainVerticalStack.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            mainVerticalStack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            mainVerticalStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 32),
            mainVerticalStack.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -32),
            mainVerticalStack.widthAnchor.constraint(lessThanOrEqualToConstant: 390),
            
            contentCardView.centerXAnchor.constraint(equalTo: mainVerticalStack.centerXAnchor),
            contentCardView.centerYAnchor.constraint(equalTo: mainVerticalStack.centerYAnchor),
            contentCardView.leadingAnchor.constraint(equalTo: mainVerticalStack.leadingAnchor, constant: -24),
            contentCardView.trailingAnchor.constraint(equalTo: mainVerticalStack.trailingAnchor, constant: 24),
            contentCardView.topAnchor.constraint(equalTo: mainVerticalStack.topAnchor, constant: -24),
            contentCardView.bottomAnchor.constraint(equalTo: mainVerticalStack.bottomAnchor, constant: 24),
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
    
    // completion helper
    private func playCompleteSound() {
        guard let url = Bundle.main.url(forResource: "complete", withExtension: "mp3") else {
            print("Cannot find complete.mp3")
            return
        }
        
        do {
            completionPlayer = try AVAudioPlayer(contentsOf: url)
            completionPlayer?.numberOfLoops = 0
            completionPlayer?.volume = 0.8
            completionPlayer?.play()
        } catch {
            print("Failed to play sound: \(error)")
        }
    }
    
    private func loadCompletedSessions() {
        completedSessions = UserDefaults.standard.integer(forKey: completedSessionsKey)
        updateSessionsLabel()
    }
    
    private func incrementCompletedSessions() {
        completedSessions += 1
        UserDefaults.standard.set(completedSessions, forKey: completedSessionsKey)
        updateSessionsLabel()
    }
    
    private func updateSessionsLabel() {
        sessionsLabel.text = "Focus Sessions: \(completedSessions)"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialUI()
        setupBackgroundGradient()
        styleUI()
        setupConstraints()
        updateButtonStates()
        // Do any additional setup after loading the view.
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradientLayer?.frame = view.bounds
    }
}

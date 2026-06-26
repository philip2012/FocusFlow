//
//  ViewController.swift
//  FocusFlow
//
//  Created by Nguyễn Vạn An Phúc on 25/6/26.
//

import UIKit

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
        isRunning = true
        statusLabel.text = "Focusing"
        durationSlider.isEnabled = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.handleTimerTick()
        }
        
    }
    @IBAction func pauseTapped(_ sender: UIButton) {
        
    }
    @IBAction func resetTapped(_ sender: UIButton) {
        
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
        
    }
    @IBAction func volumeChanged(_ sender: UISlider) {
        
    }
    
    // Properties
    var timer: Timer?
    var totalSeconds = 25 * 60
    var remainingSeconds = 25 * 60
    var isRunning = false
    
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialUI()
        // Do any additional setup after loading the view.
    }


}


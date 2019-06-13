//
//  ViewController.swift
//  AudioRecordThirtySeconds
//
//  Created by Nelson Gonzalez on 6/13/19.
//  Copyright © 2019 Nelson Gonzalez. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playBackButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer?
    var isGoingToPlayBack = true
    
    let countdown = Countdown()
    
    var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "ss"//"HH:mm:ss.SS"
        formatter.timeZone = TimeZone.init(secondsFromGMT: 0)
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        
        countdown.duration = 30 //seconds
        countdown.delegate = self
        
        timeLabel.font = .monospacedDigitSystemFont(ofSize: timeLabel.font.pointSize, weight: .regular)
        
    }
    
    private func updateViews() {
    
        timeLabel.text = string(from: countdown.timeRemaining)
        
        switch countdown.state {
        case .reset:
            timeLabel.text = string(from: countdown.duration)
        case .started:
            timeLabel.text = string(from: countdown.timeRemaining)
        case .finished:
            timeLabel.text = string(from: 0)
        }
        
    }
    
    func string(from duration: TimeInterval) -> String {
        let date = Date(timeIntervalSinceReferenceDate: duration)
        return dateFormatter.string(from: date)
    }
    
    
    // MARK: - Helper methods
    
    private func configure() {
        // Disable Stop/Play button when application launches
        cancelButton.isEnabled = false
        playBackButton.isEnabled = false
        
        // Get the document directory. If fails, just skip the rest of the code
        guard let directoryURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first else {
            
            let alertMessage = UIAlertController(title: "Error", message: "Failed to get the document directory for recording the audio. Please try again later.", preferredStyle: .alert)
            alertMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertMessage, animated: true, completion: nil)
            
            return
        }
        
        // Set the default audio file
        let audioFileURL = directoryURL.appendingPathComponent("MyAudioMemo.m4a")
        
        // Setup audio session
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [ .defaultToSpeaker ])
           
            // Define the recorder setting
            let recorderSetting: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            // Initiate and prepare the recorder
            audioRecorder = try AVAudioRecorder(url: audioFileURL, settings: recorderSetting)
            audioRecorder.delegate = self
            audioRecorder.isMeteringEnabled = true
            audioRecorder.prepareToRecord()
            
        } catch {
            print(error)
        }
    }
    

    @IBAction func recordButtonPressed(_ sender: UIButton) {
        // Stop the audio player before recording
        if let player = audioPlayer, player.isPlaying {
            player.stop()
        }
        
        if !audioRecorder.isRecording {
            let audioSession = AVAudioSession.sharedInstance()
            
            do {
                try audioSession.setActive(true)
                
                // Start recording
                //audioRecorder.record()
               audioRecorder.record(forDuration: 30)
                //startTimer()
                countdown.start()
                
                // Change to the Pause image
               // recordButton.setImage(UIImage(named: "Pause"), for: UIControl.State.normal)
            } catch {
                print(error)
            }
            
        } else {
            // Pause recording
            audioRecorder.pause()
          //  pauseTimer()
            
            
            // Change to the Record image
           // recordButton.setImage(UIImage(named: "Record"), for: UIControl.State.normal)
        }
        
        cancelButton.isEnabled = true
        playBackButton.isEnabled = false
    }
    @IBAction func playButtonPressed(_ sender: UIButton) {
        
        if isGoingToPlayBack {

            audioPlayer = playback()
            audioPlayer?.delegate = self
            audioPlayer?.play()
            countdown.start()
            isGoingToPlayBack = false
            playBackButton.setTitle("Stop", for: .normal)
      
        } else {

            audioPlayer = playback()
            audioPlayer?.delegate = self
            audioPlayer?.pause()
            countdown.pause()
            isGoingToPlayBack = true
            playBackButton.setTitle("Play Back", for: .normal)
        }
    }
    
    private func playback() -> AVAudioPlayer? {
        var avPlayer: AVAudioPlayer?
        if !audioRecorder.isRecording {
            guard let player = try? AVAudioPlayer(contentsOf: audioRecorder.url) else {
                print("Failed to initialize AVAudioPlayer")
                return nil
            }
            avPlayer = player
        }
        return avPlayer
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
       // recordButton.setImage(UIImage(named: "Record"), for: UIControl.State.normal)
        recordButton.isEnabled = true
        cancelButton.isEnabled = false
        playBackButton.isEnabled = true
        
        // Stop the audio recorder
        audioRecorder?.stop()

        countdown.reset()
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setActive(false)
        } catch {
            print(error)
        }
    }
    
}


// MARK: - Extension

extension ViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            let alertMessage = UIAlertController(title: "Finish Recording", message: "Successfully recorded the audio!", preferredStyle: .alert)
            alertMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertMessage, animated: true, completion: nil)
            playBackButton.isEnabled = true
            cancelButton.isEnabled = false
        }
    }
}

extension ViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playBackButton.isSelected = false
     
        countdown.reset()
        
        let alertMessage = UIAlertController(title: "Finish Playing", message: "Finish playing the recording!", preferredStyle: .alert)
        alertMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertMessage, animated: true, completion: nil)
    }
}

extension ViewController: CountdownDelegate {
    func countdownDidUpdate(timeRemaining: TimeInterval) {
        updateViews()
    }
    
    func countdownDidFinish() {
      //  showAlert()
        print("Finished")
    }
}

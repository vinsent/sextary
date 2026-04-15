import Foundation
import Combine
import AVFoundation
import Speech

final class ChatViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var messages: [ChatMessage] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var hasAPIKey: Bool = false
    @Published var isRecording: Bool = false
    @Published var recordingLevel: Float = 0.0
    @Published var recordingCancelled: Bool = false
    @Published var recognizedText: String = ""
    
    private var apiKey: String? = nil
    private var apiService: KimiAPIService? = nil
    private let keychainManager: KeychainManager
    private var audioRecorder: AVAudioRecorder?
    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isCancelledByUser: Bool = false
    private var thinkingTimer: Timer?
    private var isThinkingAnimationRunning: Bool = false
    
    init(apiService: KimiAPIService? = nil, keychainManager: KeychainManager = KeychainManager.shared) {
        self.apiService = apiService
        self.keychainManager = keychainManager
        initializeMessages()
        checkAPIKeyStatus()
    }
    
    func configApiKey(_ key: String) {
        self.apiKey = key
        self.apiService = KimiAPIService(with: key)
        self.hasAPIKey = true
    }
    
    func checkAPIKeyStatus() {
        self.hasAPIKey = keychainManager.getAPIKey() != nil
        if let apiKey = keychainManager.getAPIKey() {
            self.apiKey = apiKey
            self.apiService = KimiAPIService(with: apiKey)
        }
    }
    
    private func initializeMessages() {
        messages.append(ChatMessage(content: "Hello! I'm your AI assistant. How can I help you today?", isUser: false))
    }
    
    func sendMessage() {
        guard !inputText.isEmpty, let apiService = apiService else { return }
        
        // Add user message
        let userMessage = ChatMessage(content: inputText, isUser: true)
        messages.append(userMessage)
        
        // Clear input field
        let messageText = inputText
        inputText = ""
        
        // Show loading status
        isLoading = true
        errorMessage = ""
        
        // Add assistant message placeholder
        let placeholderMessage = ChatMessage(content: "thinking", isUser: false)
        messages.append(placeholderMessage)
        
        // Start thinking animation
        // Use DispatchQueue.main.asyncAfter instead of Timer to ensure the animation triggers correctly
        DispatchQueue.main.async {
            self.isThinkingAnimationRunning = true
            self.animateThinkingDots(dotsCount: 1)
        }
        
        // Send message to Kimi API
        Task {
            do {
                let messagesForAPI = [
                    Message.system("You are a helpful AI assistant that responds to user queries in a friendly and informative manner."),
                    Message.user(messageText)
                ]
                
                let stream = try await apiService.stream(messagesForAPI)
                
                // Handle streaming response
                var accumulatedContent = ""
                for try await chunk in stream {
                    accumulatedContent += chunk
                    
                    // Update assistant message
                    await MainActor.run {
                        if let lastIndex = messages.indices.last, !messages[lastIndex].isUser {
                            messages[lastIndex] = ChatMessage(content: accumulatedContent, isUser: false)
                        }
                        
                        // Stop thinking animation
                        if self.isThinkingAnimationRunning {
                            self.isThinkingAnimationRunning = false
                        }
                    }
                }
            } catch {
                // Stop thinking animation
                await MainActor.run {
                    thinkingTimer?.invalidate()
                    self.isThinkingAnimationRunning = false
                }
                
                await MainActor.run {
                    errorMessage = "Error: \(error.localizedDescription)"
                    // Remove placeholder message
                    if let lastIndex = messages.indices.last, !messages[lastIndex].isUser {
                        messages.removeLast()
                    }
                }
            }
            
            // Close loading status regardless of success or failure
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied:
                    self.errorMessage = "Speech recognition denied"
                case .restricted:
                    self.errorMessage = "Speech recognition restricted"
                case .notDetermined:
                    self.errorMessage = "Speech recognition not determined"
                @unknown default:
                    self.errorMessage = "Speech recognition error"
                }
            }
        }
    }
    
    func startRecording() {
        // Request speech recognition authorization
        requestSpeechAuthorization()
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Audio session setup error: \(error.localizedDescription)"
            return
        }
        
        // Create audio engine
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        // Initialize speech recognizer
        if speechRecognizer == nil {
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        // Set speech recognition task hint to help recognize punctuation
        if #available(iOS 13.0, *) {
            recognitionRequest.taskHint = .dictation
        }
        
        // Check if speech recognizer is available
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognizer not available"
            return
        }
        
        // Create recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                // Ignore "No speech detected" error
                if error.localizedDescription != "No speech detected" {
                    print("Speech recognition error: \(error.localizedDescription)")
                }
                return
            }
            
            if let result = result {
                let recognizedText = result.bestTranscription.formattedString
                // Add punctuation to recognition result
                let textWithPunctuation = addPunctuation(to: recognizedText)
                DispatchQueue.main.async {
                    self.recognizedText = textWithPunctuation
                }
            }
        }
        
        // Configure audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Install audio input processing
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, when in
            guard let self = self else { return }
            
            // Calculate volume level
            let level = self.calculateLevel(buffer: buffer)
            DispatchQueue.main.async {
                self.recordingLevel = level
            }
            
            // Add audio data to recognition request
            self.recognitionRequest?.append(buffer)
        }
        
        // Start audio engine
        do {
            try audioEngine.start()
            isRecording = true
            isCancelledByUser = false
            recordingCancelled = false
        } catch {
            errorMessage = "Audio engine start error: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        // Stop audio engine
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        // End recognition request
        recognitionRequest?.endAudio()
        
        // Cancel recognition task
        recognitionTask?.cancel()
        
        // Reset state
        isRecording = false
        recordingLevel = 0.0
        
        // If the user didn't cancel recording, send message
        if !isCancelledByUser && !recognizedText.isEmpty {
            // Add punctuation to recognition result
            let textWithPunctuation = addPunctuation(to: recognizedText)
            inputText = textWithPunctuation
            sendMessage()
        }
        
        // Clear recognition result
        recognizedText = ""
    }
    
    func cancelRecording() {
        guard isRecording else { return }
        
        // Mark as user cancelled
        isCancelledByUser = true
        recordingCancelled = true
        
        // Stop recording
        stopRecording()
        
        // Clear input text and recognition result
        inputText = ""
        recognizedText = ""
    }
    
    private func calculateLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0.0 }
        
        let channelCount = buffer.format.channelCount
        let frameLength = UInt(buffer.frameLength)
        
        var channelLevels: [Float] = []
        
        for channel in 0..<Int(channelCount) {
            let channelDataPtr = channelData[channel]
            var sum: Float = 0.0
            
            for frame in 0..<Int(frameLength) {
                sum += abs(channelDataPtr[frame])
            }
            
            let average = sum / Float(frameLength)
            let level = 20 * log10(average + 0.0001)
            channelLevels.append(max(0, min(1, (level + 60) / 60)))
        }
        
        return channelLevels.reduce(0, +) / Float(channelLevels.count)
    }
    
    // Add punctuation to recognition result
    private func addPunctuation(to text: String) -> String {
        var result = text
        
        // Remove extra spaces
        result = result.trimmingCharacters(in: .whitespaces)
        
        // If text is empty, return directly
        if result.isEmpty {
            return result
        }
        
        // Detect text language
        let isChinese = result.range(of: "[\u{4e00}-\u{9fa5}]", options: .regularExpression) != nil
        
        // Handle Chinese text
        if isChinese {
            // Handle comma addition
            let greetings = ["你好", "您好", "早上好", "下午好", "晚上好"]
            for greeting in greetings {
                if result.contains(greeting) {
                    // Only add comma after greeting if there's no punctuation
                    let pattern = "\\Q" + greeting + "\\E([^,，.。!?！？]*)$"
                    let regex = try? NSRegularExpression(pattern: pattern, options: [])
                    if let regex = regex {
                        let range = NSRange(location: 0, length: result.utf16.count)
                        if regex.matches(in: result, options: [], range: range).count > 0 {
                            // Only add comma after greeting if there's no punctuation
                            let lastIndex = result.index(result.endIndex, offsetBy: -1)
                            let lastChar = result[lastIndex]
                            if ![",", "，", ".", "。", "!", "！", "?", "？"].contains(lastChar) {
                                result = result.replacingOccurrences(of: greeting, with: greeting + "，")
                            }
                        }
                    }
                }
            }
            
            // Remove duplicate commas
            result = result.replacingOccurrences(of: ",,", with: ",")
            result = result.replacingOccurrences(of: "，，", with: "，")
            
            // Check if there's already punctuation
            let lastChar = result.last
            let hasPunctuation = lastChar?.isPunctuation ?? false
            if !hasPunctuation {
                // Check if it's a question
                let questionWords = ["什么", "怎么", "为什么", "哪", "谁", "吗", "呢", "吧"]
                let isQuestion = questionWords.contains { result.contains($0) }
                
                if isQuestion {
                    result += "？"
                } else {
                    result += "。"
                }
            }
        } 
        // Handle English text
        else {
            // Check if there's already punctuation
            let lastChar = result.last
            let hasPunctuation = lastChar?.isPunctuation ?? false
            if !hasPunctuation {
                // Check if it's a question
                let questionWords = ["what", "how", "why", "where", "who", "when", "is", "are", "do", "does", "did"]
                let lowercaseResult = result.lowercased()
                let isQuestion = questionWords.contains { lowercaseResult.hasPrefix($0 + " ") || lowercaseResult.contains(" " + $0 + " ") }
                
                if isQuestion {
                    result += "?"
                } else {
                    result += "."
                }
            }
        }
        
        return result
    }
    
    // Thinking animation
    private func animateThinkingDots(dotsCount: Int) {
        // Check if animation needs to continue
        guard isLoading && isThinkingAnimationRunning else { return }
        
        // Update dotsCount
        let newDotsCount = dotsCount % 3 + 1
        let dots = String(repeating: ".", count: newDotsCount)
        
        // Update UI
        if let lastIndex = messages.indices.last, !messages[lastIndex].isUser {
            messages[lastIndex] = ChatMessage(content: "thinking\(dots)", isUser: false)
        }
        
        // Delay 0.5 seconds before continuing animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Check again if animation should continue
            if self.isLoading && self.isThinkingAnimationRunning {
                self.animateThinkingDots(dotsCount: newDotsCount)
            }
        }
    }
}

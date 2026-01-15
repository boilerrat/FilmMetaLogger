import Foundation
import Speech

final class SpeechTranscriber: ObservableObject {
    @Published private(set) var lastError: Error?
    private let recognizer: SFSpeechRecognizer?

    init(locale: Locale = Locale(identifier: "en_US")) {
        recognizer = SFSpeechRecognizer(locale: locale)
    }

    func requestAuthorization(completion: @escaping (SFSpeechRecognizerAuthorizationStatus) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status)
            }
        }
    }

    func transcribeAudio(at url: URL, completion: @escaping (String?) -> Void) {
        guard let recognizer else {
            completion(nil)
            return
        }

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false

        recognizer.recognitionTask(with: request) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error {
                    self?.lastError = error
                    completion(nil)
                    return
                }

                if let result, result.isFinal {
                    completion(result.bestTranscription.formattedString)
                }
            }
        }
    }
}

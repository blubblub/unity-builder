#!/usr/bin/swift

import Foundation

// MARK: - Models and Types

struct UnityCredentials {
    let email: String
    let password: String
    let serial: String
}

enum ActivationError: Error, LocalizedError {
    case missingEnvironmentVariable(String)
    case directoryCreationFailed(String)
    case unityActivationFailed(Int32)
    case invalidCredentialsFormat
    
    var errorDescription: String? {
        switch self {
        case .missingEnvironmentVariable(let variable):
            return "Missing environment variable: \(variable)"
        case .directoryCreationFailed(let path):
            return "Failed to create directory: \(path)"
        case .unityActivationFailed(let exitCode):
            return "Unity activation failed with exit code: \(exitCode)"
        case .invalidCredentialsFormat:
            return "Invalid credentials format"
        }
    }
}

// MARK: - Unity Activator Class

class UnityActivator {
    private let environment = ProcessInfo.processInfo.environment
    private let fileManager = FileManager.default
    
    // Environment variables
    private var activateLicensePath: String {
        return environment["ACTIVATE_LICENSE_PATH"] ?? ""
    }
    
    private var unityVersion: String {
        return environment["UNITY_VERSION"] ?? ""
    }
    
    private var unityCredentials: String? {
        return environment["UNITY_CREDENTIALS"]
    }
    
    private var unityEmail: String? {
        return environment["UNITY_EMAIL"]
    }
    
    private var unityPassword: String? {
        return environment["UNITY_PASSWORD"]
    }
    
    private var unitySerial: String? {
        return environment["UNITY_SERIAL"]
    }
    
    func run() throws {
        print("Starting Unity license activation...")
        
        // Ensure project directory structure exists
        try createDirectoryStructure()
        
        // Change to activation directory
        let originalPath = fileManager.currentDirectoryPath
        print("Changing to \"\(activateLicensePath)\" directory.")
        fileManager.changeCurrentDirectoryPath(activateLicensePath)
        
        defer {
            // Return to original directory
            fileManager.changeCurrentDirectoryPath(originalPath)
        }
        
        var success = false
        
        // Try activation with bulk credentials first, then fallback to single credentials
        if let bulkCredentials = unityCredentials, !bulkCredentials.isEmpty {
            print("Requesting activation with array of credentials...")
            success = try activateWithBulkCredentials(bulkCredentials)
        } else {
            print("Requesting activation with default credentials")
            print("Bulk credentials are empty: \(unityCredentials ?? "nil")")
            success = try activateWithSingleCredentials()
        }
        
        if success {
            print("License activation successful.")
        } else {
            print("Unclassified error occurred while trying to activate license.")
            print("::error ::There was an error while trying to activate the Unity license.")
            exit(1)
        }
    }
    
    private func createDirectoryStructure() throws {
        guard !activateLicensePath.isEmpty else {
            throw ActivationError.missingEnvironmentVariable("ACTIVATE_LICENSE_PATH")
        }
        
        let assetsPath = "\(activateLicensePath)/Assets"
        
        // Create main directory
        if !fileManager.fileExists(atPath: activateLicensePath) {
            try fileManager.createDirectory(atPath: activateLicensePath, withIntermediateDirectories: true)
        }
        
        // Create Assets directory
        if !fileManager.fileExists(atPath: assetsPath) {
            try fileManager.createDirectory(atPath: assetsPath, withIntermediateDirectories: true)
        }
    }
    
    private func activateWithBulkCredentials(_ credentialsString: String) throws -> Bool {
        let credentials = parseBulkCredentials(credentialsString)
        
        for credential in credentials {
            print("Trying to activate license for \(credential.email)")
            
            let exitCode = try executeUnityActivation(credential)
            
            if exitCode == 0 {
                // Export environment variables for license cleanup
                setEnvironmentVariable("UNITY_EMAIL", value: credential.email)
                setEnvironmentVariable("UNITY_PASSWORD", value: credential.password)
                setEnvironmentVariable("UNITY_SERIAL", value: credential.serial)
                
                let cleanedEmail = credential.email.replacingOccurrences(of: "@", with: "AT")
                print("Activation complete with credentials: \(cleanedEmail)")
                return true
            }
        }
        
        return false
    }
    
    private func activateWithSingleCredentials() throws -> Bool {
        guard let email = unityEmail,
              let password = unityPassword,
              let serial = unitySerial else {
            throw ActivationError.missingEnvironmentVariable("UNITY_EMAIL, UNITY_PASSWORD, or UNITY_SERIAL")
        }
        
        let credentials = UnityCredentials(email: email, password: password, serial: serial)
        let exitCode = try executeUnityActivation(credentials)
        
        return exitCode == 0
    }
    
    private func executeUnityActivation(_ credentials: UnityCredentials) throws -> Int32 {
        let unityPath = "/Applications/Unity/Hub/Editor/\(unityVersion)/Unity.app/Contents/MacOS/Unity"
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: unityPath)
        process.arguments = [
            "-logFile", "-",
            "-batchmode",
            "-nographics",
            "-quit",
            "-serial", credentials.serial,
            "-username", credentials.email,
            "-password", credentials.password,
            "-projectPath", activateLicensePath
        ]
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus
        } catch {
            print("Failed to execute Unity: \(error)")
            throw ActivationError.unityActivationFailed(-1)
        }
    }
    
    private func parseBulkCredentials(_ credentialsString: String) -> [UnityCredentials] {
        var credentials: [UnityCredentials] = []
        
        // Split by double newlines to get blocks
        let blocks = credentialsString.components(separatedBy: "\n\n")
        
        for block in blocks {
            let lines = block.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            var email = ""
            var password = ""
            var serial = ""
            
            for line in lines {
                let components = line.components(separatedBy: ":")
                guard components.count >= 2 else { continue }
                
                let key = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let value = components.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespacesAndNewlines)
                
                switch key {
                case "EMAIL":
                    email = value
                case "PASS":
                    password = value
                case "SERIAL":
                    serial = value
                default:
                    continue
                }
            }
            
            if !email.isEmpty && !password.isEmpty && !serial.isEmpty {
                credentials.append(UnityCredentials(email: email, password: password, serial: serial))
            }
        }
        
        return credentials
    }
    
    private func setEnvironmentVariable(_ key: String, value: String) {
        setenv(key, value, 1)
    }
}

// MARK: - Main Execution

do {
    let activator = UnityActivator()
    try activator.run()
} catch {
    print("Error: \(error.localizedDescription)")
    if let activationError = error as? ActivationError,
       case .unityActivationFailed(let exitCode) = activationError {
        exit(exitCode)
    } else {
        exit(1)
    }
}

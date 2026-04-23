// Services/UserNameService.swift
import Foundation

enum UserNameService {
    private static let key = "userName"

    static var name: String {
        get { UserDefaults.standard.string(forKey: key) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    static var hasName: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
}

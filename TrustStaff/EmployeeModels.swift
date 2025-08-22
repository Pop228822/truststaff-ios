import Foundation

struct EmployeeResponse: Decodable, Identifiable {
    let id: Int
    let full_name: String
    let birth_date: String
    let record_count: Int
    let contact: String?
    var records: [ReputationRecord]
    let add_record_link: String?
}

struct ReputationRecord: Codable, Identifiable {
    let id: Int
    let is_blocked_employer: Bool?
    let blocked_message: String?
    let employer_id: Int?
    let position: String?
    let hired_at: String?
    let fired_at: String?
    let misconduct: String?
    let dismissal_reason: String?
    let commendation: String?
}

struct ReputationRecordOut: Codable {
    let is_blocked_employer: Bool
    let blocked_message: String?
    let employer_id: Int?
    let position: String?
    let hired_at: String?
    let fired_at: String?
    let misconduct: String?
    let dismissal_reason: String?
    let commendation: String?
}

struct EmployeeSearchResult: Identifiable, Codable {
    let employee_id: Int
    var id: Int { employee_id } // Уникальный id
    let full_name: String
    let birth_date: String
    let record_count: Int
    let records: [ReputationRecordOut]?
}

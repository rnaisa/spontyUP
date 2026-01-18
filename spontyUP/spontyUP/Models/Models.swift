//
//  Models.swift
//  spontyUP
//
//  Created by HSLU-N0004887 on 01.12.2024.
//

import Foundation

struct Profile: Decodable, Identifiable, Hashable {
    let id: UUID
    let username: String
    let fullName: String?
    let registered: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case registered
    }
}

struct UpdateProfileParams: Encodable {
    let username: String
    let fullName: String

    enum CodingKeys: String, CodingKey {
        case username
        case fullName = "full_name"
    }
}

struct UpdateEventParams: Encodable {
    let title: String
    let description: String
    let date: Date
    let location: String
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case date = "event_date"
        case location
    }
}

struct RegisterProfileParams: Encodable {
    let username: String
    let fullName: String
    let registered: Bool

    enum CodingKeys: String, CodingKey {
        case username
        case fullName = "full_name"
        case registered
    }
}

struct Friendship: Decodable, Identifiable, Hashable {
    let userId: UUID
    let friendId: UUID
    let friendUsername: String
    let friendshipId: UUID

    var id: UUID {
        return self.friendshipId
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case friendId = "friend_id"
        case friendUsername = "friend_username"
        case friendshipId = "friendship_id"
    }
}

struct FriendshipWithProfile: Identifiable {
    let friendship: Friendship
    let profile: Profile
    
    var id: UUID {
        return UUID()
    }
}

enum EventStatus: String, Decodable {
    case draft = "Draft"
    case published = "Published"
    case cancelled = "Cancelled"
    case deleted = "Deleted"
}

struct Event: Decodable, Identifiable {
    let id: UUID
    let eventTitle: String
    let eventCreatorUserId: UUID
    let eventDate: Date
    let eventStatus: String
    let eventLocation: String
    let eventDescription: String
    let isOpenCircle: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case eventTitle = "title"
        case eventCreatorUserId = "user_id"
        case eventDate = "event_date"
        case eventStatus = "status"
        case eventLocation = "location"
        case eventDescription = "description"
        case isOpenCircle = "is_open_circle"
    }
}

struct CreateEventParams: Encodable {
    let userId: UUID
    let eventTitle: String
    let eventDate: Date
    let eventLocation: String
    let eventDescription: String
    let isOpenCircle: Bool
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case eventTitle = "title"
        case eventDate = "event_date"
        case eventLocation = "location"
        case eventDescription = "description"
        case isOpenCircle = "is_open_circle"
    }
}

enum InvitationStatus: String, Decodable, Encodable {
    case pending = "Pending"
    case accepted = "Accepted"
    case declined = "Declined"
    case tentative = "Tentative"
}

struct Invitation: Decodable, Identifiable {
    let id: UUID
    let eventId: UUID
    let senderId: UUID
    let receiverId: UUID
    let status: InvitationStatus

    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case status
    }
}

struct EventWithInvitations: Identifiable, Hashable {
    let event: Event
    let invitations: [Invitation]
    let isCurrentUserHost: Bool
    
    var id: UUID {
        return event.id
    }
    
    static func == (lhs: EventWithInvitations, rhs: EventWithInvitations) -> Bool {
        lhs.event.id == rhs.event.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(event.id)
    }
}


enum FriendRequestStatus: String, Decodable, Encodable {
    case pending = "Pending"
    case accepted = "Accepted"
    case declined = "Declined"
}

struct FriendRequest: Decodable, Identifiable {
    let id: UUID
    let senderId: UUID
    let receiverId: UUID
    let status: FriendRequestStatus

    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case status
    }
}

struct sendFriendRequestParams: Encodable {
    let senderId: UUID
    let receiverId: UUID
    
    enum CodingKeys: String, CodingKey {
        case senderId = "sender_id"
        case receiverId = "receiver_id"
    }
}

struct UpdateFriendRequestParams: Encodable {
    let senderId: UUID
    let receiverId: UUID
    let status: FriendRequestStatus
    
    enum CodingKeys: String, CodingKey {
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case status
    }
}

struct FriendGroup: Decodable, Identifiable {
    let id: UUID
    let userId: UUID
    let name: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
    }
}

struct CreateFriendGroupParams: Encodable {
    let userId: UUID
    let name: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name
    }
}

struct GroupMember: Decodable, Identifiable {
    let id: UUID
    let groupId: UUID
    let friendId: UUID
    let friendshipId: UUID

    enum CodingKeys: String, CodingKey {
        case id
        case groupId = "group_id"
        case friendId = "friend_id"
        case friendshipId = "friendship_id"
    }
}

struct CreateGroupMemberParams: Encodable {
    let groupId: UUID
    let friendId: UUID
    let friendshipId: UUID

    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case friendId = "friend_id"
        case friendshipId = "friendship_id"
    }
}

struct GroupMemberWithProfile: Identifiable {
    let groupMember: GroupMember
    let profile: Profile
    
    var id: UUID {
        return UUID()
    }
}

struct FriendRequestWithProfile: Identifiable {
    let friendRequest: FriendRequest
    let profile: Profile
    
    var id: UUID {
        return UUID()
    }
}

struct CreateInvitationParams: Encodable {
    let eventId: UUID
    let senderId: UUID
    let receiverId: UUID

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case senderId = "sender_id"
        case receiverId = "receiver_id"
    }
}

struct UpdateInvitationParams: Encodable {
    let eventId: UUID
    let senderId: UUID
    let receiverId: UUID
    let status: InvitationStatus

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case status
    }
}


//
//  Handler.swift
//  spontyUP
//
//  Created by HSLU-N0004887 on 01.12.2024.
//

import Foundation
import Supabase

@Observable
@MainActor
class SupabaseHandler {
    static let shared = SupabaseHandler()

    var client: SupabaseClient
    var auth: AuthClient

    var currentUserProfile: Profile? = nil
    var friendsList: [FriendshipWithProfile] = []
    var groupsList: [FriendGroup] = []
    var friendRequestsList: [FriendRequestWithProfile] = []
    var sentFriendRequestsProfileList: [Profile] = []
    var inboxEventsWithInvitationsList: [EventWithInvitations] = []
    var eventsList: [Event] = []
    var userInvitationsList: [Invitation] = []
    var eventsWithInvitiationsList: [EventWithInvitations] = []
    var hostedEventsWithInvitationsList: [EventWithInvitations] = []

    var isRegistered: Bool = false

    private init() {
        let url = Secrets.supabaseURL
        let key = Secrets.supabaseKey

        guard let supabaseURL = URL(string: url) else {
            fatalError("Invalid Supabase URL: \(url)")
        }

        let client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: key)
        self.client = client
        self.auth = client.auth
    }

    /// Fetches and validates an environment variable
    /// - Parameter key: The name of the environment variable
    /// - Returns: The non-empty value of the environment variable
    private static func getEnvironmentVariable(_ key: String) -> String {
        guard let value = ProcessInfo.processInfo.environment[key],
            !value.isEmpty
        else {
            fatalError("Missing or empty environment variable: \(key)")
        }
        return value
    }

    public func getCurrentUser() async -> User? {
        do {
            return try await auth.session.user
        } catch {
            print("Failed to fetch the current user: \(error)")
            return nil
        }
    }

    public func getProfile(userId: UUID) async throws -> Profile {
        do {
            let profile: Profile =
                try await client
                .from("profiles")
                .select("*")
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            return profile
        } catch {
            print("Failed to fetch profile: \(error)")
            throw error
        }
    }

    func ensureCurrentUser() async throws -> User {
        guard let currentUser = await getCurrentUser() else {
            throw NSError(
                domain: "No user session found", code: 401, userInfo: nil)
        }
        return currentUser
    }

    public func updateRegistrationStatus() async throws {
        self.isRegistered = try await checkUserRegistration()
    }

    public func updateFriendsList() async throws {
        let friends = try await fetchFriendshipsWithProfiles()
        self.friendsList = friends
    }

    public func updateGroupsList() async throws {
        let groups = try await fetchGroups()
        self.groupsList = groups
    }

    public func updateFriendRequestsList() async throws {
        let friendRequests = try await fetchPendingFriendRequestsWithProfiles()
        self.friendRequestsList = friendRequests
    }
    
    public func updateSentFriendRequestsList() async throws {
        let friendRequests = try await fetchSentFriendRequestsProfiles()
        self.sentFriendRequestsProfileList = friendRequests
    }

    public func updateEventsList() async throws {
        let events = try await fetchEvents()
        self.eventsList = events
    }

    public func updateUserInvitationsList() async throws {
        let userInvitiatons = try await fetchUserInvitations()
        self.userInvitationsList = userInvitiatons
    }

    public func updateEventsWithInvitationsList() async throws {
        let eventsWithInvitations = try await fetchEventsWithInvitations()
        self.eventsWithInvitiationsList = eventsWithInvitations
    }

    public func updateInboxEventsWithInvitationsList() async throws {
        let inboxEventsWithInvitations =
            try await fetchInboxEventsWithInvitations()
        self.inboxEventsWithInvitationsList = inboxEventsWithInvitations
    }

    public func updateHostedEventsWithInvitationsList() async throws {
        let hostedEventsWithInvitations =
            try await fetchHostedEventsWithInvitations()
        self.hostedEventsWithInvitationsList = hostedEventsWithInvitations
    }

    // Update current user profile (username, fullname)
    public func updateCurrentUserProfileVariable() async throws {
        let currentUserProfile = try await fetchCurrentUserProfile()
        self.currentUserProfile = currentUserProfile
    }

    // get the current user
    public func fetchCurrentUserProfile() async throws -> Profile {
        guard let currentUser = await getCurrentUser() else {
            throw NSError(
                domain: "No user session found", code: 401, userInfo: nil)
        }

        do {
            // Fetch the user's profile from the database
            let userProfile: Profile =
                try await client
                .from("profiles")
                .select()
                .eq("id", value: currentUser.id)
                .single()
                .execute()
                .value

            // Store the profile in the handler
            return userProfile
        } catch {
            print("Failed to fetch user profile: \(error)")
            throw error
        }
    }

    // Sign in
    public func signIn(email: String, password: String) async throws {
        try await auth.signIn(email: email, password: password)
    }

    // Sign out
    public func signOut() async throws {
        try await auth.signOut()

    }

    // Sign up
    public func signUp(email: String, password: String) async throws {
        try await auth.signUp(email: email, password: password)
    }

    // Update current user profile (username, fullname)
    public func updateCurrentUserProfile(
        username: String, fullName: String
    ) async throws {
        let currentUser = try await ensureCurrentUser()

        // Perform the update
        do {
            try await client
                .from("profiles")
                .update(
                    UpdateProfileParams(
                        username: username,
                        fullName: fullName
                    )
                )
                .eq("id", value: currentUser.id)
                .execute()
        } catch {
            // Log and rethrow the error for the caller to handle
            print(
                "Failed to update profile for user \(currentUser.id): \(error)")
            throw error
        }
    }

    // register current user profile
    public func registerCurrentUserProfile(
        username: String, fullName: String
    ) async throws {
        let currentUser = try await ensureCurrentUser()

        // Perform the update
        do {
            try await client
                .from("profiles")
                .update(
                    RegisterProfileParams(
                        username: username,
                        fullName: fullName,
                        registered: true
                    )
                )
                .eq("id", value: currentUser.id)
                .execute()

        } catch {
            // Log and rethrow the error for the caller to handle
            print(
                "Failed to register profile for user \(currentUser.id): \(error)"
            )
            throw error
        }
    }

    private func checkUserRegistration() async throws -> Bool {
        guard let currentUser = await getCurrentUser() else {
            throw NSError(
                domain: "No user session found", code: 401, userInfo: nil)
        }

        do {
            let userProfile: Profile =
                try await client
                .from("profiles")
                .select()
                .eq("id", value: currentUser.id)
                .single()
                .execute()
                .value

            let isUserRegistered: Bool = userProfile.registered
            return isUserRegistered
        } catch {
            print(
                "Failed to check if user \(currentUser.id) is registered: \(error)"
            )
            throw error
        }
    }

    // fetch all friends of current user
    private func fetchFriends() async throws -> [Friendship] {

        let currentUser = try await ensureCurrentUser()

        do {
            let friends: [Friendship] =
                try await client
                .from("friendships_view")
                .select()
                .eq("user_id", value: currentUser.id)
                .execute()
                .value
            return friends
        } catch {
            print(
                "Failed to fetch friends for user \(currentUser.id): \(error)")
            throw error
        }

    }

    public func fetchFriendshipsWithProfiles() async throws
        -> [FriendshipWithProfile]
    {
        _ = try await ensureCurrentUser()

        do {
            // Fetch group members
            let friendships: [Friendship] = try await fetchFriends()

            // Extract the friend IDs
            let friendIds = friendships.map { $0.friendId }  // Replace `friendId` with the actual column name

            // Fetch profiles based on the friend IDs
            let profiles: [Profile] =
                try await client
                .from("profiles")
                .select()
                .in("id", values: friendIds)
                .execute()
                .value

            // Create a dictionary for fast lookup
            let profileDict = Dictionary(
                uniqueKeysWithValues: profiles.map { ($0.id, $0) })

            // Combine GroupMember and Profile into GroupMemberWithProfile
            let combined: [FriendshipWithProfile] = friendships.compactMap {
                friendship in
                guard let profile = profileDict[friendship.friendId] else {
                    return nil  // Skip if the profile is not found
                }
                return FriendshipWithProfile(
                    friendship: friendship, profile: profile)
            }

            return combined
        } catch {
            print("Failed to fetch friendships with profiles: \(error)")
            throw error
        }
    }
    
    // Define a custom error for better clarity
    enum FetchProfileError: Error {
        case isAlreadyCurrentUser
    }
    
    public func fetchFriendshipsWithProfileOfUser(userId: UUID) async throws
        -> FriendshipWithProfile
    {
        let currentUser = try await ensureCurrentUser()
        
        guard currentUser.id != userId else {
            throw FetchProfileError.isAlreadyCurrentUser
        }

        do {

            // Fetch profiles based on the friend IDs
            let profile: Profile = try await getProfile(userId: userId)
            
            let friendship: Friendship =
                try await client
                .from("friendships_view")
                .select("*")
                .eq("user_id", value: currentUser.id)
                .eq("friend_id", value: userId)
                .single()
                .execute()
                .value

            return FriendshipWithProfile(friendship: friendship, profile: profile)
        } catch {
            print("Failed to fetch friendships with profiles: \(error)")
            throw error
        }
    }

    public func fetchFriendshipsWithProfilesInGroup(group: FriendGroup)
        async throws -> [FriendshipWithProfile]
    {
        _ = try await ensureCurrentUser()

        do {
            // Step 1: Fetch friendships with profiles using the existing function
            let allFriendshipsWithProfiles =
                try await fetchFriendshipsWithProfiles()

            // Step 2: Fetch group members for the given group
            let groupMembers: [GroupMember] =
                try await client
                .from("group_members")
                .select()
                .eq("group_id", value: group.id)
                .execute()
                .value

            // Extract the user IDs of group members
            let memberIds = groupMembers.map { $0.friendshipId }

            // Step 3: Filter friendships to include only those in the group
            let filteredFriendshipsWithProfiles =
                allFriendshipsWithProfiles.filter { friendshipWithProfile in
                    memberIds.contains(friendshipWithProfile.friendship.id)
                }

            return filteredFriendshipsWithProfiles
        } catch {
            print(
                "Failed to fetch friendships with profiles in group: \(error)")
            throw error
        }
    }
    
    public func fetchFriendshipsWithProfilesAddedToEvent(eventId: UUID)
        async throws -> [FriendshipWithProfile]
    {
        let currentUser = try await ensureCurrentUser()

        do {
            // Step 1: Fetch friendships with profiles using the existing function
            let allFriendshipsWithProfiles =
                try await fetchFriendshipsWithProfiles()

            // Step 2: Fetch invitations for given event and currentuser as sendeer
            let invitedMembers: [Invitation] =
                try await client
                .from("invitations")
                .select()
                .eq("event_id", value: eventId)
                .eq("sender_id", value: currentUser.id)
                .execute()
                .value

            // Extract the user IDs of invited users
            let invitedIds = invitedMembers.map { $0.receiverId }

            // Step 3: Filter friendships to include only those invited to specified event
            let filteredFriendshipsWithProfiles =
                allFriendshipsWithProfiles.filter { friendshipWithProfile in
                    invitedIds.contains(friendshipWithProfile.profile.id)
                }

            return filteredFriendshipsWithProfiles
        } catch {
            print(
                "Failed to fetch friendships with profiles in event: \(error)")
            throw error
        }
    }

    // fetch all groups of current user
    private func fetchGroups() async throws -> [FriendGroup] {

        let currentUser = try await ensureCurrentUser()

        do {
            let groups: [FriendGroup] =
                try await client
                .from("groups")
                .select()
                .eq("user_id", value: currentUser.id)
                .execute()
                .value
            return groups
        } catch {
            print("Failed to fetch groups for user \(currentUser.id): \(error)")
            throw error
        }

    }

    // fetch all groups of current user
    public func fetchGroupsOfFriend(friend: FriendshipWithProfile) async throws
        -> [FriendGroup]
    {

        _ = try await ensureCurrentUser()

        do {
            let groups: [FriendGroup] = try await fetchGroups()

            // Extract the group ids
            let groupIds = groups.map { $0.id }

            // Fetch profiles based on the friend IDs
            let groupMembers: [GroupMember] =
                try await client
                .from("group_members")
                .select()
                .in("group_id", values: groupIds)
                .eq("friend_id", value: friend.profile.id)
                .execute()
                .value

            let groupOfFriendIds = groupMembers.map { $0.groupId }

            let groupsToReturn: [FriendGroup] =
                try await client
                .from("groups")
                .select()
                .in("id", values: groupOfFriendIds)
                .execute()
                .value

            return groupsToReturn
        } catch {
            print(
                "Failed to fetch groups for user \(friend.profile.id): \(error)"
            )
            throw error
        }

    }

    // fetch all friend requests of current user
    private func fetchFriendRequests() async throws -> [FriendRequest] {

        let currentUser = try await ensureCurrentUser()

        do {
            let requests: [FriendRequest] =
                try await client
                .from("friend_requests")
                .select()
                .eq("receiver_id", value: currentUser.id)
                .execute()
                .value
            return requests
        } catch {
            print(
                "Failed to fetch friend requests for user \(currentUser.id): \(error)"
            )
            throw error
        }

    }

    // fetch all friend requests of current user
    private func fetchPendingFriendRequests() async throws -> [FriendRequest] {

        let currentUser = try await ensureCurrentUser()

        do {
            let requests: [FriendRequest] =
                try await client
                .from("friend_requests")
                .select()
                .eq("receiver_id", value: currentUser.id)
                .eq("status", value: "Pending")
                .execute()
                .value
            return requests
        } catch {
            print(
                "Failed to fetch friend requests for user \(currentUser.id): \(error)"
            )
            throw error
        }

    }

    public func updateFriendRequestWithProfile(
        friendRequest: FriendRequest, status: FriendRequestStatus
    ) async throws {

        _ = try await ensureCurrentUser()

        do {
            try await client
                .from("friend_requests")
                .update(
                    UpdateFriendRequestParams(
                        senderId: friendRequest.senderId,
                        receiverId: friendRequest.receiverId,
                        status: status
                    )
                )
                .eq("id", value: friendRequest.id)
                .execute()
        }
    }

    // fetch all friend requests of current user
    private func fetchFriendRequestsWithProfiles() async throws
        -> [FriendRequestWithProfile]
    {

        let currentUser = try await ensureCurrentUser()

        do {
            // Fetch group members
            let friendRequests: [FriendRequest] =
                try await fetchFriendRequests()

            // Extract the friend IDs
            let senderIds = friendRequests.map { $0.senderId }  // Replace `friendId` with the actual column name

            // Fetch profiles based on the friend IDs
            let profiles: [Profile] =
                try await client
                .from("profiles")
                .select()
                .in("id", values: senderIds)
                .execute()
                .value

            // Create a dictionary for fast lookup
            let profileDict = Dictionary(
                uniqueKeysWithValues: profiles.map { ($0.id, $0) })

            // Combine GroupMember and Profile into GroupMemberWithProfile
            let combined: [FriendRequestWithProfile] = friendRequests.compactMap
            { request in
                guard let profile = profileDict[request.senderId] else {
                    return nil  // Skip if the profile is not found
                }
                return FriendRequestWithProfile(
                    friendRequest: request, profile: profile)
            }

            return combined
        } catch {
            print(
                "Failed to fetch friend requests for user \(currentUser.id): \(error)"
            )
            throw error
        }

    }

    // fetch all pending friend requests of current user
    private func fetchPendingFriendRequestsWithProfiles() async throws
        -> [FriendRequestWithProfile]
    {

        let currentUser = try await ensureCurrentUser()

        do {
            // Fetch group members
            let friendRequests: [FriendRequest] =
                try await fetchPendingFriendRequests()

            // Extract the friend IDs
            let senderIds = friendRequests.map { $0.senderId }  // Replace `friendId` with the actual column name

            // Fetch profiles based on the friend IDs
            let profiles: [Profile] =
                try await client
                .from("profiles")
                .select()
                .in("id", values: senderIds)
                .execute()
                .value

            // Create a dictionary for fast lookup
            let profileDict = Dictionary(
                uniqueKeysWithValues: profiles.map { ($0.id, $0) })

            // Combine GroupMember and Profile into GroupMemberWithProfile
            let combined: [FriendRequestWithProfile] = friendRequests.compactMap
            { request in
                guard let profile = profileDict[request.senderId] else {
                    return nil  // Skip if the profile is not found
                }
                return FriendRequestWithProfile(
                    friendRequest: request, profile: profile)
            }

            return combined
        } catch {
            print(
                "Failed to fetch friend requests for user \(currentUser.id): \(error)"
            )
            throw error
        }

    }
    
    // fetch all pending friend requests of current user
    private func fetchSentFriendRequestsProfiles() async throws
        -> [Profile]
    {

        let currentUser = try await ensureCurrentUser()

        do {
            // Fetch group members
            let friendRequests: [FriendRequest] =
            try await client
            .from("friend_requests")
            .select()
            .eq("sender_id", value: currentUser.id)
            .execute()
            .value

            // Extract the friend IDs
            let receiverIds = friendRequests.map { $0.receiverId }

            // Fetch profiles based on the friend IDs
            let profiles: [Profile] =
                try await client
                .from("profiles")
                .select()
                .in("id", values: receiverIds)
                .execute()
                .value

            return profiles
        } catch {
            print(
                "Failed to fetch sent friend requests profiles for user \(currentUser.id): \(error)"
            )
            throw error
        }

    }

    public func sendFriendRequest(receiverId: UUID) async throws {
        let currentUser = try await ensureCurrentUser()

        do {
            // Insert members into the group_members table
            try await client
                .from("friend_requests")
                .insert(
                    sendFriendRequestParams(
                        senderId: currentUser.id, receiverId: receiverId)
                )
                .execute()
        } catch {
            print("Failed to create group members: \(error)")
            throw error
        }

    }

    // fetch invitiations of current user
    private func fetchUserInvitations() async throws -> [Invitation] {
        let currentUser = try await ensureCurrentUser()

        do {
            // Fetch event IDs
            let invitations: [Invitation] =
                try await client
                .from("invitations")
                .select()
                .eq("receiver_id", value: currentUser.id)
                .execute()
                .value

            return invitations
        } catch {
            print("Failed to fetch invitations: \(error)")
            throw error
        }
    }

    // fetch invitiations of current user
    private func fetchInboxInvitations() async throws -> [Invitation] {
        let currentUser = try await ensureCurrentUser()

        do {
            // Fetch event IDs
            let invitations: [Invitation] =
                try await client
                .from("invitations")
                .select()
                .eq("receiver_id", value: currentUser.id)
                .eq("status", value: "Pending")
                .execute()
                .value

            return invitations
        } catch {
            print("Failed to fetch pending invitations: \(error)")
            throw error
        }
    }

    private func fetchEventInvitations(eventId: UUID) async throws
        -> [Invitation]
    {
        _ = try await ensureCurrentUser()

        do {
            // Fetch event IDs
            let invitations: [Invitation] =
                try await client
                .from("invitations")
                .select()
                .eq("event_id", value: eventId)
                .execute()
                .value

            return invitations
        } catch {
            print("Failed to fetch invitations: \(error)")
            throw error
        }
    }
    
    private func fetchEventInvitationsSentByCurrentUser(eventId: UUID) async throws
        -> [Invitation]
    {
        _ = try await ensureCurrentUser()

        do {
            // Fetch event IDs
            let invitations: [Invitation] =
                try await client
                .from("invitations")
                .select()
                .eq("event_id", value: eventId)
                .execute()
                .value

            return invitations
        } catch {
            print("Failed to fetch invitations: \(error)")
            throw error
        }
    }

    // fetch events from database
    // TODO: implement so only the events relevant to current user are fetched and displayed
    private func fetchEvents() async throws -> [Event] {
        _ = try await ensureCurrentUser()

        do {
            // Fetch event IDs
            let invitations: [Invitation] = try await fetchUserInvitations()

            let eventIds = invitations.map { $0.eventId }

            // Fetch events using the IDs
            let events: [Event] =
                try await client
                .from("events")
                .select()
                .in("id", values: eventIds)
                .execute()
                .value

            return events
        } catch {
            print("Failed to fetch events: \(error)")
            throw error
        }
    }
    

    public func fetchEventById(eventId: UUID) async throws -> Event {
        _ = try await ensureCurrentUser()

        do {
            // Fetch events using the IDs
            let event: Event =
                try await client
                .from("events")
                .select("*")
                .eq("id", value: eventId)
                .single()
                .execute()
                .value

            return event
        } catch {
            print("Failed to fetch single event: \(error)")
            throw error
        }
    }

    private func fetchEventInvitations(eventIds: [UUID]) async throws -> [UUID:
        [Invitation]]
    {
        _ = try await ensureCurrentUser()

        do {
            // Fetch all invitations for the given event IDs
            let allInvitations: [Invitation] =
                try await client
                .from("invitations")
                .select()
                .in("event_id", values: eventIds)
                .execute()
                .value

            // Group invitations by event_id
            let groupedInvitations = Dictionary(
                grouping: allInvitations, by: { $0.eventId })
            return groupedInvitations
        } catch {
            print("Failed to fetch invitations from event array: \(error)")
            throw error
        }
    }

    private func fetchPendingEventInvitations(eventIds: [UUID]) async throws
        -> [UUID:
        [Invitation]]
    {
        _ = try await ensureCurrentUser()

        do {
            // Fetch all invitations for the given event IDs
            let allInvitations: [Invitation] =
                try await client
                .from("invitations")
                .select()
                .in("event_id", values: eventIds)
                .eq("status", value: "Pending")
                .execute()
                .value

            // Group invitations by event_id
            let groupedInvitations = Dictionary(
                grouping: allInvitations, by: { $0.eventId })
            return groupedInvitations
        } catch {
            print("Failed to fetch invitations from event array: \(error)")
            throw error
        }
    }

    private func fetchEventsWithInvitations() async throws
        -> [EventWithInvitations]
    {
        _ = try await ensureCurrentUser()

        do {
            //Fetch user invitations to get relevant event IDs
            let userInvitations: [Invitation] = try await fetchUserInvitations()
            let invitedEventIds = userInvitations.map { $0.eventId }

            // Fetch events created by the current user
            let createdEvents: [Event] = try await fetchHostedEvents()
            let createdEventIds = createdEvents.map { $0.id }

            // Combine the invited event IDs and created event IDs
            let eventIds = invitedEventIds + createdEventIds

            // Fetch the events using the IDs
            let events: [Event] =
                try await client
                .from("events")
                .select()
                .in("id", values: eventIds)
                .execute()
                .value

            // Fetch invitations grouped by event ID
            let invitationsByEvent = try await fetchEventInvitations(
                eventIds: eventIds)

            // Combine events and their invitations
            let eventsWithInvitations: [EventWithInvitations] = events.map {
                event in
                let invitations = invitationsByEvent[event.id] ?? []
                let isHost = createdEventIds.contains(event.id)
                return EventWithInvitations(
                    event: event,
                    invitations: invitations,
                    isCurrentUserHost: isHost
                )
            }

            return eventsWithInvitations
        } catch {
            print("Failed to fetch events with invitations: \(error)")
            throw error
        }
    }
    
    public func fetchEventWithInvitations(event: Event) async throws
        -> EventWithInvitations
    {
        let currentUser = try await ensureCurrentUser()

        do {

            // Fetch the events using the IDs
            let fetchedEvent: Event =
                try await client
                .from("events")
                .select("*")
                .eq("id", value: event.id)
                .single()
                .execute()
                .value

            // Fetch invitations grouped by event ID
            let invitationsByEvent = try await fetchEventInvitations(eventId: event.id)

            // Combine events and their invitations
            let eventWithInvitations: EventWithInvitations =
               EventWithInvitations(
                    event: fetchedEvent,
                    invitations: invitationsByEvent,
                    isCurrentUserHost: fetchedEvent.eventCreatorUserId == currentUser.id
                )
            return eventWithInvitations
            } catch {
            print("Failed to fetch invitations for event: \(error)")
            throw error
        }
    }
    
    public func fetchEventWithInvitations(eventId: UUID) async throws
        -> EventWithInvitations
    {
        let currentUser = try await ensureCurrentUser()

        do {

            // Fetch the events using the IDs
            let fetchedEvent: Event =
                try await client
                .from("events")
                .select("*")
                .eq("id", value: eventId)
                .single()
                .execute()
                .value

            // Fetch invitations grouped by event ID
            let invitationsByEvent = try await fetchEventInvitations(eventId: eventId)

            // Combine events and their invitations
            let eventWithInvitations: EventWithInvitations =
               EventWithInvitations(
                    event: fetchedEvent,
                    invitations: invitationsByEvent,
                    isCurrentUserHost: fetchedEvent.eventCreatorUserId == currentUser.id
                )
            return eventWithInvitations
            } catch {
            print("Failed to fetch invitations for event: \(error)")
            throw error
        }
    }

    private func fetchInboxEventsWithInvitations() async throws
        -> [EventWithInvitations]
    {
        _ = try await ensureCurrentUser()

        do {
            //Fetch user invitations to get relevant event IDs
            let userInvitations: [Invitation] =
                try await fetchInboxInvitations()
            let invitedEventIds = userInvitations.map { $0.eventId }

            // Combine the invited event IDs and created event IDs
            let eventIds = invitedEventIds

            // Fetch the events using the IDs
            let events: [Event] =
                try await client
                .from("events")
                .select()
                .in("id", values: eventIds)
                .execute()
                .value

            // Fetch invitations grouped by event ID
            let invitationsByEvent = try await fetchPendingEventInvitations(
                eventIds: eventIds)

            // Combine events and their invitations
            let eventsWithInvitations: [EventWithInvitations] = events.map {
                event in
                let invitations = invitationsByEvent[event.id] ?? []
                let isHost = false
                return EventWithInvitations(
                    event: event,
                    invitations: invitations,
                    isCurrentUserHost: isHost
                )
            }

            return eventsWithInvitations
        } catch {
            print("Failed to fetch events with invitations: \(error)")
            throw error
        }
    }

    private func fetchHostedEventsWithInvitations() async throws
        -> [EventWithInvitations]
    {
        _ = try await ensureCurrentUser()

        do {
            // Fetch events created by the current user
            let createdEvents: [Event] = try await fetchHostedEvents()

            // Fetch invitations grouped by event ID for these created events
            let eventIds = createdEvents.map { $0.id }
            let invitationsByEvent = try await fetchEventInvitations(
                eventIds: eventIds)

            // Combine events and their invitations
            let eventsWithInvitations: [EventWithInvitations] =
                createdEvents.map { event in
                    let invitations = invitationsByEvent[event.id] ?? []
                    return EventWithInvitations(
                        event: event,
                        invitations: invitations,
                        isCurrentUserHost: true  // All events here are created by the user
                    )
                }

            return eventsWithInvitations
        } catch {
            print("Failed to fetch user-created events: \(error)")
            throw error
        }
    }

    public func fetchHostedEvents() async throws -> [Event] {
        let currentUser = try await ensureCurrentUser()

        do {
            // Fetch events using the IDs
            let events: [Event] =
                try await client
                .from("events")
                .select()
                .eq("user_id", value: currentUser.id)
                .execute()
                .value

            return events
        } catch {
            print("Failed to fetch created events: \(error)")
            throw error
        }
    }

    // create new event in database
    public func createEvent(
        title: String, date: Date, location: String, description: String, isOpenCircle: Bool
    ) async throws {
        let currentUser = try await ensureCurrentUser()

        do {
            try await client
                .from("events")
                .insert(
                    CreateEventParams(
                        userId: currentUser.id,
                        eventTitle: title,
                        eventDate: date,
                        eventLocation: location,
                        eventDescription: description,
                        isOpenCircle: isOpenCircle
                    )
                )
                .execute()
        } catch {
            print("Failed to create event: \(error)")
            throw error
        }

    }

    // Update an existing event in the database
    public func updateEvent(
        id: UUID,
        title: String,
        date: Date,
        location: String,
        description: String
    ) async throws {
        // Create the update parameters
        let updates = UpdateEventParams(
            title: title,
            description: description,
            date: date,
            location: location
        )

        do {
            // Perform the update
            try await client
                .from("events")
                .update(updates)
                .eq("id", value: id.uuidString)  // Ensure UUID is passed correctly
                .execute()
        } catch {
            print("Failed to update event \(id): \(error)")
            throw error
        }
    }

    // Update event details
    public func updateEventDetails(eventId: UUID) async throws
        -> EventWithInvitations
    {
        let event: Event =
            try await client
            .from("events")
            .select()
            .eq("id", value: eventId.uuidString)
            .single()
            .execute()
            .value

        let invitations: [Invitation] = try await fetchEventInvitations(
            eventId: event.id)

        // fetch current user ID
        let currentUserId = try await ensureCurrentUser().id
        let isCurrentUserHost = event.eventCreatorUserId == currentUserId

        return EventWithInvitations(
            event: event,
            invitations: invitations,
            isCurrentUserHost: isCurrentUserHost
        )
    }

    // cancel the event
    public func cancelEvent(eventId: UUID) async throws {
        let updates = ["status": "Cancelled"]
        try await client
            .from("events")
            .update(updates)
            .eq("id", value: eventId.uuidString)
            .execute()
    }

    // create new event in database
    public func createAndReturnEvent(
        title: String, date: Date, location: String, description: String,
        isOpenCircle: Bool
    ) async throws -> Event {
        let currentUser = try await ensureCurrentUser()

        do {
            let event: Event =
                try await client
                .from("events")
                .insert(
                    CreateEventParams(
                        userId: currentUser.id,
                        eventTitle: title,
                        eventDate: date,
                        eventLocation: location,
                        eventDescription: description,
                        isOpenCircle: isOpenCircle
                    )
                )
                .select("*")  // To return the inserted object
                .single()
                .execute()
                .value

            return event
        } catch {
            print("Failed to create and return event: \(error)")
            throw error
        }

    }

    public func createInvitation(members: [CreateInvitationParams]) async throws
    {
        _ = try await ensureCurrentUser()

        // Ensure the members array is not empty
        guard !members.isEmpty else {
            throw InvitationError.emptyMembersList
        }

        do {
            // Insert members into the group_members table
            try await client
                .from("invitations")
                .insert(members)
                .execute()
        } catch {
            print("Failed to create invitations: \(error)")
            throw error
        }
    }
    
    public func createInvitation(eventId: UUID, members: Set<UUID>) async throws
    {
        let currentUser = try await ensureCurrentUser()

        // Ensure the members array is not empty
        guard !members.isEmpty else {
            throw InvitationError.emptyMembersList
        }

        do {
            let membersToInvite = members.map {
                CreateInvitationParams(eventId: eventId, senderId: currentUser.id, receiverId: $0)
            }
            
            // Insert members into the group_members table
            try await client
                .from("invitations")
                .insert(membersToInvite)
                .execute()
        } catch {
            print("Failed to create invitations from eventId and UUID set: \(error)")
            throw error
        }
    }

    public func updateInboxInvitation(event: Event, status: InvitationStatus)
        async throws
    {
        let currentUser = try await ensureCurrentUser()

        do {
            // Insert members into the group_members table
            try await client
                .from("invitations")
                .update(
                    UpdateInvitationParams(
                        eventId: event.id, senderId: event.eventCreatorUserId,
                        receiverId: currentUser.id, status: status)
                )
                .eq("event_id", value: event.id)
                .eq("receiver_id", value: currentUser.id)
                .execute()
        } catch {
            print("Failed to create invitations: \(error)")
            throw error
        }
    }

    // Define a custom error for better clarity
    enum InvitationError: Error {
        case emptyMembersList
    }

    // create new event in database
    public func createAndReturnGroup(
        name: String
    ) async throws -> FriendGroup {
        let currentUser = try await ensureCurrentUser()

        do {
            let group: FriendGroup =
                try await client
                .from("groups")
                .insert(
                    CreateFriendGroupParams(
                        userId: currentUser.id,
                        name: name
                    )
                )
                .select("*")  // To return the inserted object
                .single()
                .execute()
                .value

            return group

        } catch {
            print("Failed to create group: \(error)")
            throw error
        }

    }

    public func createGroupMembers(members: [CreateGroupMemberParams])
        async throws
    {
        _ = try await ensureCurrentUser()

        // Ensure the members array is not empty
        guard !members.isEmpty else {
            throw GroupMemberError.emptyMembersList
        }

        do {
            // Insert members into the group_members table
            try await client
                .from("group_members")
                .insert(members)
                .execute()
        } catch {
            print("Failed to create group members: \(error)")
            throw error
        }
    }

    // Define a custom error for better clarity
    enum GroupMemberError: Error {
        case emptyMembersList
    }

    public func fetchGroupMembers(groupId: UUID) async throws -> [GroupMember] {
        _ = try await ensureCurrentUser()

        do {
            let groupMembers: [GroupMember] =
                try await client
                .from("group_members")
                .select()
                .eq("group_id", value: groupId)
                .execute()
                .value

            return groupMembers
        } catch {
            print("Failed to fetch group members: \(error)")
            throw error
        }
    }

    public func fetchGroupMembersWithProfiles(groupId: UUID) async throws
        -> [GroupMemberWithProfile]
    {
        _ = try await ensureCurrentUser()

        do {
            // Fetch group members
            let groupMembers: [GroupMember] = try await fetchGroupMembers(
                groupId: groupId)

            // Extract the friend IDs
            let friendIds = groupMembers.map { $0.friendId }  // Replace `friendId` with the actual column name

            // Fetch profiles based on the friend IDs
            let profiles: [Profile] =
                try await client
                .from("profiles")
                .select()
                .in("id", values: friendIds)
                .execute()
                .value

            // Create a dictionary for fast lookup
            let profileDict = Dictionary(
                uniqueKeysWithValues: profiles.map { ($0.id, $0) })

            // Combine GroupMember and Profile into GroupMemberWithProfile
            let combined: [GroupMemberWithProfile] = groupMembers.compactMap {
                groupMember in
                guard let profile = profileDict[groupMember.friendId] else {
                    return nil  // Skip if the profile is not found
                }
                return GroupMemberWithProfile(
                    groupMember: groupMember, profile: profile)
            }

            return combined
        } catch {
            print("Failed to fetch group members with profiles: \(error)")
            throw error
        }
    }

    public func fetchAllGroupMembersWithProfiles(groups: [FriendGroup])
        async throws -> [GroupMemberWithProfile]
    {
        _ = try await ensureCurrentUser()

        do {

            let groupIds = groups.map {
                $0.id
            }

            // Step 1: Fetch group members for all specified groups
            let groupMembers: [GroupMember] =
                try await client
                .from("group_members")
                .select()
                .in("group_id", values: groupIds)
                .execute()
                .value

            // Step 2: Extract the unique friend IDs from the group members
            let friendIds = Set(groupMembers.map { $0.friendId })  // Avoid duplicates

            // Step 3: Fetch profiles based on the friend IDs
            let profiles: [Profile] =
                try await client
                .from("profiles")
                .select()
                .in("id", values: Array(friendIds))  // Convert Set to Array
                .execute()
                .value

            // Step 4: Create a dictionary for fast profile lookup
            let profileDict = Dictionary(
                uniqueKeysWithValues: profiles.map { ($0.id, $0) })

            // Step 5: Combine GroupMember and Profile into GroupMemberWithProfile
            let combined: [GroupMemberWithProfile] = groupMembers.compactMap {
                groupMember in
                guard let profile = profileDict[groupMember.friendId] else {
                    return nil  // Skip if the profile is not found
                }
                return GroupMemberWithProfile(
                    groupMember: groupMember, profile: profile)
            }

            return combined
        } catch {
            print("Failed to fetch group members with profiles: \(error)")
            throw error
        }
    }

    public func searchUsers(searchText: String) async throws -> [Profile] {
        _ = try await ensureCurrentUser()

        do {
            let profiles: [Profile] = try await client.rpc(
                "search_profiles_by_username_prefix",
                params: ["prefix": searchText]
            )
            .execute()
            .value

            return profiles
        } catch {
            print("Failed to search users: \(error)")
            throw error
        }

    }

}

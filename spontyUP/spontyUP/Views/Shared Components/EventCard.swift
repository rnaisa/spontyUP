//
//  EventCard.swift
//  spontyUP
//
//  Created by Pascal on 04.12.2024.
//

import SwiftUI

struct EventCard: View {
    var eventDetails: EventWithInvitations
    @State private var isEditingEvent: Bool = false

    var body: some View {
        NavigationLink(destination: EventDetailView(event: eventDetails)) {
            VStack(alignment: .leading, spacing: 8) {
                // Cancelled Event Notification
                if eventDetails.event.eventStatus == "Cancelled" {
                    Text("Event cancelled")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Event Date and Edit Button
                HStack {
                    Text(eventDetails.event.eventDate, format: .dateTime.day().month().year().hour().minute())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    if eventDetails.isCurrentUserHost {
                        Image(systemName: "person.fill")
                            .foregroundColor(.accentColor)
                    }
                }
                
                // Event Title
                Text(eventDetails.event.eventTitle)
                    .font(.title3)
                    .bold()
                    .lineLimit(1)
                
                // Event Description
                Text(eventDetails.event.eventDescription)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                
                // Attendees
                Text("Who's invited")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    ZStack {
                        ForEach((0..<min(3, eventDetails.invitations.count)).reversed(), id: \.self) { index in
                            Circle()
                                .fill(Color.accentColor.opacity(1))
                                .frame(width: 30, height: 30)
                                .shadow(radius: 2)
                                .offset(x: CGFloat(index * -20))
                        }
                    }
                    .padding(.leading, CGFloat((min(3, eventDetails.invitations.count) - 1) * 20))
                    
                    if eventDetails.invitations.count > 3 {
                        Text("+ \(eventDetails.invitations.count - 3)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.accentColor.opacity(0.1)) // Custom accent color
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
        
    }
}

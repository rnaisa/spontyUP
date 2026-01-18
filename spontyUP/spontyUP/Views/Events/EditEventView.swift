//
//  EditEventView.swift
//  spontyUP
//
//  Created by Pascal on 15.12.2024.
//

import SwiftUI

struct EditEventView: View {
    let eventId: UUID
    @Environment(SupabaseHandler.self) private var supabase
    @Environment(\.dismiss) private var dismiss

    @State private var eventTitle: String = ""
    @State private var eventDate: Date = Date()
    @State private var eventLocation: String = ""
    @State private var eventDescription: String = ""
    @State private var isUpdating: Bool = false
    @State private var originalEventTitle: String = ""
    @State private var originalEventDate: Date = Date()
    @State private var originalEventLocation: String = ""
    @State private var originalEventDescription: String = ""
    @State private var showErrorAlert: Bool = false
    @State private var isShowingExitConfirmation: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Event Title
                VStack(alignment: .leading) {
                    Text("Event Title")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                    TextField("Enter event title", text: $eventTitle)
                        .textFieldStyle(.roundedBorder)
                }

                // Event Date
                VStack(alignment: .leading) {
                    Text("Event Date")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                    DatePicker(
                        "Select date",
                        selection: $eventDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                }

                // Event Location
                VStack(alignment: .leading) {
                    Text("Event Location")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                    TextField("Enter event location", text: $eventLocation)
                        .textFieldStyle(.roundedBorder)
                }

                // Event Description
                VStack(alignment: .leading) {
                    Text("Event Description")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                    TextField("Enter event description", text: $eventDescription, axis: .vertical)
                        .lineLimit(5)
                        .textFieldStyle(.roundedBorder)
                }

                Spacer()

                // Save Changes Button
                Button(action: saveChanges) {
                    if isUpdating {
                        ProgressView()
                    } else {
                        Text("Save Changes")
                    }
                }
                .buttonStyle(ProfileActionButtonStyle())
                .disabled(isUpdating || fieldsAreUnchanged())
                .alert("Failed to update event", isPresented: $showErrorAlert) {
                    Button("OK", role: .cancel) {}
                }
            }
            .padding()
            .navigationTitle("Edit Event")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: handleExit) {
                        Image(systemName: "xmark")
                    }
                }
            }
            .confirmationDialog(
                "You have unsaved changes. Do you want to discard your edits or continue editing?",
                isPresented: $isShowingExitConfirmation,
                titleVisibility: .visible
            ) {
                Button("Discard Changes", role: .destructive) {
                    dismiss()
                }
                Button("Continue Editing", role: .cancel) {}
            }
            .interactiveDismissDisabled(!fieldsAreUnchanged()) // Prevent swipe dismiss if there are unsaved changes
            .task {
                await loadEventDetails()
            }
        }
    }

    /// Prefill form fields with the event's existing details
    private func loadEventDetails() async {
        do {
            let event = try await supabase.fetchEventById(eventId: eventId)
            eventTitle = event.eventTitle
            eventDate = event.eventDate
            eventLocation = event.eventLocation
            eventDescription = event.eventDescription
            
            originalEventTitle = eventTitle
            originalEventDate = eventDate
            originalEventLocation = eventLocation
            originalEventDescription = eventDescription
        } catch {
            print("loadEventDetails failed.")
        }
    }

    /// Check if fields are unchanged to disable the save button
    private func fieldsAreUnchanged() -> Bool {
        eventTitle == originalEventTitle &&
        eventDate == originalEventDate &&
        eventLocation == originalEventLocation &&
        eventDescription == originalEventDescription
    }
    
    /// Handles the exit action, checking for unsaved changes
    private func handleExit() {
        if !fieldsAreUnchanged() {
            isShowingExitConfirmation = true
        } else {
            dismiss()
        }
    }
    
    /// Save changes to the event
    private func saveChanges() {
        Task {
            isUpdating = true
            do {
                try await supabase.updateEvent(
                    id: eventId,
                    title: eventTitle,
                    date: eventDate,
                    location: eventLocation,
                    description: eventDescription
                )
                dismiss() // Dismiss the view on success
            } catch {
                showErrorAlert = true
            }
            isUpdating = false
        }
    }
}


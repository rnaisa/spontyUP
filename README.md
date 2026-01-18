# SpontyUp

The app simplifying spontaneity & organization of your social plans

> _Archived Xcode prototype originally developed during an iOS development course at the Lucerne University of Applied Sciences._

![Simulator Screen Recording SpontyUP](Assets/simulator_rec_spontyup.GIF)

## Features

Effortlessly create events, invite friends, and manage invitations – all in one place.

- **Easy Invitations:** Invite friends or custom groups with just a few taps
- **Flexible Hosting:** Allow invitees to bring their own friends or groups, making it easy to mix friend circles seamlessly
- **Spontaneous Gatherings:** Quickly create and join events for any occasion

## How it works

1. **Sign Up / Sign In**. Each user has a unique username. Editing the profile is possible.
2. Add Friends in the `Friends` Tab by looking up usernames. Received Friend Requests are in the `Friend Requests` Subtab in the `Inbox` Tab
3. All Friends are automatically added to the default `All` Group, more groups can be made or modified in the `Groups` Subtab to simplify event invitiations. These groups are only visible to the logged in user. Each "FriendDetailView" also lists groups they are in and allow modifying them.
4. In the Manage `Events` tab, create an event and invite individual friends or all friends from the selected groups automatically. These invitations appear in friends' inboxes once the event is created. Events can be modified.
5. The `Feed` shows events that the logged in user created or was invited to, from 24 hours in the past until the future. All others are hidden for now. 

No deletions are possible and only minimal client-side input constraint checks are in place.

## Dependencies

This project relies on a forked version of the following SwiftUI package that has since been removed:

- **[SwiftUI-Toasts](https://github.com/sunghyun-k/swiftui-toasts)**  
  Licensed under the **MIT License**. For more details, see the package's [LICENSE](https://github.com/sunghyun-k/swiftui-toasts?tab=MIT-1-ov-file) file.

The App worked with a Supabase Backend for Authentication and Data Handling using the **[Supabase Swift SDK](https://github.com/supabase/supabase-swift)**. There were security policies in place (auth only access, restricted database operations etc).

![Supabase Schema SpontyUP](Assets/supabase_schema.png)
*SpontyUp Supabase Schema*


---

### License Notice

This project is licensed under the [GNU License](LICENCE)

```plaintext
GNU Licence

Copyright (c) [2024] [Pascal Thürig, Maisa Melezanovic]

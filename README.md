# Track Me

Track Me records the location of each person who installs the app and signs in. An admin opens the same app, sees every tracked person on one map, and can open that person’s details for the current day.

People are tracked only after they create an account and allow location. Signing out stops recording.

## What each person sees

**Tracked user**

1. Sign in with email and password, or with Google.
2. Allow location, including background location.
3. The home screen shows one marker with that person’s name at their latest position.
4. Recording continues while the app is open, in the background, and after the app is closed. Android shows a persistent notification while tracking is on.

A location is saved when either of these happens:

- 5 minutes have passed since the last save, or
- the person has moved 10 meters.

**Admin**

An admin is not tracked. Signing in as an admin opens the people map and stops recording for that account.

- Each tracked person has one named marker. Admin accounts are not shown.
- The marker moves when that person’s latest location is saved.
- Tapping a marker focuses the map on that person’s path for today and opens their details.
- The path and **Today’s history** include every location recorded for that person during the current day. Other days are left out.

## How an account becomes an admin

Sign in once so the app creates `profiles/{uid}`. Then, in the Firebase Realtime Database console, set that profile’s `role` to exactly `admin`. Sign out and sign in again.

You can also allow an email before the first sign-in. Add this node (console write only):

```text
admins/{email} = true
```

Replace every `.` in the email with `,`.

```text
islam.kamal.fci@gmail.com  →  admins/islam,kamal,fci@gmail,com
```

A normal account cannot change its own role to admin.

## Where data is stored

Project: `track-me-8e64a`

Database: `https://track-me-8e64a-default-rtdb.firebaseio.com`

| Path | What it holds |
| --- | --- |
| `profiles/{uid}` | Name, email, and role (`user` or `admin`) |
| `admins/{email-key}` | `true` when that email should be an admin |
| `users/{uid}/currentLocation` | Latest saved position. This is the map marker. |
| `users/{uid}/locations` | Every saved position. Today’s history groups these by hour. |

Database rules are in `firebase/database.rules.json`. A person can read and write only their own profile and locations. An admin can read every profile and every location. Deploy rule changes with:

```bash
firebase deploy --only database --project track-me-8e64a
```

## Run the app

This repo uses Flutter through FVM. `dart` and `flutter` are not on the default shell path.

```bash
export PATH="$PATH:$HOME/fvm/versions/3.44.1/bin:$HOME/.pub-cache/bin"

fvm flutter pub get
fvm flutter run
```

Release on a connected phone:

```bash
fvm flutter run --release
```

Android application id: `com.app.trackMe`  
iOS bundle id: `com.example.locationTrackingExample`

### Firebase on a new machine

1. In the Firebase console, turn on **Email/Password** and **Google** sign-in.
2. Register the Android app as `com.app.trackMe` and add the debug (and release) SHA-1 and SHA-256. Google Sign-In closes immediately when the SHA-1 is missing.
3. Register the iOS app with the bundle id above.
4. Generate the local config:

```bash
export PATH="$PATH:$HOME/fvm/versions/3.44.1/bin:$HOME/.pub-cache/bin"
flutterfire configure --project=track-me-8e64a
```

`flutterfire` calls `dart` directly, so the FVM `bin` directory must be on `PATH` before the pub-cache `bin` directory.

5. Publish the database rules with the `firebase deploy` command above.

After changing the tracking interval or `google-services.json`, stop the app and start it again. A hot reload keeps the previous tracking session.

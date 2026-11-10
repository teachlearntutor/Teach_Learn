# Teach Learn

**Teach. Learn. Track.**

TeachLearn is an Android app (Flutter + Firebase) for home tutors. Tutors manage their students, class schedule and attendance in one place, and students or parents can find tutors and send lesson requests.

> Status: **in active development.** Not yet published on any store.

## Features

### For tutors
- Student management: add, edit, search, group by class, pause or archive
- Weekly class schedule with holidays, one-off changes and time-clash warnings
- Attendance marking (present / absent / late / excused) and per-student attendance percentage
- Public tutor profile (headline, bio, subjects, class levels, city, area, mode, experience, availability)
- Lesson request inbox: accept or decline, then add the student in one tap
- Call and WhatsApp shortcuts for student contacts

### For students and parents
- **Tutor Finder:** search by subject, city, mode, class level and experience, sort, and load more
- Send a lesson request to a tutor, and track it in **My Requests** (pending, accepted, declined, cancelled)
- Tutor phone and WhatsApp unlock only after the tutor accepts

### For everyone
- Email/password and Google sign-in, with a role chosen at sign-up (Tutor, Student, Parent)
- Unique public ID per user (TL-XXXXX)
- Profile with photo (stored on the device), light and dark themes, offline-friendly data
- Royal Blue design with Bricolage Grotesque and Onest fonts

## Tech stack

| Area | Choice |
| --- | --- |
| UI | Flutter (Dart), Material 3 |
| State management | Riverpod |
| Backend | Firebase Authentication, Cloud Firestore, Crashlytics (Spark plan) |
| Local storage | shared_preferences |
| Other | google_sign_in, url_launcher, image_picker, Lucide icons |

No Firebase Storage, Cloud Functions or paid services are used.

## Project structure

```
lib/
  core/            theme, shared widgets, utilities
  features/
    auth/          login, sign-up, Google sign-in, role selection
    onboarding/    splash
    tutor/         tutor home and dashboard
    learner/       student / parent home
    students/      student CRUD
    schedule/      classes, sessions, holidays
    attendance/    attendance marking and stats
    profile/       profile, settings
    marketplace/   tutor finder, public profile, lesson requests
docs/
  FIRESTORE_SCHEMA.md   data model
firestore.rules         security rules
```

## Data model (short)

```
users/{uid}                 profile, role, publicId
  students/ classes/ sessions/ holidays/ attendance/
publicIds/{id}              reserved public IDs
tutorProfiles/{uid}         public tutor profile
  private/contact           phone, readable only after a request is accepted
lessonRequests/{from_to}    request between a learner and a tutor
```

Full details: [docs/FIRESTORE_SCHEMA.md](docs/FIRESTORE_SCHEMA.md). Access is controlled by [firestore.rules](firestore.rules) (owner-only data, default deny).

## Getting started

### Prerequisites
- Flutter SDK (stable) and Android Studio or VS Code
- An Android phone or emulator
- A Firebase project (free Spark plan)

### Firebase setup
1. Create a Firebase project and add an Android app with package name `com.teachlearn.app`.
2. Enable **Authentication** (Email/Password and Google) and create a **Firestore** database.
3. Add your debug SHA-1 and SHA-256 fingerprints in Project settings.
4. Place `google-services.json` in `android/app/`.
5. Generate `lib/firebase_options.dart`:
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
6. Publish `firestore.rules` in Firebase Console, under Firestore Database, then Rules.

### Run
```
flutter pub get
flutter run --profile
```
Use `--profile` for realistic speed. Debug mode is noticeably slower.

### Checks
```
flutter analyze
flutter test
```

### Release build
Create your own upload keystore and `android/key.properties` (both are git-ignored), add the release SHA-1 and SHA-256 to Firebase, then:
```
flutter build apk --release
```
Never commit keystores, passwords or API keys.

## Roadmap

- Class reminders (local notifications)
- Low-attendance alerts and PDF reports
- Terms and Conditions, delete account
- Urdu localization
- Reviews, in-app chat, report and block for the marketplace
- Play Store release

## License

All rights reserved. Not open source at this time.
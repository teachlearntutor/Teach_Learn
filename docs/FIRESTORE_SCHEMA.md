# TeachLearn Cloud Firestore Database Schema

This document describes the Cloud Firestore data structures, subcollections, and field definitions used in TeachLearn.

---

## Collections & Subcollections Overview

```
/users/{uid}                           -> User Profile (Tutor / Student / Parent)
  ├── /students/{studentId}             -> Enrolled Students Subcollection
  └── /attendance/{studentId_yyyy-MM-dd} -> Attendance Records Subcollection

/tutorProfiles/{tutorUid}              -> Public Tutor Finder Profiles
/lessonRequests/{fromUid_toUid}        -> Lesson Inquiry Requests
/publicIds/{publicId}                  -> Global Reserved Short Codes (TL-XXXXX)
```

---

## Collection Schemas

### 1. User Profile (`/users/{uid}`)
- `displayName` (string): Full user name.
- `email` (string): User email address.
- `photoUrl` (string, optional): Profile photo URL.
- `role` (string): Account role (`tutor`, `student`, `parent`).
- `publicId` (string): Unique assigned short ID (e.g. `TL-7K3Q9`).
- `createdAt` (timestamp): Account creation date.

---

### 2. Students Subcollection (`/users/{uid}/students/{studentId}`)
- `code` (string): Unique student code (e.g. `S-4K2P`).
- `name` (string): Student full name (1 to 80 characters).
- `searchName` (string): Lowercase student name for search queries.
- `classLevel` (string): Class/grade level (e.g. `Class 9`).
- `classSort` (number): Numeric helper for class ordering (e.g. `9`).
- `school` (string, optional): School name.
- `subjects` (array of strings, max 10): List of enrolled subjects.
- `parentName` (string, optional): Parent/guardian name.
- `parentContact` (string, optional): Parent phone number.
- `address` (string, optional): Student home address.
- `startDate` (string): Registration date (`yyyy-MM-dd`).
- `status` (string): Account status (`active`, `paused`, `left`).
- `leftAt` (timestamp, optional): Date student marked as left.
- `notes` (string, optional): Internal tutor notes.
- `avatarKey` (string, optional): Avatar color/preset key.
- `createdAt` (timestamp): Creation timestamp.
- `updatedAt` (timestamp): Last update timestamp.

---

### 3. Attendance Subcollection (`/users/{uid}/attendance/{studentId_yyyy-MM-dd}`)
- `studentId` (string): Associated student ID.
- `date` (string): Attendance date (`yyyy-MM-dd`).
- `studentName` (string): Student name at the time attendance was marked.
- `status` (string): Roll call status (`present`, `absent`, `leave`).
- `note` (string, optional): Attendance note.
- `markedAt` (timestamp): Timestamp when roll call was saved.

---

### 4. Public Tutor Profiles Collection (`/tutorProfiles/{tutorUid}`)
- `displayName` (string): Tutor display name.
- `publicId` (string): Public ID code.
- `headline` (string): Profile headline.
- `bio` (string): Teaching bio and background.
- `subjects` (array of strings): Subjects taught.
- `levels` (array of strings): Classes/grades taught.
- `city` (string): City location.
- `area` (string): Area/sector location.
- `mode` (string): Teaching mode (`home` or `online`).
- `experienceYears` (number): Years of experience.
- `isPublished` (boolean): Visibility switch in Tutor Finder.
- `createdAt` (timestamp): Creation timestamp.
- `updatedAt` (timestamp): Last update timestamp.

---

### 7. Lesson Requests Collection (`/lessonRequests/{fromUid_toUid}`)
- `fromUid` (string): Student/Parent user UID.
- `toUid` (string): Tutor user UID.
- `fromName` (string): Student/Parent display name.
- `learnerName` (string): Learner name shown to the tutor.
- `classLevel` (string): Learner's class, when provided.
- `subject` (string): Subject requested.
- `subjects` (array of strings): Learner's requested subjects.
- `city` (string): Learner's preferred city, when provided.
- `area` (string): Learner's preferred area, when provided.
- `mode` (string): Preferred teaching mode, when provided.
- `message` (string): Message details.
- `status` (string): Request status (`pending`, `accepted`, `declined`, `cancelled`).
- `createdAt` (timestamp): Creation timestamp.
- `updatedAt` (timestamp): Last update timestamp.

Lesson requests do not store phone numbers or private contact details.

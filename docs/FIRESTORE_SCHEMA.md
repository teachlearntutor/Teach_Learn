# TeachLearn Cloud Firestore Database Schema

This document describes the Cloud Firestore data structures, subcollections, and field definitions used in TeachLearn.

---

## Collections & Subcollections Overview

```
/users/{uid}                           -> User Profile (Tutor / Student / Parent)
  ├── /students/{studentId}             -> Enrolled Students Subcollection
  ├── /classes/{classId}                -> Weekly Recurring Classes Subcollection
  ├── /sessions/{sessionId}             -> Individual Generated/Extra Sessions
  ├── /holidays/{holidayId}             -> User Holidays Subcollection
  └── /attendance/{sessionId_studentId} -> Attendance Records Subcollection

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

### 3. Weekly Classes Subcollection (`/users/{uid}/classes/{classId}`)
- `title` (string, optional): Class title.
- `subject` (string): Subject name.
- `classLevel` (string): Grade/Class level.
- `studentIds` (array of strings, max 30): List of enrolled student IDs.
- `weekdays` (array of numbers, 1..7): Days of week (1 = Monday, 7 = Sunday).
- `startTime` (string): Start time in `HH:mm` format.
- `durationMin` (number): Duration in minutes (15 to 300).
- `timezone` (string): Timezone string (default `Asia/Karachi`).
- `startDate` (string): Effective start date (`yyyy-MM-dd`).
- `endDate` (string, optional): Effective end date.
- `location` (map): `{ type: "home" | "online", place: string, link: string }`.
- `active` (boolean): Whether recurring class is active.
- `createdAt` (timestamp): Creation timestamp.
- `updatedAt` (timestamp): Last update timestamp.

---

### 4. Sessions Subcollection (`/users/{uid}/sessions/{sessionId}`)
- `classId` (string, optional): Parent weekly class ID.
- `kind` (string): Session type (`regular`, `extra`, `makeup`).
- `date` (string): Session date (`yyyy-MM-dd`).
- `startAt` (timestamp): Session start DateTime.
- `endAt` (timestamp): Session end DateTime.
- `status` (string): Session status (`scheduled`, `completed`, `cancelled`, `rescheduled`).
- `cancelReason` (string, optional): Reason if cancelled.
- `rescheduledFrom` (string, optional): Original session ID if rescheduled.
- `subject` (string): Subject name.
- `studentIds` (array of strings): List of student IDs.
- `location` (map): Location details.
- `attendanceMarked` (boolean): Flag indicating if roll call is saved.
- `createdAt` (timestamp): Creation timestamp.
- `updatedAt` (timestamp): Last update timestamp.

---

### 5. Attendance Subcollection (`/users/{uid}/attendance/{sessionId}_{studentId}`)
- `sessionId` (string): Associated class session ID.
- `classId` (string, optional): Weekly class ID.
- `studentId` (string): Associated student ID.
- `date` (string): Attendance date (`yyyy-MM-dd`).
- `startAt` (timestamp): Session start DateTime.
- `status` (string): Roll call status (`present`, `absent`, `late`).
- `reason` (string, optional): Absence or late reason.
- `markedAt` (timestamp): Timestamp when roll call was saved.

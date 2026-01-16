# Firestore Collections Setup Guide

## Collections Structure

Your Circle app uses the following Firestore collections:

### 1. **users**
```
Collection: users
Document ID: {userId} (from Firebase Auth)

Fields:
- displayName: string
- email: string
- photoURL: string (optional)
- bio: string (optional)
- createdAt: timestamp
- updatedAt: timestamp
- settings: map
- preferences: map
- circles: array<string> (circle IDs)
```

### 2. **circles**
```
Collection: circles
Document ID: auto-generated

Fields:
- name: string
- description: string
- imageUrl: string (optional)
- createdBy: string (userId)
- createdAt: timestamp
- updatedAt: timestamp
- members: array<string> (userIds)
- admins: array<string> (userIds)
- memberCount: number
- isPrivate: boolean
- category: string
- settings: map
```

### 3. **circles/{circleId}/posts**
```
Subcollection: posts (under circles)
Document ID: auto-generated

Fields:
- circleId: string
- authorId: string
- content: string
- imageUrls: array<string> (optional)
- createdAt: timestamp
- updatedAt: timestamp
- likesCount: number
- commentsCount: number
- type: string (text/image/link)
```

### 4. **circles/{circleId}/posts/{postId}/comments**
```
Subcollection: comments (under posts)
Document ID: auto-generated

Fields:
- postId: string
- authorId: string
- content: string
- createdAt: timestamp
- parentCommentId: string (optional, for replies)
```

### 5. **circles/{circleId}/posts/{postId}/likes**
```
Subcollection: likes (under posts)
Document ID: {userId}

Fields:
- userId: string
- createdAt: timestamp
```

### 6. **circles/{circleId}/tasks**
```
Subcollection: tasks (under circles)
Document ID: auto-generated

Fields:
- circleId: string
- title: string
- description: string
- assignedTo: array<string> (userIds)
- createdBy: string (userId)
- dueDate: timestamp
- status: string (pending/in_progress/completed)
- priority: string (low/medium/high)
- createdAt: timestamp
- updatedAt: timestamp
```

### 7. **circles/{circleId}/messages**
```
Subcollection: messages (under circles)
Document ID: auto-generated

Fields:
- circleId: string
- senderId: string
- content: string
- type: string (text/image/file)
- timestamp: timestamp
- readBy: array<string> (userIds)
- attachments: array<map> (optional)
```

### 8. **circles/{circleId}/files**
```
Subcollection: files (under circles)
Document ID: auto-generated

Fields:
- circleId: string
- uploadedBy: string (userId)
- fileName: string
- fileUrl: string
- fileType: string
- fileSize: number
- uploadedAt: timestamp
- description: string (optional)
```

### 9. **notifications**
```
Collection: notifications
Document ID: auto-generated

Fields:
- userId: string
- type: string (post/comment/task/message/circle_invite)
- title: string
- body: string
- data: map
- isRead: boolean
- createdAt: timestamp
- relatedId: string (postId/taskId/circleId)
```

### 10. **backups** (System collection)
```
Collection: backups
Document ID: auto-generated

Fields:
- user_id: string
- backup_type: string
- created_at: timestamp
- data: map
- status: string
```

### 11. **analytics** (System collection)
```
Collection: analytics
Document ID: auto-generated

Fields:
- event_type: string
- user_id: string
- timestamp: timestamp
- data: map
```

## Setup Instructions

### Option 1: Automatic Creation (Recommended)
The collections will be created automatically when your app writes the first document. Just run your app and:
1. Sign up a user → creates `users` collection
2. Create a circle → creates `circles` collection
3. Post in a circle → creates `posts` subcollection
4. And so on...

### Option 2: Manual Creation in Firebase Console
1. Go to Firebase Console: https://console.firebase.google.com
2. Select your project: **circle-app-d9f18**
3. Navigate to **Firestore Database**
4. Click **Start collection**
5. Create each collection with a sample document

## Important Indexes

You'll need to create composite indexes for these queries:

1. **Posts by circle and timestamp**
   - Collection: `circles/{circleId}/posts`
   - Fields: `circleId` (Ascending), `createdAt` (Descending)

2. **Tasks by circle and status**
   - Collection: `circles/{circleId}/tasks`
   - Fields: `circleId` (Ascending), `status` (Ascending), `dueDate` (Ascending)

3. **Messages by circle and timestamp**
   - Collection: `circles/{circleId}/messages`
   - Fields: `circleId` (Ascending), `timestamp` (Descending)

4. **Notifications by user and read status**
   - Collection: `notifications`
   - Fields: `userId` (Ascending), `isRead` (Ascending), `createdAt` (Descending)

**Note:** Firebase will automatically prompt you to create these indexes when you run queries that need them.

## Next Steps

1. ✅ Firebase project created and configured
2. ✅ Authentication enabled (Email/Password + Google OAuth)
3. ✅ Firestore rules deployed
4. 🔄 Run your app to auto-create collections
5. 🔄 Create indexes as prompted by Firebase
6. 🔄 Test all features to ensure proper data flow

## Testing Your Setup

Run these commands to test:

```bash
cd circle_app
flutter run
```

Then test each feature:
- Sign up/Sign in
- Create a circle
- Post in a circle
- Create a task
- Send a message
- Upload a file

Each action will create the necessary collections and documents automatically.

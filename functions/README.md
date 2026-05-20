# Firebase Functions for SannyBunnies

This folder contains Firebase Cloud Functions for topic-based push notifications.

## Setup

1. Install dependencies:
   ```bash
   cd functions
   npm install
   ```

2. Deploy functions:
   ```bash
   firebase deploy --only functions
   ```

## What is included

- `onNewsCreated`: sends notifications to `general` and `parents` topics when a new `news` document is created.
- `onScheduleChanged`: sends notifications to `group_<groupId>` when a schedule document is created or updated.
- `onChildUpdated`: sends notifications to parent and teacher topics when a child document changes relevant fields.

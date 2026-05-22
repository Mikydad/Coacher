Accountability Circles V1 — Full Engineering PRD
1. Problem Statement

Users often fail to stay consistent because accountability is weak. Large communities become noisy and impersonal, while individual AI coaching can feel isolated.

The goal is not to build another social network or chat app.

The goal is to create small accountability circles where users know each other, support progress, maintain consistency, and reinforce behavior change.

Core problem being solved:

Solo goals lose momentum
Large groups lose accountability
Reminders alone eventually become background noise
AI coaching alone lacks human reinforcement

The system should combine:

AI coaching + community + goals + accountability
2. Product Goal

Create small accountability communities that improve:

consistency
motivation
completion rates
social accountability
long-term habit retention

Core product principle:

Goals
↓
Progress
↓
Accountability
↓
Communication

Never:

Chat
↓
Maybe goals

Chat exists to support accountability, not replace it.

3. Success Metrics
Primary metrics
Daily active circle participation
Weekly commitment completion rate
Shared challenge completion rate
User retention after joining a circle
Circle retention after 30 days
Secondary metrics
Messages per active member
Goal completion improvement after joining circles
Circle survival (>14 days active)
Weekly challenge participation rate
4. Circle System
Circle Constraints

Minimum members:

4

Maximum members:

8

Rationale:

Small enough for recognition
Large enough to survive inactivity
Circle Types
Private Circle
Invite only
Public Circle

Users can discover through:

categories
search
recommendations
Join Rules

Circle configuration:

enum JoinPolicy{
   open,
   requestApproval
}

Open:

User joins immediately

Approval:

User requests join
Moderator approves
Member Rules

Users can:

leave anytime
participate in challenges
create challenge proposals
Moderator Rules

Creator:

Becomes moderator automatically

Creator may assign:

1 additional moderator

Moderators can:

approve members
edit circle settings
initiate member removal vote
manage challenge approvals
Member Removal

Flow:

Moderator initiates vote
      ↓
Moderators vote
      ↓
Majority reached
      ↓
Remove member
Maximum Circles

Users:

Maximum = 3 circles

Future:

Premium = 5 circles

Reason:

Avoid notification overload and weak accountability.

5. Circle Discovery

Users may discover circles via:

Browse

Examples:

Fitness
Learning
Business
Reading
Productivity
Search

Examples:

Running
Chinese
Gym
Morning routine
AI Recommendations

Recommendation inputs:

goals
interests
timezone
activity level
coaching style
commitment level

Example:

Running Circle #42

Members: 6/8
Timezone: East Africa
Commitment: Disciplined
6. Chat System

Chat supports:

text
emoji reactions
accomplishment/proof images

No:

video
voice rooms
public feeds
Image Rules

Images only allowed for:

Workout proof
Study proof
Healthy meal
Milestone
Goal progress

Purpose:

Prevent spam.

Message Model
class CircleMessage{

String id;

String circleId;

String senderId;

MessageType type;

String? content;

String? imageUrl;

DateTime createdAt;

}
7. Activity Feed

System generated events:

Examples:

Mike completed Workout 🔥

Sarah reached 10 day streak

David finished Chinese practice

User generated:

🏃 Workout complete

📚 Finished study session

🎯 Goal milestone reached

Purpose:

Reduce meaningless chat and encourage accountability.

8. Weekly Commitments

Users set:

1–3 commitments

Example:

Workout ×5

Read ×3

Sleep before 11PM

Weekly review:

Completed:

2/3
9. Shared Challenges

Two challenge types:

Competition Mode
Mike → 8/30

Sarah → 7/30

David → 5/30
Team Mode
Group target:

200 miles

Current:

137/200
Challenge Creation Flow

Any member can create:

Create challenge
        ↓
Pending approval
        ↓
Members vote
        ↓
Majority reached
        ↓
Challenge active
10. Challenge Progress Sync

Hybrid approach:

Automatic updates

From:

goals
habits
tasks

Example:

Morning Run completed
↓
Challenge progress +1
Manual updates

Allowed for:

Standalone challenges

Example:

User uploads proof image
↓
Progress updated

Rule:

Automatic updates override manual updates
11. Circle Streak

Tracks overall consistency.

Example:

Circle streak:

12 days 🔥

Rule:

Minimum participation threshold required

Example:

5/8 members completed today's goal
12. AI Group Pulse
Daily Pulse

Purpose:

Quick status summary.

Example:

Group Pulse

6 members active

Mike:
Workout streak 11

Sarah:
Missed study twice
Weekly Pulse

Purpose:

Long-term reflection.

Example:

Weekly Review

Success:

83%

Strongest day:

Tuesday

Most missed:

Sleep goals

AI suggestions:

Suggested challenge:

Everyone complete one focused session before 8PM
13. Notifications

Default notifications:

Receive:

mentions
challenge updates
moderator actions
accountability events
weekly summaries

Muted by default:

reactions
low-value events
User Preferences

Per circle:

☑ Mentions

☑ Challenge updates

☑ Weekly summary

☑ Accomplishments

☐ Reactions

Additional:

Mute circle

Mute until tomorrow

Priority circle
14. Database Architecture
Firestore Collections
users/

circles/

circleMembers/

messages/

activityFeed/

challenges/

challengeVotes/

aiPulse/
Firebase Storage

Stores:

Images
Isar

Local caching:

Messages

Circle metadata

Challenge state

AI pulse
15. Implementation Roadmap
Phase 1

Foundation

Build:

circle models
create/join flow
permissions
Firestore structure
Phase 2

Communication

Build:

text chat
proof image upload
reactions
activity feed
Phase 3

Accountability

Build:

challenge system
progress sync
circle streaks
weekly commitments
Phase 4

AI

Build:

AI pulse
recommendations
notification preferences
Phase 5

Future

Build:

accountability partner matching
advanced AI suggestions
betting system
dynamic AI circles
16. Explicit V1 Exclusions

Not included:

video
livestreams
voice rooms
public social feed
AI moderation
betting
large public communities
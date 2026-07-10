import 'feature_guide.dart';

/// Content registry for everything the app can teach about itself.
/// Shape mirrors [AiCapabilityRegistry]: static const data + static helpers.
abstract final class FeatureGuides {
  static const List<FeatureGuide> all = [
    tasks,
    disciplineModes,
    focus,
    reminders,
    goals,
    circles,
    analytics,
    planTomorrow,
    coachAi,
  ];

  static FeatureGuide? byId(String id) {
    for (final g in all) {
      if (g.id == id) return g;
    }
    return null;
  }

  /// Best keyword match against user input, or null. Longest keyword wins
  /// so 'discipline mode' beats a bare 'mode'.
  static FeatureGuide? matchTopic(String userInput) {
    final lower = userInput.toLowerCase();
    FeatureGuide? best;
    var bestLen = 0;
    for (final g in all) {
      for (final k in g.keywords) {
        if (k.length > bestLen && lower.contains(k)) {
          best = g;
          bestLen = k.length;
        }
      }
    }
    return best;
  }

  static const _educationPhrases = [
    'what is',
    'what are',
    "what's",
    'how do i',
    'how do you',
    'how does',
    'how do reminders',
    'how to use',
    'explain',
    'teach me',
    'tell me about',
    'which mode',
    'what does',
  ];

  /// True when the input asks ABOUT the app rather than commanding it.
  /// Gates the education path so commands ("add me to a circle") still
  /// reach their normal handling (including unsupported-domain answers).
  static bool isEducationQuestion(String userInput) {
    final lower = userInput.toLowerCase().trim();
    return _educationPhrases.any(lower.contains) && matchTopic(lower) != null;
  }

  // ─── Guides ───────────────────────────────────────────────────────────────

  static const tasks = FeatureGuide(
    id: 'tasks',
    title: 'Tasks',
    emoji: '✅',
    oneLiner: 'Plan your day as small, doable steps.',
    what:
        'Tasks are the building blocks of your day in PathPal. Each one has '
        'a title, an optional time and duration, and a discipline mode that '
        'decides how firmly the app holds you to it.',
    why:
        'A day planned as concrete steps gets done; a vague to-do list gets '
        'postponed. Completing tasks feeds your progress score and streak.',
    howSteps: [
      'Tap ADD TASK on the Home screen.',
      'Give it a name — a time and duration help the app plan around it.',
      'Tap the circle next to a task when you finish it.',
      'Score honestly — partial completion still counts.',
    ],
    tips: [
      'Start with 2–3 tasks a day. Momentum beats ambition.',
    ],
    keywords: [
      'task',
      'tasks',
      'add task',
      'add a task',
      'create a task',
      'to-do',
      'todo',
      'complete a task',
    ],
    suggestedPrompts: [
      'Add a 30 minute workout tomorrow morning',
      'What is Discipline Mode?',
      'How does the progress score work?',
    ],
    tryItRoute: '/add-task',
  );

  static const disciplineModes = FeatureGuide(
    id: 'disciplineModes',
    title: 'Discipline Modes',
    emoji: '🎚️',
    oneLiner: 'Choose how firmly the app holds you to your plan.',
    what:
        'Discipline Modes set how strictly PathPal treats your tasks — '
        'Flexible gives gentle nudges, Disciplined asks you to account for '
        'anything unfinished, and Extreme requires a completed focus '
        'session before a task can be checked off. New tasks inherit a mode '
        'from your default, scaled by how important the task is.',
    why:
        'One size never fits every day. Flexible keeps easy days '
        'guilt-free, while stricter modes protect the commitments you '
        'refuse to negotiate with yourself.',
    howSteps: [
      'Open Profile and find the Discipline Modes section.',
      'Pick a default mode — new tasks inherit it.',
      'Override the mode on any single task from its detail screen.',
      'Try a stricter mode on just your most important task first.',
    ],
    tips: [
      'Start flexible and tighten up — strictness you abandon teaches the '
          'wrong habit.',
    ],
    keywords: [
      'discipline mode',
      'discipline modes',
      'enforcement',
      'strict mode',
      'flexible mode',
      'extreme mode',
      'disciplined mode',
      'which mode',
      'mode should i use',
    ],
    suggestedPrompts: [
      'Which discipline mode fits a busy week?',
      'How do reminders work?',
      'What is Focus mode?',
    ],
    tryItTabIndex: 5, // MainTabIndex.profile
  );

  static const focus = FeatureGuide(
    id: 'focus',
    title: 'Focus Sessions',
    emoji: '🎯',
    oneLiner: 'A distraction-free timer for one task at a time.',
    what:
        'Focus starts a timed session for a single task: pick the task, '
        'start the timer, and work until it ends. Sessions are recorded, so '
        'the app knows what you actually spent time on.',
    why:
        'Deep work happens one task at a time. A running timer turns "I '
        'should work on this" into a commitment with a finish line — and '
        'Extreme-mode tasks require a completed session to count.',
    howSteps: [
      'Tap START FOCUS on the Home screen.',
      'Pick the task you want to work on.',
      'Hit Start and stay with it until the timer ends.',
      'Finish — the session is saved to your progress automatically.',
    ],
    tips: [
      'Pair Focus with your hardest task of the day, not the easiest.',
    ],
    keywords: [
      'focus',
      'focus session',
      'focus mode',
      'deep work',
      'timer',
      'pomodoro',
      'start focus',
    ],
    suggestedPrompts: [
      'Start a focus session for my next task',
      'What is Discipline Mode?',
      'How does the progress score work?',
    ],
    tryItRoute: '/focus',
  );

  static const reminders = FeatureGuide(
    id: 'reminders',
    title: 'Reminders',
    emoji: '⏰',
    oneLiner: 'The app nudges you when a task is due.',
    what:
        'Any task with a time can remind you when it starts. Reminders '
        'respect your sleep window and quiet hours, and adapt if you keep '
        'snoozing or ignoring them.',
    why:
        'The hardest part of a plan is remembering it at the right moment. '
        'A well-timed nudge beats an alarm you learn to ignore.',
    howSteps: [
      'When adding a task, switch the reminder on and pick a time.',
      'Allow notifications when the app asks — no permission, no nudges.',
      'Tune quiet hours in Profile under Reminder Settings.',
    ],
    tips: [
      'Set reminders a few minutes before the task, not at the deadline.',
    ],
    keywords: [
      'reminder',
      'reminders',
      'notification',
      'notifications',
      'notify me',
      'remind me how',
      'quiet hours',
      'sleep window',
    ],
    suggestedPrompts: [
      'Add a reminder to stretch at 4pm',
      'What is Plan Tomorrow?',
      'Which discipline mode fits a busy week?',
    ],
  );

  static const goals = FeatureGuide(
    id: 'goals',
    title: 'Goals & Habits',
    emoji: '🏁',
    oneLiner: 'Long-term targets your daily tasks add up to.',
    what:
        'Goals track something bigger than a day: a target (like "run '
        '20 km this month"), check-ins toward it, and the habits that '
        'support it. Your goal activity drives the streak on Home.',
    why:
        'Tasks answer "what now?"; goals answer "what for?". Progress you '
        'can see is progress you keep making.',
    howSteps: [
      'Open the Goals tab and create a goal.',
      'Give it a clear target and a deadline.',
      'Check in whenever you make progress.',
      'Watch the streak and progress ring react on Home.',
    ],
    tips: [
      'One ambitious goal beats five vague ones.',
    ],
    keywords: [
      'goal',
      'goals',
      'habit',
      'habits',
      'target',
      'check-in',
      'check in on my goal',
    ],
    suggestedPrompts: [
      'Create a goal to read 12 books this year',
      'How does the streak work?',
      'What are Tasks?',
    ],
    tryItTabIndex: 2, // MainTabIndex.goals
  );

  static const circles = FeatureGuide(
    id: 'circles',
    title: 'Circles',
    emoji: '👥',
    oneLiner: 'Small accountability groups that keep you honest.',
    what:
        'A Circle is a private group where members share weekly '
        'commitments, post proof of their work, chat, and run challenges '
        'together.',
    why:
        'Telling someone your plan doubles the chance you follow it. '
        'Circles make your progress visible to people who care.',
    howSteps: [
      'Open the Circles tab and create or join a circle.',
      'Set your weekly commitments so members can see them.',
      'Post a photo proof when you complete something.',
      'Join a challenge to compete together.',
    ],
    tips: [
      'Small circles work best — 3 to 6 people who actually know you.',
    ],
    keywords: [
      'circle',
      'circles',
      'community',
      'accountability',
      'accountability partner',
      'weekly commitment',
      'challenge',
      'challenges',
    ],
    suggestedPrompts: [
      'What are weekly commitments?',
      'What are Goals?',
      'How do I use Focus?',
    ],
    tryItTabIndex: 4, // MainTabIndex.community
  );

  static const analytics = FeatureGuide(
    id: 'analytics',
    title: 'Progress & Analytics',
    emoji: '📊',
    oneLiner: 'See how your effort compounds over time.',
    what:
        'The Progress tab tracks your completion rate, day streak, focus '
        'time, and trends across the week — plus coaching insights about '
        'your patterns.',
    why:
        'What gets measured gets improved. Seeing a streak you built is '
        'the strongest reason not to break it.',
    howSteps: [
      'Complete tasks and goal check-ins — the numbers update by '
          'themselves.',
      'Open the Progress tab to see your streak, score, and weekly trend.',
      'Read the insights — they point at patterns you may not notice.',
    ],
    tips: [
      'A partial score still moves the numbers. Honesty beats perfection.',
    ],
    keywords: [
      'analytics',
      'progress',
      'stats',
      'statistics',
      'score',
      'progress score',
      'discipline score',
      'streak',
      'completion rate',
    ],
    suggestedPrompts: [
      'How am I doing this week?',
      'How does the streak work?',
      'What are Goals?',
    ],
    tryItTabIndex: 3, // MainTabIndex.progress
  );

  static const planTomorrow = FeatureGuide(
    id: 'planTomorrow',
    title: 'Plan Tomorrow',
    emoji: '🌙',
    oneLiner: 'Win tomorrow the evening before.',
    what:
        'Plan Tomorrow is an evening ritual: line up tomorrow\'s tasks, '
        'drag them into order, and wake up to a day that\'s already '
        'decided.',
    why:
        'Deciding in the morning wastes your best energy on logistics. A '
        'plan made the night before removes the "what now?" friction.',
    howSteps: [
      'Tap PLAN TOMORROW on the Home screen in the evening.',
      'Add the 2–5 tasks that matter most.',
      'Drag them into the order you want to face them.',
    ],
    tips: [
      'Put the hardest task first — willpower is highest early.',
    ],
    keywords: [
      'plan tomorrow',
      'tomorrow planning',
      'evening planning',
      'plan my day ahead',
      'plan ahead',
    ],
    suggestedPrompts: [
      'Help me plan tomorrow',
      'What are Tasks?',
      'How do reminders work?',
    ],
    tryItRoute: '/plan-tomorrow',
  );

  static const coachAi = FeatureGuide(
    id: 'coachAi',
    title: 'Coach AI',
    emoji: '✨',
    oneLiner: 'Your planning assistant that speaks plain language.',
    what:
        'Coach AI plans with you in chat: it can add and move tasks, '
        'create goals, set reminders, answer questions about your '
        'schedule, and explain any feature of the app.',
    why:
        'Typing "gym at 6, call mom after lunch" is faster than any form. '
        'The coach also sees your schedule, so its suggestions fit your '
        'real day.',
    howSteps: [
      'Open the Coach tab.',
      'Say what you want in your own words — no special commands.',
      'Review the plan it proposes, then confirm or tweak it.',
      'Ask it anything about the app, like "what is Discipline Mode?".',
    ],
    tips: [
      'Give times and durations for the best plans.',
    ],
    keywords: [
      'coach ai',
      'ai coach',
      'coach',
      'assistant',
      'ai chat',
      'chatbot',
      'what can the ai do',
    ],
    suggestedPrompts: [
      'Plan my morning with a workout and reading',
      'What is Plan Tomorrow?',
      'Which discipline mode fits a busy week?',
    ],
    tryItTabIndex: 1, // MainTabIndex.coach
  );
}

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

  /// Everything askable/lookupable: page guides + element help topics.
  /// NOTE matchTopic ties break to the FIRST list — an element keyword that
  /// duplicates a page-guide keyword is dead. The registry test enforces
  /// exact-string keyword uniqueness across this whole set.
  static const List<FeatureGuide> searchable = [...all, ...elements];

  static FeatureGuide? byId(String id) {
    for (final g in searchable) {
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
    for (final g in searchable) {
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

  // ─── Element help topics (the `?` dots + AI-askable) ─────────────────────
  // NOT in [all]: they skip the first-time-card/tour surfaces and the
  // ≥2-howSteps rule. Keywords must be exact-string unique vs page guides
  // (ties are dead) and each topic's lowercase title must be a keyword so
  // "Tell me about <title>" round-trips through matchTopic.

  static const List<FeatureGuide> elements = [
    flowNow,
    todaysProgress,
    todaysTasks,
    todaysGoals,
    weeklySummary,
    goalsHabitsBreakdown,
    taskIntegrity,
    coachingFocus,
    streakAtRisk,
    weeklyCommitments,
    challengeVoting,
    cycleProgress,
    milestones,
    goalActions,
    carryForward,
    coachTone,
    coreOptimization,
  ];

  static const flowNow = FeatureGuide(
    id: 'flowNow',
    title: 'Flow Now',
    emoji: '🌊',
    oneLiner: 'The one task you should be doing right now.',
    what:
        'Flow Now watches your day and surfaces the single task that fits '
        'this moment — the one in progress, or the next one due. The label '
        'shows the current time block and how many tasks are still open.',
    why:
        'Deciding what to do next is where momentum dies. Flow Now makes '
        'that decision for you, so you can act instead of scanning a list.',
    howSteps: [
      'Glance at the strip — it always shows your best next move.',
      'Tap it to jump into that task or start a focus session.',
    ],
    tips: ['If the strip feels wrong, check your task times — it follows them.'],
    keywords: ['flow now', 'flow now strip', 'next task suggestion'],
    suggestedPrompts: ['What is Focus?', "Tell me about Today's Tasks"],
  );

  static const todaysProgress = FeatureGuide(
    id: 'todaysProgress',
    title: "Today's Progress",
    emoji: '📈',
    oneLiner: 'Your streak, score, and 7-day trend at a glance.',
    what:
        'The big number is your day streak — consecutive days with real '
        'progress. The percentage is how much of today\'s planned work is '
        'done, weighted by how important each item is. The small chart is '
        'your last 7 days.',
    why:
        'Seeing the streak you built is the strongest reason not to break '
        'it. One honest glance beats a page of statistics.',
    howSteps: [],
    tips: [
      'Partial completions count too — the score rewards honesty, not '
          'perfection.',
    ],
    keywords: ["today's progress", 'todays progress', 'day streak number'],
    suggestedPrompts: ['How am I doing this week?', 'How does the streak work?'],
  );

  static const todaysTasks = FeatureGuide(
    id: 'todaysTasks',
    title: "Today's Tasks",
    emoji: '📋',
    oneLiner: "Everything you planned for today, in one list.",
    what:
        "Today's Tasks lists what you planned for today. Tap the circle "
        'when you finish something; tap the swap icon if plans changed and '
        'you need to move or reshuffle a task.',
    why:
        'The list is your day made concrete — checking items off here is '
        'what feeds your progress score and streak.',
    howSteps: [
      'Tap the circle next to a task when you complete it.',
      'Score honestly if asked — partial still counts.',
      'Use the swap icon when plans change instead of ignoring the task.',
    ],
    keywords: ["today's tasks", 'todays task list'],
    suggestedPrompts: ['Add a 30 minute workout today', 'What is Flow Now?'],
  );

  static const todaysGoals = FeatureGuide(
    id: 'todaysGoals',
    title: "Today's Goals",
    emoji: '🎯',
    oneLiner: 'Goal check-ins that are due today.',
    what:
        'This card shows the goals and habits with progress due today. '
        'Checking in here moves the long-term goal forward and keeps your '
        'streak alive.',
    why:
        'Goals fail quietly when they never show up in your day. Surfacing '
        'them next to your tasks keeps the long game visible.',
    howSteps: [
      'Tap a goal to check in with today\'s progress.',
      'Even a small check-in counts — consistency beats size.',
    ],
    keywords: ["today's goals", 'todays goal list', 'goal check-ins today'],
    suggestedPrompts: ['What are Goals?', 'How does the streak work?'],
  );

  static const weeklySummary = FeatureGuide(
    id: 'weeklySummary',
    title: 'Weekly Summary',
    emoji: '📊',
    oneLiner: 'How your whole week is going, in one ring.',
    what:
        'The ring is your overall completion for this week across tasks '
        'and goals, weighted by importance. The date range shows which '
        'week you\'re looking at.',
    why:
        'Days lie — one bad Tuesday feels like failure. The week is the '
        'honest unit of progress.',
    howSteps: [],
    tips: ['A steady 70% every week beats a perfect Monday and a dead Friday.'],
    keywords: ['weekly summary', 'weekly summary ring', 'week completion ring'],
    suggestedPrompts: ['How am I doing this week?', 'Tell me about Task Integrity'],
  );

  static const goalsHabitsBreakdown = FeatureGuide(
    id: 'goalsHabitsBreakdown',
    title: 'Goals & Habits',
    emoji: '🏁',
    oneLiner: 'Your long-term targets, measured by the day, week, and month.',
    what:
        'This section breaks your goal and habit check-ins into day, week, '
        'and month views so you can see whether the long game is actually '
        'moving.',
    why:
        'Habits feel invisible day to day. Only the week and month views '
        'show whether they\'re real.',
    howSteps: [],
    keywords: ['goals & habits', 'goals and habits section', 'habit breakdown'],
    suggestedPrompts: ['What are Goals?', 'Tell me about the Weekly Summary'],
  );

  static const taskIntegrity = FeatureGuide(
    id: 'taskIntegrity',
    title: 'Task Integrity',
    emoji: '🧭',
    oneLiner: 'Do you actually do what you plan?',
    what:
        'Task Integrity compares what you planned against what you '
        'completed, across the day, week, and month. High integrity means '
        'your plans can be trusted.',
    why:
        'Planning feels like progress but isn\'t. This number keeps your '
        'plans honest — it only moves when you finish things.',
    howSteps: [],
    tips: [
      'If integrity is low, plan fewer tasks — a short list you finish '
          'beats a long list you abandon.',
    ],
    keywords: ['task integrity', 'plan vs done', 'completion integrity'],
    suggestedPrompts: ['How am I doing this week?', 'Which discipline mode fits a busy week?'],
  );

  static const coachingFocus = FeatureGuide(
    id: 'coachingFocus',
    title: 'Coaching Focus',
    emoji: '🔍',
    oneLiner: 'The one pattern the coach thinks matters most right now.',
    what:
        'The app studies your recent activity and picks a single focus — '
        'a pattern worth fixing or a strength worth doubling down on. It '
        'updates as your behavior changes.',
    why:
        'Ten insights are noise; one is a plan. This card is the app\'s '
        'best single piece of advice for you this week.',
    howSteps: [],
    keywords: ['coaching focus', 'coaching insight card', 'focus insight'],
    suggestedPrompts: ['How am I doing this week?', 'What is Coach AI?'],
  );

  static const streakAtRisk = FeatureGuide(
    id: 'streakAtRisk',
    title: 'Streak at Risk',
    emoji: '⚠️',
    oneLiner: 'A warning before your streak breaks — not after.',
    what:
        'This card appears when today is on track to end without the '
        'progress that keeps your streak alive, while there\'s still time '
        'to save it.',
    why:
        'Streaks rarely break on hard days — they break on days you '
        'forgot. A timely nudge is the difference.',
    howSteps: [
      'Complete any planned task or goal check-in before the day ends.',
    ],
    keywords: ['streak at risk', 'streak warning', 'save my streak'],
    suggestedPrompts: ['What should I do right now?', 'How does the streak work?'],
  );

  static const weeklyCommitments = FeatureGuide(
    id: 'weeklyCommitments',
    title: 'Weekly Commitments',
    emoji: '🤝',
    oneLiner: 'What you promised your circle this week.',
    what:
        'Weekly Commitments are the 1-3 things you publicly commit to in '
        'a circle each week. Members see each other\'s commitments and '
        'progress — that\'s the accountability.',
    why:
        'A private plan is easy to abandon. A promise your friends can '
        'see is not.',
    howSteps: [
      'Set 1-3 commitments at the start of the week.',
      'Mark progress as you go — members see it update.',
      'Keep them small enough that you\'d be embarrassed NOT to finish.',
    ],
    keywords: ['weekly commitments', 'circle commitments', 'my commitments'],
    suggestedPrompts: ['What are Circles?', 'Tell me about Challenge Voting'],
  );

  static const challengeVoting = FeatureGuide(
    id: 'challengeVoting',
    title: 'Challenge Voting',
    emoji: '🗳️',
    oneLiner: 'Challenges start when the circle agrees they should.',
    what:
        'New challenges wait in "Waiting for votes" until enough members '
        'vote them in — then they move to Active and everyone\'s progress '
        'counts toward the team total.',
    why:
        'A challenge nobody chose is homework. Voting makes it a pact.',
    howSteps: [
      'Vote on pending challenges you\'d actually do.',
      'Once active, log progress — proofs keep it honest.',
    ],
    keywords: ['challenge voting', 'waiting for votes', 'active challenges'],
    suggestedPrompts: ['What are Circles?', 'Tell me about Weekly Commitments'],
  );

  static const cycleProgress = FeatureGuide(
    id: 'cycleProgress',
    title: 'Cycle Progress',
    emoji: '🔄',
    oneLiner: 'How far you are into this goal\'s current period.',
    what:
        'Goals run in cycles — a week, a month, or a custom period. This '
        'section shows check-ins accumulated in the current cycle against '
        'the target, and when the cycle resets.',
    why:
        'A goal without a deadline drifts. The cycle gives every goal a '
        'finish line that keeps coming back.',
    howSteps: [],
    keywords: ['cycle progress', 'goal cycle', 'goal period progress'],
    suggestedPrompts: ['What are Goals?', 'Tell me about Milestones'],
  );

  static const milestones = FeatureGuide(
    id: 'milestones',
    title: 'Milestones',
    emoji: '🪜',
    oneLiner: 'The big goal, broken into steps you can actually finish.',
    what:
        'Milestones split a goal into ordered steps. Ticking one off is '
        'real, visible progress even when the finish line is months away.',
    why:
        '"Run a marathon" paralyzes; "run 5k this month" starts today.',
    howSteps: [
      'Break the goal into 3-6 milestones when you create it.',
      'Tick each one off as you reach it.',
    ],
    keywords: ['milestones', 'goal milestones', 'goal steps'],
    suggestedPrompts: ['What are Goals?', 'Tell me about Cycle Progress'],
  );

  static const goalActions = FeatureGuide(
    id: 'goalActions',
    title: 'Goal Actions',
    emoji: '⚡',
    oneLiner: 'Quick moves for this goal: check in, edit, archive.',
    what:
        'The Actions row holds everything you can do to this goal — log a '
        'check-in, edit its target or deadline, or archive it when it no '
        'longer serves you.',
    why:
        'Goals should be living things. Editing or archiving honestly '
        'beats letting dead goals rot on the list.',
    howSteps: [],
    keywords: ['goal actions', 'archive a goal', 'edit my goal'],
    suggestedPrompts: ['What are Goals?', 'Create a goal to read 12 books'],
  );

  static const carryForward = FeatureGuide(
    id: 'carryForward',
    title: 'Carry Forward',
    emoji: '📦',
    oneLiner: "Unfinished today doesn't mean gone — move it to tomorrow.",
    what:
        'This section lists today\'s unfinished tasks while you plan '
        'tomorrow. Carry forward the ones that still matter; let go of '
        'the ones that don\'t.',
    why:
        'Unfinished tasks silently vanishing teaches you to distrust your '
        'own plan. Deciding explicitly — keep or drop — keeps it honest.',
    howSteps: [
      'Review each unfinished task while planning tomorrow.',
      'Carry forward what still matters; skip what doesn\'t.',
    ],
    keywords: ['carry forward', 'unfinished from today', 'move task to tomorrow'],
    suggestedPrompts: ['What is Plan Tomorrow?', 'Help me plan tomorrow'],
  );

  static const coachTone = FeatureGuide(
    id: 'coachTone',
    title: 'Coach Tone',
    emoji: '🗣️',
    oneLiner: 'How the coach talks to you — gentle, balanced, or blunt.',
    what:
        'Coach Tone sets the personality of nudges, briefs, and Coach AI '
        'replies — from supportive encouragement to no-excuses direct.',
    why:
        'The same message lands differently on different people. Pick the '
        'voice you\'ll actually listen to.',
    howSteps: [
      'Pick the tone that matches what gets through to you.',
      'Change it any time — messages adapt immediately.',
    ],
    keywords: ['coach tone', 'coach personality', 'coaching style'],
    suggestedPrompts: ['What is Coach AI?', 'Which discipline mode fits a busy week?'],
  );

  static const coreOptimization = FeatureGuide(
    id: 'coreOptimization',
    title: 'Core Optimization',
    emoji: '⚙️',
    oneLiner: 'Account, notifications, appearance, and reminder tuning.',
    what:
        'The settings that shape how the app behaves around you: account '
        'and privacy, notification preferences, dark or light appearance, '
        'and reminder quiet hours.',
    why:
        'An app that nudges you at the wrong times gets muted. Five '
        'minutes here makes every reminder land better.',
    howSteps: [
      'Set your sleep window in Reminder Settings so nudges respect it.',
      'Pick the appearance you like — everything else is optional.',
    ],
    keywords: ['core optimization', 'optimization settings', 'app settings section'],
    suggestedPrompts: ['How do reminders work?', 'Tell me about Coach Tone'],
  );
}

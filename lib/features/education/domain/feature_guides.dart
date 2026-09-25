import '../../../app/application/main_tab_navigation.dart';
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
    direction,
    time,
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
        'Tasks are the building blocks of your day in SidePal. Each one has '
        'a title, an optional time and duration, and a strictness level that '
        'decides how firmly the app holds you to it.',
    why:
        'A day planned as concrete steps gets done; a vague to-do list gets '
        'postponed. Completing tasks feeds your progress score.',
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
      'What is Strictness?',
      'How does the progress score work?',
    ],
    tryItRoute: '/add-task',
  );

  static const disciplineModes = FeatureGuide(
    id: 'disciplineModes',
    title: 'Strictness',
    emoji: '🎚️',
    oneLiner: "How strict SidePal is when you don't follow your plan.",
    what:
        'Strictness sets what SidePal asks of you when a task goes '
        'unfinished. Flexible lets you move or dismiss it easily. '
        'Disciplined asks for a decision — do it, move it, or say why. '
        'Extreme requires it to be done or moved with a reason, with no '
        'skipping, and a focus session before a task can be ticked off. '
        'New tasks inherit the level from your default, scaled by how '
        'important the task is.',
    why:
        'One size never fits every day. Flexible keeps easy days '
        'guilt-free, while stricter levels protect the commitments you '
        'refuse to negotiate with yourself.',
    howSteps: [
      'Open Profile and find the Strictness section.',
      'Pick a default level — new tasks inherit it.',
      'Override the level on any single task from its detail screen.',
      'Try a stricter level on just your most important task first.',
    ],
    tips: [
      'Start flexible and tighten up — strictness you abandon teaches the '
          'wrong habit.',
    ],
    keywords: [
      'strictness',
      'strictness level',
      'how strict',
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
      'Which strictness fits a busy week?',
      'How do reminders work?',
      'What is Focus mode?',
    ],
    tryItTabIndex: MainTabIndex.profile,
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
        'Extreme tasks require a completed session to count.',
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
      'timer',
      'pomodoro',
      'start focus',
    ],
    suggestedPrompts: [
      'Start a focus session for my next task',
      'What is Strictness?',
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
        'respect your quiet hours and your status, and adapt if you keep '
        'snoozing or ignoring them.',
    why:
        'The hardest part of a plan is remembering it at the right moment. '
        'A well-timed nudge beats an alarm you learn to ignore.',
    howSteps: [
      'When adding a task, switch the reminder on and pick a time.',
      'Allow notifications when the app asks — no permission, no nudges.',
      'Tune quiet hours in Profile under Notifications & Reminders.',
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
      'Which strictness fits a busy week?',
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
        'support it. Your goal activity feeds your progress score on Home.',
    why:
        'Tasks answer "what now?"; goals answer "what for?". Progress you '
        'can see is progress you keep making.',
    howSteps: [
      'Open the Goals tab and create a goal.',
      'Give it a clear target and a deadline.',
      'Check in whenever you make progress.',
      'Watch the progress ring react on Home.',
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
      'How does the progress score work?',
      'What are Tasks?',
    ],
    tryItTabIndex: MainTabIndex.goals,
  );

  static const direction = FeatureGuide(
    id: 'direction',
    title: 'Direction',
    emoji: '🧭',
    oneLiner: 'What matters to you this year, quarter, and month.',
    what:
        'Direction is where you tell SidePal what you are moving toward — '
        'in your own words, for this year, this quarter, and this month. '
        'It is not a goal: no deadline, no progress bar, no tasks. Just '
        'context SidePal keeps in mind while helping you.',
    why:
        'Tasks answer "what now?", goals answer "what for?", and Direction '
        'answers "where am I heading?". With it, the coach can prioritise '
        'what actually matters to you instead of giving generic advice.',
    howSteps: [
      'Open Profile → Direction.',
      'Write a sentence for the year, the quarter, or the month — any can '
          'stay empty.',
      'Tap Save. Change it whenever what matters changes.',
      'At the start of a month, SidePal quietly asks what your focus is.',
    ],
    tips: [
      'Keep it to one sentence — a direction, not a plan.',
      'SidePal never nags you about it; it only remembers.',
    ],
    keywords: [
      'direction',
      'focus this month',
      'focus this quarter',
      'what matters',
      'where am i heading',
      'north star',
    ],
    suggestedPrompts: [
      'What should I work on given my direction?',
      'How is Direction different from Goals?',
    ],
    tryItRoute: '/direction',
  );

  static const time = FeatureGuide(
    id: 'time',
    title: 'Your Time',
    emoji: '⏱️',
    oneLiner: 'See how you spent your time today or this week.',
    what:
        'Tap "Track your time" on Home and say what you are doing right '
        'now — "Gym", "Scrolling", "Working on SidePal". SidePal stamps '
        'the time; the next thing you log ends the previous one, so you '
        'never type durations. The Your Time page shows your day as a '
        'timeline with the gaps you did not log left honest, plus a '
        'summary at the bottom.',
    why:
        'Plans say what you meant to do. The timeline says what you '
        'actually did. Seeing the two side by side is how you notice your '
        'own patterns — SidePal never scores or judges them.',
    howSteps: [
      'On Home, tap "Track your time".',
      'Type what you are doing right now, or tap one of your recent '
          'activities.',
      'Optionally add how long you intend to spend.',
      'Tap Log. Log the next thing when it changes.',
      'Open Profile → Your Time to see your day and the summary.',
    ],
    tips: [
      'Imperfect tracking is fine — three entries a day already tell a story.',
      'A focus session logs itself, with an exact end.',
    ],
    keywords: [
      'time',
      'your time',
      'time tracking',
      'log time',
      'track',
      'timeline',
      'where did my time go',
      'what am i doing',
      'log activity',
    ],
    suggestedPrompts: [
      'What is the Your Time page?',
      'How is Your Time different from the focus timer?',
    ],
    tryItRoute: '/time',
  );

  static const circles = FeatureGuide(
    id: 'circles',
    title: 'Groups',
    emoji: '👥',
    oneLiner: 'Small accountability groups that keep you honest.',
    what:
        'A Group is a private space where members keep each other '
        'accountable — talk, share progress, make weekly commitments, and '
        'take on challenges together.',
    why:
        'Telling someone your plan doubles the chance you follow it. '
        'Groups make your progress visible to people who care.',
    howSteps: [
      'Open the Community tab and create or join a group.',
      'Set your weekly commitments so members can see them.',
      'Post a photo proof when you complete something.',
      'Join a challenge to compete together.',
    ],
    tips: [
      'Small groups work best — 3 to 6 people who actually know you.',
    ],
    keywords: [
      'group',
      'groups',
      'accountability group',
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
    tryItTabIndex: MainTabIndex.community,
  );

  static const analytics = FeatureGuide(
    id: 'analytics',
    title: 'Progress & Analytics',
    emoji: '📊',
    oneLiner: 'See how your effort compounds over time.',
    what:
        'Progress scores every day with one number: 60% goals and habits, '
        '40% tasks. Browse it by day, week, month, quarter, or year — each '
        'day is a ring, and tapping one shows what that day asked of you '
        'and what you did. Coaching insights sit underneath.',
    why:
        'What gets measured gets improved. One honest number a day beats '
        'a page of statistics.',
    howSteps: [
      'Complete tasks and goal check-ins — the numbers update by '
          'themselves.',
      'Pick Day, Week, Month, Quarter, or Year and page back with the '
          'arrows.',
      'Tap a ring in Week or Month to open that day\'s detail.',
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
      'completion rate',
    ],
    suggestedPrompts: [
      'How am I doing this week?',
      'How does the progress score work?',
      'What are Goals?',
    ],
    tryItTabIndex: MainTabIndex.profile, // Progress lives in Profile now
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
      'Ask it anything about the app, like "what is Strictness?".',
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
      'Which strictness fits a busy week?',
    ],
    tryItRoute: '/coach', // Coach is a sheet now; the route presents it
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
    forLater,
    suggestedForLater,
    weeklyCommitments,
    challengeVoting,
    cycleProgress,
    milestones,
    goalActions,
    carryForward,
    coachTone,
    coreOptimization,
    deepWork,
  ];

  static const flowNow = FeatureGuide(
    id: 'flowNow',
    title: 'Up Next',
    emoji: '🌊',
    oneLiner: 'The one task you should be doing right now.',
    what:
        'This strip shows the single task that fits this moment. It reads '
        'IN FOCUS while a focus session is running, PAUSED when you have '
        'paused one, and UP NEXT when nothing is running. The header shows '
        'the current time block and how many tasks are still open.',
    why:
        'Deciding what to do next is where momentum dies. The strip makes '
        'that decision for you, so you can act instead of scanning a list.',
    howSteps: [
      'Glance at the strip — it always shows your best next move.',
      'Tap it to jump into that task or start a focus session.',
    ],
    tips: ['If the strip feels wrong, check your task times — it follows them.'],
    keywords: ['up next', 'in focus strip', 'next task suggestion', 'flow now'],
    suggestedPrompts: ['What is Focus?', "Tell me about Today's Tasks"],
  );

  static const todaysProgress = FeatureGuide(
    id: 'todaysProgress',
    title: "Today's Progress",
    emoji: '📈',
    oneLiner: 'Your score for today, and this week so far.',
    what:
        'The percentage is how much of today\'s planned work is done, '
        'weighted by how important each item is. The small chart is this '
        'week\'s progress, Monday to today.',
    why:
        'One honest glance beats a page of statistics.',
    howSteps: [],
    tips: [
      'Partial completions count too — the score rewards honesty, not '
          'perfection.',
    ],
    keywords: ["today's progress", 'todays progress', "this week's progress"],
    suggestedPrompts: ['How am I doing this week?', 'How does the progress score work?'],
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
        'what feeds your progress score.',
    howSteps: [
      'Tap the circle next to a task when you complete it.',
      'Score honestly if asked — partial still counts.',
      'Use the swap icon when plans change instead of ignoring the task.',
    ],
    keywords: ["today's tasks", 'todays task list'],
    suggestedPrompts: ['Add a 30 minute workout today', 'What is Up Next?'],
  );

  static const todaysGoals = FeatureGuide(
    id: 'todaysGoals',
    title: "Today's Goals",
    emoji: '🎯',
    oneLiner: 'Goal check-ins that are due today.',
    what:
        'This card shows the goals and habits with progress due today. '
        'Checking in here moves the long-term goal forward.',
    why:
        'Goals fail quietly when they never show up in your day. Surfacing '
        'them next to your tasks keeps the long game visible.',
    howSteps: [
      'Tap a goal to check in with today\'s progress.',
      'Even a small check-in counts — consistency beats size.',
    ],
    keywords: ["today's goals", 'todays goal list', 'goal check-ins today'],
    suggestedPrompts: ['What are Goals?', 'How does the progress score work?'],
  );

  static const weeklySummary = FeatureGuide(
    id: 'weeklySummary',
    title: 'Period Discipline',
    emoji: '📊',
    oneLiner: 'One number for the period you\'re looking at.',
    what:
        'Discipline is your completion for the selected period: 60% goals '
        'and habits, 40% tasks, weighted by importance, so a heavy day '
        'counts more than a light one. "Days met" counts the days that '
        'cleared your strictness level\'s bar; a day with nothing planned is '
        'quiet, not a failure. The chip compares you with the previous '
        'period.',
    why:
        'Days lie — one bad Tuesday feels like failure. The week is the '
        'honest unit of progress.',
    howSteps: [],
    tips: ['A steady 70% every week beats a perfect Monday and a dead Friday.'],
    keywords: [
      'weekly summary',
      'period discipline',
      'discipline number',
      'period summary',
      'days met',
    ],
    suggestedPrompts: ['How am I doing this week?', 'Tell me about Task Integrity'],
  );

  static const goalsHabitsBreakdown = FeatureGuide(
    id: 'goalsHabitsBreakdown',
    title: 'Goals & Habits',
    emoji: '🏁',
    oneLiner: 'The 60% of your score that comes from the long game.',
    what:
        'This bar is your goal and habit completion for the selected '
        'period. It carries 60% of the Discipline number — when only goals '
        'were planned on a day, it carries all of it.',
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
        'completed for the selected period. It carries 40% of the '
        'Discipline number — all of it on days with no goals due. High '
        'integrity means your plans can be trusted.',
    why:
        'Planning feels like progress but isn\'t. This number keeps your '
        'plans honest — it only moves when you finish things.',
    howSteps: [],
    tips: [
      'If integrity is low, plan fewer tasks — a short list you finish '
          'beats a long list you abandon.',
    ],
    keywords: ['task integrity', 'plan vs done', 'completion integrity'],
    suggestedPrompts: ['How am I doing this week?', 'Which strictness fits a busy week?'],
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

  static const forLater = FeatureGuide(
    id: 'forLater',
    title: 'Plan for Later',
    emoji: '🕰️',
    oneLiner: 'Things you want to do without choosing an exact time.',
    what:
        'Plan for later holds the small things you mean to do soon — a call, a '
        'message, an errand — without picking a clock time. Say roughly '
        'when (today, tomorrow, this week, the weekend) and SidePal finds '
        'a good moment and nudges you.',
    why:
        'Not everything deserves a slot in your plan. Parking it here '
        'keeps it out of your head without letting it slip.',
    howSteps: [
      'Tap + on the Plan for later card and type what you want to do.',
      'Pick roughly when, then tap "Find me a good time".',
    ],
    tips: ['Errands can remind you when you head out the door.'],
    keywords: ['for later', 'plan for later', 'without an exact time', 'find me a good time'],
    suggestedPrompts: ['Remind me to call my mom this week', "Tell me about Today's Tasks"],
  );

  static const suggestedForLater = FeatureGuide(
    id: 'suggestedForLater',
    title: 'Suggested for Later',
    emoji: '💡',
    oneLiner: 'Things SidePal noticed you might want to do.',
    what:
        'These are ideas SidePal picked up from your chats and your days — '
        'someone you mentioned wanting to call, an errand that came up. '
        'Nothing here nudges you until you say so.',
    why:
        'Good intentions get lost in conversation. Keeping them visible '
        'means you decide, instead of forgetting.',
    howSteps: [
      'Tap "Remind me" to move one onto your Plan for later list.',
      'Tap the × to dismiss anything that does not fit.',
    ],
    keywords: ['suggested for later', 'sidepal noticed', 'suggestions for later'],
    suggestedPrompts: ['Tell me about Plan for Later', 'What does SidePal know about me?'],
  );

  static const weeklyCommitments = FeatureGuide(
    id: 'weeklyCommitments',
    title: 'Weekly Commitments',
    emoji: '🤝',
    oneLiner: 'What you told your group you would get done this week.',
    what:
        'Weekly Commitments are the 1-3 things you commit to in a group '
        'each week. Members see each other\'s commitments and progress — '
        'that\'s the accountability.',
    why:
        'A private plan is easy to abandon. A commitment your friends can '
        'see is not.',
    howSteps: [
      'Set 1-3 commitments at the start of the week.',
      'Mark progress as you go — members see it update.',
      'Keep them small enough that you\'d be embarrassed NOT to finish.',
    ],
    keywords: ['weekly commitments', 'group commitments', 'my commitments'],
    suggestedPrompts: ['What are Groups?', 'Tell me about Challenge Voting'],
  );

  static const challengeVoting = FeatureGuide(
    id: 'challengeVoting',
    title: 'Challenge Voting',
    emoji: '🗳️',
    oneLiner: 'Challenges start when the group agrees they should.',
    what:
        'A proposed challenge waits for votes until enough members approve '
        'it — then it moves to Active and everyone\'s progress counts '
        'toward the team total. "Needs your vote" means you have not '
        'voted on it yet.',
    why:
        'A challenge nobody chose is homework. Voting makes it a pact.',
    howSteps: [
      'Vote on pending challenges you\'d actually do.',
      'Once active, log progress — proofs keep it honest.',
    ],
    keywords: ['challenge voting', 'waiting for votes', 'needs your vote', 'active challenges'],
    suggestedPrompts: ['What are Groups?', 'Tell me about Weekly Commitments'],
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
    title: 'Coach Style',
    emoji: '🗣️',
    oneLiner: 'How the coach talks to you — supportive, balanced, direct, or tough.',
    what:
        'Coach style sets the personality of nudges, briefs, and coach '
        'replies — from gentle encouragement to tough, no-excuses honesty.',
    why:
        'The same message lands differently on different people. Pick the '
        'voice you\'ll actually listen to.',
    howSteps: [
      'Pick the style that matches what gets through to you.',
      'Change it any time — messages adapt immediately.',
    ],
    keywords: ['coach style', 'coach tone', 'coach personality', 'coaching style'],
    suggestedPrompts: ['What is Coach AI?', 'Which strictness fits a busy week?'],
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
      'Set your quiet hours in Notifications & Reminders so nudges respect them.',
      'Pick the appearance you like — everything else is optional.',
    ],
    keywords: ['core optimization', 'optimization settings', 'app settings section'],
    suggestedPrompts: ['How do reminders work?', 'Tell me about Coach Style'],
  );

  static const deepWork = FeatureGuide(
    id: 'deepWork',
    title: 'Deep Work',
    emoji: '⚡',
    oneLiner: 'Silence notifications while you work on this task.',
    what:
        'Deep Work marks a task as a no-interruption block: while you work '
        'on it, the app holds its own notifications so nothing pulls you '
        'away mid-task. It quiets SidePal only — your phone\'s other apps '
        'and its system Do Not Disturb are untouched.',
    why:
        'One ping can cost twenty minutes of focus. Blocking alerts on your '
        'hardest tasks protects the time you already decided to protect.',
    howSteps: [
      'Turn on Deep Work when creating or editing a task.',
      'Work on the task — alerts stay quiet until you finish.',
    ],
    keywords: [
      // Moved off the Focus guide: asking about "deep work" now teaches the
      // task toggle, which cross-links to Focus Sessions.
      'deep work',
      'deep work toggle',
      'notification blackout',
      'blocks alerts',
    ],
    suggestedPrompts: [
      'What is Focus?',
      'Tell me about Strictness',
    ],
  );
}

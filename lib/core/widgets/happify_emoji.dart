import 'package:fluentui_emoji_icon/fluentui_emoji_icon.dart';
import 'package:flutter/material.dart';

class HappifyEmoji extends StatelessWidget {
  const HappifyEmoji._(this.emoji, {required this.size, this.semanticLabel});

  final FluentData emoji;
  final double size;
  final String? semanticLabel;

  factory HappifyEmoji.overview({double size = 40}) => HappifyEmoji._(
    Fluents.flSmilingFace,
    size: size,
    semanticLabel: 'Overview',
  );

  factory HappifyEmoji.records({double size = 40}) =>
      HappifyEmoji._(Fluents.flNotebook, size: size, semanticLabel: 'Records');

  factory HappifyEmoji.community({double size = 40}) => HappifyEmoji._(
    Fluents.flPeopleHugging,
    size: size,
    semanticLabel: 'Community',
  );

  factory HappifyEmoji.care({double size = 40}) => HappifyEmoji._(
    Fluents.flHeartHands,
    size: size,
    semanticLabel: 'Professional care',
  );

  factory HappifyEmoji.chat({double size = 40}) =>
      HappifyEmoji._(Fluents.flMobilePhone, size: size, semanticLabel: 'Chat');

  factory HappifyEmoji.escalation({double size = 40}) => HappifyEmoji._(
    Fluents.flSosButton,
    size: size,
    semanticLabel: 'Urgent support',
  );

  factory HappifyEmoji.history({double size = 40}) => HappifyEmoji._(
    Fluents.flCounterclockwiseArrowsButton,
    size: size,
    semanticLabel: 'History',
  );

  factory HappifyEmoji.profile({double size = 40}) => HappifyEmoji._(
    Fluents.flBustInSilhouette,
    size: size,
    semanticLabel: 'Profile',
  );

  factory HappifyEmoji.psychologist({double size = 40}) => HappifyEmoji._(
    Fluents.flHealthWorker,
    size: size,
    semanticLabel: 'Psychologist',
  );

  factory HappifyEmoji.brain({double size = 40}) =>
      HappifyEmoji._(Fluents.flBrain, size: size, semanticLabel: 'AI insight');

  factory HappifyEmoji.sparkle({double size = 40}) =>
      HappifyEmoji._(Fluents.flSparkles, size: size, semanticLabel: 'Sparkles');

  factory HappifyEmoji.mood({double size = 40}) =>
      HappifyEmoji._(Fluents.flSmilingFace, size: size, semanticLabel: 'Mood');

  factory HappifyEmoji.journal({double size = 40}) =>
      HappifyEmoji._(Fluents.flNotebook, size: size, semanticLabel: 'Journal');

  factory HappifyEmoji.grounding({double size = 40}) => HappifyEmoji._(
    Fluents.flWindFace,
    size: size,
    semanticLabel: 'Grounding',
  );

  factory HappifyEmoji.heatmap({double size = 40}) => HappifyEmoji._(
    Fluents.flWorldMap,
    size: size,
    semanticLabel: 'Mood heatmap',
  );

  factory HappifyEmoji.referral({double size = 40}) => HappifyEmoji._(
    Fluents.flLoveLetter,
    size: size,
    semanticLabel: 'Professional referral',
  );

  factory HappifyEmoji.medical({double size = 40}) => HappifyEmoji._(
    Fluents.flMedicalSymbol,
    size: size,
    semanticLabel: 'Medical support',
  );

  factory HappifyEmoji.shield({double size = 40}) => HappifyEmoji._(
    Fluents.flShield,
    size: size,
    semanticLabel: 'Privacy and safety',
  );

  factory HappifyEmoji.picture({double size = 40}) => HappifyEmoji._(
    Fluents.flFramedPicture,
    size: size,
    semanticLabel: 'Picture',
  );

  factory HappifyEmoji.purpleHeart({double size = 40}) => HappifyEmoji._(
    Fluents.flPurpleHeart,
    size: size,
    semanticLabel: 'Support given',
  );

  factory HappifyEmoji.whiteHeart({double size = 40}) => HappifyEmoji._(
    Fluents.flWhiteHeart,
    size: size,
    semanticLabel: 'Support this post',
  );

  factory HappifyEmoji.greenHeart({double size = 40}) => HappifyEmoji._(
    Fluents.flGreenHeart,
    size: size,
    semanticLabel: 'Mood records',
  );

  factory HappifyEmoji.camera({double size = 40}) =>
      HappifyEmoji._(Fluents.flCamera, size: size, semanticLabel: 'Camera');

  factory HappifyEmoji.notifications({double size = 40}) => HappifyEmoji._(
    Fluents.flBell,
    size: size,
    semanticLabel: 'Notifications',
  );

  factory HappifyEmoji.microphone({double size = 40}) => HappifyEmoji._(
    Fluents.flMicrophone,
    size: size,
    semanticLabel: 'Voice companion',
  );

  factory HappifyEmoji.accessibility({double size = 40}) => HappifyEmoji._(
    Fluents.flWheelchairSymbol,
    size: size,
    semanticLabel: 'Accessibility',
  );

  factory HappifyEmoji.phone({double size = 40}) => HappifyEmoji._(
    Fluents.flTelephoneReceiver,
    size: size,
    semanticLabel: 'Phone',
  );

  factory HappifyEmoji.settings({double size = 40}) =>
      HappifyEmoji._(Fluents.flGear, size: size, semanticLabel: 'Settings');

  factory HappifyEmoji.happy({double size = 40}) => HappifyEmoji._(
    Fluents.flGrinningFaceWithBigEyes,
    size: size,
    semanticLabel: 'Happy',
  );

  factory HappifyEmoji.calm({double size = 40}) =>
      HappifyEmoji._(Fluents.flRelievedFace, size: size, semanticLabel: 'Calm');

  factory HappifyEmoji.neutral({double size = 40}) => HappifyEmoji._(
    Fluents.flNeutralFace,
    size: size,
    semanticLabel: 'Neutral',
  );

  factory HappifyEmoji.anxious({double size = 40}) => HappifyEmoji._(
    Fluents.flAnxiousFaceWithSweat,
    size: size,
    semanticLabel: 'Anxious',
  );

  factory HappifyEmoji.sad({double size = 40}) => HappifyEmoji._(
    Fluents.flDowncastFaceWithSweat,
    size: size,
    semanticLabel: 'Sad',
  );

  factory HappifyEmoji.distressed({double size = 40}) => HappifyEmoji._(
    Fluents.flFaceScreamingInFear,
    size: size,
    semanticLabel: 'Distressed',
  );

  factory HappifyEmoji.companion({double size = 40}) => HappifyEmoji._(
    Fluents.flTeddyBear,
    size: size,
    semanticLabel: 'Happify Companion',
  );

  factory HappifyEmoji.link({double size = 40}) =>
      HappifyEmoji._(Fluents.flLink, size: size, semanticLabel: 'Pair device');

  factory HappifyEmoji.iot({double size = 40}) => HappifyEmoji._(
    Fluents.flAntennaBars,
    size: size,
    semanticLabel: 'IoT connection',
  );

  factory HappifyEmoji.update({double size = 40}) => HappifyEmoji._(
    Fluents.flCounterclockwiseArrowsButton,
    size: size,
    semanticLabel: 'Firmware update',
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: FluentUiEmojiIcon(fl: emoji, w: size, h: size),
    );
  }
}

Widget happifyMoodEmoji(String mood, {double size = 40}) {
  return switch (mood) {
    'HAPPY' => HappifyEmoji.happy(size: size),
    'CALM' => HappifyEmoji.calm(size: size),
    'ANXIOUS' => HappifyEmoji.anxious(size: size),
    'SAD' => HappifyEmoji.sad(size: size),
    'DISTRESSED' => HappifyEmoji.distressed(size: size),
    _ => HappifyEmoji.neutral(size: size),
  };
}

import 'package:colorful_iconify_flutter/icons/fluent_emoji_flat.dart';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';

class HappifyEmoji extends StatelessWidget {
  const HappifyEmoji._(
    this.icon, {
    required this.size,
    required this.semanticLabel,
  });

  final String icon;
  final double size;
  final String semanticLabel;

  factory HappifyEmoji.overview({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.house_with_garden,
    size: size,
    semanticLabel: 'Home',
  );
  factory HappifyEmoji.check({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.check_mark_button,
    size: size,
    semanticLabel: 'Confirm',
  );
  factory HappifyEmoji.back({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.left_arrow,
    size: size,
    semanticLabel: 'Back',
  );
  factory HappifyEmoji.next({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.right_arrow,
    size: size,
    semanticLabel: 'Continue',
  );
  factory HappifyEmoji.email({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.envelope,
    size: size,
    semanticLabel: 'Email',
  );
  factory HappifyEmoji.edit({double size = 40}) =>
      HappifyEmoji._(FluentEmojiFlat.pencil, size: size, semanticLabel: 'Edit');
  factory HappifyEmoji.warning({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.warning,
    size: size,
    semanticLabel: 'Warning',
  );
  factory HappifyEmoji.close({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.cross_mark,
    size: size,
    semanticLabel: 'Close',
  );
  factory HappifyEmoji.eye({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.eye,
    size: size,
    semanticLabel: 'Show password',
  );
  factory HappifyEmoji.play({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.play_button,
    size: size,
    semanticLabel: 'Play',
  );
  factory HappifyEmoji.comment({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.speech_balloon,
    size: size,
    semanticLabel: 'Comment',
  );
  factory HappifyEmoji.report({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.triangular_flag,
    size: size,
    semanticLabel: 'Report',
  );
  factory HappifyEmoji.signOut({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.door,
    size: size,
    semanticLabel: 'Sign out',
  );
  factory HappifyEmoji.records({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.notebook,
    size: size,
    semanticLabel: 'Records',
  );
  factory HappifyEmoji.community({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.people_hugging,
    size: size,
    semanticLabel: 'Community',
  );
  factory HappifyEmoji.care({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.heart_hands,
    size: size,
    semanticLabel: 'Professional care',
  );
  factory HappifyEmoji.chat({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.mobile_phone,
    size: size,
    semanticLabel: 'Chat',
  );
  factory HappifyEmoji.escalation({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.sos_button,
    size: size,
    semanticLabel: 'Urgent support',
  );
  factory HappifyEmoji.history({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.counterclockwise_arrows_button,
    size: size,
    semanticLabel: 'History',
  );
  factory HappifyEmoji.profile({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.bust_in_silhouette,
    size: size,
    semanticLabel: 'Profile',
  );
  factory HappifyEmoji.psychologist({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.health_worker,
    size: size,
    semanticLabel: 'Psychologist',
  );
  factory HappifyEmoji.brain({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.brain,
    size: size,
    semanticLabel: 'AI insight',
  );
  factory HappifyEmoji.sparkle({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.sparkles,
    size: size,
    semanticLabel: 'Highlight',
  );
  factory HappifyEmoji.mood({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.smiling_face,
    size: size,
    semanticLabel: 'Mood',
  );
  factory HappifyEmoji.journal({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.notebook,
    size: size,
    semanticLabel: 'Journal',
  );
  factory HappifyEmoji.grounding({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.wind_face,
    size: size,
    semanticLabel: 'Grounding',
  );
  factory HappifyEmoji.heatmap({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.world_map,
    size: size,
    semanticLabel: 'Mood heatmap',
  );
  factory HappifyEmoji.referral({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.love_letter,
    size: size,
    semanticLabel: 'Professional referral',
  );
  factory HappifyEmoji.medical({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.medical_symbol,
    size: size,
    semanticLabel: 'Medical support',
  );
  factory HappifyEmoji.shield({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.shield,
    size: size,
    semanticLabel: 'Privacy and safety',
  );
  factory HappifyEmoji.picture({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.framed_picture,
    size: size,
    semanticLabel: 'Picture',
  );
  factory HappifyEmoji.purpleHeart({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.purple_heart,
    size: size,
    semanticLabel: 'Support given',
  );
  factory HappifyEmoji.whiteHeart({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.white_heart,
    size: size,
    semanticLabel: 'Support this post',
  );
  factory HappifyEmoji.greenHeart({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.green_heart,
    size: size,
    semanticLabel: 'Mood records',
  );
  factory HappifyEmoji.camera({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.camera,
    size: size,
    semanticLabel: 'Camera',
  );
  factory HappifyEmoji.notifications({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.bell,
    size: size,
    semanticLabel: 'Notifications',
  );
  factory HappifyEmoji.microphone({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.studio_microphone,
    size: size,
    semanticLabel: 'Voice companion',
  );
  factory HappifyEmoji.accessibility({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.wheelchair_symbol,
    size: size,
    semanticLabel: 'Accessibility',
  );
  factory HappifyEmoji.phone({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.mobile_phone,
    size: size,
    semanticLabel: 'Phone',
  );
  factory HappifyEmoji.settings({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.gear,
    size: size,
    semanticLabel: 'Settings',
  );
  factory HappifyEmoji.happy({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.grinning_face_with_big_eyes,
    size: size,
    semanticLabel: 'Happy',
  );
  factory HappifyEmoji.calm({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.relieved_face,
    size: size,
    semanticLabel: 'Calm',
  );
  factory HappifyEmoji.neutral({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.neutral_face,
    size: size,
    semanticLabel: 'Neutral',
  );
  factory HappifyEmoji.anxious({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.anxious_face_with_sweat,
    size: size,
    semanticLabel: 'Anxious',
  );
  factory HappifyEmoji.sad({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.downcast_face_with_sweat,
    size: size,
    semanticLabel: 'Sad',
  );
  factory HappifyEmoji.distressed({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.face_screaming_in_fear,
    size: size,
    semanticLabel: 'Distressed',
  );
  factory HappifyEmoji.companion({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.robot,
    size: size,
    semanticLabel: 'Happify Companion',
  );
  factory HappifyEmoji.link({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.link,
    size: size,
    semanticLabel: 'Pair device',
  );
  factory HappifyEmoji.iot({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.antenna_bars,
    size: size,
    semanticLabel: 'IoT connection',
  );
  factory HappifyEmoji.update({double size = 40}) => HappifyEmoji._(
    FluentEmojiFlat.counterclockwise_arrows_button,
    size: size,
    semanticLabel: 'Firmware update',
  );

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    child: Iconify(icon, size: size),
  );
}

Widget happifyMoodEmoji(String mood, {double size = 40}) => switch (mood) {
  'HAPPY' => HappifyEmoji.happy(size: size),
  'CALM' => HappifyEmoji.calm(size: size),
  'ANXIOUS' => HappifyEmoji.anxious(size: size),
  'SAD' => HappifyEmoji.sad(size: size),
  'DISTRESSED' => HappifyEmoji.distressed(size: size),
  _ => HappifyEmoji.neutral(size: size),
};

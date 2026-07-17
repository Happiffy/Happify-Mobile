import 'package:equatable/equatable.dart';

import '../data/care_chat_realtime.dart';

class CareChatState extends Equatable {
  const CareChatState({
    this.loading = false,
    this.sending = false,
    this.updatingStatus = false,
    this.realtimeStatus = CareChatRealtimeStatus.disconnected,
    this.session = const {},
    this.peerOnline = false,
    this.typingUserId,
    this.typingDisplayName,
    this.errorMessage,
  });

  final bool loading;
  final bool sending;
  final bool updatingStatus;
  final CareChatRealtimeStatus realtimeStatus;
  final Map<String, dynamic> session;
  final bool peerOnline;
  final String? typingUserId;
  final String? typingDisplayName;
  final String? errorMessage;

  CareChatState copyWith({
    bool? loading,
    bool? sending,
    bool? updatingStatus,
    CareChatRealtimeStatus? realtimeStatus,
    Map<String, dynamic>? session,
    bool? peerOnline,
    String? typingUserId,
    String? typingDisplayName,
    String? errorMessage,
    bool clearTyping = false,
    bool clearError = false,
  }) {
    return CareChatState(
      loading: loading ?? this.loading,
      sending: sending ?? this.sending,
      updatingStatus: updatingStatus ?? this.updatingStatus,
      realtimeStatus: realtimeStatus ?? this.realtimeStatus,
      session: session ?? this.session,
      peerOnline: peerOnline ?? this.peerOnline,
      typingUserId: clearTyping ? null : typingUserId ?? this.typingUserId,
      typingDisplayName: clearTyping
          ? null
          : typingDisplayName ?? this.typingDisplayName,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    sending,
    updatingStatus,
    realtimeStatus,
    session,
    peerOnline,
    typingUserId,
    typingDisplayName,
    errorMessage,
  ];
}

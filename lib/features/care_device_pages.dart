import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:record/record.dart';

import '../core/app_services.dart';
import '../core/happify_repository.dart';
import '../core/theme/happify_colors.dart';
import '../core/theme/happify_theme.dart';
import '../core/widgets/common_widgets.dart';
import '../core/widgets/happify_button.dart';
import '../core/widgets/happify_emoji.dart';
import 'companion/bloc_device_detail_sheet.dart';

class _VoiceSession {
  const _VoiceSession({required this.id, required this.turns});

  final String id;
  final List<Map<String, dynamic>> turns;

  DateTime get startedAt {
    final dates = turns
        .map((turn) => DateTime.tryParse(turn['createdAt']?.toString() ?? ''))
        .whereType<DateTime>()
        .toList();
    if (dates.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    dates.sort();
    return dates.first;
  }

  DateTime get latestAt {
    final dates = turns
        .map((turn) => DateTime.tryParse(turn['createdAt']?.toString() ?? ''))
        .whereType<DateTime>()
        .toList();
    if (dates.isEmpty) return startedAt;
    dates.sort();
    return dates.last;
  }
}

class VoicePage extends StatefulWidget {
  const VoicePage({super.key});

  @override
  State<VoicePage> createState() => _VoicePageState();
}

class _VoicePageState extends State<VoicePage> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _recording = false;
  bool _uploading = false;
  bool _loadingTurns = true;
  String? _path;
  String? _error;
  String? _turnsError;
  String? _idempotencyKey;
  late String _sessionId;
  Map<String, dynamic>? _turn;
  List<Map<String, dynamic>> _turns = [];

  @override
  void initState() {
    super.initState();
    _sessionId = _newSessionId();
  }

  String _newSessionId() =>
      'session-${DateTime.now().microsecondsSinceEpoch.toString()}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadingTurns) unawaited(_loadTurns());
  }

  Future<void> _loadTurns() async {
    try {
      final turns = await HappifyRepository(
        AppServices.of(context).auth.api,
      ).voiceTurns(limit: 100);
      if (mounted) {
        setState(() {
          _turns = turns;
          _loadingTurns = false;
          _turnsError = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadingTurns = false;
          _turnsError = failureMessage(error);
        });
      }
    }
  }

  Future<void> _resumeSession(String sessionId) async {
    if (_recording || _uploading || _sessionId == sessionId) return;
    await AppServices.of(context).speech.stop();
    if (!mounted) return;
    setState(() {
      _sessionId = sessionId;
      _path = null;
      _idempotencyKey = null;
      _turn = null;
      _error = null;
    });
  }

  Future<void> _startNewSession() async {
    await AppServices.of(context).speech.stop();
    final path = _path;
    if (path != null) {
      try {
        await File(path).delete();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _sessionId = _newSessionId();
      _path = null;
      _idempotencyKey = null;
      _turn = null;
      _error = null;
    });
  }

  List<_VoiceSession> get _sessions {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final turn in _turns) {
      final turnId = turn['id']?.toString() ?? '';
      final rawSessionId = turn['sessionId']?.toString();
      final sessionId = rawSessionId == null || rawSessionId.isEmpty
          ? 'legacy-$turnId'
          : rawSessionId;
      grouped.putIfAbsent(sessionId, () => []).add(turn);
    }
    final sessions =
        grouped.entries
            .map((entry) => _VoiceSession(id: entry.key, turns: entry.value))
            .toList()
          ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return sessions;
  }

  int get _currentSessionNumber {
    final sessions = _sessions;
    final index = sessions.indexWhere((session) => session.id == _sessionId);
    return index < 0 ? sessions.length + 1 : index + 1;
  }

  Future<bool> _hasVoiceConsent() async {
    final documents = await HappifyRepository(
      AppServices.of(context).auth.api,
    ).consents();
    final latest = <String, Map<String, dynamic>>{};
    for (final document in documents) {
      final scope = document['scope']?.toString();
      if (scope != 'VOICE_PROCESSING') continue;
      final version = (document['version'] as num?)?.toInt() ?? 0;
      final currentVersion = (latest[scope]?['version'] as num?)?.toInt() ?? 0;
      if (version >= currentVersion) latest[scope!] = document;
    }
    return objectList(
      latest['VOICE_PROCESSING']?['consents'],
    ).any((item) => item['status'] == 'ACCEPTED');
  }

  Future<void> _toggleRecording() async {
    if (_recording) {
      final path = await _recorder.stop();
      if (mounted) {
        setState(() {
          _recording = false;
          _path = path;
        });
      }
      return;
    }
    try {
      if (!await _hasVoiceConsent()) {
        if (!mounted) return;
        final review = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Voice consent required'),
            content: const Text(
              'Review and accept the latest voice-processing consent before recording.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Review consent'),
              ),
            ],
          ),
        );
        if (review == true && mounted) await context.push('/consent');
        return;
      }
    } catch (error) {
      if (mounted) showMessage(context, failureMessage(error));
      return;
    }
    if (!await _recorder.hasPermission()) {
      if (mounted) {
        showMessage(
          context,
          'Microphone permission is required to record a voice turn.',
        );
      }
      return;
    }
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}${Platform.pathSeparator}happify-${DateTime.now().millisecondsSinceEpoch}.wav';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    if (mounted) {
      setState(() {
        _recording = true;
        _path = null;
        _idempotencyKey = null;
        _turn = null;
        _error = null;
      });
    }
  }

  Future<void> _upload() async {
    final services = AppServices.of(context);
    final path = _path;
    if (path == null) return;
    final idempotencyKey =
        _idempotencyKey ??
        'mobile-${DateTime.now().microsecondsSinceEpoch.toString()}';
    setState(() {
      _uploading = true;
      _idempotencyKey = idempotencyKey;
    });
    var uploaded = false;
    try {
      final turn = await HappifyRepository(AppServices.of(context).auth.api)
          .uploadVoice(
            File(path),
            idempotencyKey: idempotencyKey,
            sessionId: _sessionId,
            language: 'id',
          );
      uploaded = true;
      if (mounted) {
        setState(() {
          _turn = turn;
          _turns = [turn, ..._turns.where((item) => item['id'] != turn['id'])];
          _error = null;
        });
        final audioUrl = turn['audioUrl']?.toString();
        final risk = turn['riskLevel']?.toString();
        if (services.settings.voiceResponseAutoplay &&
            audioUrl != null &&
            audioUrl.isNotEmpty &&
            risk != 'HIGH' &&
            risk != 'CRISIS') {
          unawaited(
            services.speech
                .playProtected(services.auth.api, audioUrl)
                .catchError((_) {}),
          );
        }
      }
    } catch (error) {
      if (mounted) setState(() => _error = failureMessage(error));
    } finally {
      if (uploaded) {
        try {
          await File(path).delete();
        } catch (_) {}
        if (mounted) {
          setState(() {
            _path = null;
            _idempotencyKey = null;
          });
        }
      }
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = AppServices.of(context);
    final risk = _turn?['riskLevel']?.toString();
    final urgent = risk == 'HIGH' || risk == 'CRISIS';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice companion'),
        actions: [
          TextButton.icon(
            onPressed: _recording || _uploading ? null : _startNewSession,
            icon: Icon(PhosphorIcons.plusCircle(PhosphorIconsStyle.bold)),
            label: const Text('New session'),
          ),
        ],
      ),
      body: HappifyPage(
        refresh: _loadTurns,
        children: [
          Center(child: HappifyEmoji.microphone(size: 76)),

          const SizedBox(height: 16),
          FeatureCard(
            color: HappifyColors.blueSurface,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIcons.chatCircleDots(PhosphorIconsStyle.duotone),
                    color: HappifyColors.blueDark,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sesi $_currentSessionNumber · Sedang berlangsung',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Semua rekaman berikutnya masuk ke sesi ini. Pilih Sesi baru saat memulai topik atau percakapan yang berbeda.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Play AI responses automatically'),
            subtitle: const Text('Responses are spoken after processing.'),
            value: services.settings.voiceResponseAutoplay,
            onChanged: (value) async {
              await services.settings.update(voiceResponseAutoplay: value);
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 8),
          HappifyButton(
            label: _recording ? 'Stop recording' : 'Start recording',
            icon: _recording
                ? PhosphorIcons.stop(PhosphorIconsStyle.fill)
                : PhosphorIcons.microphone(PhosphorIconsStyle.fill),

            onPressed: _uploading ? null : _toggleRecording,
          ),
          if (_path != null && !_recording) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _uploading ? null : _upload,
              icon: Icon(PhosphorIcons.uploadSimple(PhosphorIconsStyle.bold)),

              label: Text(_uploading ? 'Processing...' : 'Upload for response'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            FeatureCard(
              color: HappifyColors.redSurface,
              child: const Text(
                'We could not process this recording. Please try again.',
              ),
            ),
          ],
          if (_turn != null) ...[
            const SizedBox(height: 20),
            FeatureCard(
              color: urgent ? const Color(0xFFFBE4DE) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voice result',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Transcript: ${_turn!['transcript'] ?? 'No transcript returned.'}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Response: ${_turn!['responseText'] ?? 'No text response returned.'}',
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _VoiceResultChip(
                        label: 'Mood',
                        value: prettyEnum(_turn!['detectedMood']),
                        color: moodColor(
                          _turn!['detectedMood']?.toString() ?? 'NEUTRAL',
                        ),
                      ),
                      _VoiceResultChip(
                        label: 'Risk',
                        value: prettyEnum(risk),
                        color: urgent
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                  if (_turn!['emotionConfidence'] case final num confidence)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Mood confidence: ${(confidence * 100).round()}%',
                      ),
                    ),
                  if (_turn!['audioUrl'] != null) ...[
                    const SizedBox(height: 10),
                    ListenableBuilder(
                      listenable: services.speech,
                      builder: (context, _) => services.speech.playing
                          ? OutlinedButton.icon(
                              onPressed: services.speech.stop,
                              icon: Icon(
                                PhosphorIcons.stop(PhosphorIconsStyle.fill),
                              ),
                              label: const Text('Stop response'),
                            )
                          : const Text(
                              'Your AI companion response is spoken automatically.',
                            ),
                    ),
                  ],
                  if (urgent) ...[
                    const Divider(),
                    const Text(
                      'Happify detected urgent risk and the backend created a professional care referral. If you may be in immediate danger, contact local emergency services or someone you trust now.',
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => context.push('/care'),
                      child: const Text('Open care support'),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text('Riwayat sesi', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          AsyncStateView(
            loading: _loadingTurns,
            error: _turnsError,
            isEmpty: !_loadingTurns && _turns.isEmpty,
            emptyMessage:
                'Riwayat sesi akan muncul setelah rekaman pertama diproses.',
            onRetry: _loadTurns,
            child: Column(
              children: _sessions.reversed.take(10).map((session) {
                final sessionNumber = _sessions.indexOf(session) + 1;
                final active = session.id == _sessionId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FeatureCard(
                    color: active ? HappifyColors.blueSurface : null,
                    onTap: () => _resumeSession(session.id),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              PhosphorIcons.chatCircleText(
                                PhosphorIconsStyle.duotone,
                              ),
                              color: HappifyColors.blueDark,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sesi $sessionNumber',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${session.turns.length} rekaman · ${shortDate(session.startedAt)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? HappifyColors.greenSurface
                                    : HappifyColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(
                                  HappifyRadii.pill,
                                ),
                              ),
                              child: Text(
                                active ? 'Aktif' : 'Tersimpan',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          active
                              ? 'Tap to keep talking in this session.'
                              : 'Tap to continue this session.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceResultChip extends StatelessWidget {
  const _VoiceResultChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: .45)),
        ),
        child: Text('$label: $value'),
      ),
    );
  }
}

class CarePage extends StatefulWidget {
  const CarePage({this.sessionId, super.key});
  final String? sessionId;

  @override
  State<CarePage> createState() => _CarePageState();
}

class _CarePageState extends State<CarePage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _providers = [];
  List<Map<String, dynamic>> _referrals = [];
  List<Map<String, dynamic>> _chats = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final repo = HappifyRepository(AppServices.of(context).auth.api);
      final results = await Future.wait<Object?>([
        repo.providers(),
        repo.referrals(),
        repo.chats(),
      ]);
      if (mounted) {
        setState(() {
          _providers = results[0]! as List<Map<String, dynamic>>;
          _referrals = results[1]! as List<Map<String, dynamic>>;
          _chats = results[2]! as List<Map<String, dynamic>>;
          _loading = false;
          _error = null;
        });
      }
      if (widget.sessionId != null && mounted) {
        unawaited(_openChat(widget.sessionId!));
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = failureMessage(error);
          _loading = false;
        });
      }
    }
  }

  Future<void> _request([Map<String, dynamic>? provider]) async {
    final reason = await showTextPrompt(
      context,
      title: 'Request professional care',
      label: 'What support do you need?',
      maxLines: 4,
    );
    if (reason == null || reason.isEmpty || !mounted) return;
    try {
      await HappifyRepository(AppServices.of(context).auth.api).createReferral(
        riskLevel: 'MEDIUM',
        reason: reason,
        requestComment: reason,
        provider: provider,
      );
      if (!mounted) return;
      showMessage(context, 'Care request submitted.');
      await _load();
    } catch (error) {
      if (mounted) showMessage(context, failureMessage(error));
    }
  }

  Future<void> _openChat(String id) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CareChatSheet(sessionId: id),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Professional care')),
      body: HappifyPage(
        refresh: _load,
        children: [
          const FeatureCard(
            color: Color(0xFFE6DCF0),
            child: Text(
              'Happify can connect signed-in users with configured care providers. It does not diagnose or replace emergency services.',
            ),
          ),
          const SizedBox(height: 12),
          AsyncStateView(
            loading: _loading,
            error: _error,
            isEmpty: _providers.isEmpty && _referrals.isEmpty && _chats.isEmpty,
            emptyMessage: 'No providers, referrals, or chats are available.',
            onRetry: () {
              setState(() => _loading = true);
              unawaited(_load());
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilledButton.icon(
                  onPressed: () => _request(),
                  icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold)),
                  label: const Text('New care request'),
                ),
                const SizedBox(height: 18),
                Text(
                  'Referral status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_referrals.isEmpty) const Text('No care requests yet.'),
                ..._referrals.map(
                  (item) => ListTile(
                    leading: HappifyEmoji.medical(size: 34),
                    title: Text(item['reason'].toString()),
                    subtitle: Text(
                      '${prettyEnum(item['status'])} · ${prettyEnum(item['riskLevel'])} · ${shortDate(item['createdAt'])}',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Care chats',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_chats.isEmpty)
                  const Text('Accepted referrals will create care chats here.'),
                ..._chats.map(
                  (chat) => ListTile(
                    onTap: () => _openChat(chat['id'].toString()),
                    leading: HappifyEmoji.chat(size: 34),
                    title: Text(
                      objectMap(
                            chat['psychologist'],
                          )['displayName']?.toString() ??
                          'Care professional',
                    ),
                    subtitle: Text(
                      '${prettyEnum(chat['status'])} · ${shortDate(chat['updatedAt'])}',
                    ),
                    trailing: Icon(
                      PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Providers',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_providers.isEmpty)
                  const Text('No active providers are configured.'),
                ..._providers.map(
                  (provider) => FeatureCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider['name'].toString(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${prettyEnum(provider['type'])} · ${provider['region']}',
                        ),
                        Text(provider['description'].toString()),
                        TextButton(
                          onPressed: () => _request(provider),
                          child: const Text('Request this provider'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CareChatSheet extends StatefulWidget {
  const CareChatSheet({required this.sessionId, super.key});
  final String sessionId;

  @override
  State<CareChatSheet> createState() => _CareChatSheetState();
}

class _CareChatSheetState extends State<CareChatSheet> {
  final _message = TextEditingController();
  bool _loading = true;
  Map<String, dynamic> _session = {};
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final session = await HappifyRepository(
        AppServices.of(context).auth.api,
      ).chat(widget.sessionId);
      if (mounted) {
        setState(() {
          _session = session;
          _loading = false;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = failureMessage(error);
          _loading = false;
        });
      }
    }
  }

  Future<void> _send() async {
    if (_message.text.trim().isEmpty) return;
    try {
      await HappifyRepository(
        AppServices.of(context).auth.api,
      ).sendChat(widget.sessionId, _message.text.trim());
      _message.clear();
      await _load();
    } catch (error) {
      if (mounted) showMessage(context, failureMessage(error));
    }
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = objectList(_session['messages']);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .88,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Care chat',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final next = _session['status'] == 'OPEN'
                          ? 'CLOSED'
                          : 'OPEN';
                      await HappifyRepository(
                        AppServices.of(context).auth.api,
                      ).updateChatStatus(widget.sessionId, next);
                      await _load();
                    },
                    child: Text(
                      _session['status'] == 'OPEN'
                          ? 'Close chat'
                          : 'Reopen chat',
                    ),
                  ),
                ],
              ),
              if (_error != null)
                const Text('Care chat is temporarily unavailable.'),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : messages.isEmpty
                    ? const Center(child: Text('No messages yet.'))
                    : ListView(
                        children: messages.map((item) {
                          final sender = objectMap(item['sender']);
                          return ListTile(
                            title: Text(
                              sender['displayName']?.toString() ??
                                  prettyEnum(sender['role']),
                            ),
                            subtitle: Text(item['content']?.toString() ?? ''),
                            trailing: Text(shortDate(item['createdAt'])),
                          );
                        }).toList(),
                      ),
              ),
              if (_session['summary'] != null)
                FeatureCard(child: Text('Summary: ${_session['summary']}')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _message,
                      enabled: _session['status'] == 'OPEN',
                      maxLength: 1200,
                      decoration: const InputDecoration(labelText: 'Message'),
                    ),
                  ),
                  IconButton(
                    onPressed: _session['status'] == 'OPEN' ? _send : null,
                    icon: Icon(
                      PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.bold),
                    ),
                    tooltip: 'Send message',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompanionPage extends StatefulWidget {
  const CompanionPage({super.key});

  @override
  State<CompanionPage> createState() => _CompanionPageState();
}

class _CompanionPageState extends State<CompanionPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _devices = [];
  Map<String, dynamic>? _pairing;
  Timer? _pairTimer;
  Duration _remaining = Duration.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final devices = await HappifyRepository(
        AppServices.of(context).auth.api,
      ).devices();
      if (mounted) {
        setState(() {
          _devices = devices;
          _loading = false;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = failureMessage(error);
          _loading = false;
        });
      }
    }
  }

  Future<void> _startPairing() async {
    final serial = TextEditingController();
    final secret = TextEditingController();
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Companion pairing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: serial,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Serial number'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: secret,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Claim code'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start'),
          ),
        ],
      ),
    );
    if (proceed == true && mounted) {
      try {
        final session = await HappifyRepository(
          AppServices.of(context).auth.api,
        ).startPairing(serial.text.trim(), secret.text);
        setState(() => _pairing = session);
        _startCountdown();
      } catch (error) {
        if (mounted) showMessage(context, failureMessage(error));
      }
    }
    serial.dispose();
    secret.dispose();
  }

  void _startCountdown() {
    _pairTimer?.cancel();
    _updateRemaining();
    _pairTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateRemaining(),
    );
  }

  void _updateRemaining() {
    final expires = DateTime.tryParse(_pairing?['expiresAt']?.toString() ?? '');
    if (expires == null || !mounted) return;
    final remaining = expires.difference(DateTime.now().toUtc());
    setState(
      () => _remaining = remaining.isNegative ? Duration.zero : remaining,
    );
    if (remaining.isNegative) _pairTimer?.cancel();
  }

  Future<void> _refreshPairing() async {
    final id = _pairing?['id']?.toString();
    if (id == null) return;
    try {
      final session = await HappifyRepository(
        AppServices.of(context).auth.api,
      ).pairing(id);
      if (mounted) setState(() => _pairing = session);
    } catch (error) {
      if (mounted) showMessage(context, failureMessage(error));
    }
  }

  @override
  void dispose() {
    _pairTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Happify Companion')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startPairing,
        icon: Icon(PhosphorIcons.link(PhosphorIconsStyle.bold)),
        label: const Text('Pair device'),
      ),
      body: HappifyPage(
        refresh: _load,
        children: [
          Center(child: HappifyEmoji.companion(size: 96)),
          const SizedBox(height: 12),
          if (_pairing != null) ...[
            FeatureCard(
              color: const Color(0xFFF7E0C7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pairing ${prettyEnum(_pairing!['status'])}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Time remaining: ${_remaining.inMinutes}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                  ),
                  Text(
                    'Device: ${objectMap(_pairing!['device'])['serialNumber'] ?? ''}',
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: _refreshPairing,
                        child: const Text('Refresh status'),
                      ),
                      FilledButton(
                        onPressed: _remaining == Duration.zero
                            ? null
                            : () async {
                                await HappifyRepository(
                                  AppServices.of(context).auth.api,
                                ).completePairing(_pairing!['id'].toString());
                                _pairTimer?.cancel();
                                setState(() => _pairing = null);
                                await _load();
                              },
                        child: const Text('Complete'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await HappifyRepository(
                            AppServices.of(context).auth.api,
                          ).cancelPairing(_pairing!['id'].toString());
                          _pairTimer?.cancel();
                          setState(() => _pairing = null);
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          AsyncStateView(
            loading: _loading,
            error: _error,
            isEmpty: _devices.isEmpty,
            emptyMessage: 'No Companion is paired with this account.',
            onRetry: () {
              setState(() => _loading = true);
              unawaited(_load());
            },
            child: Column(
              children: _devices
                  .map(
                    (device) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FeatureCard(
                        onTap: () async {
                          final changed = await showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) =>
                                BlocDeviceDetailSheet(device: device),
                          );
                          if (changed == true && mounted) {
                            await _load();
                          }
                        },
                        child: Row(
                          children: [
                            HappifyEmoji.companion(size: 34),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device['displayName']?.toString() ??
                                        device['model'].toString(),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  Text(
                                    '${device['serialNumber']} · ${prettyEnum(device['status'])}',
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

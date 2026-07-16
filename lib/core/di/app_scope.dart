import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/care/data/care_chat_realtime.dart';
import '../../features/care/data/care_repository.dart';
import '../../features/companion/data/companion_repository.dart';
import '../app_services.dart';
import '../happify_repository.dart';

class AppScope extends StatelessWidget {
  const AppScope({required this.auth, required this.child, super.key});

  final AuthController auth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<HappifyRepository>(
          create: (_) => HappifyRepository(auth.api),
        ),
        RepositoryProvider<CareRepository>(
          create: (context) =>
              CareRepository(context.read<HappifyRepository>()),
        ),
        RepositoryProvider<CareChatRealtimeFactory>(
          create: (_) =>
              CareChatRealtimeFactory(tokenProvider: auth.freshToken),
        ),
        RepositoryProvider<CompanionRepository>(
          create: (context) =>
              CompanionRepository(context.read<HappifyRepository>()),
        ),
      ],
      child: child,
    );
  }
}

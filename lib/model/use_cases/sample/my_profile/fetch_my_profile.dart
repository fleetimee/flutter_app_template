import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../utils/logger.dart';
import '../../../../utils/provider.dart';
import '../../../entities/sample/developer.dart';
import '../../../repositories/firebase_auth/firebase_auth_repository.dart';
import '../../../repositories/firestore/document_repository.dart';

final fetchMyProfileProvider = StreamProvider<Developer?>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState == AuthState.noSignIn) {
    return Stream.value(null);
  }
  final userId = ref.read(firebaseAuthRepositoryProvider).loggedInUserId;
  if (userId == null) {
    return Stream.value(null);
  }
  logger.info('userId: $userId');
  return ref
      .read(documentRepositoryProvider)
      .snapshots(Developer.docPath(userId))
      .map((event) {
    final data = event.data();
    return data != null ? Developer.fromJson(data) : null;
  });
});

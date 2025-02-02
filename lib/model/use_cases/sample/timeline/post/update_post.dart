import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../entities/sample/developer.dart';
import '../../../../entities/sample/enum/operation_type.dart';
import '../../../../entities/sample/timeline/post.dart';
import '../../../../repositories/firebase_auth/firebase_auth_repository.dart';
import '../../../../repositories/firestore/document_repository.dart';
import 'post_operation_observer.dart';

final updatePostProvider = Provider(UpdatePost.new);

class UpdatePost {
  UpdatePost(this._ref);
  final Ref _ref;

  Future<void> call({
    required Post oldPost,
    required String text,
  }) async {
    /// 自身のユーザIDを取得
    final userId = _ref.read(firebaseAuthRepositoryProvider).loggedInUserId;
    if (userId == null) {
      return;
    }

    /// 更新する投稿データを設定
    final postId = oldPost.postId;
    final newPost = oldPost.copyWith(
      text: text,
      updatedAt: DateTime.now(), // オブザーバー用に設定
    );

    /// サーバーへ保存する
    await _ref.read(documentRepositoryProvider).update(
          Developer.postDocPath(
            userId: userId,
            docId: postId,
          ),
          data: newPost.toUpdateDoc,
        );

    /// 更新したことをアプリ内へ通知
    _ref.read(postOperationObserverProvider).add(
          OperationData(
            type: OperationType.update,
            post: newPost,
          ),
        );
  }
}

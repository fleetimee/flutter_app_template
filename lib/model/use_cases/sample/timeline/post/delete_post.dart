import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../entities/sample/developer.dart';
import '../../../../entities/sample/enum/operation_type.dart';
import '../../../../entities/sample/timeline/post.dart';
import '../../../../repositories/firebase_auth/firebase_auth_repository.dart';
import '../../../../repositories/firestore/document_repository.dart';
import 'post_operation_observer.dart';

final deletePostProvider = Provider(DeletePost.new);

class DeletePost {
  DeletePost(this._ref);
  final Ref _ref;

  Future<void> call(Post post) async {
    /// 自身のユーザIDを取得
    final userId = _ref.read(firebaseAuthRepositoryProvider).loggedInUserId;
    if (userId == null) {
      return;
    }

    /// 削除する投稿データを設定
    final postId = post.postId;

    /// サーバーへ保存する
    await _ref.read(documentRepositoryProvider).remove(
          Developer.postDocPath(
            userId: userId,
            docId: postId,
          ),
        );

    /// 削除したことをアプリ内へ通知
    _ref.read(postOperationObserverProvider).add(
          OperationData(
            type: OperationType.delete,
            post: post,
          ),
        );
  }
}

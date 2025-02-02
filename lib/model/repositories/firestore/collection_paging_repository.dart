import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'document.dart';

final collectionPagingRepositoryProvider = Provider.family
    .autoDispose<CollectionPagingRepository, CollectionParam>((ref, query) {
  return CollectionPagingRepository(
    query: query.query,
    limit: query.limit,
    decode: query.decode,
  );
});

/// https://docs-v2.riverpod.dev/docs/concepts/modifiers/family#passing-multiple-parameters-to-a-family
class CollectionParam<T extends Object> extends Equatable {
  const CollectionParam({
    required this.query,
    this.limit,
    required this.decode,
  });
  final Query<Map<String, dynamic>> query;
  final int? limit;
  final T Function(Map<String, dynamic>) decode;

  @override
  List<Object?> get props => [query, limit, decode];
}

class CollectionPagingRepository<T extends Object> {
  CollectionPagingRepository({
    required this.query,
    this.limit,
    required this.decode,
  });

  final Query<Map<String, dynamic>> query;
  final int? limit;
  final T Function(Map<String, dynamic>) decode;
  DocumentSnapshot<Map<String, dynamic>>? _startAfterDocument;

  Future<List<Document<T>>> fetch({
    Source source = Source.serverAndCache,
    void Function(List<Document<T>>)? fromCache,
  }) async {
    if (fromCache != null) {
      try {
        final cacheDocuments = await _fetch(source: Source.cache);
        fromCache(
          cacheDocuments
              .map(
                (e) => Document(
                  ref: e.reference,
                  exists: e.exists,
                  entity: e.exists ? decode(e.data()!) : null,
                ),
              )
              .toList(),
        );
      } on Exception catch (_) {
        fromCache([]);
      }
    }
    final documents = await _fetch(source: source);
    return documents
        .map(
          (e) => Document(
            ref: e.reference,
            exists: e.exists,
            entity: e.exists ? decode(e.data()!) : null,
          ),
        )
        .toList();
  }

  Future<List<Document<T>>> fetchMore({
    Source source = Source.serverAndCache,
  }) async {
    if (_startAfterDocument == null) {
      return [];
    }
    final documents =
        await _fetch(source: source, startAfterDocument: _startAfterDocument);
    return documents
        .map(
          (e) => Document(
            ref: e.reference,
            exists: e.exists,
            entity: e.exists ? decode(e.data()!) : null,
          ),
        )
        .toList();
  }

  Future<List<DocumentSnapshot<Map<String, dynamic>>>> _fetch({
    Source source = Source.serverAndCache,
    DocumentSnapshot? startAfterDocument,
  }) async {
    var dataSource = query;
    if (limit != null) {
      dataSource = dataSource.limit(limit!);
    }
    if (startAfterDocument != null) {
      dataSource = dataSource.startAfterDocument(startAfterDocument);
    }
    final result = await dataSource.get(GetOptions(source: source));
    final documents = result.docs.toList();

    if (documents.isNotEmpty) {
      _startAfterDocument = documents.last;
    }
    return documents;
  }
}

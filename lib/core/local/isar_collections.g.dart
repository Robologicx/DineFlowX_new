// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_collections.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

int _jsSafeInt(String value) => int.parse(value);

extension GetLocalBusinessRecordCollection on Isar {
  IsarCollection<LocalBusinessRecord> get localBusinessRecords =>
      this.collection();
}

final LocalBusinessRecordSchema = CollectionSchema(
  name: r'LocalBusinessRecord',
  id: _jsSafeInt('6417491974066690786'),
  properties: {
    r'documentId': PropertySchema(
      id: 0,
      name: r'documentId',
      type: IsarType.string,
    ),
    r'isDeleted': PropertySchema(
      id: 1,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'payloadJson': PropertySchema(
      id: 2,
      name: r'payloadJson',
      type: IsarType.string,
    ),
    r'pendingSync': PropertySchema(
      id: 3,
      name: r'pendingSync',
      type: IsarType.bool,
    ),
    r'updatedAtMs': PropertySchema(
      id: 4,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
  },
  estimateSize: _localBusinessRecordEstimateSize,
  serialize: _localBusinessRecordSerialize,
  deserialize: _localBusinessRecordDeserialize,
  deserializeProp: _localBusinessRecordDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'documentId': IndexSchema(
      id: _jsSafeInt('4187168439921340405'),
      name: r'documentId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'documentId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'isDeleted': IndexSchema(
      id: _jsSafeInt('-786475870904832312'),
      name: r'isDeleted',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isDeleted',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'pendingSync': IndexSchema(
      id: _jsSafeInt('6092646898846083691'),
      name: r'pendingSync',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'pendingSync',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _localBusinessRecordGetId,
  getLinks: _localBusinessRecordGetLinks,
  attach: _localBusinessRecordAttach,
  version: '3.1.0+1',
);

int _localBusinessRecordEstimateSize(
  LocalBusinessRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.documentId.length * 3;
  bytesCount += 3 + object.payloadJson.length * 3;
  return bytesCount;
}

void _localBusinessRecordSerialize(
  LocalBusinessRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.documentId);
  writer.writeBool(offsets[1], object.isDeleted);
  writer.writeString(offsets[2], object.payloadJson);
  writer.writeBool(offsets[3], object.pendingSync);
  writer.writeLong(offsets[4], object.updatedAtMs);
}

LocalBusinessRecord _localBusinessRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LocalBusinessRecord();
  object.documentId = reader.readString(offsets[0]);
  object.isDeleted = reader.readBool(offsets[1]);
  object.isarId = id;
  object.payloadJson = reader.readString(offsets[2]);
  object.pendingSync = reader.readBool(offsets[3]);
  object.updatedAtMs = reader.readLong(offsets[4]);
  return object;
}

P _localBusinessRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _localBusinessRecordGetId(LocalBusinessRecord object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _localBusinessRecordGetLinks(
  LocalBusinessRecord object,
) {
  return [];
}

void _localBusinessRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  LocalBusinessRecord object,
) {
  object.isarId = id;
}

extension LocalBusinessRecordByIndex on IsarCollection<LocalBusinessRecord> {
  Future<LocalBusinessRecord?> getByDocumentId(String documentId) {
    return getByIndex(r'documentId', [documentId]);
  }

  LocalBusinessRecord? getByDocumentIdSync(String documentId) {
    return getByIndexSync(r'documentId', [documentId]);
  }

  Future<bool> deleteByDocumentId(String documentId) {
    return deleteByIndex(r'documentId', [documentId]);
  }

  bool deleteByDocumentIdSync(String documentId) {
    return deleteByIndexSync(r'documentId', [documentId]);
  }

  Future<List<LocalBusinessRecord?>> getAllByDocumentId(
    List<String> documentIdValues,
  ) {
    final values = documentIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'documentId', values);
  }

  List<LocalBusinessRecord?> getAllByDocumentIdSync(
    List<String> documentIdValues,
  ) {
    final values = documentIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'documentId', values);
  }

  Future<int> deleteAllByDocumentId(List<String> documentIdValues) {
    final values = documentIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'documentId', values);
  }

  int deleteAllByDocumentIdSync(List<String> documentIdValues) {
    final values = documentIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'documentId', values);
  }

  Future<Id> putByDocumentId(LocalBusinessRecord object) {
    return putByIndex(r'documentId', object);
  }

  Id putByDocumentIdSync(LocalBusinessRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'documentId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDocumentId(List<LocalBusinessRecord> objects) {
    return putAllByIndex(r'documentId', objects);
  }

  List<Id> putAllByDocumentIdSync(
    List<LocalBusinessRecord> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'documentId', objects, saveLinks: saveLinks);
  }
}

extension LocalBusinessRecordQueryWhereSort
    on QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QWhere> {
  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterWhere>
  anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterWhere>
  anyIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isDeleted'),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterWhere>
  anyPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'pendingSync'),
      );
    });
  }
}

extension LocalBusinessRecordQueryWhere
    on QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QWhereClause> {
  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterWhereClause>
  isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(lower: isarId, upper: isarId),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterWhereClause>
  isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterWhereClause>
  isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterWhereClause>
  isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterWhereClause>
  isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerIsarId,
          includeLower: includeLower,
          upper: upperIsarId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterWhereClause>
  documentIdEqualTo(String documentId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'documentId', value: [documentId]),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterWhereClause>
  documentIdNotEqualTo(String documentId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'documentId',
                lower: [],
                upper: [documentId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'documentId',
                lower: [documentId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'documentId',
                lower: [documentId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'documentId',
                lower: [],
                upper: [documentId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterWhereClause>
  isDeletedEqualTo(bool isDeleted) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'isDeleted', value: [isDeleted]),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterWhereClause>
  isDeletedNotEqualTo(bool isDeleted) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isDeleted',
                lower: [],
                upper: [isDeleted],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isDeleted',
                lower: [isDeleted],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isDeleted',
                lower: [isDeleted],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isDeleted',
                lower: [],
                upper: [isDeleted],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterWhereClause>
  pendingSyncEqualTo(bool pendingSync) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'pendingSync',
          value: [pendingSync],
        ),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterWhereClause>
  pendingSyncNotEqualTo(bool pendingSync) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pendingSync',
                lower: [],
                upper: [pendingSync],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pendingSync',
                lower: [pendingSync],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pendingSync',
                lower: [pendingSync],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pendingSync',
                lower: [],
                upper: [pendingSync],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension LocalBusinessRecordQueryFilter
    on
        QueryBuilder<
          LocalBusinessRecord,
          LocalBusinessRecord,
          QFilterCondition
        > {
  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  documentIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'documentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  documentIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'documentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  documentIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'documentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  documentIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'documentId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  documentIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'documentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  documentIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'documentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  documentIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'documentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  documentIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'documentId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  documentIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'documentId', value: ''),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  documentIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'documentId', value: ''),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isDeleted', value: value),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isarId', value: value),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  isarIdGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  isarIdLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'isarId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  payloadJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  payloadJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  payloadJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  payloadJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'payloadJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  payloadJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  payloadJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  payloadJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  payloadJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'payloadJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  payloadJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'payloadJson', value: ''),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  payloadJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'payloadJson', value: ''),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  pendingSyncEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'pendingSync', value: value),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAtMs', value: value),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  updatedAtMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  updatedAtMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterFilterCondition>
  updatedAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension LocalBusinessRecordQueryObject
    on
        QueryBuilder<
          LocalBusinessRecord,
          LocalBusinessRecord,
          QFilterCondition
        > {}

extension LocalBusinessRecordQueryLinks
    on
        QueryBuilder<
          LocalBusinessRecord,
          LocalBusinessRecord,
          QFilterCondition
        > {}

extension LocalBusinessRecordQuerySortBy
    on QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QSortBy> {
  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterSortBy>
  sortByDocumentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.asc);
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterSortBy>
  sortByDocumentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.desc);
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterSortBy>
  sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterSortBy>
  sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterSortBy>
  sortByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterSortBy>
  sortByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterSortBy>
  sortByPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingSync', Sort.asc);
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterSortBy>
  sortByPendingSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingSync', Sort.desc);
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterSortBy>
  sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterSortBy>
  sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension LocalBusinessRecordQuerySortThenBy
    on QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QSortThenBy> {
  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterSortBy>
  thenByDocumentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.asc);
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterSortBy>
  thenByDocumentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.desc);
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterSortBy>
  thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterSortBy>
  thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterSortBy>
  thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterSortBy>
  thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterSortBy>
  thenByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterSortBy>
  thenByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterSortBy>
  thenByPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingSync', Sort.asc);
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterSortBy>
  thenByPendingSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingSync', Sort.desc);
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterSortBy>
  thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QAfterSortBy>
  thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension LocalBusinessRecordQueryWhereDistinct
    on QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QDistinct> {
  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QDistinct>
  distinctByDocumentId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'documentId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QDistinct>
  distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QDistinct>
  distinctByPayloadJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payloadJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QDistinct>
  distinctByPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pendingSync');
    });
  }

  QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QDistinct>
  distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension LocalBusinessRecordQueryProperty
    on QueryBuilder<LocalBusinessRecord, LocalBusinessRecord, QQueryProperty> {
  QueryBuilder<LocalBusinessRecord, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<LocalBusinessRecord, String, QQueryOperations>
  documentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'documentId');
    });
  }

  QueryBuilder<LocalBusinessRecord, bool, QQueryOperations>
  isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<LocalBusinessRecord, String, QQueryOperations>
  payloadJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payloadJson');
    });
  }

  QueryBuilder<LocalBusinessRecord, bool, QQueryOperations>
  pendingSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pendingSync');
    });
  }

  QueryBuilder<LocalBusinessRecord, int, QQueryOperations>
  updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLocalBranchScopedRecordCollection on Isar {
  IsarCollection<LocalBranchScopedRecord> get localBranchScopedRecords =>
      this.collection();
}

final LocalBranchScopedRecordSchema = CollectionSchema(
  name: r'LocalBranchScopedRecord',
  id: _jsSafeInt('3344294200222150181'),
  properties: {
    r'branchId': PropertySchema(
      id: 0,
      name: r'branchId',
      type: IsarType.string,
    ),
    r'businessId': PropertySchema(
      id: 1,
      name: r'businessId',
      type: IsarType.string,
    ),
    r'collectionName': PropertySchema(
      id: 2,
      name: r'collectionName',
      type: IsarType.string,
    ),
    r'documentId': PropertySchema(
      id: 3,
      name: r'documentId',
      type: IsarType.string,
    ),
    r'isDeleted': PropertySchema(
      id: 4,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'payloadJson': PropertySchema(
      id: 5,
      name: r'payloadJson',
      type: IsarType.string,
    ),
    r'pendingSync': PropertySchema(
      id: 6,
      name: r'pendingSync',
      type: IsarType.bool,
    ),
    r'uniqueKey': PropertySchema(
      id: 7,
      name: r'uniqueKey',
      type: IsarType.string,
    ),
    r'updatedAtMs': PropertySchema(
      id: 8,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
  },
  estimateSize: _localBranchScopedRecordEstimateSize,
  serialize: _localBranchScopedRecordSerialize,
  deserialize: _localBranchScopedRecordDeserialize,
  deserializeProp: _localBranchScopedRecordDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'uniqueKey': IndexSchema(
      id: _jsSafeInt('-866995956150369819'),
      name: r'uniqueKey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uniqueKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'businessId': IndexSchema(
      id: _jsSafeInt('2228048290814354584'),
      name: r'businessId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'businessId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'branchId': IndexSchema(
      id: _jsSafeInt('2037049677925728410'),
      name: r'branchId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'branchId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'collectionName': IndexSchema(
      id: _jsSafeInt('-4238329797778617380'),
      name: r'collectionName',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'collectionName',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'documentId': IndexSchema(
      id: _jsSafeInt('4187168439921340405'),
      name: r'documentId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'documentId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'isDeleted': IndexSchema(
      id: _jsSafeInt('-786475870904832312'),
      name: r'isDeleted',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isDeleted',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'pendingSync': IndexSchema(
      id: _jsSafeInt('6092646898846083691'),
      name: r'pendingSync',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'pendingSync',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _localBranchScopedRecordGetId,
  getLinks: _localBranchScopedRecordGetLinks,
  attach: _localBranchScopedRecordAttach,
  version: '3.1.0+1',
);

int _localBranchScopedRecordEstimateSize(
  LocalBranchScopedRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.branchId.length * 3;
  bytesCount += 3 + object.businessId.length * 3;
  bytesCount += 3 + object.collectionName.length * 3;
  bytesCount += 3 + object.documentId.length * 3;
  bytesCount += 3 + object.payloadJson.length * 3;
  bytesCount += 3 + object.uniqueKey.length * 3;
  return bytesCount;
}

void _localBranchScopedRecordSerialize(
  LocalBranchScopedRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.branchId);
  writer.writeString(offsets[1], object.businessId);
  writer.writeString(offsets[2], object.collectionName);
  writer.writeString(offsets[3], object.documentId);
  writer.writeBool(offsets[4], object.isDeleted);
  writer.writeString(offsets[5], object.payloadJson);
  writer.writeBool(offsets[6], object.pendingSync);
  writer.writeString(offsets[7], object.uniqueKey);
  writer.writeLong(offsets[8], object.updatedAtMs);
}

LocalBranchScopedRecord _localBranchScopedRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LocalBranchScopedRecord();
  object.branchId = reader.readString(offsets[0]);
  object.businessId = reader.readString(offsets[1]);
  object.collectionName = reader.readString(offsets[2]);
  object.documentId = reader.readString(offsets[3]);
  object.isDeleted = reader.readBool(offsets[4]);
  object.isarId = id;
  object.payloadJson = reader.readString(offsets[5]);
  object.pendingSync = reader.readBool(offsets[6]);
  object.uniqueKey = reader.readString(offsets[7]);
  object.updatedAtMs = reader.readLong(offsets[8]);
  return object;
}

P _localBranchScopedRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _localBranchScopedRecordGetId(LocalBranchScopedRecord object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _localBranchScopedRecordGetLinks(
  LocalBranchScopedRecord object,
) {
  return [];
}

void _localBranchScopedRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  LocalBranchScopedRecord object,
) {
  object.isarId = id;
}

extension LocalBranchScopedRecordByIndex
    on IsarCollection<LocalBranchScopedRecord> {
  Future<LocalBranchScopedRecord?> getByUniqueKey(String uniqueKey) {
    return getByIndex(r'uniqueKey', [uniqueKey]);
  }

  LocalBranchScopedRecord? getByUniqueKeySync(String uniqueKey) {
    return getByIndexSync(r'uniqueKey', [uniqueKey]);
  }

  Future<bool> deleteByUniqueKey(String uniqueKey) {
    return deleteByIndex(r'uniqueKey', [uniqueKey]);
  }

  bool deleteByUniqueKeySync(String uniqueKey) {
    return deleteByIndexSync(r'uniqueKey', [uniqueKey]);
  }

  Future<List<LocalBranchScopedRecord?>> getAllByUniqueKey(
    List<String> uniqueKeyValues,
  ) {
    final values = uniqueKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'uniqueKey', values);
  }

  List<LocalBranchScopedRecord?> getAllByUniqueKeySync(
    List<String> uniqueKeyValues,
  ) {
    final values = uniqueKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uniqueKey', values);
  }

  Future<int> deleteAllByUniqueKey(List<String> uniqueKeyValues) {
    final values = uniqueKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uniqueKey', values);
  }

  int deleteAllByUniqueKeySync(List<String> uniqueKeyValues) {
    final values = uniqueKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uniqueKey', values);
  }

  Future<Id> putByUniqueKey(LocalBranchScopedRecord object) {
    return putByIndex(r'uniqueKey', object);
  }

  Id putByUniqueKeySync(
    LocalBranchScopedRecord object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(r'uniqueKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUniqueKey(List<LocalBranchScopedRecord> objects) {
    return putAllByIndex(r'uniqueKey', objects);
  }

  List<Id> putAllByUniqueKeySync(
    List<LocalBranchScopedRecord> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'uniqueKey', objects, saveLinks: saveLinks);
  }
}

extension LocalBranchScopedRecordQueryWhereSort
    on QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QWhere> {
  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterWhere>
  anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterWhere>
  anyIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isDeleted'),
      );
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterWhere>
  anyPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'pendingSync'),
      );
    });
  }
}

extension LocalBranchScopedRecordQueryWhere
    on
        QueryBuilder<
          LocalBranchScopedRecord,
          LocalBranchScopedRecord,
          QWhereClause
        > {
  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterWhereClause
  >
  isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(lower: isarId, upper: isarId),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterWhereClause
  >
  isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterWhereClause
  >
  isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterWhereClause
  >
  isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterWhereClause
  >
  isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerIsarId,
          includeLower: includeLower,
          upper: upperIsarId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterWhereClause
  >
  uniqueKeyEqualTo(String uniqueKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'uniqueKey', value: [uniqueKey]),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterWhereClause
  >
  uniqueKeyNotEqualTo(String uniqueKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uniqueKey',
                lower: [],
                upper: [uniqueKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uniqueKey',
                lower: [uniqueKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uniqueKey',
                lower: [uniqueKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uniqueKey',
                lower: [],
                upper: [uniqueKey],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterWhereClause
  >
  businessIdEqualTo(String businessId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'businessId', value: [businessId]),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterWhereClause
  >
  businessIdNotEqualTo(String businessId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'businessId',
                lower: [],
                upper: [businessId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'businessId',
                lower: [businessId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'businessId',
                lower: [businessId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'businessId',
                lower: [],
                upper: [businessId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterWhereClause
  >
  branchIdEqualTo(String branchId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'branchId', value: [branchId]),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterWhereClause
  >
  branchIdNotEqualTo(String branchId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'branchId',
                lower: [],
                upper: [branchId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'branchId',
                lower: [branchId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'branchId',
                lower: [branchId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'branchId',
                lower: [],
                upper: [branchId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterWhereClause
  >
  collectionNameEqualTo(String collectionName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'collectionName',
          value: [collectionName],
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterWhereClause
  >
  collectionNameNotEqualTo(String collectionName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'collectionName',
                lower: [],
                upper: [collectionName],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'collectionName',
                lower: [collectionName],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'collectionName',
                lower: [collectionName],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'collectionName',
                lower: [],
                upper: [collectionName],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterWhereClause
  >
  documentIdEqualTo(String documentId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'documentId', value: [documentId]),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterWhereClause
  >
  documentIdNotEqualTo(String documentId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'documentId',
                lower: [],
                upper: [documentId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'documentId',
                lower: [documentId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'documentId',
                lower: [documentId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'documentId',
                lower: [],
                upper: [documentId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterWhereClause
  >
  isDeletedEqualTo(bool isDeleted) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'isDeleted', value: [isDeleted]),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterWhereClause
  >
  isDeletedNotEqualTo(bool isDeleted) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isDeleted',
                lower: [],
                upper: [isDeleted],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isDeleted',
                lower: [isDeleted],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isDeleted',
                lower: [isDeleted],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isDeleted',
                lower: [],
                upper: [isDeleted],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterWhereClause
  >
  pendingSyncEqualTo(bool pendingSync) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'pendingSync',
          value: [pendingSync],
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterWhereClause
  >
  pendingSyncNotEqualTo(bool pendingSync) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pendingSync',
                lower: [],
                upper: [pendingSync],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pendingSync',
                lower: [pendingSync],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pendingSync',
                lower: [pendingSync],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pendingSync',
                lower: [],
                upper: [pendingSync],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension LocalBranchScopedRecordQueryFilter
    on
        QueryBuilder<
          LocalBranchScopedRecord,
          LocalBranchScopedRecord,
          QFilterCondition
        > {
  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  branchIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'branchId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  branchIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'branchId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  branchIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'branchId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  branchIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'branchId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  branchIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'branchId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  branchIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'branchId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  branchIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'branchId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  branchIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'branchId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  branchIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'branchId', value: ''),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  branchIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'branchId', value: ''),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  businessIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'businessId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  businessIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'businessId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  businessIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'businessId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  businessIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'businessId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  businessIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'businessId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  businessIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'businessId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  businessIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'businessId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  businessIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'businessId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  businessIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'businessId', value: ''),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  businessIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'businessId', value: ''),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  collectionNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'collectionName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  collectionNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'collectionName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  collectionNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'collectionName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  collectionNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'collectionName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  collectionNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'collectionName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  collectionNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'collectionName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  collectionNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'collectionName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  collectionNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'collectionName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  collectionNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'collectionName', value: ''),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  collectionNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'collectionName', value: ''),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  documentIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'documentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  documentIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'documentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  documentIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'documentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  documentIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'documentId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  documentIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'documentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  documentIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'documentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  documentIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'documentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  documentIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'documentId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  documentIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'documentId', value: ''),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  documentIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'documentId', value: ''),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isDeleted', value: value),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isarId', value: value),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  isarIdGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  isarIdLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'isarId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  payloadJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  payloadJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  payloadJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  payloadJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'payloadJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  payloadJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  payloadJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  payloadJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  payloadJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'payloadJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  payloadJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'payloadJson', value: ''),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  payloadJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'payloadJson', value: ''),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  pendingSyncEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'pendingSync', value: value),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  uniqueKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'uniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  uniqueKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  uniqueKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  uniqueKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uniqueKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  uniqueKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'uniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  uniqueKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'uniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  uniqueKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'uniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  uniqueKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'uniqueKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  uniqueKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uniqueKey', value: ''),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  uniqueKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uniqueKey', value: ''),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAtMs', value: value),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  updatedAtMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  updatedAtMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LocalBranchScopedRecord,
    LocalBranchScopedRecord,
    QAfterFilterCondition
  >
  updatedAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension LocalBranchScopedRecordQueryObject
    on
        QueryBuilder<
          LocalBranchScopedRecord,
          LocalBranchScopedRecord,
          QFilterCondition
        > {}

extension LocalBranchScopedRecordQueryLinks
    on
        QueryBuilder<
          LocalBranchScopedRecord,
          LocalBranchScopedRecord,
          QFilterCondition
        > {}

extension LocalBranchScopedRecordQuerySortBy
    on QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QSortBy> {
  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  sortByBranchId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'branchId', Sort.asc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  sortByBranchIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'branchId', Sort.desc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  sortByBusinessId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'businessId', Sort.asc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  sortByBusinessIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'businessId', Sort.desc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  sortByCollectionName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collectionName', Sort.asc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  sortByCollectionNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collectionName', Sort.desc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  sortByDocumentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.asc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  sortByDocumentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.desc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  sortByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  sortByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  sortByPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingSync', Sort.asc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  sortByPendingSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingSync', Sort.desc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  sortByUniqueKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.asc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  sortByUniqueKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.desc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension LocalBranchScopedRecordQuerySortThenBy
    on
        QueryBuilder<
          LocalBranchScopedRecord,
          LocalBranchScopedRecord,
          QSortThenBy
        > {
  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  thenByBranchId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'branchId', Sort.asc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  thenByBranchIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'branchId', Sort.desc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  thenByBusinessId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'businessId', Sort.asc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  thenByBusinessIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'businessId', Sort.desc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  thenByCollectionName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collectionName', Sort.asc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  thenByCollectionNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collectionName', Sort.desc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  thenByDocumentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.asc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  thenByDocumentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.desc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  thenByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  thenByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  thenByPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingSync', Sort.asc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  thenByPendingSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingSync', Sort.desc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  thenByUniqueKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.asc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  thenByUniqueKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.desc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QAfterSortBy>
  thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension LocalBranchScopedRecordQueryWhereDistinct
    on
        QueryBuilder<
          LocalBranchScopedRecord,
          LocalBranchScopedRecord,
          QDistinct
        > {
  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QDistinct>
  distinctByBranchId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'branchId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QDistinct>
  distinctByBusinessId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'businessId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QDistinct>
  distinctByCollectionName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'collectionName',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QDistinct>
  distinctByDocumentId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'documentId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QDistinct>
  distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QDistinct>
  distinctByPayloadJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payloadJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QDistinct>
  distinctByPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pendingSync');
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QDistinct>
  distinctByUniqueKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uniqueKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalBranchScopedRecord, LocalBranchScopedRecord, QDistinct>
  distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension LocalBranchScopedRecordQueryProperty
    on
        QueryBuilder<
          LocalBranchScopedRecord,
          LocalBranchScopedRecord,
          QQueryProperty
        > {
  QueryBuilder<LocalBranchScopedRecord, int, QQueryOperations>
  isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<LocalBranchScopedRecord, String, QQueryOperations>
  branchIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'branchId');
    });
  }

  QueryBuilder<LocalBranchScopedRecord, String, QQueryOperations>
  businessIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'businessId');
    });
  }

  QueryBuilder<LocalBranchScopedRecord, String, QQueryOperations>
  collectionNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'collectionName');
    });
  }

  QueryBuilder<LocalBranchScopedRecord, String, QQueryOperations>
  documentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'documentId');
    });
  }

  QueryBuilder<LocalBranchScopedRecord, bool, QQueryOperations>
  isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<LocalBranchScopedRecord, String, QQueryOperations>
  payloadJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payloadJson');
    });
  }

  QueryBuilder<LocalBranchScopedRecord, bool, QQueryOperations>
  pendingSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pendingSync');
    });
  }

  QueryBuilder<LocalBranchScopedRecord, String, QQueryOperations>
  uniqueKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uniqueKey');
    });
  }

  QueryBuilder<LocalBranchScopedRecord, int, QQueryOperations>
  updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLocalGlobalRecordCollection on Isar {
  IsarCollection<LocalGlobalRecord> get localGlobalRecords => this.collection();
}

final LocalGlobalRecordSchema = CollectionSchema(
  name: r'LocalGlobalRecord',
  id: _jsSafeInt('6690418523410158840'),
  properties: {
    r'collectionName': PropertySchema(
      id: 0,
      name: r'collectionName',
      type: IsarType.string,
    ),
    r'documentId': PropertySchema(
      id: 1,
      name: r'documentId',
      type: IsarType.string,
    ),
    r'isDeleted': PropertySchema(
      id: 2,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'payloadJson': PropertySchema(
      id: 3,
      name: r'payloadJson',
      type: IsarType.string,
    ),
    r'pendingSync': PropertySchema(
      id: 4,
      name: r'pendingSync',
      type: IsarType.bool,
    ),
    r'uniqueKey': PropertySchema(
      id: 5,
      name: r'uniqueKey',
      type: IsarType.string,
    ),
    r'updatedAtMs': PropertySchema(
      id: 6,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
  },
  estimateSize: _localGlobalRecordEstimateSize,
  serialize: _localGlobalRecordSerialize,
  deserialize: _localGlobalRecordDeserialize,
  deserializeProp: _localGlobalRecordDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'uniqueKey': IndexSchema(
      id: _jsSafeInt('-866995956150369819'),
      name: r'uniqueKey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uniqueKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'collectionName': IndexSchema(
      id: _jsSafeInt('-4238329797778617380'),
      name: r'collectionName',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'collectionName',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'documentId': IndexSchema(
      id: _jsSafeInt('4187168439921340405'),
      name: r'documentId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'documentId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'isDeleted': IndexSchema(
      id: _jsSafeInt('-786475870904832312'),
      name: r'isDeleted',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isDeleted',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'pendingSync': IndexSchema(
      id: _jsSafeInt('6092646898846083691'),
      name: r'pendingSync',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'pendingSync',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _localGlobalRecordGetId,
  getLinks: _localGlobalRecordGetLinks,
  attach: _localGlobalRecordAttach,
  version: '3.1.0+1',
);

int _localGlobalRecordEstimateSize(
  LocalGlobalRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.collectionName.length * 3;
  bytesCount += 3 + object.documentId.length * 3;
  bytesCount += 3 + object.payloadJson.length * 3;
  bytesCount += 3 + object.uniqueKey.length * 3;
  return bytesCount;
}

void _localGlobalRecordSerialize(
  LocalGlobalRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.collectionName);
  writer.writeString(offsets[1], object.documentId);
  writer.writeBool(offsets[2], object.isDeleted);
  writer.writeString(offsets[3], object.payloadJson);
  writer.writeBool(offsets[4], object.pendingSync);
  writer.writeString(offsets[5], object.uniqueKey);
  writer.writeLong(offsets[6], object.updatedAtMs);
}

LocalGlobalRecord _localGlobalRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LocalGlobalRecord();
  object.collectionName = reader.readString(offsets[0]);
  object.documentId = reader.readString(offsets[1]);
  object.isDeleted = reader.readBool(offsets[2]);
  object.isarId = id;
  object.payloadJson = reader.readString(offsets[3]);
  object.pendingSync = reader.readBool(offsets[4]);
  object.uniqueKey = reader.readString(offsets[5]);
  object.updatedAtMs = reader.readLong(offsets[6]);
  return object;
}

P _localGlobalRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _localGlobalRecordGetId(LocalGlobalRecord object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _localGlobalRecordGetLinks(
  LocalGlobalRecord object,
) {
  return [];
}

void _localGlobalRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  LocalGlobalRecord object,
) {
  object.isarId = id;
}

extension LocalGlobalRecordByIndex on IsarCollection<LocalGlobalRecord> {
  Future<LocalGlobalRecord?> getByUniqueKey(String uniqueKey) {
    return getByIndex(r'uniqueKey', [uniqueKey]);
  }

  LocalGlobalRecord? getByUniqueKeySync(String uniqueKey) {
    return getByIndexSync(r'uniqueKey', [uniqueKey]);
  }

  Future<bool> deleteByUniqueKey(String uniqueKey) {
    return deleteByIndex(r'uniqueKey', [uniqueKey]);
  }

  bool deleteByUniqueKeySync(String uniqueKey) {
    return deleteByIndexSync(r'uniqueKey', [uniqueKey]);
  }

  Future<List<LocalGlobalRecord?>> getAllByUniqueKey(
    List<String> uniqueKeyValues,
  ) {
    final values = uniqueKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'uniqueKey', values);
  }

  List<LocalGlobalRecord?> getAllByUniqueKeySync(List<String> uniqueKeyValues) {
    final values = uniqueKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uniqueKey', values);
  }

  Future<int> deleteAllByUniqueKey(List<String> uniqueKeyValues) {
    final values = uniqueKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uniqueKey', values);
  }

  int deleteAllByUniqueKeySync(List<String> uniqueKeyValues) {
    final values = uniqueKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uniqueKey', values);
  }

  Future<Id> putByUniqueKey(LocalGlobalRecord object) {
    return putByIndex(r'uniqueKey', object);
  }

  Id putByUniqueKeySync(LocalGlobalRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'uniqueKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUniqueKey(List<LocalGlobalRecord> objects) {
    return putAllByIndex(r'uniqueKey', objects);
  }

  List<Id> putAllByUniqueKeySync(
    List<LocalGlobalRecord> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'uniqueKey', objects, saveLinks: saveLinks);
  }
}

extension LocalGlobalRecordQueryWhereSort
    on QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QWhere> {
  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterWhere>
  anyIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isDeleted'),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterWhere>
  anyPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'pendingSync'),
      );
    });
  }
}

extension LocalGlobalRecordQueryWhere
    on QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QWhereClause> {
  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterWhereClause>
  isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(lower: isarId, upper: isarId),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterWhereClause>
  isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterWhereClause>
  isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterWhereClause>
  isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterWhereClause>
  isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerIsarId,
          includeLower: includeLower,
          upper: upperIsarId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterWhereClause>
  uniqueKeyEqualTo(String uniqueKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'uniqueKey', value: [uniqueKey]),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterWhereClause>
  uniqueKeyNotEqualTo(String uniqueKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uniqueKey',
                lower: [],
                upper: [uniqueKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uniqueKey',
                lower: [uniqueKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uniqueKey',
                lower: [uniqueKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uniqueKey',
                lower: [],
                upper: [uniqueKey],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterWhereClause>
  collectionNameEqualTo(String collectionName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'collectionName',
          value: [collectionName],
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterWhereClause>
  collectionNameNotEqualTo(String collectionName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'collectionName',
                lower: [],
                upper: [collectionName],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'collectionName',
                lower: [collectionName],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'collectionName',
                lower: [collectionName],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'collectionName',
                lower: [],
                upper: [collectionName],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterWhereClause>
  documentIdEqualTo(String documentId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'documentId', value: [documentId]),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterWhereClause>
  documentIdNotEqualTo(String documentId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'documentId',
                lower: [],
                upper: [documentId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'documentId',
                lower: [documentId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'documentId',
                lower: [documentId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'documentId',
                lower: [],
                upper: [documentId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterWhereClause>
  isDeletedEqualTo(bool isDeleted) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'isDeleted', value: [isDeleted]),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterWhereClause>
  isDeletedNotEqualTo(bool isDeleted) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isDeleted',
                lower: [],
                upper: [isDeleted],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isDeleted',
                lower: [isDeleted],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isDeleted',
                lower: [isDeleted],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isDeleted',
                lower: [],
                upper: [isDeleted],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterWhereClause>
  pendingSyncEqualTo(bool pendingSync) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'pendingSync',
          value: [pendingSync],
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterWhereClause>
  pendingSyncNotEqualTo(bool pendingSync) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pendingSync',
                lower: [],
                upper: [pendingSync],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pendingSync',
                lower: [pendingSync],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pendingSync',
                lower: [pendingSync],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pendingSync',
                lower: [],
                upper: [pendingSync],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension LocalGlobalRecordQueryFilter
    on QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QFilterCondition> {
  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  collectionNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'collectionName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  collectionNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'collectionName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  collectionNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'collectionName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  collectionNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'collectionName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  collectionNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'collectionName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  collectionNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'collectionName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  collectionNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'collectionName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  collectionNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'collectionName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  collectionNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'collectionName', value: ''),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  collectionNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'collectionName', value: ''),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  documentIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'documentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  documentIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'documentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  documentIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'documentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  documentIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'documentId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  documentIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'documentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  documentIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'documentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  documentIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'documentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  documentIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'documentId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  documentIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'documentId', value: ''),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  documentIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'documentId', value: ''),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isDeleted', value: value),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isarId', value: value),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  isarIdGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  isarIdLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'isarId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  payloadJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  payloadJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  payloadJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  payloadJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'payloadJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  payloadJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  payloadJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  payloadJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  payloadJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'payloadJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  payloadJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'payloadJson', value: ''),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  payloadJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'payloadJson', value: ''),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  pendingSyncEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'pendingSync', value: value),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  uniqueKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'uniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  uniqueKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  uniqueKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  uniqueKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uniqueKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  uniqueKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'uniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  uniqueKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'uniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  uniqueKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'uniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  uniqueKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'uniqueKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  uniqueKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uniqueKey', value: ''),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  uniqueKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uniqueKey', value: ''),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAtMs', value: value),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  updatedAtMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  updatedAtMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterFilterCondition>
  updatedAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension LocalGlobalRecordQueryObject
    on QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QFilterCondition> {}

extension LocalGlobalRecordQueryLinks
    on QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QFilterCondition> {}

extension LocalGlobalRecordQuerySortBy
    on QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QSortBy> {
  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  sortByCollectionName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collectionName', Sort.asc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  sortByCollectionNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collectionName', Sort.desc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  sortByDocumentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.asc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  sortByDocumentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.desc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  sortByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  sortByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  sortByPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingSync', Sort.asc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  sortByPendingSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingSync', Sort.desc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  sortByUniqueKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.asc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  sortByUniqueKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.desc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension LocalGlobalRecordQuerySortThenBy
    on QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QSortThenBy> {
  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  thenByCollectionName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collectionName', Sort.asc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  thenByCollectionNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collectionName', Sort.desc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  thenByDocumentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.asc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  thenByDocumentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.desc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  thenByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  thenByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  thenByPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingSync', Sort.asc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  thenByPendingSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingSync', Sort.desc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  thenByUniqueKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.asc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  thenByUniqueKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.desc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QAfterSortBy>
  thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension LocalGlobalRecordQueryWhereDistinct
    on QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QDistinct> {
  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QDistinct>
  distinctByCollectionName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'collectionName',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QDistinct>
  distinctByDocumentId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'documentId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QDistinct>
  distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QDistinct>
  distinctByPayloadJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payloadJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QDistinct>
  distinctByPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pendingSync');
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QDistinct>
  distinctByUniqueKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uniqueKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QDistinct>
  distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension LocalGlobalRecordQueryProperty
    on QueryBuilder<LocalGlobalRecord, LocalGlobalRecord, QQueryProperty> {
  QueryBuilder<LocalGlobalRecord, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<LocalGlobalRecord, String, QQueryOperations>
  collectionNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'collectionName');
    });
  }

  QueryBuilder<LocalGlobalRecord, String, QQueryOperations>
  documentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'documentId');
    });
  }

  QueryBuilder<LocalGlobalRecord, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<LocalGlobalRecord, String, QQueryOperations>
  payloadJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payloadJson');
    });
  }

  QueryBuilder<LocalGlobalRecord, bool, QQueryOperations>
  pendingSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pendingSync');
    });
  }

  QueryBuilder<LocalGlobalRecord, String, QQueryOperations>
  uniqueKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uniqueKey');
    });
  }

  QueryBuilder<LocalGlobalRecord, int, QQueryOperations> updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSyncQueueOperationCollection on Isar {
  IsarCollection<SyncQueueOperation> get syncQueueOperations =>
      this.collection();
}

final SyncQueueOperationSchema = CollectionSchema(
  name: r'SyncQueueOperation',
  id: _jsSafeInt('-5066559844833687204'),
  properties: {
    r'attempts': PropertySchema(id: 0, name: r'attempts', type: IsarType.long),
    r'createdAtMs': PropertySchema(
      id: 1,
      name: r'createdAtMs',
      type: IsarType.long,
    ),
    r'documentPath': PropertySchema(
      id: 2,
      name: r'documentPath',
      type: IsarType.string,
    ),
    r'merge': PropertySchema(id: 3, name: r'merge', type: IsarType.bool),
    r'opId': PropertySchema(id: 4, name: r'opId', type: IsarType.string),
    r'operationType': PropertySchema(
      id: 5,
      name: r'operationType',
      type: IsarType.string,
    ),
    r'payloadJson': PropertySchema(
      id: 6,
      name: r'payloadJson',
      type: IsarType.string,
    ),
    r'updatedAtMs': PropertySchema(
      id: 7,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
  },
  estimateSize: _syncQueueOperationEstimateSize,
  serialize: _syncQueueOperationSerialize,
  deserialize: _syncQueueOperationDeserialize,
  deserializeProp: _syncQueueOperationDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'opId': IndexSchema(
      id: _jsSafeInt('-7257366839637970090'),
      name: r'opId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'opId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'operationType': IndexSchema(
      id: _jsSafeInt('7940488376024458150'),
      name: r'operationType',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'operationType',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'documentPath': IndexSchema(
      id: _jsSafeInt('-5231785169774962353'),
      name: r'documentPath',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'documentPath',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _syncQueueOperationGetId,
  getLinks: _syncQueueOperationGetLinks,
  attach: _syncQueueOperationAttach,
  version: '3.1.0+1',
);

int _syncQueueOperationEstimateSize(
  SyncQueueOperation object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.documentPath.length * 3;
  bytesCount += 3 + object.opId.length * 3;
  bytesCount += 3 + object.operationType.length * 3;
  {
    final value = object.payloadJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _syncQueueOperationSerialize(
  SyncQueueOperation object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.attempts);
  writer.writeLong(offsets[1], object.createdAtMs);
  writer.writeString(offsets[2], object.documentPath);
  writer.writeBool(offsets[3], object.merge);
  writer.writeString(offsets[4], object.opId);
  writer.writeString(offsets[5], object.operationType);
  writer.writeString(offsets[6], object.payloadJson);
  writer.writeLong(offsets[7], object.updatedAtMs);
}

SyncQueueOperation _syncQueueOperationDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SyncQueueOperation();
  object.attempts = reader.readLong(offsets[0]);
  object.createdAtMs = reader.readLong(offsets[1]);
  object.documentPath = reader.readString(offsets[2]);
  object.isarId = id;
  object.merge = reader.readBool(offsets[3]);
  object.opId = reader.readString(offsets[4]);
  object.operationType = reader.readString(offsets[5]);
  object.payloadJson = reader.readStringOrNull(offsets[6]);
  object.updatedAtMs = reader.readLong(offsets[7]);
  return object;
}

P _syncQueueOperationDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _syncQueueOperationGetId(SyncQueueOperation object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _syncQueueOperationGetLinks(
  SyncQueueOperation object,
) {
  return [];
}

void _syncQueueOperationAttach(
  IsarCollection<dynamic> col,
  Id id,
  SyncQueueOperation object,
) {
  object.isarId = id;
}

extension SyncQueueOperationByIndex on IsarCollection<SyncQueueOperation> {
  Future<SyncQueueOperation?> getByOpId(String opId) {
    return getByIndex(r'opId', [opId]);
  }

  SyncQueueOperation? getByOpIdSync(String opId) {
    return getByIndexSync(r'opId', [opId]);
  }

  Future<bool> deleteByOpId(String opId) {
    return deleteByIndex(r'opId', [opId]);
  }

  bool deleteByOpIdSync(String opId) {
    return deleteByIndexSync(r'opId', [opId]);
  }

  Future<List<SyncQueueOperation?>> getAllByOpId(List<String> opIdValues) {
    final values = opIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'opId', values);
  }

  List<SyncQueueOperation?> getAllByOpIdSync(List<String> opIdValues) {
    final values = opIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'opId', values);
  }

  Future<int> deleteAllByOpId(List<String> opIdValues) {
    final values = opIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'opId', values);
  }

  int deleteAllByOpIdSync(List<String> opIdValues) {
    final values = opIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'opId', values);
  }

  Future<Id> putByOpId(SyncQueueOperation object) {
    return putByIndex(r'opId', object);
  }

  Id putByOpIdSync(SyncQueueOperation object, {bool saveLinks = true}) {
    return putByIndexSync(r'opId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByOpId(List<SyncQueueOperation> objects) {
    return putAllByIndex(r'opId', objects);
  }

  List<Id> putAllByOpIdSync(
    List<SyncQueueOperation> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'opId', objects, saveLinks: saveLinks);
  }
}

extension SyncQueueOperationQueryWhereSort
    on QueryBuilder<SyncQueueOperation, SyncQueueOperation, QWhere> {
  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterWhere>
  anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SyncQueueOperationQueryWhere
    on QueryBuilder<SyncQueueOperation, SyncQueueOperation, QWhereClause> {
  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterWhereClause>
  isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(lower: isarId, upper: isarId),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterWhereClause>
  isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterWhereClause>
  isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterWhereClause>
  isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterWhereClause>
  isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerIsarId,
          includeLower: includeLower,
          upper: upperIsarId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterWhereClause>
  opIdEqualTo(String opId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'opId', value: [opId]),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterWhereClause>
  opIdNotEqualTo(String opId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'opId',
                lower: [],
                upper: [opId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'opId',
                lower: [opId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'opId',
                lower: [opId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'opId',
                lower: [],
                upper: [opId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterWhereClause>
  operationTypeEqualTo(String operationType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'operationType',
          value: [operationType],
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterWhereClause>
  operationTypeNotEqualTo(String operationType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'operationType',
                lower: [],
                upper: [operationType],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'operationType',
                lower: [operationType],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'operationType',
                lower: [operationType],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'operationType',
                lower: [],
                upper: [operationType],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterWhereClause>
  documentPathEqualTo(String documentPath) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'documentPath',
          value: [documentPath],
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterWhereClause>
  documentPathNotEqualTo(String documentPath) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'documentPath',
                lower: [],
                upper: [documentPath],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'documentPath',
                lower: [documentPath],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'documentPath',
                lower: [documentPath],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'documentPath',
                lower: [],
                upper: [documentPath],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension SyncQueueOperationQueryFilter
    on QueryBuilder<SyncQueueOperation, SyncQueueOperation, QFilterCondition> {
  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  attemptsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'attempts', value: value),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  attemptsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'attempts',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  attemptsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'attempts',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  attemptsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'attempts',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  createdAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAtMs', value: value),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  createdAtMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  createdAtMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  createdAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  documentPathEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'documentPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  documentPathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'documentPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  documentPathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'documentPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  documentPathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'documentPath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  documentPathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'documentPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  documentPathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'documentPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  documentPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'documentPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  documentPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'documentPath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  documentPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'documentPath', value: ''),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  documentPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'documentPath', value: ''),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isarId', value: value),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  isarIdGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  isarIdLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'isarId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  mergeEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'merge', value: value),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  opIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'opId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  opIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'opId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  opIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'opId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  opIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'opId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  opIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'opId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  opIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'opId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  opIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'opId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  opIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'opId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  opIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'opId', value: ''),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  opIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'opId', value: ''),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  operationTypeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'operationType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  operationTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'operationType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  operationTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'operationType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  operationTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'operationType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  operationTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'operationType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  operationTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'operationType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  operationTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'operationType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  operationTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'operationType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  operationTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'operationType', value: ''),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  operationTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'operationType', value: ''),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  payloadJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'payloadJson'),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  payloadJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'payloadJson'),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  payloadJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  payloadJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  payloadJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  payloadJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'payloadJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  payloadJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  payloadJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  payloadJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  payloadJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'payloadJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  payloadJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'payloadJson', value: ''),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  payloadJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'payloadJson', value: ''),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAtMs', value: value),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  updatedAtMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  updatedAtMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterFilterCondition>
  updatedAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension SyncQueueOperationQueryObject
    on QueryBuilder<SyncQueueOperation, SyncQueueOperation, QFilterCondition> {}

extension SyncQueueOperationQueryLinks
    on QueryBuilder<SyncQueueOperation, SyncQueueOperation, QFilterCondition> {}

extension SyncQueueOperationQuerySortBy
    on QueryBuilder<SyncQueueOperation, SyncQueueOperation, QSortBy> {
  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  sortByAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  sortByAttemptsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  sortByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  sortByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  sortByDocumentPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentPath', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  sortByDocumentPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentPath', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  sortByMerge() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'merge', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  sortByMergeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'merge', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  sortByOpId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'opId', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  sortByOpIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'opId', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  sortByOperationType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'operationType', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  sortByOperationTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'operationType', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  sortByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  sortByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension SyncQueueOperationQuerySortThenBy
    on QueryBuilder<SyncQueueOperation, SyncQueueOperation, QSortThenBy> {
  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  thenByAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  thenByAttemptsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  thenByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  thenByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  thenByDocumentPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentPath', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  thenByDocumentPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentPath', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  thenByMerge() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'merge', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  thenByMergeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'merge', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  thenByOpId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'opId', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  thenByOpIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'opId', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  thenByOperationType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'operationType', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  thenByOperationTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'operationType', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  thenByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  thenByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QAfterSortBy>
  thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension SyncQueueOperationQueryWhereDistinct
    on QueryBuilder<SyncQueueOperation, SyncQueueOperation, QDistinct> {
  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QDistinct>
  distinctByAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'attempts');
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QDistinct>
  distinctByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtMs');
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QDistinct>
  distinctByDocumentPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'documentPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QDistinct>
  distinctByMerge() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'merge');
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QDistinct>
  distinctByOpId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'opId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QDistinct>
  distinctByOperationType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'operationType',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QDistinct>
  distinctByPayloadJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payloadJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncQueueOperation, SyncQueueOperation, QDistinct>
  distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension SyncQueueOperationQueryProperty
    on QueryBuilder<SyncQueueOperation, SyncQueueOperation, QQueryProperty> {
  QueryBuilder<SyncQueueOperation, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<SyncQueueOperation, int, QQueryOperations> attemptsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attempts');
    });
  }

  QueryBuilder<SyncQueueOperation, int, QQueryOperations>
  createdAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtMs');
    });
  }

  QueryBuilder<SyncQueueOperation, String, QQueryOperations>
  documentPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'documentPath');
    });
  }

  QueryBuilder<SyncQueueOperation, bool, QQueryOperations> mergeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'merge');
    });
  }

  QueryBuilder<SyncQueueOperation, String, QQueryOperations> opIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'opId');
    });
  }

  QueryBuilder<SyncQueueOperation, String, QQueryOperations>
  operationTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'operationType');
    });
  }

  QueryBuilder<SyncQueueOperation, String?, QQueryOperations>
  payloadJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payloadJson');
    });
  }

  QueryBuilder<SyncQueueOperation, int, QQueryOperations>
  updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSyncStatusSnapshotCollection on Isar {
  IsarCollection<SyncStatusSnapshot> get syncStatusSnapshots =>
      this.collection();
}

final SyncStatusSnapshotSchema = CollectionSchema(
  name: r'SyncStatusSnapshot',
  id: _jsSafeInt('194421679768175203'),
  properties: {
    r'isSyncing': PropertySchema(
      id: 0,
      name: r'isSyncing',
      type: IsarType.bool,
    ),
    r'key': PropertySchema(id: 1, name: r'key', type: IsarType.string),
    r'lastSyncAtMs': PropertySchema(
      id: 2,
      name: r'lastSyncAtMs',
      type: IsarType.long,
    ),
    r'pendingWrites': PropertySchema(
      id: 3,
      name: r'pendingWrites',
      type: IsarType.long,
    ),
    r'updatedAtMs': PropertySchema(
      id: 4,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
  },
  estimateSize: _syncStatusSnapshotEstimateSize,
  serialize: _syncStatusSnapshotSerialize,
  deserialize: _syncStatusSnapshotDeserialize,
  deserializeProp: _syncStatusSnapshotDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'key': IndexSchema(
      id: _jsSafeInt('-4906094122524121629'),
      name: r'key',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'key',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _syncStatusSnapshotGetId,
  getLinks: _syncStatusSnapshotGetLinks,
  attach: _syncStatusSnapshotAttach,
  version: '3.1.0+1',
);

int _syncStatusSnapshotEstimateSize(
  SyncStatusSnapshot object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.key.length * 3;
  return bytesCount;
}

void _syncStatusSnapshotSerialize(
  SyncStatusSnapshot object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.isSyncing);
  writer.writeString(offsets[1], object.key);
  writer.writeLong(offsets[2], object.lastSyncAtMs);
  writer.writeLong(offsets[3], object.pendingWrites);
  writer.writeLong(offsets[4], object.updatedAtMs);
}

SyncStatusSnapshot _syncStatusSnapshotDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SyncStatusSnapshot();
  object.isSyncing = reader.readBool(offsets[0]);
  object.isarId = id;
  object.key = reader.readString(offsets[1]);
  object.lastSyncAtMs = reader.readLongOrNull(offsets[2]);
  object.pendingWrites = reader.readLong(offsets[3]);
  object.updatedAtMs = reader.readLong(offsets[4]);
  return object;
}

P _syncStatusSnapshotDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _syncStatusSnapshotGetId(SyncStatusSnapshot object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _syncStatusSnapshotGetLinks(
  SyncStatusSnapshot object,
) {
  return [];
}

void _syncStatusSnapshotAttach(
  IsarCollection<dynamic> col,
  Id id,
  SyncStatusSnapshot object,
) {
  object.isarId = id;
}

extension SyncStatusSnapshotByIndex on IsarCollection<SyncStatusSnapshot> {
  Future<SyncStatusSnapshot?> getByKey(String key) {
    return getByIndex(r'key', [key]);
  }

  SyncStatusSnapshot? getByKeySync(String key) {
    return getByIndexSync(r'key', [key]);
  }

  Future<bool> deleteByKey(String key) {
    return deleteByIndex(r'key', [key]);
  }

  bool deleteByKeySync(String key) {
    return deleteByIndexSync(r'key', [key]);
  }

  Future<List<SyncStatusSnapshot?>> getAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndex(r'key', values);
  }

  List<SyncStatusSnapshot?> getAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'key', values);
  }

  Future<int> deleteAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'key', values);
  }

  int deleteAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'key', values);
  }

  Future<Id> putByKey(SyncStatusSnapshot object) {
    return putByIndex(r'key', object);
  }

  Id putByKeySync(SyncStatusSnapshot object, {bool saveLinks = true}) {
    return putByIndexSync(r'key', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByKey(List<SyncStatusSnapshot> objects) {
    return putAllByIndex(r'key', objects);
  }

  List<Id> putAllByKeySync(
    List<SyncStatusSnapshot> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'key', objects, saveLinks: saveLinks);
  }
}

extension SyncStatusSnapshotQueryWhereSort
    on QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QWhere> {
  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterWhere>
  anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SyncStatusSnapshotQueryWhere
    on QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QWhereClause> {
  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterWhereClause>
  isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(lower: isarId, upper: isarId),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterWhereClause>
  isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterWhereClause>
  isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterWhereClause>
  isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterWhereClause>
  isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerIsarId,
          includeLower: includeLower,
          upper: upperIsarId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterWhereClause>
  keyEqualTo(String key) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'key', value: [key]),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterWhereClause>
  keyNotEqualTo(String key) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'key',
                lower: [],
                upper: [key],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'key',
                lower: [key],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'key',
                lower: [key],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'key',
                lower: [],
                upper: [key],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension SyncStatusSnapshotQueryFilter
    on QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QFilterCondition> {
  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  isSyncingEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isSyncing', value: value),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isarId', value: value),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  isarIdGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  isarIdLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'isarId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  keyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  keyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  keyLessThan(String value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  keyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'key',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  keyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  keyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  keyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  keyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'key',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  keyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'key', value: ''),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  keyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'key', value: ''),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  lastSyncAtMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastSyncAtMs'),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  lastSyncAtMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastSyncAtMs'),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  lastSyncAtMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastSyncAtMs', value: value),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  lastSyncAtMsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastSyncAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  lastSyncAtMsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastSyncAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  lastSyncAtMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastSyncAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  pendingWritesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'pendingWrites', value: value),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  pendingWritesGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'pendingWrites',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  pendingWritesLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'pendingWrites',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  pendingWritesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'pendingWrites',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAtMs', value: value),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  updatedAtMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  updatedAtMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterFilterCondition>
  updatedAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension SyncStatusSnapshotQueryObject
    on QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QFilterCondition> {}

extension SyncStatusSnapshotQueryLinks
    on QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QFilterCondition> {}

extension SyncStatusSnapshotQuerySortBy
    on QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QSortBy> {
  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterSortBy>
  sortByIsSyncing() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSyncing', Sort.asc);
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterSortBy>
  sortByIsSyncingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSyncing', Sort.desc);
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterSortBy>
  sortByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterSortBy>
  sortByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterSortBy>
  sortByLastSyncAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAtMs', Sort.asc);
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterSortBy>
  sortByLastSyncAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAtMs', Sort.desc);
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterSortBy>
  sortByPendingWrites() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingWrites', Sort.asc);
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterSortBy>
  sortByPendingWritesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingWrites', Sort.desc);
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterSortBy>
  sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterSortBy>
  sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension SyncStatusSnapshotQuerySortThenBy
    on QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QSortThenBy> {
  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterSortBy>
  thenByIsSyncing() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSyncing', Sort.asc);
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterSortBy>
  thenByIsSyncingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSyncing', Sort.desc);
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterSortBy>
  thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterSortBy>
  thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterSortBy>
  thenByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterSortBy>
  thenByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterSortBy>
  thenByLastSyncAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAtMs', Sort.asc);
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterSortBy>
  thenByLastSyncAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAtMs', Sort.desc);
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterSortBy>
  thenByPendingWrites() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingWrites', Sort.asc);
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterSortBy>
  thenByPendingWritesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingWrites', Sort.desc);
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterSortBy>
  thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QAfterSortBy>
  thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension SyncStatusSnapshotQueryWhereDistinct
    on QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QDistinct> {
  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QDistinct>
  distinctByIsSyncing() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSyncing');
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QDistinct>
  distinctByKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'key', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QDistinct>
  distinctByLastSyncAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncAtMs');
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QDistinct>
  distinctByPendingWrites() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pendingWrites');
    });
  }

  QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QDistinct>
  distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension SyncStatusSnapshotQueryProperty
    on QueryBuilder<SyncStatusSnapshot, SyncStatusSnapshot, QQueryProperty> {
  QueryBuilder<SyncStatusSnapshot, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<SyncStatusSnapshot, bool, QQueryOperations> isSyncingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSyncing');
    });
  }

  QueryBuilder<SyncStatusSnapshot, String, QQueryOperations> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'key');
    });
  }

  QueryBuilder<SyncStatusSnapshot, int?, QQueryOperations>
  lastSyncAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncAtMs');
    });
  }

  QueryBuilder<SyncStatusSnapshot, int, QQueryOperations>
  pendingWritesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pendingWrites');
    });
  }

  QueryBuilder<SyncStatusSnapshot, int, QQueryOperations>
  updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}


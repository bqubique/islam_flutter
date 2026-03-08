enum DialectEnum {
  hafs('hafs'),
  warsh('warsh');

  const DialectEnum(this.columnName);

  /// Matches the column name in the [verses] table.
  final String columnName;
}

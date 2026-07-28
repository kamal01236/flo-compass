enum DataSource {
  mock,
  remote;

  static DataSource fromJson(String? value) {
    return switch (value) {
      'remote' => DataSource.remote,
      _ => DataSource.mock,
    };
  }

  String get jsonValue => name;
}

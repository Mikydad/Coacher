class AccountabilityRetentionWorker {
  const AccountabilityRetentionWorker(this._prune);
  final Future<int> Function({int retentionDays, int? nowMs}) _prune;

  Future<int> run({int retentionDays = 30}) async {
    return _prune(retentionDays: retentionDays);
  }
}

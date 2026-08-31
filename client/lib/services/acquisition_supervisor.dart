enum AcquisitionDirective {
  search,
  waitForDownload,
  complete,
  searchFailed,
  downloadFailed,
}

enum AcquisitionRecovery { retrySameCandidate, retryNextCandidate, stop }

class AcquisitionSupervisor {
  AcquisitionSupervisor({this.maximumChecks = 20});

  static const pollInterval = Duration(seconds: 3);

  final int maximumChecks;
  int searchAttempts = 0;
  int downloadStartChecks = 0;
  bool actionIssued = false;
  bool transferStarted = false;
  int recoveryAttempts = 0;
  int candidateOffset = 0;
  String? lastFailure;

  bool beginSearchAttempt() {
    if (actionIssued || transferStarted || searchAttempts >= maximumChecks) {
      return false;
    }
    searchAttempts += 1;
    return true;
  }

  void markActionIssued() {
    actionIssued = true;
    downloadStartChecks = 0;
  }

  void markTransferStarted() {
    transferStarted = true;
  }

  AcquisitionRecovery classifyFailure(String message) {
    lastFailure = message;
    final normalized = message.toLowerCase();
    if (normalized.contains('provider returned') ||
        normalized.contains('not the complete requested track') ||
        normalized.contains('track identity mismatch') ||
        normalized.contains('identity cannot be verified')) {
      return _prepareRecovery(nextCandidate: true);
    }
    if (normalized.contains('connection') ||
        normalized.contains('transfer failed') ||
        normalized.contains('could not be saved') ||
        normalized.contains('no file transfer started') ||
        normalized.contains('timeout')) {
      return _prepareRecovery(nextCandidate: false);
    }
    return AcquisitionRecovery.stop;
  }

  AcquisitionRecovery _prepareRecovery({required bool nextCandidate}) {
    recoveryAttempts += 1;
    if (recoveryAttempts >= maximumChecks) return AcquisitionRecovery.stop;
    if (nextCandidate) candidateOffset += 1;
    searchAttempts = 0;
    downloadStartChecks = 0;
    actionIssued = false;
    transferStarted = false;
    return nextCandidate
        ? AcquisitionRecovery.retryNextCandidate
        : AcquisitionRecovery.retrySameCandidate;
  }

  AcquisitionDirective check() {
    if (transferStarted) return AcquisitionDirective.complete;
    if (!actionIssued) {
      return searchAttempts >= maximumChecks
          ? AcquisitionDirective.searchFailed
          : AcquisitionDirective.search;
    }
    downloadStartChecks += 1;
    return downloadStartChecks >= maximumChecks
        ? AcquisitionDirective.downloadFailed
        : AcquisitionDirective.waitForDownload;
  }

  void reset() {
    searchAttempts = 0;
    downloadStartChecks = 0;
    actionIssued = false;
    transferStarted = false;
    recoveryAttempts = 0;
    candidateOffset = 0;
    lastFailure = null;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:hi_hat/services/acquisition_supervisor.dart';

void main() {
  test('search is capped at twenty checks three seconds apart', () {
    final supervisor = AcquisitionSupervisor();

    for (var i = 0; i < 20; i++) {
      expect(supervisor.beginSearchAttempt(), isTrue);
    }

    expect(supervisor.beginSearchAttempt(), isFalse);
    expect(supervisor.check(), AcquisitionDirective.searchFailed);
    expect(AcquisitionSupervisor.pollInterval, const Duration(seconds: 3));
  });

  test('one download action switches the supervisor to observation only', () {
    final supervisor = AcquisitionSupervisor();
    expect(supervisor.beginSearchAttempt(), isTrue);
    supervisor.markActionIssued();

    expect(supervisor.beginSearchAttempt(), isFalse);
    for (var i = 0; i < 19; i++) {
      expect(supervisor.check(), AcquisitionDirective.waitForDownload);
    }
    expect(supervisor.check(), AcquisitionDirective.downloadFailed);
  });

  test('duration mismatch rotates to the next ranked candidate', () {
    final supervisor = AcquisitionSupervisor()
      ..beginSearchAttempt()
      ..markActionIssued()
      ..markTransferStarted();

    expect(
      supervisor.classifyFailure(
        'The provider returned 4:22, but this track should be 4:10.',
      ),
      AcquisitionRecovery.retryNextCandidate,
    );
    expect(supervisor.candidateOffset, 1);
    expect(supervisor.actionIssued, isFalse);
    expect(supervisor.transferStarted, isFalse);
  });

  test('downloaded metadata mismatch rotates to the next candidate', () {
    final supervisor = AcquisitionSupervisor()
      ..beginSearchAttempt()
      ..markActionIssued()
      ..markTransferStarted();

    expect(
      supervisor.classifyFailure(
        'Track identity mismatch: requested "Runaway" by Kanye West, but '
        'the downloaded FLAC is "Kanye West (Runaway)" by Nikita Kondrashev.',
      ),
      AcquisitionRecovery.retryNextCandidate,
    );
    expect(supervisor.candidateOffset, 1);
    expect(supervisor.actionIssued, isFalse);
  });

  test('permission and unsupported-file errors remain terminal', () {
    final supervisor = AcquisitionSupervisor();

    expect(
      supervisor.classifyFailure('Permission denied while saving the file.'),
      AcquisitionRecovery.stop,
    );
  });

  test('transient transfer failure retries the same candidate', () {
    final supervisor = AcquisitionSupervisor()..candidateOffset = 2;

    expect(
      supervisor.classifyFailure(
        'The file transfer failed. Check your connection and retry.',
      ),
      AcquisitionRecovery.retrySameCandidate,
    );
    expect(supervisor.candidateOffset, 2);
    expect(supervisor.lastFailure, contains('transfer failed'));
  });

  test('native download callback completes supervision immediately', () {
    final supervisor = AcquisitionSupervisor()
      ..beginSearchAttempt()
      ..markActionIssued()
      ..markTransferStarted();

    expect(supervisor.check(), AcquisitionDirective.complete);
  });
}

import 'package:flutter_test/flutter_test.dart';

class _MutationController {
  bool isUpdating = false;
  bool actionCompleted = false;
  Object? error;

  final Future<void> Function() operation;

  _MutationController({
    required this.operation,
  });

  Future<void> execute() async {
    if (isUpdating) {
      return;
    }

    isUpdating = true;
    error = null;

    try {
      await operation();

      actionCompleted = true;
    } catch (exception) {
      error = exception;
      actionCompleted = false;
    } finally {
      isUpdating = false;
    }
  }
}

void main() {
  group('Mutation failure recovery behavior', () {
    test(
      'successful mutation exits loading state and records success',
      () async {
        final controller = _MutationController(
          operation: () async {},
        );

        await controller.execute();

        expect(controller.isUpdating, isFalse);
        expect(controller.actionCompleted, isTrue);
        expect(controller.error, isNull);
      },
    );

    test(
      'failed mutation exits loading state and exposes the error',
      () async {
        final controller = _MutationController(
          operation: () async {
            throw StateError('Network unavailable');
          },
        );

        await controller.execute();

        expect(controller.isUpdating, isFalse);
        expect(controller.actionCompleted, isFalse);
        expect(controller.error, isA<StateError>());
      },
    );

    test(
      'failed mutation can be retried successfully',
      () async {
        var attempt = 0;

        final controller = _MutationController(
          operation: () async {
            attempt++;

            if (attempt == 1) {
              throw StateError('Temporary failure');
            }
          },
        );

        await controller.execute();

        expect(controller.isUpdating, isFalse);
        expect(controller.actionCompleted, isFalse);
        expect(controller.error, isA<StateError>());
        expect(attempt, 1);

        await controller.execute();

        expect(controller.isUpdating, isFalse);
        expect(controller.actionCompleted, isTrue);
        expect(controller.error, isNull);
        expect(attempt, 2);
      },
    );

    test(
      'duplicate execution is ignored while mutation is running',
      () async {
        var executionCount = 0;

        final controller = _MutationController(
          operation: () async {
            executionCount++;
            await Future<void>.delayed(
              const Duration(milliseconds: 50),
            );
          },
        );

        final first = controller.execute();
        final second = controller.execute();

        await Future.wait([
          first,
          second,
        ]);

        expect(executionCount, 1);
        expect(controller.isUpdating, isFalse);
        expect(controller.actionCompleted, isTrue);
      },
    );
  });
}
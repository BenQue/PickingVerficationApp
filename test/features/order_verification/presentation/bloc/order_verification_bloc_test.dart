import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:picking_verification_app/features/order_verification/domain/entities/verification_result.dart' as domain;
import 'package:picking_verification_app/features/order_verification/domain/repositories/verification_repository.dart';
import 'package:picking_verification_app/features/order_verification/presentation/bloc/order_verification_bloc.dart';
import 'package:picking_verification_app/features/order_verification/presentation/bloc/order_verification_event.dart';
import 'package:picking_verification_app/features/order_verification/presentation/bloc/order_verification_state.dart';

import 'order_verification_bloc_test.mocks.dart';

@GenerateMocks([VerificationRepository])
void main() {
  group('OrderVerificationBloc', () {
    late MockVerificationRepository mockVerificationRepository;
    late OrderVerificationBloc bloc;

    setUp(() {
      mockVerificationRepository = MockVerificationRepository();
      bloc = OrderVerificationBloc(
        verificationRepository: mockVerificationRepository,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is VerificationInitial', () {
      expect(bloc.state, equals(VerificationInitial()));
    });

    group('StartVerificationEvent', () {
      blocTest<OrderVerificationBloc, OrderVerificationState>(
        'should emit VerificationReady when StartVerificationEvent is added',
        build: () => bloc,
        act: (bloc) => bloc.add(const StartVerificationEvent(
          taskId: 'TASK123',
          expectedOrderId: 'ORD456',
        )),
        expect: () => [
          const VerificationReady(
            taskId: 'TASK123',
            expectedOrderId: 'ORD456',
          ),
        ],
      );
    });

    group('ScanQRCodeEvent', () {
      blocTest<OrderVerificationBloc, OrderVerificationState>(
        'should emit [VerificationLoading, VerificationSuccess] when verification succeeds',
        build: () => bloc,
        seed: () => const VerificationReady(
          taskId: 'TASK123',
          expectedOrderId: 'ORD456',
        ),
        act: (bloc) {
          when(mockVerificationRepository.verifyOrder(
            scannedOrderId: anyNamed('scannedOrderId'),
            expectedOrderId: anyNamed('expectedOrderId'),
          )).thenAnswer((_) async => domain.VerificationResult(
            orderId: 'ORD456',
            isValid: true,
            verifiedAt: DateTime(2023, 12, 25),
          ));

          bloc.add(const ScanQRCodeEvent(scannedOrderId: 'ORD456'));
        },
        expect: () => [
          const VerificationLoading(scannedOrderId: 'ORD456'),
          VerificationSuccess(
            result: domain.VerificationResult(
              orderId: 'ORD456',
              isValid: true,
              verifiedAt: DateTime(2023, 12, 25),
            ),
            taskId: 'TASK123',
          ),
        ],
      );

      blocTest<OrderVerificationBloc, OrderVerificationState>(
        'should emit [VerificationLoading, VerificationFailure] when verification fails',
        build: () => bloc,
        seed: () => const VerificationReady(
          taskId: 'TASK123',
          expectedOrderId: 'ORD456',
        ),
        act: (bloc) {
          when(mockVerificationRepository.verifyOrder(
            scannedOrderId: anyNamed('scannedOrderId'),
            expectedOrderId: anyNamed('expectedOrderId'),
          )).thenAnswer((_) async => domain.VerificationResult(
            orderId: 'ORD999',
            isValid: false,
            errorMessage: '订单号不匹配',
            verifiedAt: DateTime(2023, 12, 25),
          ));

          bloc.add(const ScanQRCodeEvent(scannedOrderId: 'ORD999'));
        },
        expect: () => [
          const VerificationLoading(scannedOrderId: 'ORD999'),
          const VerificationFailure(
            errorMessage: '订单号不匹配',
            scannedOrderId: 'ORD999',
            expectedOrderId: 'ORD456',
            taskId: 'TASK123',
          ),
        ],
      );

      blocTest<OrderVerificationBloc, OrderVerificationState>(
        'should emit [VerificationLoading, VerificationFailure] when repository throws exception',
        build: () => bloc,
        seed: () => const VerificationReady(
          taskId: 'TASK123',
          expectedOrderId: 'ORD456',
        ),
        act: (bloc) {
          when(mockVerificationRepository.verifyOrder(
            scannedOrderId: anyNamed('scannedOrderId'),
            expectedOrderId: anyNamed('expectedOrderId'),
          )).thenThrow(Exception('Network error'));

          bloc.add(const ScanQRCodeEvent(scannedOrderId: 'ORD456'));
        },
        expect: () => [
          const VerificationLoading(scannedOrderId: 'ORD456'),
          const VerificationFailure(
            errorMessage: '验证过程中出现错误：Exception: Network error',
            scannedOrderId: 'ORD456',
            expectedOrderId: 'ORD456',
            taskId: 'TASK123',
          ),
        ],
      );

      blocTest<OrderVerificationBloc, OrderVerificationState>(
        'should not emit anything when state is not VerificationReady',
        build: () => bloc,
        act: (bloc) => bloc.add(const ScanQRCodeEvent(scannedOrderId: 'ORD456')),
        expect: () => [],
        verify: (_) {
          verifyNever(mockVerificationRepository.verifyOrder(
            scannedOrderId: anyNamed('scannedOrderId'),
            expectedOrderId: anyNamed('expectedOrderId'),
          ));
        },
      );
    });

    group('VerifyManualInputEvent', () {
      blocTest<OrderVerificationBloc, OrderVerificationState>(
        'should work from VerificationReady state',
        build: () => bloc,
        seed: () => const VerificationReady(
          taskId: 'TASK123',
          expectedOrderId: 'ORD456',
        ),
        act: (bloc) {
          when(mockVerificationRepository.verifyOrder(
            scannedOrderId: anyNamed('scannedOrderId'),
            expectedOrderId: anyNamed('expectedOrderId'),
          )).thenAnswer((_) async => domain.VerificationResult(
            orderId: 'ORD456',
            isValid: true,
            verifiedAt: DateTime(2023, 12, 25),
          ));

          bloc.add(const VerifyManualInputEvent(inputOrderId: 'ORD456'));
        },
        expect: () => [
          const VerificationLoading(scannedOrderId: 'ORD456'),
          VerificationSuccess(
            result: domain.VerificationResult(
              orderId: 'ORD456',
              isValid: true,
              verifiedAt: DateTime(2023, 12, 25),
            ),
            taskId: 'TASK123',
          ),
        ],
      );

      blocTest<OrderVerificationBloc, OrderVerificationState>(
        'should work from VerificationFailure state',
        build: () => bloc,
        seed: () => const VerificationFailure(
          errorMessage: 'Previous error',
          scannedOrderId: 'ORD999',
          expectedOrderId: 'ORD456',
          taskId: 'TASK123',
        ),
        act: (bloc) {
          when(mockVerificationRepository.verifyOrder(
            scannedOrderId: anyNamed('scannedOrderId'),
            expectedOrderId: anyNamed('expectedOrderId'),
          )).thenAnswer((_) async => domain.VerificationResult(
            orderId: 'ORD456',
            isValid: true,
            verifiedAt: DateTime(2023, 12, 25),
          ));

          bloc.add(const VerifyManualInputEvent(inputOrderId: 'ORD456'));
        },
        expect: () => [
          const VerificationLoading(scannedOrderId: 'ORD456'),
          VerificationSuccess(
            result: domain.VerificationResult(
              orderId: 'ORD456',
              isValid: true,
              verifiedAt: DateTime(2023, 12, 25),
            ),
            taskId: 'TASK123',
          ),
        ],
      );
    });

    group('ResetVerificationEvent', () {
      blocTest<OrderVerificationBloc, OrderVerificationState>(
        'should reset from VerificationFailure to VerificationReady',
        build: () => bloc,
        seed: () => const VerificationFailure(
          errorMessage: 'Some error',
          scannedOrderId: 'ORD999',
          expectedOrderId: 'ORD456',
          taskId: 'TASK123',
        ),
        act: (bloc) => bloc.add(ResetVerificationEvent()),
        expect: () => [
          const VerificationReady(
            taskId: 'TASK123',
            expectedOrderId: 'ORD456',
          ),
        ],
      );

      blocTest<OrderVerificationBloc, OrderVerificationState>(
        'should not emit anything when not in VerificationFailure state',
        build: () => bloc,
        seed: () => const VerificationReady(
          taskId: 'TASK123',
          expectedOrderId: 'ORD456',
        ),
        act: (bloc) => bloc.add(ResetVerificationEvent()),
        expect: () => [],
      );
    });

    group('CancelVerificationEvent', () {
      blocTest<OrderVerificationBloc, OrderVerificationState>(
        'should emit VerificationCancelled',
        build: () => bloc,
        act: (bloc) => bloc.add(CancelVerificationEvent()),
        expect: () => [VerificationCancelled()],
      );
    });
  });
}
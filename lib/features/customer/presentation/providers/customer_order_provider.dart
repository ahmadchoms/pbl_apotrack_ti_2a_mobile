import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../staff/data/models/order.dart';
import '../../data/services/customer_order_service.dart';

class CustomerOrderState {
  final List<Order> activeOrders;
  final List<Order> historyOrders;
  final bool isLoadingActive;
  final bool isLoadingHistory;
  final String? activeError;
  final String? historyError;

  const CustomerOrderState({
    this.activeOrders = const [],
    this.historyOrders = const [],
    this.isLoadingActive = false,
    this.isLoadingHistory = false,
    this.activeError,
    this.historyError,
  });

  String? get error {
    if (activeOrders.isEmpty && historyOrders.isEmpty) {
      return activeError ?? historyError;
    }
    return null;
  }

  bool get isLoading => isLoadingActive || isLoadingHistory;

  CustomerOrderState copyWith({
    List<Order>? activeOrders,
    List<Order>? historyOrders,
    bool? isLoadingActive,
    bool? isLoadingHistory,
    String? activeError,
    String? historyError,
    bool clearActiveError = false,
    bool clearHistoryError = false,
  }) {
    return CustomerOrderState(
      activeOrders: activeOrders ?? this.activeOrders,
      historyOrders: historyOrders ?? this.historyOrders,
      isLoadingActive: isLoadingActive ?? this.isLoadingActive,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      activeError: clearActiveError ? null : activeError ?? this.activeError,
      historyError: clearHistoryError
          ? null
          : historyError ?? this.historyError,
    );
  }
}

class CustomerOrderNotifier extends StateNotifier<CustomerOrderState> {
  final CustomerOrderService _service;

  CustomerOrderNotifier(this._service) : super(const CustomerOrderState()) {
    loadAll();
  }

  Future<void> loadAll() async {
    unawaited(loadActive());
    unawaited(loadHistory());
  }

  Future<void> loadActive() async {
    if (!mounted) return;
    state = state.copyWith(isLoadingActive: true, clearActiveError: true);
    try {
      final orders = await _service.getActiveOrders();
      if (!mounted) return;
      state = state.copyWith(activeOrders: orders, isLoadingActive: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingActive: false,
        activeError: 'Gagal memuat pesanan aktif: ${e.toString()}',
      );
    }
  }

  Future<void> loadHistory() async {
    if (!mounted) return;
    state = state.copyWith(isLoadingHistory: true, clearHistoryError: true);
    try {
      final orders = await _service.getOrderHistory();
      if (!mounted) return;
      state = state.copyWith(historyOrders: orders, isLoadingHistory: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingHistory: false,
        historyError: 'Gagal memuat riwayat: ${e.toString()}',
      );
    }
  }

  Future<bool> requestCancellation(String orderId, String reason) async {
    try {
      final updated = await _service.requestCancellation(orderId, reason);
      if (!mounted) return false;
      state = state.copyWith(
        activeOrders: state.activeOrders.map((o) {
          return o.id == orderId ? updated : o;
        }).toList(),
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(activeError: 'Gagal membatalkan: ${e.toString()}');
      return false;
    }
  }

  Future<bool> confirmReceived(String orderId) async {
    try {
      await _service.confirmReceived(orderId);
      if (!mounted) return false;
      unawaited(loadAll());
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(activeError: 'Gagal konfirmasi: ${e.toString()}');
      return false;
    }
  }
}

final customerOrderProvider =
    StateNotifierProvider<CustomerOrderNotifier, CustomerOrderState>((ref) {
      return CustomerOrderNotifier(ref.read(customerOrderServiceProvider));
    });

final orderDetailProvider = FutureProvider.family<Order, String>((
  ref,
  id,
) async {
  return ref.read(customerOrderServiceProvider).getOrderDetail(id);
});

final orderTrackingProvider = FutureProvider.family<DeliveryTracking, String>((
  ref,
  id,
) async {
  return ref.read(customerOrderServiceProvider).getOrderTracking(id);
});

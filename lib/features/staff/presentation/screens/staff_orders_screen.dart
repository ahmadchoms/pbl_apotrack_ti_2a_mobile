import 'package:flutter/material.dart';

class StaffOrdersScreen extends StatelessWidget {
  const StaffOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1D70F5);
    const Color backgroundColor = Color(0xFFF9FAFB);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Manajemen Pesanan',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: primaryColor,
            unselectedLabelColor: Color(0xFF94A3B8),
            indicatorColor: primaryColor,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Diproses'),
              Tab(text: 'Siap'),
              Tab(text: 'Selesai'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrderList('PENDING'),
            _buildOrderList('PROCESSING'),
            _buildOrderList('READY'),
            _buildOrderList('COMPLETED'),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(String status) {
    // Dummy data
    final List<Map<String, dynamic>> dummyOrders = [
      {
        'id': '#ORD-0921',
        'time': '10:30',
        'customer': 'Andi Setiawan',
        'type': 'DELIVERY',
        'total': 'Rp 85.000',
        'status': status,
      },
      {
        'id': '#ORD-0922',
        'time': '11:15',
        'customer': 'Siti Aminah',
        'type': 'PICKUP',
        'total': 'Rp 120.000',
        'status': status,
      },
      {
        'id': '#ORD-0923',
        'time': '11:45',
        'customer': 'Budi Raharjo',
        'type': 'DELIVERY',
        'total': 'Rp 45.500',
        'status': status,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: dummyOrders.length,
      itemBuilder: (context, index) {
        final order = dummyOrders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    const Color primaryColor = Color(0xFF1D70F5);
    bool isDelivery = order['type'] == 'DELIVERY';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order['id'],
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                order['time'],
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order['customer'],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDelivery ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isDelivery ? Icons.local_shipping_outlined : Icons.storefront_outlined,
                      size: 14,
                      color: isDelivery ? primaryColor : const Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      order['type'],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isDelivery ? primaryColor : const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                order['total'],
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const Divider(height: 32, color: Color(0xFFF1F5F9)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Update Status',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/queue_model.dart';
import '../providers/queue_provider.dart';
import 'barcode_scanner_screen.dart';
import 'create_queue_screen.dart';
import 'queue_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedStatus;

  final List<Map<String, String?>> _statusFilters = [
    {'label': 'All', 'value': null},
    {'label': 'Waiting', 'value': 'waiting'},
    {'label': 'Processing', 'value': 'processing'},
    {'label': 'Completed', 'value': 'completed'},
    {'label': 'Cancelled', 'value': 'cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QueueProvider>().loadQueues();
    });
  }

  Future<void> _refresh() async {
    await context.read<QueueProvider>().loadQueues(status: _selectedStatus);
  }

  void _applyFilter(String? status) {
    setState(() => _selectedStatus = status);
    context.read<QueueProvider>().loadQueues(status: status);
  }

  Color _statusColor(QueueStatus status) {
    switch (status) {
      case QueueStatus.waiting:
        return Colors.orange;
      case QueueStatus.processing:
        return Colors.blue;
      case QueueStatus.completed:
        return Colors.green;
      case QueueStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cargo Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan Barcode',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const BarcodeScannerScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            filters: _statusFilters,
            selected: _selectedStatus,
            onSelected: _applyFilter,
          ),
          Expanded(
            child: Consumer<QueueProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.queues.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null && provider.queues.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(provider.error!,
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                            onPressed: _refresh,
                            child: const Text('Retry')),
                      ],
                    ),
                  );
                }

                if (provider.queues.isEmpty) {
                  return const Center(child: Text('No queues found.'));
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: provider.queues.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final queue = provider.queues[index];
                      return _QueueCard(
                        queue: queue,
                        statusColor: _statusColor(queue.status),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                QueueDetailScreen(queueId: queue.id),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateQueueScreen()),
        ).then((_) => _refresh()),
        icon: const Icon(Icons.add),
        label: const Text('New Queue'),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final List<Map<String, String?>> filters;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _FilterBar({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: filters.map((f) {
          final isSelected = f['value'] == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f['label']!),
              selected: isSelected,
              onSelected: (_) => onSelected(f['value']),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  final Queue queue;
  final Color statusColor;
  final VoidCallback onTap;

  const _QueueCard({
    required this.queue,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Text(
            queue.queueNumber.length > 3
                ? queue.queueNumber.substring(queue.queueNumber.length - 3)
                : queue.queueNumber,
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(queue.queueNumber,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          queue.vehicle?.plateNumber ?? 'No vehicle',
          style: const TextStyle(fontSize: 13),
        ),
        trailing: Chip(
          label: Text(queue.status.label,
              style: const TextStyle(fontSize: 12, color: Colors.white)),
          backgroundColor: statusColor,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/queue_model.dart';
import '../providers/queue_provider.dart';
import 'package:intl/intl.dart' hide TextDirection;

// ignore_for_file: use_build_context_synchronously

class QueueDetailScreen extends StatefulWidget {
  final int queueId;

  const QueueDetailScreen({super.key, required this.queueId});

  @override
  State<QueueDetailScreen> createState() => _QueueDetailScreenState();
}

class _QueueDetailScreenState extends State<QueueDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<QueueProvider>();
      provider.loadQueue(widget.queueId);
      provider.loadQueueHistory(widget.queueId);
    });
  }

  Future<void> _changeStatus(BuildContext context, Queue queue) async {
    final nextStatuses = _nextStatuses(queue.status);
    if (nextStatuses.isEmpty) return;

    final provider = context.read<QueueProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final selected = await showModalBottomSheet<QueueStatus>(
      context: context,
      builder: (ctx) => _StatusPickerSheet(statuses: nextStatuses),
    );

    if (selected == null || !mounted) return;

    final notesController = TextEditingController();
    if (!mounted) return;
    
    final dialogContext = context;
    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: Text('Move to ${selected.label}?'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await provider.updateQueueStatus(
          queue.id,
          selected.name,
          notes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      provider.loadQueueHistory(widget.queueId);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
              content: Text('Status updated to ${selected.label}'),
              backgroundColor: Colors.green),
        );
      }
    } else {
      final error = provider.error;
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
              content: Text(error ?? 'Failed to update status'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  List<QueueStatus> _nextStatuses(QueueStatus current) {
    switch (current) {
      case QueueStatus.waiting:
        return [QueueStatus.processing, QueueStatus.cancelled];
      case QueueStatus.processing:
        return [QueueStatus.completed, QueueStatus.cancelled];
      case QueueStatus.completed:
      case QueueStatus.cancelled:
        return [];
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('dd MMM yyyy, HH:mm').format(dt.toLocal());
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
    return Consumer<QueueProvider>(
      builder: (context, provider, _) {
        final queue = provider.selectedQueue;

        if (provider.isLoading && queue == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (queue == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Queue Detail')),
            body: Center(
              child: Text(provider.error ?? 'Queue not found',
                  style: const TextStyle(color: Colors.red)),
            ),
          );
        }

        final canChangeStatus = _nextStatuses(queue.status).isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: Text(queue.queueNumber),
            actions: [
              if (canChangeStatus)
                TextButton.icon(
                  onPressed: () => _changeStatus(context, queue),
                  icon: const Icon(Icons.update, color: Colors.white),
                  label: const Text('Update',
                      style: TextStyle(color: Colors.white)),
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await provider.loadQueue(widget.queueId);
              await provider.loadQueueHistory(widget.queueId);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatusBanner(status: queue.status, color: _statusColor(queue.status)),
                const SizedBox(height: 16),
                _InfoSection(
                  title: 'Vehicle',
                  children: [
                    _InfoRow('Plate', queue.vehicle?.plateNumber ?? '-'),
                    _InfoRow('Driver', queue.vehicle?.driverName ?? '-'),
                    _InfoRow('Phone', queue.vehicle?.driverPhone ?? '-'),
                    _InfoRow('Type', queue.vehicle?.vehicleType?.name ?? '-'),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoSection(
                  title: 'Cargo',
                  children: [
                    _InfoRow('Description', queue.cargoDescription ?? '-'),
                    _InfoRow(
                        'Weight',
                        queue.weightKg != null
                            ? '${queue.weightKg!.toStringAsFixed(1)} kg'
                            : '-'),
                    _InfoRow('Location', queue.location?.name ?? '-'),
                    _InfoRow('Notes', queue.notes ?? '-'),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoSection(
                  title: 'Timeline',
                  children: [
                    _InfoRow('Arrived', _formatDate(queue.arrivedAt)),
                    _InfoRow('Processing', _formatDate(queue.processedAt)),
                    _InfoRow('Completed', _formatDate(queue.completedAt)),
                    _InfoRow('Created', _formatDate(queue.createdAt)),
                  ],
                ),
                if (provider.queueHistory.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _HistorySection(history: provider.queueHistory),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final QueueStatus status;
  final Color color;

  const _StatusBanner({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Center(
        child: Text(
          status.label.toUpperCase(),
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final List<QueueHistory> history;

  const _HistorySection({required this.history});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status History',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Divider(),
            ...history.map((h) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(h.fromStatus.label,
                          style: const TextStyle(fontSize: 13)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward, size: 14),
                      ),
                      Text(h.toStatus.label,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      if (h.createdAt != null)
                        Text(
                          DateFormat('dd MMM, HH:mm')
                              .format(h.createdAt!.toLocal()),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _StatusPickerSheet extends StatelessWidget {
  final List<QueueStatus> statuses;

  const _StatusPickerSheet({required this.statuses});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Select new status',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...statuses.map((s) => ListTile(
                title: Text(s.label),
                onTap: () => Navigator.pop(context, s),
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

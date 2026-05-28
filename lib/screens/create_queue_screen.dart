import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle_model.dart';
import '../providers/queue_provider.dart';
import '../providers/vehicle_provider.dart';
import '../services/api_service.dart';

class CreateQueueScreen extends StatefulWidget {
  final String? scannedPlate;
  final Vehicle? preloadedVehicle;

  const CreateQueueScreen({super.key, this.scannedPlate, this.preloadedVehicle});

  @override
  State<CreateQueueScreen> createState() => _CreateQueueScreenState();
}

class _CreateQueueScreenState extends State<CreateQueueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _cargoController = TextEditingController();
  final _notesController = TextEditingController();
  final _weightController = TextEditingController();

  Vehicle? _selectedVehicle;
  VehicleType? _selectedVehicleType;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _plateController.text = widget.scannedPlate ?? '';
    _selectedVehicle = widget.preloadedVehicle;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleProvider>().loadVehicleTypes();
    });
  }

  @override
  void dispose() {
    _plateController.dispose();
    _cargoController.dispose();
    _notesController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _lookupVehicle() async {
    final plate = _plateController.text.trim().toUpperCase();
    if (plate.isEmpty) return;

    final vehicle =
        await context.read<VehicleProvider>().lookupVehicleByPlate(plate);
    setState(() => _selectedVehicle = vehicle);

    if (vehicle == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle not found — it will be registered on submit.')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final payload = <String, dynamic>{
      'plate_number': _plateController.text.trim().toUpperCase(),
      if (_selectedVehicle != null) 'vehicle_id': _selectedVehicle!.id,
      if (_selectedVehicleType != null)
        'vehicle_type_id': _selectedVehicleType!.id,
      if (_cargoController.text.trim().isNotEmpty)
        'cargo_description': _cargoController.text.trim(),
      if (_notesController.text.trim().isNotEmpty)
        'notes': _notesController.text.trim(),
      if (_weightController.text.trim().isNotEmpty)
        'weight_kg': double.tryParse(_weightController.text.trim()),
    };

    try {
      final queue = await context.read<QueueProvider>().createQueue(payload);

      if (!mounted) return;

      if (queue != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Queue ${queue.queueNumber} created'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, queue);
      } else {
        final error = context.read<QueueProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(error ?? 'Failed to create queue'),
              backgroundColor: Colors.red),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Queue')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Vehicle plate
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _plateController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Plate Number *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                    onChanged: (_) => setState(() => _selectedVehicle = null),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _lookupVehicle,
                  icon: const Icon(Icons.search),
                  tooltip: 'Look up vehicle',
                ),
              ],
            ),

            if (_selectedVehicle != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Found: ${_selectedVehicle!.driverName ?? _selectedVehicle!.plateNumber}'
                        '${_selectedVehicle!.vehicleType != null ? " (${_selectedVehicle!.vehicleType!.name})" : ""}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Vehicle type (if not found from lookup)
            if (_selectedVehicle == null)
              Consumer<VehicleProvider>(
                builder: (_, provider, __) {
                  if (provider.vehicleTypes.isEmpty) return const SizedBox.shrink();
                  return DropdownButtonFormField<VehicleType>(
                    value: _selectedVehicleType,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Type',
                      border: OutlineInputBorder(),
                    ),
                    items: provider.vehicleTypes
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedVehicleType = v),
                  );
                },
              ),

            if (_selectedVehicle == null) const SizedBox(height: 16),

            // Cargo description
            TextFormField(
              controller: _cargoController,
              decoration: const InputDecoration(
                labelText: 'Cargo Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // Weight
            TextFormField(
              controller: _weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
                suffixText: 'kg',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                if (double.tryParse(v) == null) return 'Enter a valid number';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Create Queue'),
            ),
          ],
        ),
      ),
    );
  }
}

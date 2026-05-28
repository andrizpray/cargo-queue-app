# WebSocket Real-Time Queue Updates Implementation

## Overview

This document describes the WebSocket client implementation for real-time queue updates in the Cargo Queue Flutter app.

## Architecture

### Components

1. **WebSocketService** (`lib/services/websocket_service.dart`)
   - Manages WebSocket connection lifecycle
   - Handles automatic reconnection with exponential backoff
   - Broadcasts events and connection status
   - Supports three event types: queue.created, queue.status-changed, queue.deleted

2. **QueueProvider** (`lib/providers/queue_provider.dart`)
   - Integrates WebSocket events with state management
   - Updates UI in real-time when events are received
   - Maintains backward compatibility with REST API

3. **AppLogger** (`lib/utils/logger.dart`)
   - Centralized logging utility
   - Suppresses linter warnings for production logging

## Features Implemented

### 1. WebSocket Connection Management
- Automatic connection on app startup
- Exponential backoff reconnection (5s, 10s, 15s, etc.)
- Maximum 10 reconnection attempts
- Graceful disconnection on app close

### 2. Real-Time Event Listeners
- **queue.created**: New queues appear at the top of the list
- **queue.status-changed**: Queue status updates instantly
- **queue.deleted**: Deleted queues are removed from the list

### 3. UI Updates
- **HomeScreen**: 
  - Live queue count display
  - Connection status indicator (green/red dot)
  - Real-time queue list updates
  
- **QueueDetailScreen**:
  - Live status updates
  - Connection status indicator
  - Real-time status changes reflected immediately

### 4. Connection Status Indicator
- Visual indicator showing WebSocket connection state
- Green dot = Connected
- Red dot = Disconnected
- Displayed in HomeScreen bottom bar and QueueDetailScreen

## WebSocket Event Format

### Connection
```
URL: ws://localhost:8000/app/cargo-queue-key
```

### Event Structure
```json
{
  "event": "queue.created|queue.status-changed|queue.deleted",
  "data": {
    "id": 1,
    "queue_number": "Q001",
    "status": "waiting",
    ...
  }
}
```

## Usage

### Automatic Integration
The WebSocket service is automatically initialized when the app starts:

```dart
// In QueueProvider constructor
QueueProvider(this._apiService) {
  _wsService = WebSocketService(url: AppConstants.wsUrl);
  _initializeWebSocket();
}
```

### Accessing Connection Status
```dart
Consumer<QueueProvider>(
  builder: (context, provider, _) {
    if (provider.wsConnected) {
      // Show connected state
    } else {
      // Show disconnected state
    }
  },
)
```

### Listening to Events
Events are automatically handled by the provider:
- New queues are inserted at the beginning of the list
- Status changes update existing queue objects
- Deleted queues are removed from the list

## Configuration

### WebSocket URL
Located in `lib/config/constants.dart`:
```dart
static const String wsUrl = 'ws://localhost:8000/app/cargo-queue-key';
```

### Reconnection Settings
In `lib/services/websocket_service.dart`:
- `_reconnectDelaySeconds = 5` (base delay)
- `_maxReconnectAttempts = 10` (maximum attempts)

## Testing

### Prerequisites
- Backend WebSocket server running on `ws://localhost:8000/app/cargo-queue-key`
- Flutter emulator or device

### Manual Testing Steps

1. **Start the app**
   ```bash
   flutter run
   ```

2. **Verify connection**
   - Check the connection indicator in HomeScreen (bottom bar)
   - Should show "Connected" with green dot

3. **Test queue.created event**
   - Create a new queue via the app or backend
   - New queue should appear at the top of the list in real-time

4. **Test queue.status-changed event**
   - Update a queue status via the app or backend
   - Status should update immediately in both HomeScreen and QueueDetailScreen

5. **Test queue.deleted event**
   - Delete a queue via the backend
   - Queue should disappear from the list in real-time

6. **Test reconnection**
   - Stop the backend server
   - Connection indicator should turn red
   - Restart the backend server
   - App should automatically reconnect

### Debugging
Enable logging to see WebSocket events:
```dart
// Logs are printed with [CargoQueue] prefix
// Examples:
// [CargoQueue] INFO: WebSocket connected
// [CargoQueue] INFO: Queue created: Q001
// [CargoQueue] INFO: Queue 1 status changed to processing
```

## Error Handling

### Connection Errors
- Automatically attempts to reconnect
- Exponential backoff prevents server overload
- Max 10 reconnection attempts

### Message Parsing Errors
- Logged but don't crash the app
- Invalid messages are silently ignored

### Disposal
- WebSocket is properly closed when provider is disposed
- All streams are closed to prevent memory leaks

## Performance Considerations

1. **Broadcast Streams**: Events use broadcast streams to support multiple listeners
2. **Efficient Updates**: Only affected queues are updated, not the entire list
3. **Memory Management**: Proper cleanup in dispose() method
4. **Exponential Backoff**: Prevents connection storms during outages

## Future Enhancements

1. Add message queue for offline support
2. Implement selective event subscriptions
3. Add metrics/analytics for connection health
4. Support for multiple WebSocket channels
5. Add unit tests for WebSocket service
6. Implement connection timeout handling

## Files Modified/Created

### Created
- `lib/services/websocket_service.dart` - WebSocket client implementation
- `lib/utils/logger.dart` - Logging utility

### Modified
- `pubspec.yaml` - Added web_socket_channel dependency
- `lib/config/constants.dart` - Added WebSocket URL
- `lib/providers/queue_provider.dart` - Integrated WebSocket events
- `lib/screens/home_screen.dart` - Added connection indicator and live count
- `lib/screens/queue_detail_screen.dart` - Added connection indicator

## Dependencies

- `web_socket_channel: ^2.4.0` - WebSocket client library

## Troubleshooting

### Connection not established
- Verify backend WebSocket server is running
- Check WebSocket URL in constants.dart
- Check network connectivity

### Events not received
- Verify backend is sending events in correct format
- Check logs for parsing errors
- Verify event types match enum values

### Memory leaks
- Ensure provider is properly disposed
- Check for unclosed streams in custom code

### High CPU usage
- Check reconnection loop (should use exponential backoff)
- Verify no infinite loops in event handlers

import 'package:flutter/material.dart';
import '../services/history_service.dart';
import '../models/print_job.dart';

class PrintHistoryPage extends StatefulWidget {
  const PrintHistoryPage({super.key});

  @override
  State<PrintHistoryPage> createState() => _PrintHistoryPageState();
}

class _PrintHistoryPageState extends State<PrintHistoryPage> {
  List<PrintJob> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await HistoryService.getHistory();
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    await HistoryService.clearHistory();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Print History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _history.isEmpty ? null : _clearHistory,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _history.isEmpty
                ? const Center(child: Text('No print history yet'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final job = _history[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                          title: Text(job.fileName),
                          subtitle: Text(
                              'To: ${job.printerIp}\n${job.timestamp.toString().split('.')[0]}'),
                          trailing: Text(
                            job.status,
                            style: TextStyle(
                              color: job.status.toLowerCase() == 'success'
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

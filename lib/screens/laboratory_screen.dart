import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/file_preferences.dart';
import '../l10n/app_localizations.dart';
import '../providers/laboratory_provider.dart';
import '../models/laboratory_item.dart';
import '../services/pdf_laboratory_service.dart';

class LaboratoryScreen extends StatefulWidget {
  const LaboratoryScreen({super.key});

  @override
  State<LaboratoryScreen> createState() => _LaboratoryScreenState();
}

class _LaboratoryScreenState extends State<LaboratoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  Set<String> _hiddenItemIds = {};

  @override
  void initState() {
    super.initState();
    _loadHiddenItemIds();
    final laboratoryProvider =
        Provider.of<LaboratoryProvider>(context, listen: false);
    laboratoryProvider.addListener(_onProviderChange);
    Future.microtask(() => laboratoryProvider.fetchData());
    _searchController.addListener(() {
      if (laboratoryProvider.searchQuery != _searchController.text) {
        laboratoryProvider.setSearchQuery(_searchController.text);
      }
    });
  }

  void _onProviderChange() {
    final laboratoryProvider =
        Provider.of<LaboratoryProvider>(context, listen: false);
    if (_searchController.text != laboratoryProvider.searchQuery) {
      _searchController.text = laboratoryProvider.searchQuery;
    }
  }

  Future<void> _loadHiddenItemIds() async {
    final prefs = await FilePreferences.getInstance();
    setState(() {
      _hiddenItemIds = (prefs.getStringList('hiddenLabItems') ?? []).toSet();
    });
  }

  @override
  void dispose() {
    Provider.of<LaboratoryProvider>(context, listen: false)
        .removeListener(_onProviderChange);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final provider = Provider.of<LaboratoryProvider>(context);

    final displayedItems = provider.items.where((item) {
      return !_hiddenItemIds.contains(item.treatment.treatmentId.toString());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.laboratory),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        actions: [
          if (provider.selectedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: appLocalizations.save,
              onPressed: () async {
                final pdfBytes = await PdfLaboratoryService.generateLaboratoryPdf(provider.selectedItems, appLocalizations);
                final fileName = 'laboratory_${DateTime.now().millisecondsSinceEpoch}';
                await PdfLaboratoryService.savePdf(fileName, pdfBytes);

                final prefs = await FilePreferences.getInstance();
                final idsToHide = provider.selectedItems
                    .map((item) => item.treatment.treatmentId.toString())
                    .toList();
                setState(() {
                  _hiddenItemIds.addAll(idsToHide);
                });
                await prefs.setStringList('hiddenLabItems', _hiddenItemIds.toList());
                provider.selectAll(false);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(appLocalizations.exportSuccessful),
                  ),
                );
              },
            ),
        ],
      ),
      body: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1800),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: appLocalizations.search,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surface.withAlpha(10),
                ),
              ),
            ),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayedItems.isEmpty
                      ? Center(
                          child: Text(appLocalizations.noData),
                        )
                      : _buildDataTable(context, displayedItems, provider, appLocalizations),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(
      BuildContext context,
      List<LaboratoryItem> items,
      LaboratoryProvider provider,
      AppLocalizations appLocalizations) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 32.0),
            child: DataTable(
              columnSpacing: 20,
              horizontalMargin: 16,
              dataRowHeight: 56,
              headingRowHeight: 56,
              headingRowColor: MaterialStateProperty.all(
                  colorScheme.primary.withOpacity(0.05)),
              dividerThickness: 1,
              onSelectAll: (isSelected) {
                if (isSelected != null) {
                  for (var item in items) {
                    provider.selectItem(item, isSelected);
                  }
                }
              },
              columns: [
                DataColumn(
                    label: Expanded(
                        child: Text(appLocalizations.patientId,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)))),
                DataColumn(
                    label: Expanded(
                        child: Text(appLocalizations.patientName,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)))),
                DataColumn(
                    label: Expanded(
                        child: Text(appLocalizations.toothNumber,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)))),
                DataColumn(
                    label: Expanded(
                        child: Text(appLocalizations.notesFormField,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)))),
              ],
              rows: List.generate(items.length, (index) {
                final item = items[index];
                return DataRow(
                  selected: provider.selectedItems.contains(item),
                  onSelectChanged: (isSelected) {
                    if (isSelected != null) {
                      provider.selectItem(item, isSelected);
                    }
                  },
                  cells: [
                    DataCell(Text(item.patient.patientId.toString())),
                    DataCell(Text(item.patient.name)),
                    DataCell(Text(item.treatment.toothNumber ?? '')),
                    DataCell(
                      TextField(
                        controller: provider.getNoteController(item),
                        onChanged: (newNote) {
                          provider.updateNote(item, newNote);
                        },
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/buisness_model.dart';
import 'package:hotel_management_system/data/models/close_day_report.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:hotel_management_system/data/repositories/buisness_repository.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';
import 'package:hotel_management_system/state_management/buisness_state_and_notifier.dart';

// Common currencies list
const List<String> commonCurrencies = [
  'USD',
  'EUR',
  'GBP',
  'PKR',
  'INR',
  'JPY',
  'CAD',
  'AUD',
  'CHF',
  'CNY',
  'SAR',
  'AED',
  'KWD',
  'QAR',
  'BHD',
  'OMR',
  'JOD',
  'LBP',
  'EGP',
  'TRY',
];

// Common timezones
const List<String> commonTimezones = [
  'UTC',
  'America/New_York',
  'America/Los_Angeles',
  'Europe/London',
  'Europe/Paris',
  'Asia/Tokyo',
  'Asia/Shanghai',
  'Asia/Dubai',
  'Asia/Karachi',
  'Asia/Kolkata',
  'Australia/Sydney',
];

class BusinessManagementScreen extends ConsumerStatefulWidget {
  final String? ownerId; // Optional: filter by specific owner

  const BusinessManagementScreen({super.key, this.ownerId});

  @override
  ConsumerState<BusinessManagementScreen> createState() =>
      _BusinessManagementScreenState();
}

class _BusinessManagementScreenState
    extends ConsumerState<BusinessManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showActiveOnly = true;
  bool _isClosingDay = false;

  @override
  void initState() {
    super.initState();
    // Load businesses on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(businessProvider.notifier)
          .loadBusinesses(ownerId: widget.ownerId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BusinessModel> _filterBusinesses(List<BusinessModel> businesses) {
    var filtered = businesses.where((business) => !business.isDeleted).toList();

    // Filter by active status
    if (_showActiveOnly) {
      filtered = filtered.where((business) => business.isActive).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (business) =>
                business.title.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (business.description?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false) ||
                (business.address?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false) ||
                business.industryType.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final businessState = ref.watch(businessProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedUser = ref.watch(userProvider).selectedUser;
    final activeBusinessId =
        selectedUser?.primarybusinessId ??
        BusinessRepository.temporaryBusinesshId;
    final activeBranchId =
        selectedUser?.primaryBranchId ?? BusinessRepository.temporaryBranchId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Management'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isClosingDay
                ? null
                : () => _handleCloseDay(
                    businessId: activeBusinessId,
                    branchId: activeBranchId,
                    closedBy: selectedUser?.uid,
                  ),
            icon: const Icon(Icons.event_busy),
            tooltip: 'Close Day',
          ),
          IconButton(
            onPressed: () => _showCreateBusinessDialog(context),
            icon: const Icon(Icons.add_business),
            tooltip: 'Add Business',
          ),
          IconButton(
            onPressed: () => ref
                .read(businessProvider.notifier)
                .loadBusinesses(ownerId: widget.ownerId),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar
                SearchBar(
                  controller: _searchController,
                  hintText: 'Search businesses...',
                  leading: const Icon(Icons.search),
                  trailing: _searchQuery.isNotEmpty
                      ? [
                          IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: const Icon(Icons.clear),
                          ),
                        ]
                      : null,
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),

                const SizedBox(height: 12),

                // Active Filter
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Active Only'),
                      selected: _showActiveOnly,
                      onSelected: (selected) =>
                          setState(() => _showActiveOnly = selected),
                      avatar: Icon(
                        _showActiveOnly ? Icons.check_circle : Icons.visibility,
                        size: 18,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_filterBusinesses(businessState.businesses).length} business${_filterBusinesses(businessState.businesses).length == 1 ? '' : 'es'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content Area
          Expanded(child: _buildContent(businessState, colorScheme)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateBusinessDialog(context),
        icon: const Icon(Icons.add_business),
        label: const Text('Add Business'),
      ),
    );
  }

  Future<void> _handleCloseDay({
    required String businessId,
    required String branchId,
    required String? closedBy,
  }) async {
    if (businessId.isEmpty || branchId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select an active business and branch to close day.'),
        ),
      );
      return;
    }

    final shouldClose =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Close Day'),
            content: const Text(
              'This will close the current business day and start a new one. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Close Day'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldClose || !mounted) return;

    setState(() => _isClosingDay = true);
    try {
      final tableNotifier = ref.read(
        tableProvider((businessId: businessId, branchId: branchId)).notifier,
      );

      final closeDayRequest = (
        businessId: businessId,
        branchId: branchId,
        tableNotifier: tableNotifier,
        closedBy: closedBy,
      );
      ref.invalidate(closeCurrentDayReportProvider(closeDayRequest));
      final report = await ref.read(
        closeCurrentDayReportProvider(closeDayRequest).future,
      );

      if (!mounted) return;
      await _showCloseDayReportDialog(report);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to close day: $e')));
    } finally {
      if (mounted) {
        setState(() => _isClosingDay = false);
      }
    }
  }

  String _formatReportDateTime(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  String _fmtMoney(double value) => value.toStringAsFixed(2);

  Future<void> _showCloseDayReportDialog(CloseDayReport report) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Day Closed Report'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Start: ${_formatReportDateTime(report.dayStartAt.toLocal())}',
                  ),
                  Text(
                    'Closed: ${_formatReportDateTime(report.dayClosedAt.toLocal())}',
                  ),
                  const SizedBox(height: 12),
                  Text('Total Orders: ${report.totalOrders}'),
                  Text('Completed: ${report.completedOrders}'),
                  Text('Pending: ${report.pendingOrders}'),
                  Text('In Progress: ${report.inProgressOrders}'),
                  Text('Cancelled: ${report.cancelledOrders}'),
                  Text('Refunded: ${report.refundedOrders}'),
                  const Divider(height: 24),
                  Text('Total Amount: Rs ${_fmtMoney(report.totalAmount)}'),
                  Text('Total Expenses: Rs ${_fmtMoney(report.totalExpenses)}'),
                  Text(
                    'Cash In Hand After Expense: Rs ${_fmtMoney(report.cashInHandAfterExpenses)}',
                  ),
                  Text('Profit / Loss: Rs ${_fmtMoney(report.profitOrLoss)}'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final pdf = pw.Document();
                pdf.addPage(
                  pw.Page(
                    pageFormat: PdfPageFormat.a4,
                    build: (context) {
                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Close Day Report',
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 12),
                          pw.Text(
                            'Start: ${_formatReportDateTime(report.dayStartAt.toLocal())}',
                          ),
                          pw.Text(
                            'Closed: ${_formatReportDateTime(report.dayClosedAt.toLocal())}',
                          ),
                          pw.SizedBox(height: 12),
                          pw.Text('Total Orders: ${report.totalOrders}'),
                          pw.Text('Completed: ${report.completedOrders}'),
                          pw.Text('Pending: ${report.pendingOrders}'),
                          pw.Text('In Progress: ${report.inProgressOrders}'),
                          pw.Text('Cancelled: ${report.cancelledOrders}'),
                          pw.Text('Refunded: ${report.refundedOrders}'),
                          pw.SizedBox(height: 12),
                          pw.Text(
                            'Total Amount: Rs ${_fmtMoney(report.totalAmount)}',
                          ),
                          pw.Text(
                            'Total Expenses: Rs ${_fmtMoney(report.totalExpenses)}',
                          ),
                          pw.Text(
                            'Cash In Hand After Expense: Rs ${_fmtMoney(report.cashInHandAfterExpenses)}',
                          ),
                          pw.Text(
                            'Profit / Loss: Rs ${_fmtMoney(report.profitOrLoss)}',
                          ),
                        ],
                      );
                    },
                  ),
                );

                await Printing.layoutPdf(
                  onLayout: (format) async => pdf.save(),
                );
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Download PDF'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(BusinessState state, ColorScheme colorScheme) {
    if (state.isLoading && state.businesses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error loading businesses',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref
                  .read(businessProvider.notifier)
                  .loadBusinesses(ownerId: widget.ownerId),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredBusinesses = _filterBusinesses(state.businesses);

    if (filteredBusinesses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.business,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No businesses found'
                  : 'No businesses available',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search terms'
                  : 'Get started by adding your first business',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _showCreateBusinessDialog(context),
                icon: const Icon(Icons.add_business),
                label: const Text('Add Business'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(businessProvider.notifier)
          .loadBusinesses(ownerId: widget.ownerId),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive layout
          if (constraints.maxWidth > 1200) {
            // Desktop: 3 columns
            return _buildGridView(filteredBusinesses, 3);
          } else if (constraints.maxWidth > 800) {
            // Tablet: 2 columns
            return _buildGridView(filteredBusinesses, 2);
          } else {
            // Mobile: List view
            return _buildListView(filteredBusinesses, state.isLoading);
          }
        },
      ),
    );
  }

  Widget _buildListView(List<BusinessModel> businesses, bool isLoading) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: businesses.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == businesses.length && isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final business = businesses[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildBusinessCard(business, isListView: true),
        );
      },
    );
  }

  Widget _buildGridView(List<BusinessModel> businesses, int crossAxisCount) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: businesses.length,
      itemBuilder: (context, index) => _buildBusinessCard(businesses[index]),
    );
  }

  Widget _buildBusinessCard(BusinessModel business, {bool isListView = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isListView) {
      return Card(
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showBusinessDetails(context, business),
          child: Container(
            decoration: business.coverImageUrl != null
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(business.coverImageUrl!),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.3),
                        BlendMode.darken,
                      ),
                    ),
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Business Logo
                  _buildBusinessLogo(business.logoUrl, size: 60),
                  const SizedBox(width: 16),

                  // Business Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                business.title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: business.coverImageUrl != null
                                      ? Colors.white
                                      : null,
                                ),
                              ),
                            ),
                            _buildStatusChip(business.isActive, colorScheme),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _buildIndustryChip(business.industryType, colorScheme),
                        const SizedBox(height: 8),
                        if (business.description != null) ...[
                          Text(
                            business.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: business.coverImageUrl != null
                                  ? Colors.white70
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (business.address != null ||
                            business.city != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: business.coverImageUrl != null
                                    ? Colors.white70
                                    : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _getFullAddress(business),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: business.coverImageUrl != null
                                        ? Colors.white70
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              business.currencyCode,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: business.coverImageUrl != null
                                    ? Colors.white70
                                    : colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tax: ${business.taxPercentage}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: business.coverImageUrl != null
                                    ? Colors.white70
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  PopupMenuButton(
                    itemBuilder: (context) => _buildPopupMenuItems(business),
                    icon: Icon(
                      Icons.more_vert,
                      color: business.coverImageUrl != null
                          ? Colors.white
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      // Grid Card
      return Card(
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showBusinessDetails(context, business),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image or Header
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    image: business.coverImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(business.coverImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: business.coverImageUrl == null
                        ? colorScheme.primaryContainer
                        : null,
                  ),
                  child: Stack(
                    children: [
                      if (business.coverImageUrl != null)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _buildBusinessLogo(business.logoUrl, size: 40),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: PopupMenuButton(
                          itemBuilder: (context) =>
                              _buildPopupMenuItems(business),
                          icon: Icon(
                            Icons.more_vert,
                            color: business.coverImageUrl != null
                                ? Colors.white
                                : colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              business.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: business.coverImageUrl != null
                                    ? Colors.white
                                    : colorScheme.onPrimaryContainer,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildIndustryChip(
                                  business.industryType,
                                  colorScheme,
                                  isSmall: true,
                                ),
                                const Spacer(),
                                _buildStatusChip(
                                  business.isActive,
                                  colorScheme,
                                  isSmall: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Business Details
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (business.description != null) ...[
                        Text(
                          business.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                      ],

                      const Spacer(),

                      // Footer info
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              business.city ??
                                  business.address ??
                                  'Location not set',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            business.currencyCode,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tax: ${business.taxPercentage}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildBusinessLogo(String? logoUrl, {double size = 50}) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            logoUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildPlaceholderLogo(size),
          ),
        ),
      );
    }
    return _buildPlaceholderLogo(size);
  }

  Widget _buildPlaceholderLogo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.business,
        size: size * 0.5,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildStatusChip(
    bool isActive,
    ColorScheme colorScheme, {
    bool isSmall = false,
  }) {
    return Chip(
      label: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: isSmall ? 10 : 12,
          color: isActive ? colorScheme.onPrimary : colorScheme.onSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: isActive ? colorScheme.primary : colorScheme.secondary,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildIndustryChip(
    String industryType,
    ColorScheme colorScheme, {
    bool isSmall = false,
  }) {
    return Chip(
      label: Text(
        industryType.toUpperCase(),
        style: TextStyle(
          fontSize: isSmall ? 9 : 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: colorScheme.tertiaryContainer,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _getFullAddress(BusinessModel business) {
    final parts = <String>[];
    if (business.address != null) parts.add(business.address!);
    if (business.city != null) parts.add(business.city!);
    if (business.state != null) parts.add(business.state!);
    if (business.country != null) parts.add(business.country!);
    return parts.join(', ');
  }

  List<PopupMenuEntry> _buildPopupMenuItems(BusinessModel business) {
    return [
      PopupMenuItem(
        value: 'view',
        child: const ListTile(
          leading: Icon(Icons.visibility),
          title: Text('View Details'),
          contentPadding: EdgeInsets.zero,
        ),
        onTap: () => _showBusinessDetails(context, business),
      ),
      PopupMenuItem(
        value: 'edit',
        child: const ListTile(
          leading: Icon(Icons.edit),
          title: Text('Edit'),
          contentPadding: EdgeInsets.zero,
        ),
        onTap: () => _showEditBusinessDialog(context, business),
      ),
    ];
  }

  void _showBusinessDetails(BuildContext context, BusinessModel business) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BusinessDetailsDialog(business: business),
    );
  }

  void _showCreateBusinessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BusinessFormDialog(
        title: 'Create Business',
        onSave: (business) {
          ref.read(businessProvider.notifier).addBusiness(business);
        },
      ),
    );
  }

  void _showEditBusinessDialog(BuildContext context, BusinessModel business) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BusinessFormDialog(
        title: 'Edit Business',
        initialBusiness: business,
        onSave: (updatedBusiness) {
          ref.read(businessProvider.notifier).updateBusiness(updatedBusiness);
        },
      ),
    );
  }
}

// Business Details Dialog
class BusinessDetailsDialog extends StatelessWidget {
  final BusinessModel business;
  late BuildContext context;

  BusinessDetailsDialog({super.key, required this.business});

  @override
  Widget build(BuildContext context) {
    this.context = context;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with cover image
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                image: business.coverImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(business.coverImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: business.coverImageUrl == null
                    ? colorScheme.primaryContainer
                    : null,
              ),
              child: Stack(
                children: [
                  if (business.coverImageUrl != null)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _buildBusinessLogo(business.logoUrl, size: 60),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: business.coverImageUrl != null
                            ? Colors.white
                            : colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          business.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: business.coverImageUrl != null
                                ? Colors.white
                                : colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildStatusChip(business.isActive, colorScheme),
                            const SizedBox(width: 8),
                            _buildIndustryChip(
                              business.industryType,
                              colorScheme,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (business.description != null) ...[
                      _buildSectionTitle('Description'),
                      const SizedBox(height: 8),
                      Text(
                        business.description!,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                    ],

                    _buildSectionTitle('Contact Information'),
                    const SizedBox(height: 16),

                    if (business.email != null)
                      _buildInfoTile(
                        icon: Icons.email,
                        label: 'Email',
                        value: business.email!,
                      ),
                    if (business.phone != null)
                      _buildInfoTile(
                        icon: Icons.phone,
                        label: 'Phone',
                        value: business.phone!,
                      ),
                    if (business.website != null)
                      _buildInfoTile(
                        icon: Icons.language,
                        label: 'Website',
                        value: business.website!,
                      ),

                    const SizedBox(height: 20),

                    _buildSectionTitle('Location'),
                    const SizedBox(height: 16),

                    if (business.address != null)
                      _buildInfoTile(
                        icon: Icons.location_on,
                        label: 'Address',
                        value: business.address!,
                      ),
                    if (business.city != null)
                      _buildInfoTile(
                        icon: Icons.location_city,
                        label: 'City',
                        value: business.city!,
                      ),
                    if (business.state != null)
                      _buildInfoTile(
                        icon: Icons.map,
                        label: 'State',
                        value: business.state!,
                      ),
                    if (business.country != null)
                      _buildInfoTile(
                        icon: Icons.flag,
                        label: 'Country',
                        value: business.country!,
                      ),
                    if (business.postalCode != null)
                      _buildInfoTile(
                        icon: Icons.markunread_mailbox,
                        label: 'Postal Code',
                        value: business.postalCode!,
                      ),

                    const SizedBox(height: 20),

                    _buildSectionTitle('Business Settings'),
                    const SizedBox(height: 16),

                    _buildInfoTile(
                      icon: Icons.monetization_on,
                      label: 'Currency',
                      value: business.currencyCode,
                    ),
                    _buildInfoTile(
                      icon: Icons.percent,
                      label: 'Tax Percentage',
                      value: '${business.taxPercentage}%',
                    ),
                    if (business.serviceChargePercentage != null)
                      _buildInfoTile(
                        icon: Icons.room_service,
                        label: 'Service Charge',
                        value: '${business.serviceChargePercentage}%',
                      ),
                    _buildInfoTile(
                      icon: Icons.schedule,
                      label: 'Timezone',
                      value: business.timezone,
                    ),
                    _buildInfoTile(
                      icon: Icons.category,
                      label: 'Industry Type',
                      value: business.industryType,
                    ),

                    const SizedBox(height: 20),

                    _buildSectionTitle('System Information'),
                    const SizedBox(height: 16),

                    _buildInfoTile(
                      icon: Icons.person,
                      label: 'Owner ID',
                      value: business.ownerId,
                    ),
                    _buildInfoTile(
                      icon: Icons.calendar_today,
                      label: 'Created',
                      value: _formatFullDateTime(business.createdAt),
                    ),
                    _buildInfoTile(
                      icon: Icons.update,
                      label: 'Last Updated',
                      value: _formatFullDateTime(business.updatedAt),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessLogo(String? logoUrl, {double size = 50}) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            logoUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildPlaceholderLogo(size),
          ),
        ),
      );
    }
    return _buildPlaceholderLogo(size);
  }

  Widget _buildPlaceholderLogo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.business,
        size: size * 0.5,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildStatusChip(bool isActive, ColorScheme colorScheme) {
    return Chip(
      label: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 12,
          color: isActive ? colorScheme.onPrimary : colorScheme.onSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: isActive ? colorScheme.primary : colorScheme.secondary,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildIndustryChip(String industryType, ColorScheme colorScheme) {
    return Chip(
      label: Text(
        industryType.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
      backgroundColor: colorScheme.tertiaryContainer,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// Business Form Dialog
class BusinessFormDialog extends StatefulWidget {
  final String title;
  final BusinessModel? initialBusiness;
  final Function(BusinessModel) onSave;

  const BusinessFormDialog({
    super.key,
    required this.title,
    required this.onSave,
    this.initialBusiness,
  });

  @override
  State<BusinessFormDialog> createState() => _BusinessFormDialogState();
}

class _BusinessFormDialogState extends State<BusinessFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Text Controllers
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _logoUrlController;
  late final TextEditingController _coverImageUrlController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _websiteController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _countryController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _taxPercentageController;
  late final TextEditingController _serviceChargeController;
  late final TextEditingController _industryTypeController;

  // Dropdown Values
  String _selectedCurrency = 'USD';
  String _selectedTimezone = 'UTC';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final business = widget.initialBusiness;

    _titleController = TextEditingController(text: business?.title);
    _descriptionController = TextEditingController(text: business?.description);
    _logoUrlController = TextEditingController(text: business?.logoUrl);
    _coverImageUrlController = TextEditingController(
      text: business?.coverImageUrl,
    );
    _phoneController = TextEditingController(text: business?.phone);
    _emailController = TextEditingController(text: business?.email);
    _websiteController = TextEditingController(text: business?.website);
    _addressController = TextEditingController(text: business?.address);
    _cityController = TextEditingController(text: business?.city);
    _stateController = TextEditingController(text: business?.state);
    _countryController = TextEditingController(text: business?.country);
    _postalCodeController = TextEditingController(text: business?.postalCode);
    _taxPercentageController = TextEditingController(
      text: business?.taxPercentage.toString() ?? '0',
    );
    _serviceChargeController = TextEditingController(
      text: business?.serviceChargePercentage?.toString(),
    );
    _industryTypeController = TextEditingController(
      text: business?.industryType ?? 'general',
    );

    _selectedCurrency = business?.currencyCode ?? 'USD';
    _selectedTimezone = business?.timezone ?? 'UTC';
    _isActive = business?.isActive ?? true;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _logoUrlController.dispose();
    _coverImageUrlController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _postalCodeController.dispose();
    _taxPercentageController.dispose();
    _serviceChargeController.dispose();
    _industryTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.business,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: Form(
                key: _formKey,
                child: Scrollbar(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic Information
                        _buildSectionHeader('Basic Information'),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Business Title *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.business),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a business title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _industryTypeController,
                          decoration: const InputDecoration(
                            labelText: 'Industry Type',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Images
                        _buildSectionHeader('Images'),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _logoUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Logo URL',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.image),
                            helperText: 'Square logo recommended',
                          ),
                          validator: _validateUrl,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _coverImageUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Cover Image URL',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.wallpaper),
                            helperText: 'Wide landscape image recommended',
                          ),
                          validator: _validateUrl,
                        ),
                        const SizedBox(height: 24),

                        // Contact Information
                        _buildSectionHeader('Contact Information'),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _websiteController,
                          decoration: const InputDecoration(
                            labelText: 'Website',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.language),
                          ),
                          keyboardType: TextInputType.url,
                          validator: _validateUrl,
                        ),
                        const SizedBox(height: 24),

                        // Location Information
                        _buildSectionHeader('Location'),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _cityController,
                                decoration: const InputDecoration(
                                  labelText: 'City',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.location_city),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _stateController,
                                decoration: const InputDecoration(
                                  labelText: 'State',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.map),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _countryController,
                                decoration: const InputDecoration(
                                  labelText: 'Country',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.flag),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _postalCodeController,
                                decoration: const InputDecoration(
                                  labelText: 'Postal Code',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.markunread_mailbox),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Business Settings
                        _buildSectionHeader('Business Settings'),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          initialValue: _selectedCurrency,
                          decoration: const InputDecoration(
                            labelText: 'Currency',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.monetization_on),
                          ),
                          items: commonCurrencies
                              .map(
                                (currency) => DropdownMenuItem(
                                  value: currency,
                                  child: Text(currency),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedCurrency = value!),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _taxPercentageController,
                                decoration: const InputDecoration(
                                  labelText: 'Tax Percentage',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.percent),
                                  suffixText: '%',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _serviceChargeController,
                                decoration: const InputDecoration(
                                  labelText: 'Service Charge',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.room_service),
                                  suffixText: '%',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          initialValue: _selectedTimezone,
                          decoration: const InputDecoration(
                            labelText: 'Timezone',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.schedule),
                          ),
                          items: commonTimezones
                              .map(
                                (timezone) => DropdownMenuItem(
                                  value: timezone,
                                  child: Text(timezone),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedTimezone = value!),
                        ),
                        const SizedBox(height: 24),

                        // Status
                        _buildSectionHeader('Status'),
                        const SizedBox(height: 16),

                        SwitchListTile(
                          title: const Text('Active Status'),
                          subtitle: Text(
                            _isActive
                                ? 'Business is active'
                                : 'Business is inactive',
                          ),
                          value: _isActive,
                          onChanged: (value) =>
                              setState(() => _isActive = value),
                          secondary: Icon(
                            _isActive ? Icons.check_circle : Icons.cancel,
                            color: _isActive
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _saveBusiness,
                    child: const Text('Save Business'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value != null && value.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value)) {
        return 'Please enter a valid email address';
      }
    }
    return null;
  }

  String? _validateUrl(String? value) {
    if (value != null && value.isNotEmpty) {
      final uri = Uri.tryParse(value);
      if (uri == null || (!uri.hasScheme && !value.startsWith('www.'))) {
        return 'Please enter a valid URL';
      }
    }
    return null;
  }

  void _saveBusiness() {
    if (_formKey.currentState!.validate()) {
      final business = BusinessModel(
        id:
            widget.initialBusiness?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        ownerId:
            widget.initialBusiness?.ownerId ??
            'current_user_id', // Replace with actual user ID
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        logoUrl: _logoUrlController.text.trim().isEmpty
            ? null
            : _logoUrlController.text.trim(),
        coverImageUrl: _coverImageUrlController.text.trim().isEmpty
            ? null
            : _coverImageUrlController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        state: _stateController.text.trim().isEmpty
            ? null
            : _stateController.text.trim(),
        country: _countryController.text.trim().isEmpty
            ? null
            : _countryController.text.trim(),
        postalCode: _postalCodeController.text.trim().isEmpty
            ? null
            : _postalCodeController.text.trim(),
        currencyCode: _selectedCurrency,
        taxPercentage: double.tryParse(_taxPercentageController.text) ?? 0.0,
        serviceChargePercentage: _serviceChargeController.text.trim().isEmpty
            ? null
            : double.tryParse(_serviceChargeController.text),
        timezone: _selectedTimezone,
        industryType: _industryTypeController.text.trim().isEmpty
            ? 'general'
            : _industryTypeController.text.trim(),
        isActive: _isActive,
        createdAt: widget.initialBusiness?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSave(business);
      Navigator.of(context).pop();
    }
  }
}

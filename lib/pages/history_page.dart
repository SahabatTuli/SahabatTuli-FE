import 'package:flutter/material.dart';

import '../services/history_service.dart';
import '../theme/app_colors.dart';
import '../widgets/chat_bubble.dart';
import 'profile_page.dart';

class HistoryPage extends StatefulWidget {
  final bool isTabMode;
  final VoidCallback? onBackToHome;

  const HistoryPage({
    super.key,
    this.isTabMode = false,
    this.onBackToHome,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  final HistoryService _historyService = HistoryService();

  List _allHistory = [];
  bool _isLoading = true;

  // 'all' | 'conversation' | 'collaboration'
  String _selectedCategory = 'all';
  int? _selectedMonth;
  int? _selectedYear;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final items = await _historyService.getAllHistory();
      if (!mounted) return;
      setState(() {
        _allHistory = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    const monthNames = [
      "",
      "Januari",
      "Februari",
      "Maret",
      "April",
      "Mei",
      "Juni",
      "Juli",
      "Agustus",
      "September",
      "Oktober",
      "November",
      "Desember"
    ];
    return "${date.day} ${monthNames[date.month]} ${date.year}";
  }

  String _formatBubbleTime(dynamic rawTimestamp) {
    if (rawTimestamp == null) return '';
    final dt = DateTime.tryParse(rawTimestamp.toString())?.toLocal();
    if (dt == null) return '';
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour.$minute';
  }

  List _getAvailableMonths() {
    final months = _allHistory
        .map((item) => (item['date'] as DateTime).month)
        .toSet()
        .toList();
    months.sort();
    return months;
  }

  List _getAvailableYears() {
    final years = _allHistory
        .map((item) => (item['date'] as DateTime).year)
        .toSet()
        .toList();
    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  List get _filteredData {
    return _allHistory.where((item) {
      final date = item['date'] as DateTime;
      final type = item['type']?.toString() ?? 'conversation';

      final matchesCategory =
          _selectedCategory == 'all' ? true : type == _selectedCategory;
      final matchesSearch =
          item['title'].toString().toLowerCase().contains(_searchQuery) ||
              (item['creator']?.toString().toLowerCase().contains(_searchQuery) ??
                  false);
      final matchesMonth =
          _selectedMonth == null ? true : date.month == _selectedMonth;
      final matchesYear =
          _selectedYear == null ? true : date.year == _selectedYear;

      return matchesCategory && matchesSearch && matchesMonth && matchesYear;
    }).toList();
  }

  Future<void> _openHistoryDetail(Map item) async {
    final id = item['id']?.toString() ?? '';
    final type = item['type']?.toString() ?? 'collaboration';
    final isCollab = type == 'collaboration';

    if (id.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.navy),
      ),
    );

    try {
      final detail = await _historyService.getHistoryDetail(
        id: id,
        type: type,
      );
      if (!mounted) return;
      Navigator.pop(context);

      final List savedBubbles = detail['messages'] is List
          ? detail['messages'] as List
          : (item['messages'] is List ? item['messages'] as List : []);

      String fullText = '';
      if (detail['transcripts'] is List) {
        final transcripts = detail['transcripts'] as List;
        fullText = transcripts
            .map((t) => t is Map ? (t['text']?.toString() ?? '') : t.toString())
            .where((s) => s.trim().isNotEmpty)
            .join(' ');
      } else {
        fullText = detail['content']?.toString() ??
            detail['transcript']?.toString() ??
            item['content']?.toString() ??
            '';
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) {
          return DraggableScrollableSheet(
            initialChildSize: 0.68,
            minChildSize: 0.4,
            maxChildSize: 0.92,
            expand: false,
            builder: (_, scrollController) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isCollab
                                ? AppColors.navy.withOpacity(0.1)
                                : const Color(0xFF9CCC65).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isCollab ? 'Collaboration' : 'Percakapan',
                            style: TextStyle(
                              color: isCollab
                                  ? AppColors.navy
                                  : const Color(0xFF558B2F),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(item['date'] as DateTime),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item['title'].toString(),
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isCollab && item['creator'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Host: ${item['creator']}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    const Divider(height: 24),
                    Expanded(
                      child: (!isCollab && savedBubbles.isNotEmpty)
                          ? ListView.builder(
                              controller: scrollController,
                              itemCount: savedBubbles.length,
                              itemBuilder: (_, idx) {
                                final msg = savedBubbles[idx] is Map
                                    ? Map.from(savedBubbles[idx] as Map)
                                    : {'text': savedBubbles[idx].toString()};
                                return ChatBubble(
                                  text: msg['text']?.toString() ?? '',
                                  time: _formatBubbleTime(msg['timestamp']),
                                  isFromUser: msg['isFromUser'] == true,
                                );
                              },
                            )
                          : SingleChildScrollView(
                              controller: scrollController,
                              child: Text(
                                fullText.isEmpty
                                    ? 'Tidak ada catatan percakapan pada sesi ini.'
                                    : fullText,
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.55,
                                  color: fullText.isEmpty
                                      ? Colors.grey.shade500
                                      : AppColors.textDark,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataToShow = _filteredData;
    final availableMonths = _getAvailableMonths();
    final availableYears = _getAvailableYears();

    const monthNames = [
      "",
      "Januari",
      "Februari",
      "Maret",
      "April",
      "Mei",
      "Juni",
      "Juli",
      "Agustus",
      "September",
      "Oktober",
      "November",
      "Desember"
    ];

    return Column(
      children: [
        // --- HEADER PUTIH MELENGKUNG ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  if (widget.onBackToHome != null) {
                    widget.onBackToHome!();
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.navy,
                  size: 20,
                ),
              ),
              const Text(
                'History',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColors.navy,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // --- SEGMENTED FILTER: SEMUA | PERCAKAPAN | COLLABORATION ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildCategoryChip(label: 'Semua', value: 'all'),
                _buildCategoryChip(label: 'Percakapan', value: 'conversation'),
                _buildCategoryChip(
                  label: 'Collaboration',
                  value: 'collaboration',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // --- KOLOM PENCARIAN (ROUNDED FULL) ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            height: 44,
            padding: const EdgeInsets.only(left: 20, right: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 13.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari judul atau host....',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13.5,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const Icon(
                  Icons.search_rounded,
                  color: AppColors.textDark,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // --- FILTER BULAN & TAHUN (ROUNDED FULL) ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  value: _selectedMonth == null
                      ? 'Bulan'
                      : monthNames[_selectedMonth!],
                  items: [
                    'Bulan',
                    ...availableMonths.map((m) => monthNames[m as int]),
                  ],
                  onChanged: (val) {
                    setState(() {
                      if (val == 'Bulan' || val == null) {
                        _selectedMonth = null;
                      } else {
                        _selectedMonth = monthNames.indexOf(val.toString());
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildDropdown(
                  value: _selectedYear?.toString() ?? 'Tahun',
                  items: [
                    'Tahun',
                    ...availableYears.map((y) => y.toString()),
                  ],
                  onChanged: (val) {
                    setState(() {
                      if (val == 'Tahun' || val == null) {
                        _selectedYear = null;
                      } else {
                        _selectedYear = int.tryParse(val.toString());
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // --- LIST RIWAYAT ---
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.navy),
                  )
                : RefreshIndicator(
                    color: AppColors.navy,
                    onRefresh: _loadHistory,
                    child: dataToShow.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 120),
                              Center(
                                child: Text(
                                  'Riwayat tidak ditemukan',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                            itemCount: dataToShow.length,
                            itemBuilder: (context, index) {
                              final item = dataToShow[index] as Map;
                              final isCollab = item['type'] == 'collaboration';

                              return InkWell(
                                onTap: () => _openHistoryDetail(item),
                                borderRadius: BorderRadius.circular(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['title'].toString(),
                                            style: const TextStyle(
                                              color: AppColors.textDark,
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isCollab
                                                ? AppColors.navy
                                                    .withOpacity(0.1)
                                                : const Color(0xFF9CCC65)
                                                    .withOpacity(0.18),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isCollab
                                                    ? Icons.groups_rounded
                                                    : Icons
                                                        .chat_bubble_outline_rounded,
                                                size: 12,
                                                color: isCollab
                                                    ? AppColors.navy
                                                    : const Color(0xFF558B2F),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                isCollab
                                                    ? 'Collaboration'
                                                    : 'Percakapan',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: isCollab
                                                      ? AppColors.navy
                                                      : const Color(0xFF558B2F),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          _formatDate(item['date'] as DateTime),
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 11,
                                          ),
                                        ),
                                        if (isCollab &&
                                            item['creator'] != null) ...[
                                          Text(
                                            '  •  Host: ${item['creator']}',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: Colors.grey.shade200,
                                    ),
                                    const SizedBox(height: 14),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required String value,
  }) {
    final isSelected = _selectedCategory == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.navy : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List items,
    required ValueChanged onChanged,
  }) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(20),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textDark,
            size: 22,
          ),
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 13.5,
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item.toString(),
              child: Text(item.toString()),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
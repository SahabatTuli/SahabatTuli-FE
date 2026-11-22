import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
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
  final List _allHistoryData = [
    {"title": "Percakapan 1", "date": DateTime(2026, 9, 18)},
    {"title": "Percakapan 2", "date": DateTime(2026, 9, 18)},
    {"title": "Percakapan 3", "date": DateTime(2026, 9, 18)},
    {"title": "Rapat Proyek", "date": DateTime(2025, 10, 5)},
    {"title": "Catatan Kuliah", "date": DateTime(2025, 1, 12)},
    {"title": "Diskusi Tim", "date": DateTime(2024, 12, 20)},
    {"title": "Rencana Liburan", "date": DateTime(2026, 12, 25)},
  ];

  int? _selectedMonth;
  int? _selectedYear;
  String _searchQuery = "";

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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List _getAvailableMonths() {
    final months = _allHistoryData
        .map((item) => (item['date'] as DateTime).month)
        .toSet()
        .toList();
    months.sort();
    return months;
  }

  List _getAvailableYears() {
    final years = _allHistoryData
        .map((item) => (item['date'] as DateTime).year)
        .toSet()
        .toList();
    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  List get _filteredData {
    return _allHistoryData.where((item) {
      final date = item['date'] as DateTime;
      final matchesSearch =
          item['title'].toString().toLowerCase().contains(_searchQuery);
      final matchesMonth =
          _selectedMonth == null ? true : date.month == _selectedMonth;
      final matchesYear =
          _selectedYear == null ? true : date.year == _selectedYear;
      return matchesSearch && matchesMonth && matchesYear;
    }).toList();
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

        const SizedBox(height: 18),

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
                      hintText: 'Cari....',
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
                        _selectedMonth = monthNames.indexOf(val);
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
                        _selectedYear = int.tryParse(val);
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

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
            child: dataToShow.isEmpty
                ? Center(
                    child: Text(
                      'Percakapan tidak ditemukan',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13.5,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    itemCount: dataToShow.length,
                    itemBuilder: (context, index) {
                      final item = dataToShow[index] as Map;
                      return GestureDetector(
                        onTap: () {
                          // TODO: Arahkan ke detail percakapan
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'].toString(),
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(item['date'] as DateTime),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
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
      ],
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
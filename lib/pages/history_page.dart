import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'profile_page.dart';

class HistoryPage extends StatefulWidget {
  final bool isTabMode; // 👈 Tambahan: Membedakan mode tab atau push

  const HistoryPage({super.key, this.isTabMode = false});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _allHistoryData = [
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
      "", "Januari", "Februari", "Maret", "April", "Mei", "Juni",
      "Juli", "Agustus", "September", "Oktober", "November", "Desember"
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

  List<int> get _availableMonths {
    final months = _allHistoryData.map((item) => (item['date'] as DateTime).month).toSet().toList();
    months.sort(); 
    return months;
  }

  List<int> get _availableYears {
    final years = _allHistoryData.map((item) => (item['date'] as DateTime).year).toSet().toList();
    years.sort((a, b) => b.compareTo(a)); 
    return years;
  }

  List<Map<String, dynamic>> get _filteredData {
    return _allHistoryData.where((item) {
      final date = item['date'] as DateTime;
      final matchesSearch = item['title'].toString().toLowerCase().contains(_searchQuery);
      final matchesMonth = _selectedMonth == null ? true : date.month == _selectedMonth;
      final matchesYear = _selectedYear == null ? true : date.year == _selectedYear;
      return matchesSearch && matchesMonth && matchesYear;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dataToShow = _filteredData;
    final availableMonths = _availableMonths;
    final availableYears = _availableYears;

    const monthNames = [
      "", "Januari", "Februari", "Maret", "April", "Mei", "Juni",
      "Juli", "Agustus", "September", "Oktober", "November", "Desember"
    ];

    return Column(
      children: [
        // --- HEADER ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Tombol Back (Hanya muncul jika BUKAN mode tab)
              widget.isTabMode 
                  ? const SizedBox(width: 42) // Spacer jika mode tab
                  : GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios, color: AppColors.textDark, size: 20),
                    ),
              
              const Text(
                'Riwayat Percakapan',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              // Ikon Profil (Ukuran 42 disamakan dengan Dashboard)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  );
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppColors.navy,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: AppColors.white, size: 24),
                ),
              ),
            ],
          ),
        ),

        // --- KOLOM PENCARIAN ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: const Icon(Icons.search, color: AppColors.textDark),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // --- FILTER BULAN & TAHUN ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  value: _selectedMonth == null ? 'Bulan' : monthNames[_selectedMonth!],
                  items: ['Bulan', ...availableMonths.map((m) => monthNames[m])],
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
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  value: _selectedYear?.toString() ?? 'Tahun',
                  items: ['Tahun', ...availableYears.map((y) => y.toString())],
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
        const SizedBox(height: 16),

        // --- LIST RIWAYAT ---
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: dataToShow.isEmpty
                ? const Center(
                    child: Text(
                      'Percakapan tidak ditemukan',
                      style: TextStyle(color: AppColors.textGray, fontSize: 14),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: dataToShow.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 24,
                      thickness: 0.5,
                      color: Colors.grey,
                    ),
                    itemBuilder: (context, index) {
                      final item = dataToShow[index];
                      return GestureDetector(
                        onTap: () {
                          // TODO: Arahkan ke detail percakapan
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'],
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(item['date']),
                              style: const TextStyle(
                                color: AppColors.textGray,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textDark),
          style: const TextStyle(color: AppColors.textDark, fontSize: 14),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
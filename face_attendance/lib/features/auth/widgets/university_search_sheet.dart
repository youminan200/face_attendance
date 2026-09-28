import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/university_list.dart';
import '../../../core/network/api_client.dart';
import '../../../models/university.dart';

/// 진학사 기반 대한민국 전국 468개 대학교 및 사관학교 검색 바텀시트
class UniversitySearchSheet extends StatefulWidget {
  const UniversitySearchSheet({super.key});

  static Future<UniversityItem?> show(BuildContext context) {
    return showModalBottomSheet<UniversityItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UniversitySearchSheet(),
    );
  }

  @override
  State<UniversitySearchSheet> createState() => _UniversitySearchSheetState();
}

class _UniversitySearchSheetState extends State<UniversitySearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ApiClient _apiClient = ApiClient();
  String _selectedRegion = '전체';
  List<UniversityItem> _displayList = kDefaultUniversityList;
  bool _isLoading = false;
  Timer? _debounceTimer;

  final List<String> _regions = [
    '전체',
    '서울',
    '경기·인천',
    '대전·충청',
    '영남',
    '호남·제주',
    '과기원·특수대',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadJinhakUniversities('');
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      _loadJinhakUniversities(_searchController.text.trim());
    });
  }

  Future<void> _loadJinhakUniversities(String query) async {
    setState(() => _isLoading = true);

    try {
      final res = await _apiClient.get(
        ApiConfig.universitiesEndpoint,
        queryParams: query.isNotEmpty ? {'q': query} : null,
      );

      if (res.isSuccess && res.data != null && res.data!['universities'] is List) {
        final rawList = res.data!['universities'] as List;
        final list = rawList.map((item) {
          final m = Map<String, dynamic>.from(item);
          final name = m['name'] ?? '';
          final display = m['display_name'] ?? name;
          final address = m['address'] ?? '';
          final univCode = m['univ_code']?.toString() ?? 'uni';
          final flag = m['flag']?.toString() ?? '1';

          // 지역 판별
          String region = '기타';
          if (address.contains('서울')) {
            region = '서울';
          } else if (address.contains('경기') || address.contains('인천')) {
            region = '경기·인천';
          } else if (address.contains('대전') || address.contains('충청') || address.contains('세종')) {
            region = '대전·충청';
          } else if (address.contains('부산') || address.contains('대구') || address.contains('울산') || address.contains('경상')) {
            region = '영남';
          } else if (address.contains('광주') || address.contains('전라') || address.contains('제주')) {
            region = '호남·제주';
          } else if (name.contains('과학기술') || name.contains('사관학교') || name.contains('KAIST') || name.contains('UNIST')) {
            region = '과기원·특수대';
          }

          return UniversityItem(
            code: '${univCode}_$flag',
            name: display,
            region: region,
            domain: m['homepage'] ?? '',
            protocol: '진학사 연동',
            portalUrl: m['homepage'] ?? '',
          );
        }).toList();

        if (mounted) {
          setState(() {
            _displayList = _filterByRegion(list);
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('진학사 대학 목록 조회 실패 -> 기본 리스트 사용: $e');
    }

    // 통신 오류 시 로컬 리스트 폴백
    if (mounted) {
      setState(() {
        _displayList = _filterLocalList(query);
        _isLoading = false;
      });
    }
  }

  List<UniversityItem> _filterByRegion(List<UniversityItem> list) {
    if (_selectedRegion == '전체') return list;
    return list.where((u) => u.region.contains(_selectedRegion)).toList();
  }

  List<UniversityItem> _filterLocalList(String query) {
    return kDefaultUniversityList.where((univ) {
      final matchesRegion = _selectedRegion == '전체' || univ.region.contains(_selectedRegion);
      final q = query.toLowerCase();
      final matchesQuery = q.isEmpty ||
          univ.name.toLowerCase().contains(q) ||
          univ.code.toLowerCase().contains(q);
      return matchesRegion && matchesQuery;
    }).toList();
  }

  void _onRegionSelected(String region) {
    setState(() => _selectedRegion = region);
    _loadJinhakUniversities(_searchController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 상단 핸들 바
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(100),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 타이틀 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '대학교 검색 및 선택',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '진학사 공식 전국 468개 대학 실시간 연동',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // 검색 입력창
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '대학교명 또는 영문/지역 검색 (예: 배재대, 서울대, 충남대)...',
                hintStyle: TextStyle(fontSize: 13.5, color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _loadJinhakUniversities('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF282828) : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 권역 필터 칩 목록
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _regions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final region = _regions[index];
                final isSelected = _selectedRegion == region;
                return ChoiceChip(
                  label: Text(
                    region,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[800]),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Colors.blue,
                  backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[200],
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onSelected: (_) => _onRegionSelected(region),
                );
              },
            ),
          ),

          const Divider(height: 12),

          // 대학교 목록 리스트뷰
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _displayList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              '검색된 대학교가 없습니다.',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPadding + 16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _displayList.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final univ = _displayList[index];

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.school, color: Colors.blue, size: 22),
                            ),
                            title: Text(
                              univ.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  univ.region,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                if (univ.domain.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '• ${univ.domain}',
                                    style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                                  ),
                                ],
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () => Navigator.pop(context, univ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

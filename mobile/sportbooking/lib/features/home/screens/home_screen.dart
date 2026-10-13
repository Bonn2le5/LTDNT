import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/court_model.dart';
import '../../../models/court_type_model.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/court_repository.dart';
import '../widgets/court_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  Future<List<CourtModel>>? _future;
  CourtType? _type;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= context.read<CourtRepository>().getCourts();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = context
        .read<AuthRepository>()
        .currentUser!
        .fullName
        .split(' ')
        .last;
    return PageContent(
      children: [
        const Text(
          'TP. Hồ Chí Minh',
          style: TextStyle(color: Color(0xFF6B7E72), fontSize: 12),
        ),
        const SizedBox(height: 6),
        Text('Chào $name 👋', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        const Text(
          'Hôm nay, bạn muốn chơi môn gì?',
          style: TextStyle(color: Color(0xFF6B7E72)),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF12603C), Color(0xFF218650)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: Color(0xFFC9F28B), size: 20),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'RA SÂN, HẾT MÌNH',
                      style: TextStyle(
                        color: Color(0xFFC9F28B),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Một sân đấu.\nNgàn khoảnh khắc.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tìm sân gần bạn, chọn giờ phù hợp\nvà hẹn đồng đội ngay hôm nay.',
                style: TextStyle(color: Colors.white.withValues(alpha: .85)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        TextField(
          key: const Key('court_search'),
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm tên sân…',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xóa tìm kiếm',
                    onPressed: () => setState(_search.clear),
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('Tất cả'),
                  selected: _type == null,
                  onSelected: (_) => setState(() => _type = null),
                ),
              ),
              for (final type in CourtType.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    key: Key('filter_${type.name}'),
                    avatar: Icon(courtIcon(type), size: 16),
                    label: Text(type.label),
                    selected: _type == type,
                    onSelected: (_) => setState(() => _type = type),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        FutureBuilder<List<CourtModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LoadingPanel(label: 'Đang tìm sân cho bạn…');
            }
            if (snapshot.hasError) {
              return StatePanel(
                title: 'Chưa tải được danh sách sân',
                message: 'Vui lòng thử lại sau.',
                icon: Icons.cloud_off_rounded,
                onRetry: () => setState(
                  () => _future = context.read<CourtRepository>().getCourts(),
                ),
              );
            }
            final query = _search.text.trim().toLowerCase();
            final courts = snapshot.data!
                .where(
                  (court) =>
                      (_type == null || court.type == _type) &&
                      court.name.toLowerCase().contains(query),
                )
                .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Sân dành cho bạn',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${courts.length} sân',
                      style: const TextStyle(
                        color: AppTheme.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (courts.isEmpty)
                  const StatePanel(
                    title: 'Không tìm thấy sân',
                    message: 'Thử tên sân khác hoặc thay đổi bộ lọc.',
                  ),
                for (final court in courts) ...[
                  CourtCard(court: court),
                  const SizedBox(height: 16),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

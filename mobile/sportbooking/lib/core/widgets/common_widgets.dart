import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../models/booking_model.dart';
import '../../models/court_type_model.dart';

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

IconData courtIcon(CourtType type) => switch (type) {
  CourtType.football => Icons.sports_soccer_rounded,
  CourtType.badminton => Icons.sports_tennis_rounded,
  CourtType.volleyball => Icons.sports_volleyball_rounded,
  CourtType.basketball => Icons.sports_basketball_rounded,
  CourtType.pickleball => Icons.sports_tennis_rounded,
};

class PageContent extends StatelessWidget {
  const PageContent({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(20),
  });
  final List<Widget> children;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    ),
  );
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.children, this.title});
  final List<Widget> children;
  final String? title;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(title!, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
          ],
          ...children,
        ],
      ),
    ),
  );
}

class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.emphasize = false});
  final String label;
  final String value;
  final bool emphasize;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(label, style: const TextStyle(color: Color(0xFF6B7E72))),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              color: emphasize ? AppTheme.green : null,
            ),
          ),
        ),
      ],
    ),
  );
}

class StatePanel extends StatelessWidget {
  const StatePanel({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.search_off_rounded,
    this.onRetry,
  });
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 34,
          backgroundColor: const Color(0xFFE8F1EA),
          child: Icon(icon, size: 32, color: AppTheme.green),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ],
    ),
  );
}

class LoadingPanel extends StatelessWidget {
  const LoadingPanel({super.key, this.label = 'Đang tải dữ liệu…'});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(40),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 18),
          Text(label),
        ],
      ),
    ),
  );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final BookingStatus status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      BookingStatus.pending => const Color(0xFF96600B),
      BookingStatus.cancelled ||
      BookingStatus.expired => const Color(0xFF9A4545),
      _ => AppTheme.green,
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          status.label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class BusyButton extends StatelessWidget {
  const BusyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: busy ? null : onPressed,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        children: [
          if (busy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          if (!busy && icon != null) Icon(icon, size: 20),
          Text(busy ? 'Đang xử lý…' : label, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.large = false});
  final bool large;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: large ? 52 : 34,
        height: large ? 52 : 34,
        decoration: BoxDecoration(
          color: AppTheme.green,
          borderRadius: BorderRadius.circular(large ? 16 : 10),
        ),
        child: Icon(
          Icons.sports_soccer_rounded,
          color: Colors.white,
          size: large ? 32 : 23,
        ),
      ),
      const SizedBox(width: 10),
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Đặt Sân',
            style: TextStyle(
              fontSize: large ? 28 : 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -.7,
            ),
          ),
        ),
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/orchard_theme.dart';
import '../widgets/common.dart';

class WeatherDetailScreen extends StatefulWidget {
  const WeatherDetailScreen({super.key});

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherState>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WeatherState>();
    final w = state.weather;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agri-Weather & Spraying Advisory'),
      ),
      body: state.loading && w == null
          ? const LoadingView(message: 'Fetching local orchard weather…')
          : state.error != null && w == null
              ? ErrorView(
                  message: state.error!,
                  onRetry: () => state.load(district: state.selectedDistrict),
                )
              : RefreshIndicator(
                  onRefresh: () => state.load(district: state.selectedDistrict),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      _DistrictSelector(
                        selected: state.selectedDistrict,
                        onChanged: (d) =>
                            context.read<WeatherState>().load(district: d),
                      ),
                      const SizedBox(height: 12),
                      if (w != null) ...[
                        _CurrentWeatherCard(weather: w),
                        const SizedBox(height: 14),
                        _AgriAdvisoryBanner(weather: w),
                        const SizedBox(height: 16),
                        const SectionTitle(title: '7-Day Orchard Forecast'),
                        const SizedBox(height: 8),
                        if (w.daily.isEmpty)
                          const EmptyView(message: 'Daily forecast unavailable.')
                        else
                          ...w.daily.map((day) => _DailyForecastCard(day: day)),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _DistrictSelector extends StatelessWidget {
  const _DistrictSelector({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, color: OrchardColors.pine),
            const SizedBox(width: 8),
            const Text(
              'District:',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: WeatherState.kashmiriDistricts.containsKey(selected)
                      ? selected
                      : 'srinagar',
                  items: WeatherState.kashmiriDistricts.entries.map((e) {
                    return DropdownMenuItem<String>(
                      value: e.key,
                      child: Text(
                        '${e.value} Orchard Zone',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: OrchardColors.forest,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) onChanged(val);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentWeatherCard extends StatelessWidget {
  const _CurrentWeatherCard({required this.weather});
  final WeatherInfo weather;

  @override
  Widget build(BuildContext context) {
    final w = weather;
    final temp = w.temperature != null ? '${w.temperature!.toStringAsFixed(1)}°C' : '--';
    final feels = w.feelsLike != null ? '${w.feelsLike!.toStringAsFixed(1)}°C' : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF15803D), Color(0xFF14532D)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    w.area.isEmpty ? 'Kashmir Valley' : w.area.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: Color(0xFF86EFAC),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    w.condition.isEmpty ? 'Current Conditions' : w.condition,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.wb_sunny_outlined,
                color: Color(0xFFFDE047),
                size: 40,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                temp,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (feels != null) ...[
                const SizedBox(width: 10),
                Text(
                  'Feels like $feels',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFBBF7D0),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _WeatherParam(
                  icon: Icons.water_drop_outlined,
                  label: 'Humidity',
                  value: w.humidity != null ? '${w.humidity!.round()}%' : '--',
                ),
                Container(height: 24, width: 1, color: Colors.white.withValues(alpha: 0.2)),
                _WeatherParam(
                  icon: Icons.air,
                  label: 'Wind Speed',
                  value: w.windSpeed != null ? '${w.windSpeed!.round()} km/h' : '--',
                ),
                Container(height: 24, width: 1, color: Colors.white.withValues(alpha: 0.2)),
                _WeatherParam(
                  icon: Icons.grain,
                  label: 'Rainfall',
                  value: w.precipitation != null ? '${w.precipitation} mm' : '0 mm',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherParam extends StatelessWidget {
  const _WeatherParam({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF86EFAC)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFFBBF7D0)),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _AgriAdvisoryBanner extends StatelessWidget {
  const _AgriAdvisoryBanner({required this.weather});
  final WeatherInfo weather;

  @override
  Widget build(BuildContext context) {
    final level = weather.level.toLowerCase();
    final isAlert = level == 'alert';
    final isCaution = level == 'caution';

    final Color bgColor = isAlert
        ? const Color(0xFFFEF2F2)
        : isCaution
            ? const Color(0xFFFFFBEB)
            : const Color(0xFFF0FDF4);

    final Color borderColor = isAlert
        ? const Color(0xFFFECACA)
        : isCaution
            ? const Color(0xFFFDE68A)
            : const Color(0xFFBBF7D0);

    final Color headerColor = isAlert
        ? const Color(0xFF991B1B)
        : isCaution
            ? const Color(0xFF92400E)
            : const Color(0xFF166534);

    final IconData icon = isAlert
        ? Icons.warning_amber_rounded
        : isCaution
            ? Icons.info_outline
            : Icons.check_circle_outline;

    final title = isAlert
        ? 'Orchard Weather Alert'
        : isCaution
            ? 'Advisory Notice: Marginal Spraying Window'
            : 'Optimal Orchard Spraying Window';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: headerColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: headerColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (weather.messages.isNotEmpty)
            ...weather.messages.map((msg) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: TextStyle(
                          color: headerColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          msg,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: headerColor.withValues(alpha: 0.9),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
          else if (weather.advisory.isNotEmpty)
            Text(
              weather.advisory,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: headerColor.withValues(alpha: 0.9),
              ),
            )
          else
            Text(
              'Favorable conditions for orchard care, spraying, and thinning.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: headerColor.withValues(alpha: 0.9),
              ),
            ),
        ],
      ),
    );
  }
}

class _DailyForecastCard extends StatelessWidget {
  const _DailyForecastCard({required this.day});
  final WeatherDailyForecast day;

  @override
  Widget build(BuildContext context) {
    final date = fmtDate(day.date);
    final max = day.tempMax != null ? '${day.tempMax!.round()}°' : '--';
    final min = day.tempMin != null ? '${day.tempMin!.round()}°' : '--';
    final rainProb = day.rainProbMax ?? 0;
    final wind = day.windMax != null ? '${day.windMax!.round()} km/h' : null;

    final isFrostRisk = day.tempMin != null && day.tempMin! < 2;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (isFrostRisk)
                    const Text(
                      'Frost Risk Alert',
                      style: TextStyle(
                        fontSize: 11,
                        color: OrchardColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (wind != null)
                    Text(
                      'Max Wind: $wind',
                      style: const TextStyle(fontSize: 11, color: OrchardColors.muted),
                    ),
                ],
              ),
            ),
            if (rainProb > 20)
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    const Icon(Icons.water_drop, size: 14, color: Color(0xFF0284C7)),
                    const SizedBox(width: 2),
                    Text(
                      '$rainProb%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              )
            else
              const Spacer(flex: 2),
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    max,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: OrchardColors.forest,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    min,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: OrchardColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

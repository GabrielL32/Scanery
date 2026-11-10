import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Temas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Ajustes > Temas',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Sección: Modo de apariencia
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.palette_outlined, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Modo de apariencia',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  _buildThemeModeTile(
                    context: context,
                    title: 'Predeterminado del sistema',
                    subtitle: 'Se adapta automáticamente al tema de tu dispositivo',
                    icon: Icons.brightness_auto_outlined,
                    mode: ThemeMode.system,
                    currentMode: themeProvider.themeMode,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                  ),
                  _buildThemeModeTile(
                    context: context,
                    title: 'Modo claro',
                    subtitle: 'Fondo claro siempre activo',
                    icon: Icons.light_mode_outlined,
                    mode: ThemeMode.light,
                    currentMode: themeProvider.themeMode,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                  ),
                  _buildThemeModeTile(
                    context: context,
                    title: 'Modo oscuro',
                    subtitle: 'Ideal para ambientes con poca luz y ahorro de batería',
                    icon: Icons.dark_mode_outlined,
                    mode: ThemeMode.dark,
                    currentMode: themeProvider.themeMode,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sección: Paleta de color acento
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.color_lens_outlined, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Color de acento (Material 3)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecciona el color base que personalizará los botones, tarjetas y elementos visuales de la aplicación:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: AppTheme.availableColors.map((color) {
                      final isSelected = themeProvider.seedColor.toARGB32() == color.toARGB32();
                      return InkWell(
                        onTap: () {
                          themeProvider.setSeedColor(color);
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.onSurface
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withAlpha(102),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 24,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sección: Vista previa del tema
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vista previa del estilo',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.document_scanner),
                        label: const Text('Escanear'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Exportar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Chip(
                        avatar: Icon(Icons.check_circle_outline, size: 16),
                        label: Text('Página 1'),
                      ),
                      SizedBox(width: 8),
                      Chip(
                        avatar: Icon(Icons.picture_as_pdf_outlined, size: 16),
                        label: Text('Formato A4'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeModeTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isSelected = mode == currentMode;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : const Icon(Icons.circle_outlined, color: Colors.grey),
      onTap: onTap,
    );
  }
}

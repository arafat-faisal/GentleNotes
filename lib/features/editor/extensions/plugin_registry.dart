import '../domain/entities/block_type.dart';
import 'block_plugin_interface.dart';

class PluginRegistry {
  static final PluginRegistry _instance = PluginRegistry._internal();
  factory PluginRegistry() => _instance;
  PluginRegistry._internal();

  final Map<BlockType, BlockPlugin> _plugins = {};

  void register(BlockPlugin plugin) {
    _plugins[plugin.type] = plugin;
  }

  BlockPlugin? getPlugin(BlockType type) {
    return _plugins[type];
  }

  List<BlockPlugin> getAllPlugins() {
    return _plugins.values.toList();
  }

  void clear() {
    _plugins.clear();
  }
}

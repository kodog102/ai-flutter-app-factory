class FactoryInfo {
  const FactoryInfo({
    required this.name,
    required this.version,
  });

  final String name;
  final String version;

  factory FactoryInfo.fromMap(Map<String, dynamic> map) {
    return FactoryInfo(
      name: map['name'] as String,
      version: map['version'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'version': version,
    };
  }
}

class PlatformInfo {
  const PlatformInfo({
    required this.framework,
    required this.language,
  });

  final String framework;
  final String language;

  factory PlatformInfo.fromMap(Map<String, dynamic> map) {
    return PlatformInfo(
      framework: map['framework'] as String,
      language: map['language'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'framework': framework,
      'language': language,
    };
  }
}

class ArchitectureInfo {
  const ArchitectureInfo({
    required this.style,
  });

  final String style;

  factory ArchitectureInfo.fromMap(Map<String, dynamic> map) {
    return ArchitectureInfo(
      style: map['style'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'style': style,
    };
  }
}

class WorkflowInfo {
  const WorkflowInfo({
    required this.architect,
    required this.implementation,
    required this.design,
    required this.qa,
  });

  final String architect;
  final String implementation;
  final String design;
  final String qa;

  factory WorkflowInfo.fromMap(Map<String, dynamic> map) {
    return WorkflowInfo(
      architect: map['architect'] as String,
      implementation: map['implementation'] as String,
      design: map['design'] as String,
      qa: map['qa'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'architect': architect,
      'implementation': implementation,
      'design': design,
      'qa': qa,
    };
  }
}

class TemplateInfo {
  const TemplateInfo({
    required this.id,
    required this.path,
  });

  final String id;
  final String path;

  factory TemplateInfo.fromMap(Map<String, dynamic> map) {
    return TemplateInfo(
      id: map['id'] as String,
      path: map['path'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
    };
  }
}

class FactoryManifest {
  const FactoryManifest({
    required this.factoryInfo,
    required this.platform,
    required this.architecture,
    required this.workflow,
    required this.template,
    required this.principles,
  });

  /// YAML key: `factory`
  final FactoryInfo factoryInfo;
  final PlatformInfo platform;
  final ArchitectureInfo architecture;
  final WorkflowInfo workflow;
  final TemplateInfo template;
  final List<String> principles;

  factory FactoryManifest.fromMap(Map<String, dynamic> map) {
    return FactoryManifest(
      factoryInfo: FactoryInfo.fromMap(
        Map<String, dynamic>.from(map['factory'] as Map),
      ),
      platform: PlatformInfo.fromMap(
        Map<String, dynamic>.from(map['platform'] as Map),
      ),
      architecture: ArchitectureInfo.fromMap(
        Map<String, dynamic>.from(map['architecture'] as Map),
      ),
      workflow: WorkflowInfo.fromMap(
        Map<String, dynamic>.from(map['workflow'] as Map),
      ),
      template: TemplateInfo.fromMap(
        Map<String, dynamic>.from(map['template'] as Map),
      ),
      principles: List<String>.from(map['principles'] as List),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'factory': factoryInfo.toMap(),
      'platform': platform.toMap(),
      'architecture': architecture.toMap(),
      'workflow': workflow.toMap(),
      'template': template.toMap(),
      'principles': principles,
    };
  }
}

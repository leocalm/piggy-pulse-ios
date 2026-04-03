#!/usr/bin/env ruby
# Adds the PiggyPulseWatch and PiggyPulseWatchWidgets targets to the Xcode project.

require 'xcodeproj'

project_path = File.join(__dir__, '..', 'PiggyPulse.xcodeproj')
project = Xcodeproj::Project.open(project_path)

# ──────────────────────────────────────────────────────────
# Helper: get the iOS app target
# ──────────────────────────────────────────────────────────
ios_target = project.targets.find { |t| t.name == 'PiggyPulse' }
raise 'Could not find PiggyPulse iOS target' unless ios_target

# ──────────────────────────────────────────────────────────
# Skip if already added
# ──────────────────────────────────────────────────────────
if project.targets.any? { |t| t.name == 'PiggyPulseWatch' }
  puts 'PiggyPulseWatch target already exists, skipping.'
  exit 0
end

# ──────────────────────────────────────────────────────────
# 1. Create PiggyPulseWatch group in the project
# ──────────────────────────────────────────────────────────
watch_group = project.main_group.new_group('PiggyPulseWatch', 'PiggyPulseWatch')
views_group = watch_group.new_group('Views', 'Views')
models_group = watch_group.new_group('Models', 'Models')
complications_group = watch_group.new_group('Complications', 'Complications')

# ──────────────────────────────────────────────────────────
# 2. Create the Watch App target
# ──────────────────────────────────────────────────────────
watch_target = project.new_target(
  :application,
  'PiggyPulseWatch',
  :watchos,
  '10.0'
)

# ──────────────────────────────────────────────────────────
# 3. Add source files to the watch target
# ──────────────────────────────────────────────────────────

# App entry point
app_ref = watch_group.new_file('PiggyPulseWatchApp.swift')
watch_target.source_build_phase.add_file_reference(app_ref)

# Views
%w[CurrentPeriodView.swift NetPositionView.swift AccountsListView.swift].each do |f|
  ref = views_group.new_file(f)
  watch_target.source_build_phase.add_file_reference(ref)
end

# Models
%w[WatchModels.swift WatchAPIClient.swift WatchConnectivityManager.swift CurrencyFormatter.swift].each do |f|
  ref = models_group.new_file(f)
  watch_target.source_build_phase.add_file_reference(ref)
end

# Info.plist
plist_ref = watch_group.new_file('PiggyPulseWatch-Info.plist')

# Localizable.xcstrings
loc_ref = watch_group.new_file('Localizable.xcstrings')
watch_target.resources_build_phase.add_file_reference(loc_ref)

# Assets
assets_ref = watch_group.new_file('Assets.xcassets')
watch_target.resources_build_phase.add_file_reference(assets_ref)

# ──────────────────────────────────────────────────────────
# 4. Configure Watch App build settings
# ──────────────────────────────────────────────────────────
watch_target.build_configurations.each do |config|
  s = config.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.piggypulse.ios.watchkitapp'
  s['INFOPLIST_FILE'] = 'PiggyPulseWatch/PiggyPulseWatch-Info.plist'
  s['GENERATE_INFOPLIST_FILE'] = 'YES'
  s['SDKROOT'] = 'watchos'
  s['WATCHOS_DEPLOYMENT_TARGET'] = '10.0'
  s['TARGETED_DEVICE_FAMILY'] = '4'  # Watch
  s['SWIFT_VERSION'] = '5.0'
  s['CODE_SIGN_STYLE'] = 'Automatic'
  s['DEVELOPMENT_TEAM'] = '742MF6AGHS'
  s['MARKETING_VERSION'] = '1.1.0'
  s['CURRENT_PROJECT_VERSION'] = '21'
  s['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  s['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
  s['ENABLE_PREVIEWS'] = 'YES'
  s['SWIFT_EMIT_LOC_STRINGS'] = 'YES'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks']
  s['SUPPORTED_PLATFORMS'] = 'watchos watchsimulator'
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  # Concurrency settings to match iOS target
  s['SWIFT_APPROACHABLE_CONCURRENCY'] = 'YES'
  s['SWIFT_DEFAULT_ACTOR_ISOLATION'] = 'MainActor'
end

# ──────────────────────────────────────────────────────────
# 5. Create the Widget Extension target
# ──────────────────────────────────────────────────────────
widget_target = project.new_target(
  :app_extension,
  'PiggyPulseWatchWidgets',
  :watchos,
  '10.0'
)

# Add complication source
comp_ref = complications_group.new_file('ComplicationProvider.swift')
widget_target.source_build_phase.add_file_reference(comp_ref)

# The widget extension also needs the models (API client, models, currency formatter)
%w[WatchModels.swift WatchAPIClient.swift CurrencyFormatter.swift].each do |f|
  # Find the existing file reference
  existing_ref = models_group.files.find { |fr| fr.display_name == f }
  widget_target.source_build_phase.add_file_reference(existing_ref) if existing_ref
end

# Widget Info.plist
widget_plist_ref = watch_group.new_file('PiggyPulseWatchWidgets-Info.plist')

# Widget also needs assets
widget_target.resources_build_phase.add_file_reference(assets_ref)

# Widget also needs localizable
widget_target.resources_build_phase.add_file_reference(loc_ref)

# ──────────────────────────────────────────────────────────
# 6. Configure Widget Extension build settings
# ──────────────────────────────────────────────────────────
widget_target.build_configurations.each do |config|
  s = config.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.piggypulse.ios.watchkitapp.widgets'
  s['INFOPLIST_FILE'] = 'PiggyPulseWatch/PiggyPulseWatchWidgets-Info.plist'
  s['GENERATE_INFOPLIST_FILE'] = 'YES'
  s['SDKROOT'] = 'watchos'
  s['WATCHOS_DEPLOYMENT_TARGET'] = '10.0'
  s['TARGETED_DEVICE_FAMILY'] = '4'
  s['SWIFT_VERSION'] = '5.0'
  s['CODE_SIGN_STYLE'] = 'Automatic'
  s['DEVELOPMENT_TEAM'] = '742MF6AGHS'
  s['MARKETING_VERSION'] = '1.1.0'
  s['CURRENT_PROJECT_VERSION'] = '21'
  s['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
  s['SWIFT_EMIT_LOC_STRINGS'] = 'YES'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
  s['SUPPORTED_PLATFORMS'] = 'watchos watchsimulator'
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['SWIFT_APPROACHABLE_CONCURRENCY'] = 'YES'
  s['SWIFT_DEFAULT_ACTOR_ISOLATION'] = 'MainActor'
end

# ──────────────────────────────────────────────────────────
# 7. Embed the widget extension in the watch app
# ──────────────────────────────────────────────────────────
watch_target.add_dependency(widget_target)

# Create an embed extensions build phase
embed_phase = watch_target.new_copy_files_build_phase('Embed App Extensions')
embed_phase.dst_subfolder_spec = '13'  # PlugIns
embed_phase.add_file_reference(widget_target.product_reference)

# ──────────────────────────────────────────────────────────
# 8. Add the watch app as a dependency of the iOS app
# ──────────────────────────────────────────────────────────
ios_target.add_dependency(watch_target)

# Create "Embed Watch Content" build phase on the iOS target
embed_watch_phase = ios_target.new_copy_files_build_phase('Embed Watch Content')
embed_watch_phase.dst_subfolder_spec = '16'  # Watch
embed_watch_phase.dst_path = '$(CONTENTS_FOLDER_PATH)/Watch'
embed_watch_phase.add_file_reference(watch_target.product_reference)

# ──────────────────────────────────────────────────────────
# Save
# ──────────────────────────────────────────────────────────
project.save

puts 'Successfully added PiggyPulseWatch and PiggyPulseWatchWidgets targets.'

#!/usr/bin/env ruby
require 'xcodeproj'

project_path = File.join(__dir__, '..', 'PiggyPulse.xcodeproj')
proj = Xcodeproj::Project.open(project_path)

# Check if target already exists
if proj.targets.any? { |t| t.name == 'PiggyPulseWidgets' }
  puts "Target PiggyPulseWidgets already exists, skipping."
  exit 0
end

main_target = proj.targets.find { |t| t.name == 'PiggyPulse' }

# Create the widget extension target
widget_target = proj.new_target(:app_extension, 'PiggyPulseWidgets', :ios, '18.0')
widget_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.piggypulse.ios.widgets'
  config.build_settings['INFOPLIST_FILE'] = 'PiggyPulseWidgets/PiggyPulseWidgets-Info.plist'
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'PiggyPulseWidgets/PiggyPulseWidgets.entitlements'
  config.build_settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
  config.build_settings['SWIFT_VERSION'] = '6.0'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['MARKETING_VERSION'] = '1.2.0'
  config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/../../Frameworks']
  config.build_settings['SKIP_INSTALL'] = 'YES'
end

# Create groups
widget_group = proj.main_group.new_group('PiggyPulseWidgets', 'PiggyPulseWidgets')

# Add source files to widget target
widget_files = [
  'PiggyPulseWidgets/PiggyPulseWidgets.swift',
  'PiggyPulseWidgets/NetPositionWidget.swift',
  'PiggyPulseWidgets/CurrentPeriodWidget.swift',
  'PiggyPulseWidgets/WidgetAPIClient.swift',
  'PiggyPulseWidgets/WidgetCurrencyFormatter.swift',
]

widget_files.each do |path|
  ref = widget_group.new_reference(File.basename(path))
  widget_target.source_build_phase.add_file_reference(ref)
end

# Add shared WidgetTokenStore to both main target and widget target
shared_group = proj.main_group.find_subpath('Shared/Utilities') || proj.main_group.find_subpath('Shared')
token_store_ref = nil
if shared_group
  token_store_ref = shared_group.files.find { |f| f.display_name == 'WidgetTokenStore.swift' }
  unless token_store_ref
    token_store_ref = shared_group.new_reference('WidgetTokenStore.swift')
    main_target.source_build_phase.add_file_reference(token_store_ref)
  end
end

# Also add WidgetTokenStore to widget target
if token_store_ref
  widget_target.source_build_phase.add_file_reference(token_store_ref)
end

# Embed widget extension in main app
main_target.add_dependency(widget_target)

# Add "Embed App Extensions" build phase
embed_phase = main_target.new_copy_files_build_phase('Embed App Extensions')
embed_phase.dst_subfolder_spec = '13' # PlugIns
build_file = embed_phase.add_file_reference(widget_target.product_reference)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

# Add App Group entitlements to main app if not already set
main_target.build_configurations.each do |config|
  unless config.build_settings['CODE_SIGN_ENTITLEMENTS']
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'PiggyPulse.entitlements'
  end
end

proj.save
puts "Added PiggyPulseWidgets target successfully."

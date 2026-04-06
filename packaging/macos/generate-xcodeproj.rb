#!/usr/bin/env ruby

require "fileutils"
require "rubygems"

begin
  gem "xcodeproj"
  require "xcodeproj"
rescue LoadError
  warn "Missing xcodeproj gem. Install it with:"
  warn "  gem install --user-install xcodeproj"
  exit 1
end

repo_root = File.expand_path("../..", __dir__)
project_path = File.join(repo_root, "knook.xcodeproj")
marketing_version = ENV.fetch("KNOOK_MARKETING_VERSION", "0.2.2")
current_project_version = ENV.fetch("KNOOK_CURRENT_PROJECT_VERSION", "1")

FileUtils.rm_rf(project_path)
project = Xcodeproj::Project.new(project_path)

main_group = project.main_group

sources_group = main_group.new_group("Sources", "Sources", :project)
app_group = sources_group.new_group("AppShell", "AppShell")
resources_group = app_group.new_group("Resources", "Resources")
core_group = sources_group.new_group("Core", "Core")

packaging_group = main_group.new_group("packaging", "packaging", :project)
macos_group = packaging_group.new_group("macos", "macos")
homebrew_group = packaging_group.new_group("homebrew", "homebrew")
homebrew_casks_group = homebrew_group.new_group("Casks", "Casks")

app_target = project.new_target(:application, "knook", :osx, "13.0")
core_target = project.new_target(:static_library, "Core", :osx, "13.0")
app_target.add_dependency(core_target)
app_target.frameworks_build_phase.add_file_reference(core_target.product_reference)

project.build_configuration_list.build_configurations.each do |config|
  config.build_settings["MACOSX_DEPLOYMENT_TARGET"] = "13.0"
  config.build_settings["SDKROOT"] = "macosx"
  config.build_settings["SWIFT_VERSION"] = "6.0"
end

app_target.build_configuration_list.build_configurations.each do |config|
  config.build_settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
  config.build_settings["CODE_SIGN_IDENTITY"] = "Developer ID Application"
  config.build_settings["CODE_SIGN_STYLE"] = "Manual"
  config.build_settings["CURRENT_PROJECT_VERSION"] = current_project_version
  config.build_settings["CODE_SIGN_ENTITLEMENTS"] = "packaging/macos/knook.entitlements"
  config.build_settings["DEVELOPMENT_TEAM"] = "BDT655MGNN"
  config.build_settings["ENABLE_HARDENED_RUNTIME"] = "YES"
  config.build_settings["GENERATE_INFOPLIST_FILE"] = "NO"
  config.build_settings["INFOPLIST_FILE"] = "packaging/macos/Info.plist"
  config.build_settings["LD_RUNPATH_SEARCH_PATHS"] = [
    "$(inherited)",
    "@executable_path/../Frameworks",
  ]
  config.build_settings["MACOSX_DEPLOYMENT_TARGET"] = "13.0"
  config.build_settings["MARKETING_VERSION"] = marketing_version
  config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "io.github.preetsuthar17.knook"
  config.build_settings["PRODUCT_NAME"] = "knook"
  config.build_settings["SDKROOT"] = "macosx"
  config.build_settings["SWIFT_EMIT_LOC_STRINGS"] = "YES"
  config.build_settings["SWIFT_VERSION"] = "6.0"
end

core_target.build_configuration_list.build_configurations.each do |config|
  config.build_settings["DEFINES_MODULE"] = "YES"
  config.build_settings["MACH_O_TYPE"] = "staticlib"
  config.build_settings["MACOSX_DEPLOYMENT_TARGET"] = "13.0"
  config.build_settings["PRODUCT_NAME"] = "Core"
  config.build_settings["SDKROOT"] = "macosx"
  config.build_settings["SKIP_INSTALL"] = "YES"
  config.build_settings["SWIFT_VERSION"] = "6.0"
end

app_source_refs = Dir[File.join(repo_root, "Sources/AppShell/*.swift")].sort.map do |path|
  app_group.new_file(File.basename(path))
end
core_source_refs = Dir[File.join(repo_root, "Sources/Core/*.swift")].sort.map do |path|
  core_group.new_file(File.basename(path))
end
resource_refs = [
  resources_group.new_file("AppIcon.png"),
  resources_group.new_file("Assets.xcassets"),
]

app_target.add_file_references(app_source_refs)
core_target.add_file_references(core_source_refs)
app_target.add_resources(resource_refs)

[
  "Info.plist",
  "ExportOptions.plist",
  "knook.entitlements",
  "create-dmg.sh",
  "generate-app-icons.sh",
  "generate-xcodeproj.rb",
  "release.sh",
].each do |name|
  macos_group.new_file(name)
end

homebrew_group.new_file("README.md")
homebrew_casks_group.new_file("knook.rb")

package_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
package_ref.repositoryURL = "https://github.com/simibac/ConfettiSwiftUI.git"
package_ref.requirement = {
  "kind" => "upToNextMajorVersion",
  "minimumVersion" => "1.1.0",
}
project.root_object.package_references << package_ref

package_product = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
package_product.package = package_ref
package_product.product_name = "ConfettiSwiftUI"
app_target.package_product_dependencies << package_product

package_build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
package_build_file.product_ref = package_product
app_target.frameworks_build_phase.files << package_build_file

project.sort
project.save

workspace_swiftpm_dir = File.join(project_path, "project.xcworkspace", "xcshareddata", "swiftpm")
root_package_resolved = File.join(repo_root, "Package.resolved")
if File.exist?(root_package_resolved)
  FileUtils.mkdir_p(workspace_swiftpm_dir)
  FileUtils.cp(root_package_resolved, File.join(workspace_swiftpm_dir, "Package.resolved"))
end

puts "Generated #{project_path}"

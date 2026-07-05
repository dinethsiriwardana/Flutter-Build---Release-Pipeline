require 'xcodeproj'

project = Xcodeproj::Project.open('ios/Runner.xcodeproj')
team_id = ENV['DEVELOPMENT_TEAM']
main_profile = ENV['MAIN_PROFILE_SPECIFIER']
# Uncomment the line below if using Live Activities / App Extensions
# live_profile = ENV['LIVE_ACTIVITY_PROFILE_SPECIFIER']

# Exit early if primary variables are missing to avoid cryptic errors
if team_id.nil? || team_id.empty? || main_profile.nil? || main_profile.empty?
  puts "Error: DEVELOPMENT_TEAM or MAIN_PROFILE_SPECIFIER environment variables are missing."
  exit 1
end

project.targets.each do |target|
  target.build_configurations.each do |config|
    config.build_settings['DEVELOPMENT_TEAM']   = team_id
    config.build_settings['CODE_SIGN_STYLE']    = 'Manual'
    config.build_settings['CODE_SIGN_IDENTITY'] = 'Apple Distribution'

    if target.name == 'Runner'
      config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = main_profile
    # Uncomment the block below if using Live Activities / App Extensions
    # elsif target.name.downcase.include?('live') && live_profile && !live_profile.empty?
    #   config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = live_profile
    end
  end
end

project.save

project.save

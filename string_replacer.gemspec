# frozen_string_literal: true

require_relative 'lib/string_replacer/version'

Gem::Specification.new do |spec|
  spec.name          = 'string_replacer'
  spec.version       = StringReplacer::VERSION
  spec.authors       = ['Pato']
  spec.email         = ['pato_devilla@hotmail.com']

  spec.summary       = 'Safely replace strings'
  spec.description   = 'Safely replace strings'
  # spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4.2'

  # spec.metadata['homepage_uri'] = spec.homepage
  # spec.metadata['source_code_uri'] = spec.homepage
  # spec.metadata['changelog_uri'] = 'https://github.com/apartmentlist/sidekiq-bouncer/blob/master/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end

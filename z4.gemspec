# frozen_string_literal: true

require_relative "lib/z4/version"

Gem::Specification.new do |spec|
  spec.name = "z4"
  spec.version = Z4::VERSION
  spec.authors = ["Erik Olson"]
  spec.email = ["xorgnak@gmail.com"]

  spec.summary = "a very quick app framework."
  spec.description = ["a simple app framwork built in honor of my cat.",
                      "  zyphr died on december 23rd, 2019.",
                      "She was a very good cat."].join(" ")
  spec.homepage = "https://github.com/xorgnak/z4"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "sinatra"
  spec.add_dependency "discordrb"
  spec.add_dependency "json"
  spec.add_dependency "dbm"
  spec.add_dependency "paho-mqtt"
  spec.add_dependency "browser"
  spec.add_dependency "rotp"
  spec.add_dependency "openssl"
  spec.add_dependency "rb-inotify"
  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end

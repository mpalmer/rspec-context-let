require 'git-version-bump'

Gem::Specification.new do |s|
	s.name = "rspec-context-let"

	s.version = GVB.version
	s.date    = GVB.date

	s.platform = Gem::Platform::RUBY

	s.homepage = "http://theshed.hezmatt.org/giddyup"
	s.summary = "'git-deploy' command to interact with giddyup-managed deployments"
	s.authors = ["Matt Palmer"]

	s.extra_rdoc_files = ["README.md"]
	s.files = %w{
		README.md
		lib/rspec/context-let.rb
		lib/rspec-context-let.rb
	}

	s.add_runtime_dependency "rspec-core", "~> 2.13"

	s.add_development_dependency 'bundler'
	s.add_development_dependency 'git-version-bump'
	s.add_development_dependency 'rake'
	s.add_development_dependency 'rdoc'
end

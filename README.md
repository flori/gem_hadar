# GemHadar - building gems and more

## Description

Ruby library that provides support for building gems.

## Download

The source of this library is located at

* http://github.com/flori/gem\_hadar

or can be installed via

```
$ gem install gem_hadar
```

## Usage

For more info look at `rake -T` and the code. Improve this README afterwards.

### To create/maintain ruby gems

* let your gem development-depend on gem_hadar
* add a Rakefile like this:
```ruby
# Rakefile
require 'gem_hadar'

GemHadar do
  name        'mygemname'
  path_name   'mygem'
  path_module 'Mygem'
  author      'My name'
  email       'my@mail'
  homepage    "https://github.com/younameit/#{name}"
  summary     'Precious gem'
  description 'Precious detailed gem'
  test_dir    'spec'
  ignore      'pkg', 'Gemfile.lock', '.DS_Store'

  readme      'README.md'
  title       "#{name.camelize} -- My library"
  licenses    << 'Apache-2.0'

  dependency             'sinatra'
  development_dependency 'rake'
  development_dependency 'rspec'
end
```

Note that gem_hadar is ["self hosted"](Rakefile)

### Update version

Use rake task or bump your VERSION file by hand.

### Release

`rake build`

This will basically regenerate the .gemspec with values from the Rakefile, create a tag etc.

## Author

Florian Frank \<mailto:flori@ping.de\>

## License

This software is licensed under the X11 (or MIT) license:
http://www.xfree86.org/3.3.6/COPYRIGHT2.html#3


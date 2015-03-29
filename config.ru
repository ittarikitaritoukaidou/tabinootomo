require 'rubygems'
require 'bundler'
require 'rack/protection'
require 'rack/flash'

Bundler.require
use Rack::Session::Cookie,
  :key => 'otomo.session',
  :expire_after => 2592000,
  :secret => 'wegwlksdvheglkdjgiep'
use Rack::Protection::FormToken

use Rack::Flash

use Rack::Deflater

require './otomo'
run OtomoApp










